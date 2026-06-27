import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Floating liquid-glass tab bar: a translucent pill hovering above the safe
/// area, with a rose-gold highlight that springs between the active tabs.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key, required this.items, required this.index, required this.onTap});

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.36);
    final stroke = isDark ? Colors.white.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.60);
    final inactive = (isDark ? AppColors.bodyDark : AppColors.bodyLight).withValues(alpha: 0.55);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Glass.navRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: Glass.navBlur, sigmaY: Glass.navBlur),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(Glass.navRadius),
                border: Border.all(color: stroke, width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.18),
                      blurRadius: 32,
                      offset: const Offset(0, 12)),
                ],
              ),
              child: LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth / items.length;
                return Stack(
                  children: [
                    // Springy active highlight.
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutBack,
                      left: w * index,
                      top: 8,
                      bottom: 8,
                      width: w,
                      child: Center(
                        child: Container(
                          width: w - 8,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(Glass.navRadius),
                            boxShadow: [
                              BoxShadow(color: AppColors.accent.withValues(alpha: 0.50), blurRadius: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(Glass.navRadius),
                              onTap: () => onTap(i),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(items[i].icon,
                                      size: 22, color: i == index ? AppColors.accentDeep : inactive),
                                  const SizedBox(height: 3),
                                  // scaleDown guarantees longer labels (e.g. "Itinerary")
                                  // always fit the tab without clipping.
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        items[i].label,
                                        maxLines: 1,
                                        softWrap: false,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                                            color: i == index ? AppColors.accentDeep : inactive),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
