import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_ekle_req.dart';
import 'package:esas_v1/features/izin_istek/models/izin_nedeni.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_ekle_personel_secim_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turu_secim_screen.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';

class IzinEkleFormState {
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final String aciklama;
  final int? secilenSebebiId;
  final Personel? secilenPersonel;
  final IzinNedeni? secilenNedeni;
  final bool isBaskasiAdinaBakinlari;

  // Do?um izni
  final DateTime? tahminiBirthDate;

  // Evlilik izni
  final DateTime? evlilikTarihi;
  final String esAdi;

  // Hastal?k
  final bool doktorRaporuVar;
  final String? hastalikDurumu; // 'acil' veya null
  final String hastalikiYaziniz;
  final String? hastalikBaslangicSaati; // 08-18
  final String? hastalikBaslangicDakikasi; // 00 veya 30
  final String? hastalikBitisSaati; // 08-18
  final String? hastalikBitisDakikasi; // 00 veya 30

  // Kurum g?revlendirmesi
  final String? baslangicSaati;
  final String? bitisSaati;
  final bool gunlukIzinToggle;
  final String gunlukIzinBitisSaati;

  // Dini g�n
  final String diniGunAciklama;
  final DateTime? diniGunBaslangic;
  final DateTime? diniGunBitis;
  final int girilmeyenDersSaati;
  final bool diniGunOnay;

  // Mazeret izni
  final String izindeBulunacagiAdres;

  IzinEkleFormState({
    required this.baslangicTarihi,
    required this.bitisTarihi,
    this.aciklama = '',
    this.secilenSebebiId,
    this.secilenPersonel,
    this.secilenNedeni,
    this.isBaskasiAdinaBakinlari = false,
    this.tahminiBirthDate,
    this.evlilikTarihi,
    this.esAdi = '',
    this.doktorRaporuVar = false,
    this.hastalikDurumu,
    this.hastalikiYaziniz = '',
    this.hastalikBaslangicSaati,
    this.hastalikBaslangicDakikasi,
    this.hastalikBitisSaati,
    this.hastalikBitisDakikasi,
    this.baslangicSaati,
    this.bitisSaati,
    this.gunlukIzinToggle = false,
    this.gunlukIzinBitisSaati = '17:30',
    this.diniGunAciklama = '',
    this.diniGunBaslangic,
    this.diniGunBitis,
    this.girilmeyenDersSaati = 0,
    this.diniGunOnay = false,
    this.izindeBulunacagiAdres = '',
  });

  IzinEkleFormState copyWith({
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    String? aciklama,
    int? secilenSebebiId,
    Personel? secilenPersonel,
    IzinNedeni? secilenNedeni,
    bool? isBaskasiAdinaBakinlari,
    DateTime? tahminiBirthDate,
    DateTime? evlilikTarihi,
    String? esAdi,
    bool? doktorRaporuVar,
    String? hastalikDurumu,
    String? hastalikiYaziniz,
    String? hastalikBaslangicSaati,
    String? hastalikBaslangicDakikasi,
    String? hastalikBitisSaati,
    String? hastalikBitisDakikasi,
    String? baslangicSaati,
    String? bitisSaati,
    bool? gunlukIzinToggle,
    String? gunlukIzinBitisSaati,
    String? diniGunAciklama,
    DateTime? diniGunBaslangic,
    DateTime? diniGunBitis,
    int? girilmeyenDersSaati,
    bool? diniGunOnay,
    String? izindeBulunacagiAdres,
  }) {
    return IzinEkleFormState(
      baslangicTarihi: baslangicTarihi ?? this.baslangicTarihi,
      bitisTarihi: bitisTarihi ?? this.bitisTarihi,
      aciklama: aciklama ?? this.aciklama,
      secilenSebebiId: secilenSebebiId ?? this.secilenSebebiId,
      secilenPersonel: secilenPersonel ?? this.secilenPersonel,
      secilenNedeni: secilenNedeni ?? this.secilenNedeni,
      isBaskasiAdinaBakinlari:
          isBaskasiAdinaBakinlari ?? this.isBaskasiAdinaBakinlari,
      tahminiBirthDate: tahminiBirthDate ?? this.tahminiBirthDate,
      evlilikTarihi: evlilikTarihi ?? this.evlilikTarihi,
      esAdi: esAdi ?? this.esAdi,
      doktorRaporuVar: doktorRaporuVar ?? this.doktorRaporuVar,
      hastalikDurumu: hastalikDurumu ?? this.hastalikDurumu,
      hastalikiYaziniz: hastalikiYaziniz ?? this.hastalikiYaziniz,
      hastalikBaslangicSaati:
          hastalikBaslangicSaati ?? this.hastalikBaslangicSaati,
      hastalikBaslangicDakikasi:
          hastalikBaslangicDakikasi ?? this.hastalikBaslangicDakikasi,
      hastalikBitisSaati: hastalikBitisSaati ?? this.hastalikBitisSaati,
      hastalikBitisDakikasi:
          hastalikBitisDakikasi ?? this.hastalikBitisDakikasi,
      baslangicSaati: baslangicSaati ?? this.baslangicSaati,
      bitisSaati: bitisSaati ?? this.bitisSaati,
      gunlukIzinToggle: gunlukIzinToggle ?? this.gunlukIzinToggle,
      gunlukIzinBitisSaati: gunlukIzinBitisSaati ?? this.gunlukIzinBitisSaati,
      diniGunAciklama: diniGunAciklama ?? this.diniGunAciklama,
      diniGunBaslangic: diniGunBaslangic ?? this.diniGunBaslangic,
      diniGunBitis: diniGunBitis ?? this.diniGunBitis,
      girilmeyenDersSaati: girilmeyenDersSaati ?? this.girilmeyenDersSaati,
      diniGunOnay: diniGunOnay ?? this.diniGunOnay,
      izindeBulunacagiAdres:
          izindeBulunacagiAdres ?? this.izindeBulunacagiAdres,
    );
  }
}

class IzinEkleFormNotifier extends Notifier<IzinEkleFormState> {
  @override
  IzinEkleFormState build() {
    final now = DateTime.now();
    return IzinEkleFormState(baslangicTarihi: now, bitisTarihi: now);
  }

  void setBaslangicTarihi(DateTime tarih) {
    state = state.copyWith(baslangicTarihi: tarih);
  }

  void setBitisTarihi(DateTime tarih) {
    state = state.copyWith(bitisTarihi: tarih);
  }

  void setAciklama(String aciklama) {
    state = state.copyWith(aciklama: aciklama);
  }

  void setSecilenSebebiId(int? id) {
    state = state.copyWith(secilenSebebiId: id);
  }

  void setSecilenPersonel(Personel? personel) {
    state = state.copyWith(secilenPersonel: personel);
  }

  void setSecilenNedeni(IzinNedeni? neden) {
    state = state.copyWith(
      secilenNedeni: neden,
      secilenSebebiId: neden?.izinSebebiId,
    );
  }

  void toggleBaskasiAdinaBakinlari() {
    state = state.copyWith(
      isBaskasiAdinaBakinlari: !state.isBaskasiAdinaBakinlari,
      secilenPersonel: !state.isBaskasiAdinaBakinlari
          ? null
          : state.secilenPersonel,
    );
  }

  // Do?um izni
  void setTahminiBirthDate(DateTime? date) {
    state = state.copyWith(tahminiBirthDate: date);
  }

  // Evlilik izni
  void setEvlilikTarihi(DateTime? date) {
    state = state.copyWith(evlilikTarihi: date);
  }

  void setEsAdi(String ad) {
    state = state.copyWith(esAdi: ad);
  }

  // Hastal?k
  void toggleDoktorRaporuVar() {
    state = state.copyWith(doktorRaporuVar: !state.doktorRaporuVar);
  }

  void setHastalikDurumu(String? durumu) {
    state = state.copyWith(hastalikDurumu: durumu);
  }

  void setHastalikiYaziniz(String text) {
    state = state.copyWith(hastalikiYaziniz: text);
  }

  void setHastalikBaslangicSaati(String saat) {
    state = state.copyWith(hastalikBaslangicSaati: saat);
  }

  void setHastalikBaslangicDakikasi(String dakika) {
    state = state.copyWith(hastalikBaslangicDakikasi: dakika);
  }

  void setHastalikBitisSaati(String saat) {
    state = state.copyWith(hastalikBitisSaati: saat);
  }

  void setHastalikBitisDakikasi(String dakika) {
    state = state.copyWith(hastalikBitisDakikasi: dakika);
  }

  // Kurum g?revlendirmesi
  void setBaslangicSaati(String saat) {
    // Toggle aktifse bitisSaati'ni 17:30 yap
    if (state.gunlukIzinToggle) {
      state = state.copyWith(baslangicSaati: saat, bitisSaati: '17:30');
    } else {
      state = state.copyWith(baslangicSaati: saat);
    }
  }

  void setBitisSaati(String saat) {
    // Toggle acik/kapali fark etmeksizin bitis saatini guncelle
    state = state.copyWith(bitisSaati: saat);
  }

  void toggleGunlukIzin() {
    final yeniToggle = !state.gunlukIzinToggle;
    final bitisSaat = yeniToggle ? '17:30' : state.bitisSaati;
    state = state.copyWith(gunlukIzinToggle: yeniToggle, bitisSaati: bitisSaat);
  }

  // Dini g?n
  void setDiniGunAciklama(String text) {
    state = state.copyWith(diniGunAciklama: text);
  }

  void setDiniGunBaslangic(DateTime tarih) {
    state = state.copyWith(diniGunBaslangic: tarih);
  }

  void setDiniGunBitis(DateTime tarih) {
    state = state.copyWith(diniGunBitis: tarih);
  }

  void setGirilmeyenDersSaati(int saat) {
    state = state.copyWith(girilmeyenDersSaati: saat);
  }

  void toggleDiniGunOnay() {
    state = state.copyWith(diniGunOnay: !state.diniGunOnay);
  }

  // Mazeret izni
  void setIzindeBulunacagiAdres(String adres) {
    state = state.copyWith(izindeBulunacagiAdres: adres);
  }
}

final izinEkleFormProvider =
    NotifierProvider<IzinEkleFormNotifier, IzinEkleFormState>(
      IzinEkleFormNotifier.new,
    );

class IzinEkleScreen extends ConsumerStatefulWidget {
  const IzinEkleScreen({super.key});

  @override
  ConsumerState<IzinEkleScreen> createState() => _IzinEkleScreenState();
}

class _IzinEkleScreenState extends ConsumerState<IzinEkleScreen> {
  // FocusNode'lar
  final FocusNode _aciklamaFocusNode = FocusNode();
  final FocusNode _adresFocusNode = FocusNode();
  final FocusNode _esAdiFocusNode = FocusNode();
  final FocusNode _hastalikYazinizFocusNode = FocusNode();
  final FocusNode _diniGunAciklamaFocusNode = FocusNode();
  bool _isActionInProgress = false;

  @override
  void dispose() {
    _aciklamaFocusNode.dispose();
    _adresFocusNode.dispose();
    _esAdiFocusNode.dispose();
    _hastalikYazinizFocusNode.dispose();
    _diniGunAciklamaFocusNode.dispose();
    // Form state'i temizle ekran kapanırken
    ref.invalidate(izinEkleFormProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(izinEkleFormProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text(
            '�zin istek',
            style: TextStyle(color: AppColors.textOnPrimary),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            onPressed: () => Navigator.pop(context),
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // Klavyeyi kapat
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ba�kas� ad�na istekte bulunuyorum',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                        value: formState.isBaskasiAdinaBakinlari,
                        inactiveTrackColor: AppColors.textOnPrimary,
                        onChanged: (_) {
                          ref
                              .read(izinEkleFormProvider.notifier)
                              .toggleBaskasiAdinaBakinlari();
                        },
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (formState.isBaskasiAdinaBakinlari)
                  _personelSecimCard(context, ref, formState),
                if (formState.isBaskasiAdinaBakinlari)
                  const SizedBox(height: 12),
                _izinTuruCard(context, ref, formState),
                const SizedBox(height: 12),
                _buildDynamicFields(
                  context,
                  ref,
                  formState,
                  _aciklamaFocusNode,
                  _adresFocusNode,
                  _esAdiFocusNode,
                  _hastalikYazinizFocusNode,
                  _diniGunAciklamaFocusNode,
                ),
                const SizedBox(height: 12),
                _tarihlerCard(context, ref, formState),
                const SizedBox(height: 24),
                _gonderButonu(
                  context,
                  ref,
                  formState,
                  _aciklamaFocusNode,
                  _adresFocusNode,
                  _esAdiFocusNode,
                  _hastalikYazinizFocusNode,
                  _diniGunAciklamaFocusNode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _personelSecimCard(
    BuildContext context,
    WidgetRef ref,
    IzinEkleFormState formState,
  ) {
    return _buildCard(
      child: GestureDetector(
        onTap: () async {
          if (_isActionInProgress) return;
          setState(() => _isActionInProgress = true);
          try {
            final selectedPersonel = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IzinEklePersonelSecimScreen(),
              ),
            );
            if (selectedPersonel != null) {
              ref
                  .read(izinEkleFormProvider.notifier)
                  .setSecilenPersonel(selectedPersonel);
            }
          } finally {
            if (mounted) setState(() => _isActionInProgress = false);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  formState.secilenPersonel != null
                      ? '${formState.secilenPersonel!.ad} ${formState.secilenPersonel!.soyad}'
                      : 'Personel Se?in',
                  style: TextStyle(
                    fontSize: 15,
                    color: formState.secilenPersonel != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontWeight: formState.secilenPersonel != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _izinTuruCard(
    BuildContext context,
    WidgetRef ref,
    IzinEkleFormState formState,
  ) {
    return _buildCard(
      child: GestureDetector(
        onTap: () async {
          if (_isActionInProgress) return;
          setState(() => _isActionInProgress = true);
          try {
            final selectedNeden = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IzinTuruSecimScreen(),
              ),
            );
            if (selectedNeden != null) {
              ref
                  .read(izinEkleFormProvider.notifier)
                  .setSecilenNedeni(selectedNeden);
            }
          } finally {
            if (mounted) setState(() => _isActionInProgress = false);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  formState.secilenNedeni != null
                      ? formState.secilenNedeni!.izinNedeni
                      : '?zin T?r?',
                  style: TextStyle(
                    fontSize: 15,
                    color: formState.secilenNedeni != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontWeight: formState.secilenNedeni != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDynamicFields(
    BuildContext context,
    WidgetRef ref,
    IzinEkleFormState formState,
    FocusNode aciklamaFocusNode,
    FocusNode adresFocusNode,
    FocusNode esAdiFocusNode,
    FocusNode hastalikYazinizFocusNode,
    FocusNode diniGunAciklamaFocusNode,
  ) {
    final nedeniAdi = formState.secilenNedeni?.izinNedeni.toLowerCase() ?? '';

    // 1: Do?um izni (Do?um se?ilirse)
    if (nedeniAdi.contains('do?um')) {
      return Column(
        children: [
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A??klama',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    focusNode: aciklamaFocusNode,
                    onChanged: (value) => ref
                        .read(izinEkleFormProvider.notifier)
                        .setAciklama(value),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'A??klama',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tahmini Do?um Tarihi',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  formState.tahminiBirthDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              ref
                                  .read(izinEkleFormProvider.notifier)
                                  .setTahminiBirthDate(picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 19.5,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formState.tahminiBirthDate != null
                                      ? DateFormat(
                                          'gg.aa.yyyy',
                                        ).format(formState.tahminiBirthDate!)
                                      : 'Tarih se?iniz',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: formState.tahminiBirthDate != null
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // 2: Evlilik izni (Evlilik se?ilirse)
    if (nedeniAdi.contains('evlilik') || nedeniAdi.contains('evlen')) {
      final dateTitleStyle =
          Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) ??
          const TextStyle(fontSize: 19, fontWeight: FontWeight.w700);

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Evlilik Tarihi', style: dateTitleStyle),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  formState.evlilikTarihi ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              ref
                                  .read(izinEkleFormProvider.notifier)
                                  .setEvlilikTarihi(picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 15.5,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    formState.evlilikTarihi != null
                                        ? DateFormat(
                                            'gg.aa.yyyy',
                                          ).format(formState.evlilikTarihi!)
                                        : 'gg.aa.yyyy',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: formState.evlilikTarihi != null
                                          ? AppColors.textPrimary
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: Container()),
            ],
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                focusNode: esAdiFocusNode,
                onChanged: (value) =>
                    ref.read(izinEkleFormProvider.notifier).setEsAdi(value),
                decoration: InputDecoration(
                  labelText: 'E� Ad�',
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  hintText: 'E� ad�n� giriniz',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A??klama',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    focusNode: aciklamaFocusNode,
                    onChanged: (value) => ref
                        .read(izinEkleFormProvider.notifier)
                        .setAciklama(value),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'A??klama',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 3: Hastal?k (Hastal?k se?ilirse)
    if (nedeniAdi.contains('hastal?k') || nedeniAdi.contains('hasta')) {
      return Column(
        children: [
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Doktor Raporu Var',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: formState.doktorRaporuVar,
                    inactiveTrackColor: AppColors.textOnPrimary,
                    onChanged: (_) => ref
                        .read(izinEkleFormProvider.notifier)
                        .toggleDoktorRaporuVar(),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Acil',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: formState.hastalikDurumu == 'acil',
                    inactiveTrackColor: AppColors.textOnPrimary,
                    onChanged: (_) {
                      ref
                          .read(izinEkleFormProvider.notifier)
                          .setHastalikDurumu(
                            formState.hastalikDurumu == 'acil' ? null : 'acil',
                          );
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hastal���n�z� Yaz�n�z',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    focusNode: hastalikYazinizFocusNode,
                    onChanged: (value) => ref
                        .read(izinEkleFormProvider.notifier)
                        .setHastalikiYaziniz(value),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Hastal�k a��klamas�',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hastal?k Saati',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Ba?lang??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ba?lang??',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saat',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomTimePickerSpinner(
                                  initialValue:
                                      formState.hastalikBaslangicSaati ?? '08',
                                  items: [
                                    '08',
                                    '09',
                                    '10',
                                    '11',
                                    '12',
                                    '13',
                                    '14',
                                    '15',
                                    '16',
                                    '17',
                                    '18',
                                    '19',
                                  ],
                                  disabledItems: ['12', '13'],
                                  onChanged: (value) {
                                    // 🔴 KRİTİK: Saat değiştiğinde klavyeyi kapat
                                    FocusScope.of(context).unfocus();
                                    ref
                                        .read(izinEkleFormProvider.notifier)
                                        .setHastalikBaslangicSaati(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dakika',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomTimePickerSpinner(
                                  initialValue:
                                      formState.hastalikBaslangicDakikasi ??
                                      '00',
                                  items: ['00', '30'],
                                  onChanged: (value) {
                                    // 🔴 KRİTİK: Dakika değiştiğinde klavyeyi kapat
                                    FocusScope.of(context).unfocus();
                                    ref
                                        .read(izinEkleFormProvider.notifier)
                                        .setHastalikBaslangicDakikasi(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Biti?
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Biti?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saat',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomTimePickerSpinner(
                                  initialValue:
                                      formState.hastalikBitisSaati ?? '08',
                                  items: [
                                    '08',
                                    '09',
                                    '10',
                                    '11',
                                    '12',
                                    '13',
                                    '14',
                                    '15',
                                    '16',
                                    '17',
                                    '18',
                                    '19',
                                  ],
                                  disabledItems: ['12', '13'],
                                  onChanged: (value) {
                                    // 🔴 KRİTİK: Saat değiştiğinde klavyeyi kapat
                                    FocusScope.of(context).unfocus();
                                    ref
                                        .read(izinEkleFormProvider.notifier)
                                        .setHastalikBitisSaati(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dakika',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomTimePickerSpinner(
                                  initialValue:
                                      formState.hastalikBitisDakikasi ?? '00',
                                  items: ['00', '30'],
                                  onChanged: (value) {
                                    // 🔴 KRİTİK: Dakika değiştiğinde klavyeyi kapat
                                    FocusScope.of(context).unfocus();
                                    ref
                                        .read(izinEkleFormProvider.notifier)
                                        .setHastalikBitisDakikasi(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 4: Kurum G?revlendirmesi
    if (nedeniAdi.contains('g?revlendirme') || nedeniAdi.contains('g?rev')) {
      return Column(
        children: [
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ba?lang?? Saati',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: formState.baslangicSaati,
                    items: _saatDropdownItems(),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(izinEkleFormProvider.notifier)
                            .setBaslangicSaati(value);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Saati se?iniz',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '1 g�nl�k izin',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: formState.gunlukIzinToggle,
                    inactiveTrackColor: AppColors.textOnPrimary,
                    onChanged: (_) {
                      ref
                          .read(izinEkleFormProvider.notifier)
                          .toggleGunlukIzin();
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biti� Saati',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: formState.bitisSaati,
                    items: _saatDropdownItems(),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(izinEkleFormProvider.notifier)
                            .setBitisSaati(value);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Saati se�iniz',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A??klama',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    focusNode: aciklamaFocusNode,
                    onChanged: (value) => ref
                        .read(izinEkleFormProvider.notifier)
                        .setAciklama(value),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'A??klama',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 5: Dini g?n
    if (nedeniAdi.contains('dini')) {
      return Column(
        children: [
          // A��klama
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A��klama',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    focusNode: diniGunAciklamaFocusNode,
                    onChanged: (value) => ref
                        .read(izinEkleFormProvider.notifier)
                        .setDiniGunAciklama(value),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'A��klama',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Ba?lang?? ve Biti? Tarihleri (yan yana)
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ba?lang?? Tarihi',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ) ??
                              const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  formState.diniGunBaslangic ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              ref
                                  .read(izinEkleFormProvider.notifier)
                                  .setDiniGunBaslangic(picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              formState.diniGunBaslangic != null
                                  ? DateFormat(
                                      'gg.aa.yyyy',
                                    ).format(formState.diniGunBaslangic!)
                                  : 'Tarih se?iniz',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biti? Tarihi',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ) ??
                              const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  formState.diniGunBitis ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              ref
                                  .read(izinEkleFormProvider.notifier)
                                  .setDiniGunBitis(picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              formState.diniGunBitis != null
                                  ? DateFormat(
                                      'gg.aa.yyyy',
                                    ).format(formState.diniGunBitis!)
                                  : 'Tarih se?iniz',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Girilmeyen Ders Saati
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Girilmeyen Ders Saati',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: formState.girilmeyenDersSaati > 0
                              ? () => ref
                                    .read(izinEkleFormProvider.notifier)
                                    .setGirilmeyenDersSaati(
                                      formState.girilmeyenDersSaati - 1,
                                    )
                              : null,
                          color: AppColors.primary,
                        ),
                        Text(
                          '${formState.girilmeyenDersSaati}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => ref
                              .read(izinEkleFormProvider.notifier)
                              .setGirilmeyenDersSaati(
                                formState.girilmeyenDersSaati + 1,
                              ),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.textTertiary, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '?? Dini g�n izni i�in �zel kurallar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dini g�n izni talep etti�iniz tarihlerde, dersin yap�lmad���n� ve yap�laca�� saatlerin girilemedi�ini belirtmeniz gerekir. Ayn� zamanda bu i�leme ili�kin m�d�rl���m�ze ba�vuru yapman�z zorunludur.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(color: AppColors.textTertiary, height: 1),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Okudum, anlad�m, onayl�yorum.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        value: formState.diniGunOnay,
                        inactiveTrackColor: AppColors.textOnPrimary,
                        onChanged: (_) => ref
                            .read(izinEkleFormProvider.notifier)
                            .toggleDiniGunOnay(),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 6: Mazeret (ve di�er durumlar)
    return Column(
      children: [
        _buildCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A��klama',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  focusNode: aciklamaFocusNode,
                  onChanged: (value) => ref
                      .read(izinEkleFormProvider.notifier)
                      .setAciklama(value),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'A��klama',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppColors.border, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppColors.border, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '�zinde Bulunaca�� Adres',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  focusNode: adresFocusNode,
                  onChanged: (value) => ref
                      .read(izinEkleFormProvider.notifier)
                      .setIzindeBulunacagiAdres(value),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Adres giriniz',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppColors.border, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppColors.border, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static List<DropdownMenuItem<String>> _saatDropdownItems() {
    final saatler = <String>[];
    for (int i = 8; i <= 18; i++) {
      saatler.add(i.toString().padLeft(2, '0'));
    }
    return saatler
        .map((saat) => DropdownMenuItem(value: saat, child: Text(saat)))
        .toList();
  }

  static Widget _tarihlerCard(
    BuildContext context,
    WidgetRef ref,
    IzinEkleFormState formState,
  ) {
    final dateTitleStyle =
        Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) ??
        const TextStyle(fontSize: 19, fontWeight: FontWeight.w700);

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ba?lang?? Tarihi', style: dateTitleStyle),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _secTarih(context, ref, true, formState),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 15.5,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat(
                                    'gg.aa.yyyy',
                                  ).format(formState.baslangicTarihi),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biti? Tarihi', style: dateTitleStyle),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _secTarih(context, ref, false, formState),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 15.5,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat(
                                    'gg.aa.yyyy',
                                  ).format(formState.bitisTarihi),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '?? Ba�lang�� Tarihi se�ildi�inde biti� tarihi otomatik olarak ayn� g�n olarak ayarlan�r. 1 g�nl�k izin i�in tekrar biti� tarihi girmenize gerek yoktur.',
                style: TextStyle(fontSize: 11, color: AppColors.info),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gonderButonu(
    BuildContext context,
    WidgetRef ref,
    IzinEkleFormState formState,
    FocusNode aciklamaFocusNode,
    FocusNode adresFocusNode,
    FocusNode esAdiFocusNode,
    FocusNode hastalikYazinizFocusNode,
    FocusNode diniGunAciklamaFocusNode,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _izinEkle(
          context,
          ref,
          formState,
          aciklamaFocusNode,
          adresFocusNode,
          esAdiFocusNode,
          hastalikYazinizFocusNode,
          diniGunAciklamaFocusNode,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: const Text(
          'Gönder',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static Future<void> _secTarih(
    BuildContext context,
    WidgetRef ref,
    bool isBaslangic,
    IzinEkleFormState formState,
  ) async {
    final initialDate = isBaslangic
        ? formState.baslangicTarihi
        : formState.bitisTarihi;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      if (isBaslangic) {
        ref.read(izinEkleFormProvider.notifier).setBaslangicTarihi(picked);
        // 1 g�nl�k izin i�in biti� tarihini otomatik olarak ba�lang�� tarihi ile ayn� yap
        ref.read(izinEkleFormProvider.notifier).setBitisTarihi(picked);
      } else {
        ref.read(izinEkleFormProvider.notifier).setBitisTarihi(picked);
      }
    }
  }

  Future<void> _izinEkle(
    BuildContext context,
    WidgetRef ref,
    IzinEkleFormState formState,
    FocusNode aciklamaFocusNode,
    FocusNode adresFocusNode,
    FocusNode esAdiFocusNode,
    FocusNode hastalikYazinizFocusNode,
    FocusNode diniGunAciklamaFocusNode,
  ) async {
    final nedeniAdi = formState.secilenNedeni?.izinNedeni.toLowerCase() ?? '';

    if (formState.secilenSebebiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L�tfen izin sebebi se�iniz')),
      );
      return;
    }

    // Dini g�n izni i�in �zel validasyon
    if (nedeniAdi.contains('dini')) {
      if (formState.diniGunAciklama.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L�tfen a��klama giriniz')),
        );
        _requestFocusNextFrame(context, diniGunAciklamaFocusNode);
        return;
      }
    }
    // Hastal�k izni i�in �zel validasyon
    else if (nedeniAdi.contains('hastal�k') || nedeniAdi.contains('hastalik')) {
      if (formState.hastalikiYaziniz.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L�tfen hastal���n�z� yaz�n�z')),
        );
        _requestFocusNextFrame(context, hastalikYazinizFocusNode);
        return;
      }
    }
    // Evlilik izni i�in �zel validasyon
    else if (nedeniAdi.contains('evlilik')) {
      if (formState.esAdi.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L�tfen e� ad�n� giriniz')),
        );
        _requestFocusNextFrame(context, esAdiFocusNode);
        return;
      }
      if (formState.aciklama.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L�tfen a��klama giriniz')),
        );
        _requestFocusNextFrame(context, aciklamaFocusNode);
        return;
      }
    }
    // Mazeret ve di�er izin t�rleri i�in validasyon
    else {
      if (formState.aciklama.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L�tfen a��klama giriniz')),
        );
        _requestFocusNextFrame(context, aciklamaFocusNode);
        return;
      }
      // Mazeret izni i�in adres kontrol�
      if (formState.izindeBulunacagiAdres.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L�tfen izinde bulunaca��n�z adresi giriniz'),
          ),
        );
        _requestFocusNextFrame(context, adresFocusNode);
        return;
      }
    }

    if (formState.bitisTarihi.isBefore(formState.baslangicTarihi)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biti� tarihi ba�lang�� tarihinden sonra olmal�d�r'),
        ),
      );
      return;
    }

    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      final request = IzinIstekEkleReq(
        izinSebebiId: formState.secilenSebebiId!,
        izinBaslangicTarihi: formState.baslangicTarihi,
        izinBitisTarihi: formState.bitisTarihi,
        aciklama: formState.aciklama.trim(),
        izindeBulunacagiAdres: formState.izindeBulunacagiAdres.trim(),
        baskaPersonelId: formState.secilenPersonel?.personelId,
      );
      ref.read(izinIstekRepositoryProvider).izinIstekEkle(request);

      // Provider'ları yenile
      ref.invalidate(devamEdenIsteklerimProvider);
      ref.invalidate(tamamlananIsteklerimProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İzin isteği başarıyla oluşturuldu'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  static void _requestFocusNextFrame(BuildContext context, FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      node.requestFocus();
    });
  }
}

// Custom Cupertino-style Time Picker Spinner
class CustomTimePickerSpinner extends ConsumerStatefulWidget {
  final String initialValue;
  final List<String> items;
  final Function(String) onChanged;
  final String? label;
  final List<String> disabledItems;

  const CustomTimePickerSpinner({
    super.key,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    this.label,
    this.disabledItems = const [],
  });

  @override
  ConsumerState<CustomTimePickerSpinner> createState() =>
      _CustomTimePickerSpinnerState();
}

class _CustomTimePickerSpinnerState
    extends ConsumerState<CustomTimePickerSpinner> {
  late FixedExtentScrollController _scrollController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.items.indexOf(widget.initialValue);
    if (_selectedIndex < 0) _selectedIndex = 0;
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedIndex,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        // 🔴 KRİTİK: Picker'a tıklandığında klavyeyi kapat
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.textTertiary,
        ),
        child: Stack(
          children: [
            // Center highlight
            Center(
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Cupertino Picker
            CupertinoPicker(
              scrollController: _scrollController,
              itemExtent: 32,
              onSelectedItemChanged: (int index) {
                final selectedValue = widget.items[index];
                // Disabled item se?ilirse, de?i?ikli?i kabul etme
                if (widget.disabledItems.contains(selectedValue)) {
                  return;
                }
                setState(() {
                  _selectedIndex = index;
                });
                widget.onChanged(selectedValue);
              },
              children: widget.items.asMap().entries.map((entry) {
                int index = entry.key;
                String value = entry.value;
                bool isSelected = index == _selectedIndex;
                bool isDisabled = widget.disabledItems.contains(value);

                return Center(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isSelected ? 18 : 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isDisabled
                          ? AppColors.textTertiary
                          : isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
