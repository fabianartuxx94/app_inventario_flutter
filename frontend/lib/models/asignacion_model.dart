class Asignacion {
  final int id;
  final String fechaAsignacion;
  final String estado;
  final String? observaciones;
  
  // Información del técnico
  final int tecnicoId;
  final String tecnicoNombre;
  final String tecnicoIdentificacion;
  
  // Información del inventario
  final int inventarioId;
  final String? placa;
  final String? serial;
  final String estadoEquipo;
  final String estadoAsignacion;
  
  // Información del artículo
  final String articuloReferencia;
  final String? articuloDescripcion;
  final String tipoArticulo;
  
  // Información del sitio de venta
  final int sitioVentaId;
  final String codigoSv;
  final String sitioVenta;
  final String? direccion;
  final String ciudad;
  final String? barrio;
  final double? latitud;
  final double? longitud;
  
  // Información del asignador
  final String asignadorNombre;

  Asignacion({
    required this.id,
    required this.fechaAsignacion,
    required this.estado,
    this.observaciones,
    required this.tecnicoId,
    required this.tecnicoNombre,
    required this.tecnicoIdentificacion,
    required this.inventarioId,
    this.placa,
    this.serial,
    required this.estadoEquipo,
    required this.estadoAsignacion,
    required this.articuloReferencia,
    this.articuloDescripcion,
    required this.tipoArticulo,
    required this.sitioVentaId,
    required this.codigoSv,
    required this.sitioVenta,
    this.direccion,
    required this.ciudad,
    this.barrio,
    this.latitud,
    this.longitud,
    required this.asignadorNombre,
  });

  factory Asignacion.fromJson(Map<String, dynamic> json) {
    return Asignacion(
      id: json['id'] ?? 0,
      fechaAsignacion: json['fecha_asignacion'] ?? '',
      estado: json['estado'] ?? '',
      observaciones: json['observaciones'],
      tecnicoId: json['tecnico_id'] ?? 0,
      tecnicoNombre: json['tecnico_nombre'] ?? '',
      tecnicoIdentificacion: json['tecnico_identificacion'] ?? '',
      inventarioId: json['inventario_id'] ?? 0,
      placa: json['placa'],
      serial: json['serial'],
      estadoEquipo: json['estado_equipo'] ?? '',
      estadoAsignacion: json['estado_asignacion'] ?? '',
      articuloReferencia: json['articulo_referencia'] ?? '',
      articuloDescripcion: json['articulo_descripcion'],
      tipoArticulo: json['tipo_articulo'] ?? '',
      sitioVentaId: json['sitio_venta_id'] ?? 0,
      codigoSv: json['codigo_sv'] ?? '',
      sitioVenta: json['sitio_venta'] ?? '',
      direccion: json['direccion'],
      ciudad: json['ciudad'] ?? '',
      barrio: json['barrio'],
      latitud: json['latitud'] != null ? double.parse(json['latitud'].toString()) : null,
      longitud: json['longitud'] != null ? double.parse(json['longitud'].toString()) : null,
      asignadorNombre: json['asignador_nombre'] ?? '',
    );
  }

  // Método para obtener el color según el estado
  String get estadoColor {
    switch (estado) {
      case 'asignado':
        return '0xFFFFA000'; // Amber
      case 'instalado':
        return '0xFF4CAF50'; // Green
      case 'devuelto':
        return '0xFF2196F3'; // Blue
      default:
        return '0xFF757575'; // Grey
    }
  }

  // Método para obtener el texto del estado
  String get estadoTexto {
    switch (estado) {
      case 'asignado':
        return 'Asignado';
      case 'instalado':
        return 'Instalado';
      case 'devuelto':
        return 'Devuelto';
      default:
        return estado;
    }
  }
}

class InventarioDisponible {
  final int id;
  final String? placa;
  final String? serial;
  final String estado;
  final String estadoAsignacion;
  final String bodega;
  final String? ubicacionDetallada;
  final String articuloReferencia;
  final String? articuloDescripcion;
  final String tipoArticulo;
  final String? categoriaNombre;
  final String? marcaNombre;

  InventarioDisponible({
    required this.id,
    this.placa,
    this.serial,
    required this.estado,
    required this.estadoAsignacion,
    required this.bodega,
    this.ubicacionDetallada,
    required this.articuloReferencia,
    this.articuloDescripcion,
    required this.tipoArticulo,
    this.categoriaNombre,
    this.marcaNombre,
  });

  factory InventarioDisponible.fromJson(Map<String, dynamic> json) {
    return InventarioDisponible(
      id: json['id'] ?? 0,
      placa: json['placa'],
      serial: json['serial'],
      estado: json['estado'] ?? '',
      estadoAsignacion: json['estado_asignacion'] ?? '',
      bodega: json['bodega'] ?? '',
      ubicacionDetallada: json['ubicacion_detallada'],
      articuloReferencia: json['articulo_referencia'] ?? '',
      articuloDescripcion: json['articulo_descripcion'],
      tipoArticulo: json['tipo_articulo'] ?? '',
      categoriaNombre: json['categoria_nombre'],
      marcaNombre: json['marca_nombre'],
    );
  }

  // Descripción completa para mostrar en UI
  String get descripcionCompleta {
    List<String> partes = [articuloReferencia];
    
    if (placa != null) partes.add('Placa: $placa');
    if (serial != null) partes.add('Serial: $serial');
    if (marcaNombre != null) partes.add('Marca: $marcaNombre');
    
    partes.add('Bodega: $bodega');
    
    return partes.join(' • ');
  }
}