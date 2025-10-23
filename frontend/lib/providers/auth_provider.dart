import 'package:flutter/material.dart';
import 'package:frontend/screens/login_page.dart';
import 'package:frontend/utils/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class User {
  final int id;
  final String username;
  final String nombreCompleto;
  final String rol;
  final dynamic bodega; // Puede ser String o List según el backend

  User({
    required this.id,
    required this.username,
    required this.nombreCompleto,
    required this.rol,
    this.bodega,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? json['nombre_completo'] ?? 'Usuario',
      rol: json['rol'] ?? 'usuario',
      bodega: json['bodega'], // Puede venir null o lista
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nombreCompleto': nombreCompleto,
      'rol': rol,
      'bodega': bodega,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, rol: $rol, bodega: $bodega}';
  }

  String get displayName {
    if (nombreCompleto.isNotEmpty && nombreCompleto != 'Usuario') {
      return nombreCompleto;
    }
    return username.isNotEmpty ? username : 'Usuario';
  }
}

class AuthProvider with ChangeNotifier {
  String? _token;
  DateTime? _tokenExpiry;
  Timer? _inactivityTimer;
  User? _user;
  final Duration _inactivityTimeout = const Duration(minutes: 40);

  String? get token => _token;
  User? get user => _user;
  String get userRol => _user?.rol ?? 'usuario';
  dynamic get userBodega => _user?.bodega;
  bool get isAdmin => userRol == 'administrador';
  bool get isBodega => userRol == 'bodega';
  bool get isUsuario => userRol == 'usuario';
  bool get isTecnico => userRol == 'tecnico';
  bool get isAuthenticated => _token != null && _user != null;

  bool get isPrincipalBodega =>
      (userBodega is List && (userBodega as List).contains('principal')) ||
      (userBodega == 'principal');

  void printDebugInfo() {
    print('🔐 AuthProvider Debug:');
    print('   Token: ${_token != null ? "✅ Presente" : "❌ Ausente"}');
    print('   User: $_user');
    print('   Rol: $userRol');
    print('   Bodega: $userBodega');
  }

  void resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;

    if (_token != null && isTokenValid) {
      _inactivityTimer = Timer(_inactivityTimeout, _onInactivityTimeout);
    }
  }

  void _onInactivityTimeout() {
    logout();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión cerrada por inactividad'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    });
  }

  Future<void> login(String token, Map<String, dynamic> userData) async {
    print('🚀 Login called with userData: $userData');

    _token = token;

    try {
      _user = User.fromJson(userData);
      print('✅ User created from login data: $_user');

      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));
        final exp = payload['exp'] as int;
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        print('✅ Token expiry: $_tokenExpiry');
      }
    } catch (e) {
      print('❌ Error during login: $e');
      _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('tokenExpiry', _tokenExpiry!.toIso8601String());
    await prefs.setString('userData', json.encode(_user!.toJson()));

    print('💾 Saved to SharedPreferences: ${_user!.toJson()}');

    resetInactivityTimer();
    notifyListeners();

    printDebugInfo();
  }

  Future<void> logout() async {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _token = null;
    _tokenExpiry = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('tokenExpiry');
    await prefs.remove('userData');

    notifyListeners();
  }

  Future<void> logoutWithNavigation(BuildContext context) async {
    await logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  bool get isTokenValid {
    if (_token == null || _tokenExpiry == null) return false;
    return _tokenExpiry!.isAfter(DateTime.now());
  }

  Future<bool> loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('token');
      final storedExpiry = prefs.getString('tokenExpiry');
      final storedUserData = prefs.getString('userData');

      if (storedToken != null && storedExpiry != null && storedUserData != null) {
        final expiryDate = DateTime.parse(storedExpiry);

        if (expiryDate.isAfter(DateTime.now())) {
          _token = storedToken;
          _tokenExpiry = expiryDate;

          final userMap = json.decode(storedUserData);
          _user = User.fromJson(userMap);

          resetInactivityTimer();
          notifyListeners();
          printDebugInfo();
          return true;
        } else {
          await logout();
          return false;
        }
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      print('❌ Error loading stored token: $e');
      await logout();
      return false;
    }
  }

  Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
