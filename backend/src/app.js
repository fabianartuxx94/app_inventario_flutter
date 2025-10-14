const express = require("express");
const morgan = require("morgan");
const usuarios = require("./modulos/usuarios/rutas");
const catalogo = require("./modulos/catalogo/rutas");
const auth = require("./modulos/auth/rutas");
const articulos = require("./modulos/articulos/rutas");
const uploads = require("./modulos/uploads/rutas"); // ← NUEVO MÓDULO
const { app: _app } = require("./config");
const error = require("./red/error");

const app = express();

// middlewares
app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static("uploads")); // Servir archivos estáticos

// configuracion
app.set("port", _app.port);

// rutas
app.use("/api/catalogo/", catalogo);
app.use("/api/usuarios/", usuarios);
app.use("/api/auth/", auth);
app.use("/api/articulos/", articulos);
app.use("/api/uploads/", uploads); // ← NUEVA RUTA

// manejo de errores
app.use(error);

module.exports = app;
