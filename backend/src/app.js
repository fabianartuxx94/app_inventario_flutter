const express = require("express");
const morgan = require("morgan");
const path = require("path");
const fs = require("fs");
const cors = require("./middleware/cors"); //
const usuarios = require("./modulos/usuarios/rutas");
const catalogo = require("./modulos/catalogo/rutas");
const auth = require("./modulos/auth/rutas");
const articulos = require("./modulos/articulos/rutas");
const uploads = require("./modulos/uploads/rutas");
const { app: _app } = require("./config");
const error = require("./red/error");

const app = express();

// ✅ Aplica CORS personalizado (antes de cualquier ruta)
app.use(cors);

// middlewares

app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 📁 RUTA CORREGIDA - __dirname ya es "backend/src"
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Diagnóstico mejorado
app.get("/diagnostic/static-files", (req, res) => {
  const uploadsPath = path.join(__dirname, "uploads");
  const imagesPath = path.join(uploadsPath, "images", "articulos");
  
  const diagnostico = {
    ruta_uploads: uploadsPath,
    existe_uploads: fs.existsSync(uploadsPath),
    ruta_imagenes: imagesPath,
    existe_imagenes: fs.existsSync(imagesPath),
    archivos: []
  };

  console.log("🔍 DIAGNÓSTICO CON ESTRUCTURA REAL:");
  console.log("   __dirname:", __dirname);
  console.log("   Ruta uploads:", diagnostico.ruta_uploads);
  console.log("   Existe uploads:", diagnostico.existe_uploads);
  console.log("   Ruta imágenes:", diagnostico.ruta_imagenes);
  console.log("   Existe imágenes:", diagnostico.existe_imagenes);

  if (diagnostico.existe_imagenes) {
    diagnostico.archivos = fs.readdirSync(imagesPath);
    console.log("   Archivos en articulos/:", diagnostico.archivos);
    
    // Verificar el archivo específico
    const archivoTarget = "mouse_logitech_m185.jpg";
    const archivoPath = path.join(imagesPath, archivoTarget);
    diagnostico.archivo_target = {
      nombre: archivoTarget,
      existe: fs.existsSync(archivoPath),
      ruta_completa: archivoPath
    };
    console.log("   Archivo específico:", diagnostico.archivo_target);
  }

  res.json(diagnostico);
});

// Ruta de prueba directa para la imagen
app.get("/test-image", (req, res) => {
  const imagePath = path.join(__dirname, "uploads", "images", "articulos", "mouse_logitech_m185.jpg");
  
  console.log("🖼️  INTENTANDO SERVIR IMAGEN:");
  console.log("   Ruta:", imagePath);
  console.log("   Existe:", fs.existsSync(imagePath));
  
  if (fs.existsSync(imagePath)) {
    res.sendFile(imagePath);
  } else {
    res.status(404).json({
      error: "Imagen no encontrada",
      ruta_buscada: imagePath
    });
  }
});

// configuracion
app.set("port", _app.port);

// rutas
app.use("/api/catalogo/", catalogo);
app.use("/api/usuarios/", usuarios);
app.use("/api/auth/", auth);
app.use("/api/articulos/", articulos);
app.use("/api/uploads/", uploads);

// manejo de errores
app.use(error);

module.exports = app;