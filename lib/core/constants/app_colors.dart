import 'package:flutter/material.dart';

/// Uygulamada kullanılan tüm renkler.
///
/// Tutarlı bir tasarım sistemi için tüm renkler bu sınıf üzerinden kullanılmalıdır.
/// Hardcoded Color(0x...) veya Colors.xxx kullanmaktan kaçının.
class AppColors {
  AppColors._();

  // ══════════════════════════════════════════════════════════════════════════
  // PRIMARY COLORS (Marka Renkleri)
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana marka rengi - Koyu mavi
  static const Color primary = Color(0xFF014B92);

  /// Ana marka rengi - Daha koyu ton
  static const Color primaryDark = Color(0xFF01325B);

  /// Ana marka rengi - Açık ton (label, input)
  static const Color primaryLight = Color(0xFF01396B);

  /// Ana renk - Çok açık ton (arka planlar için)
  static const Color primarySurface = Color(0xFFE8F0F8);

  // ══════════════════════════════════════════════════════════════════════════
  // BACKGROUND COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Scaffold arka plan rengi
  static const Color scaffoldBackground = Color(0xFFEEF1F5);

  /// Alternatif arka plan (bazı ekranlarda kullanılan)
  static const Color scaffoldBackgroundAlt = Color(0xFFF2F4F7);

  /// Kart arka plan rengi
  static const Color cardBackground = Colors.white;

  /// Surface rengi (elevated surfaces)
  static const Color surface = Colors.white;

  /// Saydam renk
  static const Color transparent = Colors.transparent;

  /// Overlay arka plan (modal, bottom sheet)
  static const Color overlay = Color(0x8A000000);

  // ══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Birincil metin rengi
  static const Color textPrimary = Color(0xFF2D3748);

  /// İkincil metin rengi
  static const Color textSecondary = Color(0xFF4A5568);

  /// Üçüncül metin rengi (hint, placeholder)
  static const Color textTertiary = Color(0xFF718096);

  /// Disabled metin rengi
  static const Color textDisabled = Color(0xFFA0AEC0);

  /// Beyaz metin (koyu arka plan üzerinde)
  static const Color textOnPrimary = Colors.white;

  /// Beyaz metin - yarı saydam (koyu arka plan üzerinde)
  static const Color textOnPrimaryMuted = Color(0xB3FFFFFF); // white70

  /// Siyah metin (açık arka plan üzerinde)
  static const Color textOnSurface = Color(0xFF1A202C);

  /// Label rengi (form field label)
  static const Color labelColor = Color(0xFF01396B);

  // ══════════════════════════════════════════════════════════════════════════
  // BORDER COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Standart border rengi
  static const Color border = Color(0xFFE2E8F0);

  /// Açık border (subtle)
  static const Color borderLight = Color(0xFFF1F5F9);

  /// Koyu border (daha belirgin)
  static const Color borderDark = Color(0xFFCBD5E1);

  /// Focus durumunda border
  static const Color borderFocused = primary;

  /// Error durumunda border
  static const Color borderError = Color(0xFFE53E3E);

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS (Anlam Taşıyan Renkler)
  // ══════════════════════════════════════════════════════════════════════════

  /// Başarı rengi
  static const Color success = Color(0xFF38A169);

  /// Başarı arka plan
  static const Color successBackground = Color(0xFFC6F6D5);

  /// Hata rengi
  static const Color error = Color(0xFFE53E3E);

  /// Hata arka plan
  static const Color errorBackground = Color(0xFFFED7D7);

  /// Uyarı rengi
  static const Color warning = Color(0xFFF59E0B);

  /// Uyarı arka plan
  static const Color warningBackground = Color(0xFFFEF3C7);

  /// Bilgi rengi
  static const Color info = Color(0xFF3182CE);

  /// Bilgi arka plan
  static const Color infoBackground = Color(0xFFBEE3F8);

  // ══════════════════════════════════════════════════════════════════════════
  // STATUS COLORS (Talep Durumları)
  // ══════════════════════════════════════════════════════════════════════════

  /// Onay bekliyor durumu
  static const Color statusPending = AppColors.warning;

  /// Onay bekliyor arka plan
  static const Color statusPendingBg = Color(0xFFFEF3C7);

  /// Onaylandı durumu
  static const Color statusApproved = Color(0xFF38A169);

  /// Onaylandı arka plan
  static const Color statusApprovedBg = Color(0xFFC6F6D5);

  /// Reddedildi durumu
  static const Color statusRejected = Color(0xFFE53E3E);

  /// Reddedildi arka plan
  static const Color statusRejectedBg = Color(0xFFFED7D7);

  /// Belirsiz/Bilinmiyor durumu
  static const Color statusUnknown = Color(0xFF64748B);

  /// Belirsiz arka plan
  static const Color statusUnknownBg = Color(0xFFE2E8F0);

  // ══════════════════════════════════════════════════════════════════════════
  // ICON COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Birincil ikon rengi
  static const Color iconPrimary = Color(0xFF4A5568);

  /// İkincil ikon rengi
  static const Color iconSecondary = Color(0xFF718096);

  /// Beyaz ikon (koyu arka plan)
  static const Color iconOnPrimary = Colors.white;

  // ══════════════════════════════════════════════════════════════════════════
  // DIVIDER & SEPARATOR
  // ══════════════════════════════════════════════════════════════════════════

  /// Divider rengi
  static const Color divider = Color(0xFFE2E8F0);

  /// Separator rengi (daha açık)
  static const Color separator = AppColors.borderLight;

  /// Gölge rengi
  static const Color shadow = Color(0x1A000000);

  /// Daha koyu gölge
  static const Color shadowDark = Color(0x33000000);

  /// Kart gölge rengi (subtle)
  static const Color cardShadow = Color(0x0D000000); // black with 5% opacity

  // ══════════════════════════════════════════════════════════════════════════
  // TEXT OPACITY VARIANTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Birincil metin - 87% opacity
  static const Color textPrimary87 = Color(0xDE000000);

  /// Birincil metin - 54% opacity
  static const Color textPrimary54 = Color(0x8A000000);

  /// Gri ton (eski Colors.grey yerine)
  static const Color primaryGrey = Color(0xFF9E9E9E);

  /// Hata rengi accent (daha açık)
  static const Color errorAccent = Color(0xFFFC8181);

  /// Birincil metin - 45% opacity
  static const Color textPrimary45 = Color(0x73000000);

  // ══════════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Backward compatibility için eski isimler
  static const Color gradientStart = primary;
  static const Color gradientEnd = primaryDark;
  static const Color inputLabelColor = labelColor;

  /// Primary gradient (yukarıdan aşağıya)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Primary gradient (soldan sağa)
  static const LinearGradient primaryGradientLTR = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Bottom Navigation Bar gradient
  static const LinearGradient bottomNavGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ══════════════════════════════════════════════════════════════════════════

  /// Onay durumuna göre renk döndürür
  static Color getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('redd') || lower.contains('iptal')) {
      return statusRejected;
    }
    if (lower.contains('onay bekliyor') || lower.contains('beklemede')) {
      return statusPending;
    }
    if (lower.contains('onaylandı') || lower.contains('tamamlandı')) {
      return statusApproved;
    }
    return statusUnknown;
  }

  /// Onay durumuna göre arka plan rengi döndürür
  static Color getStatusBackgroundColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('redd') || lower.contains('iptal')) {
      return statusRejectedBg;
    }
    if (lower.contains('onay bekliyor') || lower.contains('beklemede')) {
      return statusPendingBg;
    }
    if (lower.contains('onaylandı') || lower.contains('tamamlandı')) {
      return statusApprovedBg;
    }
    return statusUnknownBg;
  }
}
