import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _backupAutomatico = true;
  bool _sincronizacionAuto = true;
  int _frecuenciaSincronizacion = 30; // minutos
  bool _alertasEmail = true;
  bool _alertasPush = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Mismo estilo que otras pantallas
              const Text(
                'Configuración',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Información del usuario - Estilo consistente
              Card(
                color: Colors.white.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRoleColor(user?.rol ?? 'usuario'),
                    child: Text(
                      user?.displayName[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user?.displayName ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${user?.username ?? 'username'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user?.rol ?? 'usuario'),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleDisplayName(user?.rol ?? 'usuario'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ACTIVO',
                              style: TextStyle(
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
                ),
              ),
              const SizedBox(height: 16),

              // Configuración Avanzada (Solo para administradores)
              if (isAdmin) ...[
                _buildSectionHeader('Configuración Avanzada'),
                Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      // Backup automático
                      _buildSwitchTile(
                        title: 'Backup Automático',
                        subtitle: 'Realizar respaldos automáticos de la base de datos',
                        value: _backupAutomatico,
                        onChanged: (value) => setState(() => _backupAutomatico = value),
                        icon: Icons.backup,
                        activeColor: Colors.green,
                      ),
                      const Divider(color: Colors.white54, height: 1),
                      
                      // Sincronización automática
                      _buildSwitchTile(
                        title: 'Sincronización Automática',
                        subtitle: 'Sincronizar datos con el servidor automáticamente',
                        value: _sincronizacionAuto,
                        onChanged: (value) => setState(() => _sincronizacionAuto = value),
                        icon: Icons.sync,
                        activeColor: Colors.blue,
                      ),
                      
                      // Frecuencia de sincronización
                      if (_sincronizacionAuto) ...[
                        const Divider(color: Colors.white54, height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Frecuencia de sincronización: $_frecuenciaSincronizacion minutos',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Slider(
                                value: _frecuenciaSincronizacion.toDouble(),
                                min: 5,
                                max: 120,
                                divisions: 23,
                                label: '$_frecuenciaSincronizacion min',
                                onChanged: (value) {
                                  setState(() {
                                    _frecuenciaSincronizacion = value.toInt();
                                  });
                                },
                                activeColor: Colors.blue,
                                inactiveColor: Colors.white30,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Reportes y Analytics (Solo para administradores)
              if (isAdmin) ...[
                _buildSectionHeader('Reportes y Analytics'),
                Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      // Métricas del Dashboard
                      _buildListTile(
                        title: 'Métricas del Dashboard',
                        subtitle: 'Configurar métricas principales',
                        icon: Icons.dashboard,
                        onTap: _configurarMetricas,
                      ),
                      const Divider(color: Colors.white54, height: 1),
                      
                      // Exportación automática
                      _buildSwitchTile(
                        title: 'Exportación Automática',
                        subtitle: 'Generar reportes automáticamente',
                        value: _alertasEmail,
                        onChanged: (value) => setState(() => _alertasEmail = value),
                        icon: Icons.file_download,
                        activeColor: Colors.green,
                      ),
                      const Divider(color: Colors.white54, height: 1),
                      
                      // Alertas de Analytics
                      _buildSwitchTile(
                        title: 'Alertas de Analytics',
                        subtitle: 'Recibir alertas de métricas importantes',
                        value: _alertasPush,
                        onChanged: (value) => setState(() => _alertasPush = value),
                        icon: Icons.notifications,
                        activeColor: Colors.blue,
                      ),
                      const Divider(color: Colors.white54, height: 1),
                      
                      // Formatos de exportación
                      _buildListTile(
                        title: 'Formatos de Exportación',
                        subtitle: 'Configurar formatos preferidos',
                        icon: Icons.format_list_bulleted,
                        onTap: _configurarFormatos,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Seguridad (Visible para todos)
              _buildSectionHeader('Seguridad'),
              Card(
                color: Colors.white.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _buildListTile(
                      title: 'Cambiar Contraseña',
                      subtitle: 'Actualizar tu contraseña de acceso',
                      icon: Icons.lock,
                      onTap: () => _cambiarContrasena(authProvider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Información del Sistema (Último, visible para todos)
              _buildSectionHeader('Información del Sistema'),
              Card(
                color: Colors.white.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow('Versión de la App', '1.0.0'),
                      const Divider(color: Colors.white54, height: 16),
                      _buildInfoRow('Última Actualización', '15 Nov 2024'),
                      const Divider(color: Colors.white54, height: 16),
                      _buildInfoRow('Soporte Técnico', 'soporte@inventarioapp.com'),
                      const Divider(color: Colors.white54, height: 16),
                      _buildInfoRow('Base de Datos', 'MySQL 8.0'),
                      const Divider(color: Colors.white54, height: 16),
                      _buildInfoRow('Servidor API', 'Node.js v18'),
                      const Divider(color: Colors.white54, height: 16),
                      _buildInfoRow('Términos de Uso', 'Ver políticas'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón Acerca de
              Center(
                child: TextButton.icon(
                  onPressed: _verAcercaDe,
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  label: const Text(
                    'Acerca de InventarioApp',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para encabezados de sección
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget para items de lista con switch
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color activeColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        inactiveTrackColor: Colors.white30,
      ),
    );
  }

  // Widget para items de lista normales
  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
      onTap: onTap,
    );
  }

  // Widget para filas de información
  Widget _buildInfoRow(String titulo, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          valor,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  void _cambiarContrasena(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001F5E),
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Cambiar Contraseña',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Contraseña Actual',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
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
            ),
            const SizedBox(height: 16),
            TextFormField(
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
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Contraseña actualizada exitosamente'),
                  backgroundColor: Colors.green.shade600,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cambiar Contraseña'),
          ),
        ],
      ),
    );
  }

  void _configurarMetricas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001F5E),
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.dashboard, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Configurar Métricas',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: const [
              ListTile(
                title: Text('Total de Artículos', style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.toggle_on, color: Colors.green),
              ),
              ListTile(
                title: Text('Stock Bajo', style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.toggle_on, color: Colors.green),
              ),
              ListTile(
                title: Text('Movimientos del Mes', style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.toggle_off, color: Colors.grey),
              ),
              ListTile(
                title: Text('Usuarios Activos', style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.toggle_on, color: Colors.green),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _configurarFormatos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001F5E),
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.format_list_bulleted, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Formatos de Exportación',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: const [
              ListTile(
                title: Text('PDF', style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.check_box, color: Colors.green),
              ),
              ListTile(
                title: Text('Excel (.xlsx)', style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.check_box, color: Colors.green),
              ),
              ListTile(
                title: Text('CSV', style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.check_box_outline_blank, color: Colors.grey),
              ),
              ListTile(
                title: Text('JSON', style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.check_box_outline_blank, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _verAcercaDe() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001F5E),
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Acerca de InventarioApp',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'InventarioApp v1.0.0\n\n'
            'Sistema de gestión de inventario desarrollado para optimizar '
            'el control de activos y consumibles.\n\n'
            'Características:\n'
            '• Gestión completa de inventario\n'
            '• Control de categorías y artículos\n'
            '• Reportes y analytics\n'
            '• Multi-usuario con roles\n'
            '• Interfaz responsive\n\n'
            '© 2024 InventarioApp - Todos los derechos reservados',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
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

  String _getRoleDisplayName(String rol) {
    switch (rol) {
      case 'administrador':
        return 'ADMIN';
      case 'tecnico':
        return 'TÉCNICO';
      case 'bodega':
        return 'BODEGA';
      case 'usuario':
        return 'USUARIO';
      default:
        return rol.toUpperCase();
    }
  }
}