const controlador = require("./controlador")(require("../../DB/mysql"));
const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const { verificarToken, permitirRoles } = require("../auth/middleware");

// 🎯 ASIGNACIÓN MASIVA
router.post(
  "/asignaciones-masivas",
  verificarToken,
  permitirRoles("administrador", "bodega"),
  asignacionMasiva
);

// 🔄 TRANSFERENCIAS
router.post(
  "/transferencias",
  verificarToken,
  permitirRoles("administrador", "bodega"),
  solicitarTransferencia
);

// ✅ VERIFICAR RECEPCIÓN
router.post(
  "/transferencias/:actaId/verificar",
  verificarToken,
  permitirRoles("administrador", "bodega"),
  verificarRecepcion
);

// 🔄 DEVOLUCIONES
router.post(
  "/devoluciones",
  verificarToken,
  permitirRoles("administrador", "bodega", "tecnico"),
  procesarDevolucion
);

// 📊 STOCK AGREGADO
router.get(
  "/stock-agregado",
  verificarToken,
  permitirRoles("administrador", "bodega", "usuario"),
  obtenerStockAgregado
);

// 🔔 NOTIFICACIONES
router.get(
  "/notificaciones",
  verificarToken,
  permitirRoles("administrador", "bodega", "tecnico", "usuario"),
  obtenerNotificaciones
);

router.patch(
  "/notificaciones/:id/leer",
  verificarToken,
  permitirRoles("administrador", "bodega", "tecnico", "usuario"),
  marcarNotificacionLeida
);

router.get(
  "/notificaciones/estadisticas",
  verificarToken,
  permitirRoles("administrador", "bodega", "tecnico", "usuario"),
  obtenerEstadisticasNotificaciones
);

// ---------------------------
// Controladores HTTP
// ---------------------------

async function asignacionMasiva(req, res, next) {
  try {
    const { tecnico_id, sitio_venta_id, inventario_ids, descripcion, observaciones } = req.body;
    
    if (!tecnico_id || !sitio_venta_id || !inventario_ids) {
      return respuesta.error(req, res, "tecnico_id, sitio_venta_id e inventario_ids son requeridos", 400);
    }

    const resultado = await controlador.asignacionMasiva(req.body, req.user);
    respuesta.success(req, res, resultado, 201);
  } catch (error) {
    console.error('❌ Error en asignación masiva:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function solicitarTransferencia(req, res, next) {
  try {
    const { inventario_ids, bodega_origen, bodega_destino, motivo } = req.body;
    
    if (!inventario_ids || !bodega_origen || !bodega_destino) {
      return respuesta.error(req, res, "inventario_ids, bodega_origen y bodega_destino son requeridos", 400);
    }

    // Si no es admin, validar que bodega_origen coincide con su bodega
    if (req.user.rol !== "administrador" && req.user.bodega !== bodega_origen) {
      return respuesta.error(req, res, "No tienes permiso para transferir desde esta bodega", 403);
    }

    const resultado = await controlador.solicitarTransferencia(req.body, req.user);
    respuesta.success(req, res, resultado, 201);
  } catch (error) {
    console.error('❌ Error en transferencia:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function verificarRecepcion(req, res, next) {
  try {
    const { actaId } = req.params;
    const { items_verificados } = req.body; // Array de {inventario_id, verificado, motivo_rechazo}
    
    if (!items_verificados || !Array.isArray(items_verificados)) {
      return respuesta.error(req, res, "items_verificados es requerido y debe ser un array", 400);
    }

    const resultado = await controlador.verificarRecepcion(parseInt(actaId), items_verificados, req.user);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error en verificación de recepción:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function procesarDevolucion(req, res, next) {
  try {
    const { asignacion_id, estado_equipo, motivo_devolucion } = req.body;
    
    if (!asignacion_id || !estado_equipo) {
      return respuesta.error(req, res, "asignacion_id y estado_equipo son requeridos", 400);
    }

    // Validar estado_equipo
    const estadosValidos = ['bueno', 'danado', 'reparacion'];
    if (!estadosValidos.includes(estado_equipo)) {
      return respuesta.error(req, res, "estado_equipo debe ser: bueno, danado o reparacion", 400);
    }

    const resultado = await controlador.procesarDevolucion(req.body, req.user);
    respuesta.success(req, res, resultado, 201);
  } catch (error) {
    console.error('❌ Error en devolución:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function obtenerStockAgregado(req, res, next) {
  try {
    const resultado = await controlador.obtenerStockAgregado(req.user);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error obteniendo stock agregado:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function obtenerNotificaciones(req, res, next) {
  try {
    const resultado = await controlador.obtenerNotificaciones(req.user);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error obteniendo notificaciones:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function marcarNotificacionLeida(req, res, next) {
  try {
    const { id } = req.params;
    const resultado = await controlador.marcarNotificacionLeida(parseInt(id), req.user);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error marcando notificación como leída:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

async function obtenerEstadisticasNotificaciones(req, res, next) {
  try {
    const resultado = await controlador.obtenerEstadisticasNotificaciones(req.user);
    respuesta.success(req, res, resultado, 200);
  } catch (error) {
    console.error('❌ Error obteniendo estadísticas de notificaciones:', error);
    respuesta.error(req, res, error.message, 500);
  }
}

module.exports = router;