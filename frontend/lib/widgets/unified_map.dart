import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:frontend/models/sitio_venta_model.dart';
import 'package:frontend/config/config.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MapStyles {
  static const Map<String, String> styles = {
    'Claro': 'mapbox/light-v11',
    'Calles': 'mapbox/streets-v12',
    'Satélite': 'mapbox/satellite-v9',
    'Satélite + Calles': 'mapbox/satellite-streets-v12',
    'Oscuro': 'mapbox/dark-v11',
    'Exterior': 'mapbox/outdoors-v12',
    'Navegación Día': 'mapbox/navigation-day-v1',
    'Navegación Noche': 'mapbox/navigation-night-v1',
  };
}

class UnifiedMap extends StatefulWidget {
  final List<SitioVenta> sitios;
  final Function(SitioVenta) onSitioTapped;
  final latlong.LatLng? initialCenter;
  final double? initialZoom;
  final bool showUserLocation;
  final latlong.LatLng? userLocation;
  final VoidCallback? onMapCreated;
  final String initialStyle;

  const UnifiedMap({
    super.key,
    required this.sitios,
    required this.onSitioTapped,
    this.initialCenter,
    this.initialZoom = 8.0,
    this.showUserLocation = false,
    this.userLocation,
    this.onMapCreated,
    this.initialStyle = 'mapbox/light-v11',
  });

  @override
  State<UnifiedMap> createState() => UnifiedMapState();
}

class UnifiedMapState extends State<UnifiedMap> {
  late dynamic _mapController;
  String _currentStyle = 'mapbox/light-v11';
  double _currentZoom = 8.0;

  @override
  void initState() {
    super.initState();
    _currentStyle = widget.initialStyle;
    _currentZoom = widget.initialZoom ?? 8.0;
    _initializeMap();
    widget.onMapCreated?.call();
  }

  void _initializeMap() {
    try {
      if (kIsWeb) {
        _mapController = _WebMapController(
          onZoomChanged: (zoom) {
            setState(() {
              _currentZoom = zoom;
            });
          },
        );
      } else {
        _mapController = _MobileMapController(
          onZoomChanged: (zoom) {
            setState(() {
              _currentZoom = zoom;
            });
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing map: $e');
      }
      _mapController = _WebMapController(
        onZoomChanged: (zoom) {
          setState(() {
            _currentZoom = zoom;
          });
        },
      );
    }
  }

  // Método para cambiar estilo del mapa
  void changeMapStyle(String style) {
    setState(() {
      _currentStyle = style;
    });
  }

  // Obtener estilo actual
  String get currentStyle => _currentStyle;

  // Obtener zoom actual
  double get currentZoom => _currentZoom;

  // Métodos públicos para controlar el mapa
  void centerMap(double lat, double lng, {double zoom = 14.0}) {
    try {
      _mapController.centerMap(lat, lng, zoom: zoom);
      setState(() {
        _currentZoom = zoom;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error centering map: $e');
      }
    }
  }

  void fitBounds(List<latlong.LatLng> points) {
    try {
      _mapController.fitBounds(points);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fitting bounds: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _mapController.build(
        sitios: widget.sitios,
        onSitioTapped: widget.onSitioTapped,
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        showUserLocation: widget.showUserLocation,
        userLocation: widget.userLocation,
        mapStyle: _currentStyle,
        currentZoom: _currentZoom,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error building map: $e');
      }
      return _buildErrorFallback();
    }
  }

  Widget _buildErrorFallback() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'Error cargando el mapa',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.sitios.length} sitios disponibles',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _mapController.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disposing map controller: $e');
      }
    }
    super.dispose();
  }
}

// TileProvider personalizado con caché
class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CachedNetworkImageProvider(url);
  }
}

// Controlador para Web usando flutter_map
class _WebMapController {
  late MapController _mapController;
  final Function(double)? onZoomChanged;

  _WebMapController({this.onZoomChanged}) {
    _mapController = MapController();
  }

  Widget build({
    required List<SitioVenta> sitios,
    required Function(SitioVenta) onSitioTapped,
    latlong.LatLng? initialCenter,
    double? initialZoom,
    bool showUserLocation = false,
    latlong.LatLng? userLocation,
    required String mapStyle,
    required double currentZoom,
  }) {
    final mapboxToken = AppConfig.tokenMap;
    
    if (kDebugMode) {
      print('🗺️ Using Mapbox token: ${mapboxToken.substring(0, 20)}...');
      print('🗺️ Using map style: $mapStyle');
      print('🗺️ Current zoom: $currentZoom');
    }
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter ?? const latlong.LatLng(2.813, -75.462),
        initialZoom: initialZoom ?? 8.0,
        maxZoom: 19.0,
        minZoom: 7.0,
        onPositionChanged: (position, hasGesture) {
          if (onZoomChanged != null) {
            onZoomChanged!(position.zoom);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/$mapStyle/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
          userAgentPackageName: 'com.example.frontend',
          tileProvider: CachedTileProvider(),
        ),
        MarkerLayer(
          markers: _buildMarkers(sitios, onSitioTapped, currentZoom),
        ),
        if (showUserLocation && userLocation != null) 
          _buildUserLocationMarker(userLocation),
      ],
    );
  }

  List<Marker> _buildMarkers(List<SitioVenta> sitios, Function(SitioVenta) onSitioTapped, double currentZoom) {
    return sitios.where((sitio) => sitio.latitud != null && sitio.longitud != null).map((sitio) {
      return Marker(
        point: latlong.LatLng(
          sitio.latitud!.toDouble(),
          sitio.longitud!.toDouble(),
        ),
        width: _getMarkerSize(currentZoom),
        height: _getMarkerSize(currentZoom),
        child: GestureDetector(
          onTap: () => onSitioTapped(sitio),
          child: _buildCustomMarker(sitio, currentZoom),
        ),
      );
    }).toList();
  }

  double _getMarkerSize(double zoom) {
    if (zoom >= 16.0) {
      return 45.0;
    } else if (zoom >= 14.0) {
      return 40.0;
    } else if (zoom >= 12.0) {
      return 35.0;
    } else if (zoom >= 10.0) {
      return 30.0;
    } else if (zoom >= 8.0) {
      return 25.0;
    } else {
      return 20.0;
    }
  }

  Widget _buildCustomMarker(SitioVenta sitio, double currentZoom) {
    final iconPath = _getIconPathForTipo(sitio.tipoSv);
    final markerSize = _getMarkerSize(currentZoom);
    
    return Container(
      child: Stack(
        children: [
          Center(
            child: Image.asset(
              iconPath,
              width: markerSize * 1.0,
              height: markerSize * 1.0,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: markerSize * 0.9,
                  height: markerSize * 0.9,
                  decoration: BoxDecoration(
                    color: _getColorForEstado(sitio.estadoSv),
                    borderRadius: BorderRadius.circular(markerSize * 0.5),
                  ),
                  child: Icon(
                    _getIconForTipo(sitio.tipoSv),
                    color: Colors.white,
                    size: markerSize * 0.5,
                  ),
                );
              },
            ),
          ),
          if (currentZoom >= 12.0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Text(
                  sitio.codigoSv,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: markerSize * 0.12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getIconPathForTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'punto fijo':
        return 'assets/icons/punto_fijo.png';
      case 'tienda a tienda':
        return 'assets/icons/tienda_a_tienda.png';
      default:
        return 'assets/icons/punto_fijo.png';
    }
  }

  Color _getColorForEstado(String estado) {
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

  IconData _getIconForTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'tienda':
        return Icons.store;
      case 'supermercado':
        return Icons.shopping_cart;
      case 'restaurante':
        return Icons.restaurant;
      default:
        return Icons.place;
    }
  }

  MarkerLayer _buildUserLocationMarker(latlong.LatLng userLocation) {
    return MarkerLayer(
      markers: [
        Marker(
          point: userLocation,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person_pin_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void centerMap(double lat, double lng, {double zoom = 14.0}) {
    _mapController.move(latlong.LatLng(lat, lng), zoom);
  }

  void fitBounds(List<latlong.LatLng> points) {
    if (points.length >= 2) {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (var point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      final center = latlong.LatLng(
        (minLat + maxLat) / 2,
        (minLng + maxLng) / 2,
      );
      
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      final zoomLevel = 12.0 - (maxDiff * 10);
      
      _mapController.move(center, zoomLevel.clamp(8.0, 16.0));
    }
  }

  void dispose() {
    _mapController.dispose();
  }
}

// Controlador para Móvil
class _MobileMapController {
  late MapController _mapController;
  final Function(double)? onZoomChanged;

  _MobileMapController({this.onZoomChanged}) {
    _mapController = MapController();
  }

  Widget build({
    required List<SitioVenta> sitios,
    required Function(SitioVenta) onSitioTapped,
    latlong.LatLng? initialCenter,
    double? initialZoom,
    bool showUserLocation = false,
    latlong.LatLng? userLocation,
    required String mapStyle,
    required double currentZoom,
  }) {
    final mapboxToken = AppConfig.tokenMap;
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter ?? const latlong.LatLng(2.625, -75.612),
        initialZoom: initialZoom ?? 8.0,
        maxZoom: 19.0,
        minZoom: 7.0,
        onPositionChanged: (position, hasGesture) {
          if (onZoomChanged != null) {
            onZoomChanged!(position.zoom);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/$mapStyle/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
          userAgentPackageName: 'com.example.frontend',
          tileProvider: CachedTileProvider(),
        ),
        MarkerLayer(
          markers: _buildMarkers(sitios, onSitioTapped, currentZoom),
        ),
        if (showUserLocation && userLocation != null) 
          _buildUserLocationMarker(userLocation),
      ],
    );
  }

  List<Marker> _buildMarkers(List<SitioVenta> sitios, Function(SitioVenta) onSitioTapped, double currentZoom) {
    return sitios.where((sitio) => sitio.latitud != null && sitio.longitud != null).map((sitio) {
      return Marker(
        point: latlong.LatLng(
          sitio.latitud!.toDouble(),
          sitio.longitud!.toDouble(),
        ),
        width: _getMarkerSize(currentZoom),
        height: _getMarkerSize(currentZoom),
        child: GestureDetector(
          onTap: () => onSitioTapped(sitio),
          child: _buildCustomMarker(sitio, currentZoom),
        ),
      );
    }).toList();
  }

  double _getMarkerSize(double zoom) {
    if (zoom >= 16.0) {
      return 45.0;
    } else if (zoom >= 14.0) {
      return 40.0;
    } else if (zoom >= 12.0) {
      return 35.0;
    } else if (zoom >= 10.0) {
      return 30.0;
    } else if (zoom >= 8.0) {
      return 25.0;
    } else {
      return 20.0;
    }
  }

  Widget _buildCustomMarker(SitioVenta sitio, double currentZoom) {
    final iconPath = _getIconPathForTipo(sitio.tipoSv);
    final markerSize = _getMarkerSize(currentZoom);
    
    return Container(
      child: Stack(
        children: [
          Center(
            child: Image.asset(
              iconPath,
              width: markerSize * 1.0,
              height: markerSize * 1.0,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: markerSize * 0.9,
                  height: markerSize * 0.9,
                  decoration: BoxDecoration(
                    color: _getColorForEstado(sitio.estadoSv),
                    borderRadius: BorderRadius.circular(markerSize * 0.5),
                  ),
                  child: Icon(
                    _getIconForTipo(sitio.tipoSv),
                    color: Colors.white,
                    size: markerSize * 0.5,
                  ),
                );
              },
            ),
          ),
          if (currentZoom >= 12.0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Text(
                  sitio.codigoSv,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: markerSize * 0.12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getIconPathForTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'punto fijo':
        return 'assets/icons/punto_fijo.png';
      case 'tienda a tienda':
        return 'assets/icons/tienda_a_tienda.png';
      default:
        return 'assets/icons/punto_fijo.png';
    }
  }

  Color _getColorForEstado(String estado) {
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

  IconData _getIconForTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'tienda':
        return Icons.store;
      case 'supermercado':
        return Icons.shopping_cart;
      case 'restaurante':
        return Icons.restaurant;
      default:
        return Icons.place;
    }
  }

  MarkerLayer _buildUserLocationMarker(latlong.LatLng userLocation) {
    return MarkerLayer(
      markers: [
        Marker(
          point: userLocation,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person_pin_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void centerMap(double lat, double lng, {double zoom = 14.0}) {
    _mapController.move(latlong.LatLng(lat, lng), zoom);
  }

  void fitBounds(List<latlong.LatLng> points) {
    if (points.length >= 2) {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (var point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      final center = latlong.LatLng(
        (minLat + maxLat) / 2,
        (minLng + maxLng) / 2,
      );
      
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      final zoomLevel = 12.0 - (maxDiff * 10);
      
      _mapController.move(center, zoomLevel.clamp(8.0, 16.0));
    }
  }

  void dispose() {
    _mapController.dispose();
  }
}