const express = require('express');
const router = express.Router();
const mapsController = require('../maps/controlador');

// 🗺️ RUTAS PARA MAPAS Y SITIOS DE VENTA

// Obtener todos los sitios de venta (con y sin coordenadas)
router.get('/sitios-venta', mapsController.getSitiosVenta);

// Obtener solo sitios con coordenadas para el mapa
router.get('/sitios-con-coordenadas', mapsController.getSitiosConCoordenadas);

// Obtener estadísticas de sitios
router.get('/estadisticas', mapsController.getEstadisticasSitios);

// Buscar sitios por ciudad o nombre
router.get('/buscar', mapsController.buscarSitios);

// Actualizar ubicación de un sitio desde app móvil
router.put('/sitios-venta/:id/ubicacion', mapsController.actualizarUbicacionSitio);

module.exports = router;