import 'package:flutter/material.dart';

enum DokumantasyonTuruEnum {
  a4Kagidi('A4 Kağıdı İstek', '/dokumantasyon/a4_kagidi'),
  dokumantasyonBaski('Dokümantasyon Baskı İstek', '/dokumantasyon/baski');

  final String label;
  final String routePath;

  const DokumantasyonTuruEnum(this.label, this.routePath);
}

class DokumantasyonTuru {
  final DokumantasyonTuruEnum type;
  final String label;
  final IconData icon;
  final String routePath;

  DokumantasyonTuru({
    required this.type,
    required this.label,
    required this.icon,
    required this.routePath,
  });

  static final Map<DokumantasyonTuruEnum, DokumantasyonTuru> _map = {
    DokumantasyonTuruEnum.a4Kagidi: DokumantasyonTuru(
      type: DokumantasyonTuruEnum.a4Kagidi,
      label: 'A4 Kağıdı İstek',
      icon: Icons.description,
      routePath: '/dokumantasyon/a4_kagidi',
    ),
    DokumantasyonTuruEnum.dokumantasyonBaski: DokumantasyonTuru(
      type: DokumantasyonTuruEnum.dokumantasyonBaski,
      label: 'Dokümantasyon Baskı İstek',
      icon: Icons.print,
      routePath: '/dokumantasyon/baski',
    ),
  };

  static List<DokumantasyonTuru> getAll() => _map.values.toList();
}
