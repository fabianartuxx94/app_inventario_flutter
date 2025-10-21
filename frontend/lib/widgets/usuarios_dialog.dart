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

// Diálogo para crear usuario
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
  bool _activo = true;
  bool _loading = false;

  final List<String> _roles = ['administrador', 'tecnico', 'bodega', 'usuario'];

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
        'password': _passwordController.text,
        'activo': _activo,
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
      backgroundColor: const Color(0xFF001F5E),
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          const Icon(Icons.person_add, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            'Crear Nuevo Usuario',
            style: TextStyle(color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
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
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
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
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              
              const SizedBox(height: 16),

              // Rol
              DropdownButtonFormField<String>(
                value: _selectedRol,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF001F5E),
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                items: _roles.map((String rol) {
                  return DropdownMenuItem<String>(
                    value: rol,
                    child: Text(
                      rol.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRol = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmar Contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor confirme la contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Estado Activo
              Row(
                children: [
                  Checkbox(
                    value: _activo,
                    onChanged: (bool? value) {
                      setState(() {
                        _activo = value!;
                      });
                    },
                    checkColor: Colors.white,
                    fillColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.green;
                        }
                        return Colors.white70;
                      },
                    ),
                  ),
                  const Text(
                    'Usuario Activo',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _crearUsuario,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Crear Usuario'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}

// Diálogo para editar usuario
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
  bool _activo = true;
  bool _loading = false;
  bool _cambiarPassword = false;

  final List<String> _roles = ['administrador', 'tecnico', 'bodega', 'usuario'];

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
      };

      // Solo incluir password si se está cambiando
      if (_cambiarPassword && _passwordController.text.isNotEmpty) {
        usuarioData['password'] = _passwordController.text;
      }

      final resultado = await UsuariosService.actualizarUsuario(
        widget.usuario.id, 
        usuarioData, 
        context
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
      backgroundColor: const Color(0xFF001F5E),
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          const Icon(Icons.edit, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            'Editar Usuario',
            style: TextStyle(color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
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
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
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
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
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
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF001F5E),
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                items: _roles.map((String rol) {
                  return DropdownMenuItem<String>(
                    value: rol,
                    child: Text(
                      rol.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRol = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Cambiar contraseña
              Row(
                children: [
                  Checkbox(
                    value: _cambiarPassword,
                    onChanged: (bool? value) {
                      setState(() {
                        _cambiarPassword = value!;
                      });
                    },
                    checkColor: Colors.white,
                    fillColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.blue;
                        }
                        return Colors.white70;
                      },
                    ),
                  ),
                  const Text(
                    'Cambiar contraseña',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contraseña (solo si se está cambiando)
              if (_cambiarPassword) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: _cambiarPassword ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  } : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: _cambiarPassword ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirme la contraseña';
                    }
                    return null;
                  } : null,
                ),
                const SizedBox(height: 16),
              ],

              // Estado Activo
              Row(
                children: [
                  Checkbox(
                    value: _activo,
                    onChanged: (bool? value) {
                      setState(() {
                        _activo = value!;
                      });
                    },
                    checkColor: Colors.white,
                    fillColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.green;
                        }
                        return Colors.white70;
                      },
                    ),
                  ),
                  const Text(
                    'Usuario Activo',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _actualizarUsuario,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Actualizar Usuario'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}