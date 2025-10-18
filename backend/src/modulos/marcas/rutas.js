const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const controlador = require("./index");
const { verificarToken, permitirRoles } = require("../auth/middleware");

// Listar todas las marcas
router.get(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero", "consultor"),
  todos
);

// Obtener una marca específica
router.get(
  "/:id",
  verificarToken,
  permitirRoles("administrador", "bodeguero", "consultor"),
  uno
);

// Crear nueva marca
router.post(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  agregar
);

// Actualizar marca
router.put(
  "/:id",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  actualizar
);

// Eliminar marca
router.delete(
  "/:id",
  verificarToken,
  permitirRoles("administrador"),
  eliminar
);

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
    const items = await controlador.uno(req.params.id);
    respuesta.success(req, res, items, 200);
  } catch (error) {
    next(error);
  }
}

async function agregar(req, res, next) {
  try {
    console.log("🔄 CREANDO NUEVA MARCA:", req.body);
    const items = await controlador.agregar(req.body);
    respuesta.success(req, res, items, 201);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

async function actualizar(req, res, next) {
  try {
    console.log("🔄 ACTUALIZANDO MARCA:", req.params.id, req.body);
    const items = await controlador.actualizar(req.params.id, req.body);
    respuesta.success(req, res, items, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

async function eliminar(req, res, next) {
  try {
    console.log("🗑️ ELIMINANDO MARCA:", req.params.id);
    const items = await controlador.eliminar(req.params.id);
    respuesta.success(req, res, items, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

module.exports = router;