class Articulo {
  final int? articuloId;
  final int categoriaId;
  final String categoriaNombre;
  final int marcaId;
  final String marcaNombre;
  final String referencia;
  final String tipoBodega;
  final String tipoArticulo;
  final String ubicacionBodega;
  final String? imagenPath;
  final String? creadoEn;
  final int stockMinimo;
  final String? etiquetas;

  Articulo({
    this.articuloId,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.marcaId,
    required this.marcaNombre,
    required this.referencia,
    required this.tipoBodega,
    required this.tipoArticulo,
    required this.ubicacionBodega,
    this.imagenPath,
    this.creadoEn,
    required this.stockMinimo,
    this.etiquetas,
  });

  factory Articulo.fromJson(Map<String, dynamic> json) {
    return Articulo(
      articuloId: json['articulo_id'] ?? json['id'],
      categoriaId: json['categoria_id'] ?? 0,
      categoriaNombre: json['categoria_nombre'] ?? '',
      marcaId: json['marca_id'] ?? 0,
      marcaNombre: json['marca_nombre'] ?? '',
      referencia: json['referencia'] ?? '',
      tipoBodega: json['tipo_bodega'] ?? 'Sistemas',
      tipoArticulo: json['tipo_articulo'] ?? 'Activo Fijo',
      ubicacionBodega: json['ubicacion_bodega'] ?? '',
      imagenPath: json['imagen_path'],
      creadoEn: json['creado_en'],
      stockMinimo: json['stock_minimo'] ?? 0,
      etiquetas: json['etiquetas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (articuloId != null) 'articulo_id': articuloId,
      'categoria_id': categoriaId,
      'marca_id': marcaId,
      'referencia': referencia,
      'tipo_bodega': tipoBodega,
      'tipo_articulo': tipoArticulo,
      'ubicacion_bodega': ubicacionBodega,
      'imagen_path': imagenPath,
    };
  }

  // ✅ AGREGAR ESTE GETTER para imagenCompletaUrl
  String get imagenCompletaUrl {
    if (imagenPath == null || imagenPath!.isEmpty) {
      return '';
    }
    
    // Si ya es una URL completa
    if (imagenPath!.startsWith('http')) {
      return imagenPath!;
    }
    
    // Si empieza con /uploads
    if (imagenPath!.startsWith('/uploads')) {
      // Reemplaza con tu dominio real
      return 'https://tu-dominio.com$imagenPath';
    }
    
    // Para rutas relativas
    return 'https://tu-dominio.com/uploads$imagenPath';
  }

  // ✅ OPCIONAL: Getter para mostrar nombre completo
  String get nombreCompleto {
    return '$marcaNombre $referencia';
  }

  // ✅ OPCIONAL: Getter para tipo display más corto
  String get tipoDisplay {
    switch (tipoArticulo) {
      case 'Activo Fijo':
        return 'Activo Fijo';
      case 'Activo de Control':
        return 'Activo Control';
      case 'Consumible':
        return 'Consumible';
      default:
        return tipoArticulo;
    }
  }
}