import 'dart:convert';

import 'package:frontend/config/config.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl = AppConfig.apiUrl;

  // LOGIN
  static Future<Map<String, dynamic>?> loginWithUserData(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final body = data['body'];

        final token = body['token'];
        final usuario = body['usuario'];

        return {
          'token': token,
          'id': usuario['id'],
          'username': usuario['username'] ?? username,
          'nombre_completo': usuario['nombre_completo'],
          'rol': usuario['rol'],
          'bodega': usuario['bodega'], // Nuevo campo
        };
      } else {
        print('❌ Login failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  // HEALTH CHECK
  static Future<bool> checkServerConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/health'),
              headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Server connection error: $e');
      return false;
    }
  }

  // ARTÍCULOS
  static Future<List<dynamic>?> getArticulos(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/articulos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

  // CREAR ARTÍCULO
  static Future<Map<String, dynamic>?> crearArticulo(
      String token, Map<String, dynamic> articuloData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/articulos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

  // ACTUALIZAR ARTÍCULO
  static Future<Map<String, dynamic>?> actualizarArticulo(
      String token, int id, Map<String, dynamic> articuloData) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/articulos/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

  // ELIMINAR ARTÍCULO
  static Future<bool> eliminarArticulo(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/articulos/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error in eliminarArticulo: $e');
      return false;
    }
  }

  // CATEGORÍAS
  static Future<List<dynamic>?> getCategorias(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/categorias'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
  Future<http.Response> patch(
  String endpoint, {
  Map<String, dynamic>? body,
  Map<String, String>? queryParams,
  required String token,
}) async {
  final Uri uri = Uri.parse('${AppConfig.apiUrl}$endpoint').replace(
    queryParameters: queryParams,
  );

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  return await http.patch(
    uri,
    headers: headers,
    body: body != null ? json.encode(body) : null,
  );
}
}
