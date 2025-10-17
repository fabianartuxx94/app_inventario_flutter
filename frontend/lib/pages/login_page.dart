import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_background.dart';
import '../services/api_service.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);

    // 👇 Llamamos al servicio y guardamos el token devuelto
    final token = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _loading = false);

    // 👇 Verificamos si el widget sigue montado antes de usar context
    if (!mounted) return;

    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage(token: token)),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Credenciales inválidas')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CustomBackground(),
          Center(
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white70),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 3),
                  Text(
                    "Login",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInput(
                    Icons.person_outline,
                    "Usuario",
                    _usernameController,
                  ),
                  const SizedBox(height: 20),
                  _buildInput(
                    Icons.lock_outline,
                    "Contraseña",
                    _passwordController,
                    obscure: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v!),
                            side: const BorderSide(color: Colors.white70),
                          ),
                          const Text(
                            "Recordarme",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Ingresar",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildLogo() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Image.asset(
        'assets/suchance.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.2),
            child: const Icon(
              Icons.business_center,
              color: Colors.white,
              size: 30,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput(
    IconData icon,
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
