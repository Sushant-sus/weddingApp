import 'package:flutter/material.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/aayojan_loader.dart';

/// Shown while the session is being restored, before auth status is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/brand/logo.webp', width: 260, fit: BoxFit.contain),
            const SizedBox(height: 24),
            const AayojanLoader(size: 72),
          ],
        ),
      ),
    );
  }
}
