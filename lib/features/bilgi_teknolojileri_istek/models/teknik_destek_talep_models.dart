class TeknikDestekTalepEkleRequest {
  final int personelId;
  final String bina;
  final String hizmetTuru;
  final String aciklama;
  final DateTime sonTarih;
  final List<HizmetItem> hizmetler;

  TeknikDestekTalepEkleRequest({
    required this.personelId,
    required this.bina,
    required this.hizmetTuru,
    required this.aciklama,
    required this.sonTarih,
    required this.hizmetler,
  });

  Map<String, dynamic> toJson() {
    return {
      'personelId': personelId,
      'bina': bina,
      'hizmetTuru': hizmetTuru,
      'aciklama': aciklama,
      'sonTarih': sonTarih.toIso8601String(),
      'hizmetler': hizmetler.map((h) => h.toJson()).toList(),
    };
  }
}

class HizmetItem {
  final String hizmetKategori;
  final String hizmetDetay;

  HizmetItem({required this.hizmetKategori, required this.hizmetDetay});

  Map<String, dynamic> toJson() {
    return {'hizmetKategori': hizmetKategori, 'hizmetDetay': hizmetDetay};
  }
}

class TeknikDestekTalepEkleResponse {
  final bool basarili;
  final String mesaj;
  final int onayKayitId;

  TeknikDestekTalepEkleResponse({
    required this.basarili,
    required this.mesaj,
    required this.onayKayitId,
  });

  factory TeknikDestekTalepEkleResponse.fromJson(Map<String, dynamic> json) {
    return TeknikDestekTalepEkleResponse(
      basarili: json['basarili'] ?? false,
      mesaj: json['mesaj'] ?? '',
      onayKayitId: json['onayKayitId'] ?? 0,
    );
  }

  @override
  String toString() =>
      'TeknikDestekTalepEkleResponse(basarili: $basarili, mesaj: $mesaj, onayKayitId: $onayKayitId)';
}
