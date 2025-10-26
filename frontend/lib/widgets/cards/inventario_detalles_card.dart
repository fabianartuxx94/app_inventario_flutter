import 'package:flutter/material.dart';
import '../../../models/inventario_model.dart';

class InventarioDetallesCard extends StatelessWidget {
  final Inventario inventario;
  final bool isAdmin;
  final VoidCallback? onEditar;
  final VoidCallback? onVerHistorial;
  final VoidCallback onCerrar;

  const InventarioDetallesCard({
    super.key,
    required this.inventario,
    required this.isAdmin,
    this.onEditar,
    this.onVerHistorial,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onCerrar,
        child: Container(
          color: Colors.black54,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: isMobile
                    ? MediaQuery.of(context).size.width * 0.95
                    : MediaQuery.of(context).size.width * 0.8,
                height: isMobile
                    ? MediaQuery.of(context).size.height * 0.85
                    : MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildDetallesCompletos(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Detalles del Inventario',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        Row(
          children: [
            if (isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.green),
                onPressed: onEditar,
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.orange),
                onPressed: onVerHistorial,
                tooltip: 'Ver historial',
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: onCerrar,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetallesCompletos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información detallada en el orden solicitado
        _buildDetalleItem('Categoría', inventario.categoriaNombre),
        _buildDetalleItem('Marca', inventario.marcaNombre ?? 'N/A'),
        _buildDetalleItem('Referencia', inventario.articuloReferencia),
        _buildDetalleItem('Placa', inventario.placa ?? 'N/A'),
        _buildDetalleItem('Serial', inventario.serial ?? 'N/A'),
        _buildDetalleItem('Descripción', 
            inventario.articuloDescripcion.isNotEmpty ? inventario.articuloDescripcion : 'N/A'),
        _buildDetalleItem('Tipo Bodega', inventario.tipoBodega),
        _buildDetalleItem('Tipo Artículo', inventario.tipoArticulo),
        _buildDetalleItem('Estado', inventario.estado),
        _buildDetalleItem('Cantidad', inventario.cantidad.toString()),
        _buildDetalleItem('Bodega', inventario.bodega),
        _buildDetalleItem('Ubicación Detallada', inventario.ubicacionDetallada ?? 'N/A'),
        
        const SizedBox(height: 20),
        _buildEstadoChip(inventario.estado),
      ],
    );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    switch (estado) {
      case 'Nuevo':
        color = Colors.green;
        break;
      case 'Bueno':
        color = Colors.blue;
        break;
      case 'Reparacion':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}