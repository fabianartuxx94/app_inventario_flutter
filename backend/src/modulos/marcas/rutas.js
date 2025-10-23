const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const controlador = require("./index");
const { verificarToken, permitirRoles } = require("../auth/middleware");

// 🧩 Listar inventario con filtros
router.get(
  "/",
  verificarToken,
  permitirRoles("administrador", "usuario", "bodeguero", "tecnico"),
  todos
);

// 🧩 Obtener un registro
router.get(
  "/:id",
  verificarToken,
  permitirRoles("administrador", "usuario", "bodeguero", "tecnico"),
  uno
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
    const resultado = await controlador.todos(req.user, req.query);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 500);
  }
}

async function uno(req, res, next) {
  try {
    const item = await controlador.uno(req.params.id, req.user);
    respuesta.success(req, res, item, 200);
  } catch (error) {
    const status = error.message.includes('permiso') ? 403 : 404;
    respuesta.error(req, res, error.message, status);
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