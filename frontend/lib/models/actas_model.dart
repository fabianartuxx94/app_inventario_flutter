// 📋 MODELO PARA ACTAS
class Acta {
  final int id;
  final String tipo;
  final String descripcion;
  final DateTime fecha;
  final String? archivoPdf;
  final String creadorNombre;
  final String? entregadoPorNombre;
  final String? recibidoPorNombre;
  final String? auditorNombre;
  final int totalItems;
  final String fechaFormateada;

  Acta({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
    this.archivoPdf,
    required this.creadorNombre,
    this.entregadoPorNombre,
    this.recibidoPorNombre,
    this.auditorNombre,
    required this.totalItems,
    required this.fechaFormateada,
  });

  factory Acta.fromJson(Map<String, dynamic> json) {
    return Acta(
      id: json['id'] ?? 0,
      tipo: json['tipo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      archivoPdf: json['archivo_pdf'],
      creadorNombre: json['creador_nombre'] ?? 'Usuario',
      entregadoPorNombre: json['entregado_por_nombre'],
      recibidoPorNombre: json['recibido_por_nombre'],
      auditorNombre: json['auditor_nombre'],
      totalItems: json['total_items'] ?? 0,
      fechaFormateada: json['fecha_formateada'] ?? '',
    );
  }

  // Método para obtener el color según el tipo
  String get tipoColor {
    switch (tipo) {
      case 'ASIGNACION':
        return '0xFF4CAF50'; // Green
      case 'TRANSFERENCIA':
        return '0xFF2196F3'; // Blue
      case 'DEVOLUCION':
        return '0xFFFF9800'; // Orange
      case 'BAJA':
        return '0xFFF44336'; // Red
      default:
        return '0xFF757575'; // Grey
    }
  }

  // Método para obtener el texto del tipo
  String get tipoTexto {
    switch (tipo) {
      case 'ASIGNACION':
        return 'Asignación';
      case 'TRANSFERENCIA':
        return 'Transferencia';
      case 'DEVOLUCION':
        return 'Devolución';
      case 'BAJA':
        return 'Baja';
      default:
        return tipo;
    }
  }
}

// 🔍 MODELO PARA DETALLES DE ACTA
class ActaDetalle {
  final int id;
  final int inventarioId;
  final String? placa;
  final String? serial;
  final String estadoActual;
  final String bodega;
  final String? ubicacionDetallada;
  final String articuloReferencia;
  final String articuloDescripcion;
  final String tipoArticulo;
  final String categoriaNombre;
  final String? marcaNombre;
  final String? informacionAdicional;

  ActaDetalle({
    required this.id,
    required this.inventarioId,
    this.placa,
    this.serial,
    required this.estadoActual,
    required this.bodega,
    this.ubicacionDetallada,
    required this.articuloReferencia,
    required this.articuloDescripcion,
    required this.tipoArticulo,
    required this.categoriaNombre,
    this.marcaNombre,
    this.informacionAdicional,
  });

  factory ActaDetalle.fromJson(Map<String, dynamic> json) {
    return ActaDetalle(
      id: json['id'] ?? 0,
      inventarioId: json['inventario_id'] ?? 0,
      placa: json['placa'],
      serial: json['serial'],
      estadoActual: json['estado_actual'] ?? '',
      bodega: json['bodega'] ?? '',
      ubicacionDetallada: json['ubicacion_detallada'],
      articuloReferencia: json['articulo_referencia'] ?? '',
      articuloDescripcion: json['articulo_descripcion'] ?? '',
      tipoArticulo: json['tipo_articulo'] ?? '',
      categoriaNombre: json['categoria_nombre'] ?? '',
      marcaNombre: json['marca_nombre'],
      informacionAdicional: json['informacion_adicional'],
    );
  }
}

// 🔔 MODELO PARA NOTIFICACIONES
class Notificacion {
  final int id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final DateTime creadoEn;
  final DateTime? leidoEn;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.creadoEn,
    this.leidoEn,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      tipo: json['tipo'] ?? 'sistema',
      leida: (json['leida'] as int?) == 1 || json['leida'] == true,
      creadoEn: DateTime.parse(json['creado_en'] ?? DateTime.now().toIso8601String()),
      leidoEn: json['leido_en'] != null ? DateTime.parse(json['leido_en']) : null,
    );
  }

  // Método para obtener el icono según el tipo
  String get iconoTipo {
    switch (tipo) {
      case 'transferencia':
        return '📦';
      case 'asignacion':
        return '🎯';
      case 'devolucion':
        return '🔄';
      default:
        return '🔔';
    }
  }
}