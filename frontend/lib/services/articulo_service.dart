import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/articulo_model.dart';
import '../config/config.dart';

class ArticuloService {
  static final String baseUrl = AppConfig.apiUrl;

  // OBTENER TODOS LOS ARTÍCULOS
  static Future<List<Articulo>> obtenerArticulos(String token) async {
    try {
      print('🔍 Solicitando artículos desde: $baseUrl/articulos/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/articulos/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Respuesta del servidor - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['body'] != null && data['body'] is List) {
          final articulosList = data['body'] as List;
          print('✅ Se obtuvieron ${articulosList.length} artículos desde "body"');
          
          final articulos = articulosList.map((item) {
            return Articulo.fromJson(Map<String, dynamic>.from(item));
          }).toList();
          
          return articulos;
        } else {
          print('⚠️  La respuesta no contiene "body" con datos');
          return [];
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        throw Exception('Error al obtener artículos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error obteniendo artículos: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // CREAR NUEVO ARTÍCULO
  static Future<Map<String, dynamic>> crearArticulo(Articulo articulo, String token) async {
    try {
      print('🆕 Creando nuevo artículo...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/articulos/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(articulo.toJson()),
      );

      final data = jsonDecode(response.body);
      print('📊 Respuesta creación - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = data['body'] ?? data;
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Artículo creado correctamente',
          'id_general': responseBody['id_general'],
          'id_catalogo': responseBody['id_catalogo'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al crear artículo (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error creando artículo: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ACTUALIZAR ARTÍCULO EXISTENTE - CORREGIDO (POST en lugar de PUT)
static Future<Map<String, dynamic>> actualizarArticulo(Articulo articulo, String token) async {
  try {
    print('✏️ Actualizando artículo ID: ${articulo.idCatalogo}');
    
    // ✅ VERIFICAR QUE imagen_path ESTÉ INCLUIDO
    final datos = articulo.toJson();
    print('📦 DATOS COMPLETOS A ENVIAR:');
    print('   imagen_path: ${datos['imagen_path']}');
    print('   Todos los campos: $datos');
    
    final response = await http.post(
      Uri.parse('$baseUrl/articulos/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(datos),
    );

    final data = jsonDecode(response.body);
    print('📊 Respuesta actualización - Status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = data['body'] ?? data;
      return {
        'success': true,
        'message': responseBody['message'] ?? 'Artículo actualizado correctamente',
        'id_general': responseBody['id_general'],
        'id_catalogo': responseBody['id_catalogo'],
      };
    } else {
      return {
        'success': false,
        'error': data['error'] ?? 'Error al actualizar artículo (${response.statusCode})',
      };
    }
  } catch (e) {
    print('❌ Error actualizando artículo: $e');
    return {
      'success': false,
      'error': 'Error de conexión: $e',
    };
  }
}

  // ELIMINAR ARTÍCULO
  static Future<Map<String, dynamic>> eliminarArticulo(int idCatalogo, String token) async {
    try {
      print('🗑️ Eliminando artículo ID: $idCatalogo');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/articulos/$idCatalogo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      print('📊 Respuesta eliminación - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = data['body'] ?? data;
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Artículo eliminado correctamente',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al eliminar artículo (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error eliminando artículo: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // OBTENER ARTÍCULO POR ID
  static Future<Articulo?> obtenerArticuloPorId(int idCatalogo, String token) async {
    try {
      print('🔍 Obteniendo artículo por ID: $idCatalogo');
      
      final response = await http.get(
        Uri.parse('$baseUrl/articulos/$idCatalogo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final articuloData = data['body'] ?? data;
        if (articuloData != null && articuloData is Map) {
          print('✅ Artículo obtenido correctamente');
          return Articulo.fromJson(Map<String, dynamic>.from(articuloData));
        } else {
          print('⚠️  No se encontró el artículo');
          return null;
        }
      } else {
        print('❌ Error obteniendo artículo: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo artículo por ID: $e');
      return null;
    }
  }
}