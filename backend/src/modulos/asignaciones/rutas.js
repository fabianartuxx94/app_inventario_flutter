const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const controlador = require("./index");
const { verificarToken, permitirRoles } = require("../auth/middleware");

// 📋 Listar asignaciones
router.get(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero", "tecnico"),
  listarAsignaciones
);

// ➕ Crear nueva asignación
router.post(
  "/",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  crearAsignacion
);

// 🔄 Actualizar estado de asignación
router.patch(
  "/:id/estado",
  verificarToken,
  permitirRoles("administrador", "bodeguero", "tecnico"),
  actualizarEstadoAsignacion
);

// 📊 Obtener inventario disponible para asignación
router.get(
  "/inventario/disponible",
  verificarToken,
  permitirRoles("administrador", "bodeguero"),
  obtenerInventarioDisponible
);

// ---------------------------
// Controladores HTTP
// ---------------------------

// 📋 Listar asignaciones
async function listarAsignaciones(req, res, next) {
  try {
    console.log('📥 Query params para asignaciones:', req.query);
    const resultado = await controlador.todos(req.user, req.query);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error en listar asignaciones:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

// ➕ Crear nueva asignación
async function crearAsignacion(req, res, next) {
  try {
    // Validaciones básicas
    const { inventario_id, tecnico_id, sitio_venta_id } = req.body;
    
    if (!inventario_id || !tecnico_id || !sitio_venta_id) {
      return respuesta.error(req, res, "Datos incompletos: inventario_id, tecnico_id y sitio_venta_id son requeridos", 400);
    }

    const resultado = await controlador.asignar(req.body, req.user);
    respuesta.success(req, res, resultado, 201);
  } catch (error) {
    console.error('❌ Error al crear asignación:', error);
    
    // Manejar errores específicos
    if (error.message.includes('no está disponible') || 
        error.message.includes('no encontrado')) {
      respuesta.error(req, res, error.message, 400);
    } else {
      respuesta.error(req, res, error.message, 500);
    }
  }
}

// 🔄 Actualizar estado de asignación
async function actualizarEstadoAsignacion(req, res, next) {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!estado) {
      return respuesta.error(req, res, "El campo 'estado' es requerido", 400);
    }

    const resultado = await controlador.actualizarEstado(id, estado, req.user);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error al actualizar estado de asignación:', error);
    
    if (error.message.includes('no válido') || 
        error.message.includes('no encontrada')) {
      respuesta.error(req, res, error.message, 400);
    } else {
      respuesta.error(req, res, error.message, 500);
    }
  }
}

// 📊 Obtener inventario disponible
async function obtenerInventarioDisponible(req, res, next) {
  try {
    console.log('🔍 Consultando inventario disponible para asignación');
    const resultado = await controlador.inventarioDisponible(req.user, req.query);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error al obtener inventario disponible:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

module.exports = router;