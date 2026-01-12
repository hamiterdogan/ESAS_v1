import 'package:intl/intl.dart';

/// Araç form için zaman hesaplama ve formatlama yardımcı metodları.
mixin AracFormTimeMixin {
  static const List<int> allowedMinutes = [
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
  ];

  /// Saat ve dakikayı format string olarak döndürür.
  String formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Tarihi kısa formatta döndürür (dd.MM.yyyy).
  String formatDateShort(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Tarihi uzun formatta döndürür (d MMMM yyyy).
  String formatDateLong(DateTime date, {String locale = 'tr_TR'}) {
    return DateFormat('d MMMM yyyy', locale).format(date);
  }

  /// İki zaman noktasını karşılaştırır (h1:m1 < h2:m2).
  bool isBefore(int h1, int m1, int h2, int m2) {
    if (h1 < h2) return true;
    if (h1 == h2 && m1 < m2) return true;
    return false;
  }

  /// İki zaman noktasını karşılaştırır (h1:m1 <= h2:m2).
  bool isBeforeOrEqual(int h1, int m1, int h2, int m2) {
    return isBefore(h1, m1, h2, m2) || (h1 == h2 && m1 == m2);
  }

  /// Gidiş saatine göre minimum dönüş saatini hesaplar.
  (int, int) computeMinDonus(int gidisHour, int gidisMinute) {
    int h = gidisHour;
    int m = gidisMinute;

    // En az 5 dakika sonra
    final idx = allowedMinutes.indexOf(m);
    if (idx < allowedMinutes.length - 1) {
      m = allowedMinutes[idx + 1];
    } else {
      m = allowedMinutes.first;
      h = (h + 1).clamp(0, 23);
    }

    return (h, m);
  }

  /// Gidiş saati değiştiğinde dönüş saatini senkronize eder.
  /// En az 1 saat fark olmasını sağlar.
  (int, int) syncDonusWithGidis({
    required int gidisHour,
    required int gidisMinute,
    required int currentDonusHour,
    required int currentDonusMinute,
  }) {
    int targetHour = gidisHour + 1;
    int targetMinute = gidisMinute;

    if (targetHour > 23) {
      targetHour = 23;
      targetMinute = allowedMinutes.last;
    }

    final minDonus = computeMinDonus(gidisHour, gidisMinute);

    // Eğer mevcut dönüş zamanı gidiş zamanından önce veya eşitse
    if (isBeforeOrEqual(
      currentDonusHour,
      currentDonusMinute,
      gidisHour,
      gidisMinute,
    )) {
      return (targetHour, targetMinute);
    }

    // Eğer mevcut dönüş minimum dönüşten önceyse
    if (isBefore(
      currentDonusHour,
      currentDonusMinute,
      minDonus.$1,
      minDonus.$2,
    )) {
      return minDonus;
    }

    return (currentDonusHour, currentDonusMinute);
  }

  /// Verilen dakikayı izin verilen dakikalar listesine yuvarlar.
  int roundToAllowedMinute(int minute) {
    for (int i = 0; i < allowedMinutes.length; i++) {
      if (minute <= allowedMinutes[i]) {
        return allowedMinutes[i];
      }
    }
    return allowedMinutes.first;
  }

  /// Sınıf stringinden seviye çıkarır (örn: "5-A" → "5").
  String deriveSeviyeFromSinif(String sinif, {String fallback = '0'}) {
    final parts = sinif.split('-');
    if (parts.isNotEmpty) {
      final numMatch = RegExp(r'\d+').firstMatch(parts.first);
      if (numMatch != null) return numMatch.group(0) ?? fallback;
    }
    return fallback;
  }
}

/// Araç form için özet (summary) string oluşturma yardımcı metodları.
mixin AracFormSummaryMixin {
  /// Seçili öğe sayısını özet stringi olarak döndürür.
  String buildCountSummary(int count, String singular, String plural) {
    if (count == 0) return 'Seçiniz';
    if (count == 1) return '1 $singular seçildi';
    return '$count $plural seçildi';
  }

  /// Seçili öğeleri liste olarak formatlar.
  String buildListSummary(
    List<String> items, {
    int maxItems = 3,
    String emptyText = 'Seçiniz',
  }) {
    if (items.isEmpty) return emptyText;

    if (items.length <= maxItems) {
      return items.join(', ');
    }

    final visible = items.take(maxItems).join(', ');
    final remaining = items.length - maxItems;
    return '$visible (+$remaining)';
  }

  /// Set'ten liste summary oluşturur.
  String buildSetSummary<T>(
    Set<T> items,
    String Function(T) labelGetter, {
    int maxItems = 3,
    String emptyText = 'Seçiniz',
  }) {
    if (items.isEmpty) return emptyText;

    final labels = items.map(labelGetter).toList();
    return buildListSummary(labels, maxItems: maxItems, emptyText: emptyText);
  }
}
