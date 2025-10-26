require("dotenv").config();

module.exports = {
  app: {
    port: process.env.PORT || 5000,
  },

  jwt: {
    clave: process.env.JWT_SECRET || "suchance27",
    tiempoExpiracion: process.env.JWT_TIEMPO_EXPIRACION || "6h",
  },

  mysql: {
    host: process.env.MYSQL_HOST || "localhost",
    user: process.env.MYSQL_USER || "root",
    password: process.env.MYSQL_PASSWORD || "",
    database: process.env.MYSQL_DATABASE || "inventario_bodega",
  },
};