import 'package:flutter/material.dart';
import 'package:frontend/widgets/usuarios_dialog.dart';
import '../../models/usuario_model.dart';
import '../../services/usuarios_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Usuario> _usuarios = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _errorMessage;
  Usuario? _usuarioSeleccionado; // Para controlar la selección en móvil

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _usuarioSeleccionado = null; // Resetear selección al recargar
    });
    
    try {
      print('🔄 INICIANDO CARGA DE USUARIOS...');
      final usuariosData = await UsuariosService.getUsuarios(context);
      
      print('📦 DATOS RECIBIDOS: $usuariosData');
      print('📦 TIPO DE DATOS: ${usuariosData.runtimeType}');
      
      if (usuariosData != null) {
        final List<Usuario> usuariosConvertidos = [];
        
        for (var data in usuariosData) {
          try {
            print('🔍 Procesando usuario: $data');
            final usuario = Usuario.fromJson(data);
            usuariosConvertidos.add(usuario);
            print('✅ Usuario convertido: ${usuario.username}');
          } catch (e) {
            print('❌ Error convirtiendo usuario: $e');
            print('❌ Datos problemáticos: $data');
          }
        }
        
        print('📊 TOTAL USUARIOS CONVERTIDOS: ${usuariosConvertidos.length}');
        
        setState(() {
          _usuarios = usuariosConvertidos;
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudieron cargar los usuarios desde el servidor';
        });
      }
    } catch (e) {
      print('❌ ERROR EN _cargarUsuarios: $e');
      setState(() {
        _errorMessage = 'Error al cargar usuarios: ${e.toString()}';
      });
    } finally {
      setState(() => _loading = false);
    }
  } 

  void _navigateToCrearUsuario() {
    UsuarioDialog.mostrarCrearUsuario(
      context: context,
      onUsuarioCreado: _onUsuarioCreado,
    );
  }

  void _navigateToEditarUsuario(Usuario usuario) {
    UsuarioDialog.mostrarEditarUsuario(
      context: context,
      usuario: usuario,
      onUsuarioActualizado: _onUsuarioActualizado,
    );
  }

  void _onUsuarioCreado() {
    _cargarUsuarios();
  }

  void _onUsuarioActualizado() {
    _cargarUsuarios();
    setState(() {
      _usuarioSeleccionado = null; // Deseleccionar después de editar
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _eliminarUsuario(Usuario usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de que quieres eliminar al usuario "${usuario.nombreCompleto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        final exito = await UsuariosService.eliminarUsuario(usuario.id, context);
        if (exito) {
          _cargarUsuarios();
          _mostrarExito('Usuario eliminado exitosamente');
          setState(() {
            _usuarioSeleccionado = null; // Deseleccionar después de eliminar
          });
        } else {
          _mostrarError('Error al eliminar el usuario');
        }
      } catch (e) {
        _mostrarError('Error al eliminar usuario: $e');
      }
    }
  }

  void _seleccionarUsuario(Usuario usuario) {
    setState(() {
      _usuarioSeleccionado = _usuarioSeleccionado == usuario ? null : usuario;
    });
  }

  List<Usuario> get _usuariosFiltrados {
    if (_searchQuery.isEmpty) return _usuarios;
    
    return _usuarios.where((usuario) {
      final query = _searchQuery.toLowerCase();
      return usuario.nombreCompleto.toLowerCase().contains(query) ||
             usuario.username.toLowerCase().contains(query) ||
             usuario.rol.toLowerCase().contains(query);
    }).toList();
  }

  Color _getRoleColor(String rol) {
    switch (rol) {
      case 'administrador':
        return Colors.red;
      case 'tecnico':
        return Colors.blue;
      case 'bodega':
        return Colors.orange;
      case 'usuario':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Detectar si es móvil
  bool get _esMovil {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width < 760; // Umbral para móvil
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Usuarios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // Botón Recargar
                  _esMovil
                      ? IconButton(
                          onPressed: _cargarUsuarios,
                          icon: const Icon(Icons.refresh),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _cargarUsuarios,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recargar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                  const SizedBox(width: 8),
                  // Botón Nuevo Usuario
                  _esMovil
                      ? IconButton(
                          onPressed: _navigateToCrearUsuario,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _navigateToCrearUsuario,
                          icon: const Icon(Icons.add),
                          label: const Text('Nuevo Usuario'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de búsqueda
          Card(
            color: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Buscar usuarios...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mensaje de error
          if (_errorMessage != null) ...[
            Card(
              color: Colors.red.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _cargarUsuarios,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Lista de usuarios
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _usuarios.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.white54),
                            SizedBox(height: 16),
                            Text(
                              'No se encontraron usuarios',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : _usuariosFiltrados.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay usuarios que coincidan con la búsqueda',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _usuariosFiltrados.length,
                            itemBuilder: (context, index) {
                              final usuario = _usuariosFiltrados[index];
                              final estaSeleccionado = _usuarioSeleccionado == usuario;
                              
                              return Card(
                                color: Colors.white.withOpacity(0.1),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getRoleColor(usuario.rol),
                                    child: Text(
                                      usuario.nombreCompleto[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    usuario.nombreCompleto,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '@${usuario.username}',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(usuario.rol),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              usuario.rol.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: usuario.activo ? Colors.green : Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              usuario.activo ? 'ACTIVO' : 'INACTIVO',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                 trailing: _esMovil
    ? (estaSeleccionado
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                iconSize: 20.0, // Tamaño reducido para móvil
                padding: EdgeInsets.all(5.0), // Elimina espacio interno
                constraints: BoxConstraints(), // Elimina espacio externo
                onPressed: () => _navigateToEditarUsuario(usuario),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                iconSize: 20.0, // Tamaño reducido para móvil
                padding: EdgeInsets.all(5.0),
                constraints: BoxConstraints(),
                onPressed: () => _eliminarUsuario(usuario),
              ),
            ],
          )
        : null)
    : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _navigateToEditarUsuario(usuario),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _eliminarUsuario(usuario),
          ),
        ],
      ),
                                  onTap: _esMovil
                                      ? () => _seleccionarUsuario(usuario)
                                      : null,
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}