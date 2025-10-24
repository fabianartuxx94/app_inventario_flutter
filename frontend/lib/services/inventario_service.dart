import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/config.dart';
import '../providers/auth_provider.dart';
import '../models/inventario_model.dart'; // ✅ IMPORTACIÓN CORRECTA

class InventarioService {
  static String get baseUrl => AppConfig.apiUrl;

  // 🧭 Obtener token del proveedor
  static Future<String?> _obtenerToken(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isTokenValid) {
        final tokenCargado = await authProvider.loadStoredToken();
        if (!tokenCargado) return null;
      }
      return authProvider.token;
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      return null;
    }
  }

// 📋 Obtener inventario paginado - MEJORADO
static Future<InventarioResponse> getInventarioPaginated({
  required BuildContext context,
  int page = 1,
  int limit = 50,
  String search = '',
  String estado = '',
  String bodega = '',
  String tipoBodega = '',
  String marca = '',
  String tipoArticulo = '',
}) async {
  try {
    final token = await _obtenerToken(context);
    if (token == null) throw Exception('No hay token válido');

    // Construir parámetros de consulta
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    // Agregar filtros solo si tienen valor
    if (search.isNotEmpty) params['search'] = search;
    if (estado.isNotEmpty) params['estado'] = estado;
    if (bodega.isNotEmpty) params['bodega'] = bodega;
    if (tipoBodega.isNotEmpty) params['tipo_bodega'] = tipoBodega;
    if (marca.isNotEmpty) params['marca'] = marca;
    if (tipoArticulo.isNotEmpty) params['tipo_articulo'] = tipoArticulo;

    final uri = Uri.parse('$baseUrl/inventario').replace(queryParameters: params);
    
    print('🌐 Solicitando inventario: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));

    print('📡 Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Datos recibidos correctamente');
      
      // ✅ Estructura esperada: {body: {items: [...], pagination: {...}}}
      if (data['body'] != null) {
        final body = data['body'] as Map<String, dynamic>;
        final items = body['items'] as List;
        final paginationData = body['pagination'] as Map<String, dynamic>;

        final pagination = Pagination(
          page: (paginationData['page'] as num?)?.toInt() ?? 1,
          limit: (paginationData['limit'] as num?)?.toInt() ?? 50,
          total: (paginationData['total'] as num?)?.toInt() ?? 0,
          totalPages: (paginationData['totalPages'] as num?)?.toInt() ?? 1,
        );

        final inventarioItems = items.map((item) => Inventario.fromJson(item)).toList();

        return InventarioResponse(
          items: inventarioItems,
          pagination: pagination,
        );
      } else {
        throw Exception('Estructura de respuesta inválida');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token inválido o expirado');
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error en getInventarioPaginated: $e');
    rethrow;
  }
}
static Future<FiltrosDisponibles> getFiltrosDisponibles(BuildContext context) async {
  try {
    final token = await _obtenerToken(context);
    if (token == null) throw Exception('No hay token');

    final url = '$baseUrl/inventario/filtros/disponibles';
    print('🔄 Solicitando filtros desde: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 GET /inventario/filtros/disponibles - Status: ${response.statusCode}');
    print('📦 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Filtros recibidos: $data');
      
      // ✅ CORRECCIÓN: Acceder a los datos dentro de 'body'
      if (data['body'] != null) {
        return FiltrosDisponibles.fromJson(data['body']);
      } else {
        // Si no viene en 'body', usar la estructura directa
        return FiltrosDisponibles.fromJson(data);
      }
    } else {
      print('⚠️ Error en respuesta, usando valores por defecto');
      return FiltrosDisponibles(
        estados: ['Nuevo', 'Bueno', 'Reparación'],
        bodegas: ['Bodega Principal', 'Bodega Garzón', 'Bodega Pitalito'],
        tiposBodega: ['BMD', 'Sistemas'],
        tiposArticulo: ['Activo Fijo', 'Activo de Control', 'Consumible'],
        marcas: [],
        categorias: [],
      );
    }
  } catch (e) {
    print('❌ Error getFiltrosDisponibles: $e');
    return FiltrosDisponibles(
      estados: ['Nuevo', 'Bueno', 'Reparación'],
      bodegas: ['Bodega Principal', 'Bodega Garzón', 'Bodega Pitalito'],
      tiposBodega: ['BMD', 'Sistemas'],
      tiposArticulo: ['Activo Fijo', 'Activo de Control', 'Consumible'],
      marcas: [],
      categorias: [],
    );
  }
}


  // 🔍 Obtener un registro específico
  static Future<Inventario> getRegistroInventario(String id, BuildContext context) async {
    try {
      final token = await _obtenerToken(context);
      if (token == null) throw Exception('No hay token');

      final response = await http.get(
        Uri.parse('$baseUrl/inventario/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 GET /inventario/$id - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Inventario.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para ver este registro');
      } else if (response.statusCode == 404) {
        throw Exception('Registro no encontrado');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getRegistroInventario: $e');
      rethrow;
    }
  }

  /* 🎛️ Obtener filtros disponibles
static Future<FiltrosDisponibles> getFiltrosDisponibles(BuildContext context) async {
  try {
    final token = await _obtenerToken(context);
    if (token == null) throw Exception('No hay token');

    final response = await http.get(
      Uri.parse('$baseUrl/inventario/filtros/disponibles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 GET /inventario/filtros/disponibles - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return FiltrosDisponibles.fromJson(data);
    } else if (response.statusCode == 404) {
      // ⚠️ Si la ruta no existe, retornar filtros vacíos
      print('⚠️ Ruta de filtros no disponible, usando valores por defecto');
      return FiltrosDisponibles(
        estados: ['Nuevo', 'Bueno', 'Reparación'],
        bodegas: ['Bodega Principal', 'Bodega Garzón', 'Bodega Pitalito'],
        tiposBodega: ['BMD', 'Sistemas'],
        tiposArticulo: [],
        marcas: [],
        categorias: [],
      );
    } else if (response.statusCode == 401) {
      throw Exception('Token inválido o expirado');
    } else {
      throw Exception('Error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error getFiltrosDisponibles: $e');
    // Retornar valores por defecto en caso de error
    return FiltrosDisponibles(
      estados: ['Nuevo', 'Bueno', 'Reparación'],
      bodegas: ['Bodega Principal', 'Bodega Garzón', 'Bodega Pitalito'],
      tiposBodega: ['BMD', 'Sistemas'],
      tiposArticulo: [],
      marcas: [],
      categorias: [],
    );
  }*/
}
