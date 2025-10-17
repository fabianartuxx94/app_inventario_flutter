import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/articulo_model.dart';
import '../../services/articulo_service.dart';
import '../../widgets/articulo_card.dart';
import 'crear_articulo_screen.dart';
import 'editar_articulo_screen.dart';
import '../../widgets/custom_background.dart';
import '../../providers/auth_provider.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  List<Articulo> _articulos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarArticulos();
  }

  Future<void> _cargarArticulos() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final articulos = await ArticuloService.obtenerArticulos(token);
      setState(() {
        _articulos = articulos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar artículos: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  Future<void> _eliminarArticulo(Articulo articulo) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar ${articulo.nombreArticulo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final resultado =
          await ArticuloService.eliminarArticulo(articulo.idCatalogo, token);

      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message']!),
            backgroundColor: Colors.green,
          ),
        );
        _cargarArticulos();
      } else {
        _mostrarError(resultado['error']!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearArticuloScreen(),
            ),
          );
          _cargarArticulos();
        },
        backgroundColor: const Color(0xFF0948d6),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          const CustomBackground(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _articulos.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay artículos disponibles',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _articulos.length,
                        itemBuilder: (context, index) {
                          final articulo = _articulos[index];
                          return ArticuloCard(
                            articulo: articulo,
                            onEdit: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditarArticuloScreen(articulo: articulo),
                                ),
                              );
                              _cargarArticulos();
                            },
                            onDelete: () => _eliminarArticulo(articulo),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
