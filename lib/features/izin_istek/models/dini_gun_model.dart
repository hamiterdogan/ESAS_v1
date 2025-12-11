class DiniGun {
  final String izinGunu;

  DiniGun({required this.izinGunu});

  factory DiniGun.fromJson(Map<String, dynamic> json) {
    return DiniGun(izinGunu: json['izinGunu'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'izinGunu': izinGunu};
  }
}
