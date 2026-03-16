import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/custom_switch_widget.dart';
import 'package:esas_v1/common/widgets/validation_uyari_widget.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/common/widgets/common_divider.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_ekle_req.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/core/services/email_service.dart';
import 'package:esas_v1/features/izin_istek/widgets/guideline_card_with_toggle.dart';
import 'package:esas_v1/common/widgets/numeric_spinner_widget.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';

class DiniIzinScreen extends ConsumerStatefulWidget {
  const DiniIzinScreen({super.key});

  @override
  ConsumerState<DiniIzinScreen> createState() => _DiniIzinScreenState();
}

class _DiniIzinScreenState extends ConsumerState<DiniIzinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aciklamaController = TextEditingController();
  final _adresController = TextEditingController();
  final _aciklamaFocusNode = FocusNode();
  final _adresFocusNode = FocusNode();
  DateTime? _initialBaslangicTarihi;
  DateTime? _initialBitisTarihi;
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;
  int _girileymeyenDersSaati = 0;
  int _secilenDiniGunIndex = 0;
  String? _secilenDiniGunAdi;
  bool _onay = false;
  bool _isSubmitting = false;
  bool _birGunlukIzin = false;
  Personel? _secilenPersonel;
  bool _basaksiAdinaIstekte = false;

  // Hata durumu state'leri
  bool _adresHatali = false;

  /// Bir sonraki günü döndürür
  DateTime _getNextSelectableDay(DateTime date) {
    return date.add(const Duration(days: 1));
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _initialBaslangicTarihi = today;
    _initialBitisTarihi = _getNextSelectableDay(today);
    _baslangicTarihi = _initialBaslangicTarihi;
    _bitisTarihi = _initialBitisTarihi;
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _adresController.dispose();
    _aciklamaFocusNode.dispose();
    _adresFocusNode.dispose();
    super.dispose();
  }

  bool _hasFormData() {
    if (!_isSameDate(_baslangicTarihi, _initialBaslangicTarihi)) return true;
    if (!_isSameDate(_bitisTarihi, _initialBitisTarihi)) return true;
    if (_birGunlukIzin) return true;
    if (_onay) return true;
    if (_basaksiAdinaIstekte) return true;
    if (_secilenPersonel != null) return true;
    if (_aciklamaController.text.isNotEmpty) return true;
    if (_adresController.text.isNotEmpty) return true;
    if (_girileymeyenDersSaati > 0) return true;
    if (_secilenDiniGunAdi != null) return true;
    return false;
  }

  bool _isSameDate(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Uyarı',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Forma girmiş olduğunuz veriler kaybolacaktır. Önceki ekrana dönmek istediğinizden emin misiniz?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: AppColors.gradientStart,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Vazgeç',
                            style: TextStyle(
                              color: AppColors.gradientStart,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Tamam',
                            style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        if (_hasFormData()) {
          final shouldPop = await _showExitConfirmationDialog();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: DismissKeyboardOnPointerDown(
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            title: const Text(
              'Dini İzin İstek',
              style: TextStyle(color: AppColors.textOnPrimary),
            ),
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başkası adına istekte bulunuyorum
                  PersonelSecimWidget(
                    initialPersonel: _secilenPersonel,
                    initialToggleState: _basaksiAdinaIstekte,
                    onPersonelSelected: (personel) {
                      setState(() {
                        _secilenPersonel = personel;
                      });
                    },
                    onToggleChanged: (value) {
                      setState(() {
                        _basaksiAdinaIstekte = value;
                      });
                    },
                  ),
                  const CommonDivider(),
                  const SizedBox(height: 10),

                  // Açıklama
                  AciklamaFieldWidget(
                    controller: _aciklamaController,
                    focusNode: _aciklamaFocusNode,
                    minCharacters: 30,
                  ),
                  const SizedBox(height: 24),

                  // 1 günlük izin toggle
                  CustomSwitchWidget(
                    value: _birGunlukIzin,
                    label: '1 günlük izin',
                    onChanged: (value) {
                      setState(() {
                        _birGunlukIzin = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Başlangıç ve Bitiş Tarihi
                  Row(
                    children: [
                      Expanded(
                        child: DatePickerBottomSheetWidget(
                          labelStyle: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize:
                                    (Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.fontSize ??
                                        14) +
                                    1,
                                color: AppColors.inputLabelColor,
                              ),
                          initialDate: _baslangicTarihi,
                          label: 'Başlangıç Tarihi',
                          onDateChanged: (date) {
                            setState(() {
                              _baslangicTarihi = date;
                              if (_birGunlukIzin) {
                                _bitisTarihi = date;
                              } else {
                                // Başlangıç > mevcut bitiş ise bitişi bir sonraki güne taşı
                                if (_bitisTarihi == null ||
                                    date.isAfter(_bitisTarihi!)) {
                                  _bitisTarihi = date.add(
                                    const Duration(days: 1),
                                  );
                                }
                                // Başlangıç tarihi bitişten küçükse bitiş sabit kalır
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _birGunlukIzin
                            ? const SizedBox()
                            : DatePickerBottomSheetWidget(
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.fontSize ??
                                              14) +
                                          1,
                                      color: AppColors.inputLabelColor,
                                    ),
                                initialDate: _bitisTarihi,
                                minDate: _baslangicTarihi != null
                                    ? _getNextSelectableDay(_baslangicTarihi!)
                                    : null,
                                label: 'Bitiş Tarihi',
                                onDateChanged: (date) {
                                  setState(() {
                                    _bitisTarihi = date;
                                  });
                                },
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dini Gün Seçimi (BottomSheet)
                  Consumer(
                    builder: (context, ref, child) {
                      final currentPersonelId = ref.watch(
                        currentPersonelIdProvider,
                      );
                      final personelId =
                          _secilenPersonel?.personelId ?? currentPersonelId;
                      final personelBilgiAsync = ref.watch(
                        personelBilgiByIdProvider(personelId),
                      );

                      return personelBilgiAsync.when(
                        data: (personelBilgi) {
                          final stringDini = personelBilgi.dini
                              ?.trim()
                              .toLowerCase();
                          if (stringDini == 'islam' || stringDini == 'i̇slam') {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dini Gün',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.fontSize ??
                                              14) +
                                          1,
                                      color: AppColors.inputLabelColor,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Consumer(
                                builder: (context, ref, child) {
                                  final diniGunlerAsync = ref.watch(
                                    diniGunlerProvider(personelId),
                                  );

                                  return diniGunlerAsync.when(
                                    data: (gunler) {
                                      if (gunler.isEmpty) {
                                        return const Text(
                                          'Dini gün bulunamadı',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        );
                                      }

                                      // Index sınırlarını kontrol et
                                      if (_secilenDiniGunIndex >=
                                          gunler.length) {
                                        _secilenDiniGunIndex = 0;
                                      }

                                      // Seçilen dini gün adını güncelle
                                      final secilenGunAdi =
                                          _secilenDiniGunAdi ??
                                          gunler[_secilenDiniGunIndex].izinGunu;

                                      return GestureDetector(
                                        onTap: () {
                                          _showDiniGunBottomSheet(gunler);
                                        },
                                        child: Container(
                                          height: 46,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: AppColors.textOnPrimary,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  secilenGunAdi,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_drop_down,
                                                color: AppColors.textPrimary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    loading: () => const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ),
                                    error: (error, stack) => Text(
                                      'Hata: $error',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        error: (e, st) => const SizedBox.shrink(),
                      );
                    },
                  ),

                  // Girilmeyen Ders Saati Spinner
                  NumericSpinnerWidget(
                    initialValue: _girileymeyenDersSaati,
                    onValueChanged: (value) {
                      setState(() {
                        _girileymeyenDersSaati = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // İzinde Bulunacağı Adres
                  Text(
                    'İzinde Bulunacağı Adres',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    focusNode: _adresFocusNode,
                    controller: _adresController,
                    decoration: InputDecoration(
                      hintText: 'Lütfen izinde bulunacağınız adresi giriniz.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.borderStandartColor,
                          width: 0.75,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.borderStandartColor,
                          width: 0.75,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.gradientStart,
                          width: 0.75,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.textOnPrimary,
                    ),
                    minLines: 3,
                    maxLines: 5,
                    onChanged: (value) {
                      if (_adresHatali && value.isNotEmpty) {
                        setState(() {
                          _adresHatali = false;
                        });
                      }
                    },
                  ),
                  const CommonDivider(),
                  const SizedBox(height: 24),

                  GuidelineCardWithToggle(
                    pdfTitle: 'İzin Kullanma Yönergesi',
                    pdfUrl:
                        'https://esas.eyuboglu.k12.tr/yonerge/izin_kullanma_esaslari_yonergesi.pdf',
                    cardButtonText: 'İzin Kullanma Yönergesi',
                    toggleText: 'Yönergeyi okudum, anladım, onaylıyorum',
                    toggleValue: _onay,
                    onToggleChanged: (value) {
                      setState(() {
                        _onay = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  GonderButtonWidget(
                    onPressed: _onay ? _submitForm : null,
                    enabled: _onay,
                    isLoading: _isSubmitting,
                    padding: 14.0,
                    borderRadius: 8.0,
                    textStyle: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      if (_formKey.currentState?.validate() ?? false) {
        // Açıklama zorunlu kontrolü (en az 30 karakter)
        if (_aciklamaController.text.length < 30) {
          await ValidationUyariWidget.goster(
            context: context,
            message: 'Lütfen en az 30 karakter olacak şekilde açıklama giriniz',
          );
          _aciklamaFocusNode.requestFocus();
          return;
        }

        // Adres zorunlu kontrolü
        if (_adresController.text.isEmpty) {
          setState(() {
            _adresHatali = true;
          });
          await ValidationUyariWidget.goster(
            context: context,
            message: 'Lütfen izin süresince bulunacağınız adresi giriniz',
          );
          _adresFocusNode.requestFocus();
          return;
        }

        // Form validasyonları
        if (_baslangicTarihi == null) {
          await ValidationUyariWidget.goster(
            context: context,
            message: 'Başlangıç tarihi seçiniz',
          );
          return;
        }

        // 1 günlük izin aktif ise başlangıç tarihi = bitiş tarihi
        DateTime bitisTarih;
        if (_birGunlukIzin) {
          bitisTarih = _baslangicTarihi!;
        } else if (_bitisTarihi == null) {
          await ValidationUyariWidget.goster(
            context: context,
            message: 'Bitiş tarihi seçiniz',
          );
          return;
        } else {
          bitisTarih = _bitisTarihi!;
        }

        // Başlangıç tarihi bitiş tarihinden büyük olamaz
        if (_baslangicTarihi!.isAfter(bitisTarih)) {
          await ValidationUyariWidget.goster(
            context: context,
            message: 'Başlangıç tarihi bitiş tarihinden büyük olamaz',
          );
          return;
        }

        try {
          // Dini İzin ID'si: 6 (sabit)
          const int izinSebebiId = 6;

          // Token'dan aldığımız personel id (dolduranPersonelId)
          final currentPersonelId = ref.read(currentPersonelIdProvider);

          // Başkası adına istekte bulunuluyorsa onun ID'si, değilse dini günleri çekmek için current user
          final personelIdForDiniGun =
              _secilenPersonel?.personelId ?? currentPersonelId;

          final personelBilgi = await ref.read(
            personelBilgiByIdProvider(personelIdForDiniGun).future,
          );
          final stringDini = personelBilgi?.dini?.trim().toLowerCase();
          final bool isIslam = stringDini == 'islam' || stringDini == 'i̇slam';

          final diniGunlerAsync = await ref.read(
            diniGunlerProvider(personelIdForDiniGun).future,
          );

          // Seçilen dini günü al (İslam ise boş gönder)
          final secilenDiniGun = (!isIslam && diniGunlerAsync.isNotEmpty)
              ? diniGunlerAsync[_secilenDiniGunIndex].izinGunu
              : '';

          // baskaPersonelId: toggle aktif ise seçilen personel id, değilse 0
          final int baskaPersonelIdValue = _basaksiAdinaIstekte
              ? (_secilenPersonel?.personelId ?? 0)
              : 0;

          // IzinIstekEkleReq oluştur - API'nin beklediği format
          final request = IzinIstekEkleReq(
            izinSebebiId: izinSebebiId,
            izinBaslangicTarihi: _baslangicTarihi!,
            izinBitisTarihi: bitisTarih,
            aciklama: _aciklamaController.text,
            izindeBulunacagiAdres: _adresController.text,
            izindeGirilmeyenToplamDersSaati: _girileymeyenDersSaati,
            baskaPersonelId: baskaPersonelIdValue,
            dolduranPersonelId: currentPersonelId,
            diniGun: secilenDiniGun,
          );

          // API çağrısını yap
          if (mounted) {
            final ozetItems = [
              IzinOzetItem(
                label: 'İzin Türü',
                value: 'Dini İzin',
                multiLine: false,
              ),
              IzinOzetItem(label: 'Açıklama', value: _aciklamaController.text),
              IzinOzetItem(
                label: 'Başlangıç Tarihi',
                value: _formatDate(_baslangicTarihi!),
                multiLine: false,
              ),
              IzinOzetItem(
                label: 'Bitiş Tarihi',
                value: _formatDate(bitisTarih),
                multiLine: false,
              ),
              if (!isIslam)
                IzinOzetItem(label: 'Dini Gün', value: secilenDiniGun),
              IzinOzetItem(
                label: 'Girilmeyen Toplam Ders Saati',
                value: _girileymeyenDersSaati.toString(),
                multiLine: false,
              ),
              IzinOzetItem(
                label: 'İzinde Bulunacağı Adres',
                value: _adresController.text,
              ),
            ];

            await showIzinOzetBottomSheet(
              context: context,
              request: request,
              izinTipi: 'Dini',
              ozetItems: ozetItems,
              onGonder: () async {
                final repo = ref.read(izinIstekRepositoryProvider);
                final result = await repo.izinIstekEkle(request);
                if (result is Failure<int>) {
                  throw Exception(result.message);
                } else if (result is Success<int>) {
                  if (result.data > 0) {
                    final emailService = ref.read(emailServiceProvider);
                    await emailService.emailIcerikOlustur(
                      id: result.data,
                      kategori: 'İzin İstek',
                      aksiyon: 'Onay Bekliyor',
                    );
                  }
                }
              },
              onSuccess: () async {
                if (!mounted) return;
                await IstekBasariliWidget.goster(
                  context: context,
                  message: 'Dini izin isteğiniz gönderilmiştir.',
                  onConfirm: () async {
                    if (!context.mounted) return;
                    ref.invalidate(devamEdenIsteklerimProvider);
                    ref.invalidate(tamamlananIsteklerimProvider);
                    final navigator = Navigator.of(context);
                    var poppedRouteCount = 0;
                    navigator.popUntil((route) {
                      if (route.isFirst || poppedRouteCount >= 2) {
                        return true;
                      }
                      poppedRouteCount++;
                      return false;
                    });
                  },
                );
              },
              onError: (error) async {
                await ValidationUyariWidget.goster(
                  context: context,
                  message: 'Hata: $error',
                );
              },
            );
          }
        } catch (e) {
          if (mounted) {
            await ValidationUyariWidget.goster(
              context: context,
              message: 'Hata oluştu: $e',
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showDiniGunBottomSheet(List<dynamic> gunler) async {
    // 🔴 KRİTİK: BottomSheet açmadan önce tüm focus'ları kapat
    _aciklamaFocusNode.unfocus();
    _adresFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: AppColors.textOnPrimary,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dini Gün Seçin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Options
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: gunler.length,
                  itemBuilder: (context, index) {
                    final gun = gunler[index];
                    final isSelected = index == _secilenDiniGunIndex;
                    return ListTile(
                      title: Text(
                        gun.izinGunu,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.gradientEnd
                              : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.gradientEnd,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _secilenDiniGunIndex = index;
                          _secilenDiniGunAdi = gun.izinGunu;
                        });
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );

    // 🔒 BottomSheet kapandıktan sonra garanti için tekrar unfocus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
