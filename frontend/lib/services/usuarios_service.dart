import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/config.dart';
import '../providers/auth_provider.dart';

class UsuariosService {
  static String get baseUrl => AppConfig.apiUrl;

  // 🧭 Obtener token del proveedor
  static Future<String?> _obtenerToken(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isTokenValid) {
        final tokenCargado = await authProvider.loadStoredToken();
        if (!tokenCargado) return null;
      }
      return authProvider.token;
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      return null;
    }
  }

  // 📥 Obtener lista de usuarios
  static Future<List<dynamic>?> getUsuarios(BuildContext context) async {
    try {
      final token = await _obtenerToken(context);
      if (token == null) throw Exception('No hay token');

      print('🔑 Enviando token: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/usuarios'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 GET /usuarios - Status: ${response.statusCode}');
      print('📡 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['body'] ?? data['usuarios'] ?? [];
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getUsuarios: $e');
      rethrow;
    }
  }

  // 🧩 Crear usuario
  static Future<dynamic> crearUsuario(
      Map<String, dynamic> data, BuildContext context) async {
    try {
      final token = await _obtenerToken(context);
      if (token == null) throw Exception('No hay token');

      final response = await http.post(
        Uri.parse('$baseUrl/usuarios'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      print('📡 POST /usuarios - Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        throw Exception('Error al crear: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error crearUsuario: $e');
      rethrow;
    }
  }

// ✏️ Actualizar usuario - MODIFICADO para usar POST
static Future<dynamic> actualizarUsuario(
    String id, Map<String, dynamic> data, BuildContext context) async {
  try {
    final token = await _obtenerToken(context);
    if (token == null) throw Exception('No hay token');

    // Incluir el ID en los datos para que el backend detecte que es actualización
    data['id'] = id;

    final response = await http.post( // CAMBIADO de PUT a POST
      Uri.parse('$baseUrl/usuarios'), // MISMA URL que crear usuario
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    print('📡 POST /usuarios (actualizar) - Status: ${response.statusCode}');
    print('📦 Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Token inválido o expirado');
    } else {
      throw Exception('Error al actualizar: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error actualizarUsuario: $e');
    rethrow;
  }
}

  // 🗑️ Eliminar usuario
  static Future<bool> eliminarUsuario(String id, BuildContext context) async {
    try {
      final token = await _obtenerToken(context);
      if (token == null) throw Exception('No hay token');

      final response = await http.delete(
        Uri.parse('$baseUrl/usuarios/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 DELETE /usuarios/$id - Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error eliminarUsuario: $e');
      return false;
    }
  }
}
