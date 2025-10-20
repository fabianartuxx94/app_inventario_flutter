import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../categorias/categorias_page.dart'; // ← Asegurar que esté importada
import '../articulos/articulos_screen.dart';
import '../articulos/crear_articulo_screen.dart';
import '../articulos/editar_articulo_screen.dart';
import '../login_page.dart';
import '../../widgets/custom_background.dart';

class DashboardScaffold extends StatefulWidget {
  const DashboardScaffold({super.key});

  @override
  State<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<DashboardScaffold> {
  int _selectedIndex = 0;
  Widget _currentPage = const DashboardHome();

  @override
  void initState() {
    super.initState();
    _currentPage = _buildArticulosScreen();
  }

  // Método para construir ArticulosScreen con los callbacks
  Widget _buildArticulosScreen() {
    return ArticulosScreen(
      onCrearArticulo: _navigateToCrearArticulo,
      onEditarArticulo: _navigateToEditarArticulo,
    );
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 2) {
        // Artículos - mantener con callbacks
        _currentPage = _buildArticulosScreen();
      } else {
        // Para otras páginas
        _currentPage = _buildPageForIndex(index);
      }
    });
  }

  Widget _buildPageForIndex(int index) {
    switch (index) {
      case 0:
        return const DashboardHome();
      case 1:
        return const CategoriasPage(); // ← Categorías agregada
      case 2:
        return _buildArticulosScreen();
      case 3:
        return _buildPlaceholderPage("Reportes");
      case 4:
        return _buildPlaceholderPage("Configuración");
      default:
        return const DashboardHome();
    }
  }

  Widget _buildPlaceholderPage(String title) {
    return Center(
      child: Text(
        "$title - En desarrollo",
        style: const TextStyle(color: Colors.white, fontSize: 22),
      ),
    );
  }

  void _navigateToCrearArticulo() {
    setState(() {
      _currentPage = CrearArticuloScreen(
        onArticuloCreado: _volverAListaArticulos,
        onCancelar: _volverAListaArticulos,
      );
      _selectedIndex = 2;
    });
  }

  void _navigateToEditarArticulo(dynamic articulo) {
    print("Navegando a editar artículo: ${articulo.referencia}");
    setState(() {
      _currentPage = EditarArticuloScreen(
        articulo: articulo,
        onArticuloActualizado: _volverAListaArticulos,
        onCancelar: _volverAListaArticulos,
      );
      _selectedIndex = 2;
    });
  }

  void _volverAListaArticulos() {
    setState(() {
      _currentPage = _buildArticulosScreen();
      _selectedIndex = 2;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cerrar sesión"),
          content: const Text("¿Estás seguro de que quieres cerrar sesión?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text("Sí, cerrar sesión"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 760;

    return Scaffold(
      body: Stack(
        children: [
          const CustomBackground(),
          SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      _buildSidebar(),
                      Expanded(child: _currentPage),
                    ],
                  )
                : _buildMobileView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final items = [
      ('Dashboard', Icons.dashboard),
      ('Categorías', Icons.category),
      ('Artículos', Icons.inventory),
      ('Reportes', Icons.analytics),
      ('Configuración', Icons.settings),
    ];

    return Container(
      width: 220,
      color: const Color(0xFF001F5E).withOpacity(0.85),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.inventory, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          const Text(
            "InventarioApp",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 30),
          for (int i = 0; i < items.length; i++)
            ListTile(
              leading: Icon(items[i].$2, color: Colors.white),
              title: Text(
                items[i].$1,
                style: const TextStyle(color: Colors.white),
              ),
              selected: _selectedIndex == i,
              selectedTileColor: Colors.white12,
              onTap: () => _onItemSelected(i),
            ),
          const Spacer(),
          const Divider(color: Colors.white54),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text(
              "Cerrar sesión",
              style: TextStyle(color: Colors.white),
            ),
            onTap: _logout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    final isCrearArticulo = _currentPage is CrearArticuloScreen;
    final isEditarArticulo = _currentPage is EditarArticuloScreen;
    final isCategoriasPage = _currentPage is CategoriasPage;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isCrearArticulo || isEditarArticulo
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _volverAListaArticulos,
              )
            : isCategoriasPage && _selectedIndex != 1
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => _onItemSelected(0),
                  )
                : null,
        iconTheme: const IconThemeData(color: Colors.white),
        title: _buildAppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: _logout,
          ),
        ],
      ),
      drawer: (isCrearArticulo || isEditarArticulo) ? null : _buildDrawer(context),
      body: _currentPage,
    );
  }

  Widget _buildAppBarTitle() {
    if (_currentPage is CrearArticuloScreen) {
      return const Text(
        'Crear Artículo',
        style: TextStyle(color: Colors.white),
      );
    } else if (_currentPage is EditarArticuloScreen) {
      return const Text(
        'Editar Artículo',
        style: TextStyle(color: Colors.white),
      );
    } else if (_currentPage is ArticulosScreen) {
      return const Text(
        'Artículos',
        style: TextStyle(color: Colors.white),
      );
    } else if (_currentPage is CategoriasPage) {
      return const Text(
        'Categorías',
        style: TextStyle(color: Colors.white),
      );
    } else {
      final titles = ["Dashboard", "Categorías", "Artículos", "Reportes", "Configuración"];
      return Text(
        titles[_selectedIndex],
        style: const TextStyle(color: Colors.white),
      );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final titles = ["Dashboard", "Categorías", "Artículos", "Reportes", "Configuración"];
    
    return Drawer(
      backgroundColor: const Color(0xFF001F5E).withOpacity(0.9),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.inventory, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          const Text(
            "InventarioApp",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < titles.length; i++)
            ListTile(
              leading: Icon(
                [
                  Icons.dashboard,
                  Icons.category,
                  Icons.inventory,
                  Icons.analytics,
                  Icons.settings
                ][i],
                color: Colors.white,
              ),
              title: Text(
                titles[i],
                style: const TextStyle(color: Colors.white),
              ),
              selected: _selectedIndex == i,
              selectedTileColor: Colors.white12,
              onTap: () {
                Navigator.pop(context);
                _onItemSelected(i);
              },
            ),
          const Spacer(),
          const Divider(color: Colors.white54),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text(
              "Cerrar sesión",
              style: TextStyle(color: Colors.white),
            ),
            onTap: _logout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Bienvenido al Panel de Inventario",
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
    );
  }
}