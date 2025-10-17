import 'package:flutter/material.dart';
import '../../widgets/custom_background.dart';

class DashboardScaffold extends StatelessWidget {
  final Widget child;
  final String title;

  const DashboardScaffold({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      drawer: isDesktop ? null : _buildDrawer(context),
      body: Stack(
        children: [
          const CustomBackground(),
          SafeArea(
            child: Row(
              children: [
                if (isDesktop) _buildSidebar(context),
                Expanded(
                  child: Column(
                    children: [
                      if (!isDesktop)
                        AppBar(
                          title: Text(title),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          centerTitle: true,
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF001F5E),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          const ListTile(
            leading: Icon(Icons.dashboard, color: Colors.white),
            title: Text('Dashboard', style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.white),
            title: const Text('Catálogo', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Navegar a catálogo (implementa navegación)
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF001F5E),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            'Inventario App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          _SidebarItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () {
              // Navega al dashboard
            },
          ),
          _SidebarItem(
            icon: Icons.category,
            label: 'Catálogo',
            onTap: () {
              // Navega al catálogo
            },
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
