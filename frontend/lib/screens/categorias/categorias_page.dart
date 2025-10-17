import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/catalogo_service.dart';
import '../../providers/auth_provider.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  List<Map<String, dynamic>> _catalogo = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    setState(() => _cargando = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final data = await CatalogoService.getCatalogo(token);
      setState(() => _catalogo = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarFormulario({Map<String, dynamic>? articulo}) async {
    final nombreController = TextEditingController(
      text: articulo?['nombre_articulo'] ?? '',
    );
    final stockController = TextEditingController(
      text: articulo?['stock_minimo']?.toString() ?? '',
    );
    final descripcionController = TextEditingController(
      text: articulo?['descripcion'] ?? '',
    );

    final isEdit = articulo != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEdit ? 'Editar artículo' : 'Nuevo artículo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del artículo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock mínimo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text(isEdit ? 'Actualizar' : 'Guardar'),
            onPressed: () async {
              final token =
                  Provider.of<AuthProvider>(context, listen: false).token!;
              final nuevoArticulo = {
                "id": articulo?['id'] ?? 0,
                "nombre_articulo": nombreController.text.trim(),
                "stock_minimo": int.tryParse(stockController.text) ?? 0,
                "descripcion": descripcionController.text.trim(),
              };
              try {
                await CatalogoService.guardarArticulo(nuevoArticulo, token);
                Navigator.pop(context);
                _cargarCatalogo();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit
                        ? 'Artículo actualizado exitosamente'
                        : 'Artículo creado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarArticulo(int id) async {
    final confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que deseas eliminar este artículo?'),
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
        await CatalogoService.eliminarArticulo(id, token);
        _cargarCatalogo();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artículo eliminado exitosamente'),
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
            : _catalogo.isEmpty
                ? Center(
                    child: Text(
                      'No hay artículos en el catálogo',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _catalogo.length,
                    itemBuilder: (context, index) {
                      final item = _catalogo[index];
                      return Card(
                        color: Colors.white.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            item['nombre_articulo'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Stock mínimo: ${item['stock_minimo']}\n${item['descripcion'] ?? 'Sin descripción'}',
                            style: GoogleFonts.poppins(),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueAccent),
                                onPressed: () =>
                                    _mostrarFormulario(articulo: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _eliminarArticulo(item['id']),
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
