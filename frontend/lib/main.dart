import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard/dashboard_page.dart';
import 'package:frontend/widgets/InactivityListener.dart';
import 'package:provider/provider.dart';
import 'screens/login_page.dart';
import 'providers/auth_provider.dart';
import 'utils/globals.dart';

void main() {
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
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return FutureBuilder(
            future: authProvider.loadStoredToken(),
            builder: (context, snapshot) {
              // Eliminamos la pantalla de carga
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
