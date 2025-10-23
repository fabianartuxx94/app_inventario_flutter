import 'package:flutter/material.dart';
import '../../models/usuario_model.dart';
import '../../services/usuarios_service.dart';

class UsuarioDialog {
  // Diálogo para crear usuario
  static Future<void> mostrarCrearUsuario({
    required BuildContext context,
    required VoidCallback onUsuarioCreado,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CrearUsuarioDialog(
        onUsuarioCreado: onUsuarioCreado,
      ),
    );
  }

  // Diálogo para editar usuario
  static Future<void> mostrarEditarUsuario({
    required BuildContext context,
    required Usuario usuario,
    required VoidCallback onUsuarioActualizado,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditarUsuarioDialog(
        usuario: usuario,
        onUsuarioActualizado: onUsuarioActualizado,
      ),
    );
  }
}

// ------------------------- Crear Usuario -------------------------
class _CrearUsuarioDialog extends StatefulWidget {
  final VoidCallback onUsuarioCreado;
  const _CrearUsuarioDialog({required this.onUsuarioCreado});

  @override
  State<_CrearUsuarioDialog> createState() => __CrearUsuarioDialogState();
}

class __CrearUsuarioDialogState extends State<_CrearUsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nombreCompletoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRol = 'usuario';
  String? _selectedBodega;
  bool _activo = true;
  bool _loading = false;

  final List<String> _roles = ['administrador', 'tecnico', 'bodega', 'usuario'];
  // Valores corregidos según el ENUM de la base de datos
  final List<String> _bodegas = [
    'Bodega Principal',
    'Bodega Garzón', 
    'Bodega Pitalito' // Corregido el nombre
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _nombreCompletoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _crearUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final usuarioData = {
        'username': _usernameController.text.trim(),
        'nombre_completo': _nombreCompletoController.text.trim(),
        'rol': _selectedRol,
        'activo': _activo,
        // Para ENUM, enviamos el string exacto o null
        'bodega': _selectedRol == 'usuario' ? null : _selectedBodega,
        'password': _passwordController.text,
      };

      final resultado = await UsuariosService.crearUsuario(usuarioData, context);

      if (resultado != null) {
        widget.onUsuarioCreado();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear el usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person_add),
          const SizedBox(width: 8),
          const Text('Nuevo Usuario'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un username';
                  }
                  if (value.length < 3) {
                    return 'El username debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nombre Completo
              TextFormField(
                controller: _nombreCompletoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rol
              DropdownButtonFormField<String>(
                value: _selectedRol,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: _roles.map((rol) => DropdownMenuItem(
                  value: rol,
                  child: Text(rol.toUpperCase()),
                )).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRol = newValue!;
                    if (_selectedRol == 'usuario') {
                      _selectedBodega = null; // Limpiar bodega
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Bodega: solo mostrar si rol no es 'usuario'
              if (_selectedRol != 'usuario')
                DropdownButtonFormField<String>(
                  value: _selectedBodega,
                  decoration: const InputDecoration(
                    labelText: 'Bodega',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Seleccione una bodega'),
                  items: _bodegas.map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(b),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedBodega = value),
                  validator: _selectedRol != 'usuario' ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor seleccione una bodega';
                    }
                    return null;
                  } : null,
                ),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese contraseña';
                  if (value.length < 6) return 'Debe tener al menos 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmar Contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Confirme contraseña';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Estado Activo
              Row(
                children: [
                  Checkbox(
                    value: _activo,
                    onChanged: (value) => setState(() => _activo = value!),
                  ),
                  const Text('Usuario Activo'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _crearUsuario,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear Usuario'),
        ),
      ],
    );
  }
}

// ------------------------- Editar Usuario -------------------------
class _EditarUsuarioDialog extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onUsuarioActualizado;

  const _EditarUsuarioDialog({
    required this.usuario,
    required this.onUsuarioActualizado,
  });

  @override
  State<_EditarUsuarioDialog> createState() => __EditarUsuarioDialogState();
}

class __EditarUsuarioDialogState extends State<_EditarUsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nombreCompletoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRol = 'usuario';
  String? _selectedBodega;
  bool _activo = true;
  bool _loading = false;
  bool _cambiarPassword = false;

  final List<String> _roles = ['administrador', 'tecnico', 'bodega', 'usuario'];
  // Valores corregidos según el ENUM de la base de datos
  final List<String> _bodegas = [
    'Bodega Principal',
    'Bodega Garzón', 
    'Bodega Pitalito' // Corregido el nombre
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  void _cargarDatosUsuario() {
    final usuario = widget.usuario;
    _usernameController.text = usuario.username;
    _nombreCompletoController.text = usuario.nombreCompleto;
    _selectedRol = usuario.rol;
    _activo = usuario.activo;
    _selectedBodega = usuario.bodega is String ? usuario.bodega : null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nombreCompletoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _actualizarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cambiarPassword && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final usuarioData = {
        'username': _usernameController.text.trim(),
        'nombre_completo': _nombreCompletoController.text.trim(),
        'rol': _selectedRol,
        'activo': _activo,
        // Para ENUM, enviamos el string exacto o null
        'bodega': _selectedRol == 'usuario' ? null : _selectedBodega,
      };

      if (_cambiarPassword && _passwordController.text.isNotEmpty) {
        usuarioData['password'] = _passwordController.text;
      }

      final resultado = await UsuariosService.actualizarUsuario(
        widget.usuario.id,
        usuarioData,
        context,
      );

      if (resultado != null) {
        widget.onUsuarioActualizado();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit),
          const SizedBox(width: 8),
          const Text('Editar Usuario'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un username';
                  }
                  if (value.length < 3) {
                    return 'El username debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nombre Completo
              TextFormField(
                controller: _nombreCompletoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rol
              DropdownButtonFormField<String>(
                value: _selectedRol,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: _roles.map((rol) => DropdownMenuItem(
                  value: rol,
                  child: Text(rol.toUpperCase()),
                )).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRol = newValue!;
                    if (_selectedRol == 'usuario') {
                      _selectedBodega = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Bodega
              DropdownButtonFormField<String>(
                value: _selectedBodega,
                decoration: const InputDecoration(
                  labelText: 'Bodega',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Seleccione una bodega'),
                items: _bodegas.map((b) => DropdownMenuItem(
                  value: b,
                  child: Text(b),
                )).toList(),
                onChanged: _selectedRol == 'usuario' 
                    ? null 
                    : (value) => setState(() => _selectedBodega = value),
                validator: _selectedRol != 'usuario' ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione una bodega';
                  }
                  return null;
                } : null,
              ),
              const SizedBox(height: 16),

              // Cambiar contraseña
              Row(
                children: [
                  Checkbox(
                    value: _cambiarPassword,
                    onChanged: (value) => setState(() => _cambiarPassword = value!),
                  ),
                  const Text('Cambiar contraseña'),
                ],
              ),
              const SizedBox(height: 16),

              if (_cambiarPassword) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_cambiarPassword) {
                      if (value == null || value.isEmpty) return 'Ingrese contraseña';
                      if (value.length < 6) return 'Debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_cambiarPassword && (value == null || value.isEmpty)) {
                      return 'Confirme contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Estado Activo
              Row(
                children: [
                  Checkbox(
                    value: _activo,
                    onChanged: (value) => setState(() => _activo = value!),
                  ),
                  const Text('Usuario Activo'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _actualizarUsuario,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Actualizar Usuario'),
        ),
      ],
    );
  }
}