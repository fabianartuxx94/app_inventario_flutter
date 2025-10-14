const jwt = require("jsonwebtoken");

// Verifica que el usuario tenga un token válido
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
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "suchance27");
    req.usuario = decoded; // ← aquí quedan disponibles id, username y rol
    next();
  } catch (error) {
    return res.status(401).json({ error: "Token inválido o expirado" });
  }
}

// Verifica si el rol del usuario está autorizado
function permitirRoles(...rolesPermitidos) {
  return (req, res, next) => {
    if (!req.usuario) {
      return res.status(401).json({ error: "No autenticado" });
    }

    if (!rolesPermitidos.includes(req.usuario.rol)) {
      return res.status(403).json({ error: "Acceso denegado: rol insuficiente" });
    }

    next();
  };
}

module.exports = { verificarToken, permitirRoles };
