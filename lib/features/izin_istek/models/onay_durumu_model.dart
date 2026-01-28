/// Onay süreci personel bilgisi
class OnaySureciPersonel {
  final String personelAdi;
  final String gorevYeri;
  final String gorevi;
  final int personelId;
  final int onaySureciId;
  final bool? onay;
  final DateTime? islemTarihi;
  final String? aciklama;
  final bool geriGonderildi;
  final int onaySirasi;
  final String onayDurumu;
  final bool onayVerecek;
  final bool bildirimGidecek;
  final bool beklet;
  final int? bekletKademe;

  OnaySureciPersonel({
    required this.personelAdi,
    required this.gorevYeri,
    required this.gorevi,
    required this.personelId,
    required this.onaySureciId,
    this.onay,
    this.islemTarihi,
    this.aciklama,
    required this.geriGonderildi,
    required this.onaySirasi,
    required this.onayDurumu,
    required this.onayVerecek,
    required this.bildirimGidecek,
    required this.beklet,
    this.bekletKademe,
  });

  factory OnaySureciPersonel.fromJson(Map<String, dynamic> json) {
    try {
      // Safer boolean parsing that handles type conversions
      bool parseBool(dynamic value, [bool defaultValue = false]) {
        if (value == null) return defaultValue;
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
        if (value is int) return value != 0;
        return defaultValue;
      }

      return OnaySureciPersonel(
        personelAdi: (json['personelAdi'] ?? '') as String,
        gorevYeri: (json['gorevYeri'] ?? '') as String,
        gorevi: (json['gorevi'] ?? '') as String,
        personelId: (json['personelID'] as int?) ?? 0,
        onaySureciId: (json['onaySureciId'] as int?) ?? 0,
        onay: json['onay'] is bool ? json['onay'] as bool : null,
        islemTarihi: json['islemTarihi'] != null
            ? DateTime.parse(json['islemTarihi'] as String)
            : null,
        aciklama: json['aciklama'] as String?,
        geriGonderildi: parseBool(json['geriGonderildi']),
        onaySirasi: (json['onaySirasi'] as int?) ?? 0,
        onayDurumu: (json['onayDurumu'] ?? '') as String,
        onayVerecek: parseBool(json['onayVerecek']),
        bildirimGidecek: parseBool(json['bildirimGidecek']),
        beklet: parseBool(json['beklet']),
        bekletKademe: json['bekletKademe'] as int?,
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Onay Durumu API Response
class OnayDurumuResponse {
  final List<OnaySureciPersonel> onayVerecekler;
  final List<OnaySureciPersonel> bildirimGidecekler;
  final OnaySureciPersonel? siradakiOnayVerecekPersonel;
  final bool onayFormuGoster;
  final bool talepGuncellenebilir;
  final int bekletKademe;
  final bool gorevAtama;
  final bool atamaGoster;
  final String talepEdenPerAdi;
  final String talepEdenPerGorev;
  final String talepEdenPerGorevYeri;
  final DateTime? talepEdenTarih;

  OnayDurumuResponse({
    required this.onayVerecekler,
    required this.bildirimGidecekler,
    this.siradakiOnayVerecekPersonel,
    required this.onayFormuGoster,
    required this.talepGuncellenebilir,
    required this.bekletKademe,
    required this.gorevAtama,
    required this.atamaGoster,
    required this.talepEdenPerAdi,
    required this.talepEdenPerGorev,
    required this.talepEdenPerGorevYeri,
    this.talepEdenTarih,
  });

  factory OnayDurumuResponse.fromJson(Map<String, dynamic> json) {
    try {
      String getStringValue(dynamic value, [String defaultValue = '']) {
        if (value == null) return defaultValue;
        if (value is String) return value;
        if (value is bool) return value.toString();
        if (value is num) return value.toString();
        return defaultValue;
      }

      bool parseBool(dynamic value, [bool defaultValue = false]) {
        if (value == null) return defaultValue;
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
        if (value is num) return value != 0;
        return defaultValue;
      }

      return OnayDurumuResponse(
        onayVerecekler:
            (json['onayVerecekler'] as List<dynamic>?)
                ?.map(
                  (e) => OnaySureciPersonel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
        bildirimGidecekler:
            (json['bildirimGidecekler'] as List<dynamic>?)
                ?.map(
                  (e) => OnaySureciPersonel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
        siradakiOnayVerecekPersonel: json['siradakiOnayVerecekPersonel'] is Map
            ? OnaySureciPersonel.fromJson(
                json['siradakiOnayVerecekPersonel'] as Map<String, dynamic>,
              )
            : null,
        onayFormuGoster: json['onayFormuGoster'] is bool
            ? json['onayFormuGoster'] as bool
            : false,
        talepGuncellenebilir: json['talepGuncellenebilir'] is bool
            ? json['talepGuncellenebilir'] as bool
            : false,
        bekletKademe: (json['bekletKademe'] as int?) ?? 0,
        gorevAtama: parseBool(json['gorevAtama']),
        atamaGoster: parseBool(json['atamaGoster']),
        talepEdenPerAdi: getStringValue(json['talepEdenPerAdi']),
        talepEdenPerGorev: getStringValue(json['talepEdenPerGorev']),
        talepEdenPerGorevYeri: getStringValue(json['talepEdenPerGorevYeri']),
        talepEdenTarih: json['talepEdenTarih'] is String
            ? DateTime.parse(json['talepEdenTarih'] as String)
            : null,
      );
    } catch (e) {
      rethrow;
    }
  }
}
