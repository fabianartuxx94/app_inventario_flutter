const TABLA_GENERAL = "articulos_generales";
const TABLA_CATALOGO = "articulos_catalogo";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  async function agregar(data) {
  try {
    console.log("📥 DATOS RECIBIDOS EN AGREGAR:");
    console.log("   id_general:", data.id_general);
    console.log("   id_catalogo:", data.id_catalogo);
    console.log("   imagen_path:", data.imagen_path);

    let generalId;
    let catalogoId;

    // 1️⃣ Insertar o actualizar artículo general
    if (data.id_general) {
      // ACTUALIZAR artículo existente
      console.log("🔄 ACTUALIZANDO ARTÍCULO GENERAL EXISTENTE - ID:", data.id_general);

      const queryGeneral = `UPDATE ${TABLA_GENERAL} 
                            SET nombre_articulo = ?, 
                                stock_minimo = ?, 
                                descripcion = ?
                            WHERE id = ?`;

      const valuesGeneral = [
        data.nombre_articulo,
        data.stock_minimo,
        data.descripcion_general,
        data.id_general,
      ];

      console.log("   SQL General:", queryGeneral);
      await db.consultaDirecta(queryGeneral, valuesGeneral);
      generalId = data.id_general;

    } else {
      // CREAR nuevo artículo
      console.log("🆕 CREANDO NUEVO ARTÍCULO GENERAL");

      const queryGeneral = `INSERT INTO ${TABLA_GENERAL} 
                            (nombre_articulo, stock_minimo, descripcion) 
                            VALUES (?, ?, ?)`;

      const valuesGeneral = [
        data.nombre_articulo,
        data.stock_minimo,
        data.descripcion_general,
      ];

      console.log("   SQL General:", queryGeneral);
      const resultado = await db.consultaDirecta(queryGeneral, valuesGeneral);
      generalId = resultado.insertId;
    }

    console.log("✅ GENERAL GUARDADO - ID:", generalId);

    // 2️⃣ Insertar o actualizar artículo catálogo
    if (data.id_catalogo) {
      // ACTUALIZAR catálogo existente
      console.log("🔄 ACTUALIZANDO CATÁLOGO EXISTENTE - ID:", data.id_catalogo);
      console.log("📸 IMAGEN_PATH A GUARDAR:", data.imagen_path);

      const queryCatalogo = `UPDATE ${TABLA_CATALOGO} 
                             SET articulo_general_id = ?,
                                 marca = ?,
                                 referencia = ?,
                                 tipo_bodega = ?,
                                 tipo = ?,
                                 descripcion = ?,
                                 imagen_path = ?
                             WHERE id = ?`;

      const valuesCatalogo = [
        generalId,
        data.marca,
        data.referencia,
        data.tipo_bodega,
        data.tipo,
        data.descripcion_catalogo,
        data.imagen_path,
        data.id_catalogo,
      ];

      console.log("   SQL Catalogo:", queryCatalogo);
      await db.consultaDirecta(queryCatalogo, valuesCatalogo);
      catalogoId = data.id_catalogo;

    } else {
      // CREAR nuevo catálogo
      console.log("🆕 CREANDO NUEVO CATÁLOGO");

      const queryCatalogo = `INSERT INTO ${TABLA_CATALOGO} 
                             (articulo_general_id, marca, referencia, tipo_bodega, tipo, descripcion, imagen_path) 
                             VALUES (?, ?, ?, ?, ?, ?, ?)`;

      const valuesCatalogo = [
        generalId,
        data.marca,
        data.referencia,
        data.tipo_bodega,
        data.tipo,
        data.descripcion_catalogo,
        data.imagen_path,
      ];

      console.log("   SQL Catalogo:", queryCatalogo);
      const resultado = await db.consultaDirecta(queryCatalogo, valuesCatalogo);
      catalogoId = resultado.insertId;
    }

    console.log("✅ CATÁLOGO GUARDADO - ID:", catalogoId);
    console.log("📸 IMAGEN_PATH GUARDADO EN BD:", data.imagen_path);

    return {
      message: "Artículo actualizado correctamente",
      id_general: generalId,
      id_catalogo: catalogoId,
    };

  } catch (error) {
    console.error("❌ ERROR EN AGREGAR:", error);
    throw error;
  }
}

  async function eliminar(id_general) {
    try {
      console.log("🗑️ ELIMINANDO ARTÍCULO ID:", id_general);

      // Primero eliminamos los catálogos asociados
      await db.query(`DELETE FROM ${TABLA_CATALOGO} WHERE articulo_general_id = ${id_general}`);

      // Luego el registro general
      await db.query(`DELETE FROM ${TABLA_GENERAL} WHERE id = ${id_general}`);

      return {
        message: "Artículo general y catálogos eliminados correctamente",
      };
    } catch (error) {
      console.error("❌ ERROR EN ELIMINAR:", error);
      throw error;
    }
  }

  async function todos() {
    try {
      console.log("📋 SOLICITANDO TODOS LOS ARTÍCULOS");
      
      const sql = `
      SELECT g.id AS id_general, g.nombre_articulo, g.stock_minimo, g.descripcion AS descripcion_general,
             c.id AS id_catalogo, c.marca, c.referencia, c.tipo_bodega, c.tipo, c.descripcion AS descripcion_catalogo, c.imagen_path
      FROM ${TABLA_GENERAL} g
      LEFT JOIN ${TABLA_CATALOGO} c ON g.id = c.articulo_general_id
      ORDER BY g.id DESC
      `;
      
      const resultado = await db.consultaDirecta(sql);
      console.log(`✅ SE OBTUVIERON ${resultado.length} ARTÍCULOS`);
      
      return resultado;
    } catch (error) {
      console.error("❌ ERROR EN TODOS:", error);
      throw error;
    }
  }

  async function uno(id) {
    try {
      console.log("🔍 SOLICITANDO ARTÍCULO ID:", id);
      
      const sql = `
      SELECT g.id AS id_general, g.nombre_articulo, g.stock_minimo, g.descripcion AS descripcion_general,
             c.id AS id_catalogo, c.marca, c.referencia, c.tipo_bodega, c.tipo, c.descripcion AS descripcion_catalogo, c.imagen_path
      FROM ${TABLA_GENERAL} g
      LEFT JOIN ${TABLA_CATALOGO} c ON g.id = c.articulo_general_id
      WHERE c.id = ${id} OR g.id = ${id}
      `;
      
      const resultado = await db.consultaDirecta(sql);
      console.log(`✅ ARTÍCULO ENCONTRADO:`, resultado.length > 0 ? "SÍ" : "NO");
      
      return resultado.length > 0 ? resultado[0] : null;
    } catch (error) {
      console.error("❌ ERROR EN UNO:", error);
      throw error;
    }
  }

  return { agregar, eliminar, todos, uno };
};