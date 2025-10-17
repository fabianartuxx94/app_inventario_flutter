import 'package:flutter/material.dart';
import 'package:frontend/screens/articulos/catalogo_screen.dart';
import '../widgets/custom_background.dart';
import 'catalogo_page.dart';
import '../widgets/responsive_layout.dart';

class DashboardPage extends StatelessWidget {
  final String token;

  const DashboardPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: ResponsiveLayout.isMobile(context) ? _buildDrawer(context) : null,
      body: Stack(
        children: [
          const CustomBackground(),
          SafeArea(
            child: ResponsiveLayout(
              mobileBody: _buildMobileLayout(context),
              desktopBody: _buildDesktopLayout(context),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────── MOBILE ─────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Panel principal',
            style: TextStyle(color: Colors.white),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildGrid(context, crossAxisCount: 2),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────── DESKTOP ─────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildSidebar(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel principal',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: _buildGrid(context, crossAxisCount: 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────── GRID DE TARJETAS ─────────────────────────────────

  Widget _buildGrid(BuildContext context, {required int crossAxisCount}) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      children: [
        _DashboardCard(
          icon: Icons.category_rounded,
          title: 'Categorías',
          color: const Color(0xFF2E8BFF),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CatalogoPage(token: token),
              ),
            );
          },
        ),
        _DashboardCard(
          icon: Icons.inventory,
          title: 'Artículos',
          color: const Color(0xFF3EB489),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CatalogoScreen(token: token),
              ),
            );
          },
        ),
        const _DashboardCard(
          icon: Icons.analytics_rounded,
          title: 'Reportes',
          color: Color(0xFFE0B200),
        ),
        const _DashboardCard(
          icon: Icons.settings_rounded,
          title: 'Configuración',
          color: Color(0xFFB14AED),
        ),
      ],
    );
  }

  // ───────────────────────────────── SIDEBAR ─────────────────────────────────

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.black.withOpacity(0.4),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.inventory, size: 50, color: Colors.white),
          const SizedBox(height: 10),
          const Text(
            "InventarioApp",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 40),
          _buildNavItem(Icons.dashboard, 'Dashboard'),
          _buildNavItem(Icons.category, 'Categorías'),
          _buildNavItem(Icons.inventory, 'Artículos'),
          _buildNavItem(Icons.analytics, 'Reportes'),
          _buildNavItem(Icons.settings, 'Configuración'),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "v1.0.0",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        // TODO: navegación futura
      },
    );
  }

  // ───────────────────────────────── DRAWER ─────────────────────────────────

  Widget _buildDrawer(BuildContext context) {
  return Drawer(
    backgroundColor: Colors.black.withOpacity(0.8),
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.inventory, size: 48, color: Colors.white),
              SizedBox(height: 10),
              Text(
                'InventarioApp',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
        _buildDrawerItem(context, Icons.dashboard, 'Dashboard'),
        _buildDrawerItem(context, Icons.category, 'Categorías'),
        _buildDrawerItem(context, Icons.inventory, 'Artículos'),
        _buildDrawerItem(context, Icons.analytics, 'Reportes'),
        _buildDrawerItem(context, Icons.settings, 'Configuración'),
      ],
    ),
  );
}

  Widget _buildDrawerItem(BuildContext context, IconData icon, String label) {
  return ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(label, style: const TextStyle(color: Colors.white)),
    onTap: () {
      Navigator.pop(context);
      // TODO: navega según label si quieres
      },
    );
  }
}

// ───────────────────────────────── DASHBOARD CARD ─────────────────────────────────

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
