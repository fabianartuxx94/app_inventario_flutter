import 'package:flutter/material.dart';
import 'package:frontend/config/config.dart';
import '../../../models/articulo_model.dart';

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

  /// Tarjeta horizontal (modo zoom escritorio)
  Widget _buildHorizontalCard(BuildContext context, bool isMobile) {
    const baseFontSize = 20.0;

    return Container(
      decoration: _buildCardDecoration(),
      child: Row(
        children: [
          Expanded(flex: 6, child: _buildImageSection(context, horizontal: true)),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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

                //  _horizontalInfoRow(Icons.qr_code, 'Referencia:', articulo.referencia, baseFontSize + 3),
                  _horizontalInfoRow(Icons.category, 'Tipo Artículo:', articulo.tipoArticulo, baseFontSize + 3),
                  _horizontalInfoRow(Icons.warehouse, 'Tipo Bodega:', articulo.tipoBodega, baseFontSize + 3),
                  _horizontalInfoRow(Icons.description, 'Descripción:', articulo.descripcion, baseFontSize + 3),
                  const SizedBox(height: 8),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta vertical (móvil o modo normal)
  Widget _buildVerticalCard(BuildContext context, bool isMobile) {
    final baseFontSize = isZoomMode
        ? (isMobile ? 16.0 : 30.0)
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

                //  _infoRow(Icons.qr_code, 'Referencia: ${articulo.referencia}', baseFontSize),
                  _infoRow(Icons.category, 'Tipo Artículo: ${articulo.tipoArticulo}', baseFontSize),
                  _infoRow(Icons.warehouse, 'Tipo Bodega: ${articulo.tipoBodega}', baseFontSize),
                  _infoRow(Icons.description, 'Descripción: ${articulo.descripcion}', baseFontSize),
                

                  const SizedBox(height: 4),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildImageSection(BuildContext context, {bool horizontal = false}) {
    return Stack(
      fit: StackFit.expand,
      children: [
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
        if (isZoomMode || isSelected)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: horizontal
                  ? const BorderRadius.horizontal(left: Radius.circular(16))
                  : const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
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
        if (isZoomMode)
          Positioned(
            top: 12,
            right: 12,
            child: _buildZoomButtons(context),
          ),
      ],
    );
  }

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

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF2a2f40),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white54, size: 32),
      ),
    );
  }

  String _buildImageUrl(String path) {
    if (path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    if (path.startsWith('/uploads')) return '${AppConfig.baseUrl}$path';
    return '${AppConfig.imagesUrl}/$path';
  }

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
