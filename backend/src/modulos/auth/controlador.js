const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const TABLA = "usuarios";

module.exports = function (dbInyectada) {
  let db = dbInyectada;
  if (!db) {
    db = require("../../DB/mysql");
  }

  async function login(username, password) {
    // Buscar usuario por username usando la función 'buscar'
    const usuario = await db.buscar(TABLA, "username", username);

    if (!usuario) {
      throw new Error("Usuario no encontrado");
    }

    if (!usuario.activo) {
      throw new Error("Cuenta inactiva");
    }

    // Verificar contraseña usando el campo 'password_hash'
    const passwordValida = await bcrypt.compare(
      password,
      usuario.password_hash
    );
    if (!passwordValida) {
      throw new Error("Contraseña incorrecta");
    }

    // Crear token JWT
    const payload = {
      id: usuario.id,
      username: usuario.username,
      rol: usuario.rol,
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET || "suchance27", {
      expiresIn: "2h",
    });

    return {
      message: "Login exitoso",
      token,
      usuario: {
        id: usuario.id,
        nombre_completo: usuario.nombre_completo,
        rol: usuario.rol,
      },
    };
  }

  return { login };
};
