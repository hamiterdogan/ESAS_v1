import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';

/// Uygulama teması.
///
/// Bu sınıf, uygulamanın tüm görsel stillerini tanımlar.
/// [MaterialApp]'da `theme: AppTheme.light` şeklinde kullanılır.
class AppTheme {
  AppTheme._();

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: _lightColorScheme,

      // Scaffold
      scaffoldBackgroundColor: AppColors.scaffoldBackground,

      // AppBar
      appBarTheme: _appBarTheme,

      // Card
      cardTheme: _cardTheme,

      // Elevated Button
      elevatedButtonTheme: _elevatedButtonTheme,

      // Text Button
      textButtonTheme: _textButtonTheme,

      // Outlined Button
      outlinedButtonTheme: _outlinedButtonTheme,

      // Floating Action Button
      floatingActionButtonTheme: _floatingActionButtonTheme,

      // Input Decoration (TextField, TextFormField)
      inputDecorationTheme: _inputDecorationTheme,

      // Checkbox
      checkboxTheme: _checkboxTheme,

      // Switch
      switchTheme: _switchTheme,

      // TabBar
      tabBarTheme: _tabBarTheme,

      // Bottom Sheet
      bottomSheetTheme: _bottomSheetTheme,

      // Dialog
      dialogTheme: _dialogTheme,

      // Divider
      dividerTheme: _dividerTheme,

      // Snackbar
      snackBarTheme: _snackBarTheme,

      // Text Theme
      textTheme: _textTheme,

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.iconPrimary, size: 24),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: AppColors.iconOnPrimary,
        size: 24,
      ),

      // Splash & Highlight
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COLOR SCHEME
  // ══════════════════════════════════════════════════════════════════════════

  static ColorScheme get _lightColorScheme {
    return const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primarySurface,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.primarySurface,
      onSecondaryContainer: AppColors.primaryLight,
      surface: AppColors.surface,
      onSurface: AppColors.textOnSurface,
      surfaceContainerHighest: AppColors.scaffoldBackground,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      errorContainer: AppColors.errorBackground,
      onErrorContainer: AppColors.error,
      outline: AppColors.border,
      outlineVariant: AppColors.borderLight,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APPBAR THEME
  // ══════════════════════════════════════════════════════════════════════════

  static AppBarTheme get _appBarTheme {
    return const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.iconOnPrimary),
      actionsIconTheme: IconThemeData(color: AppColors.iconOnPrimary),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CARD THEME
  // ══════════════════════════════════════════════════════════════════════════

  static CardThemeData get _cardTheme {
    return CardThemeData(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUTTON THEMES
  // ══════════════════════════════════════════════════════════════════════════

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData get _outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  static FloatingActionButtonThemeData get _floatingActionButtonTheme {
    return const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 4,
      shape: StadiumBorder(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INPUT DECORATION THEME
  // ══════════════════════════════════════════════════════════════════════════

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),

      // Hint style
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 15),

      // Label style
      labelStyle: const TextStyle(
        color: AppColors.labelColor,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),

      // Floating label style
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      // Error style
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),

      // Helper style
      helperStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),

      // Borders
      border: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.borderFocused, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.borderError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.borderError, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CHECKBOX & SWITCH THEMES
  // ══════════════════════════════════════════════════════════════════════════

  static CheckboxThemeData get _checkboxTheme {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
      side: const BorderSide(color: AppColors.border, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  }

  static SwitchThemeData get _switchTheme {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primarySurface;
        }
        return AppColors.borderLight;
      }),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB BAR THEME
  // ══════════════════════════════════════════════════════════════════════════

  static TabBarThemeData get _tabBarTheme {
    return const TabBarThemeData(
      labelColor: AppColors.textOnPrimary,
      unselectedLabelColor: Colors.white70,
      indicatorColor: AppColors.textOnPrimary,
      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEET THEME
  // ══════════════════════════════════════════════════════════════════════════

  static BottomSheetThemeData get _bottomSheetTheme {
    return BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bottomSheetRadius),
      elevation: 8,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOG THEME
  // ══════════════════════════════════════════════════════════════════════════

  static DialogThemeData get _dialogTheme {
    return DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.modalRadius),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 15,
        color: AppColors.textSecondary,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIVIDER THEME
  // ══════════════════════════════════════════════════════════════════════════

  static DividerThemeData get _dividerTheme {
    return const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SNACKBAR THEME
  // ══════════════════════════════════════════════════════════════════════════

  static SnackBarThemeData get _snackBarTheme {
    return SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: const TextStyle(
        color: AppColors.textOnPrimary,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEXT THEME
  // ══════════════════════════════════════════════════════════════════════════

  static TextTheme get _textTheme {
    return const TextTheme(
      // Display styles (büyük başlıklar)
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),

      // Headline styles (sayfa başlıkları)
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),

      // Title styles (kart/section başlıkları)
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),

      // Body styles (içerik metinleri)
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      ),

      // Label styles (buton, form label)
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
      ),
    );
  }
}
