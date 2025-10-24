const TABLA_ACTAS = "actas";
const TABLA_ACTA_DETALLES = "acta_detalles";
const TABLA_INVENTARIO = "inventario";
const TABLA_ARTICULOS = "articulos";
const TABLA_USUARIOS = "usuarios";
const TABLA_PERSONAL = "personal";
const TABLA_TECNICOS = "tecnicos";
const TABLA_SITIOS_VENTA = "sitios_venta";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  // 📋 LISTAR ACTAS CON PAGINACIÓN Y FILTROS
  async function listarActas(usuario, queryParams = {}) {
    try {
      const { page = 1, limit = 20, tipo = '', fecha_desde = '', fecha_hasta = '' } = queryParams;
      const offset = (page - 1) * limit;

      let sql = `
        SELECT SQL_CALC_FOUND_ROWS
          a.id,
          a.tipo,
          a.descripcion,
          a.fecha,
          a.archivo_pdf,
          
          -- Información del usuario creador
          uc.nombre_completo as creador_nombre,
          uc.username as creador_username,
          
          -- Información del personal involucrado
          ep.nombre as entregado_por_nombre,
          rp.nombre as recibido_por_nombre,
          ap.nombre as auditor_nombre,
          
          -- Contador de items en el acta
          (SELECT COUNT(*) FROM acta_detalles ad WHERE ad.acta_id = a.id) as total_items,
          
          -- Fecha formateada
          DATE_FORMAT(a.fecha, '%d/%m/%Y %H:%i') as fecha_formateada
          
        FROM ${TABLA_ACTAS} a
        LEFT JOIN ${TABLA_USUARIOS} uc ON a.usuario_creador_id = uc.id
        LEFT JOIN ${TABLA_PERSONAL} ep ON a.entregado_por_id = ep.id
        LEFT JOIN ${TABLA_PERSONAL} rp ON a.recibido_por_id = rp.id
        LEFT JOIN ${TABLA_PERSONAL} ap ON a.auditor_id = ap.id
        WHERE 1=1
      `;

      const params = [];

      // 🔒 Filtro de seguridad por bodega (si no es admin)
      if (usuario.rol !== "administrador") {
        // Solo actas donde el usuario creador es el mismo o está relacionado con su bodega
        sql += ` AND a.usuario_creador_id = ?`;
        params.push(usuario.id);
      }

      // 🔍 Filtros opcionales
      if (tipo) {
        sql += ` AND a.tipo = ?`;
        params.push(tipo);
      }

      if (fecha_desde) {
        sql += ` AND DATE(a.fecha) >= ?`;
        params.push(fecha_desde);
      }

      if (fecha_hasta) {
        sql += ` AND DATE(a.fecha) <= ?`;
        params.push(fecha_hasta);
      }

      sql += ` ORDER BY a.fecha DESC, a.id DESC LIMIT ? OFFSET ?`;
      params.push(parseInt(limit), offset);

      // Ejecutar consulta
      const actas = await db.consultaDirecta(sql, params);
      
      // Obtener total
      const countResult = await db.consultaDirecta('SELECT FOUND_ROWS() as total');
      const total = countResult[0].total;

      return {
        actas,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages: Math.ceil(total / limit)
        }
      };

    } catch (error) {
      console.error("❌ ERROR en listarActas:", error);
      throw error;
    }
  }

  // 🔍 OBTENER DETALLES COMPLETOS DE UN ACTA
  async function obtenerActaCompleta(actaId, usuario) {
    try {
      // 1. Obtener información base del acta
      const actaSql = `
        SELECT 
          a.*,
          uc.nombre_completo as creador_nombre,
          uc.username as creador_username,
          ep.nombre as entregado_por_nombre,
          rp.nombre as recibido_por_nombre,
          ap.nombre as auditor_nombre,
          DATE_FORMAT(a.fecha, '%d/%m/%Y a las %H:%i') as fecha_formateada
        FROM ${TABLA_ACTAS} a
        LEFT JOIN ${TABLA_USUARIOS} uc ON a.usuario_creador_id = uc.id
        LEFT JOIN ${TABLA_PERSONAL} ep ON a.entregado_por_id = ep.id
        LEFT JOIN ${TABLA_PERSONAL} rp ON a.recibido_por_id = rp.id
        LEFT JOIN ${TABLA_PERSONAL} ap ON a.auditor_id = ap.id
        WHERE a.id = ?
      `;

      const actaResult = await db.consultaDirecta(actaSql, [actaId]);
      
      if (actaResult.length === 0) {
        throw new Error("Acta no encontrada");
      }

      const acta = actaResult[0];

      // 🔒 Verificar permisos (solo admin o usuario creador)
      if (usuario.rol !== "administrador" && acta.usuario_creador_id !== usuario.id) {
        throw new Error("No tienes permiso para ver este acta");
      }

      // 2. Obtener detalles del acta
      const detallesSql = `
        SELECT 
          ad.*,
          i.placa,
          i.serial,
          i.estado as estado_actual,
          i.bodega,
          i.ubicacion_detallada,
          a.referencia as articulo_referencia,
          a.descripcion as articulo_descripcion,
          a.tipo_articulo,
          c.nombre as categoria_nombre,
          m.nombre as marca_nombre,
          
          -- Información adicional según el tipo de acta
          CASE 
            WHEN act.tipo = 'ASIGNACION' THEN (
              SELECT CONCAT(t.nombre_completo, ' - ', sv.sitio_venta)
              FROM asignaciones asig
              LEFT JOIN tecnicos t ON asig.tecnico_id = t.id
              LEFT JOIN sitios_venta sv ON asig.sitio_venta_id = sv.id
              WHERE asig.inventario_id = ad.inventario_id 
              AND asig.fecha_asignacion >= act.fecha
              LIMIT 1
            )
            WHEN act.tipo = 'TRANSFERENCIA' THEN (
              SELECT CONCAT('De: ', t.bodega_origen, ' a: ', t.bodega_destino)
              FROM transferencias_bodegas t
              WHERE t.inventario_id = ad.inventario_id 
              AND t.acta_id = act.id
              LIMIT 1
            )
            WHEN act.tipo = 'DEVOLUCION' THEN (
              SELECT CONCAT('Estado: ', d.estado_equipo, ' - ', COALESCE(d.motivo_devolucion, ''))
              FROM devoluciones d
              WHERE d.asignacion_id IN (
                SELECT asig.id FROM asignaciones asig 
                WHERE asig.inventario_id = ad.inventario_id
              )
              AND d.fecha_devolucion >= act.fecha
              LIMIT 1
            )
            ELSE NULL
          END as informacion_adicional
          
        FROM ${TABLA_ACTA_DETALLES} ad
        INNER JOIN ${TABLA_INVENTARIO} i ON ad.inventario_id = i.id
        INNER JOIN ${TABLA_ARTICULOS} a ON i.articulo_id = a.id
        LEFT JOIN categorias c ON a.categoria_id = c.id
        LEFT JOIN marcas m ON a.marca_id = m.id
        INNER JOIN ${TABLA_ACTAS} act ON ad.acta_id = act.id
        WHERE ad.acta_id = ?
        ORDER BY a.referencia, i.placa
      `;

      const detalles = await db.consultaDirecta(detallesSql, [actaId]);

      // 3. Obtener estadísticas del acta
      const estadisticasSql = `
        SELECT 
          COUNT(*) as total_items,
          COUNT(DISTINCT a.tipo_articulo) as tipos_articulo,
          COUNT(DISTINCT i.bodega) as bodegas_afectadas,
          GROUP_CONCAT(DISTINCT a.tipo_articulo) as lista_tipos
        FROM ${TABLA_ACTA_DETALLES} ad
        INNER JOIN ${TABLA_INVENTARIO} i ON ad.inventario_id = i.id
        INNER JOIN ${TABLA_ARTICULOS} a ON i.articulo_id = a.id
        WHERE ad.acta_id = ?
      `;

      const estadisticas = await db.consultaDirecta(estadisticasSql, [actaId]);

      return {
        acta: {
          ...acta,
          estadisticas: estadisticas[0] || {}
        },
        detalles: detalles
      };

    } catch (error) {
      console.error("❌ ERROR en obtenerActaCompleta:", error);
      throw error;
    }
  }

  // 📊 OBTENER ESTADÍSTICAS DE ACTAS
  async function obtenerEstadisticasActas(usuario, filtros = {}) {
    try {
      const { fecha_desde = '', fecha_hasta = '' } = filtros;

      let sql = `
        SELECT 
          tipo,
          COUNT(*) as total_actas,
          SUM(
            (SELECT COUNT(*) FROM acta_detalles ad WHERE ad.acta_id = a.id)
          ) as total_items,
          MIN(fecha) as fecha_primer_acta,
          MAX(fecha) as fecha_ultima_acta
        FROM ${TABLA_ACTAS} a
        WHERE 1=1
      `;

      const params = [];

      // 🔒 Filtro de seguridad
      if (usuario.rol !== "administrador") {
        sql += ` AND usuario_creador_id = ?`;
        params.push(usuario.id);
      }

      // Filtros de fecha
      if (fecha_desde) {
        sql += ` AND DATE(fecha) >= ?`;
        params.push(fecha_desde);
      }

      if (fecha_hasta) {
        sql += ` AND DATE(fecha) <= ?`;
        params.push(fecha_hasta);
      }

      sql += ` GROUP BY tipo ORDER BY total_actas DESC`;

      const estadisticas = await db.consultaDirecta(sql, params);

      // Estadísticas generales
      const generalSql = `
        SELECT 
          COUNT(*) as total_actas,
          COUNT(DISTINCT usuario_creador_id) as usuarios_activos,
          SUM(
            (SELECT COUNT(*) FROM acta_detalles ad WHERE ad.acta_id = a.id)
          ) as total_items_movidos,
          MIN(fecha) as fecha_inicio_sistema,
          MAX(fecha) as fecha_ultima_actividad
        FROM ${TABLA_ACTAS} a
        WHERE 1=1
      `;

      const generalParams = [];
      if (usuario.rol !== "administrador") {
        generalSql += ` AND usuario_creador_id = ?`;
        generalParams.push(usuario.id);
      }

      const general = await db.consultaDirecta(generalSql, generalParams);

      return {
        por_tipo: estadisticas,
        general: general[0] || {}
      };

    } catch (error) {
      console.error("❌ ERROR en obtenerEstadisticasActas:", error);
      throw error;
    }
  }

  // 🎛️ OBTENER FILTROS DISPONIBLES PARA ACTAS
  async function obtenerFiltrosDisponibles(usuario) {
    try {
      let sql = `
        SELECT 
          tipo,
          COUNT(*) as cantidad
        FROM ${TABLA_ACTAS} 
        WHERE 1=1
      `;

      const params = [];

      if (usuario.rol !== "administrador") {
        sql += ` AND usuario_creador_id = ?`;
        params.push(usuario.id);
      }

      sql += ` GROUP BY tipo ORDER BY tipo`;

      const tipos = await db.consultaDirecta(sql, params);

      // Obtener rangos de fechas
      const fechasSql = `
        SELECT 
          MIN(DATE(fecha)) as fecha_minima,
          MAX(DATE(fecha)) as fecha_maxima
        FROM ${TABLA_ACTAS} 
        WHERE 1=1
      `;

      const fechasParams = [];
      if (usuario.rol !== "administrador") {
        fechasSql += ` AND usuario_creador_id = ?`;
        fechasParams.push(usuario.id);
      }

      const fechas = await db.consultaDirecta(fechasSql, fechasParams);

      return {
        tipos: tipos.map(t => t.tipo),
        fechas: fechas[0] || { fecha_minima: null, fecha_maxima: null }
      };

    } catch (error) {
      console.error("❌ ERROR en obtenerFiltrosDisponibles:", error);
      throw error;
    }
  }

  // 📄 GENERAR PDF DEL ACTA (placeholder - integración futura)
  async function generarPdfActa(actaId, usuario) {
    try {
      // Primero verificar permisos
      const actaSql = `SELECT * FROM ${TABLA_ACTAS} WHERE id = ?`;
      const acta = await db.consultaDirecta(actaSql, [actaId]);

      if (acta.length === 0) {
        throw new Error("Acta no encontrada");
      }

      if (usuario.rol !== "administrador" && acta[0].usuario_creador_id !== usuario.id) {
        throw new Error("No tienes permiso para generar PDF de este acta");
      }

      // Por ahora retornamos información para el PDF
      // En una implementación real, aquí se integraría con una librería de PDF
      return {
        success: true,
        message: "PDF generado exitosamente (simulación)",
        acta_id: actaId,
        pdf_url: `/api/actas/${actaId}/pdf`, // Endpoint ficticio para el PDF
        datos_acta: {
          ...acta[0],
          fecha_generacion: new Date().toISOString()
        }
      };

    } catch (error) {
      console.error("❌ ERROR en generarPdfActa:", error);
      throw error;
    }
  }

  return {
    listarActas,
    obtenerActaCompleta,
    obtenerEstadisticasActas,
    obtenerFiltrosDisponibles,
    generarPdfActa
  };
};