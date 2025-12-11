import 'package:flutter/material.dart';

enum TalepTuruEnum {
  aracIstek('Araç İstek', 'arac_istek'),
  bilgiTeknolojileri('Bilgi Teknolojileri', 'bilgi_teknolojileri'),
  dokumantasyonIstek('Dokümantasyon İstek', 'dokumantasyon_istek'),
  egitimIstek('Eğitim İstek', 'egitim_istek'),
  izinIstek('İzin İstek', 'izin_istek'),
  sarfMalzemeIstek('Sarf Malzeme İstek', 'sarf_malzeme_istek'),
  satinAlma('Satın Alma', 'satin_alma'),
  teknikDestek('Teknik Destek', 'teknik_destek'),
  yiyecekIcecekIstek('Yiyecek İçecek İstek', 'yiyecek_icecek_istek');

  final String label;
  final String routePath;

  const TalepTuruEnum(this.label, this.routePath);
}

class TalepTuru {
  final TalepTuruEnum type;
  final String label;
  final IconData icon;
  final String routePath;

  TalepTuru({
    required this.type,
    required this.label,
    required this.icon,
    required this.routePath,
  });

  static final Map<TalepTuruEnum, TalepTuru> _map = {
    TalepTuruEnum.aracIstek: TalepTuru(
      type: TalepTuruEnum.aracIstek,
      label: 'Araç İstek',
      icon: Icons.directions_car,
      routePath: '/arac_istek',
    ),
    TalepTuruEnum.bilgiTeknolojileri: TalepTuru(
      type: TalepTuruEnum.bilgiTeknolojileri,
      label: 'Bilgi Teknolojileri',
      icon: Icons.computer,
      routePath: '/bilgi_teknolojileri',
    ),
    TalepTuruEnum.dokumantasyonIstek: TalepTuru(
      type: TalepTuruEnum.dokumantasyonIstek,
      label: 'Dokümantasyon İstek',
      icon: Icons.description,
      routePath: '/dokumantasyon_istek',
    ),
    TalepTuruEnum.egitimIstek: TalepTuru(
      type: TalepTuruEnum.egitimIstek,
      label: 'Eğitim İstek',
      icon: Icons.school,
      routePath: '/egitim_istek',
    ),
    TalepTuruEnum.izinIstek: TalepTuru(
      type: TalepTuruEnum.izinIstek,
      label: 'İzin İstek',
      icon: Icons.calendar_today,
      routePath: '/izin_istek',
    ),
    TalepTuruEnum.sarfMalzemeIstek: TalepTuru(
      type: TalepTuruEnum.sarfMalzemeIstek,
      label: 'Sarf Malzeme İstek',
      icon: Icons.inventory,
      routePath: '/sarf_malzeme_istek',
    ),
    TalepTuruEnum.satinAlma: TalepTuru(
      type: TalepTuruEnum.satinAlma,
      label: 'Satın Alma',
      icon: Icons.shopping_cart,
      routePath: '/satin_alma',
    ),
    TalepTuruEnum.teknikDestek: TalepTuru(
      type: TalepTuruEnum.teknikDestek,
      label: 'Teknik Destek',
      icon: Icons.build,
      routePath: '/teknik_destek',
    ),
    TalepTuruEnum.yiyecekIcecekIstek: TalepTuru(
      type: TalepTuruEnum.yiyecekIcecekIstek,
      label: 'Yiyecek İçecek İstek',
      icon: Icons.restaurant,
      routePath: '/yiyecek_icecek_istek',
    ),
  };

  static TalepTuru fromEnum(TalepTuruEnum type) {
    return _map[type]!;
  }

  static List<TalepTuru> getAll() {
    return _map.values.toList();
  }
}
