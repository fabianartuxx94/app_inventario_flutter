import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class MarcasService {
  static Future<List<dynamic>> obtenerMarcas(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiUrl}/marcas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Error al obtener marcas: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> guardarMarca(
      Map<String, dynamic> marcaData, String token) async {
    final isEdit = marcaData['id'] != null && marcaData['id'] != 0;
    
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/marcas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(marcaData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'data': data['data'] ?? marcaData,
        'message': isEdit ? 'Marca actualizada exitosamente' : 'Marca creada exitosamente'
      };
    } else {
      throw Exception('Error al guardar marca: ${response.statusCode}');
    }
  }

  static Future<void> eliminarMarca(int id, String token) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiUrl}/marcas/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar marca: ${response.statusCode}');
    }
  }
}