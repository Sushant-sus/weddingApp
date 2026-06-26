import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A frosted "liquid glass" surface: real background blur + translucent overlay
/// fill + a hairline inner stroke and a soft top highlight (the wet-glass sheen).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blur = Glass.cardBlur,
    this.radius = Glass.cardRadius,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.fillOpacity,
  });

  final Widget child;
  final double blur;
  final double radius;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double? fillOpacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.55));
    final stroke = isDark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.65);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fillOpacity != null ? Colors.white.withValues(alpha: fillOpacity!) : fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: stroke, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scaffold whose background is the soft 162° gradient behind all glass.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({super.key, required this.body, this.bottomNavigationBar, this.floatingActionButton});

  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(gradient: isDark ? AppGradients.dark : AppGradients.light),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

/// A small translucent chip/badge with an optional category tint.
class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.label, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: tint), const SizedBox(width: 4)],
          Text(label, style: AppTheme.eyebrow(tint)),
        ],
      ),
    );
  }
}

/// Primary gradient button with the rose-gold glow.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, this.onPressed, this.icon, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null || loading ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.button,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.accentDeep.withValues(alpha: 0.45), blurRadius: 26, offset: const Offset(0, 10)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: loading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: loading
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2C1A10)))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[Icon(icon, size: 18, color: const Color(0xFF2C1A10)), const SizedBox(width: 8)],
                          Text(label,
                              style: const TextStyle(
                                  color: Color(0xFF2C1A10), fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
