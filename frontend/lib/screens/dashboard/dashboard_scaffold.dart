import 'package:flutter/material.dart';
import 'package:frontend/screens/usuarios/usuarios_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/menu_service.dart';
import '../categorias/categorias_page.dart';
import '../articulos/articulos_screen.dart';
import '../articulos/crear_articulo_screen.dart';
import '../articulos/editar_articulo_screen.dart';
import '../../widgets/custom_background.dart';

class DashboardScaffold extends StatefulWidget {
  const DashboardScaffold({super.key});

  @override
  State<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<DashboardScaffold> {
  int _selectedIndex = 0;
  late Widget _currentPage;
  List<MenuOption> _menuOptions = [];
  final Set<String> _expandedMenus = {};

  @override
  void initState() {
    super.initState();
    _initializeMenu();
    _currentPage = DashboardHome(authProvider: Provider.of<AuthProvider>(context, listen: false));
  }

  void _initializeMenu() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _menuOptions = MenuService.getMenuOptions(authProvider.userRol);
  }

  Widget _buildArticulosScreen() {
    return ArticulosScreen(
      onCrearArticulo: _navigateToCrearArticulo,
      onEditarArticulo: _navigateToEditarArticulo,
    );
  }

  void _onItemSelected(int index) {
    if (index >= _menuOptions.length && index < 100) return;
    
    setState(() {
      _selectedIndex = index;
      _currentPage = _buildPageForIndex(index);
    });
  }

  Widget _buildPageForIndex(int index) {
    // Si es un índice de submenú (>= 100)
    if (index >= 100) {
      final mainIndex = (index - 100) ~/ 10;
      final subIndex = (index - 100) % 10;
      
      if (mainIndex < _menuOptions.length && 
          _menuOptions[mainIndex].submenu != null &&
          subIndex < _menuOptions[mainIndex].submenu!.length) {
        
        final subOption = _menuOptions[mainIndex].submenu![subIndex];
        return _buildPageForRoute(subOption.route);
      }
    }
    
    // Si es un índice de menú principal
    if (index < _menuOptions.length) {
      return _buildPageForRoute(_menuOptions[index].route);
    }
    
    return DashboardHome(authProvider: Provider.of<AuthProvider>(context, listen: false));
  }

  Widget _buildPageForRoute(String route) {
    switch (route) {
      case '/dashboard':
        return DashboardHome(authProvider: Provider.of<AuthProvider>(context, listen: false));
      case '/categorias':
        return const CategoriasPage();
      case '/articulos':
        return _buildArticulosScreen();
      case '/activos':
        return _buildPlaceholderPage("Activos");
      case '/consumibles':
        return _buildPlaceholderPage("Consumibles");
      case '/movimientos':
        return _buildPlaceholderPage("Movimientos");
      case '/sitios-venta':
        return _buildPlaceholderPage("Sitios de Venta");
      case '/usuarios':
        return const UsuariosScreen();
      case '/reportes':
        return _buildPlaceholderPage("Reportes");
      case '/configuracion':
        return _buildPlaceholderPage("Configuración");
      case '/ruteros':
        return _buildPlaceholderPage("Ruteros");
      case '/mantenimientos':
        return _buildPlaceholderPage("Mantenimientos SV");
      case '/ubicaciones':
        return _buildPlaceholderPage("Ubicaciones");
      case '/asignaciones':
        return _buildPlaceholderPage("Asignaciones");
      case '/entradas-compras':
        return _buildPlaceholderPage("Entradas Compras");
      default:
        return DashboardHome(authProvider: Provider.of<AuthProvider>(context, listen: false));
    }
  }

  Widget _buildPlaceholderPage(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            "$title - En desarrollo",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Esta funcionalidad estará disponible pronto",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCrearArticulo() {
    setState(() {
      _currentPage = CrearArticuloScreen(
        onArticuloCreado: _volverAListaArticulos,
        onCancelar: _volverAListaArticulos,
      );
      _updateSelectedIndexForRoute('/articulos');
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
      _updateSelectedIndexForRoute('/articulos');
    });
  }

  void _volverAListaArticulos() {
    setState(() {
      _currentPage = _buildArticulosScreen();
      _updateSelectedIndexForRoute('/articulos');
    });
  }

  void _updateSelectedIndexForRoute(String route) {
    final routeIndex = _findMenuIndexByRoute(route);
    _selectedIndex = routeIndex >= 0 ? routeIndex : 0;
  }

  int _findMenuIndexByRoute(String route) {
    for (int i = 0; i < _menuOptions.length; i++) {
      // Buscar en menús principales
      if (_menuOptions[i].route == route) {
        return i;
      }
      // Buscar en submenús
      if (_menuOptions[i].submenu != null) {
        for (int j = 0; j < _menuOptions[i].submenu!.length; j++) {
          if (_menuOptions[i].submenu![j].route == route) {
            return 100 + (i * 10) + j;
          }
        }
      }
    }
    return -1;
  }

  bool _isExpandedMenu(String route) {
    return _expandedMenus.contains(route);
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
                Provider.of<AuthProvider>(context, listen: false)
                    .logoutWithNavigation(context);
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
    final authProvider = Provider.of<AuthProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 760;

    return Scaffold(
      body: Stack(
        children: [
          const CustomBackground(),
          SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      _buildSidebar(authProvider),
                      Expanded(child: _currentPage),
                    ],
                  )
                : _buildMobileView(context, authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AuthProvider authProvider) {
    return Container(
      width: 220,
      color: const Color(0xFF001F5E).withOpacity(0.85),
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildUserHeader(authProvider),
          const SizedBox(height: 20),
          const Divider(color: Colors.white54, height: 1),
          const SizedBox(height: 10),
          
          Expanded(
            child: ListView(
              children: [
                for (int i = 0; i < _menuOptions.length; i++)
                  _buildMenuTile(_menuOptions[i], i),
              ],
            ),
          ),
          
          const Divider(color: Colors.white54, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text(
              "Cerrar sesión",
              style: TextStyle(color: Colors.white),
            ),
            onTap: _logout,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMenuTile(MenuOption option, int index) {
    final hasSubmenu = option.submenu != null && option.submenu!.isNotEmpty;
    final isExpanded = _isExpandedMenu(option.route);

    return Column(
      children: [
        ListTile(
          leading: Icon(option.icon, color: Colors.white),
          title: Text(
            option.title,
            style: const TextStyle(color: Colors.white),
          ),
          trailing: hasSubmenu
              ? Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                )
              : null,
          selected: _selectedIndex == index && !hasSubmenu,
          selectedTileColor: Colors.white12,
          onTap: () {
            if (hasSubmenu) {
              setState(() {
                if (isExpanded) {
                  _expandedMenus.remove(option.route);
                } else {
                  _expandedMenus.add(option.route);
                }
              });
            } else {
              _onItemSelected(index);
            }
          },
        ),
        if (hasSubmenu && isExpanded)
          ...option.submenu!.map((subOption) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ListTile(
                leading: Icon(subOption.icon, color: Colors.white70, size: 20),
                title: Text(
                  subOption.title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                selected: _selectedIndex == _findMenuIndexByRoute(subOption.route),
                selectedTileColor: Colors.white10,
                onTap: () {
                  final realIndex = _findMenuIndexByRoute(subOption.route);
                  if (realIndex != -1) {
                    _onItemSelected(realIndex);
                  }
                },
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildUserHeader(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ✅ CORREGIDO: Imagen completa sin forma circular
          Container(
            width: 120, // Tamaño más ancho para mostrar la imagen completa
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12), // Bordes redondeados suaves
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/suchance.png', // ✅ Cambiado a .png
              fit: BoxFit.contain, // Muestra toda la imagen sin recortar
              errorBuilder: (context, error, stackTrace) {
                // Fallback si la imagen no existe
                return Container(
                  decoration: BoxDecoration(
                    color: _getRoleColor(authProvider.userRol),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 50,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            authProvider.user?.displayName ?? 'Usuario',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(authProvider.userRol),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getRoleDisplayName(authProvider.userRol),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (authProvider.user?.username != null) ...[
            const SizedBox(height: 4),
            Text(
              '@${authProvider.user!.username}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileView(BuildContext context, AuthProvider authProvider) {
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
            : isCategoriasPage && _selectedIndex != _findMenuIndexByRoute('/categorias')
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => _onItemSelected(_findMenuIndexByRoute('/dashboard')),
                  )
                : null,
        iconTheme: const IconThemeData(color: Colors.white),
        title: _buildAppBarTitle(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text(
                _getRoleDisplayName(authProvider.userRol),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _getRoleColor(authProvider.userRol),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: _logout,
          ),
        ],
      ),
      drawer: (isCrearArticulo || isEditarArticulo) ? null : _buildDrawer(context, authProvider),
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
      for (int i = 0; i < _menuOptions.length; i++) {
        if (_selectedIndex == i) {
          return Text(
            _menuOptions[i].title,
            style: const TextStyle(color: Colors.white),
          );
        }
        if (_menuOptions[i].submenu != null) {
          for (int j = 0; j < _menuOptions[i].submenu!.length; j++) {
            final subIndex = 100 + (i * 10) + j;
            if (_selectedIndex == subIndex) {
              return Text(
                _menuOptions[i].submenu![j].title,
                style: const TextStyle(color: Colors.white),
              );
            }
          }
        }
      }
      return const Text(
        'Dashboard',
        style: TextStyle(color: Colors.white),
      );
    }
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      backgroundColor: const Color(0xFF001F5E).withOpacity(0.9),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // ✅ CORREGIDO: Imagen completa en drawer
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/suchance.png', // ✅ Cambiado a .png
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: _getRoleColor(authProvider.userRol),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 60,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "InventarioApp",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(authProvider.userRol),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getRoleDisplayName(authProvider.userRol),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: ListView(
              children: [
                for (int i = 0; i < _menuOptions.length; i++)
                  _buildMobileMenuTile(_menuOptions[i], i, context),
              ],
            ),
          ),
          
          const Spacer(),
          const Divider(color: Colors.white54),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.user?.displayName ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  authProvider.user?.username ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
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

  Widget _buildMobileMenuTile(MenuOption option, int index, BuildContext context) {
    final hasSubmenu = option.submenu != null && option.submenu!.isNotEmpty;
    final isExpanded = _isExpandedMenu(option.route);

    return Column(
      children: [
        ListTile(
          leading: Icon(option.icon, color: Colors.white),
          title: Text(
            option.title,
            style: const TextStyle(color: Colors.white),
          ),
          trailing: hasSubmenu
              ? Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                )
              : null,
          selected: _selectedIndex == index && !hasSubmenu,
          selectedTileColor: Colors.white12,
          onTap: () {
            if (hasSubmenu) {
              setState(() {
                if (isExpanded) {
                  _expandedMenus.remove(option.route);
                } else {
                  _expandedMenus.add(option.route);
                }
              });
            } else {
              Navigator.pop(context);
              _onItemSelected(index);
            }
          },
        ),
        if (hasSubmenu && isExpanded)
          ...option.submenu!.map((subOption) {
            return Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: ListTile(
                leading: Icon(subOption.icon, color: Colors.white70, size: 18),
                title: Text(
                  subOption.title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                selected: _selectedIndex == _findMenuIndexByRoute(subOption.route),
                selectedTileColor: Colors.white10,
                onTap: () {
                  Navigator.pop(context);
                  final realIndex = _findMenuIndexByRoute(subOption.route);
                  if (realIndex != -1) {
                    _onItemSelected(realIndex);
                  }
                },
              ),
            );
          }).toList(),
      ],
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

class DashboardHome extends StatelessWidget {
  final AuthProvider authProvider;

  const DashboardHome({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // ✅ CORREGIDO: Imagen completa en dashboard
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/suchance.png', // ✅ Cambiado a .png
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: _getRoleColor(authProvider.userRol),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido, ${authProvider.user?.displayName ?? 'Usuario'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor(authProvider.userRol),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getRoleDisplayName(authProvider.userRol),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (authProvider.user?.username != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '@${authProvider.user!.username}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          if (authProvider.isAdmin) _buildAdminStats(),
          if (authProvider.isTecnico) _buildTecnicoStats(),
          if (authProvider.isBodega) _buildBodegaStats(),
          if (authProvider.isUsuario) _buildUsuarioStats(),
        ],
      ),
    );
  }

  Widget _buildAdminStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Panel de Administrador",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard("Usuarios", "12", Icons.people, Colors.blue),
            _buildStatCard("Artículos", "156", Icons.inventory_2, Colors.green),
            _buildStatCard("Categorías", "8", Icons.category, Colors.orange),
            _buildStatCard("Activos", "45", Icons.computer, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTecnicoStats() {
    return const Center(
      child: Text(
        "Panel de Técnico - Funcionalidades técnicas",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildBodegaStats() {
    return const Center(
      child: Text(
        "Panel de Bodega - Gestión de inventario",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildUsuarioStats() {
    return const Center(
      child: Text(
        "Panel de Usuario - Consulta y búsqueda",
        style: TextStyle(color: Colors.white, fontSize: 18),
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
        return 'ADMINISTRADOR';
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