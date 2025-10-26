const TABLA_INVENTARIO = "inventario";
const cacheManager = require("../../utils/cache");
const { AppLogger } = require("../../utils/logger");
const logger = new AppLogger('inventario');

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  // 🔍 Determina si el usuario puede modificar o crear registros
  function puedeModificar(usuario, bodegaRegistro) {
    const esAdmin = usuario.rol === "administrador";
    const tieneBodega = usuario.bodega !== null;

    if (esAdmin) return true;
    if (!tieneBodega) return false;
    return usuario.bodega === bodegaRegistro;
  }

  // 📋 LISTAR INVENTARIO OPTIMIZADO
  async function todos(usuario, queryParams = {}) {
    const startTime = Date.now();
    
    try {
      const {
        page = 1,
        limit = 50,
        search = '',
        estado = '',
        bodega = '',
        tipo_bodega = '',
        marca = '',
        tipo_articulo = ''
      } = queryParams;

      const offset = (page - 1) * limit;

      // 🎯 CONSULTA OPTIMIZADA CON ÍNDICES
      let sql = `
        SELECT SQL_CALC_FOUND_ROWS
          i.id,
          i.articulo_id,
          i.placa,
          i.serial,
          i.estado,
          i.cantidad,
          i.bodega,
          i.ubicacion_detallada,
          i.fecha_creacion,
          i.fecha_actualizacion,
          i.estado_asignacion,
          a.referencia AS articulo_referencia,
          a.descripcion AS articulo_descripcion,
          a.tipo_articulo,
          a.tipo_bodega,
          c.nombre AS categoria_nombre,
          m.nombre AS marca_nombre
        FROM inventario i
        INNER JOIN articulos a ON i.articulo_id = a.id
        LEFT JOIN categorias c ON a.categoria_id = c.id
        LEFT JOIN marcas m ON a.marca_id = m.id
        WHERE i.estado != 'Baja'
      `;

      const params = [];

      // 🔒 Filtro de seguridad por bodega
      if (usuario.rol !== "administrador" && usuario.bodega) {
        sql += ` AND i.bodega = ?`;
        params.push(usuario.bodega);
      }

      // 🔍 Búsqueda optimizada
      if (search) {
        sql += ` AND (
          a.referencia LIKE ? OR 
          i.placa LIKE ? OR 
          i.serial LIKE ? OR
          a.descripcion LIKE ?
        )`;
        const searchTerm = `%${search}%`;
        params.push(searchTerm, searchTerm, searchTerm, searchTerm);
      }

      // 🏢 Filtros por atributo
      if (estado) {
        sql += ` AND i.estado = ?`;
        params.push(estado);
      }
      if (bodega) {
        sql += ` AND i.bodega = ?`;
        params.push(bodega);
      }
      if (tipo_bodega) {
        sql += ` AND a.tipo_bodega = ?`;
        params.push(tipo_bodega);
      }
      if (marca) {
        sql += ` AND m.nombre = ?`;
        params.push(marca);
      }
      if (tipo_articulo) {
        sql += ` AND a.tipo_articulo = ?`;
        params.push(tipo_articulo);
      }

      // 📄 Paginación con índice
      sql += ` ORDER BY i.fecha_actualizacion DESC LIMIT ? OFFSET ?`;
      params.push(parseInt(limit), offset);

      // 🚀 Ejecutar consulta
      const items = await db.consultaDirecta(sql, params);
      const countResult = await db.consultaDirecta('SELECT FOUND_ROWS() as total');
      const total = countResult[0].total;

      const duration = Date.now() - startTime;
      logger.database(sql, duration, { params, rows: items.length });

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
      logger.error("Error consultando inventario", { error: error.message, queryParams });
      throw error;
    }
  }

  // 🔍 CONSULTAR UN REGISTRO CON CACHE
  async function uno(id, usuario) {
    const cacheKey = `inventario_${id}_${usuario.id}`;
    
    return cacheManager.get('consultas', cacheKey, async () => {
      try {
        const sql = `
          SELECT 
            i.id,
            i.articulo_id,
            i.placa,
            i.serial,
            i.estado,
            i.cantidad,
            i.bodega,
            i.ubicacion_detallada,
            i.fecha_creacion,
            i.fecha_actualizacion,
            i.estado_asignacion,
            a.referencia AS articulo_referencia,
            a.descripcion AS articulo_descripcion,
            a.tipo_articulo,
            a.tipo_bodega,
            m.id AS marca_id,
            m.nombre AS marca_nombre,
            c.id AS categoria_id,
            c.nombre AS categoria_nombre,
            u.id AS usuario_id,
            u.username AS usuario_creador,
            u.nombre_completo AS usuario_nombre
          FROM inventario i
          INNER JOIN articulos a ON i.articulo_id = a.id
          LEFT JOIN marcas m ON a.marca_id = m.id
          LEFT JOIN categorias c ON a.categoria_id = c.id
          INNER JOIN usuarios u ON i.usuario_id = u.id
          WHERE i.id = ?
        `;

        const resultado = await db.consultaDirecta(sql, [id]);
        if (!resultado.length) throw new Error("Registro no encontrado");

        const registro = resultado[0];

        // ✅ Validar permisos
        if (
          usuario.rol === "administrador" ||
          usuario.bodega === null ||
          usuario.bodega === registro.bodega
        ) {
          return registro;
        }

        throw new Error("No tienes permiso para ver este registro");
      } catch (error) {
        logger.error("Error consultando inventario por ID", { id, error: error.message });
        throw error;
      }
    }, 300); // Cache por 5 minutos
  }

  // ➕ CREAR NUEVO REGISTRO
  async function agregar(data, usuario) {
    const connection = await db.getConnection();
    
    try {
      await connection.beginTransaction();

      if (!puedeModificar(usuario, data.bodega)) {
        throw new Error("No tienes permiso para crear en esta bodega");
      }

      const sql = `
        INSERT INTO ${TABLA_INVENTARIO}
        (articulo_id, placa, serial, estado, estado_asignacion, cantidad, bodega, ubicacion_detallada, usuario_id, fecha_creacion, fecha_actualizacion)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
      `;
      
      const resultado = await connection.query(sql, [
        data.articulo_id,
        data.placa || null,
        data.serial || null,
        data.estado,
        data.estado_asignacion || 'disponible',
        data.cantidad || 1,
        data.bodega,
        data.ubicacion_detallada || null,
        usuario.id,
      ]);

      await connection.commit();

      // 🧹 Invalidar caches relevantes
      cacheManager.del('filtros', `filtros_${usuario.id}_${usuario.bodega || 'all'}`);
      cacheManager.findKeys('consultas', `inventario_`).forEach(key => {
        cacheManager.del('consultas', key);
      });

      logger.business('crear', 'inventario', resultado.insertId, usuario);

      return {
        message: "Inventario agregado correctamente",
        id: resultado.insertId,
      };
    } catch (error) {
      await connection.rollback();
      logger.error("Error agregando inventario", { data, error: error.message });
      throw error;
    } finally {
      connection.release();
    }
  }

  // 🔄 ACTUALIZAR REGISTRO
  async function actualizar(id, data, usuario) {
    const connection = await db.getConnection();
    
    try {
      await connection.beginTransaction();

      // Verificar existencia y permisos
      const registro = await connection.query(
        `SELECT bodega FROM ${TABLA_INVENTARIO} WHERE id = ?`,
        [id]
      );

      if (!registro.length) throw new Error("Registro no encontrado");
      const bodegaRegistro = registro[0].bodega;

      if (!puedeModificar(usuario, bodegaRegistro)) {
        throw new Error("No tienes permiso para modificar este registro");
      }

      const sql = `
        UPDATE ${TABLA_INVENTARIO}
        SET 
          articulo_id=?, 
          placa=?, 
          serial=?, 
          estado=?, 
          estado_asignacion=?, 
          cantidad=?, 
          bodega=?, 
          ubicacion_detallada=?, 
          usuario_id=?, 
          fecha_actualizacion=NOW()
        WHERE id=?
      `;
      
      await connection.query(sql, [
        data.articulo_id,
        data.placa || null,
        data.serial || null,
        data.estado,
        data.estado_asignacion || 'disponible',
        data.cantidad || 1,
        data.bodega,
        data.ubicacion_detallada || null,
        usuario.id,
        id,
      ]);

      await connection.commit();

      // 🧹 Invalidar caches
      cacheManager.del('filtros', `filtros_${usuario.id}_${usuario.bodega || 'all'}`);
      cacheManager.del('consultas', `inventario_${id}_${usuario.id}`);
      cacheManager.findKeys('consultas', `inventario_`).forEach(key => {
        cacheManager.del('consultas', key);
      });

      logger.business('actualizar', 'inventario', id, usuario);

      return {
        message: "Inventario actualizado correctamente",
        id: parseInt(id),
      };
    } catch (error) {
      await connection.rollback();
      logger.error("Error actualizando inventario", { id, error: error.message });
      throw error;
    } finally {
      connection.release();
    }
  }

  // 🗑️ ELIMINAR REGISTRO
  async function eliminar(id, usuario) {
    const connection = await db.getConnection();
    
    try {
      await connection.beginTransaction();

      const registro = await connection.query(
        `SELECT bodega FROM ${TABLA_INVENTARIO} WHERE id = ?`,
        [id]
      );

      if (!registro.length) throw new Error("Registro no encontrado");
      const bodegaRegistro = registro[0].bodega;

      if (!puedeModificar(usuario, bodegaRegistro)) {
        throw new Error("No tienes permiso para eliminar este registro");
      }

      await connection.query(`DELETE FROM ${TABLA_INVENTARIO} WHERE id = ?`, [id]);
      await connection.commit();

      // 🧹 Invalidar caches
      cacheManager.del('filtros', `filtros_${usuario.id}_${usuario.bodega || 'all'}`);
      cacheManager.del('consultas', `inventario_${id}_${usuario.id}`);

      logger.business('eliminar', 'inventario', id, usuario);

      return {
        message: "Inventario eliminado correctamente",
        id: parseInt(id),
      };
    } catch (error) {
      await connection.rollback();
      logger.error("Error eliminando inventario", { id, error: error.message });
      throw error;
    } finally {
      connection.release();
    }
  }

  // 📊 FILTROS DISPONIBLES CON CACHE AVANZADO
  async function filtrosDisponibles(usuario) {
    const cacheKey = `filtros_${usuario.id}_${usuario.bodega || 'all'}`;
    
    return cacheManager.get('filtros', cacheKey, async () => {
      try {
        const params = usuario.rol !== "administrador" && usuario.bodega !== null ? [usuario.bodega] : [];

        // 🚀 CONSULTA ÚNICA OPTIMIZADA
        const sql = `
          SELECT 'estados' as tipo, estado as valor FROM inventario 
          WHERE estado != 'Baja' ${params.length ? 'AND bodega = ?' : ''}
          UNION ALL
          SELECT 'bodegas' as tipo, bodega as valor FROM inventario 
          WHERE estado != 'Baja' ${params.length ? 'AND bodega = ?' : ''}
          UNION ALL
          SELECT 'tipos_bodega' as tipo, a.tipo_bodega as valor 
          FROM inventario i INNER JOIN articulos a ON i.articulo_id = a.id
          WHERE i.estado != 'Baja' ${params.length ? 'AND i.bodega = ?' : ''}
          UNION ALL
          SELECT 'tipos_articulo' as tipo, a.tipo_articulo as valor 
          FROM inventario i INNER JOIN articulos a ON i.articulo_id = a.id
          WHERE i.estado != 'Baja' ${params.length ? 'AND i.bodega = ?' : ''}
          UNION ALL
          SELECT 'marcas' as tipo, m.nombre as valor 
          FROM inventario i 
          INNER JOIN articulos a ON i.articulo_id = a.id
          LEFT JOIN marcas m ON a.marca_id = m.id
          WHERE i.estado != 'Baja' AND m.nombre IS NOT NULL ${params.length ? 'AND i.bodega = ?' : ''}
          UNION ALL
          SELECT 'categorias' as tipo, c.nombre as valor 
          FROM inventario i 
          INNER JOIN articulos a ON i.articulo_id = a.id
          LEFT JOIN categorias c ON a.categoria_id = c.id
          WHERE i.estado != 'Baja' AND c.nombre IS NOT NULL ${params.length ? 'AND i.bodega = ?' : ''}
          UNION ALL
          SELECT 'estados_asignacion' as tipo, estado_asignacion as valor 
          FROM inventario 
          WHERE estado != 'Baja' ${params.length ? 'AND bodega = ?' : ''}
        `;

        // Replicar parámetros para cada UNION
        const allParams = [...params, ...params, ...params, ...params, ...params, ...params, ...params];
        const resultados = await db.consultaDirecta(sql, allParams);
        
        // 🎯 PROCESAR RESULTADOS
        const resultadoFinal = {
          estados: [],
          bodegas: [],
          tipos_bodega: [],
          tipos_articulo: [],
          marcas: [],
          categorias: [],
          estados_asignacion: []
        };

        resultados.forEach(row => {
          if (row.valor) {
            resultadoFinal[row.tipo]?.push(row.valor);
          }
        });

        // 🧹 ELIMINAR DUPLICADOS Y ORDENAR
        Object.keys(resultadoFinal).forEach(key => {
          resultadoFinal[key] = [...new Set(resultadoFinal[key])].sort();
        });

        logger.debug('Filtros generados', { 
          totalOpciones: resultados.length,
          usuario: usuario.id 
        });

        return resultadoFinal;
      } catch (error) {
        logger.error("Error obteniendo filtros", { error: error.message });
        
        // 🆘 VALORES POR DEFECTO EN CASO DE ERROR
        return {
          estados: ['Nuevo', 'Bueno', 'Reparacion'],
          bodegas: usuario.bodega ? [usuario.bodega] : ['Bodega Principal', 'Bodega Garzon', 'Bodega Pitalito'],
          tipos_bodega: ['BMD', 'Sistemas'],
          tipos_articulo: ['Activo Fijo', 'Activo de Control', 'Consumible'],
          marcas: [],
          categorias: [],
          estados_asignacion: ['disponible', 'asignado', 'instalado', 'en_mantenimiento']
        };
      }
    }, 300); // Cache por 5 minutos
  }

  return { 
    todos, 
    uno, 
    agregar, 
    actualizar, 
    eliminar, 
    filtrosDisponibles 
  };
};