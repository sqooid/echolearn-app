import 'package:flutter/material.dart';

class AppColors {
  final Color screen;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color border;
  final Color borderStrong;

  const AppColors({
    required this.screen,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.border,
    required this.borderStrong,
  });
}

const lightColors = AppColors(
  screen: Color(0xFFF1F1F2),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFF6F6F7),
  surface3: Color(0xFFEDEDEE),
  ink: Color(0xFF17171A),
  inkSoft: Color(0xFF6A6A70),
  inkFaint: Color(0xFF9B9BA1),
  border: Color(0xFFE6E6E8),
  borderStrong: Color(0xFFD6D6D9),
);

const darkColors = AppColors(
  screen: Color(0xFF121214),
  surface: Color(0xFF1C1C1F),
  surface2: Color(0xFF232327),
  surface3: Color(0xFF2A2A2F),
  ink: Color(0xFFF4F4F6),
  inkSoft: Color(0xFFA2A2A9),
  inkFaint: Color(0xFF6C6C73),
  border: Color(0xFF2C2C31),
  borderStrong: Color(0xFF3A3A40),
);

class LingoTheme extends InheritedWidget {
  final AppColors colors;
  final Color accent;
  final Color onAccent;
  final double density;
  final double gap;

  const LingoTheme({
    super.key,
    required super.child,
    required this.colors,
    required this.accent,
    required this.onAccent,
    required this.density,
    required this.gap,
  });

  static LingoTheme of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<LingoTheme>();
    assert(result != null, 'No LingoTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(LingoTheme oldWidget) {
    return colors != oldWidget.colors ||
        accent != oldWidget.accent ||
        onAccent != oldWidget.onAccent ||
        density != oldWidget.density ||
        gap != oldWidget.gap;
  }
}

double densityMultiplier(String spacing) {
  switch (spacing) {
    case 'compact':
      return 0.8;
    case 'comfortable':
      return 1.2;
    default:
      return 1.0;
  }
}

double gapPixels(String spacing) {
  switch (spacing) {
    case 'compact':
      return 9;
    case 'comfortable':
      return 18;
    default:
      return 13;
  }
}
