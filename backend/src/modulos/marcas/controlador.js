const TABLA_MARCAS = "marcas";

// 📋 Obtener todas las marcas
async function todos() {
  try {
    console.log("📋 SOLICITANDO TODAS LAS MARCAS");
    
    const sql = `SELECT * FROM ${TABLA_MARCAS} ORDER BY nombre`;
    console.log("🔍 SQL:", sql);
    
    const db = require("../../DB/mysql");
    const resultado = await db.consultaDirecta(sql);
    
    console.log(`✅ SE OBTUVIERON ${resultado.length} MARCAS`);
    return resultado;
  } catch (error) {
    console.error("❌ ERROR EN CONTROLADOR MARCAS - TODOS:", error);
    throw error;
  }
}

// 🔍 Obtener una marca por ID
async function uno(id) {
  try {
    const sql = `SELECT * FROM ${TABLA_MARCAS} WHERE id = ?`;
    const db = require("../../DB/mysql");
    const resultado = await db.consultaDirecta(sql, [id]);
    return resultado.length > 0 ? resultado[0] : null;
  } catch (error) {
    console.error("❌ ERROR EN CONTROLADOR MARCAS - UNO:", error);
    throw error;
  }
}

// ➕ Crear nueva marca
async function agregar(data) {
  try {
    console.log("📥 CREANDO NUEVA MARCA:", data);
    
    const sql = `INSERT INTO ${TABLA_MARCAS} (nombre) VALUES (?)`;
    const db = require("../../DB/mysql");
    const resultado = await db.consultaDirecta(sql, [data.nombre]);
    
    console.log("✅ MARCA CREADA CON ID:", resultado.insertId);
    return {
      message: "Marca creada correctamente",
      id: resultado.insertId
    };
  } catch (error) {
    console.error("❌ ERROR EN CONTROLADOR MARCAS - AGREGAR:", error);
    throw error;
  }
}


module.exports = {
  todos,
  uno,
  agregar
};