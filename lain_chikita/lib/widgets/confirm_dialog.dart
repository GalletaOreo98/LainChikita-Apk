import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/translations.dart';

/// Muestra un diálogo de confirmación. Devuelve true solo si el usuario confirmó.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(title, style: const TextStyle(color: AppColors.primaryText, fontSize: 24.0)),
      content: Text(message, style: const TextStyle(color: AppColors.primaryText, fontSize: 24.0)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr('cancel'), style: const TextStyle(color: AppColors.primaryText, fontSize: 30.0)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel, style: const TextStyle(color: AppColors.focusItem, fontSize: 30.0)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
