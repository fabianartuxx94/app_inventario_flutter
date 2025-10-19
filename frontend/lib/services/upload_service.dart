import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../config/config.dart';

class UploadService {
  // Cambiar de const a final (ya que no es constante en tiempo de compilación)
  static final String baseUrl = AppConfig.baseUrl;

  // Subir imagen con token y datos del artículo
  static Future<Map<String, dynamic>> uploadImage(
    File imageFile, 
    String token, {
    String? nombreArticulo,
    String? marca,
    String? referencia,
  }) async {
    try {
      if (kDebugMode) {
        print('🚀 ========== INICIANDO SUBIDA DE IMAGEN ==========');
      }
      if (kDebugMode) {
        print('📁 Archivo local: ${imageFile.path}');
      }
      if (kDebugMode) {
        print('📝 Datos para nombre descriptivo:');
      }
      if (kDebugMode) {
        print('   • Artículo: "${nombreArticulo ?? "NO PROPORCIONADO"}"');
      }
      if (kDebugMode) {
        print('   • Marca: "${marca ?? "NO PROPORCIONADA"}"');
      }
      if (kDebugMode) {
        print('   • Referencia: "${referencia ?? "NO PROPORCIONADA"}"');
      }
      if (kDebugMode) {
        print('   • Servidor: ${AppConfig.baseUrl}');
      }
      
      // Verificar que el archivo existe
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
        Uri.parse('$baseUrl/uploads/image'),
      );

      // Agregar headers con token
      request.headers['Authorization'] = 'Bearer $token';

      // Agregar archivo con content-type explícito
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', 
          imageFile.path,
          contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
        ),
      );

      // AGREGAR DATOS PARA EL NOMBRE - SIEMPRE enviar los datos
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
      if (kDebugMode) {
        print('   Campos enviados: ${request.fields}');
      }

      var response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (kDebugMode) {
        print('📊 RESPUESTA DEL SERVIDOR:');
      }
      if (kDebugMode) {
        print('   Status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('   Data: $data');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ IMAGEN SUBIDA EXITOSAMENTE');
        }
        if (kDebugMode) {
          print('   📸 URL: ${data['imageUrl']}');
        }
        if (kDebugMode) {
          print('   📄 Nombre archivo: ${data['filename']}');
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
    } catch (e) {
      if (kDebugMode) {
        print('💥 ERROR CRÍTICO EN UPLOAD: $e');
      }
      return {
        'success': false, 
        'error': 'Error de conexión: $e'
      };
    }
  }

  // Diagnosticar estado de uploads
  static Future<Map<String, dynamic>> diagnostic(String token) async {
    try {
      if (kDebugMode) {
        print('🔍 Solicitando diagnóstico del servidor...');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/uploads/diagnostic'),
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

  // URL completa para mostrar imágenes - MEJORADA
  static String getImageUrl(String imagePath) {
  if (imagePath.startsWith('http')) return imagePath;
  
  if (kDebugMode) {
    print('🔍 CONSTRUYENDO URL PARA: "$imagePath"');
  }
  
  // CASO 1: Si la ruta YA es correcta (/uploads/images/articulos/...)
  if (imagePath.startsWith('/uploads/')) {
    final url = '${AppConfig.baseUrl}$imagePath';
    if (kDebugMode) {
      print('   🎯 URL desde ruta uploads: $url');
    }
    return url;
  }
  
  // CASO 2: Si es solo el nombre del archivo
  if (!imagePath.contains('/')) {
    final url = '${AppConfig. baseUrl}/images/articulos/$imagePath';
    if (kDebugMode) {
      print('   🎯 URL desde nombre archivo: $url');
    }
    return url;
  }
  
  // CASO 3: Para cualquier otro caso
  final url = '${AppConfig.baseUrl}/$imagePath';
  if (kDebugMode) {
    print('   🎯 URL desde ruta relativa: $url');
  }
  return url;
}
  // Verificar si una imagen existe en el servidor
  static Future<bool> verifyImageExists(String imageUrl, String token) async {
    final client = http.Client();
    try {
      final url = getImageUrl(imageUrl);
      if (kDebugMode) {
        print('🔍 Verificando existencia de imagen: $url');
      }
      
      final response = await client
          .get(Uri.parse(url))
          .timeout(Duration(seconds: 5));
      
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

  // Método para probar la conexión al servidor
  static Future<Map<String, dynamic>> testConnection() async {
    final client = http.Client();
    try {
      if (kDebugMode) {
        print('🔍 Probando conexión con servidor: ${AppConfig.baseUrl}');
      }
      
      final response = await client
          .get(Uri.parse(AppConfig.baseUrl))
          .timeout(Duration(seconds: 5));
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': response.statusCode == 200 ? 'Conexión exitosa' : 'Error de conexión',
      };
    } on TimeoutException {
      if (kDebugMode) {
        print('❌ Timeout: No se pudo conectar al servidor en 5 segundos');
      }
      return {
        'success': false,
        'error': 'Timeout: El servidor no respondió',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error probando conexión: $e');
      }
      return {
        'success': false,
        'error': 'No se pudo conectar al servidor: $e',
      };
    } finally {
      client.close();
    }
  }
}