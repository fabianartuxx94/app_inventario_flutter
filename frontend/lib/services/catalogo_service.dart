import 'dart:convert';
import 'package:http/http.dart' as http;

class CatalogoService {
  static const String _baseUrl =
      'http://192.168.0.102:5000/api/catalogo'; // Emulador Android

  /// Obtener lista completa del catálogo
  static Future<List<Map<String, dynamic>>> getCatalogo(String token) async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📥 Status: ${response.statusCode}');
    print('📩 Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['body']);
    } else {
      throw Exception('Error al obtener catálogo: ${response.statusCode}');
    }
  }

  /// Crear o actualizar un artículo según su ID
  static Future<void> guardarArticulo(
    Map<String, dynamic> articulo,
    String token,
  ) async {
    // Solo enviamos los campos relevantes
    final data = {
      "id": articulo["id"] ?? 0,
      "nombre_articulo": articulo["nombre_articulo"],
      "stock_minimo": articulo["stock_minimo"],
      "descripcion": articulo["descripcion"],
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    print('📤 POST $_baseUrl');
    print('📦 Enviado: ${jsonEncode(data)}');
    print('📥 Status: ${response.statusCode}');
    print('📩 Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al crear o actualizar artículo');
    }
  }

  /// Eliminar artículo — el backend espera el ID en el cuerpo (no en la URL)
  static Future<void> eliminarArticulo(int id, String token) async {
    final response = await http.delete(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"id": id}),
    );

    print('🗑️ DELETE $_baseUrl');
    print('📦 ID: $id');
    print('📥 Status: ${response.statusCode}');
    print('📩 Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar artículo');
    }
  }
}
