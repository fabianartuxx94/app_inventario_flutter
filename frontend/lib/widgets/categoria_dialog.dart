import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/categorias_service.dart';
import '../providers/auth_provider.dart';

class CategoriaDialog extends StatefulWidget {
  final Map<String, dynamic>? categoria;
  final Function()? onGuardado;

  const CategoriaDialog({
    super.key,
    this.categoria,
    this.onGuardado,
  });

  @override
  State<CategoriaDialog> createState() => _CategoriaDialogState();
}

class _CategoriaDialogState extends State<CategoriaDialog> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _etiquetasController = TextEditingController();

  bool get _isEdit => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nombreController.text = widget.categoria!['nombre'] ?? '';
      _stockController.text = (widget.categoria!['stock_minimo'] ?? 0).toString();
      _etiquetasController.text = _formatEtiquetas(widget.categoria!['etiquetas']);
    }
  }

  String _formatEtiquetas(dynamic etiquetas) {
    if (etiquetas == null) return '';
    if (etiquetas is String) {
      try {
        final parsed = List<String>.from(json.decode(etiquetas));
        return parsed.join(', ');
      } catch (e) {
        return etiquetas;
      }
    }
    if (etiquetas is List) {
      return etiquetas.join(', ');
    }
    return '';
  }

  Future<void> _guardarCategoria() async {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de la categoría es requerido')),
      );
      return;
    }

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      
      final categoriaData = {
        "id": widget.categoria?['id'] ?? 0,
        "nombre": _nombreController.text.trim(),
        "stock_minimo": int.tryParse(_stockController.text) ?? 0,
        "etiquetas": _etiquetasController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      };

      await CategoriasService.guardarCategoria(categoriaData, token);
      
      if (widget.onGuardado != null) {
        widget.onGuardado!();
      }

      Navigator.pop(context, categoriaData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit 
              ? 'Categoría actualizada exitosamente' 
              : 'Categoría creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEdit ? 'Editar categoría' : 'Nueva categoría',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock mínimo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _etiquetasController,
              decoration: const InputDecoration(
                labelText: 'Etiquetas (separadas por comas)',
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
          child: Text(_isEdit ? 'Actualizar' : 'Guardar'),
          onPressed: _guardarCategoria,
        ),
      ],
    );
  }
}