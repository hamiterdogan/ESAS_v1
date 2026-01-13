import 'dart:io';

import 'package:state_notifier/state_notifier.dart';
import 'package:esas_v1/features/satin_alma/domain/entities/satin_alma_talep_entity.dart';
import 'package:esas_v1/features/satin_alma/domain/usecases/create_satin_alma_talep_usecase.dart';

class SatinAlmaFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  // Fields
  final bool pesin;
  final DateTime? sonTeslimTarihi;
  final String aliminAmaci;
  final int odemeSekliId;
  final String webSitesi;
  final String saticiTel;
  final List<int> binaId;
  final String saticiFirma;
  final String dosyaAciklama;
  final int odemeVadesiGun;
  
  final List<SatinAlmaUrunSatirEntity> urunSatirlar;
  
  // Calculated
  double get genelToplam => urunSatirlar.fold(0, (sum, item) => sum + (item.miktar * item.birimFiyati));

  const SatinAlmaFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.pesin = false,
    this.sonTeslimTarihi,
    this.aliminAmaci = '',
    this.odemeSekliId = 0,
    this.webSitesi = '',
    this.saticiTel = '',
    this.binaId = const <int>[],
    this.saticiFirma = '',
    this.dosyaAciklama = '',
    this.odemeVadesiGun = 0,
    this.urunSatirlar = const <SatinAlmaUrunSatirEntity>[],
  });

  SatinAlmaFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool? pesin,
    DateTime? sonTeslimTarihi,
    String? aliminAmaci,
    int? odemeSekliId,
    String? webSitesi,
    String? saticiTel,
    List<int>? binaId,
    String? saticiFirma,
    String? dosyaAciklama,
    int? odemeVadesiGun,
    List<SatinAlmaUrunSatirEntity>? urunSatirlar,
  }) {
    return SatinAlmaFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      pesin: pesin ?? this.pesin,
      sonTeslimTarihi: sonTeslimTarihi ?? this.sonTeslimTarihi,
      aliminAmaci: aliminAmaci ?? this.aliminAmaci,
      odemeSekliId: odemeSekliId ?? this.odemeSekliId,
      webSitesi: webSitesi ?? this.webSitesi,
      saticiTel: saticiTel ?? this.saticiTel,
      binaId: binaId ?? this.binaId,
      saticiFirma: saticiFirma ?? this.saticiFirma,
      dosyaAciklama: dosyaAciklama ?? this.dosyaAciklama,
      odemeVadesiGun: odemeVadesiGun ?? this.odemeVadesiGun,
      urunSatirlar: urunSatirlar ?? this.urunSatirlar,
    );
  }
}

class SatinAlmaFormNotifier extends StateNotifier<SatinAlmaFormState> {
  final CreateSatinAlmaTalepUseCase _createUseCase;

  SatinAlmaFormNotifier(this._createUseCase) : super(const SatinAlmaFormState());

  void setPesin(bool value) => state = state.copyWith(pesin: value);
  void setSonTeslimTarihi(DateTime date) => state = state.copyWith(sonTeslimTarihi: date);
  void setAliminAmaci(String value) => state = state.copyWith(aliminAmaci: value);
  void setOdemeSekli(int id) => state = state.copyWith(odemeSekliId: id);
  void setWebSitesi(String value) => state = state.copyWith(webSitesi: value);
  void setSaticiTel(String value) => state = state.copyWith(saticiTel: value);
  void setSaticiFirma(String value) => state = state.copyWith(saticiFirma: value);
  void setDosyaAciklama(String value) => state = state.copyWith(dosyaAciklama: value);
  void setOdemeVadesiGun(int value) => state = state.copyWith(odemeVadesiGun: value);
  
  void toggleBina(int id) {
    final current = [...state.binaId];
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(binaId: current);
  }

  void addUrunSatir(SatinAlmaUrunSatirEntity item) {
    state = state.copyWith(urunSatirlar: [...state.urunSatirlar, item]);
  }
  
  void removeUrunSatir(int index) {
      final updated = [...state.urunSatirlar];
      updated.removeAt(index);
      state = state.copyWith(urunSatirlar: updated);
  }

  Future<void> submit(List<File> files) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Validation
    if (state.binaId.isEmpty) {
         state = state.copyWith(isLoading: false, errorMessage: 'Lütfen en az bir yerleşke/bina seçiniz.');
         return;
    }
    if (state.urunSatirlar.isEmpty) {
         state = state.copyWith(isLoading: false, errorMessage: 'Lütfen en az bir ürün ekleyiniz.');
         return;
    }

    final talep = SatinAlmaTalep(
      files: files,
      pesin: state.pesin,
      sonTeslimTarihi: state.sonTeslimTarihi ?? DateTime.now(),
      aliminAmaci: state.aliminAmaci,
      odemeSekliId: state.odemeSekliId,
      webSitesi: state.webSitesi,
      saticiTel: state.saticiTel,
      binaId: state.binaId,
      odemeVadesiGun: state.odemeVadesiGun,
      urunSatirlar: state.urunSatirlar,
      saticiFirma: state.saticiFirma,
      genelToplam: state.genelToplam,
      dosyaAciklama: state.dosyaAciklama,
    );

    final result = await _createUseCase(talep);

    state = result.when(
      success: (_) => state.copyWith(isLoading: false, isSuccess: true),
      failure: (message) => state.copyWith(isLoading: false, errorMessage: message),
    );
  }
}
