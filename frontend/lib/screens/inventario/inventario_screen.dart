import 'package:flutter/material.dart';
import 'package:frontend/widgets/cards/inventario_card.dart';
import 'package:provider/provider.dart';
import '../../models/inventario_model.dart';
import '../../services/inventario_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_background.dart';
import '../../widgets/inventario_detalles_card.dart';
import '../../widgets/cards/inventario_tabla_card.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final List<Inventario> _inventario = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 50;
  
  // Filtros activos
  String _searchQuery = '';
  String _selectedEstado = '';
  String _selectedBodega = '';
  String _selectedTipoBodega = '';
  String _filterTipoInventario = 'Todos';
  
  // Vista
  bool _showFiltrosAvanzados = false;
  
  // Filtros disponibles
  FiltrosDisponibles _filtrosDisponibles = FiltrosDisponibles(
    estados: [],
    bodegas: [],
    tiposBodega: [],
    tiposArticulo: [],
    marcas: [],
    categorias: [],
  );
  
  Inventario? _inventarioSeleccionadoZoom;
  bool _mostrarZoom = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      _cargarMas();
    }
  }

  void _onSearchChanged() {
    // Debounce para evitar muchas llamadas a la API
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() => _searchQuery = _searchController.text);
        _cargarInventario(reset: true);
      }
    });
  }

  Future<void> _cargarDatosIniciales() async {
    await _cargarFiltrosDisponibles();
    await _cargarInventario(reset: true);
  }

Future<void> _cargarFiltrosDisponibles() async {
  try {
    print('🔄 Cargando filtros disponibles...');
    final filtros = await InventarioService.getFiltrosDisponibles(context);
    print('✅ Filtros cargados: $filtros');
    
    setState(() {
      _filtrosDisponibles = filtros;
    });
    
    // Debug detallado
    _debugFiltros();
  } catch (e) {
    print('❌ Error cargando filtros: $e');
    setState(() {
      _filtrosDisponibles = FiltrosDisponibles(
        estados: ['Nuevo', 'Bueno', 'Reparación'],
        bodegas: _obtenerBodegasPorUsuario(),
        tiposBodega: ['BMD', 'Sistemas'],
        tiposArticulo: ['Activo Fijo', 'Activo de Control', 'Consumible'],
        marcas: [],
        categorias: [],
      );
    });
    _debugFiltros();
  }
}

void _debugFiltros() {
  print('🔍 DEBUG FILTROS DISPONIBLES:');
  print('  Estados: ${_filtrosDisponibles.estados}');
  print('  Bodegas: ${_filtrosDisponibles.bodegas}');
  print('  Tipos Bodega: ${_filtrosDisponibles.tiposBodega}');
  print('  Tipos Artículo: ${_filtrosDisponibles.tiposArticulo}');
  print('  Marcas: ${_filtrosDisponibles.marcas}');
  print('  Categorías: ${_filtrosDisponibles.categorias}');
}

List<String> _obtenerBodegasPorUsuario() {
  final authProvider = context.read<AuthProvider>();
  final user = authProvider.user;
  
  if (user?.rol == 'administrador') {
    return ['Bodega Principal', 'Bodega Garzón', 'Bodega Pitalito'];
  } else if (user?.bodega != null) {
    return [user!.bodega!];
  }
  return [];
}

  Future<void> _cargarInventario({bool reset = false}) async {
    if (_loading) return;
    
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _inventario.clear();
        _hasMore = true;
      }
    });

    try {
      final response = await InventarioService.getInventarioPaginated(
        context: context,
        page: _page,
        limit: _limit,
        search: _searchQuery,
        estado: _selectedEstado,
        bodega: _selectedBodega,
        tipoBodega: _selectedTipoBodega,
        marca: '',
        tipoArticulo: _filterTipoInventario == 'Todos' ? '' : _filterTipoInventario,
      );

      setState(() {
        if (reset) {
          _inventario.clear();
        }
        _inventario.addAll(response.items);
        _hasMore = _page < response.pagination.totalPages;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      _mostrarError('Error al cargar inventario: $e');
    }
  }

  Future<void> _cargarMas() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);
    _page++;

    try {
      final response = await InventarioService.getInventarioPaginated(
        context: context,
        page: _page,
        limit: _limit,
        search: _searchQuery,
        estado: _selectedEstado,
        bodega: _selectedBodega,
        tipoBodega: _selectedTipoBodega,
        marca: '',
        tipoArticulo: _filterTipoInventario == 'Todos' ? '' : _filterTipoInventario,
      );

      setState(() {
        _inventario.addAll(response.items);
        _hasMore = _page < response.pagination.totalPages;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loadingMore = false;
        _page--; // Revertir en caso de error
      });
      print('Error al cargar más registros: $e');
    }
  }

  void _aplicarFiltro(String tipo, String? valor) {
    setState(() {
      switch (tipo) {
        case 'estado':
          _selectedEstado = valor ?? '';
          break;
        case 'bodega':
          _selectedBodega = valor ?? '';
          break;
        case 'tipoBodega':
          _selectedTipoBodega = valor ?? '';
          break;
        case 'tipoInventario':
          _filterTipoInventario = valor ?? 'Todos';
          break;
      }
    });
    _cargarInventario(reset: true);
  }

  void _limpiarFiltros() {
    setState(() {
      _selectedEstado = '';
      _selectedBodega = '';
      _selectedTipoBodega = '';
      _filterTipoInventario = 'Todos';
      _searchController.clear();
      _searchQuery = '';
    });
    _cargarInventario(reset: true);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _toggleZoomInventario(Inventario? inventario) {
    setState(() {
      _mostrarZoom = inventario != null;
      _inventarioSeleccionadoZoom = inventario;
    });
  }

  // Métodos para calcular estadísticas
  int get _totalActivosFijos => _inventario.where((item) => item.tipoArticulo == 'Activo Fijo').length;
  int get _totalActivosControl => _inventario.where((item) => item.tipoArticulo == 'Activo de Control').length;
  int get _totalConsumibles => _inventario.where((item) => item.tipoArticulo == 'Consumible').length;

  List<Inventario> get _inventarioFiltrado {
    var filtered = _inventario;

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      final lowerSearch = _searchQuery.toLowerCase();
      filtered = filtered.where((item) =>
          item.articuloReferencia.toLowerCase().contains(lowerSearch) ||
          item.articuloDescripcion.toLowerCase().contains(lowerSearch) ||
          (item.placa?.toLowerCase().contains(lowerSearch) ?? false) ||
          (item.serial?.toLowerCase().contains(lowerSearch) ?? false) ||
          item.categoriaNombre.toLowerCase().contains(lowerSearch) ||
          (item.marcaNombre?.toLowerCase().contains(lowerSearch) ?? false) ||
          item.tipoArticulo.toLowerCase().contains(lowerSearch) ||
          item.bodega.toLowerCase().contains(lowerSearch)).toList();
    }

    // Filtro por tipo de inventario
    if (_filterTipoInventario != 'Todos') {
      filtered = filtered.where((item) => item.tipoArticulo == _filterTipoInventario).toList();
    }

    // Filtros adicionales
    if (_selectedEstado.isNotEmpty) {
      filtered = filtered.where((item) => item.estado == _selectedEstado).toList();
    }

    if (_selectedBodega.isNotEmpty) {
      filtered = filtered.where((item) => item.bodega == _selectedBodega).toList();
    }

    if (_selectedTipoBodega.isNotEmpty) {
      filtered = filtered.where((item) => item.tipoBodega == _selectedTipoBodega).toList();
    }

    return filtered;
  }

  // Concatenar categoría + marca + referencia
  String _getTituloItem(Inventario item) {
    List<String> partes = [];
    if (item.categoriaNombre.isNotEmpty) partes.add(item.categoriaNombre);
    if (item.marcaNombre != null && item.marcaNombre!.isNotEmpty) partes.add(item.marcaNombre!);
    if (item.articuloReferencia.isNotEmpty) partes.add(item.articuloReferencia);
    return partes.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.rol == 'administrador';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 750;

    return Scaffold(
      floatingActionButton: isAdmin && !_mostrarZoom
          ? FloatingActionButton(
              onPressed: _mostrarDialogoNuevoRegistro,
              backgroundColor: const Color(0xFF0948d6),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const CustomBackground(),
          Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 20),
            child: Column(
              children: [
                // Header con estadísticas
                _buildHeader(isMobile),
                const SizedBox(height: 20),
                
                // Barra de búsqueda y controles
                _buildSearchBar(isMobile, isAdmin),
                
                // Filtros avanzados
                if (_showFiltrosAvanzados) _buildFiltrosAvanzados(),
                
                const SizedBox(height: 10),
                
                // Contenido principal
                Expanded(
                  child: _loading && _inventario.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _inventarioFiltrado.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron registros',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            )
                          : isMobile 
                              ? _buildMobileView(isAdmin)
                              : _buildDesktopView(isAdmin),
                ),
              ],
            ),
          ),
          if (_mostrarZoom && _inventarioSeleccionadoZoom != null)
            _buildOverlayZoom(context, isAdmin),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final total = _inventario.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Gestión de Inventario",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard('Todos', total.toString(), Colors.blue, 'Todos'),
              const SizedBox(width: 10),
              _buildStatCard('Activos Fijos', _totalActivosFijos.toString(), Colors.green, 'Activo Fijo'),
              const SizedBox(width: 10),
              _buildStatCard('Activos Control', _totalActivosControl.toString(), Colors.orange, 'Activo de Control'),
              const SizedBox(width: 10),
              _buildStatCard('Consumibles', _totalConsumibles.toString(), Colors.red, 'Consumible'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, String tipoFiltro) {
    final isSelected = _filterTipoInventario == tipoFiltro;

    return GestureDetector(
      onTap: () {
        _aplicarFiltro('tipoInventario', tipoFiltro);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.5) : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile, bool isAdmin) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: _showFiltrosAvanzados ? 2 : 4,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar por categoría, marca, referencia, placa, serial...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: const Color.fromARGB(111, 30, 41, 59),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
            ),
            if (_showFiltrosAvanzados) const SizedBox(width: 10),
            if (_showFiltrosAvanzados) 
              
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(
                _showFiltrosAvanzados ? Icons.filter_alt_off : Icons.filter_alt,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() => _showFiltrosAvanzados = !_showFiltrosAvanzados);
              },
              tooltip: _showFiltrosAvanzados ? 'Ocultar filtros' : 'Mostrar filtros',
            ),
          ],
        ),
      ],
    );
  }

Widget _buildFiltrosEnLinea() {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (_filtrosDisponibles.estados.isNotEmpty)
        _buildFiltroChip('Estado', _selectedEstado, _filtrosDisponibles.estados, 'estado'),
      if (_filtrosDisponibles.bodegas.isNotEmpty)
        _buildFiltroChip('Bodega', _selectedBodega, _filtrosDisponibles.bodegas, 'bodega'),
      if (_filtrosDisponibles.tiposBodega.isNotEmpty)
        _buildFiltroChip('Tipo Bodega', _selectedTipoBodega, _filtrosDisponibles.tiposBodega, 'tipoBodega'),
    ],
  );
}

  Widget _buildFiltroChip(String label, String selectedValue, List<String> opciones, String tipo) {
    return InputChip(
      label: Text(selectedValue.isEmpty ? label : '$label: $selectedValue'),
      labelStyle: TextStyle(
        color: selectedValue.isEmpty ? Colors.white70 : Colors.white,
        fontSize: 12,
      ),
      backgroundColor: selectedValue.isEmpty 
          ? const Color.fromARGB(111, 30, 41, 59)
          : Colors.blue.withOpacity(0.3),
      onPressed: () {
        _mostrarDialogoFiltro(label, opciones, tipo, selectedValue);
      },
      onDeleted: selectedValue.isEmpty ? null : () => _aplicarFiltro(tipo, null),
    );
  }

  void _mostrarDialogoFiltro(String label, List<String> opciones, String tipo, String selectedValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar $label'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: opciones.length,
            itemBuilder: (context, index) {
              final opcion = opciones[index];
              return ListTile(
                title: Text(opcion),
                trailing: selectedValue == opcion ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.of(context).pop();
                  _aplicarFiltro(tipo, opcion);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

Widget _buildFiltrosAvanzados() {
  // Si no hay datos, mostrar mensaje informativo
  if (_filtrosDisponibles.estados.isEmpty && 
      _filtrosDisponibles.bodegas.isEmpty && 
      _filtrosDisponibles.tiposBodega.isEmpty) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(111, 30, 41, 59),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros Avanzados',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 16),
          const Text(
            'No hay opciones de filtro disponibles en este momento.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _cargarFiltrosDisponibles,
            child: const Text('Reintentar carga de filtros'),
          ),
        ],
      ),
    );
  }

  return Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color.fromARGB(111, 30, 41, 59),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtros Avanzados',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            if (_filtrosDisponibles.estados.isNotEmpty)
              _buildFiltroDropdown(
                'Estado',
                _selectedEstado,
                _filtrosDisponibles.estados,
                (value) => _aplicarFiltro('estado', value),
              ),
            if (_filtrosDisponibles.bodegas.isNotEmpty)
              _buildFiltroDropdown(
                'Bodega',
                _selectedBodega,
                _filtrosDisponibles.bodegas,
                (value) => _aplicarFiltro('bodega', value),
              ),
            if (_filtrosDisponibles.tiposBodega.isNotEmpty)
              _buildFiltroDropdown(
                'Tipo Bodega',
                _selectedTipoBodega,
                _filtrosDisponibles.tiposBodega,
                (value) => _aplicarFiltro('tipoBodega', value),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_selectedEstado.isNotEmpty || _selectedBodega.isNotEmpty || _selectedTipoBodega.isNotEmpty)
          TextButton(
            onPressed: _limpiarFiltros,
            child: const Text(
              'Limpiar filtros',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildFiltroDropdown(
    String label,
    String selectedValue,
    List<String> opciones,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(111, 30, 41, 59),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selectedValue.isEmpty ? null : selectedValue,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('Todos', style: TextStyle(color: Colors.white70))),
                ...opciones.map((opcion) => DropdownMenuItem(
                  value: opcion,
                  child: Text(opcion, style: const TextStyle(color: Colors.white)),
                )),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildMobileView(bool isAdmin) {
  return GridView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.only(bottom: 80, top: 8),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.75,
    ),
    itemCount: _inventarioFiltrado.length + (_loadingMore ? 1 : 0),
    itemBuilder: (context, index) {
      if (index >= _inventarioFiltrado.length) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }
      
      final registro = _inventarioFiltrado[index];
      return InventarioCard(
        inventario: registro,
        isAdmin: isAdmin,
        onVerDetalles: () => _toggleZoomInventario(registro),
        onEditar: () => _editarRegistro(registro),
        onVerHistorial: () => _verHistorial(registro),
      );
    },
  );
}


Widget _buildDesktopView(bool isAdmin) {
  return InventarioTablaCard(
    inventarios: _inventarioFiltrado,
    isAdmin: isAdmin,
    onVerDetalles: () {}, // Puedes dejar vacío o implementar
    onEditar: () => _mostrarDialogoEditar(), // Método genérico
    onVerMovimientos: () => _mostrarDialogoMovimientos(), // Método genérico
    onVerDetallesInventario: (registro) => _toggleZoomInventario(registro),
  );
}

// Agrega estos métodos si no los tienes
void _mostrarDialogoEditar() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Editar Registro'),
      content: const Text('Funcionalidad en desarrollo'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

void _mostrarDialogoMovimientos() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Movimientos'),
      content: const Text('Funcionalidad en desarrollo'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

  Widget _buildMobileCard(Inventario registro, bool isAdmin) {
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
                _buildEstadoChip(registro.estado),
                Text(
                  'Cant: ${registro.cantidad}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Título concatenado
            Text(
              _getTituloItem(registro),
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
            _buildInfoItem('Placa', registro.placa ?? 'N/A'),
            _buildInfoItem('Serial', registro.serial ?? 'N/A'),
            _buildInfoItem('Tipo', registro.tipoArticulo),
            _buildInfoItem('Bodega', registro.bodega),
            
            const Spacer(),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18, color: Colors.blue),
                  onPressed: () => _toggleZoomInventario(registro),
                  tooltip: 'Ver detalles',
                ),
                if (isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.green),
                    onPressed: () => _editarRegistro(registro),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, size: 18, color: Colors.orange),
                    onPressed: () => _verHistorial(registro),
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
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color),
    ),
    child: Text(
      estado,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildOverlayZoom(BuildContext context, bool isAdmin) {
  return InventarioDetallesCard(
    inventario: _inventarioSeleccionadoZoom!,
    isAdmin: isAdmin,
    onEditar: () => _editarRegistro(_inventarioSeleccionadoZoom!),
    onVerHistorial: () => _verHistorial(_inventarioSeleccionadoZoom!),
    onCerrar: () => _toggleZoomInventario(null),
  );
}

  Widget _buildDetallesCompletos(Inventario registro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información detallada en el orden solicitado
        _buildDetalleItem('Categoría', registro.categoriaNombre),
        _buildDetalleItem('Marca', registro.marcaNombre ?? 'N/A'),
        _buildDetalleItem('Referencia', registro.articuloReferencia),
        _buildDetalleItem('Placa', registro.placa ?? 'N/A'),
        _buildDetalleItem('Serial', registro.serial ?? 'N/A'),
        _buildDetalleItem('Descripción', registro.articuloDescripcion.isNotEmpty ? registro.articuloDescripcion : 'N/A'),
        _buildDetalleItem('Tipo Bodega', registro.tipoBodega),
        _buildDetalleItem('Tipo Artículo', registro.tipoArticulo),
        _buildDetalleItem('Estado', registro.estado),
        _buildDetalleItem('Cantidad', registro.cantidad.toString()),
        _buildDetalleItem('Bodega', registro.bodega),
        _buildDetalleItem('Ubicación Detallada', registro.ubicacionDetallada ?? 'N/A'),
        
        const SizedBox(height: 20),
        _buildEstadoChip(registro.estado),
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

  void _mostrarDialogoNuevoRegistro() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Registro'),
        content: const Text('Funcionalidad en desarrollo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _editarRegistro(Inventario registro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Registro'),
        content: Text('Editar: ${_getTituloItem(registro)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _verHistorial(Inventario registro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial de Movimientos'),
        content: Text('Historial de: ${_getTituloItem(registro)}\n\nFuncionalidad en desarrollo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _eliminarRegistro(Inventario registro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: Text('¿Estás seguro de eliminar ${_getTituloItem(registro)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              _mostrarError('Funcionalidad en desarrollo');
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

}