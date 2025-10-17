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
    return Card(
      color: const Color(0xFF1a2235),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen del artículo
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF474554),
                    image: articulo.imagenPath.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(articulo.imagenCompletaUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: articulo.imagenPath.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.inventory_2,
                            size: 40,
                            color: Color(0xFFaca9bb),
                          ),
                        )
                      : null,
                ),
              ),

              // Botones de acción
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        color: Colors.blue,
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16),
                        color: Colors.red,
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marca y Referencia
                  Text(
                    '${articulo.marca} ${articulo.referencia}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Tipo y Bodega
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildChip(
                        label: articulo.tipoDisplay,
                        color: _getColorPorTipo(articulo.tipo),
                      ),
                      _buildChip(
                        label: articulo.tipoBodega,
                        color: _getColorPorBodega(articulo.tipoBodega),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Descripción
                  Expanded(
                    child: Text(
                      articulo.descripcionCatalogo.isNotEmpty
                          ? articulo.descripcionCatalogo
                          : 'Sin descripción',
                      style: const TextStyle(
                        color: Color(0xFFaca9bb),
                        fontSize: 11,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getColorPorTipo(String tipo) {
    switch (tipo) {
      case 'activo_fijo':
        return const Color(0xFF10b981); // Verde
      case 'activo_control':
        return const Color(0xFFf59e0b); // Amarillo
      case 'consumible':
        return const Color(0xFFef4444); // Rojo
      default:
        return const Color(0xFF6b7280); // Gris
    }
  }

  Color _getColorPorBodega(String bodega) {
    switch (bodega) {
      case 'Sistemas':
        return const Color(0xFF0948d6); // Azul
      case 'Bmd':
        return const Color(0xFF8b5cf6); // Púrpura
      default:
        return const Color(0xFF6b7280); // Gris
    }
  }
}
