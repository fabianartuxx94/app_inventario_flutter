// 📦 MODELO PARA STOCK AGREGADO
class StockAgregado {
  final String referencia;
  final String descripcion;
  final String tipoArticulo;
  final String categoriaNombre;
  final String? marcaNombre;
  final int stockTotal;
  final int unidadesTotales;
  final Map<String, dynamic> stockPorBodega;

  StockAgregado({
    required this.referencia,
    required this.descripcion,
    required this.tipoArticulo,
    required this.categoriaNombre,
    this.marcaNombre,
    required this.stockTotal,
    required this.unidadesTotales,
    required this.stockPorBodega,
  });

  factory StockAgregado.fromJson(Map<String, dynamic> json) {
    return StockAgregado(
      referencia: json['referencia'] ?? '',
      descripcion: json['descripcion'] ?? '',
      tipoArticulo: json['tipo_articulo'] ?? '',
      categoriaNombre: json['categoria_nombre'] ?? '',
      marcaNombre: json['marca_nombre'],
      stockTotal: (json['stock_total'] as num?)?.toInt() ?? 0,
      unidadesTotales: (json['unidades_totales'] as num?)?.toInt() ?? 0,
      stockPorBodega: Map<String, dynamic>.from(json['stock_por_bodega'] ?? {}),
    );
  }

  // Método para obtener stock de una bodega específica
  int getStockBodega(String bodega) {
    final bodegaData = stockPorBodega[bodega];
    if (bodegaData is Map) {
      return (bodegaData['stock'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  // Método para obtener unidades de una bodega específica
  int getUnidadesBodega(String bodega) {
    final bodegaData = stockPorBodega[bodega];
    if (bodegaData is Map) {
      return (bodegaData['unidades'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  // Lista de bodegas con stock
  List<String> get bodegasConStock {
    return stockPorBodega.keys.toList();
  }
}

// 🎯 MODELO PARA RESPUESTA DE ASIGNACIÓN MASIVA
class RespuestaAsignacionMasiva {
  final bool success;
  final String message;
  final int? actaId;
  final int itemsAsignados;

  RespuestaAsignacionMasiva({
    required this.success,
    required this.message,
    this.actaId,
    required this.itemsAsignados,
  });

  factory RespuestaAsignacionMasiva.fromJson(Map<String, dynamic> json) {
    return RespuestaAsignacionMasiva(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      actaId: json['acta_id'],
      itemsAsignados: json['items_asignados'] ?? 0,
    );
  }
}

// 🔄 MODELO PARA RESPUESTA DE TRANSFERENCIA
class RespuestaTransferencia {
  final bool success;
  final String message;
  final int? actaId;
  final int itemsTransferidos;
  final bool notificacionEnviada;

  RespuestaTransferencia({
    required this.success,
    required this.message,
    this.actaId,
    required this.itemsTransferidos,
    required this.notificacionEnviada,
  });

  factory RespuestaTransferencia.fromJson(Map<String, dynamic> json) {
    return RespuestaTransferencia(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      actaId: json['acta_id'],
      itemsTransferidos: json['items_transferidos'] ?? 0,
      notificacionEnviada: json['notificacion_enviada'] ?? false,
    );
  }
}

// 🔄 MODELO PARA RESPUESTA DE DEVOLUCIÓN
class RespuestaDevolucion {
  final bool success;
  final String message;
  final int? actaId;
  final String estadoEquipo;

  RespuestaDevolucion({
    required this.success,
    required this.message,
    this.actaId,
    required this.estadoEquipo,
  });

  factory RespuestaDevolucion.fromJson(Map<String, dynamic> json) {
    return RespuestaDevolucion(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      actaId: json['acta_id'],
      estadoEquipo: json['estado_equipo'] ?? '',
    );
  }
}

// 📊 MODELO PARA ESTADÍSTICAS DE NOTIFICACIONES
class EstadisticasNotificaciones {
  final int total;
  final int noLeidas;
  final List<EstadisticaTipo> porTipo;

  EstadisticasNotificaciones({
    required this.total,
    required this.noLeidas,
    required this.porTipo,
  });

  factory EstadisticasNotificaciones.fromJson(Map<String, dynamic> json) {
    final porTipoData = json['por_tipo'] as List? ?? [];
    return EstadisticasNotificaciones(
      total: (json['total'] as num?)?.toInt() ?? 0,
      noLeidas: (json['no_leidas'] as num?)?.toInt() ?? 0,
      porTipo: porTipoData.map((item) => EstadisticaTipo.fromJson(item)).toList(),
    );
  }

  // Porcentaje de notificaciones leídas
  double get porcentajeLeidas {
    if (total == 0) return 0.0;
    return ((total - noLeidas) / total * 100);
  }
}

class EstadisticaTipo {
  final String tipo;
  final int total;
  final int noLeidas;

  EstadisticaTipo({
    required this.tipo,
    required this.total,
    required this.noLeidas,
  });

  factory EstadisticaTipo.fromJson(Map<String, dynamic> json) {
    return EstadisticaTipo(
      tipo: json['tipo'] ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      noLeidas: (json['no_leidas'] as num?)?.toInt() ?? 0,
    );
  }
}

// 📈 MODELO PARA ESTADÍSTICAS DE ACTAS
class EstadisticasActas {
  final List<EstadisticaActaTipo> porTipo;
  final EstadisticasActaGeneral general;

  EstadisticasActas({
    required this.porTipo,
    required this.general,
  });

  factory EstadisticasActas.fromJson(Map<String, dynamic> json) {
    final porTipoData = json['por_tipo'] as List? ?? [];
    return EstadisticasActas(
      porTipo: porTipoData.map((item) => EstadisticaActaTipo.fromJson(item)).toList(),
      general: EstadisticasActaGeneral.fromJson(json['general'] ?? {}),
    );
  }
}

class EstadisticaActaTipo {
  final String tipo;
  final int totalActas;
  final int totalItems;
  final DateTime? fechaPrimerActa;
  final DateTime? fechaUltimaActa;

  EstadisticaActaTipo({
    required this.tipo,
    required this.totalActas,
    required this.totalItems,
    this.fechaPrimerActa,
    this.fechaUltimaActa,
  });

  factory EstadisticaActaTipo.fromJson(Map<String, dynamic> json) {
    return EstadisticaActaTipo(
      tipo: json['tipo'] ?? '',
      totalActas: (json['total_actas'] as num?)?.toInt() ?? 0,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      fechaPrimerActa: json['fecha_primer_acta'] != null 
          ? DateTime.parse(json['fecha_primer_acta']) 
          : null,
      fechaUltimaActa: json['fecha_ultima_acta'] != null 
          ? DateTime.parse(json['fecha_ultima_acta']) 
          : null,
    );
  }

  // Promedio de items por acta
  double get promedioItemsPorActa {
    if (totalActas == 0) return 0.0;
    return totalItems / totalActas;
  }
}

class EstadisticasActaGeneral {
  final int totalActas;
  final int usuariosActivos;
  final int totalItemsMovidos;
  final DateTime? fechaInicioSistema;
  final DateTime? fechaUltimaActividad;

  EstadisticasActaGeneral({
    required this.totalActas,
    required this.usuariosActivos,
    required this.totalItemsMovidos,
    this.fechaInicioSistema,
    this.fechaUltimaActividad,
  });

  factory EstadisticasActaGeneral.fromJson(Map<String, dynamic> json) {
    return EstadisticasActaGeneral(
      totalActas: (json['total_actas'] as num?)?.toInt() ?? 0,
      usuariosActivos: (json['usuarios_activos'] as num?)?.toInt() ?? 0,
      totalItemsMovidos: (json['total_items_movidos'] as num?)?.toInt() ?? 0,
      fechaInicioSistema: json['fecha_inicio_sistema'] != null 
          ? DateTime.parse(json['fecha_inicio_sistema']) 
          : null,
      fechaUltimaActividad: json['fecha_ultima_actividad'] != null 
          ? DateTime.parse(json['fecha_ultima_actividad']) 
          : null,
    );
  }

  // Promedio de items por acta
  double get promedioItemsPorActa {
    if (totalActas == 0) return 0.0;
    return totalItemsMovidos / totalActas;
  }

  // Promedio de actas por usuario
  double get promedioActasPorUsuario {
    if (usuariosActivos == 0) return 0.0;
    return totalActas / usuariosActivos;
  }
}

// 📝 MODELO PARA SOLICITUD DE ASIGNACIÓN MASIVA
class SolicitudAsignacionMasiva {
  final int tecnicoId;
  final int sitioVentaId;
  final List<int> inventarioIds;
  final String? descripcion;
  final String? observaciones;

  SolicitudAsignacionMasiva({
    required this.tecnicoId,
    required this.sitioVentaId,
    required this.inventarioIds,
    this.descripcion,
    this.observaciones,
  });

  Map<String, dynamic> toJson() {
    return {
      'tecnico_id': tecnicoId,
      'sitio_venta_id': sitioVentaId,
      'inventario_ids': inventarioIds,
      if (descripcion != null && descripcion!.isNotEmpty) 'descripcion': descripcion,
      if (observaciones != null && observaciones!.isNotEmpty) 'observaciones': observaciones,
    };
  }
}

// 📦 MODELO PARA SOLICITUD DE TRANSFERENCIA
class SolicitudTransferencia {
  final List<int> inventarioIds;
  final String bodegaOrigen;
  final String bodegaDestino;
  final String? motivo;

  SolicitudTransferencia({
    required this.inventarioIds,
    required this.bodegaOrigen,
    required this.bodegaDestino,
    this.motivo,
  });

  Map<String, dynamic> toJson() {
    return {
      'inventario_ids': inventarioIds,
      'bodega_origen': bodegaOrigen,
      'bodega_destino': bodegaDestino,
      if (motivo != null && motivo!.isNotEmpty) 'motivo': motivo,
    };
  }
}

// 🔄 MODELO PARA SOLICITUD DE DEVOLUCIÓN
class SolicitudDevolucion {
  final int asignacionId;
  final String estadoEquipo;
  final String? motivoDevolucion;

  SolicitudDevolucion({
    required this.asignacionId,
    required this.estadoEquipo,
    this.motivoDevolucion,
  });

  Map<String, dynamic> toJson() {
    return {
      'asignacion_id': asignacionId,
      'estado_equipo': estadoEquipo,
      if (motivoDevolucion != null && motivoDevolucion!.isNotEmpty) 'motivo_devolucion': motivoDevolucion,
    };
  }
}