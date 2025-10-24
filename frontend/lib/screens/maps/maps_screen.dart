import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/maps/detalles_sitio_card.dart';
import 'package:frontend/services/map_service.dart';
import 'package:frontend/models/sitio_venta_model.dart';
import 'package:frontend/widgets/custom_background.dart';
import 'package:frontend/widgets/unified_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';

class MapaSitiosScreen extends StatefulWidget {
  const MapaSitiosScreen({super.key});

  @override
  State<MapaSitiosScreen> createState() => _MapaSitiosScreenState();
}

class _MapaSitiosScreenState extends State<MapaSitiosScreen> {
  List<SitioVenta> sitios = [];
  List<SitioVenta> sitiosFiltrados = [];
  bool isLoading = true;
  String errorMessage = '';
  String filtroCiudad = 'Todas';
  String filtroTipo = 'Todos';
  String filtroBusqueda = '';
  Set<String> ciudades = {'Todas'};
  Set<String> tiposSv = {'Todos'};

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SitioVenta> _sugerencias = [];

  // ✅ CORREGIDO: Usar GlobalKey con el tipo correcto
  final GlobalKey<UnifiedMapState> _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarSitiosVenta();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _cargarSitiosVenta() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final resultado = await MapService.obtenerSitiosVentaMapa(
      authProvider: authProvider,
      soloConCoordenadas: true,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
      if (resultado['success'] == true) {
        sitios = (resultado['sitios'] as List)
            .map((item) => SitioVenta.fromJson(item))
            .toList();
        sitiosFiltrados = List.from(sitios);

        ciudades = {'Todas'};
        tiposSv = {'Todos'};
        for (var sitio in sitios) {
          ciudades.add(sitio.ciudad);
          tiposSv.add(sitio.tipoSv);
        }
      } else {
        errorMessage = resultado['error'] ?? 'Error desconocido';
      }
    });
  }

  void _aplicarFiltros() async {
    setState(() {
      sitiosFiltrados = sitios.where((sitio) {
        final cumpleCiudad =
            filtroCiudad == 'Todas' || sitio.ciudad == filtroCiudad;
        final cumpleTipo =
            filtroTipo == 'Todos' || sitio.tipoSv == filtroTipo;
        final cumpleBusqueda = filtroBusqueda.isEmpty ||
            sitio.sitioVenta.toLowerCase().contains(filtroBusqueda.toLowerCase()) ||
            sitio.codigoSv.toLowerCase().contains(filtroBusqueda.toLowerCase());
        return cumpleCiudad && cumpleTipo && cumpleBusqueda;
      }).toList();
    });

    // Centrar el mapa en los sitios filtrados
    _centrarMapaEnSitios();
  }

  void _buscarSitios(String query) {
    setState(() {
      filtroBusqueda = query;
      
      if (query.isNotEmpty) {
        _sugerencias = sitios.where((sitio) {
          final nombreMatches = sitio.sitioVenta.toLowerCase().contains(query.toLowerCase());
          final codigoMatches = sitio.codigoSv.toLowerCase().contains(query.toLowerCase());
          final ciudadMatches = sitio.ciudad.toLowerCase().contains(query.toLowerCase());
          
          return nombreMatches || codigoMatches || ciudadMatches;
        }).toList();
        
        if (_sugerencias.length > 5) {
          _sugerencias = _sugerencias.sublist(0, 5);
        }
      } else {
        _sugerencias.clear();
      }
    });
    
    _aplicarFiltros();
  }

  void _seleccionarSugerencia(SitioVenta sitio) {
    _searchController.text = sitio.sitioVenta;
    _searchFocusNode.unfocus();
    setState(() {
      _sugerencias.clear();
      filtroBusqueda = sitio.sitioVenta;
    });
    _aplicarFiltros();
    _centrarMapaEnSitio(sitio);
  }

  Future<void> _centrarMapaEnSitio(SitioVenta sitio) async {
    if (sitio.latitud != null && sitio.longitud != null && _mapKey.currentState != null) {
      _mapKey.currentState!.centerMap(
        sitio.latitud!.toDouble(),
        sitio.longitud!.toDouble(),
        zoom: 14.0,
      );
    }
  }

  Future<void> _centrarMapaEnSitios() async {
    if (!mounted) return;
    
    final coords = sitiosFiltrados
        .where((s) => s.latitud != null && s.longitud != null)
        .map((s) => latlong.LatLng(
              s.latitud!.toDouble(),
              s.longitud!.toDouble(),
            ))
        .toList();

    if (coords.isNotEmpty && _mapKey.currentState != null) {
      _mapKey.currentState!.fitBounds(coords);
    }
  }

  void _mostrarDetallesSitio(SitioVenta sitio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DetallesSitioCard(
        sitio: sitio,
        onActualizarUbicacion: () => _actualizarUbicacion(sitio),
        onCerrar: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _actualizarUbicacion(SitioVenta sitio) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Actualizar ubicación para ${sitio.sitioVenta}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CustomBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                _buildFiltros(),
                Expanded(child: _buildMapa()),
              ],
            ),
          ),
          if (isLoading) _buildLoadingIndicator(),
          if (errorMessage.isNotEmpty) _buildErrorWidget(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF001F5E).withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _buscarSitios,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar por sitio, código o ciudad...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                                  onPressed: () {
                                    _searchController.clear();
                                    _buscarSitios('');
                                    _searchFocusNode.unfocus();
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Chip(
                label: Text(
                  '${sitiosFiltrados.length} sitios',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.blue,
              ),
            ],
          ),
          
          if (_sugerencias.isNotEmpty && _searchFocusNode.hasFocus)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF001F5E).withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: _sugerencias.map((sitio) {
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _obtenerColorContainerEstado(sitio.estadoSv).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _obtenerIconoEstado(sitio.estadoSv),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      sitio.sitioVenta,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${sitio.codigoSv} • ${sitio.ciudad}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(
                      Icons.place,
                      color: Colors.white.withOpacity(0.7),
                      size: 18,
                    ),
                    onTap: () => _seleccionarSugerencia(sitio),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: const Color(0xFF001F5E).withOpacity(0.8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: filtroCiudad,
              dropdownColor: const Color(0xFF001F5E),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Ciudad',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ciudades.map((ciudad) {
                return DropdownMenuItem(
                  value: ciudad,
                  child: Text(
                    ciudad,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  filtroCiudad = value!;
                  _aplicarFiltros();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: filtroTipo,
              dropdownColor: const Color(0xFF001F5E),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Tipo SV',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: tiposSv.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(
                    tipo,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  filtroTipo = value!;
                  _aplicarFiltros();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    return UnifiedMap(
      key: _mapKey,
      sitios: sitiosFiltrados,
      onSitioTapped: _mostrarDetallesSitio,
      initialCenter: const latlong.LatLng(2.830, -75.612),
      initialZoom: 7.0,
      onMapCreated: () {
        // El mapa se ha creado, centrar en los sitios
        if (sitiosFiltrados.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centrarMapaEnSitios();
          });
        }
      },
    );
  }

  Color _obtenerColorContainerEstado(String estado) {
    switch (estado) {
      case 'Activo':
        return Colors.green;
      case 'Mantenimiento':
        return Colors.orange;
      case 'Inactivo':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _obtenerIconoEstado(String estado) {
    switch (estado) {
      case 'Activo':
        return Icons.check_circle;
      case 'Mantenimiento':
        return Icons.build;
      case 'Inactivo':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 50),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarSitiosVenta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}