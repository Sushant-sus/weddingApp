import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// The Aayojan marigold loading spinner — a native, animated recreation of
/// assets/brand/Aayojan_loader.svg (Flutter can't run the SVG's CSS keyframes).
/// Outer petals glow in sequence and drift-rotate; the core gently beats.
class AayojanLoader extends StatefulWidget {
  const AayojanLoader({super.key, this.size = 120});
  final double size;

  @override
  State<AayojanLoader> createState() => _AayojanLoaderState();
}

class _AayojanLoaderState extends State<AayojanLoader> with TickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 11000))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _spin]),
        builder: (_, _) => CustomPaint(painter: _MarigoldPainter(pulse: _pulse.value, spin: _spin.value)),
      ),
    );
  }
}

class _MarigoldPainter extends CustomPainter {
  _MarigoldPainter({required this.pulse, required this.spin});
  final double pulse; // 0..1 over 1.4s
  final double spin; // 0..1 over 11s

  static const _petalTop = Color(0xFFFF8A1E);
  static const _petalBot = Color(0xFFFFC53C);
  static const _inner = Color(0xFFFF3D9A);
  static const _coreCenter = Color(0xFFFFD23C);
  static const _coreEdge = Color(0xFFE23B2E);
  static const _coreDot = Color(0xFFFFF3D0);

  @override
  void paint(Canvas canvas, Size size) {
    // Match the SVG: viewBox 200, content at translate(100,100) scale(1.6).
    canvas.scale(size.width / 200);
    canvas.translate(100, 100);
    canvas.scale(1.6);

    // ---- Outer petals: slow spin group + per-petal sequential glow ----
    canvas.save();
    canvas.rotate(spin * 30 * math.pi / 180);
    for (var i = 0; i < 12; i++) {
      final phase = ((pulse - i / 12) % 1 + 1) % 1;
      final g = (1 - math.cos(2 * math.pi * phase)) / 2; // 0..1
      final opacity = 0.22 + 0.78 * g;
      final scale = 0.9 + 0.1 * g;
      canvas.save();
      canvas.rotate(i * 30 * math.pi / 180);
      canvas.translate(0, -35);
      canvas.scale(scale);
      canvas.translate(0, 35);
      final rect = Rect.fromCenter(center: const Offset(0, -35), width: 18, height: 40);
      final paint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -55),
          const Offset(0, -15),
          [_petalTop.withValues(alpha: opacity), _petalBot.withValues(alpha: opacity)],
        );
      canvas.drawOval(rect, paint);
      canvas.restore();
    }
    canvas.restore();

    // ---- Inner petals: static pink ring ----
    final innerPaint = Paint()..color = _inner.withValues(alpha: 0.9);
    for (var i = 0; i < 12; i++) {
      canvas.save();
      canvas.rotate((15 + i * 30) * math.pi / 180);
      canvas.drawOval(Rect.fromCenter(center: const Offset(0, -23), width: 13, height: 26), innerPaint);
      canvas.restore();
    }

    // ---- Core: beating radial gradient + cream dot ----
    final b = (1 - math.cos(2 * math.pi * pulse)) / 2;
    final coreScale = 0.9 + 0.18 * b;
    canvas.save();
    canvas.scale(coreScale);
    canvas.drawCircle(
      Offset.zero,
      14,
      Paint()..shader = ui.Gradient.radial(const Offset(0, -3), 16, [_coreCenter, _coreEdge]),
    );
    canvas.drawCircle(Offset.zero, 5.5, Paint()..color = _coreDot);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarigoldPainter old) => old.pulse != pulse || old.spin != spin;
}
