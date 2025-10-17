import 'package:flutter/material.dart';
import '../../models/articulo_model.dart';
import '../../services/articulo_service.dart';
import '../../widgets/articulo_card.dart';
import 'crear_articulo_screen.dart';
import 'editar_articulo_screen.dart';
import '../../widgets/custom_background.dart';
import 'package:google_fonts/google_fonts.dart';

class CatalogoScreen extends StatefulWidget {
  final String token;

  const CatalogoScreen({super.key, required this.token});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  List<Articulo> _articulos = [];
  List<Articulo> _articulosFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarArticulos();
  }

  Future<void> _cargarArticulos() async {
    try {
      final articulos = await ArticuloService.obtenerArticulos(widget.token);
      setState(() {
        _articulos = articulos;
        _articulosFiltrados = articulos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar artículos: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
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
      final resultado = await ArticuloService.eliminarArticulo(
        articulo.idCatalogo, 
        widget.token
      );
      
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
    appBar: AppBar(
      title: Text(
        'Catálogo de Artículos',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF0948d6),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _cargarArticulos,
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CrearArticuloScreen(token: widget.token),
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

        // Contenido
        Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _articulosFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron artículos',
                            style: TextStyle(
                              color: Color(0xFFaca9bb),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75, // 🔧 Ajustado para evitar overflow
                          ),
                          itemCount: _articulosFiltrados.length,
                          itemBuilder: (context, index) {
                            final articulo = _articulosFiltrados[index];
                            return ArticuloCard(
                              articulo: articulo,
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditarArticuloScreen(
                                      articulo: articulo,
                                      token: widget.token,
                                    ),
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
      ],
    ),
  );
}
}