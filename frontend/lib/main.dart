import 'package:flutter/material.dart';
import 'screens/catalogo/catalogo_page.dart';
import 'screens/login_page.dart';
import 'screens/dashboard/dashboard_page.dart';


void main() {
  runApp(const InventarioApp());
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 9, 17, 136),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return DashboardPage(token: args);
        },
        '/catalogo': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return CatalogoPage(token: args);
        },
      },
    );
  }
}


