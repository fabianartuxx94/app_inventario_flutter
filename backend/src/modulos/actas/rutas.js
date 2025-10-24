const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const controlador = require("./index");
const { verificarToken, permitirRoles } = require("../auth/middleware");

// 📋 LISTAR ACTAS
router.get(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodega", "tecnico", "usuario"),
  listarActas
);

// 🔍 OBTENER ACTA COMPLETA
router.get(
  "/:id",
  verificarToken,
  permitirRoles("administrador", "bodega", "tecnico", "usuario"),
  obtenerActaCompleta
);

// 📊 ESTADÍSTICAS DE ACTAS
router.get(
  "/estadisticas/generales",
  verificarToken,
  permitirRoles("administrador", "bodega", "tecnico", "usuario"),
  obtenerEstadisticas
);

// 🎛️ FILTROS DISPONIBLES
router.get(
  "/filtros/disponibles",
  verificarToken,
  permitirRoles("administrador", "bodega", "tecnico", "usuario"),
  obtenerFiltrosDisponibles
);

// 📄 GENERAR PDF
router.post(
  "/:id/generar-pdf",
  verificarToken,
  permitirRoles("administrador", "bodega", "tecnico", "usuario"),
  generarPdf
);

// ---------------------------
// Controladores HTTP
// ---------------------------

async function listarActas(req, res, next) {
  try {
    const resultado = await controlador.listarActas(req.user, req.query);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error listando actas:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function obtenerActaCompleta(req, res, next) {
  try {
    const { id } = req.params;
    const resultado = await controlador.obtenerActaCompleta(parseInt(id), req.user);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error obteniendo acta:', error);
    
    if (error.message.includes('No tienes permiso')) {
      respuesta.error(req, res, error.message, 403);
    } else if (error.message.includes('no encontrada')) {
      respuesta.error(req, res, error.message, 404);
    } else {
      respuesta.error(req, res, error.message, 500);
    }
  }
}

async function obtenerEstadisticas(req, res, next) {
  try {
    const resultado = await controlador.obtenerEstadisticasActas(req.user, req.query);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error obteniendo estadísticas:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function obtenerFiltrosDisponibles(req, res, next) {
  try {
    const resultado = await controlador.obtenerFiltrosDisponibles(req.user);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error obteniendo filtros:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function generarPdf(req, res, next) {
  try {
    const { id } = req.params;
    const resultado = await controlador.generarPdfActa(parseInt(id), req.user);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error generando PDF:', error);
    
    if (error.message.includes('No tienes permiso')) {
      respuesta.error(req, res, error.message, 403);
    } else if (error.message.includes('no encontrada')) {
      respuesta.error(req, res, error.message, 404);
    } else {
      respuesta.error(req, res, error.message, 500);
    }
  }
}

module.exports = router;