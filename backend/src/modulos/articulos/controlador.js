const TABLA_GENERAL = "articulos_generales";
const TABLA_CATALOGO = "articulos_catalogo";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) db = require("../../DB/mysql");

  async function agregar(data) {
    const conexion = await db.getConnection();

    try {
      await conexion.beginTransaction();

      // 1️⃣ Insertar o actualizar artículo general
      const general = {
        id: data.id_general || undefined,
        nombre_articulo: data.nombre_articulo,
        stock_minimo: data.stock_minimo,
        descripcion: data.descripcion_general,
      };

      const [resultadoGeneral] = await conexion.query(
        `INSERT INTO ${TABLA_GENERAL} SET ? ON DUPLICATE KEY UPDATE ?`,
        [general, general]
      );

      const generalId = data.id_general || resultadoGeneral.insertId;

      // 2️⃣ Insertar o actualizar artículo catálogo (relacionado)
      const catalogo = {
        id: data.id_catalogo || undefined,
        articulo_general_id: generalId,
        marca: data.marca,
        referencia: data.referencia,
        tipo_bodega: data.tipo_bodega,
        tipo: data.tipo,
        descripcion: data.descripcion_catalogo,
        imagen_path: data.imagen_path,
      };

      await conexion.query(
        `INSERT INTO ${TABLA_CATALOGO} SET ? ON DUPLICATE KEY UPDATE ?`,
        [catalogo, catalogo]
      );

      await conexion.commit();
      conexion.release();

      return { message: "Artículo agregado o actualizado correctamente" };
    } catch (error) {
      await conexion.rollback();
      conexion.release();
      throw error;
    }
  }

  async function eliminar(id_general) {
    const conexion = await db.getConnection();

    try {
      await conexion.beginTransaction();

      // Primero eliminamos los catálogos asociados
      await conexion.query(
        `DELETE FROM ${TABLA_CATALOGO} WHERE articulo_general_id = ?`,
        [id_general]
      );

      // Luego el registro general
      await conexion.query(`DELETE FROM ${TABLA_GENERAL} WHERE id = ?`, [
        id_general,
      ]);

      await conexion.commit();
      conexion.release();

      return {
        message: "Artículo general y catálogos eliminados correctamente",
      };
    } catch (error) {
      await conexion.rollback();
      conexion.release();
      throw error;
    }
  }

  async function todos() {
    const sql = `
    SELECT g.id AS id_general, g.nombre_articulo, g.stock_minimo, g.descripcion AS descripcion_general,
           c.id AS id_catalogo, c.marca, c.referencia, c.tipo_bodega, c.tipo, c.descripcion AS descripcion_catalogo, c.imagen_path
    FROM ${TABLA_GENERAL} g
    LEFT JOIN ${TABLA_CATALOGO} c ON g.id = c.articulo_general_id
    ORDER BY g.id DESC
  `;
    return db.consultaDirecta(sql);
  }

  return { agregar, eliminar, todos };
};
