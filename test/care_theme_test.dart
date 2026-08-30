import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/core/theme/app_theme.dart';

// Guards the accessibility contract of the senior-friendly careTheme.
// If these fail, Care Mode no longer meets the spec it was built to.
void main() {
  group('careTheme accessibility contract', () {
    final theme = AppTheme.careTheme;

    test('body text is at least 18sp', () {
      expect(theme.textTheme.bodyMedium!.fontSize, greaterThanOrEqualTo(18));
      expect(theme.textTheme.bodyLarge!.fontSize, greaterThanOrEqualTo(18));
      expect(theme.textTheme.bodySmall!.fontSize, greaterThanOrEqualTo(16));
    });

    test('buttons meet the 56x56 tap target minimum', () {
      final size =
          theme.elevatedButtonTheme.style!.minimumSize!.resolve({})!;
      expect(size.width, greaterThanOrEqualTo(56));
      expect(size.height, greaterThanOrEqualTo(56));
      final textSize = theme.textButtonTheme.style!.minimumSize!.resolve({})!;
      expect(textSize.height, greaterThanOrEqualTo(56));
    });

    test('stays light for legibility regardless of system setting', () {
      expect(theme.brightness, Brightness.light);
    });

    test('tap targets are padded, not shrunk', () {
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  });

  group('standard themes', () {
    test('light and dark themes disagree on brightness', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
    });
  });
}
