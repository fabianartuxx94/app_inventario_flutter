import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/articulo_model.dart';
import '../../services/articulo_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/image_uploader.dart';

class EditarArticuloScreen extends StatefulWidget {
  final Articulo articulo;
  final String token;

  const EditarArticuloScreen({
    super.key,
    required this.articulo,
    required this.token,
  });

  @override
  State<EditarArticuloScreen> createState() => _EditarArticuloScreenState();
}

class _EditarArticuloScreenState extends State<EditarArticuloScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _marcaController;
  late TextEditingController _referenciaController;
  late TextEditingController _descripcionController;
  late TextEditingController _stockMinimoController;

  late String _tipoBodega;
  late String _tipo;
  late String _imagenUrl;
  bool _isLoading = false;
  File? _nuevaImagenSeleccionada;

  final List<Map<String, String>> _tiposArticulo = [
    {'value': 'activo_fijo', 'label': 'Activo Fijo'},
    {'value': 'activo_control', 'label': 'Activo Control'},
    {'value': 'consumible', 'label': 'Consumible'},
  ];

  final List<String> _bodegas = ['Sistemas', 'Bmd'];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.articulo.nombreArticulo);
    _marcaController = TextEditingController(text: widget.articulo.marca);
    _referenciaController = TextEditingController(text: widget.articulo.referencia);
    _descripcionController = TextEditingController(text: widget.articulo.descripcionCatalogo);
    _stockMinimoController = TextEditingController(text: widget.articulo.stockMinimo.toString());
    _tipoBodega = widget.articulo.tipoBodega;
    _tipo = widget.articulo.tipo;
    _imagenUrl = widget.articulo.imagenPath;
  }

  Future<void> _actualizarArticulo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('🔄 INICIANDO ACTUALIZACIÓN DE ARTÍCULO');
      print('📝 Datos del formulario:');
      print('   • Nombre: ${_nombreController.text.trim()}');
      print('   • Marca: ${_marcaController.text.trim()}');
      print('   • Referencia: ${_referenciaController.text.trim()}');
      print('   • Tiene nueva imagen: ${_nuevaImagenSeleccionada != null}');

      String? nuevaImagenUrl;

      // Subir nueva imagen si existe
      if (_nuevaImagenSeleccionada != null) {
        print('🖼️ Subiendo NUEVA imagen con datos reales...');
        
        final uploadResult = await UploadService.uploadImage(
          _nuevaImagenSeleccionada!,
          widget.token,
          nombreArticulo: _nombreController.text.trim(),
          marca: _marcaController.text.trim(),
          referencia: _referenciaController.text.trim(),
        );

        if (uploadResult['success']) {
          nuevaImagenUrl = uploadResult['imageUrl'];
          print('✅ Imagen subida exitosamente: $nuevaImagenUrl');
          print('   📄 Nombre del archivo: ${uploadResult['filename']}');
        } else {
          print('❌ Error subiendo imagen: ${uploadResult['error']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error subiendo imagen: ${uploadResult['error']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Preparar el artículo para actualizar
      final articuloActualizado = Articulo(
        idGeneral: widget.articulo.idGeneral,
        nombreArticulo: _nombreController.text.trim(),
        stockMinimo: int.tryParse(_stockMinimoController.text) ?? widget.articulo.stockMinimo,
        descripcionGeneral: _descripcionController.text.trim(),
        idCatalogo: widget.articulo.idCatalogo,
        marca: _marcaController.text.trim(),
        referencia: _referenciaController.text.trim(),
        tipoBodega: _tipoBodega,
        tipo: _tipo,
        descripcionCatalogo: _descripcionController.text.trim(),
        imagenPath: nuevaImagenUrl ?? _imagenUrl,
      );

      print('💾 Guardando artículo en BD...');
      final resultado = await ArticuloService.actualizarArticulo(
        articuloActualizado, 
        widget.token
      );

      if (resultado['success'] == true) {
        print('✅ Artículo actualizado exitosamente en BD');
        
        if (nuevaImagenUrl != null) {
          setState(() {
            _imagenUrl = nuevaImagenUrl!;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${resultado['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 1500));
        Navigator.of(context).pop(true);
      } else {
        print('❌ Error guardando artículo: ${resultado['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${resultado['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('💥 ERROR CRÍTICO: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al actualizar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _probarDiagnostico() async {
    print('🔍 Ejecutando diagnóstico...');
    final resultado = await UploadService.diagnostic(widget.token);
    print('📊 Resultado diagnóstico: $resultado');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Diagnóstico: ${resultado['success'] ? 'Éxito' : 'Error'}'),
        backgroundColor: resultado['success'] ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1422),
      appBar: AppBar(
        title: const Text('Editar Artículo'),
        backgroundColor: const Color(0xFF0948d6),
        actions: [
          if (!_isLoading) IconButton(
            icon: const Icon(Icons.bug_report, size: 20),
            onPressed: _probarDiagnostico,
            tooltip: 'Diagnóstico',
          ),
          IconButton(
            icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _actualizarArticulo,
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Actualizando artículo...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a202c),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF474554)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Color(0xFFf59e0b), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ID: ${widget.articulo.idGeneral} • ${widget.articulo.nombreArticulo}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    ImageUploader(
                      onImageSelected: (imageFile) {
                        setState(() {
                          _nuevaImagenSeleccionada = imageFile;
                        });
                        print('📸 Nueva imagen seleccionada para subir al guardar: ${imageFile.path}');
                      },
                      currentImageUrl: _imagenUrl,
                      token: widget.token,
                      nombreArticulo: _nombreController.text,
                      marca: _marcaController.text,
                      referencia: _referenciaController.text,
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre del Artículo *',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es requerido';
                        }
                        if (value.length < 2) {
                          return 'El nombre debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _marcaController,
                            label: 'Marca *',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La marca es requerida';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _referenciaController,
                            label: 'Referencia/Modelo *',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La referencia es requerida';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            value: _tipo,
                            items: _tiposArticulo,
                            label: 'Tipo de Artículo *',
                            onChanged: (value) => setState(() => _tipo = value!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            value: _tipoBodega,
                            items: _bodegas.map((bodega) => {
                              'value': bodega,
                              'label': bodega
                            }).toList(),
                            label: 'Bodega *',
                            onChanged: (value) => setState(() => _tipoBodega = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _stockMinimoController,
                      label: 'Stock Mínimo *',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El stock mínimo es requerido';
                        }
                        final stock = int.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Ingrese un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _descripcionController,
                      label: 'Descripción *',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La descripción es requerida';
                        }
                        if (value.length < 10) {
                          return 'La descripción debe tener al menos 10 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    if (_nuevaImagenSeleccionada != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a202c),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFf59e0b)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: Color(0xFFf59e0b), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'La imagen se guardará con:',
                                  style: TextStyle(
                                    color: Color(0xFFf59e0b),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_nombreController.text.isNotEmpty ? _nombreController.text : "articulo"}_'
                              '${_marcaController.text.isNotEmpty ? _marcaController.text + "_" : ""}'
                              '${_referenciaController.text.isNotEmpty ? _referenciaController.text + "_" : ""}'
                              'timestamp.jpg',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _actualizarArticulo,
                        icon: _isLoading 
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save, size: 20),
                        label: Text(
                          _isLoading ? 'Actualizando...' : 'Actualizar Artículo',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFf59e0b),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFaca9bb)),
        filled: true,
        fillColor: const Color(0xFF474554).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF474554)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF474554)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0948d6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<Map<String, String>> items,
    required String label,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isNotEmpty ? value : null,
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
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFaca9bb)),
        filled: true,
        fillColor: const Color(0xFF474554).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF474554)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF474554)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _marcaController.dispose();
    _referenciaController.dispose();
    _descripcionController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }
}