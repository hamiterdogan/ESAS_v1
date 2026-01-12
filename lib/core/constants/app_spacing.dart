import 'package:flutter/material.dart';

/// Uygulamada kullanılan spacing (boşluk) ve border radius sabitleri.
///
/// Tutarlı bir tasarım sistemi için tüm spacing ve radius değerleri
/// bu sınıf üzerinden kullanılmalıdır.
class AppSpacing {
  AppSpacing._();

  // ══════════════════════════════════════════════════════════════════════════
  // SPACING VALUES
  // ══════════════════════════════════════════════════════════════════════════

  /// 2.0
  static const double xxs = 2.0;

  /// 4.0
  static const double xs = 4.0;

  /// 6.0
  static const double sm = 6.0;

  /// 8.0
  static const double md = 8.0;

  /// 12.0
  static const double lg = 12.0;

  /// 16.0
  static const double xl = 16.0;

  /// 20.0
  static const double xxl = 20.0;

  /// 24.0
  static const double xxxl = 24.0;

  /// 32.0
  static const double huge = 32.0;

  /// 48.0
  static const double massive = 48.0;

  // ══════════════════════════════════════════════════════════════════════════
  // EDGE INSETS (Padding/Margin)
  // ══════════════════════════════════════════════════════════════════════════

  /// Standart ekran padding'i (horizontal: 16, vertical: 12)
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  /// Kart içi padding (all: 16)
  static const EdgeInsets cardPadding = EdgeInsets.all(xl);

  /// Kart içi küçük padding (all: 12)
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(lg);

  /// Liste item padding (horizontal: 16, vertical: 12)
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  /// Form field arası boşluk (bottom: 16)
  static const EdgeInsets formFieldSpacing = EdgeInsets.only(bottom: xl);

  /// Bottom sheet padding
  static const EdgeInsets bottomSheetPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  /// Dialog padding
  static const EdgeInsets dialogPadding = EdgeInsets.all(xxxl);

  // ══════════════════════════════════════════════════════════════════════════
  // SIZED BOXES (Vertical Spacing)
  // ══════════════════════════════════════════════════════════════════════════

  /// Vertical 4px
  static const SizedBox verticalXs = SizedBox(height: xs);

  /// Vertical 6px
  static const SizedBox verticalSm = SizedBox(height: sm);

  /// Vertical 8px
  static const SizedBox verticalMd = SizedBox(height: md);

  /// Vertical 12px
  static const SizedBox verticalLg = SizedBox(height: lg);

  /// Vertical 16px
  static const SizedBox verticalXl = SizedBox(height: xl);

  /// Vertical 24px
  static const SizedBox verticalXxl = SizedBox(height: xxxl);

  /// Vertical 32px
  static const SizedBox verticalHuge = SizedBox(height: huge);

  // ══════════════════════════════════════════════════════════════════════════
  // SIZED BOXES (Horizontal Spacing)
  // ══════════════════════════════════════════════════════════════════════════

  /// Horizontal 4px
  static const SizedBox horizontalXs = SizedBox(width: xs);

  /// Horizontal 6px
  static const SizedBox horizontalSm = SizedBox(width: sm);

  /// Horizontal 8px
  static const SizedBox horizontalMd = SizedBox(width: md);

  /// Horizontal 12px
  static const SizedBox horizontalLg = SizedBox(width: lg);

  /// Horizontal 16px
  static const SizedBox horizontalXl = SizedBox(width: xl);

  /// Horizontal 24px
  static const SizedBox horizontalXxl = SizedBox(width: xxxl);
}

/// Uygulamada kullanılan border radius sabitleri.
class AppRadius {
  AppRadius._();

  /// 4.0
  static const double xs = 4.0;

  /// 6.0
  static const double sm = 6.0;

  /// 8.0 - Standart form field, küçük buton
  static const double md = 8.0;

  /// 12.0 - Kart, büyük buton
  static const double lg = 12.0;

  /// 16.0 - Bottom sheet köşeleri
  static const double xl = 16.0;

  /// 20.0 - Modal dialog
  static const double xxl = 20.0;

  /// 24.0
  static const double xxxl = 24.0;

  /// Tam yuvarlak (çok büyük değer)
  static const double full = 999.0;

  // ══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS OBJECTS
  // ══════════════════════════════════════════════════════════════════════════

  /// BorderRadius.circular(8)
  static BorderRadius get cardRadius => BorderRadius.circular(lg);

  /// BorderRadius.circular(8)
  static BorderRadius get buttonRadius => BorderRadius.circular(md);

  /// BorderRadius.circular(8)
  static BorderRadius get inputRadius => BorderRadius.circular(md);

  /// Checkbox radius (4)
  static BorderRadius get checkboxRadius => BorderRadius.circular(xs);

  /// Bottom sheet üst köşeler (16)
  static BorderRadius get bottomSheetRadius => const BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );

  /// Modal bottom sheet (tüm köşeler yuvarlatılmış)
  static BorderRadius get modalRadius => BorderRadius.circular(xxl);
}
