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
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarFormulario({Map<String, dynamic>? articulo}) async {
    final nombreController =
        TextEditingController(text: articulo?['nombre_articulo'] ?? '');
    final stockController = TextEditingController(
        text: articulo?['stock_minimo']?.toString() ?? '');
    final descripcionController =
        TextEditingController(text: articulo?['descripcion'] ?? '');

    final isEdit = articulo != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar artículo' : 'Nuevo artículo'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock mínimo'),
                keyboardType: TextInputType.number,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nuevoArticulo = {
                "id": articulo?['id'] ?? 0,
                "nombre_articulo": nombreController.text.trim(),
                "stock_minimo": int.tryParse(stockController.text) ?? 0,
                "descripcion": descripcionController.text.trim(),
              };
              try {
                await CatalogoService.guardarArticulo(
                    nuevoArticulo, widget.token);
                if (!mounted) return;
                Navigator.pop(context);
                _cargarCatalogo();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(isEdit ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarArticulo(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar artículo?'),
        content: const Text('Esta acción no se puede deshacer.'),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Stack(
        children: [
          const CustomBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Catálogo de Artículos',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isDesktop)
                        ElevatedButton.icon(
                          onPressed: () => _mostrarFormulario(),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _cargando
                        ? const Center(child: CircularProgressIndicator())
                        : _catalogo.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay artículos cargados',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _cargarCatalogo,
                                child: isDesktop
                                    ? _buildGridView()
                                    : _buildListView(),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _mostrarFormulario(),
              label: const Text('Agregar'),
              icon: const Icon(Icons.add),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _catalogo.length,
      itemBuilder: (context, index) {
        final item = _catalogo[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.white.withOpacity(0.9),
          child: ListTile(
            title: Text(
              item['nombre_articulo'],
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Stock mínimo: ${item['stock_minimo']}\n${item['descripcion']}',
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _mostrarFormulario(articulo: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarArticulo(item['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      itemCount: _catalogo.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 3,
      ),
      itemBuilder: (context, index) {
        final item = _catalogo[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.inventory, size: 40, color: Colors.blueAccent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['nombre_articulo'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text('Stock mínimo: ${item['stock_minimo']}'),
                    Text(item['descripcion']),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _mostrarFormulario(articulo: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarArticulo(item['id']),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

