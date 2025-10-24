import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/asignaciones_service.dart';
import 'package:frontend/models/asignacion_model.dart';

class AsignacionesScreen extends StatefulWidget {
  const AsignacionesScreen({super.key});

  @override
  State<AsignacionesScreen> createState() => _AsignacionesScreenState();
}

class _AsignacionesScreenState extends State<AsignacionesScreen> {
  final AsignacionesService _asignacionesService = AsignacionesService();
  List<Asignacion> _asignaciones = [];
  List<InventarioDisponible> _inventarioDisponible = [];
  bool _loading = true;
  bool _error = false;
  String _errorMessage = '';
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  bool _hasMore = true;

  // Filtros
  String _filtroEstado = '';
  String _filtroTecnico = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    await _cargarAsignaciones();
    await _cargarInventarioDisponible();
  }

  Future<void> _cargarAsignaciones() async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _error = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final resultado = await _asignacionesService.listarAsignaciones(
      authProvider: authProvider,
      page: _currentPage,
      limit: _itemsPerPage,
      estado: _filtroEstado.isNotEmpty ? _filtroEstado : null,
      tecnicoId: _filtroTecnico.isNotEmpty ? _filtroTecnico : null,
    );

    if (!mounted) return;

    if (resultado['success']) {
      final items = resultado['items'] ?? [];
      final pagination = resultado['pagination'] ?? {};
      
      setState(() {
        if (_currentPage == 1) {
          _asignaciones = (items as List)
              .map((item) => Asignacion.fromJson(item))
              .toList();
        } else {
          _asignaciones.addAll((items as List)
              .map((item) => Asignacion.fromJson(item))
              .toList());
        }
        
        _hasMore = _currentPage < (pagination['totalPages'] ?? 1);
        _loading = false;
      });
    } else {
      setState(() {
        _error = true;
        _errorMessage = resultado['error'] ?? 'Error al cargar asignaciones';
        _loading = false;
      });
    }
  }

  Future<void> _cargarInventarioDisponible() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final resultado = await _asignacionesService.obtenerInventarioDisponible(
      authProvider: authProvider,
    );

    if (resultado['success']) {
      if (mounted) {
        setState(() {
          _inventarioDisponible = (resultado['items'] as List)
              .map((item) => InventarioDisponible.fromJson(item))
              .toList();
        });
      }
    }
  }

  Future<void> _crearNuevaAsignacion() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // TODO: Implementar diálogo o pantalla para crear asignación
    // Por ahora, mostramos un placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de crear asignación en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _actualizarEstadoAsignacion(int asignacionId, String nuevoEstado) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final resultado = await _asignacionesService.actualizarEstado(
      authProvider: authProvider,
      asignacionId: asignacionId,
      nuevoEstado: nuevoEstado,
    );

    if (resultado['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Estado actualizado'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargarAsignaciones(); // Recargar datos
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['error'] ?? 'Error al actualizar estado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoEstado(Asignacion asignacion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cambiar Estado'),
          content: const Text('Selecciona el nuevo estado de la asignación:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            if (asignacion.estado != 'instalado')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _actualizarEstadoAsignacion(asignacion.id, 'instalado');
                },
                child: const Text('Marcar como Instalado'),
              ),
            if (asignacion.estado != 'devuelto')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _actualizarEstadoAsignacion(asignacion.id, 'devuelto');
                },
                child: const Text('Marcar como Devuelto'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFiltros() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filtroEstado.isNotEmpty ? _filtroEstado : null,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    dropdownColor: const Color(0xFF001F5E),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Todos los estados'),
                      ),
                      const DropdownMenuItem(
                        value: 'asignado',
                        child: Text('Asignado'),
                      ),
                      const DropdownMenuItem(
                        value: 'instalado',
                        child: Text('Instalado'),
                      ),
                      const DropdownMenuItem(
                        value: 'devuelto',
                        child: Text('Devuelto'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filtroEstado = value ?? '';
                        _currentPage = 1;
                      });
                      _cargarAsignaciones();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'ID Técnico',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _filtroTecnico = value;
                        _currentPage = 1;
                      });
                      _cargarAsignaciones();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _cargarAsignaciones,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aplicar Filtros'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filtroEstado = '';
                      _filtroTecnico = '';
                      _currentPage = 1;
                    });
                    _cargarAsignaciones();
                  },
                  child: const Text(
                    'Limpiar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsignacionCard(Asignacion asignacion) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asignacion.articuloReferencia,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (asignacion.placa != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Placa: ${asignacion.placa}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(asignacion.estado),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    asignacion.estadoTexto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, color: Colors.white.withOpacity(0.7), size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Técnico: ${asignacion.tecnicoNombre}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.store, color: Colors.white.withOpacity(0.7), size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Sitio: ${asignacion.sitioVenta}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.7), size: 16),
                const SizedBox(width: 4),
                Text(
                  'Fecha: ${_formatearFecha(asignacion.fechaAsignacion)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (asignacion.observaciones != null && asignacion.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Observaciones: ${asignacion.observaciones}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (asignacion.estado != 'devuelto')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _mostrarDialogoEstado(asignacion),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cambiar Estado'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Cargando asignaciones...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white.withOpacity(0.7),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarAsignaciones,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in,
            color: Colors.white.withOpacity(0.7),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay asignaciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron asignaciones con los filtros aplicados',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _crearNuevaAsignacion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear Primera Asignación'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Asignaciones a Técnicos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _crearNuevaAsignacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Asignación'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFiltros(),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? _buildLoadingIndicator()
                : _error
                    ? _buildErrorWidget()
                    : _asignaciones.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: Colors.white,
                            backgroundColor: const Color(0xFF001F5E),
                            onRefresh: _cargarAsignaciones,
                            child: ListView.builder(
                              itemCount: _asignaciones.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _asignaciones.length) {
                                  // Cargar más items
                                  _currentPage++;
                                  _cargarAsignaciones();
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _buildAsignacionCard(_asignaciones[index]),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'asignado':
        return Colors.orange;
      case 'instalado':
        return Colors.green;
      case 'devuelto':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return fecha;
    }
  }
}