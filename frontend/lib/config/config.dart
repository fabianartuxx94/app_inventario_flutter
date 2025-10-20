import 'package:flutter/foundation.dart';

class AppConfig {
  static const String serverIp = '10.192.84.125';
  static const int serverPort = 5000;
  static const String baseUrl = 'http://$serverIp:$serverPort';
  
  static const String apiUrl = '$baseUrl/api';
  static const String imagesUrl = '$baseUrl/uploads/images/articulos';
  
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
  }
}