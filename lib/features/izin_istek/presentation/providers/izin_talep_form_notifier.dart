import 'package:state_notifier/state_notifier.dart';
import 'package:esas_v1/features/izin_istek/domain/entities/izin_talep.dart';
import 'package:esas_v1/features/izin_istek/domain/usecases/create_izin_talep_usecase.dart';

class IzinTalepFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  // Form Fields
  final int izinSebebiId;
  final DateTime? izinBaslangicTarihi;
  final DateTime? izinBitisTarihi;
  final String aciklama;
  final String izindeBulunacagiAdres;

  // Dynamic Fields
  final bool doktorRaporu;
  final String diniGun;
  final DateTime? dogumTarihi;
  final DateTime? evlilikTarihi;
  final String? esAdi;

  const IzinTalepFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.izinSebebiId = 0,
    this.izinBaslangicTarihi,
    this.izinBitisTarihi,
    this.aciklama = '',
    this.izindeBulunacagiAdres = '',
    this.doktorRaporu = false,
    this.diniGun = '',
    this.dogumTarihi,
    this.evlilikTarihi,
    this.esAdi,
  });

  IzinTalepFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    int? izinSebebiId,
    DateTime? izinBaslangicTarihi,
    DateTime? izinBitisTarihi,
    String? aciklama,
    String? izindeBulunacagiAdres,
    bool? doktorRaporu,
    String? diniGun,
    DateTime? dogumTarihi,
    DateTime? evlilikTarihi,
    String? esAdi,
  }) {
    return IzinTalepFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      izinSebebiId: izinSebebiId ?? this.izinSebebiId,
      izinBaslangicTarihi: izinBaslangicTarihi ?? this.izinBaslangicTarihi,
      izinBitisTarihi: izinBitisTarihi ?? this.izinBitisTarihi,
      aciklama: aciklama ?? this.aciklama,
      izindeBulunacagiAdres:
          izindeBulunacagiAdres ?? this.izindeBulunacagiAdres,
      doktorRaporu: doktorRaporu ?? this.doktorRaporu,
      diniGun: diniGun ?? this.diniGun,
      dogumTarihi: dogumTarihi ?? this.dogumTarihi,
      evlilikTarihi: evlilikTarihi ?? this.evlilikTarihi,
      esAdi: esAdi ?? this.esAdi,
    );
  }
}

class IzinTalepFormNotifier extends StateNotifier<IzinTalepFormState> {
  final CreateIzinTalepUseCase _createUseCase;

  IzinTalepFormNotifier(this._createUseCase)
    : super(const IzinTalepFormState());

  void setIzinSebebi(int id) => state = state.copyWith(izinSebebiId: id);
  void setAciklama(String value) => state = state.copyWith(aciklama: value);
  void setIzindeBulunacagiAdres(String value) =>
      state = state.copyWith(izindeBulunacagiAdres: value);
  void setDoktorRaporu(bool value) =>
      state = state.copyWith(doktorRaporu: value);
  void setDiniGun(String value) => state = state.copyWith(diniGun: value);
  void setEsAdi(String value) => state = state.copyWith(esAdi: value);

  void setIzinBaslangicTarihi(DateTime date) {
    state = state.copyWith(izinBaslangicTarihi: date);
    _calculateDuration();
  }

  void setIzinBitisTarihi(DateTime date) {
    state = state.copyWith(izinBitisTarihi: date);
    _calculateDuration();
  }

  void setDogumTarihi(DateTime date) =>
      state = state.copyWith(dogumTarihi: date);
  void setEvlilikTarihi(DateTime date) =>
      state = state.copyWith(evlilikTarihi: date);

  Future<void> _calculateDuration() async {
    if (state.izinBaslangicTarihi == null ||
        state.izinBitisTarihi == null ||
        state.izinSebebiId == 0)
      return;

    // Call repository to calculate duration if needed.
  }

  Future<void> submit() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    if (state.izinSebebiId == 0) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lütfen izin türü seçiniz.',
      );
      return;
    }

    final talep = IzinTalep(
      izinSebebiId: state.izinSebebiId,
      izinBaslangicTarihi: state.izinBaslangicTarihi ?? DateTime.now(),
      izinBitisTarihi: state.izinBitisTarihi ?? DateTime.now(),
      aciklama: state.aciklama,
      izindeBulunacagiAdres: state.izindeBulunacagiAdres,
      doktorRaporu: state.doktorRaporu,
      diniGun: state.diniGun,
      dogumTarihi: state.dogumTarihi,
      evlilikTarihi: state.evlilikTarihi,
      esAdi: state.esAdi,
      // Default values
      izinBaslangicSaat: 8,
      izinBaslangicDakika: 0,
      izinBitisSaat: 17,
      izinBitisDakika: 30,
    );

    final result = await _createUseCase(talep);

    state = result.when(
      success: (_) => state.copyWith(isLoading: false, isSuccess: true),
      failure: (message) =>
          state.copyWith(isLoading: false, errorMessage: message),
    );
  }
}
