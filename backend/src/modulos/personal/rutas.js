const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const controlador = require("./index");
const { verificarToken, permitirRoles } = require("../auth/middleware");

// 📋 Listar todo el personal
router.get(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero", "consultor"),
  todos
);

// 🔍 Obtener por ID
router.get(
  "/:id",
  verificarToken,
  permitirRoles("administrador", "bodeguero", "consultor"),
  uno
);

// ➕ Agregar nuevo registro
router.post(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  agregar
);

// 🔄 Actualizar registro existente
router.put(
  "/:id",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  actualizar
);

// 🗑️ Eliminar registro
router.delete(
  "/:id",
  verificarToken,
  permitirRoles("administrador"),
  eliminar
);

// ------------------------------
// Handlers
// ------------------------------
async function todos(req, res, next) {
  try {
    const items = await controlador.todos();
    respuesta.success(req, res, items, 200);
  } catch (error) {
    next(error);
  }
}

async function uno(req, res, next) {
  try {
    const item = await controlador.uno(req.params.id);
    if (!item) return respuesta.error(req, res, "Personal no encontrado", 404);
    respuesta.success(req, res, item, 200);
  } catch (error) {
    next(error);
  }
}

async function agregar(req, res, next) {
  try {
    const nuevo = await controlador.agregar(req.body);
    respuesta.success(req, res, nuevo, 201);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

async function actualizar(req, res, next) {
  try {
    const actualizado = await controlador.actualizar(req.params.id, req.body);
    respuesta.success(req, res, actualizado, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

async function eliminar(req, res, next) {
  try {
    const eliminado = await controlador.eliminar(req.params.id);
    respuesta.success(req, res, eliminado, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

module.exports = router;
