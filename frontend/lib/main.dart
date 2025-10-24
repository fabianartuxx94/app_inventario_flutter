import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard/dashboard_scaffold.dart';
import 'package:frontend/widgets/InactivityListener.dart';
import 'package:provider/provider.dart';
import 'screens/login_page.dart';
import 'providers/auth_provider.dart';
import 'utils/globals.dart';
import 'services/map_initialization_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ Añadir import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ INICIALIZAR flutter_dotenv PRIMERO
  await dotenv.load(fileName: ".env");

  // ✅ Opcional: imprimir configuración para debug
  if (kDebugMode) {
    print('✅ .env cargado correctamente');
    print('✅ MAP_TOKEN disponible: ${dotenv.env['MAP_TOKEN'] != null}');
  }

  // Inicialización segura para web y móvil
  await MapInitializationService.initialize();

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
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
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
              if (authProvider.isTokenValid) {
                return InactivityListener(
                  child: const DashboardScaffold(),
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