class DovizKuru {
  final double kur;
  final String dovizKodu;

  DovizKuru({required this.kur, required this.dovizKodu});

  static DovizKuru fromAny(dynamic raw, {required String fallbackDovizKodu}) {
    if (raw == null) {
      return DovizKuru(kur: 0.0, dovizKodu: fallbackDovizKodu);
    }
    if (raw is Map) {
      return DovizKuru.fromJson(
        Map<String, dynamic>.from(raw),
        fallbackDovizKodu: fallbackDovizKodu,
      );
    }
    // Bazı servisler liste döndürebiliyor: [{...}] veya []
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map) {
        return DovizKuru.fromJson(
          Map<String, dynamic>.from(first),
          fallbackDovizKodu: fallbackDovizKodu,
        );
      }
      if (first is num || first is String) {
        final parsed = _tryParseKur(first);
        return DovizKuru(kur: parsed, dovizKodu: fallbackDovizKodu);
      }
    }
    // Düz string/num dönerse
    if (raw is num || raw is String) {
      final parsed = _tryParseKur(raw);
      return DovizKuru(kur: parsed, dovizKodu: fallbackDovizKodu);
    }
    return DovizKuru(kur: 0.0, dovizKodu: fallbackDovizKodu);
  }

  factory DovizKuru.fromJson(
    Map<String, dynamic> json, {
    required String fallbackDovizKodu,
  }) {
    // Bazı servisler response'u sarmalıyor olabilir
    final nested = (json['data'] ?? json['result'] ?? json['sonuc']);
    if (nested is Map) {
      return DovizKuru.fromJson(
        Map<String, dynamic>.from(nested),
        fallbackDovizKodu: fallbackDovizKodu,
      );
    }
    if (nested is List && nested.isNotEmpty) {
      final first = nested.first;
      if (first is Map) {
        return DovizKuru.fromJson(
          Map<String, dynamic>.from(first),
          fallbackDovizKodu: fallbackDovizKodu,
        );
      }
      if (first is num || first is String) {
        final parsed = _tryParseKur(first);
        return DovizKuru(kur: parsed, dovizKodu: fallbackDovizKodu);
      }
    }

    final dovizKodu =
        (json['dovizKodu'] ?? json['DovizKodu'] ?? json['kod'] ?? json['Kod'])
            as String? ??
        fallbackDovizKodu;

    final rawKur =
        json['tlTutar'] ??
        json['kur'] ??
        json['Kur'] ??
        json['dovizKuru'] ??
        json['DovizKuru'] ??
        json['rate'] ??
        json['Rate'];

    double kur = _tryParseKur(rawKur);

    // Hiçbir alan uymadıysa tek değerli maplerde doğrudan ilk değeri dene
    if (kur == 0.0 && rawKur == null && json.length == 1) {
      final value = json.values.first;
      kur = _tryParseKur(value);
    }

    return DovizKuru(kur: kur, dovizKodu: dovizKodu);
  }

  static double _tryParseKur(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final trimmed = value.trim();
      final normalized = trimmed.contains(',')
          ? trimmed.replaceAll('.', '').replaceAll(',', '.')
          : trimmed.replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0.0;
    }
    return 0.0;
  }
}
