const jwt = require("jsonwebtoken");
const config = require("../config");

const clave = config.jwt.clave;

/*
 * Asigna un token JWT al usuario autenticado.
 * Incluye los campos id, username, rol y bodega.
 * 
 * @param {Object} usuario - Datos del usuario autenticado.
 * @returns {String} token firmado.
 */
function asignartoken(usuario) {
  // Validar que tenga los campos esperados
  const payload = {
    id: usuario.id,
    username: usuario.username,
    rol: usuario.rol,
    bodega: usuario.bodega || null, // puede ser null si no tiene bodega asignada
  };

  return jwt.sign(payload, clave, {
    expiresIn: config.jwt.tiempoExpiracion,
  });
}

module.exports = asignartoken;
