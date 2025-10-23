class Inventario {
  final int id;
  final int articuloId;
  final String? placa;
  final String? serial;
  final String estado;
  final int cantidad;
  final String bodega;
  final String? ubicacionDetallada;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  
  final String articuloReferencia;
  final String articuloDescripcion;
  final String tipoArticulo;
  final String tipoBodega;
  final String categoriaNombre;
  final String? marcaNombre;

  Inventario({
    required this.id,
    required this.articuloId,
    this.placa,
    this.serial,
    required this.estado,
    required this.cantidad,
    required this.bodega,
    this.ubicacionDetallada,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.articuloReferencia,
    required this.articuloDescripcion,
    required this.tipoArticulo,
    required this.tipoBodega,
    required this.categoriaNombre,
    this.marcaNombre,
  });

  factory Inventario.fromJson(Map<String, dynamic> json) {
    return Inventario(
      id: json['id'] as int,
      articuloId: json['articulo_id'] as int,
      placa: json['placa'] as String?,
      serial: json['serial'] as String?,
      estado: (json['estado'] as String?) ?? 'Bueno',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
      bodega: (json['bodega'] as String?) ?? 'Bodega Principal',
      ubicacionDetallada: json['ubicacion_detallada'] as String?,
      fechaCreacion: DateTime.parse((json['fecha_creacion'] as String?) ?? DateTime.now().toIso8601String()),
      fechaActualizacion: DateTime.parse((json['fecha_actualizacion'] as String?) ?? DateTime.now().toIso8601String()),
      articuloReferencia: (json['articulo_referencia'] as String?) ?? 'Sin referencia',
      articuloDescripcion: (json['articulo_descripcion'] as String?) ?? 'Sin descripción',
      tipoArticulo: (json['tipo_articulo'] as String?) ?? 'general',
      tipoBodega: (json['tipo_bodega'] as String?) ?? 'Sistemas',
      categoriaNombre: (json['categoria_nombre'] as String?) ?? 'Sin categoría',
      marcaNombre: json['marca_nombre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'articulo_id': articuloId,
      'placa': placa,
      'serial': serial,
      'estado': estado,
      'cantidad': cantidad,
      'bodega': bodega,
      'ubicacion_detallada': ubicacionDetallada,
      'articulo_referencia': articuloReferencia,
      'articulo_descripcion': articuloDescripcion,
      'tipo_articulo': tipoArticulo,
      'tipo_bodega': tipoBodega,
      'categoria_nombre': categoriaNombre,
      'marca_nombre': marcaNombre,
    };
  }
}

class InventarioResponse {
  final List<Inventario> items;
  final Pagination pagination;

  InventarioResponse({required this.items, required this.pagination});

  factory InventarioResponse.fromJson(Map<String, dynamic> json) {
    return InventarioResponse(
      items: (json['items'] as List)
          .map((item) => Inventario.fromJson(item))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

class FiltrosDisponibles {
  final List<String> estados;
  final List<String> bodegas;
  final List<String> tiposBodega;
  final List<String> tiposArticulo;
  final List<String> marcas;
  final List<String> categorias;

  FiltrosDisponibles({
    required this.estados,
    required this.bodegas,
    required this.tiposBodega,
    required this.tiposArticulo,
    required this.marcas,
    required this.categorias,
  });

  factory FiltrosDisponibles.fromJson(Map<String, dynamic> json) {
    // Manejar diferentes estructuras de respuesta
    final estados = _parseList(json['estados'] ?? []);
    final bodegas = _parseList(json['bodegas'] ?? []);
    final tiposBodega = _parseList(json['tipos_bodega'] ?? []);
    final tiposArticulo = _parseList(json['tipos_articulo'] ?? []);
    final marcas = _parseList(json['marcas'] ?? []);
    final categorias = _parseList(json['categorias'] ?? []);

    print('🔄 Parsing FiltrosDisponibles:');
    print('  - Estados: $estados');
    print('  - Bodegas: $bodegas');
    print('  - Tipos Bodega: $tiposBodega');
    print('  - Tipos Artículo: $tiposArticulo');
    print('  - Marcas: $marcas');
    print('  - Categorías: $categorias');

    return FiltrosDisponibles(
      estados: estados,
      bodegas: bodegas,
      tiposBodega: tiposBodega,
      tiposArticulo: tiposArticulo,
      marcas: marcas,
      categorias: categorias,
    );
  }

  static List<String> _parseList(dynamic data) {
    if (data is List) {
      return List<String>.from(data);
    }
    return [];
  }

  @override
  String toString() {
    return 'FiltrosDisponibles(estados: $estados, bodegas: $bodegas, tiposBodega: $tiposBodega, tiposArticulo: $tiposArticulo, marcas: $marcas, categorias: $categorias)';
  }
}