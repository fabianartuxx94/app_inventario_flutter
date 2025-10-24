import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class MarcasService {
  static Future<List<dynamic>> obtenerMarcas(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/marcas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 GET /marcas - Status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // ✅ CORRECCIÓN: Usar 'body' en lugar de 'data'
        if (data['body'] != null && data['body'] is List) {
          return data['body'];
        } 
        // ✅ Si viene directamente como array
        else if (data is List) {
          return data;
        }
        // ❌ Si no viene en el formato esperado
        else {
          print('⚠️ Estructura inesperada en marcas: $data');
          return [];
        }
      } else {
        print('❌ Error obteniendo marcas: ${response.statusCode}');
        throw Exception('Error al obtener marcas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en obtenerMarcas: $e');
      throw Exception('Error al obtener marcas: $e');
    }
  }

  static Future<Map<String, dynamic>> guardarMarca(
      Map<String, dynamic> marcaData, String token) async {
    try {
      final isEdit = marcaData['id'] != null && marcaData['id'] != 0;
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/marcas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(marcaData),
      );

      print('📡 POST /marcas - Status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // ✅ CORRECCIÓN: Usar 'body' en lugar de 'data'
        return {
          'success': true,
          'data': data['body'] ?? marcaData,
          'message': data['message'] ?? (isEdit ? 'Marca actualizada exitosamente' : 'Marca creada exitosamente')
        };
      } else {
        throw Exception('Error al guardar marca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en guardarMarca: $e');
      throw Exception('Error al guardar marca: $e');
    }
  }

  static Future<void> eliminarMarca(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.apiUrl}/marcas/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar marca: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en eliminarMarca: $e');
      throw Exception('Error al eliminar marca: $e');
    }
  }
}