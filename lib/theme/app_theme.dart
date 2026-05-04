import 'package:flutter/material.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

class AppColors {
  static const background = Color(0xFF0A0A14);
  static const card = Color(0xFF0F0F1E);
  static const cardBorder = Color(0xFF1A1A2E);
  static const accent = Color(0xFF6C63FF);
  static const neonGreen = Color(0xFF39FF14);
  static const neonCyan = Color(0xFF00E5FF);
  static const textPrimary = Color(0xFFE0E0F0);
  static const textSecondary = Color(0xFF9090A8);
  static const expense = Color(0xFFFF4757);
  static const income = Color(0xFF2ED573);
  static const warning = Color(0xFFFFD93D);

  // Categorias
  static const catMercado = Color(0xFF4CAF50);
  static const catFarmacia = Color(0xFFE91E63);
  static const catLazer = Color(0xFF9C27B0);
  static const catEstudos = Color(0xFF2196F3);
  static const catFaculdade = Color(0xFF3F51B5);
  static const catRoupa = Color(0xFFFF5722);
  static const catIfood = Color(0xFFFF0000);
  static const catUber = Color(0xFF000000);
  static const catGasolina = Color(0xFFFF9800);
  static const catSaude = Color(0xFF00BCD4);
  static const catNecessidade = Color(0xFF607D8B);
  static const catApartamento = Color(0xFF795548);
  static const catManutencao = Color(0xFF9E9E9E);
  static const catPresente = Color(0xFFFF4081);

  // Bancos
  static const bankItau = Color(0xFFFF6B00);
  static const bankNubank = Color(0xFF820AD1);
  static const bankInter = Color(0xFFFF6B00);
}

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accent,
    secondary: AppColors.neonGreen,
    surface: AppColors.card,
    error: AppColors.expense,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: AppColors.textPrimary,
  ),
  fontFamily: 'SpaceGrotesk',
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk'),
    bodyLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk'),
    bodyMedium: TextStyle(color: AppColors.textSecondary, fontFamily: 'SpaceGrotesk'),
    labelLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
  ),
  cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.cardBorder, width: 1),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'SpaceGrotesk',
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.card,
    selectedItemColor: AppColors.accent,
    unselectedItemColor: AppColors.textSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardBorder,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
    ),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    hintStyle: const TextStyle(color: AppColors.textSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    shape: CircleBorder(),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.cardBorder, thickness: 1),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.textSecondary),
    trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.accent.withValues(alpha: 0.3) : AppColors.cardBorder),
  ),
);

extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get kBg => isDark ? AppColors.background : const Color(0xFFF0F0F8);
  Color get kCard => isDark ? AppColors.card : Colors.white;
  Color get kCardBorder => isDark ? AppColors.cardBorder : const Color(0xFFE0E0EE);
  Color get kTextPrimary => isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E);
  Color get kTextSecondary => isDark ? AppColors.textSecondary : const Color(0xFF606080);
}

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF0F0F8),
  colorScheme: const ColorScheme.light(
    primary: AppColors.accent,
    secondary: Color(0xFF4CAF50),
    surface: Colors.white,
    error: AppColors.expense,
    onPrimary: Colors.white,
    onSurface: Color(0xFF1A1A2E),
  ),
  fontFamily: 'SpaceGrotesk',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1A1A2E),
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Color(0xFF1A1A2E),
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'SpaceGrotesk',
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.accent,
    unselectedItemColor: Color(0xFF9090A8),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE0E0EE), width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    shape: CircleBorder(),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFE8E8F0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0EE)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0EE)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
    ),
    labelStyle: const TextStyle(color: Color(0xFF606080)),
    hintStyle: const TextStyle(color: Color(0xFF606080)),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE0E0EE), thickness: 1),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.accent : const Color(0xFF9090A8)),
    trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.accent.withValues(alpha: 0.3) : const Color(0xFFE0E0EE)),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF1A1A2E), fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: Color(0xFF1A1A2E), fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: Color(0xFF1A1A2E), fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: Color(0xFF1A1A2E), fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(color: Color(0xFF1A1A2E), fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: Color(0xFF1A1A2E), fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: Color(0xFF1A1A2E), fontFamily: 'SpaceGrotesk'),
    bodyLarge: TextStyle(color: Color(0xFF1A1A2E), fontFamily: 'SpaceGrotesk'),
    bodyMedium: TextStyle(color: Color(0xFF606080), fontFamily: 'SpaceGrotesk'),
    labelLarge: TextStyle(color: Color(0xFF1A1A2E), fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
  ),
);
