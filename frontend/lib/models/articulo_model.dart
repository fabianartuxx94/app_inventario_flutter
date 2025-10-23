import '../config/config.dart'; // Asegúrate de importar tu AppConfig

class Articulo {
  final int? articuloId;
  final int categoriaId;
  final String categoriaNombre;
  final int marcaId;
  final String marcaNombre;
  final String referencia;
  final String tipoBodega;
  final String tipoArticulo;
  final bool esActivo; // nuevo
  final String descripcion; // nuevo
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
    required this.esActivo,
    required this.descripcion,
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
      esActivo: (json['es_activo'] is int) ? (json['es_activo'] == 1) : (json['es_activo'] ?? false),
      descripcion: json['descripcion'] ?? '',
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
      'es_activo': esActivo ? 1 : 0, // enviar como entero
      'descripcion': descripcion,
      'imagen_path': imagenPath,
      'stock_minimo': stockMinimo,
      if (etiquetas != null) 'etiquetas': etiquetas,
    };
  }

  // Getter ejemplo para mostrar descripción
  String get descripcionCorta => descripcion.length > 50 ? '${descripcion.substring(0, 50)}...' : descripcion;

  /// ✅ Getter para imagen completa usando AppConfig
  String get imagenCompletaUrl {
    if (imagenPath == null || imagenPath!.isEmpty) return '';

    if (imagenPath!.startsWith('http')) return imagenPath!;
    if (imagenPath!.startsWith('/uploads')) return '${AppConfig.baseUrl}$imagenPath';

    return '${AppConfig.imagesUrl}/$imagenPath';
  }

  /// ✅ Nombre completo para mostrar
  String get nombreCompleto => '$marcaNombre $referencia';

  /// ✅ Tipo legible
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
