// middleware/cors.js
const cors = require('cors');

const corsOptions = {
  origin: function (origin, callback) {
    // Permitir localhost y tu IP para desarrollo
    const allowedOrigins = [
      'http://localhost:5000',
      'http://127.0.0.1:5000',
      'http://localhost:5000',
      'http://10.192.84.125:5000', // Tu IP para desarrollo web
      'http://localhost:62941'
    ];
    
    if (!origin || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('No permitido por CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
};

module.exports = cors(corsOptions);