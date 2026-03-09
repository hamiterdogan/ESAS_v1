/// Bildirim modeli - API'den gelen bildirim verileri
class BildirimModel {
  final int id;
  final String baslik;
  final String mesaj;
  final String? deepLink;
  final String bildirimTipi; // talep türü route path (ör: "satin_alma")
  final int? talepId;
  final String? onayTipi;
  final int? onayKayitId;
  final String aksiyonTipi; // "onay_bekliyor", "bilgilendirme", "gorev_atama"
  final bool okundu;
  final DateTime olusturmaTarihi;
  final String? gonderenAd;

  BildirimModel({
    required this.id,
    required this.baslik,
    required this.mesaj,
    this.deepLink,
    required this.bildirimTipi,
    this.talepId,
    this.onayTipi,
    this.onayKayitId,
    required this.aksiyonTipi,
    required this.okundu,
    required this.olusturmaTarihi,
    this.gonderenAd,
  });

  factory BildirimModel.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1';
      }
      if (value is num) return value != 0;
      return false;
    }

    final parsedOnayKayitId = parseInt(
      json['onayKayitId'] ?? json['OnayKayitId'],
    );
    final parsedTalepId =
        parseInt(json['talepId'] ?? json['TalepId']) ?? parsedOnayKayitId;
    final parsedOnayTipi = (json['onayTipi'] ?? json['OnayTipi'])?.toString();
    final parsedId = parseInt(json['id'] ?? json['Id']) ?? 0;

    return BildirimModel(
      id: parsedId,
      baslik:
          (json['title'] ?? json['Title'] ?? json['baslik'] ?? json['Baslik'])
              ?.toString() ??
          '',
      mesaj:
          (json['body'] ?? json['Body'] ?? json['mesaj'] ?? json['Mesaj'])
              ?.toString() ??
          '',
      deepLink: (json['deepLink'] ?? json['DeepLink'])?.toString(),
      bildirimTipi:
          (json['bildirimTipi'] ?? json['BildirimTipi'])?.toString() ??
          parsedOnayTipi ??
          '',
      talepId: parsedTalepId,
      onayTipi: parsedOnayTipi,
      onayKayitId: parsedOnayKayitId,
      aksiyonTipi:
          (json['aksiyonTipi'] ?? json['AksiyonTipi'])?.toString() ??
          'bilgilendirme',
      okundu: parseBool(
        json['isRead'] ?? json['IsRead'] ?? json['okundu'] ?? json['Okundu'],
      ),
      olusturmaTarihi:
          DateTime.tryParse(
            (json['createdAt'] ??
                        json['CreatedAt'] ??
                        json['olusturmaTarihi'] ??
                        json['OlusturmaTarihi'])
                    ?.toString() ??
                '',
          ) ??
          DateTime.now(),
      gonderenAd: (json['gonderenAd'] ?? json['GonderenAd'])?.toString(),
    );
  }

  /// Bildirim actionable mi (onay/red yapılabilir mi)?
  bool get isActionable => aksiyonTipi == 'onay_bekliyor';

  /// Deep link route path
  String? get deepLinkRoute {
    if (deepLink != null && deepLink!.isNotEmpty) {
      final uri = Uri.tryParse(deepLink!);
      if (uri != null && uri.host == 'talep-detay') {
        final idFromPath = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : null;
        if (idFromPath != null && idFromPath.isNotEmpty) {
          final kategori = uri.queryParameters['kategori'];
          final encodedKategori = kategori != null
              ? Uri.encodeQueryComponent(kategori)
              : null;
          return encodedKategori != null
              ? '/talep-detay/$idFromPath?kategori=$encodedKategori'
              : '/talep-detay/$idFromPath';
        }
      }
    }

    final normalizedBildirimTipi = _normalizeValue(bildirimTipi);
    if (normalizedBildirimTipi == 'bilgiteknolojileri') {
      return talepId != null
          ? '/teknik_destek/detay/$talepId'
          : '/bilgi_teknolojileri';
    }
    if (normalizedBildirimTipi == 'teknikdestek') {
      return talepId != null
          ? '/teknik_destek/detay/$talepId'
          : '/teknik_destek';
    }
    if (normalizedBildirimTipi == 'sarfmalzemeistek') {
      return talepId != null
          ? '/sarf_malzeme_istek/detay/$talepId'
          : '/sarf_malzeme_istek';
    }

    if (talepId == null) return null;

    final normalizedOnayTipi = _normalizeValue(onayTipi ?? '');
    if (normalizedOnayTipi.contains('dokumantasyon') ||
        normalizedOnayTipi.contains('dokuman')) {
      return '/dokumantasyon/detay/$talepId';
    }
    if (normalizedOnayTipi.contains('izin')) {
      return '/izin/detay/$talepId';
    }
    if (normalizedOnayTipi.contains('satinalma')) {
      return '/satin_alma/detay/$talepId';
    }
    if (normalizedOnayTipi.contains('egitim')) {
      return '/egitim_istek/detay/$talepId';
    }
    if (normalizedOnayTipi.contains('yiyecek') ||
        normalizedOnayTipi.contains('icecek')) {
      return '/yiyecek_icecek_istek/detay/$talepId';
    }
    if (normalizedOnayTipi.contains('bilgiteknoloji') ||
        normalizedOnayTipi.contains('teknikdestek') ||
        normalizedOnayTipi.contains('teknik')) {
      return '/teknik_destek/detay/$talepId';
    }
    if (normalizedOnayTipi.contains('arac')) {
      return '/arac/detay/$talepId';
    }
    if (normalizedOnayTipi.contains('sarfmalzeme') ||
        normalizedOnayTipi.contains('sarf')) {
      return '/sarf_malzeme_istek/detay/$talepId';
    }

    switch (normalizedBildirimTipi) {
      case 'satinalma':
        return '/satin_alma/detay/$talepId';
      case 'aracistek':
        return '/arac/detay/$talepId';
      case 'izinistek':
        return '/izin/detay/$talepId';
      case 'dokumantasyonistek':
        return '/dokumantasyon/detay/$talepId';
      case 'egitimistek':
        return '/egitim_istek/detay/$talepId';
      case 'yiyecekicecekistek':
        return '/yiyecek_icecek_istek/detay/$talepId';
      case 'bilgiteknolojileri':
      case 'teknikdestek':
        return '/teknik_destek/detay/$talepId';
      case 'sarfmalzemeistek':
        return '/sarf_malzeme_istek/detay/$talepId';
      default:
        final normalizedBaslik = _normalizeValue(baslik);
        if (normalizedBaslik.contains('dokumantasyon')) {
          return '/dokumantasyon/detay/$talepId';
        }
        if (normalizedBaslik.contains('izin')) {
          return '/izin/detay/$talepId';
        }
        if (normalizedBaslik.contains('bilgiteknoloji') ||
            normalizedBaslik.contains('teknikdestek') ||
            normalizedBaslik.contains('teknik')) {
          return '/teknik_destek/detay/$talepId';
        }
        return null;
    }
  }

  String _normalizeValue(String value) => value
      .replaceAll('İ', 'I')
      .replaceAll('Ğ', 'G')
      .replaceAll('Ü', 'U')
      .replaceAll('Ş', 'S')
      .replaceAll('Ö', 'O')
      .replaceAll('Ç', 'C')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Bildirim listesi API response modeli
class BildirimListResponse {
  final List<BildirimModel> bildirimler;
  final int toplamSayfa;
  final int toplamKayit;
  final int okunmamisSayisi;

  BildirimListResponse({
    required this.bildirimler,
    required this.toplamSayfa,
    required this.toplamKayit,
    required this.okunmamisSayisi,
  });

  factory BildirimListResponse.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final items =
        (root['items'] as List<dynamic>? ??
                root['Items'] as List<dynamic>? ??
                root['bildirimler'] as List<dynamic>? ??
                const <dynamic>[])
            .map((e) => BildirimModel.fromJson(e as Map<String, dynamic>))
            .toList();

    return BildirimListResponse(
      bildirimler: items,
      toplamSayfa: (root['toplamSayfa'] as int?) ?? 1,
      toplamKayit:
          (root['totalCount'] as int?) ??
          (root['TotalCount'] as int?) ??
          (root['toplamKayit'] as int?) ??
          items.length,
      okunmamisSayisi:
          (root['okunmamisSayisi'] as int?) ??
          items.where((item) => !item.okundu).length,
    );
  }
}

/// Token kayıt response
class TokenKaydetResponse {
  final bool basarili;
  final String? mesaj;

  TokenKaydetResponse({required this.basarili, this.mesaj});

  factory TokenKaydetResponse.fromJson(Map<String, dynamic> json) {
    return TokenKaydetResponse(
      basarili: json['basarili'] as bool? ?? false,
      mesaj: json['mesaj'] as String?,
    );
  }
}

/// Bildirim aksiyon (onay/red) response
class BildirimAksiyonResponse {
  final bool basarili;
  final String? mesaj;

  BildirimAksiyonResponse({required this.basarili, this.mesaj});

  factory BildirimAksiyonResponse.fromJson(Map<String, dynamic> json) {
    return BildirimAksiyonResponse(
      basarili: json['basarili'] as bool? ?? false,
      mesaj: json['mesaj'] as String?,
    );
  }
}
