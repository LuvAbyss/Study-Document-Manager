import 'package:flutter/material.dart';

/// Bảng màu và Theme hệ thống theo ngôn ngữ thiết kế của Cashew
/// Hỗ trợ Material 3, Dark Mode & Light Mode với độ tương phản cao, hiện đại.
class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF1E88E5); // Cashew vibrant blue
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFFBBDEFB);

  // Secondary & Accent
  static const Color accent = Color(0xFF00BFA5); // Teal accent
  static const Color accentAmber = Color(0xFFFFB300); // Warm amber
  static const Color accentPurple = Color(0xFF7E57C2); // Soft purple

  // Document Type Semantic Colors
  static const Color typeLecture = Color(0xFF5C6BC0); // Indigo for Lectures
  static const Color typeAssignment = Color(0xFFFF7043); // Deep orange for Assignments
  static const Color typeReference = Color(0xFF26A69A); // Teal for References
  static const Color typeExam = Color(0xFFE91E63); // Pink/Crimson for Exams

  // Priority Semantic Colors
  static const Color priorityLow = Color(0xFF4CAF50); // Green
  static const Color priorityMedium = Color(0xFF29B6F6); // Light Blue
  static const Color priorityHigh = Color(0xFFFFA726); // Orange
  static const Color priorityUrgent = Color(0xFFEF5350); // Red

  // Status Colors
  static const Color statusPending = Color(0xFF78909C); // Blue Grey
  static const Color statusInProgress = Color(0xFF42A5F5); // Blue
  static const Color statusCompleted = Color(0xFF66BB6A); // Green
  static const Color statusArchived = Color(0xFF9E9E9E); // Grey

  // Surface & Background - Light Mode
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);

  // Surface & Background - Dark Mode
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF242424);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkTextPrimary = Color(0xFFEEEEEE);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);

  /// Trả về theme sáng chuẩn Cashew
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        outline: lightBorder,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  /// Trả về theme tối chuẩn Cashew
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        outline: darkBorder,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
