import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:frontend/models/sitio_venta_model.dart';
import 'package:frontend/config/config.dart';
import 'package:latlong2/latlong.dart' as latlong;

// Import para web
import 'package:flutter_map/flutter_map.dart';

class UnifiedMap extends StatefulWidget {
  final List<SitioVenta> sitios;
  final Function(SitioVenta) onSitioTapped;
  final latlong.LatLng? initialCenter;
  final double? initialZoom;
  final bool showUserLocation;
  final VoidCallback? onMapCreated;



  const UnifiedMap({
    super.key,
    required this.sitios,
    required this.onSitioTapped,
    this.initialCenter,
    this.initialZoom = 6.0,
    this.showUserLocation = false,
    this.onMapCreated,
  });

  @override
  State<UnifiedMap> createState() => UnifiedMapState();
}
  // En tu unified_map.dart - método para cambiar estilos
class MapStyles {
  static const String streets = 'mapbox/streets-v12';
  static const String outdoors = 'mapbox/outdoors-v12';
  static const String light = 'mapbox/light-v11';
  static const String dark = 'mapbox/dark-v11';
  static const String satellite = 'mapbox/satellite-v9';
  static const String satelliteStreets = 'mapbox/satellite-streets-v12';
  static const String navigationDay = 'mapbox/navigation-day-v1';
  static const String navigationNight = 'mapbox/navigation-night-v1';
}

class UnifiedMapState extends State<UnifiedMap> {
  late dynamic _mapController;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    widget.onMapCreated?.call();
  }

  void _initializeMap() {
    try {
      if (kIsWeb) {
        _mapController = _WebMapController();
      } else {
        _mapController = _MobileMapController();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing map: $e');
      }
      // Fallback to web controller
      _mapController = _WebMapController();
    }
  }

  // Métodos públicos para controlar el mapa
  void centerMap(double lat, double lng, {double zoom = 14.0}) {
    try {
      _mapController.centerMap(lat, lng, zoom: zoom);
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

// Controlador para Web usando flutter_map
class _WebMapController {
  late MapController _mapController;

  _WebMapController() {
    _mapController = MapController();
  }

  Widget build({
    required List<SitioVenta> sitios,
    required Function(SitioVenta) onSitioTapped,
    latlong.LatLng? initialCenter,
    double? initialZoom,
    bool showUserLocation = false,
  }) {
    final mapboxToken = AppConfig.tokenMap;
    
    if (kDebugMode) {
      print('🗺️ Using Mapbox token: ${mapboxToken.substring(0, 20)}...');
    }
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter ?? const latlong.LatLng(1.625, -75.612),
        initialZoom: initialZoom ?? 6.0,
        maxZoom: 18.0,
        minZoom: 3.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
          userAgentPackageName: 'com.example.frontend',
        ),
        MarkerLayer(
          markers: _buildMarkers(sitios, onSitioTapped),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(List<SitioVenta> sitios, Function(SitioVenta) onSitioTapped) {
    return sitios.where((sitio) => sitio.latitud != null && sitio.longitud != null).map((sitio) {
      return Marker(
        point: latlong.LatLng(
          sitio.latitud!.toDouble(),
          sitio.longitud!.toDouble(),
        ),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => onSitioTapped(sitio),
          child: Container(
            decoration: BoxDecoration(
              color: _getColorForEstado(sitio.estadoSv),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                sitio.codigoSv,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
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

  void centerMap(double lat, double lng, {double zoom = 14.0}) {
    _mapController.move(latlong.LatLng(lat, lng), zoom);
  }

  void fitBounds(List<latlong.LatLng> points) {
    if (points.length >= 2) {
      // Para flutter_map 8.x, necesitamos calcular los bounds manualmente
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
      
      // Calcular zoom aproximado basado en la extensión
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

// Controlador para Móvil - Usando flutter_map temporalmente
class _MobileMapController {
  late MapController _mapController;

  _MobileMapController() {
    _mapController = MapController();
  }

  Widget build({
    required List<SitioVenta> sitios,
    required Function(SitioVenta) onSitioTapped,
    latlong.LatLng? initialCenter,
    double? initialZoom,
    bool showUserLocation = false,
  }) {
    final mapboxToken = AppConfig.tokenMap;
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter ?? const latlong.LatLng(1.625, -75.612),
        initialZoom: initialZoom ?? 6.0,
        maxZoom: 18.0,
        minZoom: 3.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
          userAgentPackageName: 'com.example.frontend',
        ),
        MarkerLayer(
          markers: _buildMarkers(sitios, onSitioTapped),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(List<SitioVenta> sitios, Function(SitioVenta) onSitioTapped) {
    return sitios.where((sitio) => sitio.latitud != null && sitio.longitud != null).map((sitio) {
      return Marker(
        point: latlong.LatLng(
          sitio.latitud!.toDouble(),
          sitio.longitud!.toDouble(),
        ),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => onSitioTapped(sitio),
          child: Container(
            decoration: BoxDecoration(
              color: _getColorForEstado(sitio.estadoSv),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                sitio.codigoSv,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
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

  void centerMap(double lat, double lng, {double zoom = 14.0}) {
    _mapController.move(latlong.LatLng(lat, lng), zoom);
  }

  void fitBounds(List<latlong.LatLng> points) {
    if (points.length >= 2) {
      // Para flutter_map 8.x, necesitamos calcular los bounds manualmente
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
      
      // Calcular zoom aproximado basado en la extensión
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