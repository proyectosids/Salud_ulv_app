import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/shadows.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FaIconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final fontSize = context.fonts;
    final iconSize = context.iconSize;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        boxShadow: context.shadows.smBoxShadow,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        maxLines: maxLines,
        enabled: enabled,

        style: TextStyle(color: colors.textPrimary, fontSize: fontSize.caption),

        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(
            color: colors.textPrimary,
            fontSize: fontSize.caption,
          ),
          hintStyle: TextStyle(
            color: colors.textPrimary,
            fontSize: fontSize.caption,
          ),
          prefixIcon: prefixIcon != null
              ? Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: FaIcon(
                    prefixIcon,
                    size: iconSize.sm,
                    color: colors.secondary,
                  ),
                )
              : null,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: colors.background,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
            borderSide: BorderSide(color: colors.border, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
            borderSide: BorderSide(color: colors.danger, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
            borderSide: BorderSide(color: colors.danger, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class CustomPasswordField extends StatefulWidget {
  const CustomPasswordField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconSize = context.iconSize;

    return CustomTextFormField(
      label: widget.label,
      hintText: widget.hintText,
      controller: widget.controller,
      validator: widget.validator,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      obscureText: _obscureText, // 👈 controlado por el estado interno
      prefixIcon: FontAwesomeIcons.lock,
      suffixIcon: IconButton(
        icon: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: FaIcon(
            _obscureText ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
            size: iconSize.sm,
            color: colors.secondary,
          ),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText; // 👈 aquí cambia al picar
          });
        },
      ),
    );
  }
}

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.length,
    this.controller,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
  });

  final int length;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleChange(String value, int index) {
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    _notifyChange();
  }

  void _handleKeyBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _notifyChange();
    }
  }

  void _notifyChange() {
    final code = _controllers.map((c) => c.text).join();

    // 👇 sincroniza con el controller externo, si lo pasaron
    widget.controller?.text = code;

    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(boxShadow: context.shadows.smBoxShadow),

          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace) {
                _handleKeyBackspace(index);
              }
            },
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              autofocus: widget.autofocus && index == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(
                fontSize: context.fontsSize.body,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: colors.background,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMd),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMd),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMd),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
              onChanged: (value) => _handleChange(value, index),
            ),
          ),
        );
      }),
    );
  }
}
