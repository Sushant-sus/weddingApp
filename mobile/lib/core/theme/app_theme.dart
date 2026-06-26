import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utsav "Liquid Glass" design tokens (from design_handoff_utsav/README.md).
/// Colours, gradients, radii and the glass recipe live here so every surface
/// reproduces the spec consistently.
class AppColors {
  // Brand / primary accent (wedding rose-gold).
  static const accent = Color(0xFFC9A28A);
  static const accentDeep = Color(0xFFBC8868);
  static const accentLight = Color(0xFFD8B49C);

  // Status colours.
  static const open = Color(0xFFC9A28A); // needs-service / open
  static const booked = Color(0xFF6FBF8E); // accepted / booked
  static const pending = Color(0xFFE0A458);
  static const declined = Color(0xFFD9737A);
  static const star = Color(0xFFE0A458);

  // Category accents (dots, chips, thumbnails).
  static const Map<String, Color> category = {
    'engagement': Color(0xFFD98A94),
    'haldi': Color(0xFFE0A458),
    'mehendi': Color(0xFF6FBF8E),
    'sangeet': Color(0xFFA88BD9),
    'wedding': Color(0xFFC9A28A),
    'reception': Color(0xFF7FA8D9),
    // Service categories.
    'catering': Color(0xFFE0A458),
    'photography': Color(0xFF7FA8D9),
    'decor': Color(0xFFA88BD9),
    'makeup': Color(0xFFD98A94),
    'dj_dhol': Color(0xFFC9A28A),
    'pandit': Color(0xFFE0A458),
    'mandap': Color(0xFF7FA8D9),
  };

  static Color categoryColor(String? slug) =>
      category[slug?.toLowerCase()] ?? accent;

  // Light theme text.
  static const headingLight = Color(0xFF241B2C);
  static const bodyLight = Color(0xFF2B2630);
  // Dark theme text.
  static const headingDark = Color(0xFFFBEFE6);
  static const bodyDark = Color(0xFFF6F1EC);
}

class AppGradients {
  // 162° background gradients behind the glass.
  static const light = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFFF9DDE3), Color(0xFFF5E8DB), Color(0xFFE3D8F2)],
  );
  static const dark = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFF2E1B38), Color(0xFF3A1C33), Color(0xFF241B40)],
  );

  // Primary button gradient.
  static const button = LinearGradient(
    colors: [AppColors.accentLight, AppColors.accentDeep],
  );
}

/// Glass recipe constants (BackdropFilter sigma + overlay fill opacities).
class Glass {
  static const double cardBlur = 20;
  static const double navBlur = 30;
  static const double sheetBlur = 28;
  static const double chipBlur = 14;

  static const double cardRadius = 22;
  static const double sheetRadius = 34;
  static const double navRadius = 34;
}

class AppTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
    );
    final bodyColor = isDark ? AppColors.bodyDark : AppColors.bodyLight;
    final headingColor = isDark ? AppColors.headingDark : AppColors.headingLight;

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: bodyColor, displayColor: headingColor);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(primary: AppColors.accent),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );
  }

  /// Serif display font (Libre Caslon) for titles, event names, big numbers.
  static TextStyle serif({
    double size = 24,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.libreCaslonDisplay(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// Uppercase eyebrow / label style.
  static TextStyle eyebrow(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: color,
      );
}
