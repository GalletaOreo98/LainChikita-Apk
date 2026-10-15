import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Botón grande de los menús (gacha, datos del juego). Si [onPressed] es null se muestra deshabilitado.
class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primaryBtn,
    this.disabledColor,
    this.disabledTextColor = AppColors.disabledText,
    this.padding = const EdgeInsets.all(10.0),
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? disabledColor;
  final Color disabledTextColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(380, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        backgroundColor: color,
        disabledBackgroundColor: disabledColor,
        padding: padding,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(color: enabled ? AppColors.primaryText : disabledTextColor, fontSize: 34.0),
        textAlign: TextAlign.center,
      ),
    );
  }
}
