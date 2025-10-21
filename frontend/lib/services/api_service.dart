import 'dart:convert';
import 'package:frontend/config/config.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl = AppConfig.apiUrl;

  static Future<Map<String, dynamic>?> loginWithUserData(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔑 Login response: $data');

        final body = data['body'];
        final token = body['token'];
        final usuario = body['usuario'];

        return {
          'token': token,
          'id': usuario['id'],
          'username': username,
          'nombre_completo': usuario['nombre_completo'],
          'rol': usuario['rol'],
        };
      } else {
        print('❌ Login failed with status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  // Método para verificar la conexión con el servidor
  static Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Server connection error: $e');
      return false;
    }
  }

  // Método para obtener artículos
  static Future<List<dynamic>?> getArticulos() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/articulos'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['body'] ?? [];
      } else {
        print('❌ Error fetching articulos: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error in getArticulos: $e');
      return null;
    }
  }

  // Método para crear artículo
  static Future<Map<String, dynamic>?> crearArticulo(Map<String, dynamic> articuloData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/articulos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(articuloData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('❌ Error creating articulo: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error in crearArticulo: $e');
      return null;
    }
  }

  // Método para actualizar artículo
  static Future<Map<String, dynamic>?> actualizarArticulo(int id, Map<String, dynamic> articuloData) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/articulos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(articuloData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('❌ Error updating articulo: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error in actualizarArticulo: $e');
      return null;
    }
  }

  // Método para eliminar artículo
  static Future<bool> eliminarArticulo(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/articulos/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error in eliminarArticulo: $e');
      return false;
    }
  }

  // Método para obtener categorías
  static Future<List<dynamic>?> getCategorias() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/categorias'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['body'] ?? [];
      } else {
        print('❌ Error fetching categorias: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error in getCategorias: $e');
      return null;
    }
  }
}