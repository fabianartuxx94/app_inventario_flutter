import 'dart:convert';
import 'package:frontend/config/config.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class AsignacionesService {

  // 📋 Listar asignaciones con paginación y filtros
  Future<Map<String, dynamic>> listarAsignaciones({
    required AuthProvider authProvider,
    int page = 1,
    int limit = 50,
    String? tecnicoId,
    String? estado,
  }) async {
    try {
      // Verificar autenticación
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      // Construir URL con query parameters
      String url = '${AppConfig.apiUrl}/asignaciones?page=$page&limit=$limit';
      
      if (tecnicoId != null && tecnicoId.isNotEmpty) {
        url += '&tecnico_id=$tecnicoId';
      }
      
      if (estado != null && estado.isNotEmpty) {
        url += '&estado=$estado';
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
          'data': data['data'] ?? data, // Adaptar según la estructura de tu API
          'pagination': data['data']?['pagination'] ?? data['pagination'],
          'items': data['data']?['items'] ?? data['body'],
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar asignaciones: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en listarAsignaciones: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // ➕ Crear nueva asignación
  Future<Map<String, dynamic>> crearAsignacion({
    required AuthProvider authProvider,
    required int inventarioId,
    required int tecnicoId,
    required int sitioVentaId,
    String? observaciones,
  }) async {
    try {
      // Verificar autenticación
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final Map<String, dynamic> body = {
        'inventario_id': inventarioId,
        'tecnico_id': tecnicoId,
        'sitio_venta_id': sitioVentaId,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/asignaciones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'message': data['data']?['message'] ?? data['message'],
          'id': data['data']?['id'] ?? data['id'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error al crear asignación: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en crearAsignacion: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 🔄 Actualizar estado de asignación
  Future<Map<String, dynamic>> actualizarEstado({
    required AuthProvider authProvider,
    required int asignacionId,
    required String nuevoEstado,
  }) async {
    try {
      // Verificar autenticación
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final Map<String, dynamic> body = {
        'estado': nuevoEstado,
      };

      final response = await http.patch(
        Uri.parse('${AppConfig.apiUrl}/asignaciones/$asignacionId/estado'),
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
          'message': data['data']?['message'] ?? data['message'],
          'nuevo_estado': data['data']?['nuevo_estado'] ?? nuevoEstado,
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error al actualizar estado: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en actualizarEstado: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 📊 Obtener inventario disponible para asignación
  Future<Map<String, dynamic>> obtenerInventarioDisponible({
    required AuthProvider authProvider,
    String? tipoArticulo,
    String? categoria,
  }) async {
    try {
      // Verificar autenticación
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      // Construir URL con query parameters
      String url = '${AppConfig.apiUrl}/asignaciones/inventario/disponible';
      
      if (tipoArticulo != null && tipoArticulo.isNotEmpty) {
        url += '?tipo_articulo=$tipoArticulo';
      }
      
      if (categoria != null && categoria.isNotEmpty) {
        url += '${url.contains('?') ? '&' : '?'}categoria=$categoria';
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
          'items': data['data']?['items'] ?? data['body'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar inventario disponible: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerInventarioDisponible: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 👨‍💼 Obtener técnicos disponibles (servicio auxiliar)
  Future<Map<String, dynamic>> obtenerTecnicos({
    required AuthProvider authProvider,
  }) async {
    try {
      // Verificar autenticación
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/tecnicos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'tecnicos': data['data'] ?? data['body'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar técnicos: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerTecnicos: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 🏪 Obtener sitios de venta (servicio auxiliar)
  Future<Map<String, dynamic>> obtenerSitiosVenta({
    required AuthProvider authProvider,
  }) async {
    try {
      // Verificar autenticación
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/sitios-venta'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'sitios_venta': data['data'] ?? data['body'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar sitios de venta: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerSitiosVenta: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }
}