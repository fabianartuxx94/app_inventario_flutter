import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../models/articulo_model.dart';
import '../../services/articulos_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/image_uploader.dart';
import '../../widgets/custom_background.dart';
import '../../providers/auth_provider.dart';
import '../../config/config.dart'; // ✅ Importa la configuración con la IP real

class EditarArticuloScreen extends StatefulWidget {
  final Articulo articulo;
  final VoidCallback? onArticuloActualizado;
  final VoidCallback? onCancelar;

  const EditarArticuloScreen({
    super.key,
    required this.articulo,
    this.onArticuloActualizado,
    this.onCancelar,
  });

  @override
  State<EditarArticuloScreen> createState() => _EditarArticuloScreenState();
}

class _EditarArticuloScreenState extends State<EditarArticuloScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenciaController = TextEditingController();
  final _ubicacionBodegaController = TextEditingController();

  String _tipoBodega = 'Sistemas';
  String _tipoArticulo = 'Activo Fijo';
  dynamic _nuevaImagenSeleccionada;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosArticulo();
  }

  void _cargarDatosArticulo() {
    _referenciaController.text = widget.articulo.referencia;
    _ubicacionBodegaController.text = widget.articulo.ubicacionBodega;
    _tipoBodega = widget.articulo.tipoBodega;
    _tipoArticulo = widget.articulo.tipoArticulo;
  }

  Future<void> _actualizarArticulo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      String? nuevaImagenUrl;

      if (_nuevaImagenSeleccionada != null) {
  final uploadResult = await UploadService.uploadImage(
    _nuevaImagenSeleccionada, // ✅ Ahora envía los datos correctos
    token,
    nombreArticulo: widget.articulo.categoriaNombre,
    marca: widget.articulo.marcaNombre,
    referencia: _referenciaController.text.trim(),
  );
  if (uploadResult['success']) {
    nuevaImagenUrl = uploadResult['imageUrl'];
  }
}

      final articuloActualizado = Articulo(
        articuloId: widget.articulo.articuloId,
        categoriaId: widget.articulo.categoriaId,
        categoriaNombre: widget.articulo.categoriaNombre,
        marcaId: widget.articulo.marcaId,
        marcaNombre: widget.articulo.marcaNombre,
        referencia: _referenciaController.text.trim(),
        tipoBodega: _tipoBodega,
        tipoArticulo: _tipoArticulo,
        ubicacionBodega: _ubicacionBodegaController.text.trim(),
        imagenPath: nuevaImagenUrl ?? widget.articulo.imagenPath,
        stockMinimo: widget.articulo.stockMinimo,
        etiquetas: widget.articulo.etiquetas,
      );

      final resultado = await ArticuloService.actualizarArticulo(articuloActualizado, token);

      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${resultado['message']}'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (widget.onArticuloActualizado != null) {
          widget.onArticuloActualizado!();
        }
      } else {
        _mostrarError(resultado['error'] ?? 'Error al actualizar artículo');
      }
    } catch (e) {
      _mostrarError('Error al actualizar artículo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  /// ✅ Esta función ahora construye bien la URL de imagen usando AppConfig
  String _buildImageUrl(String imagenPath) {
    if (imagenPath.isEmpty) {
      return '';
    }

    if (imagenPath.startsWith('http')) {
      return imagenPath;
    }

    if (imagenPath.startsWith('/uploads')) {
      return '${AppConfig.baseUrl}$imagenPath';
    }

    return '${AppConfig.imagesUrl}/$imagenPath';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Stack(
      children: [
        const CustomBackground(),
        
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con botón de volver - SOLO en escritorio
              if (!isMobile) _buildHeader(),
              if (!isMobile) const SizedBox(height: 20),
              
              Expanded(
                child: _isLoading
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
                                      // Información del artículo
                                      _buildInfoArticulo(),
                                      const SizedBox(height: 20),
                                      
                                      ImageUploader(
                                        onImageSelected: (imageData) {
                                          setState(() {
                                            _nuevaImagenSeleccionada = imageData;
                                          });
                                        },
                                        currentImageUrl: _buildImageUrl(widget.articulo.imagenPath ?? ''),
                                        nombreArticulo: widget.articulo.categoriaNombre,
                                        marca: widget.articulo.marcaNombre,
                                        referencia: _referenciaController.text,
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Wrap(
                                            spacing: 16,
                                            runSpacing: 16,
                                            children: [
                                              // Referencia
                                              SizedBox(
                                                width: isMobile ? double.infinity : constraints.maxWidth / 2 - 20,
                                                child: _buildTextField(
                                                  controller: _referenciaController,
                                                  label: 'Referencia *',
                                                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                                                ),
                                              ),
                                              // Ubicación en bodega
                                              SizedBox(
                                                width: isMobile ? double.infinity : constraints.maxWidth / 2 - 20,
                                                child: _buildTextField(
                                                  controller: _ubicacionBodegaController,
                                                  label: 'Ubicación en Bodega *',
                                                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                                                ),
                                              ),
                                              // Tipo de artículo
                                              SizedBox(
                                                width: isMobile ? double.infinity : constraints.maxWidth / 2 - 20,
                                                child: _buildDropdown(
                                                  value: _tipoArticulo,
                                                  label: 'Tipo de Artículo *',
                                                  items: [
                                                    {'value': 'Activo Fijo', 'label': 'Activo Fijo'},
                                                    {'value': 'Activo de Control', 'label': 'Activo de Control'},
                                                    {'value': 'Consumible', 'label': 'Consumible'},
                                                  ],
                                                  onChanged: (v) => setState(() => _tipoArticulo = v!),
                                                ),
                                              ),
                                              // Bodega
                                              SizedBox(
                                                width: isMobile ? double.infinity : constraints.maxWidth / 2 - 20,
                                                child: _buildDropdown(
                                                  value: _tipoBodega,
                                                  label: 'Bodega *',
                                                  items: ['Sistemas', 'Bmd'].map((b) => {'value': b, 'label': b}).toList(),
                                                  onChanged: (v) => setState(() => _tipoBodega = v!),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      
                                      // Botón de actualizar
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton.icon(
                                          onPressed: _isLoading ? null : _actualizarArticulo,
                                          icon: const Icon(Icons.save),
                                          label: Text(
                                            _isLoading ? 'Actualizando...' : 'Actualizar Artículo',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color.fromARGB(255, 43, 131, 8),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
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
          onPressed: widget.onCancelar,
          tooltip: 'Volver a la lista',
        ),
        const SizedBox(width: 8),
        Text(
          'Editar Artículo',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoArticulo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2f40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0948d6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFf59e0b), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editando: ${widget.articulo.marcaNombre} ${widget.articulo.referencia}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Categoría: ${widget.articulo.categoriaNombre}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
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
  // ✅ VERIFICAR que el valor actual existe en la lista
  final validItems = items.where((item) => item['value'] != null).toList();
  final validValues = validItems.map((item) => item['value']!).toList();
  
  String currentValue = value;
  
  // Si el valor actual no está en la lista, usar el primero disponible
  if (!validValues.contains(value)) {
    currentValue = validValues.isNotEmpty ? validValues.first : '';
    print('⚠️ Valor "$value" no encontrado en la lista. Usando: "$currentValue"');
  }

  // Verificar duplicados
  final duplicates = _findDuplicateValues(validValues);
  if (duplicates.isNotEmpty) {
    print('❌ VALORES DUPLICADOS EN DROPDOWN: $duplicates');
  }

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
        value: currentValue, // ✅ Ahora siempre es un valor válido
        dropdownColor: const Color(0xFF2d3748),
        style: const TextStyle(color: Colors.white),
        onChanged: onChanged,
        items: validItems.map((item) {
          return DropdownMenuItem<String>(
            value: item['value']!,
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
        validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
      ),
    ],
  );
}

// Método auxiliar para encontrar duplicados
List<String> _findDuplicateValues(List<String> values) {
  final duplicates = <String>[];
  final seen = <String>{};
  
  for (final value in values) {
    if (seen.contains(value)) {
      duplicates.add(value);
    } else {
      seen.add(value);
    }
  }
  
  return duplicates;
}
}