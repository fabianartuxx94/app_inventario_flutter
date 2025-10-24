// 📁 app.js

const express = require("express");
const morgan = require("morgan");
const path = require("path");
const fs = require("fs");

// 🔐 Middleware personalizado de CORS
const cors = require("./middleware/cors");

// 📦 Rutas del sistema
const usuarios = require("./modulos/usuarios/rutas");
const categorias = require("./modulos/categorias/rutas");
const auth = require("./modulos/auth/rutas");
const articulos = require("./modulos/articulos/rutas");
const uploads = require("./modulos/uploads/rutas");
const marcas = require("./modulos/marcas/rutas");
const inventario = require("./modulos/inventario/rutas");
const asignaciones = require("./modulos/asignaciones/rutas");
const gestion = require("./modulos/gestion/rutas");
const actas = require("./modulos/actas/rutas");
const maps = require('./modulos/maps/rutas');
// 🔧 Configuración
const { app: _app } = require("./config");

// ❌ Manejo de errores
const error = require("./red/error");

const app = express();

// ------------------------------
// 🔧 Middleware global
// ------------------------------
app.use(cors); // CORS personalizado
app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ------------------------------
// 📁 Servir archivos estáticos
// ------------------------------

// Sirve imágenes desde: /uploads/images/articulos/*
const rutaUploads = path.join(__dirname, "uploads"); // backend/uploads
const rutaImagenesArticulos = path.join(rutaUploads, "images", "articulos");

app.use("/uploads/images/articulos", express.static(rutaImagenesArticulos));

// Diagnóstico para verificar archivos estáticos
app.get("/diagnostic/static-files", (req, res) => {
  const diagnostico = {
    ruta_uploads: rutaUploads,
    existe_uploads: fs.existsSync(rutaUploads),
    ruta_imagenes: rutaImagenesArticulos,
    existe_imagenes: fs.existsSync(rutaImagenesArticulos),
    archivos: []
  };

  console.log("🔍 DIAGNÓSTICO RUTA DE ARCHIVOS:");
  console.log("   Ruta uploads:", diagnostico.ruta_uploads);
  console.log("   Existe uploads:", diagnostico.existe_uploads);
  console.log("   Ruta imágenes:", diagnostico.ruta_imagenes);
  console.log("   Existe imágenes:", diagnostico.existe_imagenes);

  if (diagnostico.existe_imagenes) {
    diagnostico.archivos = fs.readdirSync(rutaImagenesArticulos);
    const archivo = "mouse_logitech_m185.jpg";
    const archivoPath = path.join(rutaImagenesArticulos, archivo);
    diagnostico.archivo_target = {
      nombre: archivo,
      existe: fs.existsSync(archivoPath),
      ruta_completa: archivoPath
    };
  }

  res.json(diagnostico);
});

// Ruta directa para test de imagen
app.get("/test-image", (req, res) => {
  const filePath = path.join(rutaImagenesArticulos, "mouse_logitech_m185.jpg");

  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).json({
      error: "Imagen no encontrada",
      ruta_buscada: filePath
    });
  }
});

// ------------------------------
// 🧩 API REST - Módulos del sistema
// ------------------------------
app.use("/api/categorias", categorias);
app.use("/api/usuarios", usuarios);
app.use("/api/auth", auth);
app.use("/api/articulos", articulos);
app.use("/api/marcas", marcas);
app.use("/api/inventario", inventario);
app.use("/api/asignaciones", asignaciones);
app.use("/api/gestion", gestion);
app.use("/api/actas", actas);
app.use("/api/maps", maps);
app.use("/api/uploads", uploads); // ¡Cuidado de no duplicar con `/uploads`!

// ------------------------------
// ❌ Manejo de errores centralizado
// ------------------------------
app.use(error);

// ------------------------------
// 🚀 Configuración del puerto
// ------------------------------
app.set("port", _app.port || 5000);

module.exports = app;
