import 'package:flutter/material.dart';
import 'package:frontend/services/marcas_service.dart';
import 'package:frontend/widgets/cards/categoria_dialog.dart';
import 'package:provider/provider.dart';
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
  final _descripcionController = TextEditingController();

  // ✅ CORREGIDO: Variables de estado definidas correctamente
  String _tipoBodega = 'Sistemas';
  String _tipoArticulo = 'Activo Fijo';
  bool _esActivo = true; // ✅ CORREGIDO: Variable faltante definida
  dynamic _imagenSeleccionada;
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

  // ✅ OPTIMIZADO: Constantes para listas estáticas
  static const List<Map<String, String>> _tiposArticulo = [
    {'value': 'Activo Fijo', 'label': 'Activo Fijo'},
    {'value': 'Activo de Control', 'label': 'Activo de Control'},
    {'value': 'Consumible', 'label': 'Consumible'},
  ];

  static const List<String> _bodegas = ['Sistemas', 'Bmd'];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    _categoriaSearchController.addListener(_filtrarCategorias);
    _marcaSearchController.addListener(_filtrarMarcas);
  }

  @override
  void dispose() {
    _referenciaController.dispose();
    _categoriaSearchController.dispose();
    _marcaSearchController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // ✅ OPTIMIZADO: Método único para cargar datos
  Future<void> _cargarDatosIniciales() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      
      // ✅ OPTIMIZADO: Carga paralela de categorías y marcas
      final futures = await Future.wait([
        ArticuloService.obtenerCategorias(token),
        ArticuloService.obtenerMarcas(token),
      ]);

      setState(() {
        _categorias = futures[0];
        _marcas = futures[1];
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
      _mostrarError('Error al cargar datos iniciales: $e');
    }
  }

  // ✅ OPTIMIZADO: Método reutilizable para buscar en listas
  String _obtenerNombreDeLista(List<dynamic> lista, int? id, String campoNombre) {
    if (id == null) return '';
    try {
      final elemento = lista.firstWhere(
        (elemento) => (elemento['id'] as int) == id,
        orElse: () => {},
      );
      return elemento.isNotEmpty ? elemento[campoNombre]?.toString() ?? '' : '';
    } catch (e) {
      return '';
    }
  }

  String _getNombreCategoria() => _obtenerNombreDeLista(_categorias, _categoriaId, 'nombre');
  String _getNombreMarca() => _obtenerNombreDeLista(_marcas, _marcaId, 'nombre');

  Future<void> _crearNuevaCategoria() async {
    final nombreCategoria = _categoriaSearchController.text.trim();
    if (nombreCategoria.isEmpty) return;

    final existeCategoria = _categorias.any((categoria) =>
        categoria['nombre'].toString().toLowerCase() == nombreCategoria.toLowerCase());

    if (existeCategoria) {
      _seleccionarElementoExistente(_categorias, nombreCategoria, 'nombre', (id) {
        _categoriaId = id;
      }, _categoriaSearchController);
    } else {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CategoriaDialog(
          categoria: null, 
          nombrePredefinido: nombreCategoria,
          onGuardado: _cargarDatosIniciales,
        ),
      );

      if (result != null && result['nombre'] != null) {
        await _procesarElementoCreado(result['nombre']!, _categorias, 'nombre', (id) {
          _categoriaId = id;
        }, _categoriaSearchController);
      }
    }
  }

  Future<void> _crearNuevaMarca() async {
    final nombreMarca = _marcaSearchController.text.trim();
    if (nombreMarca.isEmpty) return;

    final existeMarca = _marcas.any((marca) =>
        marca['nombre'].toString().toLowerCase() == nombreMarca.toLowerCase());

    if (existeMarca) {
      _seleccionarElementoExistente(_marcas, nombreMarca, 'nombre', (id) {
        _marcaId = id;
      }, _marcaSearchController);
    } else {
      final confirmarCreacion = await _mostrarDialogoConfirmacion(
        'Crear Nueva Marca',
        '¿Estás seguro de que quieres crear la marca "$nombreMarca"?',
      );

      if (confirmarCreacion == true) {
        await _crearMarcaEnServidor(nombreMarca);
      }
    }
  }

  // ✅ OPTIMIZADO: Métodos auxiliares reutilizables
  void _seleccionarElementoExistente(
    List<dynamic> lista,
    String nombre,
    String campoNombre,
    Function(int) onSeleccionado,
    TextEditingController controller,
  ) {
    final elementoExistente = lista.firstWhere(
      (elemento) => elemento[campoNombre].toString().toLowerCase() == nombre.toLowerCase(),
    );
    
    setState(() {
      onSeleccionado(elementoExistente['id'] as int);
      controller.text = elementoExistente[campoNombre];
      _mostrarCrearCategoria = false;
      _mostrarListaCategorias = false;
    });
    
    _mostrarSnackBar('✅ $nombre seleccionado', Colors.blue);
  }

  Future<void> _procesarElementoCreado(
    String nombre,
    List<dynamic> lista,
    String campoNombre,
    Function(int) onSeleccionado,
    TextEditingController controller,
  ) async {
    setState(() {
      controller.text = nombre;
      _mostrarCrearCategoria = false;
      _mostrarListaCategorias = false;
    });
    
    await _cargarDatosIniciales();
    
    final nuevoElemento = lista.firstWhere(
      (elemento) => elemento[campoNombre] == nombre,
      orElse: () => {},
    );
    
    if (nuevoElemento.isNotEmpty) {
      setState(() {
        onSeleccionado(nuevoElemento['id'] as int);
      });
    }
  }

  Future<bool?> _mostrarDialogoConfirmacion(String titulo, String contenido) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(contenido),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFf59e0b)),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearMarcaEnServidor(String nombreMarca) async {
    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final marcaData = {"nombre": nombreMarca};

      final resultado = await MarcasService.guardarMarca(marcaData, token);
      
      if (resultado['success'] == true) {
        await _recargarMarcas();
        await _procesarElementoCreado(nombreMarca, _marcas, 'nombre', (id) {
          _marcaId = id;
        }, _marcaSearchController);
        
        _mostrarSnackBar('✅ Marca "$nombreMarca" creada exitosamente', Colors.green);
      } else {
        _mostrarError(resultado['error'] ?? 'Error al crear la marca');
      }
    } catch (e) {
      _mostrarError('Error al crear marca: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ OPTIMIZADO: Método único para filtrar listas
  void _filtrarLista({
    required String query,
    required List<dynamic> listaCompleta,
    required Function(List<dynamic>) onFiltrado,
    required Function(bool) onMostrarCrear,
    required Function(bool) onMostrarLista,
    required String campoNombre,
  }) {
    if (query.isEmpty) {
      onFiltrado([]);
      onMostrarCrear(false);
      onMostrarLista(false);
      return;
    }

    final elementosFiltrados = listaCompleta.where((elemento) {
      final nombre = elemento[campoNombre].toString().toLowerCase();
      return nombre.contains(query.toLowerCase());
    }).toList();

    final existeElemento = listaCompleta.any((elemento) =>
        elemento[campoNombre].toString().toLowerCase() == query.toLowerCase());

    onFiltrado(elementosFiltrados);
    onMostrarCrear(!existeElemento && query.isNotEmpty);
    onMostrarLista(true);
  }

  void _filtrarCategorias() {
    _filtrarLista(
      query: _categoriaSearchController.text,
      listaCompleta: _categorias,
      onFiltrado: (filtradas) => setState(() => _categoriasFiltradas = filtradas),
      onMostrarCrear: (mostrar) => setState(() => _mostrarCrearCategoria = mostrar),
      onMostrarLista: (mostrar) => setState(() => _mostrarListaCategorias = mostrar),
      campoNombre: 'nombre',
    );
  }

  void _filtrarMarcas() {
    _filtrarLista(
      query: _marcaSearchController.text,
      listaCompleta: _marcas,
      onFiltrado: (filtradas) => setState(() => _marcasFiltradas = filtradas),
      onMostrarCrear: (mostrar) => setState(() => _mostrarCrearMarca = mostrar),
      onMostrarLista: (mostrar) => setState(() => _mostrarListaMarcas = mostrar),
      campoNombre: 'nombre',
    );
  }

  Future<void> _recargarMarcas() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final marcas = await ArticuloService.obtenerMarcas(token);
      setState(() => _marcas = marcas);
    } catch (e) {
      print('Error al recargar marcas: $e');
    }
  }

  // ✅ CORREGIDO: Incluye todos los campos del modelo Articulo
  Future<void> _crearArticulo() async {
    if (!_formKey.currentState!.validate()) return;
    
    // ✅ CORREGIDO: Validaciones completas
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

      // Subir imagen si existe
      if (_imagenSeleccionada != null) {
        final uploadResult = await UploadService.uploadImage(
          _imagenSeleccionada!,
          token,
          nombreArticulo: _getNombreCategoria(),
          marca: _getNombreMarca(),
          referencia: _referenciaController.text.trim(),
        );
        if (uploadResult['success']) {
          imagenUrl = uploadResult['imageUrl'];
        }
      }

      // ✅ CORREGIDO: Crear artículo con todos los campos del modelo
      final nuevoArticulo = Articulo(
        articuloId: null,
        categoriaId: _categoriaId!,
        categoriaNombre: _getNombreCategoria(),
        marcaId: _marcaId!,
        marcaNombre: _getNombreMarca(),
        referencia: _referenciaController.text.trim(),
        tipoBodega: _tipoBodega,
        tipoArticulo: _tipoArticulo,
        esActivo: _esActivo, // ✅ CORREGIDO: Variable ahora definida
        descripcion: _descripcionController.text.trim(), // ✅ CORREGIDO: Campo añadido
        imagenPath: imagenUrl,
        creadoEn: null,
      );

      final resultado = await ArticuloService.crearArticulo(nuevoArticulo, token);
      
      if (resultado['success'] == true) {
        _mostrarSnackBar('✅ ${resultado['message']}', Colors.green);
        
        widget.onArticuloCreado?.call();
      } else {
        _mostrarError(resultado['error'] ?? 'Error al crear el artículo');
      }
    } catch (e) {
      _mostrarError('Error al crear artículo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ OPTIMIZADO: Métodos de utilidad reutilizables
  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  void _mostrarError(String mensaje) {
    _mostrarSnackBar(mensaje, Colors.red);
  }

  // ✅ OPTIMIZADO: Widgets reutilizables para la UI
  Widget _buildSearchField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onClear,
    required bool mostrarLista,
    required List<dynamic> elementosFiltrados,
    required bool mostrarCrear,
    required VoidCallback onCrear,
    required Function(dynamic) onSeleccionar,
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
        Column(
          children: [
            TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar $label...',
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
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: onClear,
                      )
                    : null,
              ),
            ),
            
            if (mostrarLista && (elementosFiltrados.isNotEmpty || mostrarCrear)) ...[
              const SizedBox(height: 8),
              _buildListaOpciones(
                elementosFiltrados: elementosFiltrados,
                mostrarCrear: mostrarCrear,
                textoCrear: controller.text,
                onCrear: onCrear,
                onSeleccionar: onSeleccionar,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildListaOpciones({
    required List<dynamic> elementosFiltrados,
    required bool mostrarCrear,
    required String textoCrear,
    required VoidCallback onCrear,
    required Function(dynamic) onSeleccionar,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2a2f40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF474554)),
      ),
      child: Column(
        children: [
          if (mostrarCrear)
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
              title: Text(
                'Crear "$textoCrear"',
                style: const TextStyle(color: Colors.green, fontSize: 14),
              ),
              onTap: onCrear,
            ),
          
          ...elementosFiltrados.map((elemento) {
            return ListTile(
              title: Text(
                elemento['nombre'],
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              onTap: () => onSeleccionar(elemento),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Stack(
      children: [
        const CustomBackground(),
        
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop) _buildHeader(),
              if (isDesktop) const SizedBox(height: 20),
              
              Expanded(
                child: _cargandoCategorias || _cargandoMarcas || _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFf59e0b)))
                    : SingleChildScrollView(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Card(
                              color: const Color(0xFF1a1f2e).withOpacity(0.9),
                              elevation: 8,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      if (isDesktop) ...[
                                        _buildTitle(),
                                        const SizedBox(height: 20),
                                      ],
                                      
                                      ImageUploader(
                                        onImageSelected: (imageData) {
                                          setState(() => _imagenSeleccionada = imageData);
                                        },
                                        nombreArticulo: _getNombreCategoria(),
                                        marca: _getNombreMarca(),
                                        referencia: _referenciaController.text,
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      _buildFormFields(isDesktop),
                                      const SizedBox(height: 32),
                                      
                                      _buildActionButtons(isDesktop),
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

  Widget _buildFormFields(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = isDesktop ? constraints.maxWidth / 2 - 20 : double.infinity;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Búsqueda de categoría
            SizedBox(width: fieldWidth, child: _buildCategoriaSearch()),
            // Búsqueda de marca
            SizedBox(width: fieldWidth, child: _buildMarcaSearch()),
            // Referencia
            SizedBox(width: fieldWidth, child: _buildReferenciaField()),
            // Tipo de artículo
            SizedBox(width: fieldWidth, child: _buildTipoArticuloDropdown()),
            // Bodega
            SizedBox(width: fieldWidth, child: _buildBodegaDropdown()),
            // Descripción ✅ CORREGIDO: Campo añadido
            SizedBox(width: fieldWidth, child: _buildDescripcionField()),
          ],
        );
      },
    );
  }

  // ✅ OPTIMIZADO: Widgets específicos para cada campo
  Widget _buildCategoriaSearch() {
    return _buildSearchField(
      controller: _categoriaSearchController,
      label: 'Categoría *',
      onClear: () {
        _categoriaSearchController.clear();
        setState(() {
          _categoriaId = null;
          _mostrarCrearCategoria = false;
          _mostrarListaCategorias = false;
        });
      },
      mostrarLista: _mostrarListaCategorias,
      elementosFiltrados: _categoriasFiltradas,
      mostrarCrear: _mostrarCrearCategoria,
      onCrear: _crearNuevaCategoria,
      onSeleccionar: (categoria) {
        setState(() {
          _categoriaId = categoria['id'] as int;
          _categoriaSearchController.text = categoria['nombre'];
          _mostrarCrearCategoria = false;
          _mostrarListaCategorias = false;
        });
      },
    );
  }

  Widget _buildMarcaSearch() {
    return _buildSearchField(
      controller: _marcaSearchController,
      label: 'Marca *',
      onClear: () {
        _marcaSearchController.clear();
        setState(() {
          _marcaId = null;
          _mostrarCrearMarca = false;
          _mostrarListaMarcas = false;
        });
      },
      mostrarLista: _mostrarListaMarcas,
      elementosFiltrados: _marcasFiltradas,
      mostrarCrear: _mostrarCrearMarca,
      onCrear: _crearNuevaMarca,
      onSeleccionar: (marca) {
        final marcaId = marca['id'];
        if (marcaId != null) {
          setState(() {
            _marcaId = marcaId is int ? marcaId : int.tryParse(marcaId.toString());
            _marcaSearchController.text = marca['nombre'] ?? '';
            _mostrarCrearMarca = false;
            _mostrarListaMarcas = false;
          });
        }
      },
    );
  }

  Widget _buildReferenciaField() => _buildTextField(
    controller: _referenciaController,
    label: 'Referencia *',
    validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
  );

  Widget _buildDescripcionField() => _buildTextField(
    controller: _descripcionController,
    label: 'Descripción *',
    maxLines: 3,
    validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
  );

  Widget _buildTipoArticuloDropdown() {
  return _buildDropdown(
    value: _tipoArticulo,
    label: 'Tipo de Artículo *',
    items: _tiposArticulo,
    onChanged: (v) {
      setState(() {
        _tipoArticulo = v!;

        // Lógica para definir _esActivo según el tipo de artículo
        if (_tipoArticulo == "Activo Fijo") {
          _esActivo = true;
        } else if (_tipoArticulo == "Activo de Control") {
          _esActivo = true;
        } else {
          _esActivo = false;
        }
      });
    },
  );
}

  Widget _buildBodegaDropdown() => _buildDropdown(
    value: _tipoBodega,
    label: 'Bodega *',
    items: _bodegas.map((b) => {'value': b, 'label': b}).toList(),
    onChanged: (v) => setState(() => _tipoBodega = v!),
  );


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
          initialValue: value,
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

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onCancelar,
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

  Widget _buildTitle() {
    return Row(
      children: [
        const Icon(Icons.add_circle_outline, color: Color.fromARGB(255, 43, 131, 8), size: 28),
        const SizedBox(width: 12),
        Text(
          'Crear Nuevo Artículo',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDesktop) {
    return Row(
      children: [
        if (isDesktop) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onCancelar,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _crearArticulo,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(
              _isLoading ? 'Creando...' : 'Crear Artículo',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 43, 131, 8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}