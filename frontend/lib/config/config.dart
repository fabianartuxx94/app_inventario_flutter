// lib/config/config.dart
class AppConfig {
  static const String serverIp = '10.192.84.125';
  static const int serverPort = 5000;
  static const String baseUrl = 'http://$serverIp:$serverPort';
  
  // Cambiar getters por constantes
  static const String apiUrl = '$baseUrl/api';
  static const String uploadsUrl = '$baseUrl/uploads';
  
  // Método para mostrar configuración actual
  static void printConfig() {
    print('⚙️ CONFIGURACIÓN ACTUAL:');
    print('   • Servidor: $serverIp:$serverPort');
    print('   • URL Base: $baseUrl');
    print('   • API: $apiUrl');
    print('   • Uploads: $uploadsUrl');
  }
}