import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/validation_uyari_widget.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/common/widgets/common_divider.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_ekle_req.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/widgets/guideline_card_with_toggle.dart';

class EvlilikIzinScreen extends ConsumerStatefulWidget {
  const EvlilikIzinScreen({super.key});

  @override
  ConsumerState<EvlilikIzinScreen> createState() => _EvlilikIzinScreenState();
}

class _EvlilikIzinScreenState extends ConsumerState<EvlilikIzinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aciklamaController = TextEditingController();
  final _adresController = TextEditingController();
  final _esAdiController = TextEditingController();
  final _aciklamaFocusNode = FocusNode();
  final _adresFocusNode = FocusNode();
  final _esAdiFocusNode = FocusNode();
  DateTime? _initialBaslangicTarihi;
  DateTime? _initialBitisTarihi;
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;
  DateTime? _evlilikTarihi;
  int _girileymeyenDersSaati = 0;
  bool _onay = false;
  Personel? _secilenPersonel;
  bool _basaksiAdinaIstekte = false;

  // Hata durumu state'leri
  bool _adresHatali = false;
  bool _esAdiHatali = false;

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
    _initialBaslangicTarihi = today;
    _initialBitisTarihi = _getNextSelectableDay(today);
    _baslangicTarihi = _initialBaslangicTarihi;
    _bitisTarihi = _initialBitisTarihi;
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _adresController.dispose();
    _esAdiController.dispose();
    _aciklamaFocusNode.dispose();
    _adresFocusNode.dispose();
    _esAdiFocusNode.dispose();
    super.dispose();
  }

  bool _hasFormData() {
    if (!_isSameDate(_baslangicTarihi, _initialBaslangicTarihi)) return true;
    if (!_isSameDate(_bitisTarihi, _initialBitisTarihi)) return true;
    if (_onay) return true;
    if (_basaksiAdinaIstekte) return true;
    if (_secilenPersonel != null) return true;
    if (_aciklamaController.text.isNotEmpty) return true;
    if (_adresController.text.isNotEmpty) return true;
    if (_esAdiController.text.isNotEmpty) return true;
    if (_girileymeyenDersSaati > 0) return true;
    if (_evlilikTarihi != null) return true;
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
              'Evlilik İzni İstek',
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
                        if (!value) {
                          _secilenPersonel = null;
                        }
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

                  // Başlangıç ve Bitiş Tarihi
                  Row(
                    children: [
                      Expanded(
                        child: DatePickerBottomSheetWidget(
                          initialDate: _baslangicTarihi,
                          label: 'Başlangıç Tarihi',
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
                          onDateChanged: (date) {
                            setState(() {
                              _baslangicTarihi = date;
                              if (_bitisTarihi == null ||
                                  date.isAfter(_bitisTarihi!)) {
                                var nextDay = date.add(const Duration(days: 1));
                                if (nextDay.weekday == DateTime.sunday) {
                                  nextDay = nextDay.add(
                                    const Duration(days: 1),
                                  );
                                }
                                _bitisTarihi = nextDay;
                              }
                              // Başlangıç tarihi bitişten küçükse bitiş sabit kalır
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: DatePickerBottomSheetWidget(
                          initialDate: _bitisTarihi,
                          minDate: _baslangicTarihi != null
                              ? _getNextSelectableDay(_baslangicTarihi!)
                              : null,
                          label: 'Bitiş Tarihi',
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

                  // Evlilik Tarihi
                  Row(
                    children: [
                      Expanded(
                        child: DatePickerBottomSheetWidget(
                          initialDate: _evlilikTarihi,
                          label: 'Evlilik Tarihi',
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
                          onDateChanged: (date) {
                            setState(() {
                              _evlilikTarihi = date;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Eş Adı
                  Text(
                    'Eş Adı',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                      color: AppColors.inputLabelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TextFormField(
                      focusNode: _esAdiFocusNode,
                      controller: _esAdiController,
                      decoration: InputDecoration(
                        hintText: 'Lütfen eşinizin adını giriniz.',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: true,
                        fillColor: AppColors.textOnPrimary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        if (_esAdiHatali && value.isNotEmpty) {
                          setState(() {
                            _esAdiHatali = false;
                          });
                        }
                      },
                    ),
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
                         borderSide: BorderSide(color: AppColors.borderStandartColor, width: 0.75),
                       ),
                       enabledBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8),
                         borderSide: BorderSide(color: AppColors.borderStandartColor, width: 0.75),
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8),
                         borderSide: BorderSide(color: AppColors.gradientStart, width: 0.75),
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
                    padding: 14.0,
                    borderRadius: 8.0,
                    textStyle: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
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
    if (_formKey.currentState?.validate() ?? false) {
      // Form validasyonları
      if (_baslangicTarihi == null) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Başlangıç tarihi seçiniz',
        );
        return;
      }

      if (_bitisTarihi == null) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Bitiş tarihi seçiniz',
        );
        return;
      }

      if (_evlilikTarihi == null) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Evlilik tarihi seçiniz',
        );
        return;
      }

      // Açıklama minimum 30 karakter kontrolü
      if (_aciklamaController.text.length < 30) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen en az 30 karakter olacak şekilde açıklama giriniz',
        );
        _aciklamaFocusNode.requestFocus();
        return;
      }

      // Adres boş kontrolü
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

      // Eş adı boş kontrolü
      if (_esAdiController.text.isEmpty) {
        setState(() {
          _esAdiHatali = true;
        });
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen eşinizin adını giriniz',
        );
        _esAdiFocusNode.requestFocus();
        return;
      }

      // Başlangıç tarihi bitiş tarihinden sonra olamaz
      if (_baslangicTarihi!.isAfter(_bitisTarihi!)) {
        await ValidationUyariWidget.goster(
          context: context,
          message:
              'İzin başlangıç tarihi izin bitiş tarihinden küçük olmalıdır',
        );
        return;
      }

      try {
        // Token'dan personel ID'sini al
        final dolduranPersonelId = ref.read(currentPersonelIdProvider);

        // Evlilik izin sebep ID: 2
        const int izinSebebiId = 2;

        // baskaPersonelId: toggle aktif ise seçilen personel id, değilse 0
        final int baskaPersonelIdValue =
            _basaksiAdinaIstekte && _secilenPersonel != null
            ? _secilenPersonel!.personelId
            : 0;

        // IzinIstekEkleReq oluştur - API'nin beklediği format
        final request = IzinIstekEkleReq(
          izinSebebiId: izinSebebiId,
          izinBaslangicTarihi: _baslangicTarihi!,
          izinBitisTarihi: _bitisTarihi!,
          aciklama: _aciklamaController.text,
          izindeBulunacagiAdres: _adresController.text,
          izindeGirilmeyenToplamDersSaati: _girileymeyenDersSaati,
          baskaPersonelId: baskaPersonelIdValue,
          dolduranPersonelId: dolduranPersonelId,
          evlilikTarihi: _evlilikTarihi,
          esAdi: _esAdiController.text,
        );

        // Bottom sheet'te verileri göster
        if (mounted) {
          final ozetItems = [
            IzinOzetItem(label: 'İzin Türü', value: 'Evlilik'),
            IzinOzetItem(label: 'Açıklama', value: _aciklamaController.text),
            IzinOzetItem(
              label: 'Başlangıç Tarihi',
              value: _formatDate(_baslangicTarihi!),
              multiLine: false,
            ),
            IzinOzetItem(
              label: 'Bitiş Tarihi',
              value: _formatDate(_bitisTarihi!),
              multiLine: false,
            ),
            IzinOzetItem(
              label: 'Evlilik Tarihi',
              value: _formatDate(_evlilikTarihi!),
            ),
            IzinOzetItem(label: 'Eş Adı', value: _esAdiController.text),
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
            izinTipi: 'Evlilik',
            ozetItems: ozetItems,
            onGonder: () async {
              final repo = ref.read(izinIstekRepositoryProvider);
              final result = await repo.izinIstekEkle(request);
              if (result is Failure) {
                throw Exception(result.message);
              }
            },
            onSuccess: () async {
              if (!mounted) return;
              await IstekBasariliWidget.goster(
                context: context,
                message: 'Evlilik izni isteğiniz oluşturulmuştur.',
                onConfirm: () async {
                  ref.invalidate(devamEdenIsteklerimProvider);
                  ref.invalidate(tamamlananIsteklerimProvider);
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  if (!context.mounted) return;
                  context.go('/izin_istek');
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
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
