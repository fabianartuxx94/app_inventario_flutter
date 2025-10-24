class SitioVenta {
  final int id;
  final String codigoSv;
  final String sitioVenta;
  final String direccion;
  final String ciudad;
  final String? barrio;
  final double? latitud;
  final double? longitud;
  final String tipoSv;
  final String estadoSv;
  final String? tecnologiasSv;
  final String mapboxIcon;
  final String mapboxColor;
  final bool tieneCoordenadas;

  SitioVenta({
    required this.id,
    required this.codigoSv,
    required this.sitioVenta,
    required this.direccion,
    required this.ciudad,
    this.barrio,
    this.latitud,
    this.longitud,
    required this.tipoSv,
    required this.estadoSv,
    this.tecnologiasSv,
    required this.mapboxIcon,
    required this.mapboxColor,
    required this.tieneCoordenadas,
  });

  factory SitioVenta.fromJson(Map<String, dynamic> json) {
    return SitioVenta(
      id: json['id'] ?? 0,
      codigoSv: json['codigo_sv'] ?? '',
      sitioVenta: json['sitio_venta'] ?? '',
      direccion: json['direccion'] ?? '',
      ciudad: json['ciudad'] ?? '',
      barrio: json['barrio'],
      latitud: json['latitud'] != null ? double.parse(json['latitud'].toString()) : null,
      longitud: json['longitud'] != null ? double.parse(json['longitud'].toString()) : null,
      tipoSv: json['tipo_sv'] ?? '',
      estadoSv: json['estado_sv'] ?? '',
      tecnologiasSv: json['tecnologias_sv'],
      mapboxIcon: json['mapbox_icon'] ?? 'warehouse',
      mapboxColor: json['mapbox_color'] ?? 'green',
      tieneCoordenadas: json['tiene_coordenadas'] == 1 || (json['latitud'] != null && json['longitud'] != null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_sv': codigoSv,
      'sitio_venta': sitioVenta,
      'direccion': direccion,
      'ciudad': ciudad,
      'barrio': barrio,
      'latitud': latitud,
      'longitud': longitud,
      'tipo_sv': tipoSv,
      'estado_sv': estadoSv,
      'tecnologias_sv': tecnologiasSv,
      'mapbox_icon': mapboxIcon,
      'mapbox_color': mapboxColor,
      'tiene_coordenadas': tieneCoordenadas,
    };
  }

  String get direccionCompleta {
    return '$direccion, ${barrio ?? ''}, $ciudad'.replaceAll(', ,', ',').trim();
  }

  bool get estaActivo => estadoSv == 'Activo';
  bool get necesitaCoordenadas => !tieneCoordenadas && estaActivo;
}