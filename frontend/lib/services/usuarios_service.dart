import 'dart:convert';
import 'package:frontend/config/config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UsuariosService {
  static String get baseUrl => AppConfig.apiUrl;

  // ✅ Obtener token del AuthProvider
  static Future<String?> _obtenerToken(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (!authProvider.isTokenValid) {
        print('❌ Token no válido o expirado');
        final tokenCargado = await authProvider.loadStoredToken();
        if (!tokenCargado) {
          print('❌ No se pudo cargar token válido');
          return null;
        }
      }
      
      final token = authProvider.token;
      print('✅ Token obtenido: ${token != null ? "PRESENTE" : "AUSENTE"}');
      return token;
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      return null;
    }
  }

  // ✅ CORREGIDO: Obtener todos los usuarios - AHORA SÍ FUNCIONARÁ
  static Future<List<dynamic>?> getUsuarios(BuildContext context) async {
    try {
      final token = await _obtenerToken(context);
      
      if (token == null) {
        throw Exception('No hay token de autenticación disponible');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 GET Usuarios - Status: ${response.statusCode}');
      print('📡 GET Usuarios - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // ✅ MANEJO DE DIFERENTES FORMATOS DE RESPUESTA
        if (data is List) {
          // Caso 1: La API retorna directamente una lista
          print('✅ Usuarios cargados (formato List): ${data.length}');
          return data;
        } else if (data is Map && data.containsKey('body') && data['body'] is List) {
          // ✅ CASO ESPECÍFICO DE TU API: {"error":false,"status":200,"body":[...]}
          final usuariosList = data['body'];
          print('✅ Usuarios cargados (formato body): ${usuariosList.length}');
          return usuariosList;
        } else if (data is Map && data.containsKey('data') && data['data'] is List) {
          // Caso 2: La API retorna {data: [], ...}
          final usuariosList = data['data'];
          print('✅ Usuarios cargados (formato Map con data): ${usuariosList.length}');
          return usuariosList;
        } else if (data is Map && data.containsKey('items') && data['items'] is List) {
          // Caso 3: La API retorna {items: [], ...}
          final usuariosList = data['items'];
          print('✅ Usuarios cargados (formato Map con items): ${usuariosList.length}');
          return usuariosList;
        } else if (data is Map && data.containsKey('usuarios') && data['usuarios'] is List) {
          // Caso 4: La API retorna {usuarios: [], ...}
          final usuariosList = data['usuarios'];
          print('✅ Usuarios cargados (formato Map con usuarios): ${usuariosList.length}');
          return usuariosList;
        }
        
        // ✅ Si no coincide con ningún formato conocido, mostrar error
        print('❌ Formato de respuesta no reconocido: $data');
        print('❌ Claves disponibles: ${data is Map ? data.keys.toList() : "No es un Map"}');
        throw Exception('Formato de respuesta no reconocido');
        
      } else if (response.statusCode == 401) {
        _manejarError401(context);
        throw Exception('Token de autenticación inválido');
      } else {
        throw Exception('Error al cargar usuarios: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ ERROR getUsuarios: $e');
      rethrow;
    }
  }

  // Crear usuario
  static Future<dynamic> crearUsuario(Map<String, dynamic> data, BuildContext context) async {
    try {
      final token = await _obtenerToken(context);
      
      if (token == null) {
        throw Exception('No hay token de autenticación disponible');
      }

      print('🔄 CREANDO USUARIO:');
      print('📦 DATOS: $data');

      final response = await http.post(
        Uri.parse('$baseUrl/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print('📡 POST Usuario - Status: ${response.statusCode}');
      print('📡 POST Usuario - Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // ✅ Manejar diferentes formatos de respuesta
        if (responseData is Map && responseData.containsKey('body')) {
          return responseData['body'] ?? responseData;
        }
        return responseData is Map ? responseData : {'message': 'Usuario creado'};
      } else if (response.statusCode == 401) {
        _manejarError401(context);
        throw Exception('Token de autenticación inválido');
      } else {
        throw Exception('Error al crear usuario: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ ERROR crearUsuario: $e');
      rethrow;
    }
  }

  // Actualizar usuario
// ✅ CORREGIDO: Actualizar usuario - usar POST en lugar de PUT
static Future<dynamic> actualizarUsuario(String id, Map<String, dynamic> data, BuildContext context) async {
  try {
    final token = await _obtenerToken(context);
    
    if (token == null) {
      throw Exception('No hay token de autenticación disponible');
    }

    // ✅ AGREGAR EL ID AL BODY (como espera tu backend para actualizar)
    final dataConId = {
      ...data,
      'id': id, // Tu backend espera el ID en el body para saber qué usuario actualizar
    };
    
    print('🔄 ACTUALIZANDO USUARIO ID: $id');
    print('📦 DATOS: $dataConId');

    // ✅ CAMBIAR A POST para actualizar
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios'), // ✅ Mismo endpoint que crear
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(dataConId),
    );

    print('📡 POST (Actualizar) Usuario - Status: ${response.statusCode}');
    print('📡 POST (Actualizar) Usuario - Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      if (responseData is Map && responseData.containsKey('body')) {
        return responseData['body'] ?? responseData;
      }
      return responseData is Map ? responseData : {'message': 'Usuario actualizado'};
    } else if (response.statusCode == 401) {
      _manejarError401(context);
      throw Exception('Token de autenticación inválido');
    } else {
      throw Exception('Error al actualizar usuario: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ ERROR actualizarUsuario: $e');
    rethrow;
  }
}

  // Eliminar usuario
  static Future<bool> eliminarUsuario(String id, BuildContext context) async {
    try {
      final token = await _obtenerToken(context);
      
      if (token == null) {
        throw Exception('No hay token de autenticación disponible');
      }

      print('🗑️ ELIMINANDO USUARIO ID: $id');

      final response = await http.put(
        Uri.parse('$baseUrl/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id': id,
        }),
      );

      print('📡 DELETE Usuario - Status: ${response.statusCode}');
      print('📡 DELETE Usuario - Body: ${response.body}');

      if (response.statusCode == 401) {
        _manejarError401(context);
        throw Exception('Token de autenticación inválido');
      }

      return response.statusCode == 200;
    } catch (e) {
      print('❌ ERROR eliminarUsuario: $e');
      rethrow;
    }
  }

  // ✅ Manejar error 401
  static void _manejarError401(BuildContext context) {
    print('🔐 ERROR 401 - Token inválido, haciendo logout...');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión expirada. Por favor inicie sesión nuevamente.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    });
  }
}