import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';

class TextTile extends StatelessWidget {
  final String label;
  final String? sideTitle;

  const TextTile({super.key, required this.label, this.sideTitle});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),

      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        // border: Border.all(color: colors.border),
      ),

      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: sideTitle == null ? '' : '$sideTitle ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        style: TextStyle(color: colors.textPrimary), // shared/base style
      ),
    );
  }
}

class CustomTextWidget extends StatelessWidget {
  final String label;
  final String? labelPrefix;
  final double fontSize;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;
  final double? iconSize;
  final double paddingSize;
  final TextAlign textAlign;
  final FontWeight fontWeight;

  const CustomTextWidget({
    super.key,
    required this.label,
    this.labelPrefix,
    required this.fontSize,
    this.textAlign = TextAlign.center,
    this.fontWeight = FontWeight.w500,
    this.color,
    this.backgroundColor,
    this.icon,
    this.iconSize,
    this.paddingSize = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = color ?? colors.textPrimary;

    return Container(
      padding: EdgeInsets.all(paddingSize),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(context.spacing.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize ?? context.iconSize.md, color: textColor),
            SizedBox(width: context.spacing.xs),
          ],

          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  if (labelPrefix != null)
                    TextSpan(
                      text: labelPrefix,
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                    ),
                  ),
                ],
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              textAlign: textAlign,
            ),
          ),
        ],
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  const GradientText({
    super.key,
    required this.text,
    required this.colors,
    this.fontSize = 24,
    this.fontWeight = FontWeight.bold,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final List<Color> colors;
  final double fontSize;
  final FontWeight fontWeight;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white, // necesario para que el shader se aplique bien
        ),
      ),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    this.size = 64,
    this.backgroundColor,
    this.textColor,
    this.fontWeight = FontWeight.w600,
  });

  final String firstName;
  final String lastName;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final FontWeight fontWeight;

  String get _initials {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? colors.surface,
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: textColor ?? colors.secondary,
          fontSize: size * 0.4,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
