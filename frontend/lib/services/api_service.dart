import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const _baseUrl = 'http://192.168.0.102:5000/api/auth/login';

  static Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final token = body['body']['token'];
        return token; // ✅ devolvemos el token
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error en login: $e');
      }
      return null;
    }
  }
}
