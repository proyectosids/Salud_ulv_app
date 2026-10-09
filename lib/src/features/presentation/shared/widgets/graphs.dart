import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'dart:math';

import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

enum ChartType { line, bar }

// ============================================================
// MAIN WIDGET: CustomDataChart
// Quick map of the file:
//   1. Constructor / options ............ fields below
//   2. build() .......................... data cleanup + layout
//   3. _buildHeader ..................... [TITLE] title + valueData pill
//   4. _gridData ........................ [GRID] grid lines
//   5. _titlesData ...................... [AXIS] axis numbers / dates
//   6. _downsample / _calculateNiceInterval ... data helpers
//   7. _buildLineChart .................. line chart ([COLOR], [FILL])
//   8. _buildBarChart ................... bar chart ([COLOR], [FILL])
//   9. ChartPointStyle .................. dots, curve, bar width
// ============================================================
class CustomDataChart extends StatelessWidget {
  final List<num> values;
  final List<dynamic>? times;
  final ChartType type;
  final double height;

  /// [TITLE] Title text, top-left of the chart.
  final String? title;

  /// [TITLE] Texto al extremo derecho del título (pill on the far right).
  final String? valueData;

  /// [GRID] Show / hide the grid lines.
  final bool grid;

  /// [GRID] Custom grid color. If null, uses textPrimary at 20% opacity.
  final Color? gridColor;

  /// [FILL] Línea: rellena el área. Barras: sólidas (true) o solo contorno (false).
  final bool fill;

  /// [SWAP] Línea: el tiempo pasa al eje Y y el valor al eje X. No afecta barras.
  final bool inverted;

  final String Function(num value, dynamic time)? tooltipLabelBuilder;

  /// [TOOLTIP] Background color of the tooltip shown when touching the chart.
  final Color? tooltipBackgroundColor;

  /// Max number of points/bars drawn (more data gets averaged in buckets).
  final int maxPoints;

  /// Approximate number of labels on the time axis.
  final int maxLabels;

  /// Visual style of dots / curve / bar width (see ChartPointStyle at the bottom).
  final ChartPointStyle pointStyle;

  const CustomDataChart({
    super.key,
    required this.values,
    this.times,
    this.type = ChartType.line,
    this.height = 150,
    this.title,
    this.valueData,
    this.grid = true,
    this.gridColor,
    this.fill = true,
    this.inverted = false,
    this.tooltipLabelBuilder,
    this.tooltipBackgroundColor,
    this.maxPoints = 15,
    this.maxLabels = 10,
    this.pointStyle = const ChartPointStyle(),
  });

  /// [SWAP] Solo la gráfica de línea intercambia ejes.
  bool get _swap => inverted && type == ChartType.line;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Clean the raw data: drop NaN / Infinity values and pair each value
    // with its time (or its index when no times were given).
    final rawData = <_ChartPoint>[];
    for (int i = 0; i < values.length; i++) {
      final value = values[i].toDouble();
      if (!value.isFinite) continue;
      rawData.add(
        _ChartPoint(
          value: value,
          time: times != null && i < times!.length ? times![i] : i,
        ),
      );
    }

    // Empty state text
    if (rawData.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Sin datos', style: TextStyle(color: colors.textPrimary)),
        ),
      );
    }

    // Reduce to maxPoints, and compute the max value / axis interval.
    final validData = _downsample(rawData, maxPoints);
    final maxValue = validData.map((p) => p.value).reduce(max);
    final maxY = maxValue <= 0 ? 1.0 : maxValue;
    final interval = _calculateNiceInterval(maxY);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // [TITLE] Header row (title + valueData)
        if (title != null || valueData != null) _buildHeader(context, colors),
        // Chart area. Its size comes from `height`.
        SizedBox(
          height: height,
          child: type == ChartType.line
              ? _buildLineChart(colors, validData, maxY, interval)
              : _buildBarChart(colors, validData, maxY, interval),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // [TITLE] HEADER: title on the left, valueData pill on the right
  // ------------------------------------------------------------

  Widget _buildHeader(BuildContext context, dynamic colors) {
    final spacing = context.spacing;
    final fontSize = context.fontsSize;

    return Padding(
      // Space between the header and the chart
      padding: EdgeInsets.only(bottom: spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (title != null)
            Expanded(
              // [TITLE] Title text style (color, weight, size)
              child: CustomTextWidget(
                label: title!,
                textAlign: .left,
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: fontSize.body,
              ),
            )
          else
            const Spacer(),
          if (valueData != null) ...[
            SizedBox(width: spacing.md),
            // [TITLE] valueData pill: background color and shape
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.md,
                vertical: spacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.primary.withValues(
                  alpha: 0.12,
                ), // [COLOR] pill background
                borderRadius: BorderRadius.circular(20),
              ),
              // [TITLE] valueData text style
              child: CustomTextWidget(
                label: valueData!,
                color: colors.secondary, // [COLOR] pill text
                fontWeight: FontWeight.w700,
                fontSize: fontSize.body,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // [GRID] GRID LINES
  // ------------------------------------------------------------

  // [COLOR] Grid line color: gridColor if given, else textPrimary at 20%.
  Color _gridLineColor(dynamic colors) =>
      gridColor ?? colors.textPrimary.withValues(alpha: 0.2);

  FlGridData _gridData(dynamic colors, double interval) {
    final lineColor = _gridLineColor(colors);

    if (_swap) {
      // [SWAP] Valores en X: líneas verticales en cada intervalo
      return FlGridData(
        show: grid,
        drawHorizontalLine: false,
        drawVerticalLine: true,
        verticalInterval: interval,
        getDrawingVerticalLine: (v) =>
            FlLine(color: lineColor, strokeWidth: 1, dashArray: [4, 4]),
      );
    }

    // Normal: horizontal dashed lines at each value interval
    return FlGridData(
      show: grid,
      drawHorizontalLine: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (v) =>
          FlLine(color: lineColor, strokeWidth: 1, dashArray: [4, 4]),
    );
  }

  // ------------------------------------------------------------
  // [AXIS] AXIS TITLES (numbers and dates around the chart)
  // ------------------------------------------------------------

  // [COLOR] Axis text style: color, opacity and size of numbers/dates.
  TextStyle _axisStyle(dynamic colors) => TextStyle(
    color: colors.textPrimary.withValues(alpha: 0.75),
    fontSize: 11,
  );

  FlTitlesData _titlesData(
    dynamic colors,
    List<_ChartPoint> data,
    double interval,
  ) {
    final axisStyle = _axisStyle(colors);

    // [AXIS] Numeric axis (the values). `reserved` = space taken by the labels.
    AxisTitles valueAxis({double reserved = 36}) => AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: reserved,
        interval: interval,
        getTitlesWidget: (value, meta) =>
            Text(value.toStringAsFixed(0), style: axisStyle),
      ),
    );

    // [AXIS] Time axis (dates / durations)
    AxisTitles categoryAxis({required double reserved}) => AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: reserved,
        interval: 1,
        getTitlesWidget: (value, meta) =>
            _categoryLabel(colors, value.round(), data),
      ),
    );

    const off = AxisTitles(sideTitles: SideTitles(showTitles: false));

    // Normal: values on the left, time at the bottom
    if (!_swap) {
      return FlTitlesData(
        topTitles: off,
        rightTitles: off,
        leftTitles: valueAxis(),
        bottomTitles: categoryAxis(reserved: 28),
      );
    }

    // [SWAP] Tiempo a la izquierda (Y), valores abajo (X)
    return FlTitlesData(
      topTitles: off,
      rightTitles: off,
      leftTitles: categoryAxis(reserved: 44),
      bottomTitles: valueAxis(reserved: 28),
    );
  }

  // ------------------------------------------------------------
  // DOWNSAMPLING (averages data into buckets when there is too much)
  // ------------------------------------------------------------

  List<_ChartPoint> _downsample(List<_ChartPoint> data, int maxPoints) {
    if (data.length <= maxPoints || maxPoints <= 0) return data;

    final bucketSize = (data.length / maxPoints).ceil();
    final result = <_ChartPoint>[];

    for (int i = 0; i < data.length; i += bucketSize) {
      final end = min(i + bucketSize, data.length);
      final bucket = data.sublist(i, end);

      final avgValue =
          bucket.map((p) => p.value).reduce((a, b) => a + b) / bucket.length;
      final representativeTime = bucket[bucket.length ~/ 2].time;

      result.add(_ChartPoint(value: avgValue, time: representativeTime));
    }
    return result;
  }

  // ------------------------------------------------------------
  // NICE INTERVAL (round steps for the value axis: 1, 2, 5, 10...)
  // ------------------------------------------------------------

  double _calculateNiceInterval(double maxY, {int targetSteps = 4}) {
    if (maxY <= 0) return 1;

    final rawStep = maxY / targetSteps;
    final magnitude = pow(10, (log(rawStep) / ln10).floor()).toDouble();
    final residual = rawStep / magnitude;

    double niceResidual;
    if (residual > 5) {
      niceResidual = 10;
    } else if (residual > 2) {
      niceResidual = 5;
    } else if (residual > 1) {
      niceResidual = 2;
    } else {
      niceResidual = 1;
    }

    final interval = niceResidual * magnitude;
    return interval < 1 ? 1 : interval;
  }

  // ------------------------------------------------------------
  // LABELS (how dates / durations are written)
  // ------------------------------------------------------------

  // [AXIS] Format of the time labels: DateTime -> d/m, Duration -> 5m / 1h20m
  String _labelFor(dynamic time) {
    if (time is DateTime) return '${time.day}/${time.month}';

    if (time is Duration) {
      final totalSeconds = time.inSeconds;
      if (totalSeconds < 60) return '${totalSeconds}s';

      final hours = time.inHours;
      final minutes = time.inMinutes.remainder(60);
      if (hours > 0) return '${hours}h${minutes}m';
      return '${minutes}m';
    }

    return time.toString();
  }

  // [TOOLTIP] Text shown when touching a point / bar (value + date)
  String _tooltipTextFor(num value, dynamic time) {
    if (tooltipLabelBuilder != null) return tooltipLabelBuilder!(value, time);
    return '${value.toStringAsFixed(1)}\n${_labelFor(time)}';
  }

  // [AXIS] Decides which time labels are shown (only ~maxLabels of them)
  Widget _categoryLabel(dynamic colors, int index, List<_ChartPoint> data) {
    if (index < 0 || index >= data.length) return const SizedBox.shrink();

    final labelStep = max(1, (data.length / maxLabels).ceil());
    final isFirst = index == 0;
    final isLast = index == data.length - 1;

    if (!isFirst && !isLast && index % labelStep != 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: _swap
          ? const EdgeInsets.only(right: 8)
          : const EdgeInsets.only(top: 10),
      child: Text(_labelFor(data[index].time), style: _axisStyle(colors)),
    );
  }

  // ------------------------------------------------------------
  // LINE CHART
  // ------------------------------------------------------------

  Widget _buildLineChart(
    dynamic colors,
    List<_ChartPoint> data,
    double maxY,
    double interval,
  ) {
    final last = max(1, data.length - 1).toDouble();

    // [SWAP] Normal:    x = tiempo (índice), y = valor
    //        Invertido: x = valor,           y = tiempo (índice)
    final spots = data.asMap().entries.map((e) {
      return _swap
          ? FlSpot(e.value.value, e.key.toDouble())
          : FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        // [SWAP] Axis limits. When swapped, X = values (0..maxY), Y = time (0..last)
        minX: _swap ? 0 : null,
        maxX: _swap ? maxY : null,
        minY: 0,
        maxY: _swap ? last : maxY,
        gridData: _gridData(colors, interval), // [GRID]
        borderData: FlBorderData(show: false),
        titlesData: _titlesData(colors, data, interval), // [AXIS]
        // [TOOLTIP] Popup when touching the line
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                tooltipBackgroundColor ??
                colors.surface, // [COLOR] tooltip background
            getTooltipItems: (touched) {
              return touched.map((spot) {
                final index = _swap ? spot.y.round() : spot.x.toInt();
                final value = _swap ? spot.x : spot.y;

                if (index < 0 || index >= data.length) return null;

                return LineTooltipItem(
                  _tooltipTextFor(value, data[index].time),
                  TextStyle(
                    color: colors.textPrimary, // [COLOR] tooltip text
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            // El suavizado asume x creciente, se desactiva al intercambiar ejes
            isCurved: pointStyle.isCurved && !_swap,
            curveSmoothness: pointStyle.curveSmoothness,
            preventCurveOverShooting: !_swap,
            barWidth: pointStyle.lineWidth, // line thickness
            isStrokeCapRound: true,

            // [COLOR] LINE COLOR: gradient across the line, left to right
            gradient: LinearGradient(
              colors: [colors.primary, colors.secondary, colors.tertiary],
            ),

            // [COLOR] Dots on the line (only if pointStyle.showDots is true)
            dotData: FlDotData(
              show: pointStyle.showDots,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: pointStyle.dotRadius,
                  color: pointStyle.dotColor ?? colors.primary, // dot color
                  strokeWidth: 2,
                  strokeColor: colors.surface, // ring around the dot
                );
              },
            ),

            // [FILL] AREA UNDER THE LINE. `show: fill` turns it on/off.
            // [COLOR] The gradient below is the fill color (fades to transparent).
            belowBarData: BarAreaData(
              show: fill,
              gradient: LinearGradient(
                begin: _swap ? Alignment.centerLeft : Alignment.topCenter,
                end: _swap ? Alignment.centerRight : Alignment.bottomCenter,
                colors: _swap
                    ? [
                        colors.primary.withValues(alpha: 0.0),
                        colors.primary.withValues(alpha: 0.25),
                      ]
                    : [
                        colors.secondary.withValues(
                          alpha: 0.35,
                        ), // top: stronger
                        colors.tertiary.withValues(
                          alpha: 0.15,
                        ), // top: stronger
                        colors.primary.withValues(
                          alpha: 0.05,
                        ), // bottom: transparent
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BAR CHART (siempre normal)
  // ------------------------------------------------------------

  Widget _buildBarChart(
    dynamic colors,
    List<_ChartPoint> data,
    double maxY,
    double interval,
  ) {
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        gridData: _gridData(colors, interval), // [GRID]
        borderData: FlBorderData(show: false),
        titlesData: _titlesData(colors, data, interval), // [AXIS]
        // [TOOLTIP] Popup when touching a bar
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) =>
                tooltipBackgroundColor ??
                colors.surface, // [COLOR] tooltip background
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= data.length) return null;

              return BarTooltipItem(
                _tooltipTextFor(rod.toY, data[groupIndex].time),
                TextStyle(
                  color: colors.textPrimary, // [COLOR] tooltip text
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),

        // One group (one bar) per data point
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                width: pointStyle.barChartWidth, // bar width
                borderRadius: BorderRadius.circular(pointStyle.barBorderRadius),

                // [FILL] + [COLOR] BAR COLOR when fill is true:
                // gradient from bottom (onTertiary) to top (primary)
                gradient: fill
                    ? LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          colors.onTertiary,
                          colors.secondary,
                          colors.primary,
                        ],
                      )
                    : null,

                // [FILL] When fill is false the bar is transparent (outline only)
                color: fill ? null : Colors.transparent,

                // [COLOR] Outline color/width, only used when fill is false
                borderSide: fill
                    ? BorderSide.none
                    : BorderSide(color: colors.secondary, width: 2),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ------------------------------------------------------------
// PUNTO / BARRA - CONFIGURACIÓN VISUAL (separada de la gráfica)
// ------------------------------------------------------------

/// Agrupa toda la configuración de apariencia de los puntos de la línea
/// y de las barras, para poder modificarla sin tocar `CustomDataChart`.
class ChartPointStyle {
  // --- Línea ---

  /// Si la línea se dibuja curva (true) o recta entre puntos (false).
  final bool isCurved;

  /// Qué tan suave es la curva (0.0 = angulosa, 1.0 = muy suave).
  final double curveSmoothness;

  /// Grosor de la línea.
  final double lineWidth;

  /// Si se muestran los puntos (dots) sobre la línea.
  final bool showDots;

  /// Radio de cada punto (dot), solo aplica si [showDots] es true.
  final double dotRadius;

  /// [COLOR] Color de los puntos. Si es null, se usa el color primario del tema.
  final Color? dotColor;

  /// Si se rellena el área debajo de la línea con gradiente.
  /// NOTE: not used anymore, the line fill is controlled by CustomDataChart.fill.
  final bool showBelowBarGradient;

  // --- Barras ---

  /// Ancho de cada barra en el gráfico de tipo bar.
  final double barChartWidth;

  /// Radio de las esquinas superiores de cada barra.
  final double barBorderRadius;

  const ChartPointStyle({
    this.isCurved = true,
    this.curveSmoothness = 0.3,
    this.lineWidth = 3,
    this.showDots = false,
    this.dotRadius = 4,
    this.dotColor,
    this.showBelowBarGradient = true,
    this.barChartWidth = 16,
    this.barBorderRadius = 6,
  });

  /// Permite crear una copia modificando solo algunos valores.
  ChartPointStyle copyWith({
    bool? isCurved,
    double? curveSmoothness,
    double? lineWidth,
    bool? showDots,
    double? dotRadius,
    Color? dotColor,
    bool? showBelowBarGradient,
    double? barChartWidth,
    double? barBorderRadius,
  }) {
    return ChartPointStyle(
      isCurved: isCurved ?? this.isCurved,
      curveSmoothness: curveSmoothness ?? this.curveSmoothness,
      lineWidth: lineWidth ?? this.lineWidth,
      showDots: showDots ?? this.showDots,
      dotRadius: dotRadius ?? this.dotRadius,
      dotColor: dotColor ?? this.dotColor,
      showBelowBarGradient: showBelowBarGradient ?? this.showBelowBarGradient,
      barChartWidth: barChartWidth ?? this.barChartWidth,
      barBorderRadius: barBorderRadius ?? this.barBorderRadius,
    );
  }
}

// ------------------------------------------------------------
// INTERNAL DATA MODEL
// ------------------------------------------------------------

class _ChartPoint {
  final double value;
  final dynamic time;

  const _ChartPoint({required this.value, required this.time});
}
