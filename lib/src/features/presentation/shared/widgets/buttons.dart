import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/shadows.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

// import 'package:salud_ulv_app/src/features/presentation/themes/fonts.dart';
// import 'package:salud_ulv_app/src/features/presentation/themes/dark_theme.dart';
// // import 'package:salud_ulv_app/src/features/presentation/themes/themes.dart';

class SelectFieldButton extends StatelessWidget {
  final List<String> fieldsName;
  final List<String> fields;
  final void Function()? onTap;
  // final Function action;

  const SelectFieldButton({
    super.key,
    required this.fieldsName,
    required this.fields,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // const cornerValue = WidgetCircleRadius.buttonRadius;

    return ListView.builder(
      itemCount: fields.length,
      itemBuilder: (context, index) {
        final fieldName = fieldsName[index];

        return ListTile(title: Text(fieldName), onTap: onTap);
      },
    );
  }
}

class SimpleButton extends StatelessWidget {
  const SimpleButton({
    super.key,
    this.label,
    required this.onPressed,
    this.fontSize,
    this.color,
    this.borderColor,
    this.textColor,
    this.fullWidth = false,
    this.maxLines = 1,
    this.icon,
  });

  final String? label;
  final VoidCallback onPressed;
  final double? fontSize;
  final Color? color;
  final Color? borderColor;
  final Color? textColor;
  final IconData? icon;

  /// Si es true, el botón toma todo el ancho disponible.
  /// Si es false, se ajusta al tamaño del texto (hug content).
  final bool fullWidth;

  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final backgroundColor = color ?? colors.primary;
    final foregroundColor = textColor ?? colors.foregroundFor(backgroundColor);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(context.spacing.radiusMd),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: context.spacing.md - 6,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(context.spacing.radiusLg),
            border: Border.all(color: borderColor ?? colors.border),
            boxShadow: context.shadows.smBoxShadow,
          ),
          child: icon != null
              ? Icon(icon, size: context.iconSize.md, color: foregroundColor)
              : Text(
                  label ?? '',
                  textAlign: TextAlign.center,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize ?? context.fontsSize.caption,
                  ),
                ),
        ),
      ),
    );

    // fullWidth=true -> ocupa todo el ancho disponible
    // fullWidth=false -> se ajusta al texto, sin importar el padre (Row/Column)
    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : IntrinsicWidth(child: button);
  }
}

class IconTextTile extends StatelessWidget {
  const IconTextTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.fontSize,
    this.iconSize,
    // this.color
    // this.selected = false,
  });

  final IconData icon;
  final double? fontSize;
  final double? iconSize;
  final String label;
  final VoidCallback? onTap;
  // final Color? color;
  // final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    // final fontSize = context.fonts;
    // final iconSize = context.iconSize;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(spacing.radiusMd),

        child: Container(
          width: .maxFinite,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),

          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(spacing.radiusMd),
            border: Border.all(color: colors.border),
          ),

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize ?? context.iconSize.md,
                color: colors.secondary,
              ),
              SizedBox(width: spacing.sm),
              Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: fontSize ?? context.fontsSize.caption,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridActionTile extends StatelessWidget {
  const GridActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final shadows = context.shadows;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusLg),
        boxShadow: shadows.boxShadow,
      ),
      child: Material(
        color: colors.primary,
        borderRadius: BorderRadius.circular(spacing.radiusLg),

        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(spacing.radiusLg),
          child: Stack(
            children: [
              // background icon, oversized and faded
              Positioned(
                right: -30,
                bottom: -30,
                child: FaIcon(
                  icon,
                  size: 150,
                  color: colors.onPrimary.withValues(alpha: 0.2),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FaIcon(icon, color: colors.onPrimary, size: 40),
                    SizedBox(height: spacing.sm),
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.iconSize = 24,
    this.fontSize = 10,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.colors.textPrimary;
    final fg = onPressed == null ? base.withValues(alpha: 0.4) : base;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: iconSize),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fontSize, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class SelectProgressTypeButton extends StatelessWidget {
//   final String title;
//   final Color bgColor;
//   final Widget page;

//   const SelectProgressTypeButton({super.key, required this.title, required this.bgColor, required this.page});

//   @override
//   Widget build(BuildContext context) {
//     final edgeValue = WidgetCircleRadius.bigButtonRadius;
//     final double screenWidth = MediaQuery.of(context).size.width;

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(context, MaterialPageRoute(builder: (context) => page));
//       },
//       child: Container(
//         height: 150,
//         width: screenWidth,
//         decoration: BoxDecoration(
//           shape: .rectangle,
//           borderRadius: BorderRadius.circular(edgeValue),
//           color: bgColor,
//         ),

//         child: Padding(
//           padding: EdgeInsets.all(2),
//           child: Column(
//             mainAxisAlignment: .center,
//             children: [
//               Text(title, style: SizedFonts.largeFont,)
//             ],
//           ),
//         ),
//       ));
//   }
// }

class CustomSelectableCard<T> extends StatelessWidget {
  const CustomSelectableCard({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.titleSize,
    this.info,
    this.infoSize,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.pWidth,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T> onChanged;

  final String title;
  final double? titleSize;
  final String? info;
  final double? infoSize;
  final IconData? icon;

  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final double? pWidth;

  bool get _isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    final selected = _isSelected;
    final indicatorColor = selected
        ? (selectedColor ?? colors.primary)
        : (unselectedColor ?? colors.border);

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: pWidth ?? double.infinity,
        padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
          color: selected
              ? (selectedBackgroundColor ??
                    colors.primary.withValues(alpha: 0.08))
              : (backgroundColor ?? colors.surface),
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          border: Border.all(
            color: selected ? (selectedColor ?? colors.primary) : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // selection circle, top-left
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: indicatorColor, width: 2),
                    color: selected ? indicatorColor : Colors.transparent,
                  ),
                  child: selected
                      ? Icon(
                          Icons.check,
                          size: context.iconSize.sm,
                          color: colors.onPrimary,
                        )
                      : null,
                ),
                SizedBox(width: spacing.sm),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              size: context.iconSize.sm,
                              color: colors.textPrimary,
                            ),
                            SizedBox(width: spacing.xs),
                          ],
                          Expanded(
                            child: CustomTextWidget(
                              label: title,
                              fontSize: titleSize ?? context.fontsSize.caption,
                              textAlign: TextAlign.left,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (info != null) ...[
                        SizedBox(height: spacing.xxs),
                        CustomTextWidget(
                          label: info!,
                          fontSize: infoSize ?? context.fontsSize.caption,
                          textAlign: TextAlign.left,
                          color: colors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
