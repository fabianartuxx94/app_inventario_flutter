import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_background.dart';
import '../services/api_service.dart';
import 'dashboard/dashboard_page.dart';
import '../widgets/responsive_layout.dart';

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
  final _formKey = GlobalKey<FormState>();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('username');
      final savedPassword = prefs.getString('password');
      final rememberMe = prefs.getBool('rememberMe') ?? false;

      if (mounted) {
        setState(() {
          if (savedUsername != null) _usernameController.text = savedUsername;
          if (savedPassword != null && rememberMe) _passwordController.text = savedPassword;
          _rememberMe = rememberMe;
        });
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode) {
          print('Error cargando credenciales: $e');
        }
      }
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('username', _usernameController.text.trim());
        await prefs.setString('password', _passwordController.text.trim());
        await prefs.setBool('rememberMe', true);
      } else {
        await prefs.remove('password');
        await prefs.setBool('rememberMe', false);
        await prefs.setString('username', _usernameController.text.trim());
      }
    } catch (e) {
      print('Error guardando credenciales: $e');
    }
  }

  Future<void> _clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.remove('rememberMe');
    } catch (e) {
      if (kDebugMode) {
        print('Error limpiando credenciales: $e');
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final loginResult = await ApiService.loginWithUserData(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (loginResult != null && loginResult['token'] != null) {
        await _saveCredentials();
        
        // ✅ CORREGIDO: Pasar todos los datos correctamente al AuthProvider
        Provider.of<AuthProvider>(context, listen: false).login(
          loginResult['token'],
          {
            'id': loginResult['id'],
            'username': loginResult['username'], // ✅ Ahora sí está incluido
            'nombre_completo': loginResult['nombre_completo'],
            'rol': loginResult['rol'],
          },
        );

        // ✅ DEBUG: Verificar que los datos se cargaron correctamente
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.printDebugInfo();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales inválidas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _handleKeyPress,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              const CustomBackground(),
              ResponsiveLayout(
                mobileBody: Center(child: _buildLoginForm(context, 350)),
                desktopBody: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/suchance.png',
                              width: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported,
                                      size: 100, color: Colors.white70),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              "Bienvenido a InventarioApp",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Gestiona tu inventario de forma simple y eficiente.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildLoginForm(context, 400),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, double formWidth) {
    return Container(
      width: formWidth,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
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
      child: Form(
        key: _formKey,
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su usuario';
                }
                return null;
              },
              onFieldSubmitted: (value) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
            ),
            const SizedBox(height: 20),
            _buildInput(
              Icons.lock_outline,
              "Contraseña",
              _passwordController,
              obscure: true,
              focusNode: _passwordFocusNode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su contraseña';
                }
                return null;
              },
              onFieldSubmitted: (value) => _login(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) {
                        setState(() => _rememberMe = v!);
                        if (!v!) {
                          _clearCredentials();
                        }
                      },
                      side: const BorderSide(color: Colors.white70),
                      checkColor: Colors.white,
                      fillColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.blue;
                          }
                          return Colors.transparent;
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _rememberMe = !_rememberMe);
                        if (!_rememberMe) {
                          _clearCredentials();
                        }
                      },
                      child: Text(
                        "Recordarme",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text(
                        "Ingresar",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            if (_rememberMe && _usernameController.text.isNotEmpty)
              Text(
                "Credenciales guardadas",
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
          ],
        ),
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
    FocusNode? focusNode,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
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
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        errorStyle: const TextStyle(color: Colors.red),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}