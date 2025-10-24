import 'dart:convert';
import 'package:frontend/config/config.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class MapService {
  
  // 🗺️ OBTENER SITIOS DE VENTA PARA EL MAPA
  static Future<Map<String, dynamic>> obtenerSitiosVentaMapa({
    required AuthProvider authProvider,
    bool soloConCoordenadas = true,
  }) async {
    try {
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final endpoint = soloConCoordenadas 
          ? 'maps/sitios-con-coordenadas'
          : 'maps/sitios-venta';

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'sitios': data['data'] ?? [],
          'total': data['total'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar sitios de venta: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerSitiosVentaMapa: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 📍 ACTUALIZAR UBICACIÓN DESDE MÓVIL
  static Future<Map<String, dynamic>> actualizarUbicacionSitio({
    required AuthProvider authProvider,
    required int sitioId,
    required double latitud,
    required double longitud,
    String precision = 'exacta',
  }) async {
    try {
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final body = {
        'latitud': latitud,
        'longitud': longitud,
        'precision': precision,
      };

      final response = await http.put(
        Uri.parse('${AppConfig.apiUrl}/maps/sitios-venta/$sitioId/ubicacion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Ubicación actualizada exitosamente',
          'data': data['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error al actualizar ubicación: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en actualizarUbicacionSitio: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 📊 OBTENER ESTADÍSTICAS DE SITIOS
  static Future<Map<String, dynamic>> obtenerEstadisticasSitios({
    required AuthProvider authProvider,
  }) async {
    try {
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/maps/estadisticas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'estadisticas': data['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar estadísticas: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerEstadisticasSitios: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }
}