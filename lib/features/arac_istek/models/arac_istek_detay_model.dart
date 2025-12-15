class AracIstekDetayResponse {
  final Map<String, dynamic> raw;

  AracIstekDetayResponse({required this.raw});

  factory AracIstekDetayResponse.fromJson(Map<String, dynamic> json) {
    return AracIstekDetayResponse(raw: json);
  }

  String _string(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String get adSoyad {
    final combined = _string(['adSoyad']);
    if (combined.isNotEmpty) return combined;
    final ad = _string(['ad']);
    final soyad = _string(['soyad']);
    final full = '$ad $soyad'.trim();
    return full.isNotEmpty ? full : '';
  }

  String get gorevYeri => _string(['gorevYeri', 'gorevYeriAdi', 'lokasyon']);
  String get gorev => _string(['gorev', 'gorevi', 'gorevAdi', 'unvan']);
  String get aracTuru => _string(['aracTuru', 'aracTipi']);
  String get guzergah => _string(['guzergah', 'rota', 'guzergahBilgisi']);
  String get cikisSaati => _string(['cikisSaati', 'gidisSaati']);
  String get donusSaati => _string(['donusSaati', 'gelisSaati']);
  String get baslangicTarihi =>
      _string(['baslangicTarihi', 'tarih', 'gidisTarihi']);
  String get bitisTarihi => _string(['bitisTarihi', 'donusTarihi']);
  String get aciklama => _string(['aciklama', 'aciklamasi']);
  String get soforTalebi => _string(['sofor', 'soforTalebi']);
  String get yolcuSayisi => _string(['yolcuSayisi', 'kisiSayisi']);

  // Yeni alanlar
  String get gidilecekTarih => _string(['gidilecekTarih']);
  String get gidisSaat => _string(['gidisSaat', 'gidisSaati']);
  String get donusSaat => _string(['donusSaat', 'donusSaati']);
  String get mesafe => _string(['mesafe']);
  String get istekNedeni => _string(['istekNedeni']);
  String get istekNedeniDiger => _string(['istekNedeniDiger']);

  // Gidilecek yerler listesi
  String get gidilecekYerler {
    final gidilecekYerlerList = raw['gidilecekYerler'];
    if (gidilecekYerlerList == null || gidilecekYerlerList is! List) {
      return '';
    }
    final yerler = <String>[];
    for (final item in gidilecekYerlerList) {
      if (item is Map<String, dynamic>) {
        // Önce gidilecekYer, sonra semt alanını kontrol et
        final yer = item['gidilecekYer']?.toString().trim();
        final semt = item['semt']?.toString().trim();
        final yerText = (yer != null && yer.isNotEmpty) ? yer : semt;
        if (yerText != null && yerText.isNotEmpty) {
          yerler.add(yerText);
        }
      }
    }
    return yerler.join(', ');
  }

  // Yolcu listesi
  List<Map<String, String>> get yolcuIsimleri {
    final yolcuList = raw['yolcuIsimleri'];
    final yolcular = <Map<String, String>>[];
    if (yolcuList is List) {
      for (final item in yolcuList) {
        if (item is Map<String, dynamic>) {
          final kisiTipi =
              item['kisiTipi']?.toString().trim() ??
              item['tip']?.toString().trim() ??
              item['type']?.toString().trim() ??
              '';
          yolcular.add({
            'ad':
                item['perAdi']?.toString().trim() ??
                item['ad']?.toString().trim() ??
                '',
            'gorevi': item['gorevi']?.toString().trim() ?? '',
            'gorevYeri': item['gorevYeri']?.toString().trim() ?? '',
            'kisiTipi': kisiTipi,
          });
        }
      }
    }

    final okullarSatir = raw['okullarSatir'];
    if (okullarSatir is List) {
      for (final item in okullarSatir) {
        if (item is Map<String, dynamic>) {
          final ad = item['adi']?.toString().trim() ?? '';
          final soyad = item['soyadi']?.toString().trim() ?? '';
          final sinif = item['sinif']?.toString().trim() ?? '';
          final numara = item['numara']?.toString().trim() ?? '';
          final okul = item['okulKodu']?.toString().trim() ?? '';
          final seviye = item['seviye']?.toString().trim() ?? '';

          final gorevYeri = [
            okul,
            sinif,
          ].where((v) => v.isNotEmpty).join(' • ');
          final detaylar = <String>[];
          if (seviye.isNotEmpty) detaylar.add('Seviye: $seviye');
          if (numara.isNotEmpty) detaylar.add('No: $numara');

          yolcular.add({
            'ad': '$ad $soyad'.trim(),
            'gorevi': detaylar.join(' | '),
            'gorevYeri': gorevYeri,
            'kisiTipi': 'ogrenci',
          });
        }
      }
    }

    return yolcular;
  }

  // Personel sayısı
  int get personelSayisi {
    final yolcuList = raw['yolcuIsimleri'];
    if (yolcuList == null || yolcuList is! List) {
      return 0;
    }
    return yolcuList.where((item) {
      if (item is Map<String, dynamic>) {
        final kisiTipi = item['kisiTipi']?.toString().toLowerCase() ?? '';
        return kisiTipi.contains('personel') || kisiTipi.contains('staff');
      }
      return false;
    }).length;
  }

  // Öğrenci sayısı
  int get ogrenciSayisi {
    int count = 0;
    final yolcuList = raw['yolcuIsimleri'];
    if (yolcuList is List) {
      count += yolcuList.where((item) {
        if (item is Map<String, dynamic>) {
          final kisiTipi = item['kisiTipi']?.toString().toLowerCase() ?? '';
          return kisiTipi.contains('ogrenci') || kisiTipi.contains('student');
        }
        return false;
      }).length;
    }

    final okullarSatir = raw['okullarSatir'];
    if (okullarSatir is List) {
      count += okullarSatir.length;
    }

    return count;
  }

  /// Ana detay alanlarını etiketli bir listeye çevirir.
  List<MapEntry<String, String>> get detailEntries {
    final entries = <MapEntry<String, String>>[];

    void add(String label, String value) {
      final v = value.trim();
      if (v.isNotEmpty) entries.add(MapEntry(label, v));
    }

    add('Araç Türü', aracTuru);
    add('Güzergah', guzergah);
    add('Başlangıç Tarihi', baslangicTarihi);
    add('Bitiş Tarihi', bitisTarihi);
    add('Çıkış Saati', cikisSaati);
    add('Dönüş Saati', donusSaati);
    add('Yolcu Sayısı', yolcuSayisi);
    add('Şoför Talebi', soforTalebi);
    add('Açıklama', aciklama);

    // Geri kalan alanları ekle (nested olmayan string'leri)
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value == null) continue;
      if (value is Map || value is List) continue;
      final text = value.toString().trim();
      if (text.isEmpty) continue;

      final alreadyExists = entries.any((e) => e.key == key || e.value == text);
      if (alreadyExists) continue;

      entries.add(MapEntry(_humanizeKey(key), text));
    }

    return entries;
  }

  String _humanizeKey(String key) {
    final buffer = StringBuffer();
    for (int i = 0; i < key.length; i++) {
      final char = key[i];
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (i == 0) {
        buffer.write(char.toUpperCase());
      } else {
        if (isUpper) buffer.write(' ');
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
