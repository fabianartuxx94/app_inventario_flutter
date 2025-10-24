const TABLA_INVENTARIO = "inventario";


// 🎯 CACHE EN MEMORIA - Optimización FASE 1
const filtrosCache = new Map();

// 🔧 Configuración de cache (5 minutos = 300,000 ms)
const CACHE_DURACION = 5 * 60 * 1000; 

// 🧹 Limpieza automática de cache expirado cada 10 minutos
setInterval(() => {
  const ahora = Date.now();
  for (let [key, valor] of filtrosCache.entries()) {
    if (ahora - valor.timestamp > CACHE_DURACION) {
      filtrosCache.delete(key);
      console.log('🧹 Cache limpiado:', key);
    }
  }
}, 10 * 60 * 1000);

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

    // 📊 CONSULTA PRINCIPAL OPTIMIZADA
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
        a.referencia AS articulo_referencia,
        a.descripcion AS articulo_descripcion,
        a.tipo_articulo,
        a.tipo_bodega,
        c.nombre AS categoria_nombre,
        m.nombre AS marca_nombre,
        -- 🆕 Campo para asignaciones futuras
        i.estado_asignacion
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

    // 🔍 Búsqueda optimizada con FULLTEXT (si configuras el índice)
    if (search) {
      sql += ` AND (
        a.referencia LIKE ? OR 
        i.placa LIKE ? OR 
        i.serial LIKE ?
      )`;
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    // 🏢 Filtros por atributo (con índices)
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

    // 📄 Paginación
    sql += ` ORDER BY i.fecha_actualizacion DESC LIMIT ? OFFSET ?`;
    params.push(parseInt(limit), offset);

    // 🚀 Ejecutar consulta principal
    const items = await db.consultaDirecta(sql, params);
    
    // 🎯 Obtener total con FOUND_ROWS() (MUCHO más rápido)
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

  // ➕ Crear nuevo registro - ACTUALIZADO
async function agregar(data, usuario) {
  try {
    if (!puedeModificar(usuario, data.bodega)) {
      throw new Error("No tienes permiso para crear en esta bodega");
    }

    const sql = `
      INSERT INTO ${TABLA_INVENTARIO}
      (articulo_id, placa, serial, estado, estado_asignacion, cantidad, bodega, ubicacion_detallada, usuario_id, fecha_creacion, fecha_actualizacion)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
    `;
    const resultado = await db.consultaDirecta(sql, [
      data.articulo_id,
      data.placa || null,
      data.serial || null,
      data.estado,
      data.estado_asignacion || 'disponible', // 🆕 Valor por defecto
      data.cantidad || 1,
      data.bodega,
      data.ubicacion_detallada || null,
      usuario.id,
    ]);
     invalidarCacheFiltros();
    console.log('🧹 Cache invalidado por nuevo registro');
    return {
      message: "Inventario agregado correctamente",
      id: resultado.insertId,
      
    };

  } catch (error) {
    console.error("❌ ERROR AL AGREGAR INVENTARIO:", error);
    throw error;
  }
  
}

// 🔄 Actualizar un registro - ACTUALIZADO
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
      SET 
        articulo_id=?, 
        placa=?, 
        serial=?, 
        estado=?, 
        estado_asignacion=?,  -- 🆕 Nuevo campo
        cantidad=?, 
        bodega=?, 
        ubicacion_detallada=?, 
        usuario_id=?, 
        fecha_actualizacion=NOW()
      WHERE id=?
    `;
    await db.consultaDirecta(sql, [
      data.articulo_id,
      data.placa || null,
      data.serial || null,
      data.estado,
      data.estado_asignacion || 'disponible', // 🆕 Valor por defecto
      data.cantidad || 1,
      data.bodega,
      data.ubicacion_detallada || null,
      usuario.id,
      id,
    ]);
     invalidarCacheFiltros();
    console.log('🧹 Cache invalidado por nuevo registro');
    return {
      message: "Inventario actualizado correctamente",
      id: parseInt(id),
    };
  } catch (error) {
    console.error("❌ ERROR AL ACTUALIZAR INVENTARIO:", error);
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
       invalidarCacheFiltros();
    console.log('🧹 Cache invalidado por nuevo registro');
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
       invalidarCacheFiltros();
    console.log('🧹 Cache invalidado por nuevo registro');
      return {
        message: "Inventario eliminado correctamente",
        id: parseInt(id),
      };
    } catch (error) {
      console.error("❌ ERROR AL ELIMINAR INVENTARIO:", error);
      throw error;
    }
  }

// 📊 Obtener opciones de filtros disponibles - OPTIMIZADA CON CACHE
async function filtrosDisponibles(usuario) {
  try {
    // 🎯 Clave única para cache por usuario+bodega
    const cacheKey = `filtros_${usuario.id}_${usuario.bodega || 'all'}`;
    
    // ✅ Verificar cache
    const cached = filtrosCache.get(cacheKey);
    if (cached && (Date.now() - cached.timestamp < CACHE_DURACION)) {
      console.log('🎯 Retornando filtros desde cache:', cacheKey);
      return cached.data;
    }

    console.log('🔄 Ejecutando consulta de filtros para:', usuario.id);
    
    const params = usuario.rol !== "administrador" && usuario.bodega !== null ? [usuario.bodega] : [];

    // 🚀 CONSULTA ÚNICA OPTIMIZADA - En lugar de 6 consultas separadas
    const sql = `
      -- Estados del inventario
      SELECT 'estados' as tipo, estado as valor
      FROM inventario 
      WHERE estado != 'Baja'
      ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND bodega = ?' : ''}
      
      UNION ALL
      
      -- Bodegas
      SELECT 'bodegas' as tipo, bodega as valor
      FROM inventario 
      WHERE estado != 'Baja'
      ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND bodega = ?' : ''}
      
      UNION ALL
      
      -- Tipos de bodega
      SELECT 'tipos_bodega' as tipo, a.tipo_bodega as valor
      FROM inventario i
      INNER JOIN articulos a ON i.articulo_id = a.id
      WHERE i.estado != 'Baja'
      ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND i.bodega = ?' : ''}
      
      UNION ALL
      
      -- Tipos de artículo
      SELECT 'tipos_articulo' as tipo, a.tipo_articulo as valor
      FROM inventario i
      INNER JOIN articulos a ON i.articulo_id = a.id
      WHERE i.estado != 'Baja'
      ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND i.bodega = ?' : ''}
      
      UNION ALL
      
      -- Marcas
      SELECT 'marcas' as tipo, m.nombre as valor
      FROM inventario i
      INNER JOIN articulos a ON i.articulo_id = a.id
      LEFT JOIN marcas m ON a.marca_id = m.id
      WHERE i.estado != 'Baja' AND m.nombre IS NOT NULL
      ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND i.bodega = ?' : ''}
      
      UNION ALL
      
      -- Categorías
      SELECT 'categorias' as tipo, c.nombre as valor
      FROM inventario i
      INNER JOIN articulos a ON i.articulo_id = a.id
      LEFT JOIN categorias c ON a.categoria_id = c.id
      WHERE i.estado != 'Baja' AND c.nombre IS NOT NULL
      ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND i.bodega = ?' : ''}
      
      UNION ALL
      
      -- 🆕 Estados de asignación
      SELECT 'estados_asignacion' as tipo, estado_asignacion as valor
      FROM inventario 
      WHERE estado != 'Baja'
      ${usuario.rol !== "administrador" && usuario.bodega !== null ? 'AND bodega = ?' : ''}
    `;

    // 📊 Ejecutar consulta única
    const resultados = await db.consultaDirecta(sql, [...params, ...params, ...params, ...params, ...params, ...params, ...params]);
    
    // 🎯 Procesar resultados
    const resultadoFinal = {
      estados: [],
      bodegas: [],
      tipos_bodega: [],
      tipos_articulo: [],
      marcas: [],
      categorias: [],
      estados_asignacion: []  // 🆕 Nuevo filtro
    };

    // 📋 Organizar resultados por tipo
    resultados.forEach(row => {
      if (row.valor) { // Filtrar valores nulos
        switch(row.tipo) {
          case 'estados':
            resultadoFinal.estados.push(row.valor);
            break;
          case 'bodegas':
            resultadoFinal.bodegas.push(row.valor);
            break;
          case 'tipos_bodega':
            resultadoFinal.tipos_bodega.push(row.valor);
            break;
          case 'tipos_articulo':
            resultadoFinal.tipos_articulo.push(row.valor);
            break;
          case 'marcas':
            resultadoFinal.marcas.push(row.valor);
            break;
          case 'categorias':
            resultadoFinal.categorias.push(row.valor);
            break;
          case 'estados_asignacion':
            resultadoFinal.estados_asignacion.push(row.valor);
            break;
        }
      }
    });

    // 🧹 Eliminar duplicados y ordenar
    Object.keys(resultadoFinal).forEach(key => {
      resultadoFinal[key] = [...new Set(resultadoFinal[key])].sort();
    });

    console.log('✅ Filtros procesados. Total resultados:', resultados.length);

    // 💾 Guardar en cache
    filtrosCache.set(cacheKey, {
      data: resultadoFinal,
      timestamp: Date.now()
    });

    return resultadoFinal;
    
  } catch (error) {
    console.error("❌ ERROR AL OBTENER FILTROS:", error);
    
    // 🆘 Valores por defecto en caso de error
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
}

// 🗑️ Función para invalidar cache (llamar cuando se agregue/actualice/elimine inventario)
function invalidarCacheFiltros() {
  const tamañoAntes = filtrosCache.size;
  filtrosCache.clear();
  console.log(`🧹 Cache invalidado. Elementos eliminados: ${tamañoAntes}`);
  
}

  return { todos, uno, agregar, actualizar, eliminar, filtrosDisponibles };
};
