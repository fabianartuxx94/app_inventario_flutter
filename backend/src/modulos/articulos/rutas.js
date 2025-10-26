const controlador = require("./controlador")(require("../../DB/mysql"));
const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const { verificarToken, permitirRoles } = require("../auth/middleware");

// Listar todos los artículos
router.get(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero", "consultor"),
  todos
);

// Agregar o modificar artículo
router.post(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  agregar
);

// Eliminar artículo
router.delete("/:id", verificarToken, permitirRoles("administrador"), eliminar);

// Obtener un artículo específico
router.get("/:id", verificarToken, permitirRoles("administrador", "bodeguero", "consultor"), uno);

async function todos(req, res, next) {
  try {
    const data = await controlador.todos();
    respuesta.success(req, res, data, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

async function uno(req, res, next) {
  try {
    const items = await controlador.uno(req.params.id);
    respuesta.success(req, res, items, 200);
  } catch (error) {
    next(error);
  }
}

async function agregar(req, res, next) {
  try {
    console.log("🔄 DATOS RECIBIDOS EN RUTA ARTÍCULOS:");
    console.log("   categoria_id:", req.body.categoria_id);
    console.log("   marca_id:", req.body.marca_id);
    
    const data = await controlador.agregar(req.body);
    respuesta.success(req, res, data, 201);
  } catch (error) {
    console.error("❌ ERROR en ruta agregar artículo:", error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function eliminar(req, res, next) {
  try {
    const data = await controlador.eliminar(req.params.id);
    respuesta.success(req, res, data, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

module.exports = router;