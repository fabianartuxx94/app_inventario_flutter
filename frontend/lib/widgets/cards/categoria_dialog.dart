import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/categorias_service.dart';
import '../../providers/auth_provider.dart';

class CategoriaDialog extends StatefulWidget {
  final Map<String, dynamic>? categoria;
  final Function()? onGuardado;
  final String? nombrePredefinido; // ← NUEVO PARÁMETRO

  const CategoriaDialog({
    super.key,
    this.categoria,
    this.onGuardado,
    this.nombrePredefinido, // ← NUEVO PARÁMETRO
  });

  @override
  State<CategoriaDialog> createState() => _CategoriaDialogState();
}

class _CategoriaDialogState extends State<CategoriaDialog> {
  final TextEditingController _nombreController = TextEditingController();

  bool get _isEdit => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nombreController.text = widget.categoria!['nombre'] ?? '';
    } else if (widget.nombrePredefinido != null) {
      // ✅ PRELLENAR CON EL NOMBRE DE LA BÚSQUEDA
      _nombreController.text = widget.nombrePredefinido!;
    }
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
            
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          onPressed: _guardarCategoria,
          child: Text(_isEdit ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}