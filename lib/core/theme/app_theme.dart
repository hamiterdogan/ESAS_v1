import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/theme/app_dimens.dart';
import 'package:esas_v1/core/theme/app_typography.dart';

/// Uygulama teması.
class AppTheme {
  AppTheme._();

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME COLORS
  // ══════════════════════════════════════════════════════════════════════════

  static const Color _darkBackground = Color(0xFF0F172A);     // slate-900
  static const Color _darkSurface = Color(0xFF1E293B);        // slate-800
  static const Color _darkCard = Color(0xFF1E293B);           // slate-800
  static const Color _darkSurfaceVariant = Color(0xFF2D3F55); // slate-700 tinge
  static const Color _darkBorder = Color(0xFF334155);         // slate-700
  static const Color _darkBorderLight = Color(0xFF475569);    // slate-600
  static const Color _darkTextPrimary = Color(0xFFF1F5F9);    // slate-100
  static const Color _darkTextSecondary = Color(0xFFCBD5E1);  // slate-300
  static const Color _darkTextTertiary = Color(0xFF94A3B8);   // slate-400

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,

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
      iconTheme: const IconThemeData(
        color: AppColors.iconPrimary,
        size: AppDimens.iconSizeMedium,
      ),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: AppColors.iconOnPrimary,
        size: AppDimens.iconSizeMedium,
      ),

      // Splash & Highlight
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,

      colorScheme: _darkColorScheme,

      scaffoldBackgroundColor: _darkBackground,

      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: _darkTextPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          side: const BorderSide(color: _darkBorder, width: 0.8),
        ),
        margin: const EdgeInsets.symmetric(
          vertical: AppDimens.xs / 2,
          horizontal: AppDimens.sm,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.xl,
            vertical: AppDimens.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          textStyle: AppTypography.labelLarge.copyWith(fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF60A5FA), // blue-400
          textStyle: AppTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF60A5FA),
          side: const BorderSide(color: Color(0xFF60A5FA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          textStyle: AppTypography.labelLarge.copyWith(fontSize: 16),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg,
          vertical: AppDimens.lg,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: _darkTextTertiary),
        labelStyle: AppTypography.labelLarge.copyWith(
          color: const Color(0xFF93C5FD),
        ),
        floatingLabelStyle: AppTypography.labelLarge.copyWith(
          color: const Color(0xFF60A5FA),
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.errorAccent,
        ),
        helperStyle: AppTypography.bodySmall.copyWith(
          color: _darkTextTertiary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          borderSide: const BorderSide(
            color: Color(0xFF60A5FA),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          borderSide: const BorderSide(color: AppColors.errorAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.errorAccent,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          borderSide: const BorderSide(color: _darkBorderLight),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: _darkBorderLight, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXs),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return _darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.3);
          }
          return _darkBorderLight;
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        labelStyle: AppTypography.headlineSmall,
        unselectedLabelStyle: AppTypography.headlineSmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        modalBackgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusLg),
          ),
        ),
        elevation: 8,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: _darkTextPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: _darkTextSecondary,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: _darkBorder,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: _darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: _darkTextPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: _darkTextPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: _darkTextPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: _darkTextPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: _darkTextPrimary),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: _darkTextPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: _darkTextPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: _darkTextSecondary),
        titleSmall: AppTypography.titleSmall.copyWith(color: _darkTextSecondary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: _darkTextPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: _darkTextSecondary),
        bodySmall: AppTypography.bodySmall.copyWith(color: _darkTextTertiary),
        labelLarge: AppTypography.labelLarge.copyWith(color: _darkTextPrimary),
        labelMedium: AppTypography.labelMedium.copyWith(color: _darkTextSecondary),
        labelSmall: AppTypography.labelSmall.copyWith(color: _darkTextTertiary),
      ),

      iconTheme: const IconThemeData(
        color: _darkTextSecondary,
        size: AppDimens.iconSizeMedium,
      ),

      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: AppDimens.iconSizeMedium,
      ),

      splashColor: AppColors.primary.withValues(alpha: 0.15),
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
    );
  }

  static ColorScheme get _darkColorScheme {
    return const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF1D3557),
      onPrimaryContainer: Color(0xFF93C5FD),
      secondary: Color(0xFF60A5FA),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF1E3A5F),
      onSecondaryContainer: Color(0xFF93C5FD),
      surface: _darkSurface,
      onSurface: _darkTextPrimary,
      surfaceContainerHighest: _darkBackground,
      error: AppColors.errorAccent,
      onError: Colors.white,
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFCA5A5),
      outline: _darkBorder,
      outlineVariant: _darkBorderLight,
    );
  }



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
      titleTextStyle: AppTypography.headlineMedium,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: AppDimens.xs / 2,
        horizontal: AppDimens.sm,
      ),
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
          horizontal: AppDimens.xl,
          vertical: AppDimens.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        textStyle: AppTypography.labelLarge.copyWith(fontSize: 16),
      ),
    );
  }

  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg,
          vertical: AppDimens.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        textStyle: AppTypography.labelLarge,
      ),
    );
  }

  static OutlinedButtonThemeData get _outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.xl,
          vertical: AppDimens.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        textStyle: AppTypography.labelLarge.copyWith(fontSize: 16),
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
        horizontal: AppDimens.lg,
        vertical: AppDimens.lg,
      ),

      // Hint & Label
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textTertiary,
      ),
      labelStyle: AppTypography.labelLarge.copyWith(
        color: AppColors.labelColor,
      ),
      floatingLabelStyle: AppTypography.labelLarge.copyWith(
        color: AppColors.primary,
      ),

      // Error & Helper
      errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
      helperStyle: AppTypography.bodySmall.copyWith(
        color: AppColors.textTertiary,
      ),

      // Borders
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        borderSide: const BorderSide(color: AppColors.borderFocused, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        borderSide: const BorderSide(color: AppColors.borderError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        borderSide: const BorderSide(color: AppColors.borderError, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
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
        borderRadius: BorderRadius.circular(AppDimens.radiusXs),
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
    return TabBarThemeData(
      labelColor: AppColors.textOnPrimary,
      unselectedLabelColor: Colors.white70,
      indicatorColor: AppColors.textOnPrimary,
      labelStyle: AppTypography.headlineSmall,
      unselectedLabelStyle: AppTypography.headlineSmall.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEET THEME
  // ══════════════════════════════════════════════════════════════════════════

  static BottomSheetThemeData get _bottomSheetTheme {
    return const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLg),
        ),
      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      titleTextStyle: AppTypography.headlineSmall,
      contentTextStyle: AppTypography.bodyMedium.copyWith(
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
      contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textOnPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEXT THEME
  // ══════════════════════════════════════════════════════════════════════════

  static TextTheme get _textTheme {
    return const TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      displaySmall: AppTypography.displaySmall,
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      titleSmall: AppTypography.titleSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    );
  }
}
