const express = require("express");
const multer = require("multer");
const path = require("path");
const router = express.Router();

// Configurar almacenamiento
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/images/articulos/");
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, "articulo-" + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB máximo
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp/;
    const extname = allowedTypes.test(
      path.extname(file.originalname).toLowerCase()
    );
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error("Solo se permiten imágenes JPEG, PNG, GIF o WebP"));
    }
  },
});

// Ruta para subir imagen
router.post("/image", upload.single("image"), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: "No se subió ninguna imagen",
      });
    }

    const imageUrl = `/uploads/images/articulos/${req.file.filename}`;

    res.json({
      success: true,
      message: "Imagen subida correctamente",
      imageUrl: imageUrl,
      filename: req.file.filename,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Error al subir imagen: " + error.message,
    });
  }
});

// Ruta para eliminar imagen
router.delete("/image/:filename", (req, res) => {
  try {
    const fs = require("fs");
    const filePath = path.join(
      __dirname,
      "../../../uploads/images/articulos/",
      req.params.filename
    );

    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      res.json({
        success: true,
        message: "Imagen eliminada correctamente",
      });
    } else {
      res.status(404).json({
        success: false,
        error: "Imagen no encontrada",
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Error al eliminar imagen: " + error.message,
    });
  }
});

module.exports = router;
