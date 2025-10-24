import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frontend/config/config.dart';

class MapInitializationService {
  static Future<void> initialize() async {
    if (!kIsWeb) {
      // Para móvil, inicializar Mapbox
      await _initializeMapboxForMobile();
    }
    // Para web, no necesitamos inicialización especial
  }

  static Future<void> _initializeMapboxForMobile() async {
    try {
      // Mapbox se inicializa cuando se usa el widget en móvil
      print('✅ Mapbox disponible para móvil');
    } catch (e) {
      print('❌ Error con Mapbox en móvil: $e');
    }
  }

  static String getMapboxToken() {
    return AppConfig.tokenMap;
  }

  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
}