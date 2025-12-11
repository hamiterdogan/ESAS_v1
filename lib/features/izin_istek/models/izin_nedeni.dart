class IzinNedeni {
  final int izinSebebiId;
  final String izinNedeni;
  final String izinAdi;
  final int izinKacGunSonraBaslayacak;
  final bool saatGoster;

  IzinNedeni({
    required this.izinSebebiId,
    required this.izinNedeni,
    required this.izinAdi,
    required this.izinKacGunSonraBaslayacak,
    required this.saatGoster,
  });

  factory IzinNedeni.fromJson(Map<String, dynamic> json) {
    return IzinNedeni(
      izinSebebiId: json['izinSebebiId'] as int? ?? 0,
      izinNedeni: json['izinNedeni'] as String? ?? '',
      izinAdi: json['izinAdi'] as String? ?? '',
      izinKacGunSonraBaslayacak: json['izinKacGunSonraBaslayacak'] as int? ?? 0,
      saatGoster: json['saatGoster'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'izinSebebiId': izinSebebiId,
      'izinNedeni': izinNedeni,
      'izinAdi': izinAdi,
      'izinKacGunSonraBaslayacak': izinKacGunSonraBaslayacak,
      'saatGoster': saatGoster,
    };
  }
}
