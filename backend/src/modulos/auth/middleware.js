const jwt = require("jsonwebtoken");
const config = require("../../config");

// 🔐 Verifica que el usuario tenga un token JWT válido
function verificarToken(req, res, next) {
  const header = req.headers["authorization"];

  if (!header) {
    return res.status(401).json({ error: "Token no proporcionado" });
  }

  // Espera formato: Bearer <token>
  const token = header.split(" ")[1];
  if (!token) {
    return res.status(401).json({ error: "Formato de token incorrecto" });
  }

  try {
    // Verifica y decodifica el token
    const decoded = jwt.verify(token, config.jwt.clave || process.env.JWT_SECRET );

    // ✅ El token incluye: id, username, rol y bodega
    req.user = {
      id: decoded.id,
      username: decoded.username,
      rol: decoded.rol,
      bodega: decoded.bodega ?? null, // puede venir null si es usuario consultor
    };

    next();
  } catch (error) {
    console.error("❌ Error al verificar token:", error.message);
    return res.status(401).json({ error: "Token inválido o expirado" });
  }
}

// 🔓 Verifica si el rol del usuario está autorizado para acceder a una ruta
function permitirRoles(...rolesPermitidos) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: "No autenticado" });
    }

    if (!rolesPermitidos.includes(req.user.rol)) {
      return res.status(403).json({ error: "Acceso denegado: rol insuficiente" });
    }

    next();
  };
}

module.exports = { verificarToken, permitirRoles };
