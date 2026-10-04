import 'package:flutter/material.dart';

import 'i18n.dart';
import 'models.dart';

const brandGreen = Color(0xFF63B32A);
const brandGreenDark = Color(0xFF3C7719);
const brandInk = Color(0xFF16202A);
const brandInk2 = Color(0xFF263542);
const brandFrost = Color(0xFF3D93D8);
const brandSurface = Color(0xFFF4F7F2);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandGreen,
    primary: brandGreenDark,
    secondary: brandInk2,
    tertiary: brandFrost,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: brandSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: brandSurface,
      foregroundColor: brandInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: brandInk),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE3E9E0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD6DED2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD6DED2)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: brandGreen.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: brandInk, foregroundColor: Colors.white),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

Color statusColor(Document d) {
  if (d.isOverdue) return const Color(0xFFD64545);
  return switch (d.status) {
    DocStatus.draft => Colors.blueGrey,
    DocStatus.open => const Color(0xFFE09B1A),
    DocStatus.paid => brandGreenDark,
    DocStatus.cancelled => Colors.grey,
    DocStatus.accepted => brandGreenDark,
    DocStatus.declined => const Color(0xFFD64545),
  };
}

String statusLabel(Document d) => (d.isOverdue ? 'Overdue' : d.status.label).tr;

Color categoryColor(ServiceCategory c) => switch (c) {
  ServiceCategory.garten => brandGreen,
  ServiceCategory.objekt => brandInk2,
  ServiceCategory.winter => brandFrost,
  ServiceCategory.material => const Color(0xFF9A7B4F),
};

IconData categoryIcon(ServiceCategory c) => switch (c) {
  ServiceCategory.garten => Icons.grass_rounded,
  ServiceCategory.objekt => Icons.apartment_rounded,
  ServiceCategory.winter => Icons.ac_unit_rounded,
  ServiceCategory.material => Icons.inventory_2_rounded,
};
