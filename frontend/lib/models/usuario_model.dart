class Usuario {
  final String id; // ✅ Cambiado a String
  final String username;
  final String nombreCompleto;
  final String? email;
  final String rol;
  final bool activo;

  Usuario({
    required this.id,
    required this.username,
    required this.nombreCompleto,
    this.email,
    required this.rol,
    required this.activo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '0', // ✅ Convertir a String
      username: json['username'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      email: json['email'],
      rol: json['rol'] ?? 'usuario',
      activo: json['activo'] == 1 || json['activo'] == true,
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
    };
  }
}