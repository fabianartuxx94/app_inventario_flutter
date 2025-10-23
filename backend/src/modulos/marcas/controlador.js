const TABLA_INVENTARIO = "inventario";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  // 📋 Obtener inventario con filtros y paginación
  async function todos(usuario, queryParams = {}) {
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

      let sql = `
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
      if (usuario.rol !== "administrador" && usuario.bodega !== null) {
        sql += ` AND i.bodega = ?`;
        params.push(usuario.bodega);
      }

      // 🔍 Búsqueda global (incluye categoría)
      if (search) {
        sql += ` AND (
          a.referencia LIKE ? OR 
          a.descripcion LIKE ? OR 
          i.placa LIKE ? OR 
          i.serial LIKE ? OR
          c.nombre LIKE ?
        )`;
        const searchTerm = `%${search}%`;
        params.push(searchTerm, searchTerm, searchTerm, searchTerm, searchTerm);
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

      // 📊 Contar total (para paginación)
      const countSql = `SELECT COUNT(*) as total FROM (${sql}) AS filtered`;
      const countResult = await db.consultaDirecta(countSql, params);
      const total = countResult[0].total;

      // 📄 Aplicar paginación y ordenamiento
      sql += ` ORDER BY i.fecha_actualizacion DESC LIMIT ? OFFSET ?`;
      params.push(parseInt(limit), offset);

      const items = await db.consultaDirecta(sql, params);

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
      console.error("❌ ERROR AL CONSULTAR INVENTARIO:", error);
      throw error;
    }
  }

  // 🔍 Obtener un registro específico
  async function uno(id, usuario) {
    try {
      const sql = `
        SELECT 
          i.*,
          a.*,
          c.nombre AS categoria_nombre,
          c.stock_minimo,
          m.nombre AS marca_nombre,
          u.nombre_completo AS usuario_creador
        FROM inventario i
        INNER JOIN articulos a ON i.articulo_id = a.id
        LEFT JOIN categorias c ON a.categoria_id = c.id
        LEFT JOIN marcas m ON a.marca_id = m.id
        LEFT JOIN usuarios u ON i.usuario_id = u.id
        WHERE i.id = ?
      `;

      const resultado = await db.consultaDirecta(sql, [id]);
      if (!resultado.length) throw new Error("Registro no encontrado");

      const registro = resultado[0];

      // ✅ Verificar permisos
      if (usuario.rol === "administrador" || 
          usuario.bodega === null || 
          usuario.bodega === registro.bodega) {
        return registro;
      }

      throw new Error("No tienes permiso para ver este registro");
    } catch (error) {
      console.error("❌ ERROR AL CONSULTAR REGISTRO:", error);
      throw error;
    }
  }

  // 📊 Obtener opciones de filtros disponibles
  async function filtrosDisponibles(usuario) {
    try {
      const sql = `
        SELECT 
          JSON_ARRAYAGG(DISTINCT i.estado) as estados,
          JSON_ARRAYAGG(DISTINCT i.bodega) as bodegas,
          JSON_ARRAYAGG(DISTINCT a.tipo_bodega) as tipos_bodega,
          JSON_ARRAYAGG(DISTINCT a.tipo_articulo) as tipos_articulo,
          JSON_ARRAYAGG(DISTINCT m.nombre) as marcas,
          JSON_ARRAYAGG(DISTINCT c.nombre) as categorias
        FROM inventario i
        INNER JOIN articulos a ON i.articulo_id = a.id
        LEFT JOIN marcas m ON a.marca_id = m.id
        LEFT JOIN categorias c ON a.categoria_id = c.id
        WHERE i.estado != 'Baja'
      `;

      const params = [];
      if (usuario.rol !== "administrador" && usuario.bodega !== null) {
        sql += ` AND i.bodega = ?`;
        params.push(usuario.bodega);
      }

      const resultado = await db.consultaDirecta(sql, params);
      return resultado[0] || {};
    } catch (error) {
      console.error("❌ ERROR AL OBTENER FILTROS:", error);
      throw error;
    }
  }

  return { todos, uno, filtrosDisponibles };
};