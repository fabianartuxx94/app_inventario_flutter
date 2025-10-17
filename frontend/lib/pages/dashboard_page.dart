import 'package:flutter/material.dart';
import 'package:frontend/screens/articulos/catalogo_screen.dart';
import '../widgets/custom_background.dart';
import 'catalogo_page.dart';

class DashboardPage extends StatelessWidget {
  final String token;

  const DashboardPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CustomBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Panel principal',
                        style: Theme.of(context).textTheme.headlineMedium!
                            .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        // ignore: deprecated_member_use
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: [
                        _DashboardCard(
                          icon: Icons.category_rounded,
                          title: 'Categorias',
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
        builder: (_) => CatalogoScreen(token: token), // ← Pasar token
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            // ignore: deprecated_member_use
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
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
