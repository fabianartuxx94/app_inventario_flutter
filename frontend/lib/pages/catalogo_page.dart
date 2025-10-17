import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/catalogo_service.dart';
import '../widgets/custom_background.dart';

class CatalogoPage extends StatefulWidget {
  final String token;
  const CatalogoPage({super.key, required this.token});

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
    try {
      final data = await CatalogoService.getCatalogo(widget.token);
      setState(() => _catalogo = data);
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        backgroundColor: Colors.white,
        title: Text(
          isEdit ? 'Editar artículo' : 'Nuevo artículo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del artículo',
                ),
              ),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock mínimo'),
              ),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
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
              final nuevoArticulo = {
                "id": articulo?['id'] ?? 0,
                "nombre_articulo": nombreController.text.trim(),
                "stock_minimo": int.tryParse(stockController.text) ?? 0,
                "descripcion": descripcionController.text.trim(),
              };
              try {
                await CatalogoService.guardarArticulo(
                  nuevoArticulo,
                  widget.token,
                );
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _cargarCatalogo();
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(
                  // ignore: use_build_context_synchronously
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await CatalogoService.eliminarArticulo(id, widget.token);
        _cargarCatalogo();
      } catch (e) {
        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CustomBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Catálogo de Artículos',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _cargarCatalogo,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _catalogo.length,
                            itemBuilder: (context, index) {
                              final item = _catalogo[index];
                              return Card(
                                // ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    item['nombre_articulo'],
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Stock mínimo: ${item['stock_minimo']}\n${item['descripcion']}',
                                  ),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blueAccent,
                                        ),
                                        onPressed: () =>
                                            _mostrarFormulario(articulo: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _eliminarArticulo(item['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        label: const Text('Agregar', style: TextStyle(color: Colors.black)),
        icon: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _mostrarFormulario(),
      ),
    );
  }
}
