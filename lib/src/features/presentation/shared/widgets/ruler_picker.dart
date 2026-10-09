// import 'package:flutter/material.dart';
// import 'package:flutter_ruler_picker/flutter_ruler_picker.dart';
// import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
// import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';

// class NumericRulerPicker extends StatefulWidget {
//   const NumericRulerPicker({
//     super.key,
//     required this.controller,
//     required this.onValueChanged,
//     this.ranges = const [RulerRange(begin: 0, end: 300, scale: 1)],
//     this.suffix = '',
//     this.width,
//     this.height = 75,
//     this.activeColor,
//     this.inactiveColor,
//     this.textColor,
//     this.backgroundColor,
//   });

//   final RulerPickerController controller;
//   final ValueChangedCallback onValueChanged;
//   final List<RulerRange> ranges;

//   /// Texto que se muestra después del valor, ej. " kg", " cm".
//   final String suffix;

//   final double? width;
//   final double height;

//   /// Color de la marca principal (línea grande) del centro.
//   final Color? activeColor;

//   /// Color de las líneas secundarias de la regla.
//   final Color? inactiveColor;

//   final Color? textColor;
//   final Color? backgroundColor;

//   @override
//   State<NumericRulerPicker> createState() => _NumericRulerPickerState();
// }

// class _NumericRulerPickerState extends State<NumericRulerPicker> {
//   late final ValueNotifier<num> _displayValue;

//   @override
//   void initState() {
//     super.initState();
//     _displayValue = ValueNotifier(widget.controller.value);
//   }

//   @override
//   void dispose() {
//     _displayValue.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final effectiveWidth = widget.width ?? MediaQuery.of(context).size.width;

//     return Column(
//       children: [
//         // Valor grande arriba, con sufijo
//         ValueListenableBuilder<num>(
//           valueListenable: _displayValue,
//           builder: (context, value, _) {
//             return Text(
//               '${value.round()}${widget.suffix}',
//               style: TextStyle(
//                 fontSize: context.fontsSize.title,
//                 fontWeight: FontWeight.w700,
//                 color: widget.textColor ?? colors.textPrimary,
//               ),
//             );
//           },
//         ),
//         SizedBox(height: context.spacing.md),

//         RulerPicker(
//           controller: widget.controller,
//           width: effectiveWidth,
//           height: widget.height,
//           ranges: widget.ranges,
//           rulerBackgroundColor: widget.backgroundColor ?? colors.surface,

//           onValueChanged: (value) {
//             _displayValue.value = value;
//             widget.onValueChanged(value);
//           },

//           onBuildRulerScaleText: (index, value) => value.toString(),
//           scaleLineStyleList: [
//             ScaleLineStyle(
//               scale: 0,
//               color: widget.activeColor ?? colors.secondary,
//               width: 2,
//               height: 32,
//             ),
//             ScaleLineStyle(
//               color: widget.inactiveColor ?? colors.secondary,
//               width: 1,
//               height: 20,
//             ),
//           ],
//           rulerScaleTextStyle: TextStyle(
//             color: widget.inactiveColor ?? colors.textPrimary,
//             fontSize: context.fontsSize.caption,
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class RulerPickerController extends ValueNotifier<double> {
  RulerPickerController({
    required this.min,
    required this.max,
    required double initialValue,
  }) : super(initialValue.clamp(min, max).toDouble());

  final double min;
  final double max;

  void Function(double value)? _onExternalSet;

  @override
  set value(double newValue) {
    final clamped = newValue.clamp(min, max).toDouble();

    super.value = clamped;
    _onExternalSet?.call(clamped);
  }
}

class NumericRulerPicker extends StatefulWidget {
  const NumericRulerPicker({
    super.key,
    required this.controller,
    this.onChanged,
    this.step = 1,
    this.suffix = '',
    this.height = 90,
    this.itemExtent = 10,
    this.activeColor,
    this.inactiveColor,
    this.textColor,
    this.title,
  });

  final RulerPickerController controller;

  final ValueChanged<double>? onChanged;

  final double step;

  final String suffix;

  final double height;
  final String? title;

  /// Distancia entre cada marca.
  final double itemExtent;

  final Color? activeColor;
  final Color? inactiveColor;
  final Color? textColor;

  @override
  State<NumericRulerPicker> createState() => _NumericRulerPickerState();
}

class _NumericRulerPickerState extends State<NumericRulerPicker> {
  late final ScrollController _scrollController;

  late int _itemCount;

  bool _isInternalScroll = false;

  double _sidePadding = 0;

  @override
  void initState() {
    super.initState();

    _calculateItemCount();

    _scrollController = ScrollController();

    widget.controller._onExternalSet = _onExternalValueChanged;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _scrollToValue(widget.controller.value, animated: false);
    });
  }

  void _calculateItemCount() {
    if (widget.step <= 0) {
      _itemCount = 1;
      return;
    }

    final range = widget.controller.max - widget.controller.min;

    _itemCount = (range / widget.step).round() + 1;

    if (_itemCount < 1) {
      _itemCount = 1;
    }
  }

  int _valueToIndex(double value) {
    final index = ((value - widget.controller.min) / widget.step).round();

    return index.clamp(0, _itemCount - 1);
  }

  double _indexToValue(int index) {
    final value = widget.controller.min + (index * widget.step);

    final clean = double.parse(value.toStringAsFixed(10));

    return clean.clamp(widget.controller.min, widget.controller.max).toDouble();
  }

  void _onExternalValueChanged(double value) {
    if (!mounted || _isInternalScroll) return;

    _scrollToValue(value, animated: true);
  }

  void _scrollToValue(double value, {required bool animated}) {
    if (!_scrollController.hasClients) return;

    final index = _valueToIndex(value);

    // IMPORTANTE:
    //
    // NO sumamos _sidePadding aquí.
    //
    // Gracias al padding del ListView:
    //
    // scrollOffset = index * itemExtent
    //
    final targetOffset = index * widget.itemExtent;

    final maxOffset = _scrollController.position.maxScrollExtent;

    final safeOffset = targetOffset.clamp(0.0, maxOffset);

    if (animated) {
      _scrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(safeOffset);
    }
  }

  void _handleScrollUpdate(double offset) {
    if (_itemCount <= 0) return;

    // IMPORTANTE:
    //
    // Tampoco restamos _sidePadding.
    //
    // El offset del ScrollController ya corresponde
    // directamente al índice.
    final index = (offset / widget.itemExtent).round().clamp(0, _itemCount - 1);

    final value = _indexToValue(index);

    if (value == widget.controller.value) {
      return;
    }

    _isInternalScroll = true;

    widget.controller.value = value;

    _isInternalScroll = false;

    widget.onChanged?.call(value);
  }

  @override
  void didUpdateWidget(covariant NumericRulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller ||
        oldWidget.step != widget.step ||
        oldWidget.controller.min != widget.controller.min ||
        oldWidget.controller.max != widget.controller.max) {
      oldWidget.controller._onExternalSet = null;

      _calculateItemCount();

      widget.controller._onExternalSet = _onExternalValueChanged;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _scrollToValue(widget.controller.value, animated: false);
      });
    }
  }

  @override
  void dispose() {
    widget.controller._onExternalSet = null;
    _scrollController.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    final rounded = double.parse(value.toStringAsFixed(10));

    if (rounded == rounded.roundToDouble()) {
      return rounded.round().toString();
    }

    return rounded.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        ValueListenableBuilder<double>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            return Column(
              mainAxisAlignment: .center,

              // Titulo y valor mostrado
              children: [
                CustomTextWidget(
                  label: '${_formatValue(value)}${widget.suffix}',
                  fontSize: context.fontsSize.headline,
                  color: widget.textColor ?? colors.textPrimary,
                  fontWeight: .w700,
                ),
                SizedBox(height: context.spacing.xs),

                CustomTextWidget(
                  label: widget.title ?? "",
                  fontSize: context.fontsSize.body,
                ),
              ],
            );
          },
        ),

        SizedBox(height: context.spacing.xs),

        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Esto permite que tanto MIN como MAX
              // puedan llegar al marcador central.
              _sidePadding = (constraints.maxWidth - widget.itemExtent) / 2;

              return Stack(
                alignment: Alignment.center,
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.axis == Axis.horizontal) {
                        _handleScrollUpdate(notification.metrics.pixels);
                      }

                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),

                      padding: EdgeInsets.symmetric(horizontal: _sidePadding),

                      itemCount: _itemCount,

                      itemBuilder: (context, index) {
                        final value = _indexToValue(index);

                        final isMajor = index % 10 == 0;

                        final isMid = index % 5 == 0;

                        return SizedBox(
                          width: widget.itemExtent,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isMajor)
                                  CustomTextWidget(
                                    label: _formatValue(value),
                                    fontSize: context.fontsSize.caption,
                                    color:
                                        widget.inactiveColor ??
                                        colors.textPrimary,
                                  ),

                                Container(
                                  width: 4,
                                  height: isMajor
                                      ? 32
                                      : isMid
                                      ? 22
                                      : 14,
                                  color:
                                      widget.inactiveColor ??
                                      colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Indicador central.
                  IgnorePointer(
                    child: Container(
                      width: 2,
                      height: 45,
                      color: widget.activeColor ?? colors.tertiary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
