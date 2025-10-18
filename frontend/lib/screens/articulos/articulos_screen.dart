import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/articulo_model.dart';
import '../../services/articulos_service.dart';
import '../../widgets/articulo_card.dart';
import 'crear_articulo_screen.dart';
import 'editar_articulo_screen.dart';
import '../../widgets/custom_background.dart';
import '../../providers/auth_provider.dart';

class ArticulosScreen extends StatefulWidget {
  const ArticulosScreen({super.key});
  

  @override
  State<ArticulosScreen> createState() => _ArticulosScreenState();
}

class _ArticulosScreenState extends State<ArticulosScreen> {
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
        backgroundColor: const Color(0xFF001F5E),
        title: const Text('Confirmar eliminación',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de eliminar ${articulo.marcaNombre} ${articulo.referencia}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        final token = Provider.of<AuthProvider>(context, listen: false).token!;
        final resultado = await ArticuloService.eliminarArticulo(
          articulo.articuloId!, 
          token
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
      } catch (e) {
        _mostrarError('Error al eliminar artículo: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Ajuste responsive del número de columnas
    int crossAxisCount = 1;
    if (screenWidth >= 1200) {
      crossAxisCount = 4;
    } else if (screenWidth >= 900) {
      crossAxisCount = 3;
    } else if (screenWidth >= 600) {
      crossAxisCount = 2;
    }

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
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          const CustomBackground(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Header con estadísticas
                _buildHeader(),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _articulos.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay artículos disponibles',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 0.8,
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
                                            EditarArticuloScreen(
                                                articulo: articulo),
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalArticulos = _articulos.length;
    final activosFijos = _articulos.where((a) => a.tipoArticulo == 'Activo Fijo').length;
    final activosControl = _articulos.where((a) => a.tipoArticulo == 'Activo de Control').length;
    final consumibles = _articulos.where((a) => a.tipoArticulo == 'Consumible').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gestión de Artículos",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        // Estadísticas rápidas
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatCard('Total', totalArticulos.toString(), Colors.blue),
              const SizedBox(width: 10),
              _buildStatCard('Activos Fijos', activosFijos.toString(), Colors.green),
              const SizedBox(width: 10),
              _buildStatCard('Activos Control', activosControl.toString(), Colors.orange),
              const SizedBox(width: 10),
              _buildStatCard('Consumibles', consumibles.toString(), Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}