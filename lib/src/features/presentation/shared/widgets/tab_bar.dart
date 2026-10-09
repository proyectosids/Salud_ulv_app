import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/shadows.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class TabItem {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const TabItem({required this.label, this.icon, required this.onTap});
}

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.color,
    this.backgroundColor,
    this.selectedColor,
    this.pHeight,
    this.pWidth,
  });

  final List<TabItem> tabs;
  final int initialIndex;
  final Color? color;
  final Color? backgroundColor;
  final Color? selectedColor;
  final double? pHeight;
  final double? pWidth;

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    widget.tabs[index].onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Container(
      constraints: BoxConstraints(minHeight: widget.pHeight ?? 48),
      width: widget.pWidth ?? double.infinity,
      padding: EdgeInsets.all(spacing.xs),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colors.surface,
        borderRadius: BorderRadius.circular(spacing.radiusLg),
        border: Border.all(color: colors.border),
        boxShadow: context.shadows.smBoxShadow,
      ),
      child: Row(
        children: [
          for (int i = 0; i < widget.tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => _onTabTapped(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: spacing.sm),
                  decoration: BoxDecoration(
                    color: _selectedIndex == i
                        ? (widget.selectedColor ??
                              colors.secondary.withAlpha(36))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(spacing.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.tabs[i].icon != null) ...[
                        Icon(
                          widget.tabs[i].icon,
                          size: context.iconSize.md,
                          color: _selectedIndex == i
                              ? colors.secondary
                              : widget.color ?? colors.textSecondary,
                        ),
                        SizedBox(width: spacing.xs),
                      ],
                      CustomTextWidget(
                        label: widget.tabs[i].label,
                        fontSize: context.fontsSize.caption,

                        color: _selectedIndex == i
                            ? colors.secondary
                            : widget.color ?? colors.textSecondary,
                        fontWeight: _selectedIndex == i
                            ? FontWeight.w900
                            : FontWeight.normal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
