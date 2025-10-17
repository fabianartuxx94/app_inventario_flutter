const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

const router = express.Router();

// 📁 CONFIGURACIÓN CORREGIDA - DIRECTORIO DESTINO
const getUploadsPath = () => {
  // Ruta ABSOLUTA hacia src/uploads/images/articulos/
  const baseDir = process.cwd(); // Directorio raíz del proyecto
  const targetPath = path.join(baseDir, 'src', 'uploads', 'images', 'articulos');
  
  console.log("📍 RUTA DESTINO CONFIGURADA:");
  console.log("   Base:", baseDir);
  console.log("   Destino:", targetPath);
  
  return targetPath;
};

// Función para limpiar nombres de archivo (mantén la que tienes)
const formatFileName = (text) => {
  if (!text || text === 'null' || text === 'undefined') return '';
  return text
    .toString()
    .toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, '_')
    .replace(/[^\w\-]+/g, '')
    .replace(/\-\-+/g, '_')
    .replace(/^-+/, '')
    .replace(/-+$/, '')
    .substring(0, 30);
};

// ✅ CONFIGURACIÓN MULTER CORREGIDA
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadsDir = getUploadsPath();
    
    console.log("🔄 CONFIGURANDO DESTINO:");
    console.log("   📁 Ruta destino:", uploadsDir);
    
    // Crear directorio si no existe
    if (!fs.existsSync(uploadsDir)) {
      console.log("   📂 Creando directorio...");
      try {
        fs.mkdirSync(uploadsDir, { recursive: true });
        console.log("   ✅ Directorio creado exitosamente");
      } catch (error) {
        console.log("   ❌ ERROR creando directorio:", error.message);
        return cb(error);
      }
    } else {
      console.log("   ✅ Directorio ya existe");
    }
    
    // Verificar permisos
    try {
      const testFile = path.join(uploadsDir, 'test_permissions.txt');
      fs.writeFileSync(testFile, 'test');
      fs.unlinkSync(testFile);
      console.log("   ✅ Permisos de escritura: OK");
    } catch (writeError) {
      console.log("   ❌ SIN PERMISOS DE ESCRITURA:", writeError.message);
      return cb(writeError);
    }
    
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const fileExtension = path.extname(file.originalname).toLowerCase();
    
    const { nombre_articulo, marca, referencia } = req.body;
    
    console.log("📝 CREANDO NOMBRE DE ARCHIVO:");
    console.log("   - Artículo:", nombre_articulo);
    console.log("   - Marca:", marca);
    console.log("   - Referencia:", referencia);
    
    let fileName = "";
    const nombreClean = formatFileName(nombre_articulo) || 'articulo';
    const marcaClean = formatFileName(marca);
    const referenciaClean = formatFileName(referencia);
    
    if (nombreClean && marcaClean && referenciaClean) {
      fileName = `${nombreClean}_${marcaClean}_${referenciaClean}${fileExtension}`;
    } else if (nombreClean && marcaClean) {
      fileName = `${nombreClean}_${marcaClean}${fileExtension}`;
    } else if (nombreClean) {
      fileName = `${nombreClean}${fileExtension}`;
    } else {
      fileName = `articulo_${Date.now()}${fileExtension}`;
    }
    
    console.log("   📸 Archivo final:", fileName);
    cb(null, fileName);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const fileExtension = path.extname(file.originalname).toLowerCase();
    
    console.log("🔍 Validando archivo:", file.originalname);
    
    if (allowedExtensions.includes(fileExtension)) {
      cb(null, true);
    } else {
      console.log("❌ Archivo rechazado - Extensión no permitida");
      cb(new Error(`Tipo de archivo no permitido. Solo: ${allowedExtensions.join(', ')}`), false);
    }
  },
});

// ✅ RUTA PRINCIPAL CORREGIDA
router.post("/image", upload.single("image"), (req, res) => {
  try {
    if (!req.file) {
      console.log("❌ No se recibió archivo");
      return res.status(400).json({
        success: false,
        error: "No se subió ninguna imagen",
      });
    }

    console.log("✅ ARCHIVO SUBIDO EXITOSAMENTE:");
    console.log("   📄 Nombre:", req.file.filename);
    console.log("   📍 Ruta física:", req.file.path);
    console.log("   💾 Tamaño:", req.file.size, "bytes");

    // Verificar que el archivo se guardó
    const fileExists = fs.existsSync(req.file.path);
    if (!fileExists) {
      console.log("❌ ERROR: Archivo no se guardó físicamente");
      return res.status(500).json({
        success: false,
        error: "El archivo no se guardó en el servidor",
      });
    }

    const imageUrl = `/uploads/images/articulos/${req.file.filename}`;

    res.json({
      success: true,
      message: "Imagen subida correctamente",
      imageUrl: imageUrl,
      filename: req.file.filename
    });
  } catch (error) {
    console.error("❌ ERROR:", error);
    res.status(500).json({
      success: false,
      error: "Error al subir imagen: " + error.message,
    });
  }
});

// ✅ DIAGNÓSTICO CORREGIDO
router.get("/diagnostic", (req, res) => {
  try {
    const articulosPath = getUploadsPath();
    
    console.log("🔍 DIAGNÓSTICO - Ruta verificada:", articulosPath);
    
    const info = {
      ruta_absoluta: articulosPath,
      existe_directorio: fs.existsSync(articulosPath),
      archivos: []
    };
    
    if (info.existe_directorio) {
      const files = fs.readdirSync(articulosPath);
      info.archivos = files.map(file => {
        const filePath = path.join(articulosPath, file);
        const stats = fs.statSync(filePath);
        return {
          nombre: file,
          tamaño: stats.size,
          fecha: stats.mtime
        };
      });
      info.total_archivos = files.length;
    }
    
    console.log("📊 RESULTADO DIAGNÓSTICO:", info);
    res.json(info);
  } catch (error) {
    console.error("❌ ERROR EN DIAGNÓSTICO:", error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;