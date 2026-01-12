import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/arac_istek/models/arac_istek_ekle_req.dart';
import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';

/// Araç talep formu state'i
class AracTalepFormState {
  // Tarih/Saat
  final DateTime? gidilecekTarih;
  final int gidisSaat;
  final int gidisDakika;
  final int donusSaat;
  final int donusDakika;
  final int tahminiMesafe;

  // Araç istek nedeni
  final int? selectedAracIstekNedeniId;
  final String customAracIstekNedeni;
  final List<AracIstekNedeniItem> aracIstekNedenleri;

  // Personel seçimi
  final Set<int> selectedGorevYeriIds;
  final Set<int> selectedGorevIds;
  final Set<int> selectedPersonelIds;
  final List<GorevYeriItem> gorevYerleri;
  final List<GorevItem> gorevler;
  final List<PersonelItem> personeller;
  final bool personelLoading;

  // Öğrenci seçimi
  final Set<String> selectedOgrenciIds;
  final Set<String> selectedOkulKodu;
  final Set<String> selectedSeviye;
  final Set<String> selectedSinif;
  final Set<String> selectedKulup;
  final Set<String> selectedTakim;
  final List<String> okulKoduList;
  final List<String> seviyeList;
  final List<String> sinifList;
  final List<String> initialOkulKoduList;
  final List<String> initialSeviyeList;
  final List<String> initialSinifList;
  final List<String> kulupList;
  final List<String> takimList;
  final List<FilterOgrenciItem> ogrenciList;
  final bool ogrenciLoading;

  // Gidilecek yer
  final List<YerEntry> entries;

  // Diğer
  final String aciklama;
  final bool isMEB;
  final bool isSubmitting;
  final String? errorMessage;

  const AracTalepFormState({
    this.gidilecekTarih,
    this.gidisSaat = 8,
    this.gidisDakika = 0,
    this.donusSaat = 9,
    this.donusDakika = 0,
    this.tahminiMesafe = 1,
    this.selectedAracIstekNedeniId,
    this.customAracIstekNedeni = '',
    this.aracIstekNedenleri = const [],
    this.selectedGorevYeriIds = const {},
    this.selectedGorevIds = const {},
    this.selectedPersonelIds = const {},
    this.gorevYerleri = const [],
    this.gorevler = const [],
    this.personeller = const [],
    this.personelLoading = false,
    this.selectedOgrenciIds = const {},
    this.selectedOkulKodu = const {},
    this.selectedSeviye = const {},
    this.selectedSinif = const {},
    this.selectedKulup = const {},
    this.selectedTakim = const {},
    this.okulKoduList = const [],
    this.seviyeList = const [],
    this.sinifList = const [],
    this.initialOkulKoduList = const [],
    this.initialSeviyeList = const [],
    this.initialSinifList = const [],
    this.kulupList = const [],
    this.takimList = const [],
    this.ogrenciList = const [],
    this.ogrenciLoading = false,
    this.entries = const [],
    this.aciklama = '',
    this.isMEB = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  AracTalepFormState copyWith({
    DateTime? gidilecekTarih,
    int? gidisSaat,
    int? gidisDakika,
    int? donusSaat,
    int? donusDakika,
    int? tahminiMesafe,
    int? selectedAracIstekNedeniId,
    String? customAracIstekNedeni,
    List<AracIstekNedeniItem>? aracIstekNedenleri,
    Set<int>? selectedGorevYeriIds,
    Set<int>? selectedGorevIds,
    Set<int>? selectedPersonelIds,
    List<GorevYeriItem>? gorevYerleri,
    List<GorevItem>? gorevler,
    List<PersonelItem>? personeller,
    bool? personelLoading,
    Set<String>? selectedOgrenciIds,
    Set<String>? selectedOkulKodu,
    Set<String>? selectedSeviye,
    Set<String>? selectedSinif,
    Set<String>? selectedKulup,
    Set<String>? selectedTakim,
    List<String>? okulKoduList,
    List<String>? seviyeList,
    List<String>? sinifList,
    List<String>? initialOkulKoduList,
    List<String>? initialSeviyeList,
    List<String>? initialSinifList,
    List<String>? kulupList,
    List<String>? takimList,
    List<FilterOgrenciItem>? ogrenciList,
    bool? ogrenciLoading,
    List<YerEntry>? entries,
    String? aciklama,
    bool? isMEB,
    bool? isSubmitting,
    String? errorMessage,
    bool clearGidilecekTarih = false,
    bool clearSelectedAracIstekNedeniId = false,
    bool clearErrorMessage = false,
  }) {
    return AracTalepFormState(
      gidilecekTarih: clearGidilecekTarih
          ? null
          : (gidilecekTarih ?? this.gidilecekTarih),
      gidisSaat: gidisSaat ?? this.gidisSaat,
      gidisDakika: gidisDakika ?? this.gidisDakika,
      donusSaat: donusSaat ?? this.donusSaat,
      donusDakika: donusDakika ?? this.donusDakika,
      tahminiMesafe: tahminiMesafe ?? this.tahminiMesafe,
      selectedAracIstekNedeniId: clearSelectedAracIstekNedeniId
          ? null
          : (selectedAracIstekNedeniId ?? this.selectedAracIstekNedeniId),
      customAracIstekNedeni:
          customAracIstekNedeni ?? this.customAracIstekNedeni,
      aracIstekNedenleri: aracIstekNedenleri ?? this.aracIstekNedenleri,
      selectedGorevYeriIds: selectedGorevYeriIds ?? this.selectedGorevYeriIds,
      selectedGorevIds: selectedGorevIds ?? this.selectedGorevIds,
      selectedPersonelIds: selectedPersonelIds ?? this.selectedPersonelIds,
      gorevYerleri: gorevYerleri ?? this.gorevYerleri,
      gorevler: gorevler ?? this.gorevler,
      personeller: personeller ?? this.personeller,
      personelLoading: personelLoading ?? this.personelLoading,
      selectedOgrenciIds: selectedOgrenciIds ?? this.selectedOgrenciIds,
      selectedOkulKodu: selectedOkulKodu ?? this.selectedOkulKodu,
      selectedSeviye: selectedSeviye ?? this.selectedSeviye,
      selectedSinif: selectedSinif ?? this.selectedSinif,
      selectedKulup: selectedKulup ?? this.selectedKulup,
      selectedTakim: selectedTakim ?? this.selectedTakim,
      okulKoduList: okulKoduList ?? this.okulKoduList,
      seviyeList: seviyeList ?? this.seviyeList,
      sinifList: sinifList ?? this.sinifList,
      initialOkulKoduList: initialOkulKoduList ?? this.initialOkulKoduList,
      initialSeviyeList: initialSeviyeList ?? this.initialSeviyeList,
      initialSinifList: initialSinifList ?? this.initialSinifList,
      kulupList: kulupList ?? this.kulupList,
      takimList: takimList ?? this.takimList,
      ogrenciList: ogrenciList ?? this.ogrenciList,
      ogrenciLoading: ogrenciLoading ?? this.ogrenciLoading,
      entries: entries ?? this.entries,
      aciklama: aciklama ?? this.aciklama,
      isMEB: isMEB ?? this.isMEB,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Gidilecek yer girişi
class YerEntry {
  final GidilecekYerItem yer;
  final TextEditingController adresController;

  YerEntry({required this.yer, TextEditingController? adresController})
    : adresController = adresController ?? TextEditingController();

  void dispose() {
    adresController.dispose();
  }
}

/// Araç talep formu notifier
class AracTalepFormNotifier extends Notifier<AracTalepFormState> {
  static const List<int> allowedMinutes = [
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
  ];

  @override
  AracTalepFormState build() {
    final now = DateTime.now();
    return AracTalepFormState(
      gidilecekTarih: now,
      gidisSaat: 8,
      gidisDakika: 0,
      donusSaat: 9,
      donusDakika: 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TARİH / SAAT
  // ═══════════════════════════════════════════════════════════════════════════

  void setGidilecekTarih(DateTime? date) {
    state = state.copyWith(
      gidilecekTarih: date,
      clearGidilecekTarih: date == null,
    );
  }

  void setGidisSaat(int hour, int minute) {
    state = state.copyWith(gidisSaat: hour, gidisDakika: minute);
    _syncDonusWithGidis();
  }

  void setDonusSaat(int hour, int minute) {
    // Dönüş gidişten önce olamaz
    if (_isBefore(hour, minute, state.gidisSaat, state.gidisDakika)) {
      return;
    }
    state = state.copyWith(donusSaat: hour, donusDakika: minute);
  }

  void _syncDonusWithGidis() {
    int targetHour = state.gidisSaat + 1;
    int targetMinute = state.gidisDakika;

    if (targetHour > 23) {
      targetHour = 23;
      targetMinute = allowedMinutes.last;
    }

    final nextConstraint = _computeDonusMin(state.gidisSaat, state.gidisDakika);
    if (_isBeforeOrEqual(
      targetHour,
      targetMinute,
      state.gidisSaat,
      state.gidisDakika,
    )) {
      targetHour = nextConstraint.$1;
      targetMinute = nextConstraint.$2;
    }

    if (_isBefore(
      state.donusSaat,
      state.donusDakika,
      targetHour,
      targetMinute,
    )) {
      state = state.copyWith(donusSaat: targetHour, donusDakika: targetMinute);
    }
  }

  (int, int) _computeDonusMin(int startHour, int startMinute) {
    int minHour = startHour;
    int minMinute = startMinute + 5;
    if (minMinute >= 60) {
      minMinute -= 60;
      minHour += 1;
    }
    if (minHour > 23) {
      minHour = 23;
      minMinute = allowedMinutes.last;
    }
    return (minHour, minMinute);
  }

  bool _isBefore(int h1, int m1, int h2, int m2) => h1 * 60 + m1 < h2 * 60 + m2;
  bool _isBeforeOrEqual(int h1, int m1, int h2, int m2) =>
      h1 * 60 + m1 <= h2 * 60 + m2;

  // ═══════════════════════════════════════════════════════════════════════════
  // MESAFE
  // ═══════════════════════════════════════════════════════════════════════════

  void setMesafe(int value) {
    final clamped = value.clamp(1, 9999);
    state = state.copyWith(tahminiMesafe: clamped);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ARAÇ İSTEK NEDENİ
  // ═══════════════════════════════════════════════════════════════════════════

  void setAracIstekNedeniId(int? id) {
    state = state.copyWith(
      selectedAracIstekNedeniId: id,
      clearSelectedAracIstekNedeniId: id == null,
    );
  }

  void setCustomAracIstekNedeni(String value) {
    state = state.copyWith(customAracIstekNedeni: value);
  }

  void setAracIstekNedenleri(List<AracIstekNedeniItem> items) {
    state = state.copyWith(aracIstekNedenleri: items);
  }

  String get aracIstekNedeniSummary {
    if (state.selectedAracIstekNedeniId == null) {
      return 'Araç istek nedenini seçiniz';
    }
    if (state.selectedAracIstekNedeniId == -1) {
      return 'DİĞER';
    }
    final selected = state.aracIstekNedenleri.firstWhere(
      (item) => item.id == state.selectedAracIstekNedeniId,
      orElse: () => AracIstekNedeniItem(id: -1, ad: ''),
    );
    return selected.ad.isNotEmpty ? selected.ad : 'Araç istek nedenini seçiniz';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSONEL SEÇİMİ
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> loadPersonelData() async {
    if (state.personelLoading) return;
    state = state.copyWith(personelLoading: true, clearErrorMessage: true);

    final repo = ref.read(aracTalepRepositoryProvider);
    final result = await repo.personelSecimVerisiGetir();

    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          personeller: data.personeller,
          gorevler: data.gorevler,
          gorevYerleri: data.gorevYerleri,
          personelLoading: false,
        );
      case Failure(:final message):
        state = state.copyWith(personelLoading: false, errorMessage: message);
      case Loading():
        break;
    }
  }

  void togglePersonel(int id) {
    final newSet = Set<int>.from(state.selectedPersonelIds);
    if (newSet.contains(id)) {
      newSet.remove(id);
    } else {
      newSet.add(id);
    }
    state = state.copyWith(selectedPersonelIds: newSet);
  }

  void setSelectedPersonelIds(Set<int> ids) {
    state = state.copyWith(selectedPersonelIds: ids);
  }

  void clearPersonelSelection() {
    state = state.copyWith(
      selectedPersonelIds: {},
      selectedGorevYeriIds: {},
      selectedGorevIds: {},
    );
  }

  void setGorevYeriSelection(Set<int> ids) {
    state = state.copyWith(selectedGorevYeriIds: ids);
  }

  void setGorevSelection(Set<int> ids) {
    state = state.copyWith(selectedGorevIds: ids);
  }

  String get personelSummary {
    if (state.selectedPersonelIds.isEmpty) return 'Personel seçiniz';

    final names = state.personeller
        .where((p) => state.selectedPersonelIds.contains(p.personelId))
        .map((p) => '${p.adi} ${p.soyadi}'.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (names.isEmpty) {
      return '${state.selectedPersonelIds.length} personel seçildi';
    }
    if (names.length <= 2) return names.join(', ');
    return '${names.length} personel seçildi';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ÖĞRENCİ SEÇİMİ
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> loadOgrenciData() async {
    if (state.ogrenciLoading) return;
    state = state.copyWith(ogrenciLoading: true, clearErrorMessage: true);

    final repo = ref.read(aracTalepRepositoryProvider);
    final result = await repo.ogrenciFiltrele();

    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          initialOkulKoduList: data.okulKodu,
          initialSeviyeList: data.seviye,
          initialSinifList: data.sinif,
          okulKoduList: data.okulKodu,
          seviyeList: data.seviye,
          sinifList: data.sinif,
          kulupList: data.kulup,
          takimList: data.takim,
          ogrenciList: data.ogrenci,
          ogrenciLoading: false,
        );
      case Failure(:final message):
        state = state.copyWith(ogrenciLoading: false, errorMessage: message);
      case Loading():
        break;
    }
  }

  Future<void> refreshOgrenciFilters({
    required Set<String> okulKodu,
    required Set<String> seviye,
    required Set<String> sinif,
    required Set<String> kulup,
    required Set<String> takim,
    bool autoSelectAll = false,
  }) async {
    final repo = ref.read(aracTalepRepositoryProvider);
    final result = await repo.mobilOgrenciFiltrele(
      okulKodlari: okulKodu,
      seviyeler: seviye,
      siniflar: sinif,
      kulupler: kulup,
      takimlar: takim,
    );

    switch (result) {
      case Success(:final data):
        final validOgrenciNums = data.ogrenci.map((o) => '${o.numara}').toSet();
        final newSelectedOgrenci = autoSelectAll
            ? validOgrenciNums
            : state.selectedOgrenciIds.intersection(validOgrenciNums);

        state = state.copyWith(
          seviyeList: data.seviye,
          sinifList: data.sinif,
          kulupList: data.kulup,
          takimList: data.takim,
          ogrenciList: data.ogrenci,
          selectedOgrenciIds: newSelectedOgrenci,
          selectedSeviye: seviye.intersection(data.seviye.toSet()),
          selectedSinif: sinif.intersection(data.sinif.toSet()),
          selectedKulup: kulup.intersection(data.kulup.toSet()),
          selectedTakim: takim.intersection(data.takim.toSet()),
        );
      case Failure(:final message):
        state = state.copyWith(errorMessage: message);
      case Loading():
        break;
    }
  }

  void toggleOgrenci(String numara) {
    final newSet = Set<String>.from(state.selectedOgrenciIds);
    if (newSet.contains(numara)) {
      newSet.remove(numara);
    } else {
      newSet.add(numara);
    }
    state = state.copyWith(selectedOgrenciIds: newSet);
  }

  void setSelectedOgrenciIds(Set<String> ids) {
    state = state.copyWith(selectedOgrenciIds: ids);
  }

  void setOgrenciFilters({
    Set<String>? okulKodu,
    Set<String>? seviye,
    Set<String>? sinif,
    Set<String>? kulup,
    Set<String>? takim,
  }) {
    state = state.copyWith(
      selectedOkulKodu: okulKodu ?? state.selectedOkulKodu,
      selectedSeviye: seviye ?? state.selectedSeviye,
      selectedSinif: sinif ?? state.selectedSinif,
      selectedKulup: kulup ?? state.selectedKulup,
      selectedTakim: takim ?? state.selectedTakim,
    );
  }

  String get ogrenciSummary {
    if (state.selectedOgrenciIds.isEmpty) return 'Öğrenci seçiniz';
    if (state.selectedOgrenciIds.length > 2) {
      return '${state.selectedOgrenciIds.length} öğrenci seçildi';
    }

    final Map<String, String> numaraToName = {};
    for (final o in state.ogrenciList) {
      final numara = '${o.numara}';
      if (!state.selectedOgrenciIds.contains(numara)) continue;
      numaraToName.putIfAbsent(numara, () => '${o.adi} ${o.soyadi}'.trim());
    }

    final names = numaraToName.values.where((n) => n.isNotEmpty).toList();
    if (names.length == state.selectedOgrenciIds.length && names.length <= 2) {
      return names.join(', ');
    }
    return '${state.selectedOgrenciIds.length} öğrenci seçildi';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GİDİLECEK YER
  // ═══════════════════════════════════════════════════════════════════════════

  void addYerEntry(GidilecekYerItem yer) {
    final newEntry = YerEntry(yer: yer);
    state = state.copyWith(entries: [...state.entries, newEntry]);
  }

  void removeYerEntry(int index) {
    if (index < 0 || index >= state.entries.length) return;
    final entry = state.entries[index];
    entry.dispose();
    final newEntries = List<YerEntry>.from(state.entries)..removeAt(index);
    state = state.copyWith(entries: newEntries);
  }

  String get gidilecekYerSummary {
    if (state.entries.isEmpty) return '-';

    final lines = <String>[];
    for (final e in state.entries) {
      final yer = e.yer.yerAdi.trim();
      final semt = e.yer.yerAdi.contains('Eyüboğlu')
          ? ''
          : e.adresController.text.trim();
      if (semt.isEmpty) {
        lines.add('• $yer');
      } else {
        lines.add('• $yer ($semt)');
      }
    }
    return lines.join('\n');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DİĞER
  // ═══════════════════════════════════════════════════════════════════════════

  void setAciklama(String value) {
    state = state.copyWith(aciklama: value);
  }

  void setIsMEB(bool value) {
    state = state.copyWith(isMEB: value);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM VALİDASYON
  // ═══════════════════════════════════════════════════════════════════════════

  String? validateForm() {
    if (state.entries.isEmpty) {
      return 'Lütfen en az bir gidilecek yer ekleyiniz.';
    }
    if (state.gidilecekTarih == null) {
      return 'Lütfen gidilecek tarih seçiniz.';
    }
    if (state.selectedAracIstekNedeniId == null) {
      return 'Lütfen araç istek nedenini seçiniz.';
    }
    if (state.selectedAracIstekNedeniId == -1 &&
        state.customAracIstekNedeni.trim().isEmpty) {
      return 'Lütfen diğer nedenini yazınız.';
    }
    if (state.aciklama.length < 30) {
      return 'Açıklama en az 30 karakter olmalıdır.';
    }
    final yolcuSayisi =
        state.selectedPersonelIds.length + state.selectedOgrenciIds.length;
    if (yolcuSayisi <= 0) {
      return 'Lütfen en az bir yolcu (personel veya öğrenci) seçiniz.';
    }
    for (final entry in state.entries) {
      if (!entry.yer.yerAdi.contains('Eyüboğlu') &&
          entry.adresController.text.trim().isEmpty) {
        return 'Lütfen "${entry.yer.yerAdi}" için semt/adres giriniz.';
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REQUEST BUILDER
  // ═══════════════════════════════════════════════════════════════════════════

  AracIstekEkleReq buildRequest(int currentPersonelId) {
    final gidilecekTarih = state.gidilecekTarih ?? DateTime.now();

    final gorevIdToName = {for (final g in state.gorevler) g.id: g.gorevAdi};
    final gorevYeriIdToName = {
      for (final gy in state.gorevYerleri) gy.id: gy.gorevYeriAdi,
    };

    final selectedPersonel = state.personeller
        .where((p) => state.selectedPersonelIds.contains(p.personelId))
        .toList();

    final yolcuPersonelSatir = selectedPersonel
        .map(
          (p) => AracIstekYolcuPersonelSatir(
            personelId: p.personelId,
            perAdi: '${p.adi} ${p.soyadi}'.trim(),
            gorevi: gorevIdToName[p.gorevId] ?? '',
            gorevYeri: gorevYeriIdToName[p.gorevYeriId] ?? '',
          ),
        )
        .toList();

    final yolcuDepartmanId = selectedPersonel
        .map((p) => p.gorevYeriId)
        .whereType<int>()
        .where((id) => id > 0)
        .toSet()
        .toList();

    // Öğrenci tekilleştir
    final Map<int, FilterOgrenciItem> numaraToOgr = {};
    for (final o in state.ogrenciList) {
      numaraToOgr.putIfAbsent(o.numara, () => o);
    }

    final okullarSatir = <AracIstekOkulSatir>[];
    for (final numaraStr in state.selectedOgrenciIds) {
      final numara = int.tryParse(numaraStr);
      if (numara == null) continue;
      final o = numaraToOgr[numara];
      if (o == null) continue;
      final seviye = _deriveSeviyeFromSinif(o.sinif);
      okullarSatir.add(
        AracIstekOkulSatir(
          okulKodu: o.okulKodu,
          seviye: seviye,
          sinif: o.sinif,
          numara: o.numara,
          adi: o.adi,
          soyadi: o.soyadi,
        ),
      );
    }

    final gidilecekYerSatir = state.entries
        .map(
          (e) => AracIstekGidilecekYerSatir(
            gidilecekYer: e.yer.yerAdi,
            semt: e.adresController.text.trim(),
          ),
        )
        .toList();

    final istekNedeni = _resolveIstekNedeni();
    final istekNedeniDiger = state.selectedAracIstekNedeniId == -1
        ? state.customAracIstekNedeni.trim()
        : '';

    return AracIstekEkleReq(
      personelId: currentPersonelId,
      gidilecekTarih: gidilecekTarih,
      gidisSaat: state.gidisSaat.toString().padLeft(2, '0'),
      gidisDakika: state.gidisDakika.toString().padLeft(2, '0'),
      donusSaat: state.donusSaat.toString().padLeft(2, '0'),
      donusDakika: state.donusDakika.toString().padLeft(2, '0'),
      aracTuru: 'Binek',
      yolcuPersonelSatir: yolcuPersonelSatir,
      yolcuDepartmanId: yolcuDepartmanId,
      okullarSatir: okullarSatir,
      gidilecekYerSatir: gidilecekYerSatir,
      yolcuSayisi:
          state.selectedPersonelIds.length + state.selectedOgrenciIds.length,
      mesafe: state.tahminiMesafe,
      istekNedeni: istekNedeni,
      istekNedeniDiger: istekNedeniDiger,
      aciklama: state.aciklama,
      tasinacakYuk: '',
      meb: state.isMEB,
    );
  }

  String _resolveIstekNedeni() {
    if (state.selectedAracIstekNedeniId == null) return '';
    if (state.selectedAracIstekNedeniId == -1) return 'DİĞER';
    final selected = state.aracIstekNedenleri.firstWhere(
      (i) => i.id == state.selectedAracIstekNedeniId,
      orElse: () => AracIstekNedeniItem(id: -1, ad: ''),
    );
    return selected.ad;
  }

  String _deriveSeviyeFromSinif(String sinif, {String fallback = '0'}) {
    final normalized = sinif.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) return fallback;
    if (normalized.length == 1) return normalized;
    return normalized.substring(0, 2);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBMIT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> submitForm(int currentPersonelId) async {
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    final request = buildRequest(currentPersonelId);
    final repo = ref.read(aracTalepRepositoryProvider);
    final result = await repo.aracIstekEkle(request);

    switch (result) {
      case Success():
        state = state.copyWith(isSubmitting: false);
      case Failure(:final message):
        state = state.copyWith(isSubmitting: false, errorMessage: message);
        throw Exception(message);
      case Loading():
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ÖZET BİLGİLERİ
  // ═══════════════════════════════════════════════════════════════════════════

  String get personelSummaryForOzet {
    if (state.selectedPersonelIds.isEmpty) return '-';
    if (state.selectedPersonelIds.length > 2) {
      return '${state.selectedPersonelIds.length} personel';
    }
    final names = state.personeller
        .where((p) => state.selectedPersonelIds.contains(p.personelId))
        .map((p) => '${p.adi} ${p.soyadi}'.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return '${state.selectedPersonelIds.length} personel';
    return names.join(', ');
  }

  String get ogrenciSummaryForOzet {
    if (state.selectedOgrenciIds.isEmpty) return '-';
    if (state.selectedOgrenciIds.length > 2) {
      return '${state.selectedOgrenciIds.length} öğrenci';
    }
    final Map<String, String> numaraToName = {};
    for (final o in state.ogrenciList) {
      final numara = '${o.numara}';
      if (!state.selectedOgrenciIds.contains(numara)) continue;
      numaraToName.putIfAbsent(numara, () => '${o.adi} ${o.soyadi}'.trim());
    }
    final names = numaraToName.values.toList();
    if (names.length == state.selectedOgrenciIds.length && names.isNotEmpty) {
      return names.join(', ');
    }
    return '${state.selectedOgrenciIds.length} öğrenci';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  void dispose() {
    for (final entry in state.entries) {
      entry.dispose();
    }
  }
}

/// Provider
final aracTalepFormNotifierProvider =
    NotifierProvider<AracTalepFormNotifier, AracTalepFormState>(
      AracTalepFormNotifier.new,
    );
