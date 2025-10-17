import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/articulo_model.dart';
import '../../services/articulo_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/image_uploader.dart';

class CrearArticuloScreen extends StatefulWidget {
  final String token;
  const CrearArticuloScreen({super.key, required this.token});

  @override
  State<CrearArticuloScreen> createState() => _CrearArticuloScreenState();
}

class _CrearArticuloScreenState extends State<CrearArticuloScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _marcaController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _stockMinimoController = TextEditingController(text: '0');

  String _tipoBodega = 'Sistemas';
  String _tipo = 'activo_fijo';
  String _imagenUrl = '';
  bool _isLoading = false;
  File? _imagenSeleccionada;

  final List<Map<String, String>> _tiposArticulo = [
    {'value': 'activo_fijo', 'label': 'Activo Fijo'},
    {'value': 'activo_control', 'label': 'Activo Control'},
    {'value': 'consumible', 'label': 'Consumible'},
  ];
  final List<String> _bodegas = ['Sistemas', 'Bmd'];

  Future<void> _crearArticulo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imagenFinal = _imagenUrl;

      // Subir imagen si hay una seleccionada
      if (_imagenSeleccionada != null) {
        final uploadResult = await UploadService.uploadImage(
          _imagenSeleccionada!,
          widget.token,
          nombreArticulo: _nombreController.text.trim(),
          marca: _marcaController.text.trim(),
          referencia: _referenciaController.text.trim(),
        );
        
        if (uploadResult['success']) {
          imagenFinal = uploadResult['imageUrl']!;
        } else {
          throw Exception(uploadResult['error']);
        }
      }

      final nuevoArticulo = Articulo(
        idGeneral: 0,
        nombreArticulo: _nombreController.text.trim(),
        stockMinimo: int.tryParse(_stockMinimoController.text) ?? 0,
        descripcionGeneral: _descripcionController.text.trim(),
        idCatalogo: 0,
        marca: _marcaController.text.trim(),
        referencia: _referenciaController.text.trim(),
        tipoBodega: _tipoBodega,
        tipo: _tipo,
        descripcionCatalogo: _descripcionController.text.trim(),
        imagenPath: imagenFinal,
      );

      final resultado = await ArticuloService.crearArticulo(
        nuevoArticulo,
        widget.token,
      );

      if (resultado['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message']!),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception(resultado['error']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1422),
      appBar: AppBar(
        title: const Text('Crear Nuevo Artículo'),
        backgroundColor: const Color(0xFF0948d6),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _crearArticulo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    ImageUploader(
                      onImageSelected: (imageFile) {
                        setState(() {
                          _imagenSeleccionada = imageFile;
                        });
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
                      label: 'Nombre del Artículo',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es requerido';
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
                            label: 'Marca',
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
                            label: 'Referencia/Modelo',
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
                            label: 'Tipo de Artículo',
                            onChanged: (value) {
                              setState(() {
                                _tipo = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            value: _tipoBodega,
                            items: _bodegas
                                .map((bodega) => {
                                      'value': bodega,
                                      'label': bodega,
                                    })
                                .toList(),
                            label: 'Bodega',
                            onChanged: (value) {
                              setState(() {
                                _tipoBodega = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _stockMinimoController,
                      label: 'Stock Mínimo',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descripcionController,
                      label: 'Descripción',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La descripción es requerida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _crearArticulo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Crear Artículo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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