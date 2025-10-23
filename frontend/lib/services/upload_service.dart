import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../config/config.dart';

// Importación condicional para web

class UploadService {
  static final String baseUrl = AppConfig.baseUrl;
  static final String apiUrl = AppConfig.apiUrl;

  // Subir imagen compatible con Web y Móvil
  static Future<Map<String, dynamic>> uploadImage(
  dynamic imageData, // Cambia de File a dynamic
  String token, {
  String? nombreArticulo,
  String? marca,
  String? referencia,
}) async {
  try {
    if (kIsWeb) {
      if (imageData is Map && imageData['bytes'] != null) {
        // ✅ Manejar imagen web con bytes
        return await _uploadImageWeb(
          imageData['bytes'],
          token,
          nombreArticulo: nombreArticulo,
          marca: marca,
          referencia: referencia,
        );
      }
    } else {
      if (imageData is File) {
        // ✅ Manejar imagen móvil/escritorio con File
        return await _uploadImageMobile(
          imageData,
          token,
          nombreArticulo: nombreArticulo,
          marca: marca,
          referencia: referencia,
        );
      }
    }
    
    return {
      'success': false,
      'error': 'Tipo de imagen no soportado'
    };
  } catch (e) {
    return {
      'success': false, 
      'error': 'Error procesando imagen: $e'
    };
  }
}

  // VERSIÓN PARA MÓVIL
  static Future<Map<String, dynamic>> _uploadImageMobile(
    File imageFile,
    String token, {
    String? nombreArticulo,
    String? marca,
    String? referencia,
  }) async {
    if (kDebugMode) {
      print('📁 Archivo local: ${imageFile.path}');
    }

    if (!await imageFile.exists()) {
      if (kDebugMode) {
        print('❌ EL ARCHIVO NO EXISTE LOCALMENTE');
      }
      return {
        'success': false,
        'error': 'El archivo no existe'
      };
    }

    final mimeType = lookupMimeType(imageFile.path);
    if (kDebugMode) {
      print('🔍 Mime type detectado: $mimeType');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/uploads/image'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'image', 
        imageFile.path,
        contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
      ),
    );

    request.fields['nombre_articulo'] = nombreArticulo ?? 'articulo';
    if (marca != null && marca.isNotEmpty) {
      request.fields['marca'] = marca;
    }
    if (referencia != null && referencia.isNotEmpty) {
      request.fields['referencia'] = referencia;
    }

    if (kDebugMode) {
      print('📦 Enviando solicitud al servidor...');
    }

    var response = await request.send();
    final responseData = await response.stream.bytesToString();
    final data = jsonDecode(responseData);

    return _handleServerResponse(response, data);
  }

  // VERSIÓN PARA WEB
  static Future<Map<String, dynamic>> _uploadImageWeb(
    dynamic webFile,
    String token, {
    String? nombreArticulo,
    String? marca,
    String? referencia,
  }) async {
    try {
      if (kDebugMode) {
        print('🌐 Procesando archivo para web...');
      }

      Uint8List fileBytes;
      String fileName;
      String mimeType;

      // Manejar diferentes tipos de entrada para web
      if (webFile is Uint8List) {
        fileBytes = webFile;
        fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        mimeType = 'image/jpeg';
      } else if (webFile is http.MultipartFile) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$apiUrl/uploads/image'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(webFile);

        request.fields['nombre_articulo'] = nombreArticulo ?? 'articulo';
        if (marca != null && marca.isNotEmpty) {
          request.fields['marca'] = marca;
        }
        if (referencia != null && referencia.isNotEmpty) {
          request.fields['referencia'] = referencia;
        }

        var response = await request.send();
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);

        return _handleServerResponse(response, data);
      } else {
        return {
          'success': false,
          'error': 'Tipo de archivo no soportado en web'
        };
      }

      // Crear solicitud multipart para web
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/uploads/image'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ));

      request.fields['nombre_articulo'] = nombreArticulo ?? 'articulo';
      if (marca != null && marca.isNotEmpty) {
        request.fields['marca'] = marca;
      }
      if (referencia != null && referencia.isNotEmpty) {
        request.fields['referencia'] = referencia;
      }

      if (kDebugMode) {
        print('📦 Enviando solicitud al servidor desde web...');
      }

      var response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      return _handleServerResponse(response, data);
    } catch (e) {
      if (kDebugMode) {
        print('💥 ERROR en upload web: $e');
      }
      return {
        'success': false,
        'error': 'Error en subida web: $e'
      };
    }
  }

  // MANEJO COMÚN DE RESPUESTA
  static Map<String, dynamic> _handleServerResponse(
    http.StreamedResponse response, 
    Map<String, dynamic> data
  ) {
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('✅ IMAGEN SUBIDA EXITOSAMENTE');
        print('   📸 URL: ${data['imageUrl']}');
      }
      return {
        'success': true,
        'imageUrl': data['imageUrl'],
        'message': data['message'],
        'filename': data['filename'],
      };
    } else {
      if (kDebugMode) {
        print('❌ ERROR EN RESPUESTA DEL SERVIDOR');
      }
      return {
        'success': false,
        'error': data['error'] ?? 'Error al subir imagen (${response.statusCode})',
      };
    }
  }

  // ✅ MÉTODO MEJORADO PARA SELECCIONAR IMAGEN EN WEB
  static Future<Uint8List?> pickImageWeb() async {
    if (!kIsWeb) {
      if (kDebugMode) {
        print('❌ Este método solo está disponible en web');
      }
      return null;
    }

    try {
      // Usar un file picker multiplataforma en lugar de dart:html
      return await _showFilePickerWeb();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error seleccionando imagen en web: $e');
      }
      return null;
    }
  }

  // ✅ MÉTODO PRIVADO PARA WEB CON IMPLEMENTACIÓN ALTERNATIVA
  static Future<Uint8List?> _showFilePickerWeb() async {
    // Esta función necesita ser implementada en tu widget
    // ya que requiere interacción con la UI
    if (kDebugMode) {
      print('📁 Mostrando selector de archivos para web...');
    }
    
    // En lugar de implementar aquí, delegamos a la UI
    // Retornamos null y manejamos la selección en el widget
    return null;
  }

  // ✅ MÉTODO PARA CREAR MULTIPART FILE DESDE BYTES (Útil para web)
  static http.MultipartFile createMultipartFileFromBytes(
    Uint8List bytes, {
    String filename = 'image.jpg',
    String mimeType = 'image/jpeg',
  }) {
    return http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    );
  }

  // Los demás métodos se mantienen igual...
  static Future<Map<String, dynamic>> diagnostic(String token) async {
    try {
      if (kDebugMode) {
        print('🔍 Solicitando diagnóstico del servidor...');
      }
      
      final response = await http.get(
        Uri.parse('$apiUrl/uploads/diagnostic'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (kDebugMode) {
        print('📊 DIAGNÓSTICO RECIBIDO: $data');
      }
      
      return {
        'success': response.statusCode == 200,
        'data': data,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en diagnóstico: $e');
      }
      return {
        'success': false, 
        'error': 'Error de conexión: $e'
      };
    }
  }

  static String getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) return imagePath;
    
    if (imagePath.startsWith('/uploads/')) {
      return '${AppConfig.baseUrl}$imagePath';
    }
    
    if (!imagePath.contains('/')) {
      return '${AppConfig.baseUrl}/uploads/images/articulos/$imagePath';
    }
    
    return '${AppConfig.baseUrl}/$imagePath';
  }

  static Future<bool> verifyImageExists(String imageUrl, String token) async {
    final client = http.Client();
    try {
      final url = getImageUrl(imageUrl);
      if (kDebugMode) {
        print('🔍 Verificando existencia de imagen: $url');
      }
      
      final response = await client
          .get(Uri.parse(url))
          .timeout(Duration(seconds: 15));
      
      final exists = response.statusCode == 200;
      if (kDebugMode) {
        print('   ${exists ? '✅' : '❌'} Imagen ${exists ? 'EXISTE' : 'NO EXISTE'}');
      }
      
      return exists;
    } on TimeoutException {
      if (kDebugMode) {
        print('❌ Timeout verificando imagen');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error verificando imagen: $e');
      }
      return false;
    } finally {
      client.close();
    }
  }
}