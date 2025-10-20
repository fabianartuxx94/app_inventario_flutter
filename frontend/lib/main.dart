import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard/dashboard_page.dart';
import 'package:frontend/widgets/InactivityListener.dart';
import 'package:provider/provider.dart';
import 'screens/login_page.dart';
import 'providers/auth_provider.dart';
import 'utils/globals.dart';

void main() {
  // ⭐ SOLUCIÓN: Configuración para Flutter Web
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const InventarioApp(),
    ),
  );
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      
      // ⭐ SOLUCIÓN: Configuración para errores de Flutter Web
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
          ),
          child: child!,
        );
      },
      
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 9, 17, 136),
        ),
        useMaterial3: true, // ⭐ Agregar esto
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return FutureBuilder(
            future: authProvider.loadStoredToken(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (authProvider.isTokenValid) {
                return InactivityListener(
                  child: const DashboardPage(),
                );
              } else {
                return const LoginPage();
              }
            },
          );
        },
      ),
    );
  }
}