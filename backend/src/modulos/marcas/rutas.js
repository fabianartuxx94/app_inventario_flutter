const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const controlador = require("./controlador");
const { verificarToken, permitirRoles } = require("../auth/middleware");

// 🧩 Listar todas las marcas
router.get("/", verificarToken, todos);

// 🧩 Obtener una marca
router.get("/:id", verificarToken, uno);

// 🧩 Crear nueva marca
router.post("/", verificarToken, permitirRoles("administrador", "bodeguero"), agregar);

// ---------------------------
// Controladores HTTP
// ---------------------------

async function todos(req, res, next) {
  try {
    console.log("📥 SOLICITUD GET /api/marcas recibida");
    const items = await controlador.todos();
    console.log("✅ Enviando respuesta con", items.length, "marcas");
    respuesta.success(req, res, items, 200);
  } catch (error) {
    console.error("❌ ERROR EN RUTA MARCAS - TODOS:", error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function uno(req, res, next) {
  try {
    const item = await controlador.uno(req.params.id);
    if (!item) {
      return respuesta.error(req, res, "Marca no encontrada", 404);
    }
    respuesta.success(req, res, item, 200);
  } catch (error) {
    console.error("❌ ERROR EN RUTA MARCAS - UNO:", error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function agregar(req, res, next) {
  try {
    const item = await controlador.agregar(req.body);
    respuesta.success(req, res, item, 201);
  } catch (error) {
    console.error("❌ ERROR EN RUTA MARCAS - AGREGAR:", error);
    respuesta.error(req, res, error.message, 500);
  }
}

module.exports = router;