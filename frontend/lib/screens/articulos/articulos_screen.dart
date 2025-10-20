import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/articulo_model.dart';
import '../../services/articulos_service.dart';
import '../../widgets/articulo_card.dart';
import '../../widgets/custom_background.dart';
import '../../providers/auth_provider.dart';

// Pantalla principal para gestionar los artículos
class ArticulosScreen extends StatefulWidget {
  final VoidCallback? onCrearArticulo;
  final Function(dynamic)? onEditarArticulo;

  const ArticulosScreen({
    super.key,
    this.onCrearArticulo,
    this.onEditarArticulo,
  });

  @override
  State<ArticulosScreen> createState() => _ArticulosScreenState();
}

class _ArticulosScreenState extends State<ArticulosScreen> {
  List<Articulo> _articulos = [];
  List<Articulo> _filteredArticulos = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _filterTipoArticulo = 'Todos';

  Articulo? _articuloSeleccionadoZoom;
  bool _mostrarZoom = false;

  @override
  void initState() {
    super.initState();
    _cargarArticulos();
  }

  // Obtiene los artículos desde el servicio y los guarda en el estado
  Future<void> _cargarArticulos() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final articulos = await ArticuloService.obtenerArticulos(token);
      setState(() {
        _articulos = articulos;
        _filteredArticulos = articulos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar artículos: $e');
    }
  }

  // Muestra un mensaje de error en la pantalla
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  // Muestra diálogo de confirmación y elimina el artículo si se aprueba
  Future<void> _eliminarArticulo(Articulo articulo) async {
    if (articulo.articuloId == null) {
      _mostrarError('No se puede eliminar el artículo: ID no disponible');
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar ${articulo.marcaNombre} ${articulo.referencia}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        final token = Provider.of<AuthProvider>(context, listen: false).token;

        if (token == null) {
          _mostrarError('Error de autenticación. Por favor, inicie sesión nuevamente.');
          return;
        }

        final resultado = await ArticuloService.eliminarArticulo(articulo.articuloId!, token);

        if (resultado['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['message'] ?? 'Artículo eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarArticulos();
        } else {
          _mostrarError(resultado['error'] ?? 'Error al eliminar artículo');
        }
      } catch (e) {
        _mostrarError('Error al eliminar artículo: $e');
      }
    }
  }

  // Filtra los artículos según tipo y término de búsqueda
  void _filterArticulos() {
    List<Articulo> tempList = _articulos;

    if (_filterTipoArticulo != 'Todos') {
      tempList = tempList.where((a) => a.tipoArticulo == _filterTipoArticulo).toList();
    }

    if (_searchTerm.isNotEmpty) {
      final lowerSearch = _searchTerm.toLowerCase();
      tempList = tempList.where((a) =>
        a.categoriaNombre.toLowerCase().contains(lowerSearch) ||
        a.marcaNombre.toLowerCase().contains(lowerSearch) ||
        a.referencia.toLowerCase().contains(lowerSearch)
      ).toList();
    }

    setState(() {
      _filteredArticulos = tempList;
    });
  }

  // Alterna el modo "zoom" para mostrar una tarjeta ampliada
  void _toggleZoomArticulo(Articulo? articulo) {
    setState(() {
      _mostrarZoom = articulo != null;
      _articuloSeleccionadoZoom = articulo;
    });
  }

  // Construye la interfaz principal
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 750;

    // Configuración responsiva del grid
    int crossAxisCount;
    double childAspectRatio;

    if (isMobile) {
      crossAxisCount = 2;
      childAspectRatio = 0.7;
    } else if (screenWidth >= 1200) {
      crossAxisCount = 4;
      childAspectRatio = 0.8;
    } else if (screenWidth >= 900) {
      crossAxisCount = 3;
      childAspectRatio = 0.75;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 0.7;
    }

    return Scaffold(
      floatingActionButton: (_mostrarZoom || widget.onCrearArticulo == null)
          ? null
          : FloatingActionButton(
              onPressed: widget.onCrearArticulo,
              backgroundColor: const Color(0xFF0948d6),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const CustomBackground(),
          Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 20),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 10),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _filteredArticulos.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay artículos disponibles',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            )
                          : GridView.builder(
                              padding: EdgeInsets.only(bottom: isMobile ? 70 : 80, top: 8),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: isMobile ? 12 : 16,
                                mainAxisSpacing: isMobile ? 12 : 16,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: _filteredArticulos.length,
                              itemBuilder: (context, index) {
                                final articulo = _filteredArticulos[index];
                                return ArticuloCard(
                                  articulo: articulo,
                                  isSelected: false,
                                  isZoomMode: false,
                                  onEdit: () => widget.onEditarArticulo?.call(articulo),
                                  onDelete: () => _eliminarArticulo(articulo),
                                  onSelect: () => _toggleZoomArticulo(articulo),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          if (_mostrarZoom && _articuloSeleccionadoZoom != null)
            _buildOverlayZoom(context),
        ],
      ),
    );
  }

  // Construye la tarjeta ampliada (modo zoom)
  Widget _buildOverlayZoom(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => _toggleZoomArticulo(null),
        child: Container(
          color: Colors.black54,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: SizedBox(
                width: isMobile
                    ? MediaQuery.of(context).size.width * 0.95
                    : MediaQuery.of(context).size.width * 0.6,
                height: isMobile
                    ? MediaQuery.of(context).size.height * 0.85
                    : MediaQuery.of(context).size.height * 0.9,
                child: Transform.scale(
                  scale: 0.8,
                  child: ArticuloCard(
                    articulo: _articuloSeleccionadoZoom!,
                    isSelected: true,
                    isZoomMode: true,
                    onEdit: () {
                      widget.onEditarArticulo?.call(_articuloSeleccionadoZoom!);
                      _toggleZoomArticulo(null);
                    },
                    onDelete: () {
                      _eliminarArticulo(_articuloSeleccionadoZoom!);
                      _toggleZoomArticulo(null);
                    },
                    onSelect: () => _toggleZoomArticulo(null),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Construye el encabezado con estadísticas
  Widget _buildHeader() {
    final total = _articulos.length;
    final fijos = _articulos.where((a) => a.tipoArticulo == 'Activo Fijo').length;
    final control = _articulos.where((a) => a.tipoArticulo == 'Activo de Control').length;
    final consumibles = _articulos.where((a) => a.tipoArticulo == 'Consumible').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Gestión de Artículos",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard('Todos', total.toString(), Colors.blue, 'Todos'),
              const SizedBox(width: 10),
              _buildStatCard('Activos Fijos', fijos.toString(), Colors.green, 'Activo Fijo'),
              const SizedBox(width: 10),
              _buildStatCard('Activos Control', control.toString(), Colors.orange, 'Activo de Control'),
              const SizedBox(width: 10),
              _buildStatCard('Consumibles', consumibles.toString(), Colors.red, 'Consumible'),
            ],
          ),
        ),
      ],
    );
  }

  // Construye una tarjeta para las estadísticas por tipo
  Widget _buildStatCard(String title, String value, Color color, String tipoFiltro) {
    final isSelected = _filterTipoArticulo == tipoFiltro;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterTipoArticulo = tipoFiltro;
          _filterArticulos();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.5) : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Barra de búsqueda para filtrar artículos
  Widget _buildSearchBar() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Buscar por categoría, marca o referencia',
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        filled: true,
        fillColor: const Color.fromARGB(111, 30, 41, 59),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      onChanged: (value) {
        setState(() {
          _searchTerm = value;
          _filterArticulos();
        });
      },
    );
  }
}
