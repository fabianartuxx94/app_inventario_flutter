const TABLA_INVENTARIO = "inventario";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  // 🔍 Determina si el usuario puede modificar o crear registros
  function puedeModificar(usuario, bodegaRegistro) {
    const esAdmin = usuario.rol === "administrador";
    const tieneBodega = usuario.bodega !== null;

    // ✅ Administrador: acceso total
    if (esAdmin) return true;

    // 🚫 Usuario sin bodega: solo lectura
    if (!tieneBodega) return false;

    // ✅ Bodega asignada: solo su propia bodega
    return usuario.bodega === bodegaRegistro;
  }

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

  // 🔍 Consultar un registro específico
  async function uno(id, usuario) {
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

          a.referencia AS articulo_referencia,
          a.descripcion AS articulo_descripcion,
          a.tipo_articulo,
          a.tipo_bodega,

          m.id AS marca_id,
          m.nombre AS marca_nombre,

          c.id AS categoria_id,
          c.nombre AS categoria_nombre,
          c.stock_minimo,

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

      // ✅ Permisos: admin ve todo, usuario sin bodega ve todo
      if (
        usuario.rol === "administrador" ||
        usuario.bodega === null ||
        usuario.bodega === registro.bodega
      ) {
        return registro;
      }

      throw new Error("No tienes permiso para ver este registro");
    } catch (error) {
      console.error("❌ ERROR AL CONSULTAR INVENTARIO POR ID:", error);
      throw error;
    }
  }

  // ➕ Crear nuevo registro
  async function agregar(data, usuario) {
    try {
      if (!puedeModificar(usuario, data.bodega)) {
        throw new Error("No tienes permiso para crear en esta bodega");
      }

      const sql = `
        INSERT INTO ${TABLA_INVENTARIO}
        (articulo_id, placa, serial, estado, cantidad, bodega, ubicacion_detallada, usuario_id, fecha_creacion, fecha_actualizacion)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
      `;
      const resultado = await db.consultaDirecta(sql, [
        data.articulo_id,
        data.placa || null,
        data.serial || null,
        data.estado,
        data.cantidad || 1,
        data.bodega,
        data.ubicacion_detallada || null,
        usuario.id,
      ]);

      return {
        message: "Inventario agregado correctamente",
        id: resultado.insertId,
      };
    } catch (error) {
      console.error("❌ ERROR AL AGREGAR INVENTARIO:", error);
      throw error;
    }
  }

  // 🔄 Actualizar un registro
  async function actualizar(id, data, usuario) {
    try {
      const registro = await db.consultaDirecta(
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
        SET articulo_id=?, placa=?, serial=?, estado=?, cantidad=?, bodega=?, ubicacion_detallada=?, usuario_id=?, fecha_actualizacion=NOW()
        WHERE id=?
      `;
      await db.consultaDirecta(sql, [
        data.articulo_id,
        data.placa || null,
        data.serial || null,
        data.estado,
        data.cantidad || 1,
        data.bodega,
        data.ubicacion_detallada || null,
        usuario.id,
        id,
      ]);

      return {
        message: "Inventario actualizado correctamente",
        id: parseInt(id),
      };
    } catch (error) {
      console.error("❌ ERROR AL ACTUALIZAR INVENTARIO:", error);
      throw error;
    }
  }

  // 🗑️ Eliminar registro
  async function eliminar(id, usuario) {
    try {
      const registro = await db.consultaDirecta(
        `SELECT bodega FROM ${TABLA_INVENTARIO} WHERE id = ?`,
        [id]
      );

      if (!registro.length) throw new Error("Registro no encontrado");
      const bodegaRegistro = registro[0].bodega;

      if (!puedeModificar(usuario, bodegaRegistro)) {
        throw new Error("No tienes permiso para eliminar este registro");
      }

      await db.consultaDirecta(`DELETE FROM ${TABLA_INVENTARIO} WHERE id = ?`, [id]);
      return {
        message: "Inventario eliminado correctamente",
        id: parseInt(id),
      };
    } catch (error) {
      console.error("❌ ERROR AL ELIMINAR INVENTARIO:", error);
      throw error;
    }
  }

// 📊 Obtener opciones de filtros disponibles
async function filtrosDisponibles(usuario) {
  try {
    console.log('🔄 Usuario solicitando filtros:', usuario.id, usuario.rol, usuario.bodega);
    
    const params = usuario.rol !== "administrador" && usuario.bodega !== null ? [usuario.bodega] : [];
    console.log('📊 Parámetros de seguridad:', params);

    // Definir las consultas SQL
    const consultas = {
      estados: `
        SELECT DISTINCT estado 
        FROM inventario 
        WHERE estado != 'Baja'
        ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND bodega = ?' : ''}
      `,
      bodegas: `
        SELECT DISTINCT bodega 
        FROM inventario 
        WHERE estado != 'Baja'
        ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND bodega = ?' : ''}
      `,
      tipos_bodega: `
        SELECT DISTINCT a.tipo_bodega 
        FROM inventario i
        INNER JOIN articulos a ON i.articulo_id = a.id
        WHERE i.estado != 'Baja'
        ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND i.bodega = ?' : ''}
      `,
      tipos_articulo: `
        SELECT DISTINCT a.tipo_articulo 
        FROM inventario i
        INNER JOIN articulos a ON i.articulo_id = a.id
        WHERE i.estado != 'Baja'
        ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND i.bodega = ?' : ''}
      `,
      marcas: `
        SELECT DISTINCT m.nombre 
        FROM inventario i
        INNER JOIN articulos a ON i.articulo_id = a.id
        LEFT JOIN marcas m ON a.marca_id = m.id
        WHERE i.estado != 'Baja' AND m.nombre IS NOT NULL
        ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND i.bodega = ?' : ''}
      `,
      categorias: `
        SELECT DISTINCT c.nombre 
        FROM inventario i
        INNER JOIN articulos a ON i.articulo_id = a.id
        LEFT JOIN categorias c ON a.categoria_id = c.id
        WHERE i.estado != 'Baja' AND c.nombre IS NOT NULL
        ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND i.bodega = ?' : ''}
      `
    };

    console.log('🔍 Ejecutando consultas de filtros...');
    
    // Ejecutar todas las consultas en paralelo
    const resultados = await Promise.all([
      db.consultaDirecta(consultas.estados, params),
      db.consultaDirecta(consultas.bodegas, params),
      db.consultaDirecta(consultas.tipos_bodega, params),
      db.consultaDirecta(consultas.tipos_articulo, params),
      db.consultaDirecta(consultas.marcas, params),
      db.consultaDirecta(consultas.categorias, params)
    ]);

    console.log('✅ Consultas ejecutadas correctamente');
    
    // Extraer resultados
    const estadosResult = resultados[0];
    const bodegasResult = resultados[1];
    const tiposBodegaResult = resultados[2];
    const tiposArticuloResult = resultados[3];
    const marcasResult = resultados[4];
    const categoriasResult = resultados[5];

    // Log de resultados
    console.log('📊 Resultados obtenidos:');
    console.log('  - Estados:', estadosResult.length);
    console.log('  - Bodegas:', bodegasResult.length);
    console.log('  - Tipos Bodega:', tiposBodegaResult.length);
    console.log('  - Tipos Artículo:', tiposArticuloResult.length);
    console.log('  - Marcas:', marcasResult.length);
    console.log('  - Categorías:', categoriasResult.length);

    // Procesar resultados
    const resultadoFinal = {
      estados: estadosResult.map(row => row.estado),
      bodegas: bodegasResult.map(row => row.bodega),
      tipos_bodega: tiposBodegaResult.map(row => row.tipo_bodega),
      tipos_articulo: tiposArticuloResult.map(row => row.tipo_articulo),
      marcas: marcasResult.map(row => row.nombre),
      categorias: categoriasResult.map(row => row.nombre)
    };

    console.log('✅ Resultado final procesado:', resultadoFinal);
    return resultadoFinal;
    
  } catch (error) {
    console.error("❌ ERROR AL OBTENER FILTROS:", error);
    
    // Retornar valores por defecto en caso de error
    const resultadoPorDefecto = {
      estados: ['Nuevo', 'Bueno', 'Reparación'],
      bodegas: [],
      tipos_bodega: [],
      tipos_articulo: [],
      marcas: [],
      categorias: []
    };
    
    console.log('🔄 Retornando valores por defecto:', resultadoPorDefecto);
    return resultadoPorDefecto;
  }
}

  return { todos, uno, agregar, actualizar, eliminar, filtrosDisponibles };
};
