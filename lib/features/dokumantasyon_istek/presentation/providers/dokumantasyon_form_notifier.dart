import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/dokumantasyon_istek/domain/entities/dokumantasyon_talep.dart';
import 'package:esas_v1/features/dokumantasyon_istek/domain/usecases/create_dokumantasyon_talep_usecase.dart';
import 'package:esas_v1/features/dokumantasyon_istek/presentation/providers/dokumantasyon_providers.dart';

class DokumantasyonFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  final DateTime? teslimTarihi;
  final int baskiAdedi;
  final String kagitTalebi;
  final String dokumanTuru;
  final String aciklama;
  final String baskiTuru;
  final bool onluArkali;
  final bool kopyaElden;
  final String dosyaAciklama;
  // Simplified for this refactor demo

  const DokumantasyonFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.teslimTarihi,
    this.baskiAdedi = 1,
    this.kagitTalebi = 'A4',
    this.dokumanTuru = '',
    this.aciklama = '',
    this.baskiTuru = 'Siyah-Beyaz',
    this.onluArkali = false,
    this.kopyaElden = false,
    this.dosyaAciklama = '',
  });

  DokumantasyonFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    DateTime? teslimTarihi,
    int? baskiAdedi,
    String? kagitTalebi,
    String? dokumanTuru,
    String? aciklama,
    String? baskiTuru,
    bool? onluArkali,
    bool? kopyaElden,
    String? dosyaAciklama,
  }) {
    return DokumantasyonFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      teslimTarihi: teslimTarihi ?? this.teslimTarihi,
      baskiAdedi: baskiAdedi ?? this.baskiAdedi,
      kagitTalebi: kagitTalebi ?? this.kagitTalebi,
      dokumanTuru: dokumanTuru ?? this.dokumanTuru,
      aciklama: aciklama ?? this.aciklama,
      baskiTuru: baskiTuru ?? this.baskiTuru,
      onluArkali: onluArkali ?? this.onluArkali,
      kopyaElden: kopyaElden ?? this.kopyaElden,
      dosyaAciklama: dosyaAciklama ?? this.dosyaAciklama,
    );
  }
}

/// Riverpod 3 - Migrated from StateNotifier to Notifier
class DokumantasyonFormNotifier extends Notifier<DokumantasyonFormState> {
  late final CreateDokumantasyonTalepUseCase _useCase;

  @override
  DokumantasyonFormState build() {
    _useCase = ref.watch(createDokumantasyonUseCaseProvider);
    return const DokumantasyonFormState();
  }

  void setTeslimTarihi(DateTime d) => state = state.copyWith(teslimTarihi: d);
  void setBaskiAdedi(int v) => state = state.copyWith(baskiAdedi: v);
  void setKagitTalebi(String v) => state = state.copyWith(kagitTalebi: v);
  void setDokumanTuru(String v) => state = state.copyWith(dokumanTuru: v);
  void setAciklama(String v) => state = state.copyWith(aciklama: v);
  void setBaskiTuru(String v) => state = state.copyWith(baskiTuru: v);
  void setOnluArkali(bool v) => state = state.copyWith(onluArkali: v);
  void setKopyaElden(bool v) => state = state.copyWith(kopyaElden: v);
  void setDosyaAciklama(String v) => state = state.copyWith(dosyaAciklama: v);

  Future<void> submit(List<File> files) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    if (state.teslimTarihi == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Teslim tarihi seçiniz.',
      );
      return;
    }

    final talep = DokumantasyonTalep(
      teslimTarihi: state.teslimTarihi!,
      baskiAdedi: state.baskiAdedi,
      kagitTalebi: state.kagitTalebi,
      dokumanTuru: state.dokumanTuru,
      aciklama: state.aciklama,
      baskiTuru: state.baskiTuru,
      onluArkali: state.onluArkali,
      kopyaElden: state.kopyaElden,
      files: files,
      dosyaAciklama: state.dosyaAciklama,
      sayfaSayisi: 0,
      toplamSayfa: 0,
      ogrenciSayisi: 0,
      okullarSatir: [],
      departman: '',
      paket: 0,
      a4Talebi: state.kagitTalebi == 'A4',
    );

    final result = await _useCase(talep);
    state = result.when(
      success: (_) => state.copyWith(isLoading: false, isSuccess: true),
      failure: (msg) => state.copyWith(isLoading: false, errorMessage: msg),
    );
  }
}
