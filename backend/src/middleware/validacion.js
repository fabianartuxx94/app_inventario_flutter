// 🎯 VALIDACIÓN CENTRALIZADA (sin express-validator)
const { verificarToken } = require('../modulos/auth/middleware');

class Validator {
  static validatePagination(req, res, next) {
    const { page, limit, search } = req.query;
    
    if (page && (!Number.isInteger(Number(page)) || Number(page) < 1)) {
      return res.status(400).json({
        error: true,
        message: 'Page debe ser un número mayor a 0'
      });
    }
    
    if (limit && (!Number.isInteger(Number(limit)) || Number(limit) < 1 || Number(limit) > 100)) {
      return res.status(400).json({
        error: true,
        message: 'Limit debe estar entre 1 y 100'
      });
    }
    
    if (search && search.length > 100) {
      return res.status(400).json({
        error: true,
        message: 'Search máximo 100 caracteres'
      });
    }
    
    next();
  }

  static validateID(req, res, next) {
    const id = Number(req.params.id);
    if (!id || id < 1) {
      return res.status(400).json({
        error: true,
        message: 'ID debe ser un número válido'
      });
    }
    next();
  }

  static validateInventario(req, res, next) {
    const { articulo_id, estado, cantidad, bodega } = req.body;
    const errors = [];

    if (!articulo_id || !Number.isInteger(Number(articulo_id)) || Number(articulo_id) < 1) {
      errors.push('articulo_id es requerido y debe ser un número válido');
    }

    if (!estado || !['Nuevo', 'Bueno', 'Reparacion', 'Baja'].includes(estado)) {
      errors.push('Estado inválido. Valores permitidos: Nuevo, Bueno, Reparacion, Baja');
    }

    if (cantidad && (isNaN(Number(cantidad)) || Number(cantidad) < 0)) {
      errors.push('Cantidad debe ser un número positivo');
    }

    if (!bodega || typeof bodega !== 'string' || bodega.length > 50) {
      errors.push('Bodega es requerida y máximo 50 caracteres');
    }

    if (errors.length > 0) {
      return res.status(400).json({
        error: true,
        message: 'Datos de entrada inválidos',
        detalles: errors
      });
    }

    next();
  }

  static validateLogin(req, res, next) {
    const { username, password } = req.body;
    const errors = [];

    if (!username || typeof username !== 'string' || username.length < 3 || username.length > 50) {
      errors.push('Username debe tener entre 3 y 50 caracteres');
    }

    if (!password || typeof password !== 'string' || password.length < 6) {
      errors.push('Password debe tener al menos 6 caracteres');
    }

    if (errors.length > 0) {
      return res.status(400).json({
        error: true,
        message: 'Datos de login inválidos',
        detalles: errors
      });
    }

    next();
  }
}

// 🎯 MIDDLEWARES COMPUESTOS
const validarListarConPaginacion = [
  verificarToken,
  Validator.validatePagination
];

const validarCrearInventario = [
  verificarToken,
  Validator.validateInventario
];

const validarLogin = [
  Validator.validateLogin
];

module.exports = {
  Validator,
  validarListarConPaginacion,
  validarCrearInventario,
  validarLogin
};