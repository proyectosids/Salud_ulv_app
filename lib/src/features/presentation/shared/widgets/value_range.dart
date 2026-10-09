import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class ValueRangeIndicator extends StatelessWidget {
  const ValueRangeIndicator({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.title,
    this.colors,
    this.height = 12,
    this.markerSize = 22,
    this.borderRadius = 999,
    this.showTitleAndValue = true,
    this.showMinMax = true,
    this.showThumbValue = false,
    this.fontSize,
  }) : assert(colors == null || colors.length == 5);

  final double value;
  final double min;
  final double max;

  /// Título opcional a la izquierda en el encabezado.
  final String? title;

  /// Cinco colores para el gradiente.
  final List<Color>? colors;

  final double height;
  final double markerSize;
  final double borderRadius;
  final double? fontSize;

  /// Controla si se muestra la fila superior con el título y el valor.
  final bool showTitleAndValue;

  /// Controla si se muestran los valores min y max debajo de la barra.
  final bool showMinMax;

  /// Toggle para mostrar u ocultar el valor numérico dentro del indicador/círculo.
  final bool showThumbValue;

  double get _normalizedValue {
    if (max <= min) return 0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final position = _normalizedValue;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    final rangeColors =
        colors ??
        [
          appColors.low,
          appColors.tertiary,
          appColors.success,
          appColors.warning,
          appColors.danger,
        ];
    final effectiveFontSize = fontSize ?? context.fontsSize.body;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Título a la izquierda y Valor a la derecha (Opcional)
        if (showTitleAndValue && (title != null)) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null)
                CustomTextWidget(
                  label: title!,
                  fontSize: effectiveFontSize,
                  fontWeight: .w900,
                )
              else
                const SizedBox.shrink(),
              CustomTextWidget(
                label: value.toStringAsFixed(1),
                fontSize: effectiveFontSize,
                fontWeight: .w900,
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
        ],

        // 2. Barra del indicador con el slider
        SizedBox(
          height: markerSize,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final markerLeft = (width - markerSize) * position;

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Gradient track
                  ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: rangeColors,
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Circle thumb marker
                  Positioned(
                    left: markerLeft,
                    child: Container(
                      width: markerSize,
                      height: markerSize,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.onSurface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            color: colorScheme.shadow.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                      // Toggle para ver o no el valor dentro del círculo
                      child: showThumbValue
                          ? Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Text(
                                    value.toStringAsFixed(0),
                                    style: textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 3. Límites Mínimo y Máximo debajo de la barra (Opcional)
        if (showMinMax) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.toStringAsFixed(1),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                max.toStringAsFixed(1),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
