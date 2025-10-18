import 'package:flutter/material.dart';
import 'package:frontend/utils/dialog_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/categorias_service.dart';
import '../../providers/auth_provider.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  List<Map<String, dynamic>> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _cargando = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final data = await CategoriasService.getCategorias(token);
      setState(() => _categorias = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar categorías: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarFormulario({Map<String, dynamic>? categoria}) async {
    final nombreController = TextEditingController(
      text: categoria?['nombre'] ?? '',
    );
    final stockController = TextEditingController(
      text: categoria?['stock_minimo']?.toString() ?? '',
    );
    final etiquetasController = TextEditingController(
      text: (categoria?['etiquetas'] != null)
          ? (categoria!['etiquetas'] as List).join(', ')
          : '',
    );

    final isEdit = categoria != null;

// Reemplaza todo el showDialog con:
final result = await DialogUtils.showCategoriaDialog(
  context: context,
  categoria: isEdit ? categoria : null,
  onGuardado: _cargarCategorias,
);
  }

  Future<void> _eliminarCategoria(int id) async {
    final confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que deseas eliminar esta categoría?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      try {
        await CategoriasService.eliminarCategoria(id, token);
        _cargarCategorias();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _categorias.isEmpty
                ? Center(
                    child: Text(
                      'No hay categorías registradas',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _categorias.length,
                    itemBuilder: (context, index) {
                      final item = _categorias[index];
                      final etiquetas = (item['etiquetas'] is List)
                          ? (item['etiquetas'] as List).join(', ')
                          : item['etiquetas']?.toString() ?? '';

                      return Card(
                        color: Colors.white.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            item['nombre'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Stock mínimo: ${item['stock_minimo']}\nEtiquetas: $etiquetas',
                            style: GoogleFonts.poppins(),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueAccent),
                                onPressed: () =>
                                    _mostrarFormulario(categoria: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _eliminarCategoria(item['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
