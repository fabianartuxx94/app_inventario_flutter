const jwt = require("jsonwebtoken");
config = require("../config");

const clave = config.jwt.clave;

function asignartoken(data) {
  return jwt.sign(data, clave, {
    expiresIn: config.jwt.tiempoExpiracion,
  });
}
module.exports = asignartoken;
