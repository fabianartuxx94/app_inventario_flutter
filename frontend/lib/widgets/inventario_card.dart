import 'package:flutter/material.dart';
import '../models/inventario_model.dart';

class InventarioCard extends StatelessWidget {
  final Inventario inventario;
  final bool isAdmin;
  final VoidCallback onVerDetalles;
  final VoidCallback onEditar;
  final VoidCallback onVerHistorial;

  const InventarioCard({
    Key? key,
    required this.inventario,
    required this.isAdmin,
    required this.onVerDetalles,
    required this.onEditar,
    required this.onVerHistorial,
  }) : super(key: key);

  // Concatenar categoría + marca + referencia
  String _getTituloItem(Inventario item) {
    List<String> partes = [];
    if (item.categoriaNombre.isNotEmpty) partes.add(item.categoriaNombre);
    if (item.marcaNombre != null && item.marcaNombre!.isNotEmpty) partes.add(item.marcaNombre!);
    if (item.articuloReferencia.isNotEmpty) partes.add(item.articuloReferencia);
    return partes.join(' ');
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    switch (estado) {
      case 'Nuevo':
        color = Colors.blue;
        break;
      case 'Bueno':
        color = Colors.green;
        break;
      case 'Reparacion':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEstadoChip(inventario.estado),
                Text(
                  'Cant: ${inventario.cantidad}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Título concatenado
            Text(
              _getTituloItem(inventario),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            
            // Información resumida
            _buildInfoItem('Placa', inventario.placa ?? 'N/A'),
            _buildInfoItem('Serial', inventario.serial ?? 'N/A'),
            _buildInfoItem('Tipo', inventario.tipoArticulo),
            _buildInfoItem('Bodega', inventario.bodega),
            
            const Spacer(),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18, color: Colors.blue),
                  onPressed: onVerDetalles,
                  tooltip: 'Ver detalles',
                ),
                if (isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.green),
                    onPressed: onEditar,
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, size: 18, color: Colors.orange),
                    onPressed: onVerHistorial,
                    tooltip: 'Ver historial',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}