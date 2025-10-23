import 'dart:convert';

class Usuario {
  final String id;
  final String username;
  final String nombreCompleto;
  final String? email;
  final String rol;
  final bool activo;
  final dynamic bodega; // ✅ Puede ser String o List<String>

  Usuario({
    required this.id,
    required this.username,
    required this.nombreCompleto,
    this.email,
    required this.rol,
    required this.activo,
    this.bodega,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    dynamic bodegaValue;

    // ✅ Maneja distintos tipos de valores
    if (json['bodega'] != null) {
      if (json['bodega'] is String) {
        try {
          final parsed = jsonDecode(json['bodega']);
          bodegaValue = parsed is List ? parsed : json['bodega'];
        } catch (_) {
          bodegaValue = json['bodega'];
        }
      } else {
        bodegaValue = json['bodega'];
      }
    }

    return Usuario(
      id: json['id']?.toString() ?? '0',
      username: json['username'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      email: json['email'],
      rol: json['rol'] ?? 'usuario',
      activo: json['activo'] == 1 || json['activo'] == true,
      bodega: bodegaValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nombre_completo': nombreCompleto,
      'email': email,
      'rol': rol,
      'activo': activo,
      'bodega': bodega is List ? jsonEncode(bodega) : bodega,
    };
  }

  @override
  String toString() =>
      'Usuario(id: $id, username: $username, rol: $rol, bodega: $bodega)';
}
