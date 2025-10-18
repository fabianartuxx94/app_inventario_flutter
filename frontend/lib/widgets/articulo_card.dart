import 'package:flutter/material.dart';
import '../models/articulo_model.dart';

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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a2235),
            Color(0xFF1e293b),
          ],
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
          // Header con imagen y botones de acción
          Stack(
            children: [
              // Imagen del artículo
              _buildImageSection(),
              
              // Overlay gradiente en la imagen
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        color: const Color(0xFF60a5fa),
                        onPressed: onEdit,
                        tooltip: 'Editar artículo',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16),
                        color: const Color(0xFFf87171),
                        onPressed: onDelete,
                        tooltip: 'Eliminar artículo',
                      ),
                    ],
                  ),
                ),
              ),

              // Badge de tipo en esquina superior izquierda
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorPorTipo(articulo.tipoArticulo).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTipoDisplay(articulo.tipoArticulo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marca y Referencia
                  Text(
                    articulo.referencia,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Marca
                  Text(
                    articulo.marcaNombre,
                    style: const TextStyle(
                      color: Color(0xFF94a3b8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Categoría
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        size: 12,
                        color: Color(0xFF94a3b8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          articulo.categoriaNombre,
                          style: const TextStyle(
                            color: Color(0xFF94a3b8),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Información de ubicación y stock
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Ubicación
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Color(0xFF94a3b8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${articulo.tipoBodega} • ${articulo.ubicacionBodega.isNotEmpty ? articulo.ubicacionBodega : 'Sin ubicación'}',
                                style: const TextStyle(
                                  color: Color(0xFF94a3b8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Stock mínimo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1e293b),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: articulo.stockMinimo > 0 
                                  ? const Color(0xFF10b981).withOpacity(0.3)
                                  : const Color(0xFFef4444).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 10,
                                color: articulo.stockMinimo > 0 
                                    ? const Color(0xFF10b981)
                                    : const Color(0xFFef4444),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: ${articulo.stockMinimo}',
                                style: TextStyle(
                                  color: articulo.stockMinimo > 0 
                                      ? const Color(0xFF10b981)
                                      : const Color(0xFFef4444),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

  Widget _buildImageSection() {
    final imageUrl = _buildImageUrl(articulo.imagenPath ?? '');
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2a2f40),
            Color(0xFF374151),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFFf59e0b),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderContent();
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            size: 32,
            color: const Color(0xFF94a3b8).withOpacity(0.7),
          ),
          const SizedBox(height: 4),
          Text(
            articulo.categoriaNombre,
            style: TextStyle(
              color: const Color(0xFF94a3b8).withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _buildImageUrl(String imagenPath) {
    if (imagenPath.isEmpty) {
      return _getPlaceholderImage(articulo.categoriaNombre);
    }
    
    // Si la imagen ya es una URL completa, úsala
    if (imagenPath.startsWith('http')) {
      return imagenPath;
    }
    
    // Si es una ruta relativa, construye la URL completa
    // CAMBIA 'http://localhost:3000' por tu dominio real
    final baseUrl = 'http://localhost:3000'; // o 'https://tu-dominio.com'
    
    // Remover slash inicial si existe
    final cleanPath = imagenPath.startsWith('/') ? imagenPath.substring(1) : imagenPath;
    
    return '$baseUrl/$cleanPath';
  }

  String _getPlaceholderImage(String categoria) {
    // Solo usar placeholder si no hay imagen real
    return 'https://images.unsplash.com/photo-1556656793-08538906a9f8?w=400&h=300&fit=crop';
  }

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