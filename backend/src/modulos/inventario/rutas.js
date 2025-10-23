const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const controlador = require("./index");
const { verificarToken, permitirRoles } = require("../auth/middleware");

// 🧩 Listar inventario
router.get(
  "/",
  verificarToken,
  permitirRoles("administrador", "usuario", "bodeguero"),
  todos
);

// 🧩 Obtener un registro
router.get(
  "/:id",
  verificarToken,
  permitirRoles("administrador", "usuario", "bodeguero"),
  uno
);

// 🧩 Crear nuevo registro
router.post(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  agregar
);

// 🧩 Actualizar registro
router.put(
  "/:id",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  actualizar
);

// 🧩 Eliminar registro
router.delete(
  "/:id",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  eliminar
);

// 🧩 Obtener filtros disponibles
router.get(
  "/filtros/disponibles",
  verificarToken,
  permitirRoles("administrador", "usuario", "bodeguero", "tecnico"),
  filtrosDisponibles
);

// ---------------------------
// Controladores HTTP
// ---------------------------

async function todos(req, res, next) {
  try {
    const items = await controlador.todos(req.user);
    respuesta.success(req, res, items, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

async function uno(req, res, next) {
  try {
    const item = await controlador.uno(req.params.id, req.user);
    respuesta.success(req, res, item, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 403);
  }
}

async function agregar(req, res, next) {
  try {
    const item = await controlador.agregar(req.body, req.user);
    respuesta.success(req, res, item, 201);
  } catch (error) {
    respuesta.error(req, res, error.message, 403);
  }
}

async function actualizar(req, res, next) {
  try {
    const item = await controlador.actualizar(req.params.id, req.body, req.user);
    respuesta.success(req, res, item, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 403);
  }
}

async function eliminar(req, res, next) {
  try {
    const item = await controlador.eliminar(req.params.id, req.user);
    respuesta.success(req, res, item, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 403);
  }
}

async function filtrosDisponibles(req, res, next) {
  try {
    const filtros = await controlador.filtrosDisponibles(req.user);
    respuesta.success(req, res, filtros, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

module.exports = router;
