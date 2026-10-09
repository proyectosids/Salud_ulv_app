import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';

class CustomSnackBar {
  CustomSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? context.colors.secondary,
        duration: duration,
        behavior: .floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.spacing.radiusMd),
        ),
        action: action,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, backgroundColor: context.colors.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, backgroundColor: context.colors.danger);
  }
}
