import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_ekle_req.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/widgets/guideline_card_with_toggle.dart';
import 'package:esas_v1/common/widgets/numeric_spinner_widget.dart';

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
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;
  int _girileymeyenDersSaati = 0;
  int _secilenDiniGunIndex = 0;
  String? _secilenDiniGunAdi;
  bool _onay = false;
  bool _birGunlukIzin = false;
  Personel? _secilenPersonel;
  bool _basaksiAdinaIstekte = false;

  // Hata durumu state'leri
  bool _adresHatali = false;

  /// Bir sonraki seçilebilir günü döndürür (Pazar değilse)
  DateTime _getNextSelectableDay(DateTime date) {
    var nextDay = date.add(const Duration(days: 1));
    if (nextDay.weekday == DateTime.sunday) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    return nextDay;
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _baslangicTarihi = today;
    _bitisTarihi = _getNextSelectableDay(today);
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
    if (_aciklamaController.text.isNotEmpty) return true;
    if (_adresController.text.isNotEmpty) return true;
    if (_girileymeyenDersSaati > 0) return true;
    if (_secilenDiniGunAdi != null) return true;
    if (_basaksiAdinaIstekte && _secilenPersonel != null) return true;
    return false;
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
            context.pop();
          }
        } else {
          if (context.mounted) {
            context.pop();
          }
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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
                  const SizedBox(height: 10),

                  // Açıklama
                  AciklamaFieldWidget(
                    controller: _aciklamaController,
                    focusNode: _aciklamaFocusNode,
                    minCharacters: 30,
                  ),
                  const SizedBox(height: 24),

                  // 1 günlük izin toggle
                  Row(
                    children: [
                      Switch(
                        value: _birGunlukIzin,
                        onChanged: (value) {
                          setState(() {
                            _birGunlukIzin = value;
                          });
                        },
                        activeTrackColor: AppColors.gradientStart.withValues(
                          alpha: 0.5,
                        ),
                        activeThumbColor: AppColors.gradientEnd,
                        inactiveTrackColor: AppColors.textOnPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            '1 günlük izin',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.inputLabelColor,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                                  var nextDay = date.add(
                                    const Duration(days: 1),
                                  );
                                  if (nextDay.weekday == DateTime.sunday) {
                                    nextDay = nextDay.add(
                                      const Duration(days: 1),
                                    );
                                  }
                                  _bitisTarihi = nextDay;
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dini Gün',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize:
                              (Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.fontSize ??
                                  14) +
                              1,
                          color: AppColors.inputLabelColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          // JWT token'dan decode edilen current user PersonelId
                          final currentPersonelId = ref.watch(
                            currentPersonelIdProvider,
                          );
                          // Başkası adına istekte bulunuluyorsa onun ID'si, değilse current user
                          final personelId =
                              _secilenPersonel?.personelId ?? currentPersonelId;
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
                              if (_secilenDiniGunIndex >= gunler.length) {
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
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
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
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
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
                    ],
                  ),
                  const SizedBox(height: 24),

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
                      color: AppColors.inputLabelColor,
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
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _onay
                          ? AppColors.primaryGradient
                          : LinearGradient(
                              colors: [
                                AppColors.gradientStart.withValues(alpha: 0.2),
                                AppColors.gradientEnd.withValues(alpha: 0.2),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: _onay ? _submitForm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Gönder',
                        style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
    if (_formKey.currentState?.validate() ?? false) {
      // Açıklama zorunlu kontrolü (en az 30 karakter)
      if (_aciklamaController.text.length < 30) {
        _showStatusBottomSheet(
          'Lütfen en az 30 karakter olacak şekilde açıklama giriniz',
          isError: true,
        );
        _aciklamaFocusNode.requestFocus();
        return;
      }

      // Adres zorunlu kontrolü
      if (_adresController.text.isEmpty) {
        setState(() {
          _adresHatali = true;
        });
        _showStatusBottomSheet(
          'Lütfen izin süresince bulunacağınız adresi giriniz',
          isError: true,
        );
        _adresFocusNode.requestFocus();
        return;
      }

      // Form validasyonları
      if (_baslangicTarihi == null) {
        _showStatusBottomSheet('Başlangıç tarihi seçiniz', isError: true);
        return;
      }

      // 1 günlük izin aktif ise başlangıç tarihi = bitiş tarihi
      DateTime bitisTarih;
      if (_birGunlukIzin) {
        bitisTarih = _baslangicTarihi!;
      } else if (_bitisTarihi == null) {
        _showStatusBottomSheet('Bitiş tarihi seçiniz', isError: true);
        return;
      } else {
        bitisTarih = _bitisTarihi!;
      }

      // Başlangıç tarihi bitiş tarihinden büyük olamaz
      if (_baslangicTarihi!.isAfter(bitisTarih)) {
        _showStatusBottomSheet(
          'Başlangıç tarihi bitiş tarihinden büyük olamaz',
          isError: true,
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
        final diniGunlerAsync = await ref.read(
          diniGunlerProvider(personelIdForDiniGun).future,
        );

        // Seçilen dini günü al
        final secilenDiniGun = diniGunlerAsync.isNotEmpty
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
            IzinOzetItem(label: 'İzin Türü', value: 'Dini'),
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
              if (result is Failure) {
                throw Exception(result.message);
              }
            },
            onSuccess: () {
              _showStatusBottomSheet(
                'Dini izin talebi başarıyla gönderildi!',
                isError: false,
              );
            },
            onError: (error) {
              _showStatusBottomSheet('Hata: $error', isError: true);
            },
          );
        }
      } catch (e) {
        if (mounted) {
          _showStatusBottomSheet('Hata oluştu: $e', isError: true);
        }
      }
    }
  }

  void _showStatusBottomSheet(String message, {bool isError = false}) async {
    // 🔴 KRİTİK: BottomSheet açmadan önce tüm focus'ları kapat
    _aciklamaFocusNode.unfocus();
    _adresFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext statusContext) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: AppColors.textOnPrimary,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                size: 64,
                color: isError ? AppColors.error : AppColors.success,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(statusContext);
                  // Başarı durumunda İzin Taleplerini Yönet ekranına git
                  if (!isError) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        // Tüm önceki ekranları temizleyip doğrudan İzin Taleplerini Yönet'e git
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            context.go('/izin_istek');
                          }
                        });
                      }
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientEnd,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(color: AppColors.textOnPrimary),
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
}
