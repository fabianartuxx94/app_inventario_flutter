// 🛡️ MIDDLEWARES DE OPTIMIZACIÓN (versión compatible)
let compression, rateLimit, slowDown, helmet;

// Cargar dependencias opcionales
try {
  compression = require('compression');
} catch (e) {
  console.warn('⚠️  compression no instalado, omitiendo compresión');
  compression = null;
}

try {
  rateLimit = require('express-rate-limit');
} catch (e) {
  console.warn('⚠️  express-rate-limit no instalado, omitiendo rate limiting');
  rateLimit = null;
}

try {
  slowDown = require('express-slow-down');
} catch (e) {
  console.warn('⚠️  express-slow-down no instalado, omitiendo slow down');
  slowDown = null;
}

try {
  helmet = require('helmet');
} catch (e) {
  console.warn('⚠️  helmet no instalado, omitiendo seguridad helmet');
  helmet = null;
}

// 🛡️ SEGURIDAD BÁSICA (fallback si helmet no está disponible)
const seguridad = helmet ? helmet({
  contentSecurityPolicy: false, // Desactivar CSP por ahora
  crossOriginEmbedderPolicy: false
}) : (req, res, next) => next();

// 📦 COMPRESIÓN (fallback)
const comprimir = compression ? compression({
  level: 6,
  threshold: 1024,
}) : (req, res, next) => next();

// 🚀 RATE LIMITING (fallback)
const createLimiter = (windowMs, max, message) => {
  if (!rateLimit) return (req, res, next) => next();
  
  return rateLimit({
    windowMs,
    max,
    message: { error: message },
    standardHeaders: true,
    legacyHeaders: false
  });
};

const limitadorGeneral = createLimiter(15 * 60 * 1000, 1000, 'Demasiadas solicitudes');
const limitadorAuth = createLimiter(15 * 60 * 1000, 5, 'Demasiados intentos de login');
const limitadorAPIs = createLimiter(1 * 60 * 1000, 100, 'Límite de API excedido');

// 🐌 SLOW DOWN (fallback)
const ralentizador = slowDown ? slowDown({
  windowMs: 15 * 60 * 1000,
  delayAfter: 100,
  delayMs: 500
}) : (req, res, next) => next();

// 📏 LIMITE DE CARGA
const bodyParserConfig = {
  json: { 
    limit: '10mb',
    verify: (req, res, buf) => {
      req.rawBody = buf;
    }
  },
  urlencoded: { 
    extended: true, 
    limit: '10mb',
    parameterLimit: 1000
  }
};

// 🔍 MONITOREO DE PERFORMANCE
const monitorPerformance = (req, res, next) => {
  const start = Date.now();
  const originalSend = res.send;

  req.metrics = {
    startTime: start,
    memoryStart: process.memoryUsage()
  };

  res.send = function(data) {
    const duration = Date.now() - start;
    const memoryEnd = process.memoryUsage();
    
    if (duration > 1000) {
      console.warn(`🐌 Request lenta: ${req.method} ${req.originalUrl} - ${duration}ms`);
    }

    res.set('X-Response-Time', `${duration}ms`);
    res.set('X-Memory-Usage', `${(memoryEnd.heapUsed - req.metrics.memoryStart.heapUsed) / 1024 / 1024}MB`);

    originalSend.call(this, data);
  };

  next();
};

// 🧹 CACHE CONTROL
const cacheControl = (req, res, next) => {
  if (req.method === 'GET') {
    res.set('Cache-Control', 'private, max-age=60');
  }
  next();
};

// 🔄 OPTIMIZACIÓN DE CORS
const corsOptimizado = {
  origin: function (origin, callback) {
    const allowedOrigins = [
      'http://localhost:5000',
      'http://127.0.0.1:5000',
      'http://10.192.84.125:5000',
      'http://localhost:58741'
    ];
    
    if (!origin || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      console.warn(`🚫 CORS bloqueado: ${origin}`);
      callback(new Error('No permitido por CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: [
    'Content-Type', 
    'Authorization', 
    'X-Requested-With',
    'X-Response-Time'
  ],
  maxAge: 86400
};

module.exports = {
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
};