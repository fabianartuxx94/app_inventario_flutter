const TABLA_PERSONAL = "personal";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  // 📋 Listar todo el personal
  async function todos() {
    try {
      console.log("📋 SOLICITANDO TODO EL PERSONAL");
      const sql = `SELECT id, nombre, identificacion, cargo FROM ${TABLA_PERSONAL} ORDER BY nombre`;
      const resultado = await db.consultaDirecta(sql);
      console.log(`✅ SE OBTUVIERON ${resultado.length} REGISTROS`);
      return resultado;
    } catch (error) {
      console.error("❌ ERROR EN TODOS PERSONAL:", error);
      throw error;
    }
  }

  // 🔍 Obtener un registro por ID
  async function uno(id) {
    try {
      console.log("🔍 SOLICITANDO PERSONAL ID:", id);
      const sql = `SELECT id, nombre, identificacion, cargo FROM ${TABLA_PERSONAL} WHERE id = ?`;
      const resultado = await db.consultaDirecta(sql, [id]);
      return resultado.length > 0 ? resultado[0] : null;
    } catch (error) {
      console.error("❌ ERROR EN UNO PERSONAL:", error);
      throw error;
    }
  }

// ➕ Agregar nuevo registro - ACTUALIZADO
async function agregar(data) {
  try {
    console.log("📥 AGREGANDO NUEVO PERSONAL:", data.nombre);

    // Evitar duplicados por identificación
    const existe = await db.consultaDirecta(
      `SELECT id FROM ${TABLA_PERSONAL} WHERE identificacion = ?`,
      [data.identificacion]
    );

    if (existe.length > 0) {
      throw new Error("Ya existe un registro con esta identificación");
    }

    const sql = `
      INSERT INTO ${TABLA_PERSONAL} 
      (nombre, identificacion, cargo, tipo, activo, email, telefono) 
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    const resultado = await db.consultaDirecta(sql, [
      data.nombre,
      data.identificacion,
      data.cargo || '',
      data.tipo || 'usuario',
      data.activo !== undefined ? data.activo : 1,
      data.email || null,
      data.telefono || null,
    ]);

    console.log("✅ PERSONAL AGREGADO - ID:", resultado.insertId);
    return {
      message: "Personal agregado correctamente",
      id: resultado.insertId,
      ...data
    };
  } catch (error) {
    console.error("❌ ERROR EN AGREGAR PERSONAL:", error);
    throw error;
  }
}

 // 🔄 Actualizar registro existente - ACTUALIZADO
async function actualizar(id, data) {
  try {
    console.log("🔄 ACTUALIZANDO PERSONAL ID:", id);

    // Verificar si la identificación ya está usada por otro
    const existe = await db.consultaDirecta(
      `SELECT id FROM ${TABLA_PERSONAL} WHERE identificacion = ? AND id != ?`,
      [data.identificacion, id]
    );

    if (existe.length > 0) {
      throw new Error("Otra persona ya tiene esta identificación");
    }

    const sql = `
      UPDATE ${TABLA_PERSONAL} 
      SET nombre=?, identificacion=?, cargo=?, tipo=?, activo=?, email=?, telefono=?
      WHERE id=?
    `;
    await db.consultaDirecta(sql, [
      data.nombre,
      data.identificacion,
      data.cargo || '',
      data.tipo || 'usuario',
      data.activo !== undefined ? data.activo : 1,
      data.email || null,
      data.telefono || null,
      id,
    ]);

    console.log("✅ PERSONAL ACTUALIZADO - ID:", id);
    return {
      message: "Personal actualizado correctamente",
      id: parseInt(id),
      ...data
    };
  } catch (error) {
    console.error("❌ ERROR EN ACTUALIZAR PERSONAL:", error);
    throw error;
  }
}

  // 🗑️ Eliminar registro
  async function eliminar(id) {
    try {
      console.log("🗑️ ELIMINANDO PERSONAL ID:", id);

      // Verificar si el empleado está referenciado en actas
      const enUso = await db.consultaDirecta(
        `SELECT id FROM actas WHERE entregado_por_id = ? OR recibido_por_id = ? OR auditor_id = ? LIMIT 1`,
        [id, id, id]
      );

      if (enUso.length > 0) {
        throw new Error("No se puede eliminar, el registro está asociado a un acta");
      }

      const sql = `DELETE FROM ${TABLA_PERSONAL} WHERE id = ?`;
      await db.consultaDirecta(sql, [id]);

      console.log("✅ PERSONAL ELIMINADO - ID:", id);
      return { message: "Personal eliminado correctamente", id: parseInt(id) };
    } catch (error) {
      console.error("❌ ERROR EN ELIMINAR PERSONAL:", error);
      throw error;
    }
  }

  // 📋 Listar personal con filtros (INCLUYENDO TÉCNICOS)
async function todosconfiltros(usuario, queryParams = {}) {
  try {
    const { tipo, activo, page = 1, limit = 50 } = queryParams;
    const offset = (page - 1) * limit;

    console.log("📋 SOLICITANDO PERSONAL CON FILTROS:", { tipo, activo, page, limit });

    let sql = `
      SELECT SQL_CALC_FOUND_ROWS 
        id, nombre, identificacion, cargo, tipo, activo, email, telefono,
        fecha_creacion, fecha_actualizacion
      FROM ${TABLA_PERSONAL} 
      WHERE 1=1
    `;
    const params = [];

    // 🔍 Filtros
    if (tipo) {
      sql += ` AND tipo = ?`;
      params.push(tipo);
    }

    if (activo !== undefined) {
      sql += ` AND activo = ?`;
      params.push(activo ? 1 : 0);
    }

    sql += ` ORDER BY nombre LIMIT ? OFFSET ?`;
    params.push(parseInt(limit), offset);

    const items = await db.consultaDirecta(sql, params);
    
    // Obtener total para paginación
    const countResult = await db.consultaDirecta('SELECT FOUND_ROWS() as total');
    const total = countResult[0].total;

    console.log(`✅ PERSONAL OBTENIDO: ${items.length} de ${total} registros`);

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
    console.error("❌ ERROR EN TODOS PERSONAL:", error);
    throw error;
  }
}

// 👨‍💼 Obtener solo técnicos activos (PARA ASIGNACIONES)
async function tecnicosActivos() {
  try {
    console.log("👨‍💼 SOLICITANDO TÉCNICOS ACTIVOS");
    const sql = `
      SELECT id, nombre, identificacion, cargo, email, telefono
      FROM ${TABLA_PERSONAL} 
      WHERE tipo = 'tecnico' AND activo = 1
      ORDER BY nombre
    `;
    const resultado = await db.consultaDirecta(sql);
    console.log(`✅ TÉCNICOS ACTIVOS: ${resultado.length} registros`);
    return resultado;
  } catch (error) {
    console.error("❌ ERROR EN TÉCNICOS ACTIVOS:", error);
    throw error;
  }
}

  return { 
  todos, 
  todosconfiltros,
  uno, 
  agregar, 
  actualizar, 
  eliminar,
  tecnicosActivos  
};
};
