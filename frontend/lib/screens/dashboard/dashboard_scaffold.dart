import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../categorias/categorias_page.dart';
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

  final List<Widget> _mainPages = const [
    DashboardHome(),
    CategoriasPage(),
    ArticulosScreen(),
    Placeholder(), // Reportes
    Placeholder(), // Configuración
  ];

  final List<String> _titles = [
    "Dashboard",
    "Categorías",
    "Artículos",
    "Reportes",
    "Configuración",
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar con ArticulosScreen que tiene los callbacks
    _currentPage = ArticulosScreen(
      onCrearArticulo: _navigateToCrearArticulo,
      onEditarArticulo: _navigateToEditarArticulo,
    );
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 2) {
        // Artículos - mantener con callbacks
        _currentPage = ArticulosScreen(
          onCrearArticulo: _navigateToCrearArticulo,
          onEditarArticulo: _navigateToEditarArticulo,
        );
      } else {
        _currentPage = _mainPages[index];
      }
    });
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
      _currentPage = ArticulosScreen(
        onCrearArticulo: _navigateToCrearArticulo,
        onEditarArticulo: _navigateToEditarArticulo,
      );
      _selectedIndex = 2;
    });
  }

  void _logout() {
  // Mostrar diálogo de confirmación personalizado
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text("Cerrar sesión"),
          ],
        ),
        content: const Text(
          "¿Estás seguro de que quieres cerrar sesión?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar el diálogo
            },
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar el diálogo
              // Proceder con el cierre de sesión
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text("Cerrar sesión"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

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
    drawer: isCrearArticulo || isEditarArticulo ? null : _buildDrawer(context),
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
    } else {
      return Text(
        _titles[_selectedIndex],
        style: const TextStyle(color: Colors.white),
      );
    }
  }

  Widget _buildDrawer(BuildContext context) {
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
          for (int i = 0; i < _titles.length; i++)
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
                _titles[i],
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