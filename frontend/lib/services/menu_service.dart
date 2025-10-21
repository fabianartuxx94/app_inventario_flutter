import 'package:flutter/material.dart';

class MenuOption {
  final String title;
  final String route;
  final IconData icon;
  final List<MenuOption>? submenu; // ✅ NUEVO: Para menús desplegables

  MenuOption({
    required this.title,
    required this.route,
    required this.icon,
    this.submenu,
  });
}

class MenuService {
  static List<MenuOption> getMenuOptions(String userRol) {
    switch (userRol) {
      case 'administrador':
        return _getAdminMenu();
      case 'tecnico':
        return _getTecnicoMenu();
      case 'bodega':
        return _getBodegaMenu();
      case 'usuario':
      default:
        return _getUsuarioMenu();
    }
  }

  // ✅ MENÚ PARA ADMINISTRADOR
  static List<MenuOption> _getAdminMenu() {
    return [
      MenuOption(
        title: 'Dashboard', 
        route: '/dashboard', 
        icon: Icons.dashboard
      ),
      MenuOption(
        title: 'Inventario',
        route: '/inventario',
        icon: Icons.inventory_2,
        submenu: [
          MenuOption(title: 'Categorías', route: '/categorias', icon: Icons.category),
          MenuOption(title: 'Artículos', route: '/articulos', icon: Icons.inventory),
          MenuOption(title: 'Activos', route: '/activos', icon: Icons.computer),
          MenuOption(title: 'Consumibles', route: '/consumibles', icon: Icons.local_offer),
        ],
      ),
      MenuOption(
        title: 'Movimientos', 
        route: '/movimientos', 
        icon: Icons.swap_horiz
      ),
      MenuOption(
        title: 'Sitios de Venta', 
        route: '/sitios-venta', 
        icon: Icons.store
      ),
      MenuOption(
        title: 'Usuarios', 
        route: '/usuarios', 
        icon: Icons.people
      ),
      MenuOption(
        title: 'Reportes', 
        route: '/reportes', 
        icon: Icons.analytics
      ),
      MenuOption(
        title: 'Configuración', 
        route: '/configuracion', 
        icon: Icons.settings
      ),
    ];
  }

  // ✅ MENÚ PARA USUARIO
  static List<MenuOption> _getUsuarioMenu() {
    return [
      MenuOption(
        title: 'Dashboard', 
        route: '/dashboard', 
        icon: Icons.dashboard
      ),
      MenuOption(
        title: 'Artículos', 
        route: '/articulos', 
        icon: Icons.inventory_2
      ),
      MenuOption(
        title: 'Reportes', 
        route: '/reportes', 
        icon: Icons.analytics
      ),
      MenuOption(
        title: 'Configuración', 
        route: '/configuracion', 
        icon: Icons.settings
      ),
    ];
  }

  // ✅ MENÚ PARA TÉCNICO
  static List<MenuOption> _getTecnicoMenu() {
    return [
      MenuOption(
        title: 'Dashboard', 
        route: '/dashboard', 
        icon: Icons.dashboard
      ),
      MenuOption(
        title: 'Ruteros', 
        route: '/ruteros', 
        icon: Icons.assignment
      ),
      MenuOption(
        title: 'Mantenimientos SV', 
        route: '/mantenimientos', 
        icon: Icons.build
      ),
      MenuOption(
        title: 'Ubicaciones', 
        route: '/ubicaciones', 
        icon: Icons.location_on
      ),
      MenuOption(
        title: 'Configuración', 
        route: '/configuracion', 
        icon: Icons.settings
      ),
    ];
  }

  // ✅ MENÚ PARA BODEGA
  static List<MenuOption> _getBodegaMenu() {
    return [
      MenuOption(
        title: 'Dashboard', 
        route: '/dashboard', 
        icon: Icons.dashboard
      ),
      MenuOption(
        title: 'Inventario',
        route: '/inventario',
        icon: Icons.inventory_2,
        submenu: [
          MenuOption(title: 'Artículos', route: '/articulos', icon: Icons.inventory),
          MenuOption(title: 'Activos', route: '/activos', icon: Icons.computer),
          MenuOption(title: 'Consumibles', route: '/consumibles', icon: Icons.local_offer),
        ],
      ),
      MenuOption(
        title: 'Movimientos', 
        route: '/movimientos', 
        icon: Icons.swap_horiz
      ),
      MenuOption(
        title: 'Asignaciones', 
        route: '/asignaciones', 
        icon: Icons.assignment_turned_in
      ),
      MenuOption(
        title: 'Entradas Compras', 
        route: '/entradas-compras', 
        icon: Icons.shopping_cart
      ),
      MenuOption(
        title: 'Configuración', 
        route: '/configuracion', 
        icon: Icons.settings
      ),
    ];
  }

  static String getWelcomeMessage(String userRol) {
    switch (userRol) {
      case 'administrador':
        return 'Panel de Administración Completo';
      case 'tecnico':
        return 'Panel de Control Técnico';
      case 'bodega':
        return 'Gestión de Bodega';
      case 'usuario':
        return 'Consulta de Inventario';
      default:
        return 'Bienvenido al Sistema';
    }
  }
}