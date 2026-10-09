import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/core/models/user.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/spacers.dart';

enum RowOrientation { horizontal, vertical }

class CustomListView extends StatelessWidget {
  final List<Widget> widgets;
  final RowOrientation orientation;
  final double? spacing;
  final double? runSpacing;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;
  final WrapAlignment wrapAlignment;
  final bool addContentPadding;
  final int lines;
  final ScrollController? controller;
  final bool keepAlives;

  /// Horizontal mode: height of each line.
  /// A horizontal ListView can't size itself to its content.
  final double height;

  /// Vertical mode: width of each line, used only when the parent
  /// gives no width bound (e.g. inside a Row).
  final double width;

  const CustomListView({
    super.key,
    required this.widgets,
    this.orientation = RowOrientation.horizontal,
    this.spacing = 20,
    this.runSpacing,
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrapAlignment = WrapAlignment.start,
    this.addContentPadding = false,
    this.lines = 1,
    this.controller,
    this.keepAlives = true,
    this.height = 120,
    this.width = 150,
  }) : assert(lines > 0, 'lines debe ser al menos 1');

  @override
  Widget build(BuildContext context) {
    if (widgets.isEmpty) return const SizedBox.shrink();

    final effectiveSpacing = spacing ?? context.spacing.md;
    final effectiveRunSpacing = runSpacing ?? effectiveSpacing;
    final isHorizontal = orientation == RowOrientation.horizontal;

    Widget buildSingleLine(
      List<Widget> lineWidgets, {
      ScrollController? lineController,
    }) {
      if (scrollable) {
        final list = ListView.separated(
          controller: lineController,
          scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
          // Vertical: size to content. Horizontal: height comes from the SizedBox.
          shrinkWrap: !isHorizontal,
          clipBehavior: Clip.hardEdge,
          addAutomaticKeepAlives: keepAlives,
          padding: !addContentPadding
              ? EdgeInsets.zero
              : isHorizontal
              ? EdgeInsets.symmetric(
                  vertical: effectiveSpacing * 1.5,
                  horizontal: 4,
                )
              : EdgeInsets.symmetric(horizontal: effectiveSpacing, vertical: 4),
          itemCount: lineWidgets.length,
          itemBuilder: (context, i) {
            return Align(
              alignment: _alignmentFor(crossAxisAlignment, isHorizontal),
              widthFactor: isHorizontal ? 1 : null,
              heightFactor: isHorizontal ? null : 1,
              child: lineWidgets[i],
            );
          },
          separatorBuilder: (_, _) => isHorizontal
              ? SizedBox(width: effectiveSpacing)
              : SizedBox(height: effectiveSpacing),
        );

        if (isHorizontal) {
          return SizedBox(height: height, child: list);
        }

        // Vertical + shrinkWrap needs a bounded width.
        return LayoutBuilder(
          builder: (context, constraints) => constraints.hasBoundedWidth
              ? list
              : SizedBox(width: width, child: list),
        );
      }

      return Wrap(
        direction: isHorizontal ? Axis.horizontal : Axis.vertical,
        spacing: effectiveSpacing,
        runSpacing: effectiveSpacing,
        alignment: wrapAlignment,
        crossAxisAlignment: isHorizontal
            ? WrapCrossAlignment.center
            : WrapCrossAlignment.start,
        children: lineWidgets,
      );
    }

    Widget content;

    if (lines <= 1) {
      content = buildSingleLine(widgets, lineController: controller);
    } else {
      final perLine = (widgets.length / lines).ceil();
      final chunks = <List<Widget>>[];

      for (int i = 0; i < widgets.length; i += perLine) {
        chunks.add(widgets.sublist(i, (i + perLine).clamp(0, widgets.length)));
      }

      final lineWidgets = <Widget>[];
      for (int i = 0; i < chunks.length; i++) {
        // The controller is only used with a single line.
        lineWidgets.add(buildSingleLine(chunks[i]));
        if (i != chunks.length - 1) {
          lineWidgets.add(
            isHorizontal
                ? SizedBox(height: effectiveRunSpacing)
                : SizedBox(width: effectiveRunSpacing),
          );
        }
      }

      content = isHorizontal
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: crossAxisAlignment,
              children: lineWidgets,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: crossAxisAlignment,
              children: lineWidgets,
            );
    }

    return Padding(padding: padding, child: content);
  }

  Alignment _alignmentFor(CrossAxisAlignment a, bool isHorizontal) {
    switch (a) {
      case CrossAxisAlignment.start:
        return isHorizontal ? Alignment.topCenter : Alignment.centerLeft;
      case CrossAxisAlignment.end:
        return isHorizontal ? Alignment.bottomCenter : Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }
}

class MembersList extends StatelessWidget {
  final List<User> members;

  const MembersList({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      // physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(context.spacing.md),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final user = members[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),

          leading: const CircleAvatar(child: Icon(Icons.person)),

          title: Text(
            '${user.firstname ?? ''} ${user.surname ?? ''} ${user.lastname ?? ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          subtitle: Text(
            user.userCode ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
