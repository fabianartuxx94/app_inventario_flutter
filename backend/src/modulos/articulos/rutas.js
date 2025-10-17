const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const controlador = require("./index");
const { verificarToken, permitirRoles } = require("../auth/middleware");

// Listar todos
router.get(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero", "consultor"),
  todos
);

// Agregar o modificar
router.post(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  agregar
);

// Eliminar
router.delete("/:id", verificarToken, permitirRoles("administrador"), eliminar);

router.get("/:id", verificarToken, permitirRoles("administrador"), uno);

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
    const data = await controlador.agregar(req.body);
    respuesta.success(req, res, data, 201);
  } catch (error) {
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
async function agregar(req, res, next) {
  try {
    console.log("🔄 DATOS COMPLETOS RECIBIDOS EN RUTA:");
    console.log("   imagen_path recibido:", req.body.imagen_path);
    console.log("   Todos los campos:", Object.keys(req.body));
    
    const data = await controlador.agregar(req.body);
    respuesta.success(req, res, data, 201);
  } catch (error) {
    console.error("❌ ERROR en ruta agregar:", error);
    respuesta.error(req, res, error.message, 500);
  }
}

module.exports = router;