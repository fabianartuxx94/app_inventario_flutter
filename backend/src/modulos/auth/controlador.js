const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const TABLA = "usuarios";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) {
    db = require("../../DB/mysql");
  }

  async function login(username, password) {
    // 🔍 Buscar usuario por username
    const usuario = await db.buscar(TABLA, "username", username);

    if (!usuario) {
      throw new Error("Usuario no encontrado");
    }

    if (!usuario.activo) {
      throw new Error("Cuenta inactiva");
    }

    // 🔐 Verificar contraseña usando el campo 'password_hash'
    const passwordValida = await bcrypt.compare(password, usuario.password_hash);
    if (!passwordValida) {
      throw new Error("Contraseña incorrecta");
    }

    // 🧩 Crear token JWT con los campos completos
    const payload = {
      id: usuario.id,
      username: usuario.username,
      rol: usuario.rol,
      bodega: usuario.bodega || null, // puede ser null si el usuario es solo de consulta
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET , {
      expiresIn: "6h",
    });

    // ✅ Devolver datos útiles al frontend
    return {
      message: "Login exitoso",
      token,
      usuario: {
        id: usuario.id,
        nombre_completo: usuario.nombre_completo,
        username: usuario.username,
        rol: usuario.rol,
        bodega: usuario.bodega || null,
      },
    };
  }

  return { login };
};
