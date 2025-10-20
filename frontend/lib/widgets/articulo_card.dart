import 'package:flutter/material.dart';
import 'package:frontend/config/config.dart';
import '../../models/articulo_model.dart';

/// Widget que representa una tarjeta visual de un artículo
/// con modo selección, zoom y acciones de editar/eliminar.
class ArticuloCard extends StatelessWidget {
  final Articulo articulo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelected;
  final VoidCallback onSelect;
  final bool isZoomMode;

  const ArticuloCard({
    super.key,
    required this.articulo,
    required this.onEdit,
    required this.onDelete,
    required this.isSelected,
    required this.onSelect,
    required this.isZoomMode,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 750;
    final isDesktopZoom = isZoomMode && !isMobile;

    // Contenedor con animación de escala al seleccionarse
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(isSelected ? 1.1 : 1.0),
        child: isDesktopZoom
            ? _buildHorizontalCard(context, isMobile)
            : _buildVerticalCard(context, isMobile),
      ),
    );
  }

  /// Construye la tarjeta en formato horizontal (solo para zoom en escritorio)
  Widget _buildHorizontalCard(BuildContext context, bool isMobile) {
    const baseFontSize = 16.0;

    return Container(
      decoration: _buildCardDecoration(),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: _buildImageSection(context, horizontal: true),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nombre de categoría
                  Text(
                    articulo.categoriaNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: baseFontSize + 6,
                    ),
                  ),
                  // Marca y referencia
                  Text(
                    '${articulo.marcaNombre} - ${articulo.referencia}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFcbd5e1),
                      fontSize: baseFontSize + 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Datos del artículo
                  _horizontalInfoRow(Icons.location_on, 'Ubicación:', articulo.ubicacionBodega, baseFontSize + 3),
                  _horizontalInfoRow(Icons.qr_code, 'Referencia:', articulo.referencia, baseFontSize + 3),
                  _horizontalInfoRow(Icons.category, 'Tipo Artículo:', articulo.tipoArticulo, baseFontSize + 3),
                  _horizontalInfoRow(Icons.warehouse, 'Tipo Bodega:', articulo.tipoBodega, baseFontSize + 3),
                  const SizedBox(height: 8),
                  // Etiquetas si existen
                  if (articulo.etiquetas != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Etiquetas:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: baseFontSize + 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _buildEtiquetasChips(articulo.etiquetas!, baseFontSize + 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la tarjeta en formato vertical (modo estándar o móvil)
  Widget _buildVerticalCard(BuildContext context, bool isMobile) {
    final baseFontSize = isZoomMode
        ? (isMobile ? 18.0 : 35.0)
        : (isMobile ? 10.0 : 16.0);

    return Container(
      decoration: _buildCardDecoration(),
      child: Column(
        children: [
          Expanded(
            flex: isZoomMode ? 6 : 4,
            child: _buildImageSection(context),
          ),
          Expanded(
            flex: isZoomMode ? 4 : 6,
            child: Padding(
              padding: EdgeInsets.all(isZoomMode ? 16 : (isMobile ? 8 : 12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    articulo.categoriaNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: baseFontSize + 1,
                    ),
                  ),
                  Text(
                    '${articulo.marcaNombre} - ${articulo.referencia}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFcbd5e1),
                      fontSize: baseFontSize,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _infoRow(Icons.location_on, 'Ubicación: ${articulo.ubicacionBodega}', baseFontSize),
                  _infoRow(Icons.qr_code, 'Referencia: ${articulo.referencia}', baseFontSize),
                  _infoRow(Icons.category, 'Tipo Artículo: ${articulo.tipoArticulo}', baseFontSize),
                  _infoRow(Icons.warehouse, 'Tipo Bodega: ${articulo.tipoBodega}', baseFontSize),
                  const SizedBox(height: 4),
                  if (articulo.etiquetas != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _buildEtiquetasChips(articulo.etiquetas!, baseFontSize - 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Estilo decorativo del contenedor de la tarjeta
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
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
    );
  }

  /// Construye la sección de imagen del artículo
  Widget _buildImageSection(BuildContext context, {bool horizontal = false}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagen del artículo
        ClipRRect(
          borderRadius: horizontal
              ? const BorderRadius.horizontal(left: Radius.circular(16))
              : const BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.network(
            _buildImageUrl(articulo.imagenPath ?? ''),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
            loadingBuilder: (_, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Color(0xFFf59e0b)));
            },
          ),
        ),

        // Sombra oscura si está seleccionado o en zoom
        if (isZoomMode || isSelected)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: horizontal
                  ? const BorderRadius.horizontal(left: Radius.circular(16))
                  : const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

        // Tipo de artículo en esquina superior izquierda
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getColorPorTipo(articulo.tipoArticulo),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getTipoDisplay(articulo.tipoArticulo),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Botones de acción (editar/eliminar)
        if (isZoomMode)
          Positioned(
            top: 12,
            right: 12,
            child: _buildZoomButtons(context),
          ),
      ],
    );
  }

  /// Construye los botones de edición y eliminación (solo modo zoom)
  Widget _buildZoomButtons(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: onEdit,
              iconSize: isZoomMode ? 30 : 20,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              iconSize: isZoomMode ? 24 : 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Imagen por defecto cuando no carga
  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF2a2f40),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white54, size: 32),
      ),
    );
  }

  /// Construye la URL de la imagen según la ruta proporcionada
  String _buildImageUrl(String path) {
    if (path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    if (path.startsWith('/uploads')) return '${AppConfig.baseUrl}$path';
    return '${AppConfig.imagesUrl}/$path';
  }

  /// Devuelve color representativo del tipo de artículo
  Color _getColorPorTipo(String tipo) {
    switch (tipo) {
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

  /// Devuelve texto mostrado para el tipo de artículo
  String _getTipoDisplay(String tipo) {
    switch (tipo) {
      case 'Activo Fijo':
        return 'Activo Fijo';
      case 'Activo de Control':
        return 'Activo Control';
      case 'Consumible':
        return 'Consumible';
      default:
        return tipo;
    }
  }

  /// Construye chips de etiquetas
  List<Widget> _buildEtiquetasChips(String etiquetasStr, double fontSize) {
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
          style: TextStyle(color: Colors.white, fontSize: fontSize),
        ),
      );
    }).toList();
  }

  /// Fila con ícono + texto (formato compacto)
  Widget _infoRow(IconData icon, String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF94a3b8)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: const Color(0xFF94a3b8), fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Fila con ícono, etiqueta y valor (solo para tarjeta horizontal)
  Widget _horizontalInfoRow(IconData icon, String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: fontSize - 2, color: const Color(0xFF94a3b8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFFcbd5e1),
                    fontSize: fontSize - 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF94a3b8),
                    fontSize: fontSize - 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
