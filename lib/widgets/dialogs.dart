import 'package:flutter/material.dart';

import '../state/vocab_controller.dart';
import '../theme/app_theme.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
      title: Text(title, style: AppTheme.heading(20)),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? const Color(0xFFE11D48) : AppColors.brand600,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Pide confirmación antes de reemplazar el vocabulario actual si tiene
/// cambios sin guardar. Devuelve `true` si se puede continuar.
Future<bool> confirmDiscardChanges(
  BuildContext context,
  VocabController controller, {
  String action = 'continuar',
}) {
  if (!controller.hasUnsavedWork) return Future.value(true);
  return confirmDialog(
    context,
    title: 'Cambios sin guardar',
    message: 'El vocabulario actual tiene cambios sin guardar. Si decides $action, se perderán.',
    confirmLabel: 'Descartar cambios',
    destructive: true,
  );
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}
