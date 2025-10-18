const TABLA_MARCAS = "marcas";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  async function todos() {
    try {
      console.log("📋 SOLICITANDO TODAS LAS MARCAS");
      
      // ✅ CORREGIDO: Solo solicitar columnas que existen
      const sql = `SELECT id, nombre FROM ${TABLA_MARCAS} ORDER BY nombre`;
      const resultado = await db.consultaDirecta(sql);
      
      console.log(`✅ SE OBTUVIERON ${resultado.length} MARCAS`);
      return resultado;
    } catch (error) {
      console.error("❌ ERROR EN TODOS MARCAS:", error);
      throw error;
    }
  }

  async function uno(id) {
    try {
      console.log("🔍 SOLICITANDO MARCA ID:", id);
      
      // ✅ CORREGIDO: Solo solicitar columnas que existen
      const sql = `SELECT id, nombre FROM ${TABLA_MARCAS} WHERE id = ?`;
      const resultado = await db.consultaDirecta(sql, [id]);
      
      console.log(`✅ MARCA ENCONTRADA:`, resultado.length > 0 ? "SÍ" : "NO");
      return resultado.length > 0 ? resultado[0] : null;
    } catch (error) {
      console.error("❌ ERROR EN UNO MARCA:", error);
      throw error;
    }
  }

  async function agregar(data) {
    try {
      console.log("📥 AGREGANDO NUEVA MARCA:", data.nombre);

      // Verificar si la marca ya existe
      const existe = await db.consultaDirecta(
        `SELECT id FROM ${TABLA_MARCAS} WHERE nombre = ?`, 
        [data.nombre]
      );

      if (existe.length > 0) {
        throw new Error("La marca ya existe");
      }

      // ✅ CORREGIDO: Solo insertar columnas que existen
      const sql = `INSERT INTO ${TABLA_MARCAS} (nombre) VALUES (?)`;
      const resultado = await db.consultaDirecta(sql, [data.nombre]);

      console.log("✅ MARCA CREADA - ID:", resultado.insertId);
      return {
        message: "Marca creada correctamente",
        id: resultado.insertId,
        nombre: data.nombre
      };
    } catch (error) {
      console.error("❌ ERROR EN AGREGAR MARCA:", error);
      throw error;
    }
  }

  async function actualizar(id, data) {
    try {
      console.log("🔄 ACTUALIZANDO MARCA ID:", id);

      // Verificar si el nombre ya existe en otra marca
      const existe = await db.consultaDirecta(
        `SELECT id FROM ${TABLA_MARCAS} WHERE nombre = ? AND id != ?`, 
        [data.nombre, id]
      );

      if (existe.length > 0) {
        throw new Error("Ya existe otra marca con ese nombre");
      }

      // ✅ CORREGIDO: Solo actualizar columnas que existen
      const sql = `UPDATE ${TABLA_MARCAS} SET nombre = ? WHERE id = ?`;
      await db.consultaDirecta(sql, [data.nombre, id]);

      console.log("✅ MARCA ACTUALIZADA - ID:", id);
      return {
        message: "Marca actualizada correctamente",
        id: parseInt(id),
        nombre: data.nombre
      };
    } catch (error) {
      console.error("❌ ERROR EN ACTUALIZAR MARCA:", error);
      throw error;
    }
  }

  async function eliminar(id) {
    try {
      console.log("🗑️ ELIMINANDO MARCA ID:", id);

      // Verificar si la marca está siendo usada en artículos
      const enUso = await db.consultaDirecta(
        `SELECT id FROM articulos WHERE marca_id = ? LIMIT 1`, 
        [id]
      );

      if (enUso.length > 0) {
        throw new Error("No se puede eliminar la marca porque está siendo utilizada en artículos");
      }

      const sql = `DELETE FROM ${TABLA_MARCAS} WHERE id = ?`;
      await db.consultaDirecta(sql, [id]);

      console.log("✅ MARCA ELIMINADA - ID:", id);
      return {
        message: "Marca eliminada correctamente",
        id: parseInt(id)
      };
    } catch (error) {
      console.error("❌ ERROR EN ELIMINAR MARCA:", error);
      throw error;
    }
  }

  return {
    todos,
    uno,
    agregar,
    actualizar,
    eliminar
  };
};