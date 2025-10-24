const TABLA_ASIGNACIONES = "asignaciones";
const TABLA_INVENTARIO = "inventario";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  // 📋 Listar asignaciones activas
  async function todos(usuario, queryParams = {}) {
    try {
      const { page = 1, limit = 50, tecnico_id = '', estado = '' } = queryParams;
      const offset = (page - 1) * limit;

      let sql = `
        SELECT SQL_CALC_FOUND_ROWS
          a.id,
          a.fecha_asignacion,
          a.estado,
          a.observaciones,
          
          -- Info del técnico
          t.id as tecnico_id,
          t.nombre_completo as tecnico_nombre,
          t.identificacion as tecnico_identificacion,
          
          -- Info del inventario
          i.id as inventario_id,
          i.placa,
          i.serial,
          i.estado as estado_equipo,
          i.estado_asignacion,
          
          -- Info del artículo
          ar.referencia as articulo_referencia,
          ar.descripcion as articulo_descripcion,
          ar.tipo_articulo,
          
          -- Info del sitio de venta
          sv.id as sitio_venta_id,
          sv.codigo_sv,
          sv.sitio_venta,
          sv.direccion,
          sv.ciudad,
          sv.barrio,
          sv.latitud,
          sv.longitud,
          
          -- Info del usuario que asignó
          u.nombre_completo as asignador_nombre
          
        FROM ${TABLA_ASIGNACIONES} a
        INNER JOIN tecnicos t ON a.tecnico_id = t.id
        INNER JOIN inventario i ON a.inventario_id = i.id
        INNER JOIN articulos ar ON i.articulo_id = ar.id
        INNER JOIN sitios_venta sv ON a.sitio_venta_id = sv.id
        INNER JOIN usuarios u ON a.usuario_asignador_id = u.id
        WHERE 1=1
      `;

      const params = [];

      // 🔒 Filtro de seguridad por bodega del usuario
      if (usuario.rol !== "administrador" && usuario.bodega) {
        sql += ` AND i.bodega = ?`;
        params.push(usuario.bodega);
      }

      // 🔍 Filtros opcionales
      if (tecnico_id) {
        sql += ` AND a.tecnico_id = ?`;
        params.push(tecnico_id);
      }

      if (estado) {
        sql += ` AND a.estado = ?`;
        params.push(estado);
      }

      sql += ` ORDER BY a.fecha_asignacion DESC LIMIT ? OFFSET ?`;
      params.push(parseInt(limit), offset);

      const items = await db.consultaDirecta(sql, params);
      const countResult = await db.consultaDirecta('SELECT FOUND_ROWS() as total');
      const total = countResult[0].total;

      return {
        items,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages: Math.ceil(total / limit)
        }
      };
    } catch (error) {
      console.error("❌ ERROR AL CONSULTAR ASIGNACIONES:", error);
      throw error;
    }
  }

  // ➕ Crear nueva asignación
  async function asignar(data, usuario) {
    const connection = await db.getConnection();
    
    try {
      await connection.beginTransaction();

      // 1. Verificar que el item existe y está disponible
      const itemSql = `
        SELECT i.*, a.tipo_articulo 
        FROM inventario i 
        INNER JOIN articulos a ON i.articulo_id = a.id 
        WHERE i.id = ? AND i.estado != 'Baja'
      `;
      const item = await connection.query(itemSql, [data.inventario_id]);
      
      if (!item.length) {
        throw new Error("Item de inventario no encontrado o dado de baja");
      }

      if (item[0].estado_asignacion !== 'disponible') {
        throw new Error(`El item no está disponible. Estado actual: ${item[0].estado_asignacion}`);
      }

      // 2. Verificar que el técnico existe y está activo
      const tecnicoSql = `SELECT * FROM tecnicos WHERE id = ? AND activo = 1`;
      const tecnico = await connection.query(tecnicoSql, [data.tecnico_id]);
      
      if (!tecnico.length) {
        throw new Error("Técnico no encontrado o inactivo");
      }

      // 3. Verificar que el sitio de venta existe
      const sitiosSql = `SELECT * FROM sitios_venta WHERE id = ?`;
      const sitio = await connection.query(sitiosSql, [data.sitio_venta_id]);
      
      if (!sitio.length) {
        throw new Error("Sitio de venta no encontrado");
      }

      // 4. Crear la asignación
      const asignacionSql = `
        INSERT INTO ${TABLA_ASIGNACIONES} 
        (inventario_id, tecnico_id, sitio_venta_id, usuario_asignador_id, estado, observaciones, fecha_asignacion)
        VALUES (?, ?, ?, ?, 'asignado', ?, NOW())
      `;
      
      const resultado = await connection.query(asignacionSql, [
        data.inventario_id,
        data.tecnico_id,
        data.sitio_venta_id,
        usuario.id,
        data.observaciones || null
      ]);

      // 5. Actualizar estado del inventario (el trigger se encargará del historial)
      const updateInventarioSql = `
        UPDATE inventario 
        SET estado_asignacion = 'asignado', fecha_actualizacion = NOW() 
        WHERE id = ?
      `;
      await connection.query(updateInventarioSql, [data.inventario_id]);

      await connection.commit();

      return {
        message: "Asignación creada correctamente",
        id: resultado.insertId,
        inventario_id: data.inventario_id
      };

    } catch (error) {
      await connection.rollback();
      console.error("❌ ERROR AL CREAR ASIGNACIÓN:", error);
      throw error;
    } finally {
      connection.release();
    }
  }

  // 🔄 Actualizar estado de asignación
  async function actualizarEstado(id, nuevoEstado, usuario) {
    try {
      const estadosPermitidos = ['asignado', 'instalado', 'devuelto'];
      
      if (!estadosPermitidos.includes(nuevoEstado)) {
        throw new Error("Estado no válido");
      }

      // Obtener la asignación actual
      const asignacionSql = `SELECT * FROM ${TABLA_ASIGNACIONES} WHERE id = ?`;
      const asignacion = await db.consultaDirecta(asignacionSql, [id]);
      
      if (!asignacion.length) {
        throw new Error("Asignación no encontrada");
      }

      const asignacionActual = asignacion[0];

      // Actualizar estado de la asignación
      const updateAsignacionSql = `
        UPDATE ${TABLA_ASIGNACIONES} 
        SET estado = ?, fecha_actualizacion = NOW() 
        WHERE id = ?
      `;
      await db.consultaDirecta(updateAsignacionSql, [nuevoEstado, id]);

      // Si se devuelve, marcar el inventario como disponible
      if (nuevoEstado === 'devuelto') {
        const updateInventarioSql = `
          UPDATE inventario 
          SET estado_asignacion = 'disponible', fecha_actualizacion = NOW() 
          WHERE id = ?
        `;
        await db.consultaDirecta(updateInventarioSql, [asignacionActual.inventario_id]);
      }

      return {
        message: `Asignación actualizada a: ${nuevoEstado}`,
        id: parseInt(id),
        nuevo_estado: nuevoEstado
      };

    } catch (error) {
      console.error("❌ ERROR AL ACTUALIZAR ASIGNACIÓN:", error);
      throw error;
    }
  }

  // 📊 Obtener items disponibles para asignación
  async function inventarioDisponible(usuario, queryParams = {}) {
    try {
      const { tipo_articulo = '', categoria = '' } = queryParams;

      let sql = `
        SELECT 
          i.id,
          i.placa,
          i.serial,
          i.estado,
          i.estado_asignacion,
          i.bodega,
          i.ubicacion_detallada,
          
          a.referencia as articulo_referencia,
          a.descripcion as articulo_descripcion,
          a.tipo_articulo,
          
          c.nombre as categoria_nombre,
          m.nombre as marca_nombre
          
        FROM inventario i
        INNER JOIN articulos a ON i.articulo_id = a.id
        LEFT JOIN categorias c ON a.categoria_id = c.id
        LEFT JOIN marcas m ON a.marca_id = m.id
        WHERE i.estado != 'Baja' 
        AND i.estado_asignacion = 'disponible'
      `;

      const params = [];

      // 🔒 Filtro de seguridad por bodega
      if (usuario.rol !== "administrador" && usuario.bodega) {
        sql += ` AND i.bodega = ?`;
        params.push(usuario.bodega);
      }

      // 🔍 Filtros adicionales
      if (tipo_articulo) {
        sql += ` AND a.tipo_articulo = ?`;
        params.push(tipo_articulo);
      }

      if (categoria) {
        sql += ` AND c.nombre = ?`;
        params.push(categoria);
      }

      sql += ` ORDER BY a.referencia, i.placa`;

      const items = await db.consultaDirecta(sql, params);

      return { items };

    } catch (error) {
      console.error("❌ ERROR AL CONSULTAR INVENTARIO DISPONIBLE:", error);
      throw error;
    }
  }

  return {
    todos,
    asignar,
    actualizarEstado,
    inventarioDisponible
  };
};