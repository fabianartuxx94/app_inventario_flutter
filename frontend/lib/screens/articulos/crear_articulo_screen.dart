import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/articulo_model.dart';
import '../../services/articulos_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/image_uploader.dart';
import '../../widgets/custom_background.dart';
import '../../providers/auth_provider.dart';

class CrearArticuloScreen extends StatefulWidget {
  final VoidCallback? onArticuloCreado;
  final VoidCallback? onCancelar;

  const CrearArticuloScreen({
    super.key,
    this.onArticuloCreado,
    this.onCancelar,
  });

  @override
  State<CrearArticuloScreen> createState() => _CrearArticuloScreenState();
}

class _CrearArticuloScreenState extends State<CrearArticuloScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenciaController = TextEditingController();
  final _ubicacionBodegaController = TextEditingController();

  String _tipoBodega = 'Sistemas';
  String _tipoArticulo = 'Activo Fijo';
  File? _imagenSeleccionada;
  bool _isLoading = false;
  bool _cargandoCategorias = true;
  bool _cargandoMarcas = true;

  // Listas para dropdowns
  List<dynamic> _categorias = [];
  List<dynamic> _marcas = [];
  
  // Valores seleccionados
  int? _categoriaId;
  int? _marcaId;
  
  // Búsqueda de categorías
  final TextEditingController _categoriaSearchController = TextEditingController();
  List<dynamic> _categoriasFiltradas = [];
  bool _mostrarCrearCategoria = false;
  bool _mostrarListaCategorias = false;

  // Búsqueda de marcas
  final TextEditingController _marcaSearchController = TextEditingController();
  List<dynamic> _marcasFiltradas = [];
  bool _mostrarCrearMarca = false;
  bool _mostrarListaMarcas = false;

  final List<Map<String, String>> _tiposArticulo = [
    {'value': 'Activo Fijo', 'label': 'Activo Fijo'},
    {'value': 'Activo de Control', 'label': 'Activo de Control'},
    {'value': 'Consumible', 'label': 'Consumible'},
  ];

  final List<String> _bodegas = ['Sistemas', 'Bmd'];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    _categoriaSearchController.addListener(_filtrarCategorias);
    _marcaSearchController.addListener(_filtrarMarcas);
  }

  @override
  void dispose() {
    _categoriaSearchController.dispose();
    _marcaSearchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final categorias = await ArticuloService.obtenerCategorias(token);
      final marcas = await ArticuloService.obtenerMarcas(token);
      
      setState(() {
        _categorias = categorias;
        _marcas = marcas;
        _categoriasFiltradas = [];
        _marcasFiltradas = [];
        _cargandoCategorias = false;
        _cargandoMarcas = false;
      });
    } catch (e) {
      setState(() {
        _cargandoCategorias = false;
        _cargandoMarcas = false;
      });
      _mostrarError('Error al cargar datos: $e');
    }
  }

  // MÉTODOS FALTANTES - AGREGAR AQUÍ

  String _getNombreCategoria() {
    if (_categoriaId == null) return '';
    try {
      final categoria = _categorias.firstWhere(
        (c) => (c['id'] as int) == _categoriaId,
      );
      return categoria['nombre']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getNombreMarca() {
    if (_marcaId == null) return '';
    try {
      final marca = _marcas.firstWhere(
        (m) => (m['id'] as int) == _marcaId,
      );
      return marca['nombre']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  void _crearNuevaCategoria() async {
    final nombreCategoria = _categoriaSearchController.text.trim();
    if (nombreCategoria.isEmpty) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      
      final Map<String, dynamic> nuevaCategoria = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'nombre': nombreCategoria,
        'stock_minimo': 0,
        'etiquetas': '[]'
      };

      setState(() {
        _categorias.insert(0, nuevaCategoria);
        _categoriaId = nuevaCategoria['id'] as int;
        _categoriaSearchController.text = nombreCategoria;
        _mostrarCrearCategoria = false;
        _mostrarListaCategorias = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Categoría "$nombreCategoria" creada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _mostrarError('Error al crear categoría: $e');
    }
  }

  void _crearNuevaMarca() async {
    final nombreMarca = _marcaSearchController.text.trim();
    if (nombreMarca.isEmpty) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      
      final Map<String, dynamic> nuevaMarca = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'nombre': nombreMarca,
      };

      setState(() {
        _marcas.insert(0, nuevaMarca);
        _marcaId = nuevaMarca['id'] as int;
        _marcaSearchController.text = nombreMarca;
        _mostrarCrearMarca = false;
        _mostrarListaMarcas = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Marca "$nombreMarca" creada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _mostrarError('Error al crear marca: $e');
    }
  }

  void _filtrarCategorias() {
    final query = _categoriaSearchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _categoriasFiltradas = [];
        _mostrarCrearCategoria = false;
        _mostrarListaCategorias = false;
      });
      return;
    }

    final categoriasFiltradas = _categorias.where((categoria) {
      final nombre = categoria['nombre'].toString().toLowerCase();
      return nombre.contains(query);
    }).toList();

    final existeCategoria = _categorias.any((categoria) =>
        categoria['nombre'].toString().toLowerCase() == query);

    setState(() {
      _categoriasFiltradas = categoriasFiltradas;
      _mostrarCrearCategoria = !existeCategoria && query.isNotEmpty;
      _mostrarListaCategorias = true;
    });
  }

  void _filtrarMarcas() {
    final query = _marcaSearchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _marcasFiltradas = [];
        _mostrarCrearMarca = false;
        _mostrarListaMarcas = false;
      });
      return;
    }

    final marcasFiltradas = _marcas.where((marca) {
      final nombre = marca['nombre'].toString().toLowerCase();
      return nombre.contains(query);
    }).toList();

    final existeMarca = _marcas.any((marca) =>
        marca['nombre'].toString().toLowerCase() == query);

    setState(() {
      _marcasFiltradas = marcasFiltradas;
      _mostrarCrearMarca = !existeMarca && query.isNotEmpty;
      _mostrarListaMarcas = true;
    });
  }

  Future<void> _crearArticulo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      _mostrarError('Por favor selecciona una categoría');
      return;
    }
    if (_marcaId == null) {
      _mostrarError('Por favor selecciona una marca');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      String? imagenUrl;

      if (_imagenSeleccionada != null) {
        final nombreCategoria = _getNombreCategoria();
        final nombreMarca = _getNombreMarca();
        
        final uploadResult = await UploadService.uploadImage(
          _imagenSeleccionada!,
          token,
          nombreArticulo: nombreCategoria,
          marca: nombreMarca,
          referencia: _referenciaController.text.trim(),
        );
        if (uploadResult['success']) {
          imagenUrl = uploadResult['imageUrl'];
        }
      }

      final nuevoArticulo = Articulo(
        categoriaId: _categoriaId!,
        categoriaNombre: _getNombreCategoria(),
        marcaId: _marcaId!,
        marcaNombre: _getNombreMarca(),
        referencia: _referenciaController.text.trim(),
        tipoBodega: _tipoBodega,
        tipoArticulo: _tipoArticulo,
        ubicacionBodega: _ubicacionBodegaController.text.trim(),
        imagenPath: imagenUrl,
        stockMinimo: 0,
        etiquetas: '[]',
      );

      final resultado = await ArticuloService.crearArticulo(nuevoArticulo, token);
      
      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${resultado['message']}'), 
            backgroundColor: Colors.green
          ),
        );
        
        if (widget.onArticuloCreado != null) {
          widget.onArticuloCreado!();
        }
      } else {
        _mostrarError(resultado['error'] ?? 'Error al crear el artículo');
      }
    } catch (e) {
      _mostrarError('Error al crear artículo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  // FIN DE MÉTODOS FALTANTES

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Stack(
      children: [
        const CustomBackground(),
        
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con botón de volver
              _buildHeader(),
              const SizedBox(height: 20),
              
              Expanded(
                child: _cargandoCategorias || _cargandoMarcas || _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFf59e0b)),
                      )
                    : SingleChildScrollView(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Card(
                              color: const Color(0xFF1a1f2e).withOpacity(0.9),
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      ImageUploader(
                                        onImageSelected: (imageFile) {
                                          setState(() => _imagenSeleccionada = imageFile);
                                        },
                                        nombreArticulo: _getNombreCategoria(),
                                        marca: _getNombreMarca(),
                                        referencia: _referenciaController.text,
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Wrap(
                                            spacing: 16,
                                            runSpacing: 16,
                                            children: [
                                              // Búsqueda de categoría
                                              SizedBox(
                                                width: isWide ? constraints.maxWidth / 2 - 20 : double.infinity,
                                                child: _buildCategoriaSearch(),
                                              ),
                                              // Búsqueda de marca
                                              SizedBox(
                                                width: isWide ? constraints.maxWidth / 2 - 20 : double.infinity,
                                                child: _buildMarcaSearch(),
                                              ),
                                              // Referencia
                                              SizedBox(
                                                width: isWide ? constraints.maxWidth / 2 - 20 : double.infinity,
                                                child: _buildTextField(
                                                  controller: _referenciaController,
                                                  label: 'Referencia *',
                                                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                                                ),
                                              ),
                                              // Ubicación en bodega
                                              SizedBox(
                                                width: isWide ? constraints.maxWidth / 2 - 20 : double.infinity,
                                                child: _buildTextField(
                                                  controller: _ubicacionBodegaController,
                                                  label: 'Ubicación en Bodega *',
                                                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                                                ),
                                              ),
                                              // Tipo de artículo
                                              SizedBox(
                                                width: isWide ? constraints.maxWidth / 2 - 20 : double.infinity,
                                                child: _buildDropdown(
                                                  value: _tipoArticulo,
                                                  label: 'Tipo de Artículo *',
                                                  items: _tiposArticulo,
                                                  onChanged: (v) => setState(() => _tipoArticulo = v!),
                                                ),
                                              ),
                                              // Bodega
                                              SizedBox(
                                                width: isWide ? constraints.maxWidth / 2 - 20 : double.infinity,
                                                child: _buildDropdown(
                                                  value: _tipoBodega,
                                                  label: 'Bodega *',
                                                  items: _bodegas.map((b) => {'value': b, 'label': b}).toList(),
                                                  onChanged: (v) => setState(() => _tipoBodega = v!),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      
                                      // Botones de acción
                                      _buildActionButtons(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onCancelar ?? () {},
          tooltip: 'Volver a la lista',
        ),
        const SizedBox(width: 8),
        Text(
          'Crear Artículo',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onCancelar,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _crearArticulo,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(
              _isLoading ? 'Creando...' : 'Crear Artículo',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf59e0b),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriaSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría *',
          style: TextStyle(
            color: Color(0xFFaca9bb),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Column(
          children: [
            TextFormField(
              controller: _categoriaSearchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar categoría...',
                hintStyle: const TextStyle(color: Color(0xFF6b7280)),
                filled: true,
                fillColor: const Color(0xFF2a2f40),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF474554)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0948d6), width: 2),
                ),
                suffixIcon: _categoriaSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _categoriaSearchController.clear();
                          setState(() {
                            _categoriaId = null;
                            _mostrarCrearCategoria = false;
                            _mostrarListaCategorias = false;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                _filtrarCategorias();
              },
            ),
            
            const SizedBox(height: 8),
            
            // Solo mostrar lista si hay búsqueda activa
            if (_mostrarListaCategorias && (_categoriasFiltradas.isNotEmpty || _mostrarCrearCategoria))
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2a2f40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF474554)),
                ),
                child: Column(
                  children: [
                    // Opción de crear nueva categoría
                    if (_mostrarCrearCategoria)
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                        title: Text(
                          'Crear "${_categoriaSearchController.text}"',
                          style: const TextStyle(color: Colors.green, fontSize: 14),
                        ),
                        onTap: _crearNuevaCategoria,
                      ),
                    
                    // Lista de categorías filtradas
                    ..._categoriasFiltradas.map((categoria) {
                      return ListTile(
                        title: Text(
                          categoria['nombre'],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        onTap: () {
                          setState(() {
                            _categoriaId = categoria['id'] as int;
                            _categoriaSearchController.text = categoria['nombre'];
                            _mostrarCrearCategoria = false;
                            _mostrarListaCategorias = false;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarcaSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Marca *',
          style: TextStyle(
            color: Color(0xFFaca9bb),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Column(
          children: [
            TextFormField(
              controller: _marcaSearchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar marca...',
                hintStyle: const TextStyle(color: Color(0xFF6b7280)),
                filled: true,
                fillColor: const Color(0xFF2a2f40),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF474554)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0948d6), width: 2),
                ),
                suffixIcon: _marcaSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _marcaSearchController.clear();
                          setState(() {
                            _marcaId = null;
                            _mostrarCrearMarca = false;
                            _mostrarListaMarcas = false;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                _filtrarMarcas();
              },
            ),
            
            const SizedBox(height: 8),
            
            // Solo mostrar lista si hay búsqueda activa
            if (_mostrarListaMarcas && (_marcasFiltradas.isNotEmpty || _mostrarCrearMarca))
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2a2f40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF474554)),
                ),
                child: Column(
                  children: [
                    // Opción de crear nueva marca
                    if (_mostrarCrearMarca)
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                        title: Text(
                          'Crear "${_marcaSearchController.text}"',
                          style: const TextStyle(color: Colors.green, fontSize: 14),
                        ),
                        onTap: _crearNuevaMarca,
                      ),
                    
                    // Lista de marcas filtradas
                    ..._marcasFiltradas.map((marca) {
                      return ListTile(
                        title: Text(
                          marca['nombre'],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        onTap: () {
                          setState(() {
                            _marcaId = marca['id'] as int;
                            _marcaSearchController.text = marca['nombre'];
                            _mostrarCrearMarca = false;
                            _mostrarListaMarcas = false;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFaca9bb),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2a2f40),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF474554)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0948d6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<Map<String, String>> items,
    required String label,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFaca9bb),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF2d3748),
          style: const TextStyle(color: Colors.white),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(item['label']!),
            );
          }).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2a2f40),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF474554)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) => value == null ? 'Campo requerido' : null,
        ),
      ],
    );
  }
}