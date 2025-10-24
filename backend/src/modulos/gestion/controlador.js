const TABLA_ACTAS = "actas";
const TABLA_ACTA_DETALLES = "acta_detalles";
const TABLA_ASIGNACIONES = "asignaciones";
const TABLA_DEVOLUCIONES = "devoluciones";
const TABLA_TRANSFERENCIAS = "transferencias_bodegas";
const TABLA_INVENTARIO = "inventario";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  // 🎯 ASIGNACIÓN MASIVA DE ACTIVOS
  async function asignacionMasiva(data, usuario) {
    const connection = await db.getConnection();
    
    try {
      await connection.beginTransaction();

      // 1. Validaciones básicas
      if (!data.tecnico_id || !data.sitio_venta_id || !data.inventario_ids || data.inventario_ids.length === 0) {
        throw new Error("Datos incompletos para la asignación masiva");
      }

      // 2. Verificar que todos los items existen y están disponibles
      const placeholders = data.inventario_ids.map(() => '?').join(',');
      const inventarioSql = `
        SELECT i.*, a.tipo_articulo 
        FROM inventario i 
        INNER JOIN articulos a ON i.articulo_id = a.id 
        WHERE i.id IN (${placeholders}) AND i.estado != 'Baja'
      `;
      
      const items = await connection.query(inventarioSql, data.inventario_ids);
      
      if (items.length !== data.inventario_ids.length) {
        throw new Error("Algunos items no existen o están dados de baja");
      }

      // 3. Verificar que todos son ACTIVOS (no consumibles)
      const itemsNoAptos = items.filter(item => 
        !['Activo Fijo', 'Activo de Control'].includes(item.tipo_articulo)
      );
      
      if (itemsNoAptos.length > 0) {
        throw new Error("Solo se pueden asignar Activos Fijos y de Control");
      }

      // 4. Verificar que todos están disponibles
      const itemsNoDisponibles = items.filter(item => 
        item.estado_asignacion !== 'disponible'
      );
      
      if (itemsNoDisponibles.length > 0) {
        throw new Error("Algunos items no están disponibles para asignación");
      }

      // 5. Crear acta de asignación
      const actaSql = `
        INSERT INTO ${TABLA_ACTAS} 
        (tipo, descripcion, fecha, usuario_creador_id, entregado_por_id, recibido_por_id)
        VALUES ('ASIGNACION', ?, NOW(), ?, ?, ?)
      `;
      
      const actaResult = await connection.query(actaSql, [
        data.descripcion || `Asignación masiva a técnico ${data.tecnico_id}`,
        usuario.id,
        usuario.id, // entregado_por (mismo usuario)
        data.tecnico_id
      ]);

      const actaId = actaResult.insertId;

      // 6. Crear detalles de acta y asignaciones individuales
      for (const item of items) {
        // Acta detalle
        const detalleSql = `
          INSERT INTO ${TABLA_ACTA_DETALLES} 
          (acta_id, inventario_id, estado_en_acta, comentarios)
          VALUES (?, ?, ?, ?)
        `;
        await connection.query(detalleSql, [
          actaId,
          item.id,
          item.estado,
          data.observaciones || null
        ]);

        // Asignación
        const asignacionSql = `
          INSERT INTO ${TABLA_ASIGNACIONES} 
          (inventario_id, tecnico_id, sitio_venta_id, usuario_asignador_id, estado, observaciones, fecha_asignacion)
          VALUES (?, ?, ?, ?, 'asignado', ?, NOW())
        `;
        await connection.query(asignacionSql, [
          item.id,
          data.tecnico_id,
          data.sitio_venta_id,
          usuario.id,
          data.observaciones || null
        ]);

        // Actualizar inventario
        const updateInventarioSql = `
          UPDATE inventario 
          SET estado_asignacion = 'asignado', fecha_actualizacion = NOW() 
          WHERE id = ?
        `;
        await connection.query(updateInventarioSql, [item.id]);
      }

      await connection.commit();

      return {
        success: true,
        message: `Asignación masiva completada: ${items.length} items asignados`,
        acta_id: actaId,
        items_asignados: items.length
      };

    } catch (error) {
      await connection.rollback();
      console.error("❌ ERROR en asignacionMasiva:", error);
      throw error;
    } finally {
      connection.release();
    }
  }

// 🔄 TRANSFERENCIA SIMPLIFICADA - SIN VERIFICACIÓN
async function solicitarTransferencia(data, usuario) {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();

    // 1. Validaciones
    if (!data.inventario_ids || data.inventario_ids.length === 0 || !data.bodega_destino) {
      throw new Error("Datos incompletos para transferencia");
    }

    // 2. Verificar permisos de bodega
    if (usuario.rol !== "administrador" && usuario.bodega !== data.bodega_origen) {
      throw new Error("No tienes permiso para transferir desde esta bodega");
    }

    // 3. Verificar items existen y están en bodega origen
    const placeholders = data.inventario_ids.map(() => '?').join(',');
    const inventarioSql = `
      SELECT * FROM inventario 
      WHERE id IN (${placeholders}) AND bodega = ? AND estado != 'Baja'
    `;
    
    const items = await connection.query(inventarioSql, [...data.inventario_ids, data.bodega_origen]);
    
    if (items.length !== data.inventario_ids.length) {
      throw new Error("Algunos items no existen o no están en la bodega origen");
    }

    // 4. Crear acta de transferencia
    const actaSql = `
      INSERT INTO ${TABLA_ACTAS} 
      (tipo, descripcion, fecha, usuario_creador_id, entregado_por_id)
      VALUES ('TRANSFERENCIA', ?, NOW(), ?, ?)
    `;
    
    const actaResult = await connection.query(actaSql, [
      data.motivo || `Transferencia de ${data.bodega_origen} a ${data.bodega_destino}`,
      usuario.id,
      usuario.id
    ]);

    const actaId = actaResult.insertId;

    // 5. ACTUALIZAR INVENTARIO INMEDIATAMENTE a bodega destino como "disponible"
    for (const item of items) {
      const updateInventarioSql = `
        UPDATE inventario 
        SET bodega = ?, estado_asignacion = 'disponible', fecha_actualizacion = NOW() 
        WHERE id = ?
      `;
      await connection.query(updateInventarioSql, [
        data.bodega_destino, // Se mueve inmediatamente
        item.id
      ]);

      // Registrar transferencia como COMPLETADA
      const transferenciaSql = `
        INSERT INTO ${TABLA_TRANSFERENCIAS} 
        (acta_id, inventario_id, bodega_origen, bodega_destino, cantidad, usuario_solicitante_id, estado, motivo)
        VALUES (?, ?, ?, ?, ?, ?, 'completada', ?)
      `;
      await connection.query(transferenciaSql, [
        actaId,
        item.id,
        data.bodega_origen,
        data.bodega_destino,
        item.cantidad,
        usuario.id,
        data.motivo || null
      ]);

      // Acta detalle
      const detalleSql = `
        INSERT INTO ${TABLA_ACTA_DETALLES} 
        (acta_id, inventario_id, estado_en_acta, comentarios)
        VALUES (?, ?, ?, ?)
      `;
      await connection.query(detalleSql, [
        actaId,
        item.id,
        item.estado,
        `Transferido: ${data.bodega_origen} → ${data.bodega_destino}`
      ]);
    }

    // 6. 🆕 CREAR NOTIFICACIÓN PARA LA BODEGA DESTINO
    const notificacionSql = `
      INSERT INTO notificaciones 
      (usuario_id, titulo, mensaje, tipo, leida, creado_en)
      SELECT 
        u.id,
        'Nueva Transferencia Recibida',
        ?,
        'transferencia',
        0,
        NOW()
      FROM usuarios u
      WHERE u.bodega = ? AND u.activo = 1
    `;
    
    await connection.query(notificacionSql, [
      `Has recibido ${items.length} items de ${data.bodega_origen}. Motivo: ${data.motivo || 'Sin motivo especificado'}`,
      data.bodega_destino
    ]);

    await connection.commit();

    return {
      success: true,
      message: `Transferencia completada: ${items.length} items movidos a ${data.bodega_destino}`,
      acta_id: actaId,
      items_transferidos: items.length,
      notificacion_enviada: true
    };

  } catch (error) {
    await connection.rollback();
    console.error("❌ ERROR en solicitarTransferencia:", error);
    throw error;
  } finally {
    connection.release();
  }
}

  // ✅ APROBAR/RECHAZAR TRANSFERENCIA
  async function aprobarTransferencia(actaId, decision, usuarioAprobador) {
    const connection = await db.getConnection();
    
    try {
      await connection.beginTransaction();

      // 1. Verificar que el usuario es administrador
      if (usuarioAprobador.rol !== "administrador") {
        throw new Error("Solo administradores pueden aprobar transferencias");
      }

      // 2. Obtener transferencias pendientes de esta acta
      const transferenciasSql = `
        SELECT * FROM ${TABLA_TRANSFERENCIAS} 
        WHERE acta_id = ? AND estado = 'pendiente'
      `;
      const transferencias = await connection.query(transferenciasSql, [actaId]);

      if (transferencias.length === 0) {
        throw new Error("No hay transferencias pendientes para esta acta");
      }

      const nuevoEstado = decision === 'aprobar' ? 'aprobada' : 'rechazada';

      // 3. Actualizar estado de transferencias
      const updateTransferenciasSql = `
        UPDATE ${TABLA_TRANSFERENCIAS} 
        SET estado = ?, usuario_aprobador_id = ?, fecha_aprobacion = NOW() 
        WHERE acta_id = ? AND estado = 'pendiente'
      `;
      await connection.query(updateTransferenciasSql, [
        nuevoEstado,
        usuarioAprobador.id,
        actaId
      ]);

      // 4. Si fue aprobada, actualizar inventario
      if (decision === 'aprobar') {
        for (const transferencia of transferencias) {
          const updateInventarioSql = `
            UPDATE inventario 
            SET bodega = ?, fecha_actualizacion = NOW() 
            WHERE id = ?
          `;
          await connection.query(updateInventarioSql, [
            transferencia.bodega_destino,
            transferencia.inventario_id
          ]);

          // Actualizar transferencia a completada
          const completarTransferenciaSql = `
            UPDATE ${TABLA_TRANSFERENCIAS} 
            SET estado = 'completada', fecha_completacion = NOW() 
            WHERE id = ?
          `;
          await connection.query(completarTransferenciaSql, [transferencia.id]);
        }
      }

      await connection.commit();

      return {
        success: true,
        message: `Transferencia ${nuevoEstado}: ${transferencias.length} items`,
        items_afectados: transferencias.length,
        estado: nuevoEstado
      };

    } catch (error) {
      await connection.rollback();
      console.error("❌ ERROR en aprobarTransferencia:", error);
      throw error;
    } finally {
      connection.release();
    }
  }

  // 🔄 DEVOLUCIÓN CON VALIDACIÓN DE ESTADO
  async function procesarDevolucion(data, usuario) {
    const connection = await db.getConnection();
    
    try {
      await connection.beginTransaction();

      // 1. Validaciones
      if (!data.asignacion_id || !data.estado_equipo) {
        throw new Error("Datos incompletos para devolución");
      }

      // 2. Obtener información de la asignación
      const asignacionSql = `
        SELECT a.*, i.* 
        FROM ${TABLA_ASIGNACIONES} a
        INNER JOIN inventario i ON a.inventario_id = i.id
        WHERE a.id = ?
      `;
      const asignaciones = await connection.query(asignacionSql, [data.asignacion_id]);

      if (asignaciones.length === 0) {
        throw new Error("Asignación no encontrada");
      }

      const asignacion = asignaciones[0];

      // 3. Crear acta de devolución
      const actaSql = `
        INSERT INTO ${TABLA_ACTAS} 
        (tipo, descripcion, fecha, usuario_creador_id, recibido_por_id)
        VALUES ('DEVOLUCION', ?, NOW(), ?, ?)
      `;
      
      const actaResult = await connection.query(actaSql, [
        data.motivo_devolucion || `Devolución de equipo ${asignacion.inventario_id}`,
        usuario.id,
        usuario.id // recibido_por
      ]);

      const actaId = actaResult.insertId;

      // 4. Crear detalle de acta
      const detalleSql = `
        INSERT INTO ${TABLA_ACTA_DETALLES} 
        (acta_id, inventario_id, estado_en_acta, comentarios)
        VALUES (?, ?, ?, ?)
      `;
      await connection.query(detalleSql, [
        actaId,
        asignacion.inventario_id,
        data.estado_equipo, // Estado físico del equipo
        data.motivo_devolucion || null
      ]);

      // 5. Registrar devolución
      const devolucionSql = `
        INSERT INTO ${TABLA_DEVOLUCIONES} 
        (asignacion_id, tecnico_id, sitio_venta_id, fecha_devolucion, usuario_receptor_id, estado_equipo, motivo_devolucion)
        VALUES (?, ?, ?, NOW(), ?, ?, ?)
      `;
      await connection.query(devolucionSql, [
        data.asignacion_id,
        asignacion.tecnico_id,
        asignacion.sitio_venta_id,
        usuario.id,
        data.estado_equipo,
        data.motivo_devolucion || null
      ]);

      // 6. Actualizar asignación e inventario
      const updateAsignacionSql = `
        UPDATE ${TABLA_ASIGNACIONES} 
        SET estado = 'devuelto' 
        WHERE id = ?
      `;
      await connection.query(updateAsignacionSql, [data.asignacion_id]);

      const updateInventarioSql = `
        UPDATE inventario 
        SET estado_asignacion = 'disponible', fecha_actualizacion = NOW() 
        WHERE id = ?
      `;
      await connection.query(updateInventarioSql, [asignacion.inventario_id]);

      await connection.commit();

      return {
        success: true,
        message: "Devolución procesada correctamente",
        acta_id: actaId,
        estado_equipo: data.estado_equipo
      };

    } catch (error) {
      await connection.rollback();
      console.error("❌ ERROR en procesarDevolucion:", error);
      throw error;
    } finally {
      connection.release();
    }
  }

  // 📊 OBTENER STOCK AGREGADO
  async function obtenerStockAgregado(usuario) {
    try {
      let sql = `
        SELECT 
          a.referencia,
          a.descripcion,
          a.tipo_articulo,
          c.nombre as categoria_nombre,
          m.nombre as marca_nombre,
          i.bodega,
          COUNT(i.id) as total_unidades,
          SUM(i.cantidad) as stock_total
        FROM inventario i
        INNER JOIN articulos a ON i.articulo_id = a.id
        LEFT JOIN categorias c ON a.categoria_id = c.id
        LEFT JOIN marcas m ON a.marca_id = m.id
        WHERE i.estado != 'Baja'
      `;

      const params = [];

      // Filtro por bodega si no es admin
      if (usuario.rol !== "administrador" && usuario.bodega) {
        sql += ` AND i.bodega = ?`;
        params.push(usuario.bodega);
      }

      sql += ` GROUP BY a.referencia, a.tipo_articulo, i.bodega 
               ORDER BY c.nombre, a.referencia, i.bodega`;

      const resultados = await db.consultaDirecta(sql, params);

      // Procesar para agrupar por referencia
      const stockAgrupado = {};
      
      resultados.forEach(row => {
        const key = `${row.referencia}_${row.tipo_articulo}`;
        
        if (!stockAgrupado[key]) {
          stockAgrupado[key] = {
            referencia: row.referencia,
            descripcion: row.descripcion,
            tipo_articulo: row.tipo_articulo,
            categoria_nombre: row.categoria_nombre,
            marca_nombre: row.marca_nombre,
            stock_por_bodega: {},
            stock_total: 0,
            unidades_totales: 0
          };
        }

        stockAgrupado[key].stock_por_bodega[row.bodega] = {
          stock: row.stock_total,
          unidades: row.total_unidades
        };

        stockAgrupado[key].stock_total += row.stock_total;
        stockAgrupado[key].unidades_totales += row.total_unidades;
      });

      return Object.values(stockAgrupado);

    } catch (error) {
      console.error("❌ ERROR en obtenerStockAgregado:", error);
      throw error;
    }
  }
  // 🔔 OBTENER NOTIFICACIONES DEL USUARIO
async function obtenerNotificaciones(usuario) {
  try {
    const sql = `
      SELECT 
        id,
        titulo,
        mensaje,
        tipo,
        leida,
        creado_en,
        leido_en
      FROM notificaciones 
      WHERE usuario_id = ?
      ORDER BY creado_en DESC
      LIMIT 50
    `;

    const notificaciones = await db.consultaDirecta(sql, [usuario.id]);

    return notificaciones;
  } catch (error) {
    console.error("❌ ERROR en obtenerNotificaciones:", error);
    throw error;
  }
}

// ✅ MARCAR NOTIFICACIÓN COMO LEÍDA
async function marcarNotificacionLeida(notificacionId, usuario) {
  try {
    const sql = `
      UPDATE notificaciones 
      SET leida = 1, leido_en = NOW() 
      WHERE id = ? AND usuario_id = ?
    `;

    const resultado = await db.consultaDirecta(sql, [notificacionId, usuario.id]);

    return {
      success: true,
      message: "Notificación marcada como leída",
      afectadas: resultado.affectedRows
    };
  } catch (error) {
    console.error("❌ ERROR en marcarNotificacionLeida:", error);
    throw error;
  }
}

// 📊 OBTENER ESTADÍSTICAS DE NOTIFICACIONES
async function obtenerEstadisticasNotificaciones(usuario) {
  try {
    const sql = `
      SELECT 
        COUNT(*) as total,
        SUM(leida = 0) as no_leidas,
        tipo,
        COUNT(*) as cantidad
      FROM notificaciones 
      WHERE usuario_id = ?
      GROUP BY tipo
    `;

    const estadisticas = await db.consultaDirecta(sql, [usuario.id]);

    return {
      total: estadisticas.reduce((sum, item) => sum + item.total, 0),
      no_leidas: estadisticas.reduce((sum, item) => sum + item.no_leidas, 0),
      por_tipo: estadisticas
    };
  } catch (error) {
    console.error("❌ ERROR en obtenerEstadisticasNotificaciones:", error);
    throw error;
  }
}

  return {
    asignacionMasiva,
    solicitarTransferencia,
    aprobarTransferencia,
    procesarDevolucion,
    obtenerStockAgregado,
    obtenerNotificaciones,
    obtenerEstadisticasNotificaciones,
    marcarNotificacionLeida
  };
};