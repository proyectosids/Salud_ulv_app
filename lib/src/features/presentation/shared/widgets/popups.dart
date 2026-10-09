import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/shadows.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final Color? color;
  final Color? backgroundColor;
  final String cancelLabel;
  final String confirmLabel;
  final Color? cancelColor;
  final Color? confirmColor;
  final void Function()? onTap;
  final void Function()? onCancel;
  final bool showCancel;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.cancelLabel = 'No',
    this.confirmLabel = 'Sí',
    this.cancelColor,
    this.confirmColor,
    this.onCancel,
    this.showCancel = true,
  });

  // Static helper that handles showDialog internally
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required void Function()? onTap,
    void Function()? onCancel,
    Color? color,
    Color? backgroundColor,
    String cancelLabel = 'No',
    String confirmLabel = 'Sí',
    Color? cancelColor,
    Color? confirmColor,
    bool showCancel = true,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => CustomAlertDialog(
        title: title,
        message: message,
        color: color ?? context.colors.textPrimary,
        backgroundColor: backgroundColor,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        cancelColor: cancelColor,
        confirmColor: confirmColor,
        showCancel: showCancel,
        onCancel: () {
          Navigator.of(dialogContext).pop();
          onCancel?.call();
        },
        onTap: () {
          Navigator.of(dialogContext).pop();
          onTap?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      title: CustomTextWidget(
        label: title,
        fontSize: context.fontsSize.body,
        textAlign: TextAlign.left,
        fontWeight: .w800,
        color: color,
      ),
      content: CustomTextWidget(
        label: message,
        fontSize: context.fontsSize.caption,
        textAlign: TextAlign.left,
        color: color,
      ),
      actions: [
        if (showCancel)
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            child: Text(
              cancelLabel,
              style: TextStyle(color: cancelColor ?? colors.textSecondary),
            ),
          ),
        TextButton(
          onPressed: onTap,
          child: Text(
            confirmLabel,
            style: TextStyle(color: confirmColor ?? colors.danger),
          ),
        ),
      ],
      elevation: 20,
      backgroundColor: backgroundColor ?? colors.background,
    );
  }
}

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    super.key,
    required this.child,
    this.title,
    this.pWidth,
    this.backgroundColor,
    this.internalPadding,
    this.showCloseButton = true,
    this.showOkButton = false,
    this.okLabel = 'Aceptar',
    this.onOkPressed,
  });

  final Widget child;
  final String? title;
  final double? pWidth;
  final Color? backgroundColor;
  final double? internalPadding;
  final bool showCloseButton;

  /// Shows a confirm/OK button at the bottom, for decisions or committing a value.
  final bool showOkButton;

  /// Label for the OK button.
  final String okLabel;

  /// Called when OK is tapped. Dialog closes automatically after.
  /// If you need the result to carry a value, return it via Navigator.pop
  /// yourself inside this callback instead, and leave onOkPressed null.
  final VoidCallback? onOkPressed;

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    double? pWidth,
    Color? backgroundColor,
    double? internalPadding,
    bool showCloseButton = true,
    bool showOkButton = false,
    String okLabel = 'Aceptar',
    VoidCallback? onOkPressed,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomDialog(
        title: title,
        pWidth: pWidth,
        backgroundColor: backgroundColor,
        internalPadding: internalPadding,
        showCloseButton: showCloseButton,
        showOkButton: showOkButton,
        okLabel: okLabel,
        onOkPressed: onOkPressed,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    onTapedOK(Function onOkPressed) {
      onOkPressed();
      Navigator.pop(context);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Container(
        width: pWidth ?? double.infinity,
        padding: EdgeInsets.all(internalPadding ?? spacing.lg),
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.surface,
          borderRadius: BorderRadius.circular(spacing.radiusLg),
          border: Border.all(color: colors.border),
          boxShadow: context.shadows.boxShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || showCloseButton)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Expanded(
                      child: CustomTextWidget(
                        label: title!,
                        fontSize: context.fontsSize.body,
                        textAlign: TextAlign.left,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const Spacer(),
                  if (showCloseButton)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: colors.danger.withAlpha(150),
                        size: context.iconSize.md,
                      ),
                    ),
                ],
              ),
            if (title != null || showCloseButton) SizedBox(height: spacing.md),

            child,

            if (showOkButton) ...[
              SizedBox(height: spacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (onOkPressed != null) {
                      // onOkPressed!();
                      onTapedOK(onOkPressed!);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.onSecondary,
                    padding: EdgeInsets.symmetric(vertical: spacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMd),
                    ),
                  ),
                  child: Text(okLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
