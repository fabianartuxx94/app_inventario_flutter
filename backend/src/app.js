const express = require("express");
const morgan = require("morgan");
const path = require("path");
const fs = require("fs");

// 🔧 MIDDLEWARES OPTIMIZADOS
const {
  seguridad,
  comprimir,
  limitadorGeneral,
  limitadorAuth,
  limitadorAPIs,
  ralentizador,
  bodyParserConfig,
  monitorPerformance,
  cacheControl,
  corsOptimizado
} = require("./middleware/optimizacion");

const cors = require("cors");
const { app: _app } = require("./config");
const { AppLogger } = require("./utils/logger");

const app = express();
const logger = new AppLogger('app');

// 📦 RUTAS DEL SISTEMA
const usuarios = require("./modulos/usuarios/rutas");
const categorias = require("./modulos/categorias/rutas");
const auth = require("./modulos/auth/rutas");
const articulos = require("./modulos/articulos/rutas");
const uploads = require("./modulos/uploads/rutas");
const marcas = require("./modulos/marcas/rutas");
const inventario = require("./modulos/inventario/rutas");
const asignaciones = require("./modulos/asignaciones/rutas");
const gestion = require("./modulos/gestion/rutas");
const actas = require("./modulos/actas/rutas");
const maps = require('./modulos/maps/rutas');
const personal = require("./modulos/personal/rutas");

// 📁 CONFIGURACIÓN DE ARCHIVOS ESTÁTICOS
const rutaUploads = path.join(__dirname, "uploads");
const rutaImagenesArticulos = path.join(rutaUploads, "images", "articulos");

// 🚀 MIDDLEWARES GLOBALES OPTIMIZADOS
app.use(seguridad);
app.use(comprimir);
app.use(monitorPerformance);
app.use(cacheControl);
app.use(limitadorGeneral);
app.use(ralentizador);

// CORS personalizado
app.use(cors(corsOptimizado));

// Logging optimizado
app.use(morgan('combined', {
  stream: {
    write: (message) => {
      logger.info('Request HTTP', { message: message.trim() });
    }
  }
}));

// Body parser con límites
app.use(express.json(bodyParserConfig.json));
app.use(express.urlencoded(bodyParserConfig.urlencoded));

// 🏥 ENDPOINTS DE SALUD Y MÉTRICAS
app.get("/health", (req, res) => {
  const health = {
    status: "OK",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    environment: process.env.NODE_ENV || 'development'
  };
  
  res.json(health);
});

app.get("/metrics", async (req, res) => {
  try {
    const db = require("./DB/mysql");
    const cacheManager = require("./utils/cache");
    const { getLogMetrics } = require("./utils/logger");
    
    const metrics = {
      timestamp: new Date().toISOString(),
      system: {
        uptime: process.uptime(),
        memory: process.memoryUsage()
      },
      database: db.getPoolMetrics ? db.getPoolMetrics() : { available: false },
      cache: cacheManager.getStats ? cacheManager.getStats() : { available: false },
      logs: getLogMetrics()
    };
    
    res.json(metrics);
  } catch (error) {
    logger.error('Error obteniendo métricas', { error: error.message });
    res.status(500).json({ error: 'Error obteniendo métricas' });
  }
});

// 🔧 DIAGNÓSTICO (solo desarrollo)
if (process.env.NODE_ENV !== 'production') {
  app.get("/diagnostic/static-files", (req, res) => {
    const diagnostico = {
      ruta_uploads: rutaUploads,
      existe_uploads: fs.existsSync(rutaUploads),
      ruta_imagenes: rutaImagenesArticulos,
      existe_imagenes: fs.existsSync(rutaImagenesArticulos),
      archivos: []
    };
    
    if (diagnostico.existe_imagenes) {
      diagnostico.archivos = fs.readdirSync(rutaImagenesArticulos);
    }
    
    res.json(diagnostico);
  });
}

// 🧩 API REST - MÓDULOS DEL SISTEMA
app.use("/api/auth", limitadorAuth, auth);
app.use("/api/usuarios", limitadorAPIs, usuarios);
app.use("/api/categorias", limitadorAPIs, categorias);
app.use("/api/articulos", limitadorAPIs, articulos);
app.use("/api/marcas", limitadorAPIs, marcas);
app.use("/api/inventario", limitadorAPIs, inventario);
app.use("/api/asignaciones", limitadorAPIs, asignaciones);
app.use("/api/gestion", limitadorAPIs, gestion);
app.use("/api/actas", limitadorAPIs, actas);
app.use("/api/maps", limitadorAPIs, maps);
app.use("/api/personal", limitadorAPIs, personal);
app.use("/api/uploads", uploads);

// 📁 SERVIR ARCHIVOS ESTÁTICOS
app.use("/uploads/images/articulos", express.static(rutaImagenesArticulos, {
  maxAge: '1d',
  etag: true,
  lastModified: true
}));

// 🎯 RUTA POR DEFECTO
app.get("/", (req, res) => {
  res.json({
    message: "API de Gestión de Inventario - Versión Optimizada",
    version: "2.0.0",
    status: "✅ Funcionando"
  });
});

// ❌ MANEJO DE RUTAS NO ENCONTRADAS
app.use((req, res, next) => {
  logger.warn('Ruta no encontrada', {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip
  });
  
  res.status(404).json({
    error: true,
    message: "Ruta no encontrada",
    path: req.originalUrl
  });
});

// 🛑 MANEJO DE ERRORES CENTRALIZADO
app.use((err, req, res, next) => {
  logger.error('Error no manejado', {
    error: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    userId: req.user?.id
  });
  
  // Error JWT
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      error: true,
      message: "Token inválido"
    });
  }
  
  // Error base de datos
  if (err.code && err.code.startsWith('ER_')) {
    return res.status(500).json({
      error: true,
      message: "Error en base de datos",
      code: err.code
    });
  }
  
  // Error genérico
  res.status(err.status || 500).json({
    error: true,
    message: process.env.NODE_ENV === 'production' 
      ? 'Error interno del servidor' 
      : err.message
  });
});

app.set("port", _app.port);

module.exports = app;