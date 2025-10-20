const TABLA_CATEGORIAS = "categorias";
const TABLA_ARTICULOS = "articulos";
const TABLA_MARCAS = "marcas";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  async function agregar(data) {
    try {
      console.log("📥 DATOS RECIBIDOS EN AGREGAR ARTÍCULO:");
      console.log("   categoria_id:", data.categoria_id);
      console.log("   articulo_id:", data.articulo_id);
      console.log("   marca_id:", data.marca_id);

      let articuloId;

      if (data.articulo_id) {
        // ACTUALIZAR artículo existente
        console.log("🔄 ACTUALIZANDO ARTÍCULO EXISTENTE - ID:", data.articulo_id);

        const queryArticulo = `UPDATE ${TABLA_ARTICULOS} 
                              SET categoria_id = ?, 
                                  marca_id = ?,
                                  tipo_bodega = ?, 
                                  tipo_articulo = ?,
                                  referencia = ?,
                                  ubicacion_bodega = ?,
                                  imagen_path = ?
                              WHERE id = ?`;

        const valuesArticulo = [
          data.categoria_id,
          data.marca_id,
          data.tipo_bodega,
          data.tipo_articulo,
          data.referencia,
          data.ubicacion_bodega,
          data.imagen_path,
          data.articulo_id,
        ];

        await db.consultaDirecta(queryArticulo, valuesArticulo);
        articuloId = data.articulo_id;

      } else {
        // CREAR nuevo artículo
        console.log("🆕 CREANDO NUEVO ARTÍCULO");

        const queryArticulo = `INSERT INTO ${TABLA_ARTICULOS} 
                              (categoria_id, marca_id, tipo_bodega, tipo_articulo, referencia, ubicacion_bodega, imagen_path) 
                              VALUES (?, ?, ?, ?, ?, ?, ?)`;

        const valuesArticulo = [
          data.categoria_id,
          data.marca_id,
          data.tipo_bodega,
          data.tipo_articulo,
          data.referencia,
          data.ubicacion_bodega,
          data.imagen_path,
        ];

        const resultado = await db.consultaDirecta(queryArticulo, valuesArticulo);
        articuloId = resultado.insertId;
      }

      console.log("✅ ARTÍCULO GUARDADO - ID:", articuloId);
      return {
        message: "Artículo guardado correctamente",
        articulo_id: articuloId,
      };

    } catch (error) {
      console.error("❌ ERROR EN AGREGAR ARTÍCULO:", error);
      throw error;
    }
  }

  async function eliminar(articulo_id) {
  try {
    const id = parseInt(articulo_id, 10);

    if (!id || isNaN(id)) {
      throw new Error("ID de artículo inválido");
    }

    console.log("🗑️ ELIMINANDO ARTÍCULO ID:", id);
    
    await db.consultaDirecta(`DELETE FROM ${TABLA_ARTICULOS} WHERE id = ?`, [id]);

    return { message: "Artículo eliminado correctamente" };
  } catch (error) {
    console.error("❌ ERROR EN ELIMINAR ARTÍCULO:", error);
    throw error;
  }
}

  async function todos() {
    try {
      console.log("📋 SOLICITANDO TODOS LOS ARTÍCULOS");
      
      const sql = `
      SELECT 
        a.id AS articulo_id,
        a.referencia,
        a.tipo_bodega,
        a.tipo_articulo,
        a.ubicacion_bodega,
        a.imagen_path,
        a.creado_en,
        c.id AS categoria_id,
        c.nombre AS categoria_nombre,
        c.stock_minimo,
        c.etiquetas,
        m.id AS marca_id,
        m.nombre AS marca_nombre
      FROM ${TABLA_ARTICULOS} a
      INNER JOIN ${TABLA_CATEGORIAS} c ON a.categoria_id = c.id
      INNER JOIN ${TABLA_MARCAS} m ON a.marca_id = m.id
      ORDER BY a.id DESC
      `;
      
      const resultado = await db.consultaDirecta(sql);
      console.log(`✅ SE OBTUVIERON ${resultado.length} ARTÍCULOS`);
      return resultado;
    } catch (error) {
      console.error("❌ ERROR EN TODOS ARTÍCULOS:", error);
      throw error;
    }
  }

  async function uno(id) {
    try {
      console.log("🔍 SOLICITANDO ARTÍCULO ID:", id);
      
      const sql = `
      SELECT 
        a.id AS articulo_id,
        a.referencia,
        a.tipo_bodega,
        a.tipo_articulo,
        a.ubicacion_bodega,
        a.imagen_path,
        a.creado_en,
        c.id AS categoria_id,
        c.nombre AS categoria_nombre,
        c.stock_minimo,
        c.etiquetas,
        m.id AS marca_id,
        m.nombre AS marca_nombre
      FROM ${TABLA_ARTICULOS} a
      INNER JOIN ${TABLA_CATEGORIAS} c ON a.categoria_id = c.id
      INNER JOIN ${TABLA_MARCAS} m ON a.marca_id = m.id
      WHERE a.id = ${id}
      `;
      
      const resultado = await db.consultaDirecta(sql);
      return resultado.length > 0 ? resultado[0] : null;
    } catch (error) {
      console.error("❌ ERROR EN UNO ARTÍCULO:", error);
      throw error;
    }
  }

  return { 
    agregar, 
    eliminar, 
    todos, 
    uno
  };
};