import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:utsav/core/theme/app_theme.dart';

void main() {
  test('category colours resolve with a sensible fallback', () {
    expect(AppColors.categoryColor('mehendi'), const Color(0xFF6FBF8E));
    expect(AppColors.categoryColor('unknown'), AppColors.accent);
  });
}
