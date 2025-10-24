import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String serverIp = '10.192.84.125';
  static const int serverPort = 5000;
  static const String baseUrl = 'http://$serverIp:$serverPort';
  
  static const String apiUrl = '$baseUrl/api';
  static const String imagesUrl = '$baseUrl/uploads/images/articulos';
  
  // ✅ CORREGIDO: Usar MAP_TOKEN que es el nombre correcto en tu .env
  static String get tokenMap {
    try {
      final token = dotenv.env['MAP_TOKEN'] ?? 
                   'pk.eyJ1Ijoic3VjaGFuY2UiLCJhIjoiY21oNDIyOGx6MmhmejJycTFwODFoMmI0OSJ9.QMVUrS68LB76KJgqYyd4sA';
      
      if (token.isEmpty) {
        throw Exception('Mapbox token is empty');
      }
      
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error loading Mapbox token: $e');
      }
      // Token de respaldo
      return 'pk.eyJ1Ijoic3VjaGFuY2UiLCJhIjoiY21oNDIyOGx6MmhmejJycTFwODFoMmI0OSJ9.QMVUrS68LB76KJgqYyd4sA';
    }
  }
  
  static void printConfig() {
    if (kDebugMode) {
      print('⚙️ CONFIGURACIÓN ACTUAL:');
    }
    if (kDebugMode) {
      print('   • Servidor: $serverIp:$serverPort');
    }
    if (kDebugMode) {
      print('   • URL Base: $baseUrl');
    }
    if (kDebugMode) {
      print('   • API: $apiUrl');
    }
    if (kDebugMode) {
      print('   • Images: $imagesUrl');
    }
    if (kDebugMode) {
      print('   • Map Token: ${tokenMap.substring(0, 20)}...');
    }
  }
}