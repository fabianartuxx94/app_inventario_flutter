import 'package:flutter/material.dart';
import '../models/articulo_model.dart';
import '../config/config.dart';

class ArticuloCard extends StatelessWidget {
  final Articulo articulo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ArticuloCard({
    super.key,
    required this.articulo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.2;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a2235), Color(0xFF1e293b)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 📷 Imagen con acciones
          Stack(
            children: [
              _buildImageSection(imageHeight),

              // Gradiente encima de imagen
              Container(
                height: imageHeight,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Etiqueta tipo artículo
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorPorTipo(articulo.tipoArticulo),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTipoDisplay(articulo.tipoArticulo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Botones editar y eliminar
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16, color: Color(0xFF60a5fa)),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16, color: Color(0xFFf87171)),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 📋 Información del artículo
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categoría
                Text(
                  articulo.categoriaNombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Marca y referencia
                Text(
                  '${articulo.marcaNombre} - ${articulo.referencia}',
                  style: const TextStyle(
                    color: Color(0xFFcbd5e1),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 8),

                // Detalles
                _infoRow(Icons.location_on, 'Ubicación: ${articulo.ubicacionBodega}'),
                _infoRow(Icons.qr_code, 'Referencia: ${articulo.referencia}'),
                _infoRow(Icons.category, 'Tipo Artículo: ${articulo.tipoArticulo}'),
                _infoRow(Icons.warehouse, 'Tipo Bodega: ${articulo.tipoBodega}'),

                const SizedBox(height: 8),

                // Etiquetas como chips
                if (articulo.etiquetas != null)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _buildEtiquetasChips(articulo.etiquetas!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Imagen del artículo
  Widget _buildImageSection(double height) {
    final imageUrl = _buildImageUrl(articulo.imagenPath ?? '');

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _buildPlaceholderContent(height),
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFf59e0b)),
            );
          },
        ),
      ),
    );
  }

  /// Placeholder sin imagen
  Widget _buildPlaceholderContent(double height) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF2a2f40),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white54, size: 32),
      ),
    );
  }

  /// Fila con icono y texto
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Color(0xFF94a3b8)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Chips de etiquetas
  List<Widget> _buildEtiquetasChips(String etiquetasStr) {
    final etiquetas = etiquetasStr
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return etiquetas.map((etiqueta) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 16, 7, 134),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          etiqueta,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      );
    }).toList();
  }

  /// Construcción de URL de imagen
  String _buildImageUrl(String imagenPath) {
    if (imagenPath.isEmpty) return "";
    if (imagenPath.startsWith('http')) return imagenPath;
    if (imagenPath.startsWith('/uploads')) return '${AppConfig.baseUrl}$imagenPath';
    return '${AppConfig.imagesUrl}/$imagenPath';
  }

  /// Texto bonito para tipo de artículo
  String _getTipoDisplay(String tipoArticulo) {
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

  /// Color de fondo por tipo de artículo
  Color _getColorPorTipo(String tipoArticulo) {
    switch (tipoArticulo) {
      case 'Activo Fijo':
        return const Color(0xFF10b981);
      case 'Activo de Control':
        return const Color(0xFFf59e0b);
      case 'Consumible':
        return const Color(0xFFef4444);
      default:
        return const Color(0xFF6b7280);
    }
  }
}
