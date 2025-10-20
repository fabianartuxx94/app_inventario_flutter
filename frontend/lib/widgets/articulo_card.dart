import 'package:flutter/material.dart';
import 'package:frontend/config/config.dart';
import '../../models/articulo_model.dart';

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
    final isMobile = screenWidth < 600;
    final isDesktopZoom = isZoomMode && !isMobile;

    return GestureDetector( // ⭐ CAMBIADO: Solo responde a clicks/taps
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

  Widget _buildHorizontalCard(BuildContext context, bool isMobile) {
    double baseFontSize = 16;

    return Container( // ⭐ QUITADO: GestureDetector duplicado
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
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: Image.network(
                    _buildImageUrl(articulo.imagenPath ?? ''),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFf59e0b)),
                      );
                    },
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),

                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getColorPorTipo(articulo.tipoArticulo),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTipoDisplay(articulo.tipoArticulo),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: baseFontSize - 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // BOTONES SOLO EN MODO ZOOM
                if (isZoomMode)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // BOTÓN EDITAR
                            GestureDetector(
                              onTap: () {
                                print('✏️ Botón EDITAR presionado - ID: ${articulo.articuloId}');
                                if (onEdit != null) {
                                  onEdit();
                                } else {
                                  print('❌ ERROR: onEdit es null');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.edit, 
                                  color: Colors.blueAccent,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // BOTÓN ELIMINAR
                            GestureDetector(
                              onTap: () {
                                print('🗑️ Botón ELIMINAR presionado - ID: ${articulo.articuloId}');
                                _mostrarDialogoEliminacion(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.delete, 
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

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
                  
                  _horizontalInfoRow(Icons.location_on, 'Ubicación:', articulo.ubicacionBodega, baseFontSize+3),
                  _horizontalInfoRow(Icons.qr_code, 'Referencia:', articulo.referencia, baseFontSize+3),
                  _horizontalInfoRow(Icons.category, 'Tipo Artículo:', articulo.tipoArticulo, baseFontSize+3),
                  _horizontalInfoRow(Icons.warehouse, 'Tipo Bodega:', articulo.tipoBodega, baseFontSize+3),
                  
                  const SizedBox(height: 8),
                  
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

  Widget _buildVerticalCard(BuildContext context, bool isMobile) {
    double baseFontSize;
    if (isZoomMode) {
      baseFontSize = isMobile ? 18 : 35;
    } else {
      baseFontSize = isMobile ? 10 : 16;
    }

    return Container( // ⭐ QUITADO: GestureDetector duplicado
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
        children: [
          Expanded(
            flex: isZoomMode ? 5 : 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    _buildImageUrl(articulo.imagenPath ?? ''),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFf59e0b)),
                      );
                    },
                  ),
                ),

                if (isSelected)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),

                Positioned(
                  top: isZoomMode ? 12 : 9,
                  left: isZoomMode ? 12 : 9,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isZoomMode ? 10 : 8,
                      vertical: isZoomMode ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getColorPorTipo(articulo.tipoArticulo),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTipoDisplay(articulo.tipoArticulo),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isZoomMode ? baseFontSize : baseFontSize - 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // BOTONES SOLO EN MODO ZOOM
                if (isZoomMode)
                  Positioned(
                    top: isZoomMode ? 12 : 8,
                    right: isZoomMode ? 12 : 8,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // BOTÓN EDITAR
                            GestureDetector(
                              onTap: () {
                                print('✏️ Botón EDITAR presionado - ID: ${articulo.articuloId}');
                                if (onEdit != null) {
                                  onEdit();
                                } else {
                                  print('❌ ERROR: onEdit es null');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.edit, 
                                  color: Colors.blueAccent,
                                  size: isZoomMode ? 30 : 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // BOTÓN ELIMINAR
                            GestureDetector(
                              onTap: () {
                                print('🗑️ Botón ELIMINAR presionado - ID: ${articulo.articuloId}');
                                _mostrarDialogoEliminacion(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.delete, 
                                  color: Colors.red,
                                  size: isZoomMode ? 24 : 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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

  // ... (los demás métodos se mantienen igual: _mostrarDialogoEliminacion, _buildPlaceholder, etc.)
  void _mostrarDialogoEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a2235),
          title: const Text(
            'Confirmar Eliminación',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${articulo.categoriaNombre} - ${articulo.marcaNombre} - ${articulo.referencia}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                print('❌ Eliminación cancelada');
              },
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                print('✅ Confirmada eliminación de: ${articulo.articuloId}');
                if (onDelete != null) {
                  onDelete();
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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