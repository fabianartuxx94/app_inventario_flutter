import 'dart:convert';
import 'package:frontend/config/config.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class AsignacionesService {

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

    // ✅ DEBUG: Ver estructura completa de la respuesta
    print('🔍 DEBUG - Respuesta cruda del backend:');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // ✅ DEBUG: Ver estructura de datos
      print('🔍 DEBUG - Estructura de data:');
      print('Keys: ${data.keys}');
      print('Tiene body: ${data.containsKey('body')}');
      print('Tiene data: ${data.containsKey('data')}');
      print('Tiene items: ${data.containsKey('items')}');
      
      if (data.containsKey('body')) {
        final body = data['body'];
        print('🔍 DEBUG - Tipo de body: ${body.runtimeType}');
        if (body is Map) {
          print('🔍 DEBUG - Keys de body: ${body.keys}');
        }
      }

      // ✅ CORREGIDO: Adaptar estructura según lo que realmente devuelve el backend
      Map<String, dynamic> resultado = {
        'success': true,
      };

      // Caso 1: Si viene con estructura {body: {items: [], pagination: {}}}
      if (data.containsKey('body') && data['body'] is Map) {
        final body = data['body'] as Map<String, dynamic>;
        resultado['items'] = body['items'] ?? [];
        resultado['pagination'] = body['pagination'] ?? {};
      }
      // Caso 2: Si viene con estructura {data: {items: [], pagination: {}}}
      else if (data.containsKey('data') && data['data'] is Map) {
        final body = data['data'] as Map<String, dynamic>;
        resultado['items'] = body['items'] ?? [];
        resultado['pagination'] = body['pagination'] ?? {};
      }
      // Caso 3: Si viene con estructura directa {items: [], pagination: {}}
      else if (data.containsKey('items')) {
        resultado['items'] = data['items'] ?? [];
        resultado['pagination'] = data['pagination'] ?? {};
      }
      // Caso 4: Si viene el array directamente en 'body'
      else if (data.containsKey('body') && data['body'] is List) {
        resultado['items'] = data['body'];
        resultado['pagination'] = {
          'page': page,
          'limit': limit,
          'total': data['body'].length,
          'totalPages': 1
        };
      }
      // Caso 5: Fallback
      else {
        resultado['items'] = [];
        resultado['pagination'] = {};
      }

      print('✅ DEBUG - Resultado final:');
      print('  - Items: ${resultado['items']?.length ?? 0}');
      print('  - Pagination: ${resultado['pagination']}');

      return resultado;

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

    // ✅ DEBUG: Ver estructura de respuesta
    print('🔍 DEBUG Inventario - Respuesta cruda:');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // ✅ DEBUG: Ver estructura
      print('🔍 DEBUG Inventario - Estructura:');
      print('Keys: ${data.keys}');
      print('Tiene body: ${data.containsKey('body')}');
      print('Tiene data: ${data.containsKey('data')}');
      print('Tiene items: ${data.containsKey('items')}');

      // ✅ CORREGIDO: Adaptar estructura
      List<dynamic> items = [];

      // Caso 1: Si viene con estructura {body: {items: []}}
      if (data.containsKey('body') && data['body'] is Map) {
        final body = data['body'] as Map<String, dynamic>;
        items = body['items'] ?? [];
      }
      // Caso 2: Si viene con estructura {data: {items: []}}
      else if (data.containsKey('data') && data['data'] is Map) {
        final body = data['data'] as Map<String, dynamic>;
        items = body['items'] ?? [];
      }
      // Caso 3: Si viene con estructura directa {items: []}
      else if (data.containsKey('items')) {
        items = data['items'] ?? [];
      }
      // Caso 4: Si viene el array directamente en 'body'
      else if (data.containsKey('body') && data['body'] is List) {
        items = data['body'];
      }
      // Caso 5: Si viene el array directamente en 'data'
      else if (data.containsKey('data') && data['data'] is List) {
        items = data['data'];
      }

      print('✅ DEBUG Inventario - Items encontrados: ${items.length}');

      return {
        'success': true,
        'items': items,
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

    // ✅ CORREGIDO: Usar el nuevo endpoint de personal
    final response = await http.get(
      Uri.parse('${AppConfig.apiUrl}/personal/tecnicos/activos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.token}',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // ✅ La estructura ahora viene de personal/tecnicos/activos
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