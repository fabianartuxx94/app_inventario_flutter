class Articulo {
  final int idGeneral;
  final String nombreArticulo;
  final int stockMinimo;
  final String descripcionGeneral;
  final int idCatalogo;
  final String marca;
  final String referencia;
  final String tipoBodega;
  final String tipo;
  final String descripcionCatalogo;
  final String imagenPath;

  Articulo({
    required this.idGeneral,
    required this.nombreArticulo,
    required this.stockMinimo,
    required this.descripcionGeneral,
    required this.idCatalogo,
    required this.marca,
    required this.referencia,
    required this.tipoBodega,
    required this.tipo,
    required this.descripcionCatalogo,
    required this.imagenPath,
  });

factory Articulo.fromJson(Map<String, dynamic> json) {
  return Articulo(
    idGeneral: json['id_general'] ?? 0,        // ✅ Correcto
    nombreArticulo: json['nombre_articulo'] ?? '', // ✅ Correcto  
    stockMinimo: json['stock_minimo'] ?? 0,    // ✅ Correcto
    descripcionGeneral: json['descripcion_general'] ?? '', // ✅ Correcto
    idCatalogo: json['id_catalogo'] ?? 0,      // ✅ Correcto
    marca: json['marca'] ?? '',                // ✅ Correcto
    referencia: json['referencia'] ?? '',      // ✅ Correcto
    tipoBodega: json['tipo_bodega'] ?? '',     // ✅ Correcto
    tipo: json['tipo'] ?? '',                  // ✅ Correcto
    descripcionCatalogo: json['descripcion_catalogo'] ?? '', // ✅ Correcto
    imagenPath: json['imagen_path'] ?? '',     // ✅ Correcto
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id_general': idGeneral,
      'nombre_articulo': nombreArticulo,
      'stock_minimo': stockMinimo,
      'descripcion_general': descripcionGeneral,
      'id_catalogo': idCatalogo,
      'marca': marca,
      'referencia': referencia,
      'tipo_bodega': tipoBodega,
      'tipo': tipo,
      'descripcion_catalogo': descripcionCatalogo,
      'imagen_path': imagenPath,
    };
  }

  String get imagenCompletaUrl {
    if (imagenPath.isEmpty) return '';
    if (imagenPath.startsWith('http')) return imagenPath;
    if (imagenPath.startsWith('/uploads/')) {
      return 'http://10.192.84.125:5000$imagenPath';
    }
    return 'http://10.192.84.125:5000/uploads/images/articulos/$imagenPath';
  }

  bool get esActivoFijo => tipo == 'activo_fijo';
  bool get esActivoControl => tipo == 'activo_control';
  bool get esConsumible => tipo == 'consumible';
  bool get esBodegaSistemas => tipoBodega == 'Sistemas';
  bool get esBodegaBmd => tipoBodega == 'Bmd';

  String get tipoDisplay {
    switch (tipo) {
      case 'activo_fijo': return 'Activo Fijo';
      case 'activo_control': return 'Activo Control';
      case 'consumible': return 'Consumible';
      default: return tipo;
    }
  }

  String get displayName {
    return '$nombreArticulo - $marca $referencia';
  }

  String get infoResumen {
    return '${tipoDisplay} • $tipoBodega • Stock Mín: $stockMinimo';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Articulo &&
          runtimeType == other.runtimeType &&
          idCatalogo == other.idCatalogo;

  @override
  int get hashCode => idCatalogo.hashCode;

  @override
  String toString() {
    return 'Articulo{idGeneral: $idGeneral, nombre: $nombreArticulo, marca: $marca, referencia: $referencia, tipo: $tipo}';
  }

  // Método para crear una copia con algunos campos actualizados
  Articulo copyWith({
    int? idGeneral,
    String? nombreArticulo,
    int? stockMinimo,
    String? descripcionGeneral,
    int? idCatalogo,
    String? marca,
    String? referencia,
    String? tipoBodega,
    String? tipo,
    String? descripcionCatalogo,
    String? imagenPath,
  }) {
    return Articulo(
      idGeneral: idGeneral ?? this.idGeneral,
      nombreArticulo: nombreArticulo ?? this.nombreArticulo,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      descripcionGeneral: descripcionGeneral ?? this.descripcionGeneral,
      idCatalogo: idCatalogo ?? this.idCatalogo,
      marca: marca ?? this.marca,
      referencia: referencia ?? this.referencia,
      tipoBodega: tipoBodega ?? this.tipoBodega,
      tipo: tipo ?? this.tipo,
      descripcionCatalogo: descripcionCatalogo ?? this.descripcionCatalogo,
      imagenPath: imagenPath ?? this.imagenPath,
    );
  }
}