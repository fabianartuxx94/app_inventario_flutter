import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UploadService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/uploads/image'), // ← Ruta actualizada
      );

      // Agregar archivo
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'imageUrl': data['imageUrl'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al subir imagen',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // URL completa para mostrar imágenes
  static String getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) return imagePath;
    return 'http://localhost:5000$imagePath';
  }

  static Future takePhoto() async {}

  static Future pickImage() async {}
}
