import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class CategoriasService {
  static const String _baseUrl = '${AppConfig.apiUrl}/categorias';

  /// Obtener lista completa de categorías
  static Future<List<Map<String, dynamic>>> getCategorias(String token) async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (kDebugMode) {
      print('📥 GET $_baseUrl');
      print('📥 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<Map<String, dynamic>> categorias =
          List<Map<String, dynamic>>.from(data['body']);

    
      return categorias;
    } else {
      throw Exception(
          'Error al obtener categorías: ${response.statusCode} ${response.body}');
    }
  }

  /// Crear o actualizar una categoría
  static Future<void> guardarCategoria(
    Map<String, dynamic> categoria,
    String token,
  ) async {
    // Normalizar datos
    final data = {
      "id": categoria["id"] ?? 0,
      "nombre": categoria["nombre"],
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (kDebugMode) {
      print('📤 POST $_baseUrl');
      print('📦 Enviado: ${jsonEncode(data)}');
      print('📥 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Error al crear o actualizar categoría: ${response.body}');
    }
  }

  /// Eliminar una categoría
  static Future<void> eliminarCategoria(int id, String token) async {
    final response = await http.delete(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"id": id}),
    );

    if (kDebugMode) {
      print('🗑️ DELETE $_baseUrl');
      print('📦 ID: $id');
      print('📥 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');
    }

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar categoría: ${response.body}');
    }
  }

  /// Crear categoría
  static Future<Map<String, dynamic>> crearCategoria(
      Map<String, dynamic> categoria, String token) async {
    await guardarCategoria(categoria, token);
    return {
      'success': true,
      'message': 'Categoría creada exitosamente',
    };
  }

  /// Actualizar categoría
  static Future<Map<String, dynamic>> actualizarCategoria(
      Map<String, dynamic> categoria, String token) async {
    await guardarCategoria(categoria, token);
    return {
      'success': true,
      'message': 'Categoría actualizada exitosamente',
    };
  }
}
