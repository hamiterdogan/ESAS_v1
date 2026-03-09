import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/custom_switch_widget.dart';
import 'package:esas_v1/common/widgets/file_photo_upload_widget.dart';
import 'package:esas_v1/common/widgets/validation_uyari_widget.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/common/widgets/common_divider.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_ekle_req.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/core/services/email_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:esas_v1/features/izin_istek/widgets/guideline_card_with_toggle.dart';

class HastalikIzinScreen extends ConsumerStatefulWidget {
  const HastalikIzinScreen({super.key});

  @override
  ConsumerState<HastalikIzinScreen> createState() => _HastalikIzinScreenState();
}

class _HastalikIzinScreenState extends ConsumerState<HastalikIzinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aciklamaController = TextEditingController();
  final _adresController = TextEditingController();
  final _aciklamaFocusNode = FocusNode();
  final _adresFocusNode = FocusNode();
  DateTime? _initialBaslangicTarihi;
  DateTime? _initialBitisTarihi;
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;
  int _baslangicSaat = 8;
  int _baslangicDakika = 0;
  int _bitisSaat = 17;
  int _bitisDakika = 30;
  int _girileymeyenDersSaati = 0;
  bool _onay = false;
  bool _isSubmitting = false;
  bool _acil = false;
  bool _doktorRaporuVar = false;
  bool _birGunlukIzin = false;
  File? _doktorRaporuFile;
  Personel? _secilenPersonel;
  final bool _basaksiAdinaIstekte = false;

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
    if (_baslangicSaat != 8 || _baslangicDakika != 0) return true;
    if (_bitisSaat != 17 || _bitisDakika != 30) return true;
    if (_birGunlukIzin) return true;
    if (_onay) return true;
    if (_acil) return true;
    if (_doktorRaporuVar) return true;
    if (_aciklamaController.text.isNotEmpty) return true;
    if (_adresController.text.isNotEmpty) return true;
    if (_girileymeyenDersSaati > 0) return true;
    if (_doktorRaporuFile != null) return true;
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'xls',
        'xlsx',
        'doc',
        'docx',
      ],
      withData: true,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _doktorRaporuFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickFromCamera() async {
    FocusScope.of(context).unfocus();
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      setState(() {
        _doktorRaporuFile = File(image.path);
      });
    } catch (_) {
      if (mounted) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Fotoğraf seçimi başarısız',
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    FocusScope.of(context).unfocus();
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _doktorRaporuFile = File(image.path);
      });
    } catch (_) {
      if (mounted) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Fotoğraf seçimi başarısız',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }

        if (_hasFormData()) {
          final bool shouldPop = await _showExitConfirmationDialog();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        } else {
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            title: const Text(
              'Hastalık İzni İstek',
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
                        // 1 günlük izin aktif edildiğinde bitiş saati 17:30 olsun
                        if (value) {
                          _bitisSaat = 17;
                          _bitisDakika = 30;
                        }
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

                  // Başlangıç ve Bitiş Saati (Yan Yana)
                  Row(
                    children: [
                      Expanded(
                        child: TimePickerBottomSheetWidget(
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
                          initialHour: _baslangicSaat,
                          initialMinute: _baslangicDakika,
                          minHour: 8,
                          maxHour: 17,
                          allowedMinutes: const [0, 30],
                          label: 'Başlangıç Saati',
                          onTimeChanged: (hour, minute) {
                            // 🔴 KRİTİK: Saat değiştiğinde klavyeyi kapat
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _baslangicSaat = hour;
                              _baslangicDakika = minute;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: TimePickerBottomSheetWidget(
                          key: ValueKey(
                            'end-time-$_baslangicSaat-$_baslangicDakika-$_birGunlukIzin-$_baslangicTarihi-$_bitisTarihi-$_bitisSaat-$_bitisDakika',
                          ),
                          initialHour: _bitisSaat,
                          initialMinute: _bitisDakika,
                          minHour:
                              (_birGunlukIzin ||
                                  _baslangicTarihi == _bitisTarihi)
                              ? _baslangicSaat
                              : 8,
                          minMinute:
                              (_birGunlukIzin ||
                                  _baslangicTarihi == _bitisTarihi)
                              ? _baslangicDakika
                              : 0,
                          minGapMinutes:
                              (_birGunlukIzin ||
                                  _baslangicTarihi == _bitisTarihi)
                              ? 30
                              : 0,
                          maxHour: 17,
                          allowAllMinutesAtMaxHour: true,
                          allowedMinutes: const [0, 30],
                          label: 'Bitiş Saati',
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
                          onTimeChanged: (hour, minute) {
                            // 🔴 KRİTİK: Saat değiştiğinde klavyeyi kapat
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _bitisSaat = hour;
                              _bitisDakika = minute;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Acil Toggle
                  CustomSwitchWidget(
                    value: _acil,
                    label: 'Acil',
                    onChanged: (value) {
                      setState(() {
                        _acil = value;
                      });
                    },
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

                  // Doktor Raporu Var Toggle
                  CustomSwitchWidget(
                    value: _doktorRaporuVar,
                    label: 'Doktor Raporu Var',
                    onChanged: (value) {
                      setState(() {
                        _doktorRaporuVar = value;
                        if (!value) {
                          _doktorRaporuFile = null;
                        }
                      });
                    },
                  ),

                  // Doktor Raporu Dosya Yükleme
                  if (_doktorRaporuVar) ...[
                    const SizedBox(height: 16),
                    FilePhotoUploadWidget<File>(
                      title: 'Doktor Raporu',
                      buttonText: 'Dosya/Fotoğraf Yükle',
                      files: _doktorRaporuFile == null
                          ? const []
                          : [_doktorRaporuFile!],
                      fileNameBuilder: (file) =>
                          file.path.split(Platform.pathSeparator).last,
                      onRemoveFile: (_) {
                        setState(() {
                          _doktorRaporuFile = null;
                        });
                      },
                      onPickCamera: _pickFromCamera,
                      onPickGallery: _pickFromGallery,
                      onPickFile: _pickFile,
                    ),
                  ],
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
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      if (_formKey.currentState?.validate() ?? false) {
        // Form validasyonları
        if (_baslangicTarihi == null) {
          await ValidationUyariWidget.goster(
            context: context,
            message: 'Başlangıç tarihi seçiniz',
          );
          return;
        }

        // 1 günlük izin aktif ise bitiş tarihi = başlangıç tarihi
        DateTime bitisTarih;
        int bitisSaatValue;
        int bitisDakikaValue;

        if (_birGunlukIzin) {
          bitisTarih = _baslangicTarihi!;
          bitisSaatValue = 17;
          bitisDakikaValue = 30;
        } else {
          if (_bitisTarihi == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bitiş tarihi seçiniz')),
            );
            return;
          }
          bitisTarih = _bitisTarihi!;
          bitisSaatValue = _bitisSaat;
          bitisDakikaValue = _bitisDakika;
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

        if (_doktorRaporuVar && _doktorRaporuFile == null) {
          await ValidationUyariWidget.goster(
            context: context,
            message: 'Doktor raporu dosyası seçiniz',
          );
          return;
        }

        // Başlangıç tarihi bitiş tarihinden sonra olamaz
        if (_baslangicTarihi!.isAfter(bitisTarih)) {
          await ValidationUyariWidget.goster(
            context: context,
            message:
                'İzin başlangıç tarihi izin bitiş tarihinden küçük olmalıdır',
          );
          return;
        }

        // Başlangıç ve bitiş saatleri aynı olamaz (1 günlük izin aktifken veya tarihler aynıyken)
        if ((_birGunlukIzin || _baslangicTarihi == _bitisTarihi) &&
            _baslangicSaat == _bitisSaat &&
            _baslangicDakika == _bitisDakika) {
          await ValidationUyariWidget.goster(
            context: context,
            message:
                'Lütfen başlangıç saati ve bitiş saati değerlerini kontrol ediniz',
          );
          return;
        }

        try {
          // İzin nedenleri provider'dan hastalık izin ID'sini al
          await ref.read(allIzinNedenlerProvider.future);

          // Hastalık izin sebep ID: 4
          const int izinSebebiId = 4;

          // IzinIstekEkleReq oluştur - API'nin beklediği format
          final request = IzinIstekEkleReq(
            izinSebebiId: izinSebebiId,
            izinBaslangicTarihi: _baslangicTarihi!,
            izinBitisTarihi: bitisTarih,
            aciklama: _aciklamaController.text,
            izindeBulunacagiAdres: _adresController.text,
            hastalik: _acil ? 'Acil' : 'Acil Değil',
            // Opsiyonel alanlar
            izinBaslangicSaat: _baslangicSaat,
            izinBaslangicDakika: _baslangicDakika,
            izinBitisSaat: bitisSaatValue,
            izinBitisDakika: bitisDakikaValue,
            doktorRaporu: _doktorRaporuVar,
            izindeGirilmeyenToplamDersSaati: _girileymeyenDersSaati,
            baskaPersonelId: _secilenPersonel?.personelId,
          );

          // Bottom sheet'te verileri göster
          if (mounted) {
            final ozetItems = [
              IzinOzetItem(
                label: 'İzin Türü',
                value: 'Hastalık İzni',
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
              IzinOzetItem(
                label: 'Başlangıç Saati',
                value:
                    '${_baslangicSaat.toString().padLeft(2, '0')}:${_baslangicDakika.toString().padLeft(2, '0')}',
                multiLine: false,
              ),
              IzinOzetItem(
                label: 'Bitiş Saati',
                value:
                    '${bitisSaatValue.toString().padLeft(2, '0')}:${bitisDakikaValue.toString().padLeft(2, '0')}',
                multiLine: false,
              ),
              IzinOzetItem(
                label: 'Girilmeyen Toplam Ders Saati',
                value: _girileymeyenDersSaati.toString(),
                multiLine: false,
              ),
              IzinOzetItem(
                label: 'İzinde Bulunacağı Adres',
                value: _adresController.text,
              ),
              IzinOzetItem(
                label: 'Hastalık Durumu',
                value: _acil ? 'Acil' : 'Acil Değil',
                multiLine: false,
              ),
              IzinOzetItem(
                label: 'Doktor Raporu',
                value: _doktorRaporuVar ? 'Var' : 'Yok',
                multiLine: false,
              ),
              if (_doktorRaporuVar && _doktorRaporuFile != null)
                IzinOzetItem(
                  label: 'Dosya Adı',
                  value: _doktorRaporuFile!.path
                      .split('/')
                      .last
                      .split('\\')
                      .last,
                ),
            ];

            await showIzinOzetBottomSheet(
              context: context,
              request: request,
              izinTipi: 'Hastalık',
              ozetItems: ozetItems,
              onGonder: () async {
                final repo = ref.read(izinIstekRepositoryProvider);
                // Doktor raporu varsa dosyayı da gönder
                final result = await repo.izinIstekEkle(
                  request,
                  file: _doktorRaporuVar ? _doktorRaporuFile : null,
                );
                if (result is Failure<int>) {
                  throw Exception(result.message);
                } else if (result is Success<int>) {
                  if (result.data > 0) {
                    final emailService = ref.read(emailServiceProvider);
                    await emailService.emailIcerikOlustur(
                      id: result.data,
                      kategori: 'İzin İstek',
                      aksiyon: 'Oluşturuldu',
                    );
                  }
                }
              },
              onSuccess: () async {
                if (!mounted) return;
                await IstekBasariliWidget.goster(
                  context: context,
                  message: 'Hastalık izni isteğiniz gönderilmiştir.',
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
