import 'dart:convert';
import 'package:frontend/models/gestion_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/config/config.dart';
import 'package:http/http.dart' as http;

class GestionService {
  
// 🎯 ASIGNACIÓN MASIVA (ACTUALIZADO)
Future<Map<String, dynamic>> asignacionMasiva({
  required AuthProvider authProvider,
  required SolicitudAsignacionMasiva solicitud,
}) async {
  try {
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      return {
        'success': false,
        'error': 'Usuario no autenticado',
      };
    }

    final Map<String, dynamic> body = {
      'tecnico_id': solicitud.tecnicoId,
      'sitio_venta_id': solicitud.sitioVentaId,
      'inventario_ids': solicitud.inventarioIds,
      if (solicitud.descripcion != null && solicitud.descripcion!.isNotEmpty) 
        'descripcion': solicitud.descripcion,
      if (solicitud.observaciones != null && solicitud.observaciones!.isNotEmpty) 
        'observaciones': solicitud.observaciones,
    };

    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/gestion/asignaciones-masivas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.token}',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      final respuesta = RespuestaAsignacionMasiva.fromJson(data['data'] ?? data);

      return {
        'success': true,
        'respuesta': respuesta,
      };
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      return {
        'success': false,
        'error': errorData['error'] ?? 'Error al realizar asignación masiva: ${response.statusCode}',
      };
    }
  } catch (error) {
    print('❌ ERROR en asignacionMasiva: $error');
    return {
      'success': false,
      'error': 'Error de conexión',
    };
  }
}

  // 🔄 SOLICITAR TRANSFERENCIA ENTRE BODEGAS
  Future<Map<String, dynamic>> solicitarTransferencia({
    required AuthProvider authProvider,
    required List<int> inventarioIds,
    required String bodegaOrigen,
    required String bodegaDestino,
    String? motivo,
  }) async {
    try {
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final Map<String, dynamic> body = {
        'inventario_ids': inventarioIds,
        'bodega_origen': bodegaOrigen,
        'bodega_destino': bodegaDestino,
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/gestion/transferencias'),
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
          'message': data['data']?['message'] ?? data['message'] ?? 'Transferencia completada',
          'acta_id': data['data']?['acta_id'] ?? data['acta_id'],
          'items_transferidos': data['data']?['items_transferidos'] ?? data['items_transferidos'] ?? inventarioIds.length,
          'notificacion_enviada': data['data']?['notificacion_enviada'] ?? data['notificacion_enviada'] ?? false,
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error al realizar transferencia: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en solicitarTransferencia: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 🔄 PROCESAR DEVOLUCIÓN CON VALIDACIÓN DE ESTADO
  Future<Map<String, dynamic>> procesarDevolucion({
    required AuthProvider authProvider,
    required int asignacionId,
    required String estadoEquipo, // 'bueno', 'danado', 'reparacion'
    String? motivoDevolucion,
  }) async {
    try {
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      // Validar estado del equipo
      if (!['bueno', 'danado', 'reparacion'].contains(estadoEquipo)) {
        return {
          'success': false,
          'error': 'Estado de equipo no válido. Debe ser: bueno, danado o reparacion',
        };
      }

      final Map<String, dynamic> body = {
        'asignacion_id': asignacionId,
        'estado_equipo': estadoEquipo,
        if (motivoDevolucion != null && motivoDevolucion.isNotEmpty) 'motivo_devolucion': motivoDevolucion,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/gestion/devoluciones'),
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
          'message': data['data']?['message'] ?? data['message'] ?? 'Devolución procesada',
          'acta_id': data['data']?['acta_id'] ?? data['acta_id'],
          'estado_equipo': data['data']?['estado_equipo'] ?? data['estado_equipo'] ?? estadoEquipo,
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error al procesar devolución: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en procesarDevolucion: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 📊 OBTENER STOCK AGREGADO (ACTUALIZADO)
  Future<Map<String, dynamic>> obtenerStockAgregado({
    required AuthProvider authProvider,
    String? tipoArticulo,
    String? categoria,
  }) async {
    try {
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      // Construir URL con query parameters
      String url = '${AppConfig.apiUrl}/gestion/stock-agregado';
      
      if (tipoArticulo != null || categoria != null) {
        url += '?';
        if (tipoArticulo != null) url += 'tipo_articulo=$tipoArticulo&';
        if (categoria != null) url += 'categoria=$categoria&';
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
        final stockData = data['data'] ?? data['body'] ?? [];
        
        final stock = (stockData as List)
            .map((item) => StockAgregado.fromJson(item))
            .toList();

        return {
          'success': true,
          'stock': stock,
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar stock agregado: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerStockAgregado: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 🔔 OBTENER NOTIFICACIONES
  Future<Map<String, dynamic>> obtenerNotificaciones({
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
        Uri.parse('${AppConfig.apiUrl}/gestion/notificaciones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'notificaciones': data['data'] ?? data['body'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Error al cargar notificaciones: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerNotificaciones: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // ✅ MARCAR NOTIFICACIÓN COMO LEÍDA
  Future<Map<String, dynamic>> marcarNotificacionLeida({
    required AuthProvider authProvider,
    required int notificacionId,
  }) async {
    try {
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
        };
      }

      final response = await http.patch(
        Uri.parse('${AppConfig.apiUrl}/gestion/notificaciones/$notificacionId/leer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'message': data['data']?['message'] ?? data['message'] ?? 'Notificación marcada como leída',
        };
      } else {
        return {
          'success': false,
          'error': 'Error al marcar notificación como leída: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en marcarNotificacionLeida: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }

  // 📈 OBTENER ESTADÍSTICAS DE NOTIFICACIONES
  Future<Map<String, dynamic>> obtenerEstadisticasNotificaciones({
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
        Uri.parse('${AppConfig.apiUrl}/gestion/notificaciones/estadisticas'),
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
          'error': 'Error al cargar estadísticas de notificaciones: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('❌ ERROR en obtenerEstadisticasNotificaciones: $error');
      return {
        'success': false,
        'error': 'Error de conexión',
      };
    }
  }
}