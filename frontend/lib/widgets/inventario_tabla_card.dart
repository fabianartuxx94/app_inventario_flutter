import 'package:flutter/material.dart';
import '../../models/inventario_model.dart';

class InventarioTablaCard extends StatelessWidget {
  final List<Inventario> inventarios;
  final bool isAdmin;
  final VoidCallback onVerDetalles;
  final VoidCallback onEditar;
  final VoidCallback onVerMovimientos;
  final Function(Inventario) onVerDetallesInventario;

  const InventarioTablaCard({
    super.key,
    required this.inventarios,
    required this.isAdmin,
    required this.onVerDetalles,
    required this.onEditar,
    required this.onVerMovimientos,
    required this.onVerDetallesInventario,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color.fromARGB(214, 255, 255, 255),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        child: _buildScrollableTable(),
      ),
    );
  }

  Widget _buildScrollableTable() {
    // Ancho total suficiente para todas las columnas
    const totalTableWidth = 1600.0;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: totalTableWidth,
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 12,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 70,
            headingTextStyle: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
            dataTextStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.2,
            ),
            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
            columns: const [
              DataColumn(label: SizedBox(width: 140, child: Text('Categoría'))),
              DataColumn(label: SizedBox(width: 120, child: Text('Marca'))),
              DataColumn(label: SizedBox(width: 140, child: Text('Referencia'))),
              DataColumn(label: SizedBox(width: 200, child: Text('Descripción'))),
              DataColumn(label: SizedBox(width: 100, child: Text('Placa'))),
              DataColumn(label: SizedBox(width: 120, child: Text('Serial'))),
              DataColumn(label: SizedBox(width: 100, child: Text('Tipo'))),
              DataColumn(label: SizedBox(width: 100, child: Text('Estado'))),
              DataColumn(
                label: SizedBox(width: 80, child: Text('Cantidad')),
                numeric: true,
              ),
              DataColumn(label: SizedBox(width: 120, child: Text('Bodega'))),
              DataColumn(label: SizedBox(width: 140, child: Text('Acciones'))),
            ],
            rows: inventarios.map((registro) {
              return DataRow(
                cells: [
                  _buildDataCell(registro.categoriaNombre, 140),
                  _buildDataCell(registro.marcaNombre ?? 'N/A', 120),
                  _buildDataCell(registro.articuloReferencia, 140),
                  _buildDataCell(_acortarDescripcion(registro.articuloDescripcion), 200),
                  _buildDataCell(registro.placa ?? 'N/A', 100),
                  _buildDataCell(registro.serial ?? 'N/A', 120),
                  _buildDataCell(registro.tipoArticulo, 100),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: _buildEstadoChip(registro.estado),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: Center(
                        child: Text(
                          registro.cantidad.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildDataCell(registro.bodega, 120),
                  DataCell(
                    SizedBox(
                      width: 140,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Botón Detalles
                          IconButton(
                            icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                            onPressed: () => onVerDetallesInventario(registro),
                            tooltip: 'Ver detalles',
                            padding: const EdgeInsets.all(4),
                          ),
                          // Botón Editar (solo admin)
                          if (isAdmin) 
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.green),
                              onPressed: onEditar,
                              tooltip: 'Editar',
                              padding: const EdgeInsets.all(4),
                            ),
                          // Botón Movimientos (solo admin)
                          if (isAdmin)
                            IconButton(
                              icon: const Icon(Icons.history, size: 20, color: Colors.orange),
                              onPressed: onVerMovimientos,
                              tooltip: 'Ver movimientos',
                              padding: const EdgeInsets.all(4),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataCell _buildDataCell(String text, double width) {
    return DataCell(
      Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: text,
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  String _acortarDescripcion(String descripcion) {
    if (descripcion.length > 35) {
      return '${descripcion.substring(0, 35)}...';
    }
    return descripcion;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        estado,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}