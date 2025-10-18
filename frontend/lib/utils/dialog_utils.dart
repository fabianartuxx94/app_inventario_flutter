import 'package:flutter/material.dart';
import '../widgets/categoria_dialog.dart';

class DialogUtils {
  static Future<Map<String, dynamic>?> showCategoriaDialog({
    required BuildContext context,
    Map<String, dynamic>? categoria,
    Function()? onGuardado,
  }) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CategoriaDialog(
        categoria: categoria,
        onGuardado: onGuardado,
      ),
    );
  }
}