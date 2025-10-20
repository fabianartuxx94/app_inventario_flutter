import 'package:flutter/material.dart';
import 'package:frontend/utils/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  String? _token;
  DateTime? _tokenExpiry;
  Timer? _inactivityTimer;
  final Duration _inactivityTimeout = const Duration(minutes: 30);

  String? get token => _token;

  void resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_token != null && isTokenValid) {
      _inactivityTimer = Timer(_inactivityTimeout, _onInactivityTimeout);
    }
  }

  void _onInactivityTimeout() {
    logout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
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

  Future<void> login(String token) async {
    _token = token;
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));
        final exp = payload['exp'] as int;
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (_) {
      _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('tokenExpiry', _tokenExpiry!.toIso8601String());

    resetInactivityTimer();
    notifyListeners();
  }

  Future<void> logout() async {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _token = null;
    _tokenExpiry = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('tokenExpiry');

    notifyListeners();
  }

  bool get isTokenValid {
    if (_token == null || _tokenExpiry == null) return false;
    return _tokenExpiry!.isAfter(DateTime.now());
  }

  Future<void> loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('token');
      final storedExpiry = prefs.getString('tokenExpiry');

      if (storedToken != null && storedExpiry != null) {
        final expiryDate = DateTime.parse(storedExpiry);

        if (expiryDate.isAfter(DateTime.now())) {
          _token = storedToken;
          _tokenExpiry = expiryDate;
          resetInactivityTimer();
          notifyListeners();
        } else {
          await logout();
        }
      }
    } catch (_) {
      await logout();
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
