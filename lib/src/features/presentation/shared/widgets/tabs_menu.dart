import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';

/// Describes one "page" of the [TabbedContainer].
class TabPage {
  const TabPage({required this.title, required this.child, this.icon});

  final String title;
  final Widget child;
  final IconData? icon;
}

class TabbedContainer extends StatefulWidget {
  const TabbedContainer({
    super.key,
    required this.pages,
    this.initialIndex = 0,
    this.onChanged,
    this.color,
    this.scrollableTabs = false,
  }) : assert(pages.length > 0, 'Provide at least one page');

  final List<TabPage> pages;
  final int initialIndex;

  /// Called whenever the user switches page.
  final ValueChanged<int>? onChanged;

  final Color? color;

  /// Set to true if you have many/long titles. Tabs then scroll
  /// horizontally instead of sharing the width equally.
  final bool scrollableTabs;

  @override
  State<TabbedContainer> createState() => _TabbedContainerState();
}

class _TabbedContainerState extends State<TabbedContainer> {
  late int _index = widget.initialIndex.clamp(0, widget.pages.length - 1);

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    widget.onChanged?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    final buttons = [
      for (var i = 0; i < widget.pages.length; i++)
        _TabButton(
          page: widget.pages[i],
          selected: i == _index,
          onTap: () => _select(i),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: widget.color ?? Colors.transparent,
        borderRadius: BorderRadius.circular(spacing.radiusLg),
        border: Border.all(color: Colors.transparent),
        // boxShadow: context.shadows.boxShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab buttons
          if (widget.scrollableTabs)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: buttons),
            )
          else
            Row(children: [for (final b in buttons) Expanded(child: b)]),
          SizedBox(height: spacing.md),

          // Active page
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: widget.pages[_index].child,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final TabPage page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    final activeColor = colors.secondary;
    final inactiveColor = colors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(spacing.radiusLg),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.xxs,
          vertical: spacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (page.icon != null) ...[
                  Icon(
                    page.icon,
                    size: 18,
                    color: selected ? activeColor : inactiveColor,
                  ),
                  SizedBox(width: spacing.xs),
                ],
                Flexible(
                  child: Text(
                    page.title,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: selected ? activeColor : inactiveColor,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.xs),
            // Active indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 32 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
