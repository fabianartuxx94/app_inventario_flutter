import 'dart:convert';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/config/config.dart';
import 'package:http/http.dart' as http;

class ActasService {
  
  // 📋 LISTAR ACTAS CON PAGINACIÓN Y FILTROS
  Future<Map<String, dynamic>> listarActas({
    required AuthProvider authProvider,
    int page = 1,
    int limit = 20,
    String? tipo,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    try {
      // Verificar autenticación
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      // Construir query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (tipo != null && tipo.isNotEmpty) {
        queryParams['tipo'] = tipo;
      }
      if (fechaDesde != null && fechaDesde.isNotEmpty) {
        queryParams['fecha_desde'] = fechaDesde;
      }
      if (fechaHasta != null && fechaHasta.isNotEmpty) {
        queryParams['fecha_hasta'] = fechaHasta;
      }

      // Construir URL
      String url = '${AppConfig.apiUrl}/actas?';
      queryParams.forEach((key, value) {
        url += '$key=$value&';
      });
      url = url.substring(0, url.length - 1); // Remover último &

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'actas': data['data']?['actas'] ?? data['body']?['actas'] ?? [],
          'pagination': data['data']?['pagination'] ?? data['body']?['pagination'] ?? {},
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar actas: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en listarActas: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 🔍 OBTENER ACTA COMPLETA CON DETALLES
  Future<Map<String, dynamic>> obtenerActaCompleta({
    required AuthProvider authProvider,
    required int actaId,
  }) async {
    try {
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/actas/$actaId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'acta': data['data']?['acta'] ?? data['body']?['acta'] ?? data,
          'detalles': data['data']?['detalles'] ?? data['body']?['detalles'] ?? [],
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'error': 'No tienes permiso para ver este acta',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Acta no encontrada',
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar acta: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerActaCompleta: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 📊 OBTENER ESTADÍSTICAS DE ACTAS
  Future<Map<String, dynamic>> obtenerEstadisticasActas({
    required AuthProvider authProvider,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    try {
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      // Construir URL
      String url = '${AppConfig.apiUrl}/actas/estadisticas/generales';
      if (fechaDesde != null || fechaHasta != null) {
        url += '?';
        if (fechaDesde != null) url += 'fecha_desde=$fechaDesde&';
        if (fechaHasta != null) url += 'fecha_hasta=$fechaHasta&';
        url = url.substring(0, url.length - 1);
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'estadisticas': data['data'] ?? data['body'] ?? data,
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar estadísticas: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerEstadisticasActas: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 🎛️ OBTENER FILTROS DISPONIBLES
  Future<Map<String, dynamic>> obtenerFiltrosDisponibles({
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
        Uri.parse('${AppConfig.apiUrl}/actas/filtros/disponibles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'filtros': data['data'] ?? data['body'] ?? data,
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar filtros: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerFiltrosDisponibles: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 📄 GENERAR PDF DEL ACTA
  Future<Map<String, dynamic>> generarPdfActa({
    required AuthProvider authProvider,
    required int actaId,
  }) async {
    try {
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/actas/$actaId/generar-pdf'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'pdf_info': data['data'] ?? data['body'] ?? data,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'error': 'No tienes permiso para generar PDF de este acta',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Acta no encontrada',
        };
      } else {
        return {
          'success': false,
          'error': 'Error al generar PDF: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en generarPdfActa: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }
}