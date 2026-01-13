import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/arac_istek/domain/entities/arac_talep.dart';
import 'package:esas_v1/features/arac_istek/domain/usecases/create_arac_talep_usecase.dart';
import 'package:esas_v1/features/arac_istek/presentation/providers/arac_talep_providers.dart';

class AracTalepFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  // Form Fields
  final int? personelId;
  final DateTime? gidilecekTarih;
  final String gidisSaat;
  final String gidisDakika;
  final String donusSaat;
  final String donusDakika;
  final String aracTuru;
  final List<YolcuPersonel> yolcuPersonelSatir;
  final List<OkulSatir> okullarSatir;
  final List<GidilecekYerSatir> gidilecekYerSatir;
  final String istekNedeni;
  final String aciklama;
  final bool meb;
  final int yolcuSayisi;

  const AracTalepFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.personelId,
    this.gidilecekTarih,
    this.gidisSaat = '08',
    this.gidisDakika = '00',
    this.donusSaat = '17',
    this.donusDakika = '00',
    this.aracTuru = '',
    this.yolcuPersonelSatir = const [],
    this.okullarSatir = const [],
    this.gidilecekYerSatir = const [],
    this.istekNedeni = '',
    this.aciklama = '',
    this.meb = false,
    this.yolcuSayisi = 0,
  });

  AracTalepFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    int? personelId,
    DateTime? gidilecekTarih,
    String? gidisSaat,
    String? gidisDakika,
    String? donusSaat,
    String? donusDakika,
    String? aracTuru,
    List<YolcuPersonel>? yolcuPersonelSatir,
    List<OkulSatir>? okullarSatir,
    List<GidilecekYerSatir>? gidilecekYerSatir,
    String? istekNedeni,
    String? aciklama,
    bool? meb,
    int? yolcuSayisi,
  }) {
    return AracTalepFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Reset error unless passed
      isSuccess: isSuccess ?? this.isSuccess,
      personelId: personelId ?? this.personelId,
      gidilecekTarih: gidilecekTarih ?? this.gidilecekTarih,
      gidisSaat: gidisSaat ?? this.gidisSaat,
      gidisDakika: gidisDakika ?? this.gidisDakika,
      donusSaat: donusSaat ?? this.donusSaat,
      donusDakika: donusDakika ?? this.donusDakika,
      aracTuru: aracTuru ?? this.aracTuru,
      yolcuPersonelSatir: yolcuPersonelSatir ?? this.yolcuPersonelSatir,
      okullarSatir: okullarSatir ?? this.okullarSatir,
      gidilecekYerSatir: gidilecekYerSatir ?? this.gidilecekYerSatir,
      istekNedeni: istekNedeni ?? this.istekNedeni,
      aciklama: aciklama ?? this.aciklama,
      meb: meb ?? this.meb,
      yolcuSayisi: yolcuSayisi ?? this.yolcuSayisi,
    );
  }
}

/// Riverpod 3 - Migrated from StateNotifier to Notifier
class AracTalepFormNotifier extends Notifier<AracTalepFormState> {
  late final CreateAracTalepUseCase _createAracTalepUseCase;

  @override
  AracTalepFormState build() {
    _createAracTalepUseCase = ref.watch(createAracTalepUseCaseProvider);
    return const AracTalepFormState();
  }

  void setGidilecekTarih(DateTime date) {
    state = state.copyWith(gidilecekTarih: date);
  }

  void setGidisSaat(String saat, String dakika) {
    state = state.copyWith(gidisSaat: saat, gidisDakika: dakika);
  }

  void setDonusSaat(String saat, String dakika) {
    state = state.copyWith(donusSaat: saat, donusDakika: dakika);
  }

  void setAracTuru(String value) => state = state.copyWith(aracTuru: value);
  void setIstekNedeni(String value) =>
      state = state.copyWith(istekNedeni: value);
  void setAciklama(String value) => state = state.copyWith(aciklama: value);
  void setMeb(bool value) => state = state.copyWith(meb: value);
  void setYolcuSayisi(int value) => state = state.copyWith(yolcuSayisi: value);

  void addGidilecekYer(GidilecekYerSatir item) {
    state = state.copyWith(
      gidilecekYerSatir: [...state.gidilecekYerSatir, item],
    );
  }

  void removeGidilecekYer(int index) {
    final updated = [...state.gidilecekYerSatir];
    updated.removeAt(index);
    state = state.copyWith(gidilecekYerSatir: updated);
  }

  Future<void> submit() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Basic Validation
    if (state.gidilecekTarih == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lütfen tarih seçiniz.',
      );
      return;
    }
    // Add more validations...

    final talep = AracTalep(
      personelId: state.personelId ?? 0, // Should be fetched from session
      gidilecekTarih: state.gidilecekTarih!,
      gidisSaat: state.gidisSaat,
      gidisDakika: state.gidisDakika,
      donusSaat: state.donusSaat,
      donusDakika: state.donusDakika,
      aracTuru: state.aracTuru,
      yolcuPersonelSatir: state.yolcuPersonelSatir,
      yolcuDepartmanId: [], // Logic to be implemented if needed
      okullarSatir: state.okullarSatir,
      gidilecekYerSatir: state.gidilecekYerSatir,
      yolcuSayisi: state.yolcuSayisi,
      mesafe: 0,
      istekNedeni: state.istekNedeni,
      istekNedeniDiger: '',
      aciklama: state.aciklama,
      tasinacakYuk: '',
      meb: state.meb,
    );

    final result = await _createAracTalepUseCase(talep);

    state = result.when(
      success: (_) => state.copyWith(isLoading: false, isSuccess: true),
      failure: (message) =>
          state.copyWith(isLoading: false, errorMessage: message),
    );
  }
}
