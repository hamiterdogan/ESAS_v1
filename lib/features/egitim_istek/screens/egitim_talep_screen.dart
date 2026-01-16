import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/common/widgets/duration_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/generic_summary_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/app_dialogs.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/features/egitim_istek/screens/egitim_ucretleri_screen.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';

import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';
import 'package:esas_v1/features/egitim_istek/providers/egitim_istek_providers.dart';
import 'package:esas_v1/features/egitim_istek/screens/egitim_sonrasi_paylasim_screen.dart';
import 'package:esas_v1/features/egitim_istek/repositories/egitim_istek_repository.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/satin_alma/models/para_birimi.dart';
import 'package:esas_v1/features/satin_alma/models/odeme_turu.dart';

class EgitimTalepScreen extends ConsumerStatefulWidget {
  const EgitimTalepScreen({super.key});

  @override
  ConsumerState<EgitimTalepScreen> createState() => _EgitimTalepScreenState();
}

class _EgitimTalepScreenState extends ConsumerState<EgitimTalepScreen> {
  late DateTime _initialBaslangicTarihi;
  late DateTime _initialBitisTarihi;
  late DateTime _baslangicTarihi;
  late DateTime _bitisTarihi;
  int _baslangicSaat = 8;
  int _baslangicDakika = 0;
  int _bitisSaat = 17;
  int _bitisDakika = 30;
  int _egitimGun = 0;
  int _egitimSaat = 1;
  int _girileymeyenDersSaati = 0;
  bool _topluIstekte = false;
  bool _online = false;
  bool _ucretsiz = false;
  String? _secilenEgitimAdi;
  String? _secilenEgitimTuru;
  String _adres = '';
  String _egitimSirketiAdi = '';
  String _egitimKonusu = '';
  String _webSitesi = '';
  bool _egitimYeriYurtDisi = false;
  String _egitimUlkeSehir = '';
  String? _secilenSehir;
  List<Map<String, dynamic>> _sehirler = [];
  bool _sehirlerYuklendi = false;
  List<String> _egitimAdlari = [];
  bool _egitimAdlariYuklendi = false;
  Map<String, dynamic>? _egitimUcretleriData;
  Map<String, dynamic>? _egitimSonrasiPaylasimData;
  List<String> _egitimTurleri = [];
  bool _egitimTurleriYuklendi = false;
  double _aldigiEgitimUcreti = 0;
  bool _agreeWithDocuments = false;

  final Set<int> _selectedPersonelIdsForTopluIstek = {};
  final Set<int> _selectedPersonelIdsForPaylasum = {};
  List<PersonelItem> _personeller = [];
  List<GorevItem> _gorevler = [];
  List<GorevYeriItem> _gorevYerleri = [];
  final List<PlatformFile> _selectedFiles = [];
  final TextEditingController _egitimTeklifIcerikController =
      TextEditingController();
  final TextEditingController _ozelEgitimAdiController =
      TextEditingController();

  // FocusNodes for keyboard control
  final FocusNode _egitimTeklifIcerikFocusNode = FocusNode();
  final FocusNode _ozelEgitimAdiFocusNode = FocusNode();

  // FocusNodes for validation fields
  final FocusNode _egitimSirketiAdiFocusNode = FocusNode();
  final FocusNode _egitimKonusuFocusNode = FocusNode();
  final FocusNode _webSitesiFocusNode = FocusNode();
  final FocusNode _ulkeSehirFocusNode = FocusNode();
  final FocusNode _adresFocusNode = FocusNode();

  // ScrollController for validation scrolling
  late ScrollController _scrollController;

  // GlobalKey'ler validasyon hatalarında scroll yapabilmek için
  final GlobalKey _egitimAdiKey = GlobalKey();
  final GlobalKey _egitimTuruKey = GlobalKey();
  final GlobalKey _egitimSirketiAdiKey = GlobalKey();
  final GlobalKey _egitimKonusuKey = GlobalKey();
  final GlobalKey _webSitesiKey = GlobalKey();
  final GlobalKey _adresKey = GlobalKey();
  final GlobalKey _egitimUcretiKey = GlobalKey();
  final GlobalKey _sehirKey = GlobalKey();
  final GlobalKey _ulkeSehirKey = GlobalKey();
  final GlobalKey _personelKey = GlobalKey();

  // ignore: unused_field - used to track loading state
  bool _ucretYukleniyor = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initialBaslangicTarihi = DateTime.now();
    _initialBitisTarihi = DateTime.now().add(const Duration(days: 7));
    _baslangicTarihi = _initialBaslangicTarihi;
    _bitisTarihi = _initialBitisTarihi;
    // Eğitim adlarını yükle
    if (!_egitimAdlariYuklendi) {
      _fetchEgitimAdlari();
    }
    // Eğitim türlerini yükle
    if (!_egitimTurleriYuklendi) {
      _fetchEgitimTurleri();
    }
    // Şehirleri yükle
    if (!_sehirlerYuklendi) {
      _fetchSehirler();
    }
    // Alınan eğitim ücretini yükle
    _fetchAlinanEgitimUcreti();
  }

  @override
  void dispose() {
    _egitimTeklifIcerikController.dispose();
    _ozelEgitimAdiController.dispose();
    _egitimTeklifIcerikFocusNode.dispose();
    _ozelEgitimAdiFocusNode.dispose();
    _egitimSirketiAdiFocusNode.dispose();
    _egitimKonusuFocusNode.dispose();
    _webSitesiFocusNode.dispose();
    _ulkeSehirFocusNode.dispose();
    _adresFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FocusScope.of(context).unfocus();
    try {
      final result = await FilePicker.platform.pickFiles(
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'xls',
          'xlsx',
        ],
        type: FileType.custom,
        allowMultiple: true,
      );

      if (result != null) {
        final existingNames = _selectedFiles.map((f) => f.name).toSet();
        final newFiles = <PlatformFile>[];
        final duplicateNames = <String>[];

        for (final file in result.files) {
          if (existingNames.contains(file.name)) {
            duplicateNames.add(file.name);
          } else {
            newFiles.add(file);
          }
        }

        setState(() {
          _selectedFiles.addAll(newFiles);
        });

        if (duplicateNames.isNotEmpty && mounted) {
          // 🔒 Enhanced focus control
          _egitimTeklifIcerikFocusNode.canRequestFocus = false;
          _ozelEgitimAdiFocusNode.canRequestFocus = false;
          FocusScope.of(context).unfocus();

          // 🔒 Critical: Wait 1 frame for focus state to settle
          await Future.delayed(Duration.zero);

          if (!mounted) return;

          await showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: 60,
              ),
              decoration: const BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bu dosyayı daha önce eklediniz',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    duplicateNames.join(', '),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientStart,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showStatusBottomSheet('Dosya seçimi başarısız: $e', isError: true);
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  bool _hasFormData() {
    // Temel form alanlarını kontrol et
    if (!_isSameDate(_baslangicTarihi, _initialBaslangicTarihi)) return true;
    if (!_isSameDate(_bitisTarihi, _initialBitisTarihi)) return true;
    if (_baslangicSaat != 8 || _baslangicDakika != 0) return true;
    if (_bitisSaat != 17 || _bitisDakika != 30) return true;
    if (_egitimGun != 0 || _egitimSaat != 1) return true;
    if (_girileymeyenDersSaati != 0) return true;
    if (_topluIstekte) return true;
    if (_online) return true;
    if (_ucretsiz) return true;
    if (_egitimYeriYurtDisi) return true;
    if (_agreeWithDocuments) return true;
    if (_secilenEgitimAdi != null) return true;
    if (_secilenEgitimTuru != null) return true;
    if (_egitimSirketiAdi.isNotEmpty) return true;
    if (_egitimKonusu.isNotEmpty) return true;
    if (_webSitesi.isNotEmpty) return true;
    if (_adres.isNotEmpty) return true;
    if (_egitimUlkeSehir.isNotEmpty) return true;
    if (_secilenSehir != null) return true;
    if (_topluIstekte && _selectedPersonelIdsForTopluIstek.isNotEmpty) {
      return true;
    }
    if (_selectedPersonelIdsForPaylasum.isNotEmpty) return true;
    if (_ozelEgitimAdiController.text.isNotEmpty) return true;
    if (_egitimTeklifIcerikController.text.isNotEmpty) return true;
    if (_selectedFiles.isNotEmpty) return true;
    if (_egitimUcretleriData != null) return true;
    if (_egitimSonrasiPaylasimData != null) return true;

    return false;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<bool> _showExitConfirmationDialog() async {
    return AppDialogs.showFormExitConfirm(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // Form verisi varsa onay iste
        if (_hasFormData()) {
          final shouldPop = await _showExitConfirmationDialog();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        } else {
          // Form boşsa direkt çık
          if (context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textOnPrimary,
                    ),
                    onPressed: () async {
                      if (_hasFormData()) {
                        final shouldPop = await _showExitConfirmationDialog();
                        if (shouldPop && context.mounted) {
                          context.pop();
                        }
                      } else {
                        context.pop();
                      }
                    },
                  ),
                  const Text(
                    'Eğitim İstek',
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Başlangıç Tarihi',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
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
                            DatePickerBottomSheetWidget(
                              label: null,
                              initialDate: _baslangicTarihi,
                              minDate: DateTime.now(),
                              maxDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              onDateChanged: (date) {
                                setState(() => _baslangicTarihi = date);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bitiş Tarihi',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
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
                            DatePickerBottomSheetWidget(
                              label: null,
                              initialDate: _bitisTarihi,
                              minDate: _baslangicTarihi,
                              maxDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              onDateChanged: (date) {
                                setState(() => _bitisTarihi = date);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                              ),
                          initialHour: _baslangicSaat,
                          initialMinute: _baslangicDakika,
                          minHour: 8,
                          maxHour: 17,
                          allowedMinutes: const [0, 30],
                          label: 'Başlangıç Saati',
                          onTimeChanged: (hour, minute) {
                            setState(() {
                              _baslangicSaat = hour;
                              _baslangicDakika = minute;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
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
                              ),
                          initialHour: _bitisSaat,
                          initialMinute: _bitisDakika,
                          minHour: _baslangicSaat,
                          minMinute: 0,
                          maxHour: 17,
                          allowAllMinutesAtMaxHour: true,
                          allowedMinutes: const [0, 30],
                          label: 'Bitiş Saati',
                          onTimeChanged: (hour, minute) {
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Eğitimin Süresi',
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
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          // 🔒 Enhanced focus control
                          _egitimTeklifIcerikFocusNode.canRequestFocus = false;
                          _ozelEgitimAdiFocusNode.canRequestFocus = false;
                          if (!mounted) return;
                          FocusScope.of(context).unfocus();

                          // 🔒 Critical: Wait 1 frame for focus state to settle
                          await Future.delayed(Duration.zero);

                          if (!context.mounted) return;

                          await showModalBottomSheet<void>(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (BuildContext sheetContext) {
                              return Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  color: AppColors.textOnPrimary,
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.gradientStart
                                            .withValues(alpha: 0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline,
                                        color: AppColors.gradientStart,
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Eğitimin kaç gün süreceğini ve 1 günlük eğitim saatini giriniz.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            60,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(sheetContext);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.gradientEnd,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Tamam',
                                          style: TextStyle(
                                            color: AppColors.textOnPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );

                          // Ensure keyboard stays hidden after BottomSheet closes
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              FocusScope.of(context).unfocus();
                              _egitimTeklifIcerikFocusNode.canRequestFocus =
                                  true;
                              _ozelEgitimAdiFocusNode.canRequestFocus = true;
                            }
                          });
                        },
                        child: const Icon(
                          Icons.info_outlined,
                          size: 20,
                          color: AppColors.gradientStart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DurationPickerBottomSheetWidget(
                    label: null,
                    initialDay: _egitimGun,
                    initialHour: _egitimSaat,
                    minDay: 0,
                    maxDay: 999,
                    minHour: 1,
                    maxHour: 24,
                    onDurationChanged: (day, hour) {
                      setState(() {
                        _egitimGun = day;
                        _egitimSaat = hour;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  NumericSpinnerWidget(
                    initialValue: _girileymeyenDersSaati,
                    onValueChanged: (value) {
                      setState(() {
                        _girileymeyenDersSaati = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  OnayToggleWidget(
                    initialValue: _topluIstekte,
                    label: 'Toplu istekte bulunmak istiyorum',
                    onChanged: (value) {
                      setState(() {
                        _topluIstekte = value;
                        if (!value) {
                          _selectedPersonelIdsForTopluIstek.clear();
                          // Toplu istek kapatıldığında ücret ekranını 1 kişi için güncelle
                          if (_egitimUcretleriData != null) {
                            _refreshEducationCostsScreen(1);
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_topluIstekte)
                    Container(
                      key: _personelKey,
                      child: PersonelSelectorWidget(
                        initialSelection: _selectedPersonelIdsForTopluIstek,
                        fetchFunction: () => ref
                            .read(aracTalepRepositoryProvider)
                            .personelSecimVerisiGetir(),
                        onSelectionChanged: (ids) {
                          setState(() {
                            _selectedPersonelIdsForTopluIstek.clear();
                            _selectedPersonelIdsForTopluIstek.addAll(ids);
                          });

                          // Eğitim ücretleri ekranını güncelle
                          if (_egitimUcretleriData != null) {
                            _refreshEducationCostsScreen(
                              _getSelectedPersonelCount(),
                            );
                          }
                        },
                        onDataLoaded: (data) {
                          setState(() {
                            _personeller = data.personeller;
                            _gorevler = data.gorevler;
                            _gorevYerleri = data.gorevYerleri;
                          });
                        },
                      ),
                    ),
                  if (_topluIstekte) const SizedBox(height: 24),
                  Column(
                    key: _egitimAdiKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eğitimin Adı',
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
                      GestureDetector(
                        onTap: () => _showEgitimAdiBottomSheet(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _secilenEgitimAdi ?? 'Eğitim adını seçiniz',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _secilenEgitimAdi != null
                                        ? AppColors.textPrimary
                                        : Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_secilenEgitimAdi == 'DİĞER') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ozelEgitimAdiController,
                          decoration: InputDecoration(
                            hintText: 'Eğitimin Adını Yazınız',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            filled: true,
                            fillColor: AppColors.textOnPrimary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Eğitim Türü Input
                      Expanded(
                        flex: 130,
                        child: Column(
                          key: _egitimTuruKey,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eğitim Türü',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
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
                            GestureDetector(
                              onTap: () => _showEgitimTuruBottomSheet(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textOnPrimary,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _secilenEgitimTuru ??
                                            'Eğitim türünü seçiniz',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _secilenEgitimTuru != null
                                              ? AppColors.textPrimary
                                              : Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Online Toggle
                      Expanded(
                        flex: 60,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 28.0),
                          child: OnayToggleWidget(
                            initialValue: _online,
                            label: 'Online',
                            onChanged: (value) {
                              setState(() {
                                _online = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    key: _egitimSirketiAdiKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eğitim Şirketinin Adı',
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
                      TextFormField(
                        focusNode: _egitimSirketiAdiFocusNode,
                        initialValue: _egitimSirketiAdi,
                        onChanged: (value) {
                          setState(() {
                            _egitimSirketiAdi = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Eğitim şirketinin adını giriniz',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: AppColors.textOnPrimary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    key: _egitimKonusuKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eğitimin Konusu',
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
                      TextFormField(
                        focusNode: _egitimKonusuFocusNode,
                        initialValue: _egitimKonusu,
                        onChanged: (value) {
                          setState(() {
                            _egitimKonusu = value;
                          });
                        },
                        maxLines: 3,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Eğitimin konusunu giriniz',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: AppColors.textOnPrimary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Web Sitesi',
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
                      TextFormField(
                        key: _webSitesiKey,
                        focusNode: _webSitesiFocusNode,
                        initialValue: _webSitesi,
                        onChanged: (value) {
                          setState(() {
                            _webSitesi = value;
                          });
                        },
                        validator: (value) {
                          final trimmedValue = value?.trim() ?? '';

                          // Boş bırakıldıysa OK (zorunlu değil)
                          if (trimmedValue.isEmpty) {
                            return null;
                          }

                          // Dolu ise format kontrol et (geçersizse uyarı ver)
                          final uri = Uri.tryParse(trimmedValue);
                          final hasValidProtocol =
                              uri != null &&
                              (uri.scheme == 'http' || uri.scheme == 'https');
                          final hasValidHost =
                              uri != null &&
                              uri.host.isNotEmpty &&
                              uri.host.contains('.');

                          if (!hasValidProtocol || !hasValidHost) {
                            return 'web sitesi adresini kontrol ediniz';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'http://',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: AppColors.textOnPrimary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OnayToggleWidget(
                    initialValue: _egitimYeriYurtDisi,
                    label: 'Eğitim yeri yurt dışında',
                    onChanged: (value) {
                      setState(() {
                        _egitimYeriYurtDisi = value;
                        if (value) {
                          _secilenSehir = null;
                        } else {
                          _egitimUlkeSehir = '';
                        }
                      });
                    },
                  ),
                  if (_egitimYeriYurtDisi) ...[
                    const SizedBox(height: 16),
                    Column(
                      key: _ulkeSehirKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ülke / Şehir',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
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
                        TextFormField(
                          focusNode: _ulkeSehirFocusNode,
                          initialValue: _egitimUlkeSehir,
                          onChanged: (value) {
                            setState(() {
                              _egitimUlkeSehir = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Ülke / Şehir bilgisini giriniz',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            filled: true,
                            fillColor: AppColors.textOnPrimary,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Column(
                      key: _sehirKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Şehir',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
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
                        GestureDetector(
                          onTap: () => _showSehirBottomSheet(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textOnPrimary,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _secilenSehir ?? 'Şehir seçiniz',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _secilenSehir != null
                                          ? AppColors.textPrimary
                                          : Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Column(
                    key: _adresKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adres',
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TextFormField(
                          focusNode: _adresFocusNode,
                          initialValue: _adres,
                          onChanged: (value) {
                            setState(() {
                              _adres = value;
                            });
                          },
                          maxLines: 2,
                          minLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Adres bilgisini giriniz',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            filled: true,
                            fillColor: AppColors.textOnPrimary,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OnayToggleWidget(
                    initialValue: _ucretsiz,
                    label: 'Ücretsiz',
                    onChanged: (value) {
                      setState(() {
                        _ucretsiz = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (!_ucretsiz)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 3, 16, 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outlined,
                            color: AppColors.gradientStart,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.fontSize ??
                                              14) +
                                          1,
                                      color: AppColors.gradientStart,
                                      fontWeight: FontWeight.w500,
                                    ),
                                children: [
                                  const TextSpan(
                                    text:
                                        'Yıl içerisinde aldığınız eğitimlerin toplam tutarı ',
                                  ),
                                  TextSpan(
                                    text:
                                        '${_aldigiEgitimUcreti.toStringAsFixed(2)} TL',
                                    style: TextStyle(
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.fontSize ??
                                              14) +
                                          5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: '\'dir.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_ucretsiz) ...[
                    const SizedBox(height: 16),
                    Column(
                      key: _egitimUcretiKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kişi Başı Ücretler',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
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
                        GestureDetector(
                          onTap: () async {
                            // 🔒 Ücretler ekranına gitmeden önce focus kilidi
                            _egitimTeklifIcerikFocusNode.canRequestFocus =
                                false;
                            _ozelEgitimAdiFocusNode.canRequestFocus = false;
                            FocusScope.of(context).unfocus();

                            final result =
                                await Navigator.push<Map<String, dynamic>>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EgitimUcretleriScreen(
                                      initialData: _egitimUcretleriData,
                                      selectedPersonelCount:
                                          _getSelectedPersonelCount(),
                                    ),
                                  ),
                                );

                            if (result != null) {
                              setState(() {
                                _egitimUcretleriData = result;
                              });
                            }

                            // 🔓 Geri dönüldüğünde güvenli kilit açma + unfocus
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                FocusScope.of(context).unfocus();
                                _egitimTeklifIcerikFocusNode.canRequestFocus =
                                    true;
                                _ozelEgitimAdiFocusNode.canRequestFocus = true;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textOnPrimary,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Kişi başı ücretleri giriniz',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eğitim Sonrası Kurum İçi Paylaşım',
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
                      GestureDetector(
                        onTap: () async {
                          final result =
                              await Navigator.push<Map<String, dynamic>>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EgitimSonrasiPaylasimsScreen(
                                        initialData: _egitimSonrasiPaylasimData,
                                      ),
                                ),
                              );

                          if (result != null) {
                            setState(() {
                              _egitimSonrasiPaylasimData = result;
                              // Paylaşım ekranından dönen seçili personel ID'lerini kaydet
                              if (result['selectedPersonelIds'] != null) {
                                _selectedPersonelIdsForPaylasum.clear();
                                _selectedPersonelIdsForPaylasum.addAll(
                                  List<int>.from(
                                    result['selectedPersonelIds'] as List,
                                  ),
                                );
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Paylaşım detaylarını giriniz',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eğitim Teklif Dosya / Fotoğraf Yükle',
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
                      GestureDetector(
                        onTap: _pickFiles,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                size: 24,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dosya Seçmek İçin Dokunun',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '(pdf, jpg, jpeg, png, doc, docx, xls, xlsx)',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedFiles.length,
                          itemBuilder: (context, index) {
                            final file = _selectedFiles[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file_outlined,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    onPressed: () => _removeFile(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dosyaların İçeriğini Belirtiniz',
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
                      TextFormField(
                        controller: _egitimTeklifIcerikController,
                        decoration: InputDecoration(
                          hintText: 'Dosya içeriği hakkında bilgi veriniz',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          contentPadding: const EdgeInsets.all(12),
                          filled: true,
                          fillColor: AppColors.textOnPrimary,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // PDF Dökümanları Card
                  Card(
                    color: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.border, width: 1),
                    ),
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // PDF Genelgesi
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PdfViewerScreen(
                                    title: 'Hizmet İçi Eğitim Genelgesi',
                                    pdfUrl:
                                        'https://esas.eyuboglu.k12.tr/yonerge/hizmet-ici_egitim_genelgesi.pdf',
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: AppColors.gradientStart,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Hizmet İçi Eğitim Genelgesi',
                                    style: TextStyle(
                                      color: AppColors.gradientStart,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey.shade400,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: AppColors.border,
                          indent: 16,
                          endIndent: 16,
                        ),
                        // PDF Protokolü
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PdfViewerScreen(
                                    title: 'Hizmet İçi Eğitim Protokolü',
                                    pdfUrl:
                                        'https://esas.eyuboglu.k12.tr/yonerge/egitim_protokolu_tr_en.pdf',
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: AppColors.gradientStart,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Hizmet İçi Eğitim Protokolü',
                                    style: TextStyle(
                                      color: AppColors.gradientStart,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey.shade400,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Onay Toggle Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Switch(
                        value: _agreeWithDocuments,
                        inactiveTrackColor: AppColors.textOnPrimary,
                        onChanged: (value) {
                          setState(() {
                            _agreeWithDocuments = value;
                          });
                        },
                        activeThumbColor: AppColors.textOnPrimary,
                        activeTrackColor: AppColors.gradientStart,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Genelgeyi ve protokolü okudum, anladım, onaylıyorum',
                          style: TextStyle(
                            color: AppColors.inputLabelColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _agreeWithDocuments
                          ? AppColors.primaryGradient
                          : LinearGradient(
                              colors: [
                                AppColors.gradientStart.withValues(alpha: 0.2),
                                AppColors.gradientEnd.withValues(alpha: 0.2),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _agreeWithDocuments ? _submitForm : null,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEgitimAdiBottomSheet() async {
    // 🔒 Enhanced focus control
    _egitimTeklifIcerikFocusNode.canRequestFocus = false;
    _ozelEgitimAdiFocusNode.canRequestFocus = false;
    FocusScope.of(context).unfocus();

    // 🔒 Critical: Wait 1 frame for focus state to settle
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    String searchQuery = '';

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredList = _egitimAdlari.where((egitimAdi) {
              return egitimAdi.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Eğitim Adı Seçin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Eğitim adı ara...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setModalState(() => searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.gradientStart,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setModalState(() => searchQuery = value);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  // List
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Text(
                              'Sonuç bulunamadı',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredList.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final egitimAdi = filteredList[index];
                              final isSelected = _secilenEgitimAdi == egitimAdi;

                              return ListTile(
                                title: Text(
                                  egitimAdi,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.gradientStart
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.gradientStart,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _secilenEgitimAdi = egitimAdi;
                                    // Seçim yapıldığında controller'ı temizle
                                    _ozelEgitimAdiController.clear();
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Ensure keyboard stays hidden after BottomSheet closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        _egitimTeklifIcerikFocusNode.canRequestFocus = true;
        _ozelEgitimAdiFocusNode.canRequestFocus = true;
      }
    });
  }

  void _showEgitimTuruBottomSheet() async {
    // 🔒 Enhanced focus control
    _egitimTeklifIcerikFocusNode.canRequestFocus = false;
    _ozelEgitimAdiFocusNode.canRequestFocus = false;
    FocusScope.of(context).unfocus();

    // 🔒 Critical: Wait 1 frame for focus state to settle
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: const BoxDecoration(
            color: AppColors.textOnPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Eğitim Türü Seçin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              // List
              Expanded(
                child: _egitimTurleri.isEmpty
                    ? const Center(
                        child: Text(
                          'Eğitim türü bulunamadı',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _egitimTurleri.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final tur = _egitimTurleri[index];
                          final isSelected = _secilenEgitimTuru == tur;

                          return ListTile(
                            title: Text(
                              tur,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.gradientStart
                                    : AppColors.textPrimary,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.gradientStart,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _secilenEgitimTuru = tur;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );

    // Ensure keyboard stays hidden after BottomSheet closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        _egitimTeklifIcerikFocusNode.canRequestFocus = true;
        _ozelEgitimAdiFocusNode.canRequestFocus = true;
      }
    });
  }

  Future<void> _fetchEgitimAdlari() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/EgitimIstek/EgitimAdlariDoldur');

      if (response.statusCode == 200) {
        final data = response.data;
        List<String> egitimAdlari = [];

        if (data is Map<String, dynamic> && data.containsKey('egitimAdi')) {
          final adlar = data['egitimAdi'];
          if (adlar is List) {
            egitimAdlari = List<String>.from(adlar);
          }
        }

        if (mounted) {
          setState(() {
            _egitimAdlari = ['DİĞER', ...egitimAdlari];
            _egitimAdlariYuklendi = true;
          });
        }
      }
    } catch (e) {
      developer.log(
        'Eğitim adları yükleme hatası',
        name: 'EgitimTalepScreen._fetchEgitimAdlari',
        error: e,
      );
      if (mounted) {
        _showStatusBottomSheet('Eğitim adları yüklenemedi: $e', isError: true);
      }
    }
  }

  Future<void> _fetchEgitimTurleri() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/EgitimIstek/EgitimTurleriDoldur');

      if (response.statusCode == 200) {
        final data = response.data;
        List<String> egitimTurleri = [];

        if (data is Map<String, dynamic> && data.containsKey('egitimTurleri')) {
          final turler = data['egitimTurleri'];
          if (turler is List) {
            egitimTurleri = List<String>.from(turler);
          }
        }

        if (mounted) {
          setState(() {
            _egitimTurleri = egitimTurleri;
            _egitimTurleriYuklendi = true;
          });
        }
      }
    } catch (e) {
      developer.log(
        'Eğitim türleri yükleme hatası',
        name: 'EgitimTalepScreen._fetchEgitimTurleri',
        error: e,
      );
      if (mounted) {
        _showStatusBottomSheet('Eğitim türleri yüklenemedi: $e', isError: true);
      }
    }
  }

  Future<void> _fetchSehirler() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/TalepYonetimi/SehirleriGetir');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          if (mounted) {
            setState(() {
              _sehirler = List<Map<String, dynamic>>.from(data);
              _sehirler.sort((a, b) {
                final idA = a['id'] as int? ?? 0;
                final idB = b['id'] as int? ?? 0;
                return idA.compareTo(idB);
              });
              _sehirlerYuklendi = true;
            });
          }
        }
      }
    } catch (e) {
      developer.log(
        'Şehirler yükleme hatası',
        name: 'EgitimTalepScreen._fetchSehirler',
        error: e,
      );
      if (mounted) {
        _showStatusBottomSheet('Şehirler yüklenemedi: $e', isError: true);
      }
    }
  }

  Future<void> _fetchAlinanEgitimUcreti() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/EgitimIstek/AlinanEgitimUcretiGetir');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> &&
            data.containsKey('aldigiEgitimUcreti')) {
          if (mounted) {
            setState(() {
              _aldigiEgitimUcreti = (data['aldigiEgitimUcreti'] ?? 0)
                  .toDouble();
              _ucretYukleniyor = false;
            });
          }
        }
      }
    } catch (e) {
      developer.log(
        'Alınan eğitim ücreti yükleme hatası',
        name: 'EgitimTalepScreen._fetchAlinanEgitimUcreti',
        error: e,
      );
      if (mounted) {
        setState(() {
          _ucretYukleniyor = false;
        });
      }
    }
  }

  Future<void> _showEducationCostWarning() async {
    return showModalBottomSheet<void>(
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
                'Lütfen eğitimin ücretini giriniz',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  // Eğitim ücretleri ekranını personel sayısı değişikliği ile güncelle
  Future<void> _refreshEducationCostsScreen(int personelCount) async {
    if (!mounted || _egitimUcretleriData == null) return;

    // Mevcut eğitim ücretleri ekranını kapat ve yeni personel sayısı ile aç
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EgitimUcretleriScreen(
          initialData: _egitimUcretleriData,
          selectedPersonelCount: personelCount,
          shouldFocusInput: false,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _egitimUcretleriData = result;
      });
    }
  }

  // Seçili personel sayısını hesapla (toplu istek ve seçim durumuna göre)
  int _getSelectedPersonelCount() {
    if (!_topluIstekte) {
      return 1; // Toplu istek kapalıysa 1
    }
    if (_selectedPersonelIdsForTopluIstek.isEmpty) {
      return 1; // Toplu istek açık ama personel seçili değilse 1
    }
    return _selectedPersonelIdsForTopluIstek.length; // Seçili personel sayısı
  }

  // Helper method: Widget'ın konumuna scroll yap ve focus'u ayarla
  Future<void> _scrollAndFocusToWidget(
    GlobalKey key,
    FocusNode? focusNode,
  ) async {
    final context = key.currentContext;
    if (context != null && mounted) {
      // Widget'ın konumunu bul ve scroll yap
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Focus'u ayarla
      if (focusNode != null && mounted) {
        FocusScope.of(this.context).requestFocus(focusNode);
      }
    }
  }

  Future<void> _submitForm() async {
    // 1️⃣ Eğitimin Adı seçimi zorunlu validasyonu
    if (_secilenEgitimAdi == null) {
      await _scrollAndFocusToWidget(_egitimAdiKey, null);
      if (mounted) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen eğitimin adını seçiniz',
        );
      }
      return;
    }

    // DİĞER seçildiğinde eğitim adı zorunlu validasyonu
    if (_secilenEgitimAdi == 'DİĞER' && _ozelEgitimAdiController.text.isEmpty) {
      await _scrollAndFocusToWidget(_egitimAdiKey, _ozelEgitimAdiFocusNode);
      if (mounted) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen eğitimin adını giriniz',
        );
      }
      return;
    }

    // 2️⃣ Eğitim Türü seçimi zorunlu validasyonu
    if (_secilenEgitimTuru == null) {
      await _scrollAndFocusToWidget(_egitimTuruKey, null);
      if (mounted) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen eğitim türünü seçiniz',
        );
      }
      return;
    }

    // 3️⃣ Eğitim Şirketinin Adı zorunlu validasyonu
    if (_egitimSirketiAdi.trim().isEmpty) {
      await _scrollAndFocusToWidget(
        _egitimSirketiAdiKey,
        _egitimSirketiAdiFocusNode,
      );
      if (mounted) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen eğitim şirketinin adını giriniz',
        );
      }
      return;
    }

    // 4️⃣ Eğitimin Konusu zorunlu validasyonu
    if (_egitimKonusu.trim().isEmpty) {
      await _scrollAndFocusToWidget(_egitimKonusuKey, _egitimKonusuFocusNode);
      if (mounted) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen eğitimin konusunu giriniz',
        );
      }
      return;
    }

    // 4️⃣.1 Web sitesi opsiyonel ama girildiyse format doğru olmalı
    final webSitesiTrimmed = _webSitesi.trim();
    if (webSitesiTrimmed.isNotEmpty) {
      final uri = Uri.tryParse(webSitesiTrimmed);
      final hasValidProtocol =
          uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
      final hasValidHost =
          uri != null && uri.host.isNotEmpty && uri.host.contains('.');

      if (!hasValidProtocol || !hasValidHost) {
        // Hata durumunda: uyarı + web sitesi inputuna focus
        FocusScope.of(context).unfocus();
        await Future.delayed(Duration.zero);
        await _scrollAndFocusToWidget(_webSitesiKey, null);
        if (mounted) {
          await ValidationUyariWidget.goster(
            context: context,
            message: 'web sitesi adresini kontrol ediniz',
          );
        }

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              FocusScope.of(context).requestFocus(_webSitesiFocusNode);
            }
          });
        }
        return;
      }
    }

    // Web sitesi geçerliyse (veya boşsa): hiçbir input focus olmasın, klavye kapansın
    FocusScope.of(context).unfocus();

    // 5️⃣ Şehir / Ülke-Şehir zorunlu validasyonu
    // - Online: şehir zorunlu
    // - Online değilse: Yurt dışı kapalıysa şehir zorunlu
    // - Online değilse: Yurt dışı açıksa ülke/şehir zorunlu
    if (_online) {
      if (_secilenSehir == null) {
        // Şehir seçimi bir TextField olmadığı için keyboard açık kalabiliyor.
        // Online modda da şehir zorunlu olduğundan klavyeyi kapat.
        FocusScope.of(context).unfocus();
        await Future.delayed(Duration.zero);
        await _scrollAndFocusToWidget(_sehirKey, null);
        if (mounted) {
          await ValidationUyariWidget.goster(
            context: context,
            message: 'Lütfen şehir seçiniz',
          );
        }

        // Uyarı kapandıktan sonra şehir seçim ekranını otomatik aç.
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _secilenSehir == null) {
              _showSehirBottomSheet();
            }
          });
        }
        return;
      }
    } else {
      if (_egitimYeriYurtDisi) {
        if (_egitimUlkeSehir.trim().isEmpty) {
          await _scrollAndFocusToWidget(_ulkeSehirKey, _ulkeSehirFocusNode);
          if (mounted) {
            await ValidationUyariWidget.goster(
              context: context,
              message: 'Lütfen ülke / şehir bilgisini giriniz',
            );
          }
          return;
        }
      } else {
        if (_secilenSehir == null) {
          // Şehir seçimi bir TextField olmadığı için keyboard açık kalabiliyor.
          // Yurt dışı kapalıyken şehir validasyonu patladığında klavyeyi kapat.
          FocusScope.of(context).unfocus();
          await Future.delayed(Duration.zero);
          await _scrollAndFocusToWidget(_sehirKey, null);
          if (mounted) {
            await ValidationUyariWidget.goster(
              context: context,
              message: 'Lütfen şehir seçiniz',
            );
          }

          // Uyarı kapandıktan sonra şehir seçim ekranını otomatik aç.
          // (Şehir alanı text input olmadığı için focus yerine seçim sheet'i açıyoruz.)
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _secilenSehir == null) {
                _showSehirBottomSheet();
              }
            });
          }
          return;
        }
      }
    }

    // 6️⃣ Adres zorunlu validasyonu
    if (_adres.trim().isEmpty) {
      await _scrollAndFocusToWidget(_adresKey, _adresFocusNode);
      if (mounted) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen adresi giriniz',
        );
      }
      return;
    }

    // 7️⃣ Eğitimin Ücreti validasyonu
    if (!_ucretsiz) {
      final egitimUcretiAna =
          _egitimUcretleriData?['egitimUcretiAna'] as String? ?? '';
      if (egitimUcretiAna.trim().isEmpty) {
        if (mounted) {
          await _showEducationCostWarning();
          if (mounted) {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (context) => EgitimUcretleriScreen(
                  initialData: _egitimUcretleriData,
                  selectedPersonelCount: _getSelectedPersonelCount(),
                  shouldFocusInput: true,
                ),
              ),
            );

            if (result != null && mounted) {
              setState(() {
                _egitimUcretleriData = result;
              });
            }
          }
        }
        return;
      }
    }

    // 8️⃣ Eğitim Sonrası Kurum İçi Paylaşım (zorunlu)
    final isPaylasimOk = await _ensureEgitimSonrasiPaylasimIsComplete();
    if (!isPaylasimOk) {
      return;
    }

    // Form gönderme işlemi - Özet ekranını göster
    _showSummaryAndSubmit();
  }

  String? _getEgitimSonrasiPaylasimMissingErrorType() {
    final data = _egitimSonrasiPaylasimData;
    if (data == null) {
      return 'location';
    }

    final egitimYeri = data['egitimYeri'] as String? ?? '';
    if (egitimYeri.trim().isEmpty) {
      return 'location';
    }

    final selectedPersonelIds =
        data['selectedPersonelIds'] as List? ?? const [];
    if (selectedPersonelIds.isEmpty) {
      return 'personel';
    }

    return null;
  }

  Future<bool> _ensureEgitimSonrasiPaylasimIsComplete() async {
    final errorType = _getEgitimSonrasiPaylasimMissingErrorType();
    if (errorType == null) {
      return true;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EgitimSonrasiPaylasimsScreen(
          initialData: _egitimSonrasiPaylasimData,
          shouldFocusInput: errorType == 'location',
          initialValidationErrorType: errorType,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _egitimSonrasiPaylasimData = result;
        // Paylaşım yapılacak kişileri de senkronize et
        final selectedPersonelIds =
            result['selectedPersonelIds'] as List? ?? [];
        _selectedPersonelIdsForPaylasum.clear();
        _selectedPersonelIdsForPaylasum.addAll(selectedPersonelIds.cast<int>());
      });
    }

    // Kullanıcı geri döndüğünde tekrar kontrol et (tamamlamadıysa gönderme durur)
    return _getEgitimSonrasiPaylasimMissingErrorType() == null;
  }

  Future<void> _showSummaryAndSubmit() async {
    final List<int> paylasimPersonelIds =
        _selectedPersonelIdsForPaylasum.toList(growable: false).isNotEmpty
        ? _selectedPersonelIdsForPaylasum.toList(growable: false)
        : List<int>.from(
            (_egitimSonrasiPaylasimData?['selectedPersonelIds'] as List?) ??
                const <int>[],
          );

    // Özet ekranında personel adlarını gösterebilmek için (Toplu İstek kapalıyken
    // bile Paylaşım personelleri seçilebildiğinden) personel verisini gerekirse yükle.
    final shouldLoadPersonelData =
        _personeller.isEmpty && paylasimPersonelIds.isNotEmpty;

    if (shouldLoadPersonelData) {
      final result = await ref
          .read(aracTalepRepositoryProvider)
          .personelSecimVerisiGetir();

      if (result is Success<PersonelSecimData>) {
        final data = result.data;
        if (mounted) {
          setState(() {
            _personeller = data.personeller;
            _gorevler = data.gorevler;
            _gorevYerleri = data.gorevYerleri;
          });
        } else {
          _personeller = data.personeller;
          _gorevler = data.gorevler;
          _gorevYerleri = data.gorevYerleri;
        }
      }
    }

    String pad2(int value) => value.toString().padLeft(2, '0');

    String isoDateOnly(DateTime date) {
      return DateTime(date.year, date.month, date.day).toIso8601String();
    }

    double parseMoney(String? ana, String? kusurat) {
      final main = int.tryParse((ana ?? '').replaceAll('.', '').trim()) ?? 0;
      final fracStr = (kusurat ?? '').trim();
      final fracParsed = int.tryParse(fracStr.isEmpty ? '0' : fracStr) ?? 0;
      final normalizedFrac = fracParsed.clamp(0, 99);
      return main + (normalizedFrac / 100.0);
    }

    Map<String, dynamic> buildPersonelSatir(int personelId) {
      final personel = _personeller.cast<PersonelItem?>().firstWhere(
        (p) => p?.personelId == personelId,
        orElse: () => null,
      );

      final adiSoyadi = personel == null
          ? ''
          : '${personel.adi} ${personel.soyadi}'.trim();

      final gorevi = (personel?.gorevId == null)
          ? ''
          : _gorevler
                    .cast<GorevItem?>()
                    .firstWhere(
                      (g) => g?.id == personel!.gorevId,
                      orElse: () => null,
                    )
                    ?.gorevAdi
                    .toString() ??
                '';

      final gorevYeri = (personel?.gorevYeriId == null)
          ? ''
          : _gorevYerleri
                    .cast<GorevYeriItem?>()
                    .firstWhere(
                      (gy) => gy?.id == personel!.gorevYeriId,
                      orElse: () => null,
                    )
                    ?.gorevYeriAdi
                    .toString() ??
                '';

      return {
        'egitimIstekId': 0,
        'personelId': personelId,
        'adiSoyadi': adiSoyadi,
        'gorevi': gorevi,
        'gorevYeri': gorevYeri,
        'calistigiSure': 0,
      };
    }

    // Özet ekranında da gösterilecek şekilde API payload'u burada üret.
    final ParaBirimi? egitimPb =
        _egitimUcretleriData?['selectedParaBirimi'] as ParaBirimi?;
    final ParaBirimi? ulasimPb =
        _egitimUcretleriData?['selectedUlasimParaBirimi'] as ParaBirimi?;
    final ParaBirimi? konaklamaPb =
        _egitimUcretleriData?['selectedKonaklamaParaBirimi'] as ParaBirimi?;
    final ParaBirimi? yemekPb =
        _egitimUcretleriData?['selectedYemekParaBirimi'] as ParaBirimi?;
    final OdemeTuru? odemeTuru =
        _egitimUcretleriData?['selectedOdemeTuru'] as OdemeTuru?;
    final bool vadeli = (_egitimUcretleriData?['vadeli'] as bool?) ?? false;
    final int odemeVadesi = (_egitimUcretleriData?['odemeVadesi'] as int?) ?? 0;

    final egitimUcreti = _ucretsiz
        ? 0.0
        : parseMoney(
            _egitimUcretleriData?['egitimUcretiAna'] as String?,
            _egitimUcretleriData?['egitimUcretiKusurat'] as String?,
          );
    final ulasimUcreti = _ucretsiz
        ? 0.0
        : parseMoney(
            _egitimUcretleriData?['ulasimUcretiAna'] as String?,
            _egitimUcretleriData?['ulasimUcretiKusurat'] as String?,
          );
    final konaklamaUcreti = _ucretsiz
        ? 0.0
        : parseMoney(
            _egitimUcretleriData?['konaklamaUcretiAna'] as String?,
            _egitimUcretleriData?['konaklamaUcretiKusurat'] as String?,
          );
    final yemekUcreti = _ucretsiz
        ? 0.0
        : parseMoney(
            _egitimUcretleriData?['yemekUcretiAna'] as String?,
            _egitimUcretleriData?['yemekUcretiKusurat'] as String?,
          );

    final toplamUcret = _ucretsiz
        ? 0.0
        : parseMoney(
            _egitimUcretleriData?['kisiBasiToplamAna'] as String?,
            _egitimUcretleriData?['kisiBasiToplamKusurat'] as String?,
          );
    final genelToplamUcret = _ucretsiz
        ? 0.0
        : parseMoney(
            _egitimUcretleriData?['genelToplamAna'] as String?,
            _egitimUcretleriData?['genelToplamKusurat'] as String?,
          );

    final paylasimData = _egitimSonrasiPaylasimData ?? const {};
    final DateTime? paylasimBaslangicTarihi =
        paylasimData['baslangicTarihi'] as DateTime?;
    final DateTime? paylasimBitisTarihi =
        paylasimData['bitisTarihi'] as DateTime?;
    final nowDateOnly = isoDateOnly(DateTime.now());

    final payload = <String, dynamic>{
      'egitimBaslangicTarihi': isoDateOnly(_baslangicTarihi),
      'egitimBitisTarihi': isoDateOnly(_bitisTarihi),
      'egitimBaslangicSaat': pad2(_baslangicSaat),
      'egitimBaslangicDakika': pad2(_baslangicDakika),
      'egitimBitisSaat': pad2(_bitisSaat),
      'egitimBitisDakika': pad2(_bitisDakika),
      'egitimSuresiGun': _egitimGun.toString(),
      'egitimSuresiSaat': _egitimSaat.toString(),
      'girilmeyenToplamDersSaati': _girileymeyenDersSaati,
      'egitiminAdi': _secilenEgitimAdi ?? '',
      'sirketAdi': _egitimSirketiAdi,
      'egitimIcerigi': _egitimKonusu,
      'webSitesi': _webSitesi.trim().isEmpty ? '' : _webSitesi.trim(),
      'egitimYeri': _egitimYeriYurtDisi ? 'Yurt Dışı' : 'Yurt İçi',
      // Lokasyon mapping:
      // - Online: seçilen şehir `sehir` alanına, `ulke` boş
      // - Yurt dışı: Ülke/Şehir inputu `ulke` alanına, `sehir` boş
      // - Yurt içi: seçilen şehir `sehir` alanına, `ulke` boş
      'ulke': _online ? '' : (_egitimYeriYurtDisi ? _egitimUlkeSehir : ''),
      'sehir': _online
          ? (_secilenSehir ?? '')
          : (_egitimYeriYurtDisi ? '' : (_secilenSehir ?? '')),
      'adres': _adres,
      'egitimUcreti': egitimUcreti,
      'egitimParaBirimiId': _ucretsiz ? 0 : (egitimPb?.id ?? 0),
      'ulasimUcreti': ulasimUcreti,
      'ulasimParaBirimiId': _ucretsiz ? 0 : (ulasimPb?.id ?? 0),
      'konaklamaUcreti': konaklamaUcreti,
      'konaklamaParaBirimiId': _ucretsiz ? 0 : (konaklamaPb?.id ?? 0),
      'yemekUcreti': yemekUcreti,
      'yemekParaBirimiId': _ucretsiz ? 0 : (yemekPb?.id ?? 0),
      'toplamUcret': toplamUcret,
      'genelToplamUcret': genelToplamUcret,
      'ucretsiz': _ucretsiz,
      'odemeSekliId': _ucretsiz ? 0 : (odemeTuru?.id ?? 0),
      'kdv': true,
      'pesin': _ucretsiz ? true : !vadeli,
      'vadeGun': _ucretsiz ? 0 : (vadeli ? odemeVadesi : 0),
      'ekBilgi': (_egitimUcretleriData?['digerEkBilgiler'] as String?) ?? '',
      'unvan': (_egitimUcretleriData?['hesapAdi'] as String?) ?? '',
      'hesapNo': (_egitimUcretleriData?['iban'] as String?) ?? '',
      'paylasimBaslangicTarihi': paylasimBaslangicTarihi == null
          ? nowDateOnly
          : isoDateOnly(paylasimBaslangicTarihi),
      'paylasimBitisTarihi': paylasimBitisTarihi == null
          ? nowDateOnly
          : isoDateOnly(paylasimBitisTarihi),
      'paylasimBaslangicSaat': pad2(
        (paylasimData['baslangicSaat'] as int?) ?? 0,
      ),
      'paylasimBaslangicDakika': pad2(
        (paylasimData['baslangicDakika'] as int?) ?? 0,
      ),
      'paylasimBitisSaat': pad2((paylasimData['bitisSaat'] as int?) ?? 0),
      'paylasimBitisDakika': pad2((paylasimData['bitisDakika'] as int?) ?? 0),
      'paylasimYeri': (paylasimData['egitimYeri'] as String?) ?? '',
      'paylasimYapilacakPersonelSatir': paylasimPersonelIds
          .map(buildPersonelSatir)
          .toList(),
      'egitimAlacakPersonelSatir': _topluIstekte
          ? _selectedPersonelIdsForTopluIstek.map(buildPersonelSatir).toList()
          : <Map<String, dynamic>>[],
      'protokolTipi': 'Hizmet İçi Eğitim Protokolü',
      'departman': '',
      'egitimTuru': _secilenEgitimTuru ?? '',
      'protokolImza': _agreeWithDocuments,
      'online': _online,
      'topluIstek': _topluIstekte,
      'egitiminAdiDiger': _secilenEgitimAdi == 'DİĞER'
          ? _ozelEgitimAdiController.text
          : '',
      'aldigiEgitimUcreti': _aldigiEgitimUcreti,
    };

    // Özet verilerini hazırla
    final summaryItems = <GenericSummaryItem>[];

    // 1. Eğitimin Adı
    if (_secilenEgitimAdi != null && _secilenEgitimAdi!.isNotEmpty) {
      summaryItems.add(
        GenericSummaryItem(
          label: 'Eğitimin Adı',
          value: _secilenEgitimAdi == 'Diğer'
              ? _ozelEgitimAdiController.text
              : _secilenEgitimAdi!,
          multiLine: true,
        ),
      );
    }

    // 2. Eğitim Türü
    if (_secilenEgitimTuru != null && _secilenEgitimTuru!.isNotEmpty) {
      summaryItems.add(
        GenericSummaryItem(
          label: 'Eğitim Türü',
          value: _secilenEgitimTuru!,
          multiLine: false,
        ),
      );
    }

    // 3. Eğitim Şirketi
    if (_egitimSirketiAdi.trim().isNotEmpty) {
      summaryItems.add(
        GenericSummaryItem(
          label: 'Eğitim Şirketinin Adı',
          value: _egitimSirketiAdi,
          multiLine: true,
        ),
      );
    }

    // 4. Eğitimin Konusu
    if (_egitimKonusu.trim().isNotEmpty) {
      summaryItems.add(
        GenericSummaryItem(
          label: 'Eğitimin Konusu',
          value: _egitimKonusu,
          multiLine: true,
        ),
      );
    }

    // 5. Eğitim Başlangıç Tarihi
    summaryItems.add(
      GenericSummaryItem(
        label: 'Eğitim Başlangıç Tarihi',
        value:
            '${_baslangicTarihi.day.toString().padLeft(2, '0')}.${_baslangicTarihi.month.toString().padLeft(2, '0')}.${_baslangicTarihi.year}',
        multiLine: false,
      ),
    );

    // 6. Eğitim Bitiş Tarihi
    summaryItems.add(
      GenericSummaryItem(
        label: 'Eğitim Bitiş Tarihi',
        value:
            '${_bitisTarihi.day.toString().padLeft(2, '0')}.${_bitisTarihi.month.toString().padLeft(2, '0')}.${_bitisTarihi.year}',
        multiLine: false,
      ),
    );

    // 7. Eğitim Başlangıç Saati
    summaryItems.add(
      GenericSummaryItem(
        label: 'Eğitim Başlangıç Saati',
        value:
            '${_baslangicSaat.toString().padLeft(2, '0')}:${_baslangicDakika.toString().padLeft(2, '0')}',
        multiLine: false,
      ),
    );

    // 8. Eğitim Bitiş Saati
    summaryItems.add(
      GenericSummaryItem(
        label: 'Eğitim Bitiş Saati',
        value:
            '${_bitisSaat.toString().padLeft(2, '0')}:${_bitisDakika.toString().padLeft(2, '0')}',
        multiLine: false,
      ),
    );

    // 9. Eğitim Süresi
    if (_egitimGun > 0 || _egitimSaat > 0) {
      String sure = '';
      if (_egitimGun > 0) sure += '$_egitimGun gün ';
      if (_egitimSaat > 0) sure += '$_egitimSaat saat';
      summaryItems.add(
        GenericSummaryItem(
          label: 'Eğitim Süresi',
          value: sure.trim(),
          multiLine: false,
        ),
      );
    }

    // 10. Adres
    if (_adres.trim().isNotEmpty) {
      summaryItems.add(
        GenericSummaryItem(label: 'Adres', value: _adres, multiLine: true),
      );
    }

    // 11. Şehir/Yer Bilgisi
    String yerBilgisi = '';
    if (_online) {
      yerBilgisi = _secilenSehir == null
          ? 'Online'
          : 'Online - ${_secilenSehir!}';
    } else if (_egitimYeriYurtDisi) {
      yerBilgisi =
          'Yurt Dışı${_egitimUlkeSehir.isNotEmpty ? ' - $_egitimUlkeSehir' : ''}';
    } else if (_secilenSehir != null) {
      yerBilgisi = _secilenSehir!;
    }
    if (yerBilgisi.isNotEmpty) {
      summaryItems.add(
        GenericSummaryItem(
          label: 'Eğitimin Yapılacağı Yer',
          value: yerBilgisi,
          multiLine: false,
        ),
      );
    }

    // 12. Eğitim Ücreti
    if (!_ucretsiz && _egitimUcretleriData != null) {
      final egitimUcretiAna =
          _egitimUcretleriData!['egitimUcretiAna'] as String? ?? '0';
      final egitimUcretiKusurat =
          _egitimUcretleriData!['egitimUcretiKusurat'] as String? ?? '';
      final paraBirimi = _egitimUcretleriData!['selectedParaBirimi'];

      if (egitimUcretiAna != '0') {
        final kusuratPadded = egitimUcretiKusurat.isEmpty
            ? '00'
            : egitimUcretiKusurat.padLeft(2, '0');
        String ucretStr = '$egitimUcretiAna,$kusuratPadded';
        if (paraBirimi != null) {
          final kod = paraBirimi.kod.replaceAll('TRL', 'TL');
          ucretStr += ' $kod';
        }
        summaryItems.add(
          GenericSummaryItem(
            label: 'Eğitim Ücreti',
            value: ucretStr,
            multiLine: false,
          ),
        );
      }
    } else if (_ucretsiz) {
      summaryItems.add(
        GenericSummaryItem(
          label: 'Eğitim Ücreti',
          value: 'Ücretsiz',
          multiLine: false,
        ),
      );
    }

    // 13. Web Sitesi
    if (_webSitesi.trim().isNotEmpty) {
      summaryItems.add(
        GenericSummaryItem(
          label: 'Web Sitesi',
          value: _webSitesi,
          multiLine: false,
        ),
      );
    }

    // 14. Toplu İstek ve Personel Bilgileri
    if (_topluIstekte && _selectedPersonelIdsForTopluIstek.isNotEmpty) {
      // Seçilen personel isimlerini al
      final selectedPersonelNames = _personeller
          .where(
            (p) => _selectedPersonelIdsForTopluIstek.contains(p.personelId),
          )
          .map((p) => '${p.adi} ${p.soyadi}')
          .join('\n');

      if (selectedPersonelNames.isNotEmpty) {
        summaryItems.add(
          GenericSummaryItem(
            label: 'Eğitim Alacak Personel',
            value: selectedPersonelNames,
            multiLine: true,
          ),
        );
      }
    }

    // 15. Eğitim Sonrası Paylaşım Yeri
    if (_egitimSonrasiPaylasimData != null) {
      final egitimYeri =
          _egitimSonrasiPaylasimData!['egitimYeri'] as String? ?? '';
      if (egitimYeri.isNotEmpty) {
        summaryItems.add(
          GenericSummaryItem(
            label: 'Eğitim Sonrası Paylaşım Yeri',
            value: egitimYeri,
            multiLine: true,
          ),
        );
      }
    }

    // 16. Eğitim Sonrası Paylaşım Yapılacak Kişiler (Her iki durumda da gösterilsin)
    if (paylasimPersonelIds.isNotEmpty) {
      final selectedPersonelNames = _personeller
          .where((p) => paylasimPersonelIds.contains(p.personelId))
          .map((p) => '${p.adi} ${p.soyadi}')
          .join('\n');

      summaryItems.add(
        GenericSummaryItem(
          label: 'Eğitim Sonrası Paylaşım Yapılacak Kişiler',
          value: selectedPersonelNames.isNotEmpty
              ? selectedPersonelNames
              : 'Seçili kişi sayısı: ${paylasimPersonelIds.length}',
          multiLine: true,
        ),
      );
    }

    // 17. Yüklenen Dosyalar
    if (_selectedFiles.isNotEmpty) {
      summaryItems.add(
        GenericSummaryItem(
          label: 'Yüklenen Dosyalar',
          value: _selectedFiles.map((f) => f.name).join('\n'),
          multiLine: true,
        ),
      );
    }

    // 18. Eğitim Teklifi İçeriği
    if (_egitimTeklifIcerikController.text.trim().isNotEmpty) {
      summaryItems.add(
        GenericSummaryItem(
          label: 'Eğitim Teklifi İçeriği',
          value: _egitimTeklifIcerikController.text,
          multiLine: true,
        ),
      );
    }

    if (!mounted) return;

    // Özet ekranını göster
    await showGenericSummaryBottomSheet(
      context: context,
      requestData: payload,
      title: 'Eğitim Talebi Özeti',
      summaryItems: summaryItems,
      showRequestData: true,
      confirmButtonLabel: 'Gönder',
      cancelButtonLabel: 'Düzenle',
      onConfirm: () async {
        final repo = ref.read(egitimIstekRepositoryProvider);
        final result = await repo.egitimIstekEkle(
          payload: payload,
          formFiles: _selectedFiles,
          dosyaAciklama: '',
        );

        if (result is Failure<int>) {
          throw Exception(result.message);
        }
      },
      onSuccess: () {
        _showStatusBottomSheet(
          'Eğitim isteği başarılı bir şekilde oluşturuldu',
          isError: false,
          onOk: () {
            ref.invalidate(egitimDevamEdenTaleplerProvider);
            ref.invalidate(egitimTamamlananTaleplerProvider);
            context.go('/egitim_istek');
          },
        );
      },
      onError: (error) {
        _showStatusBottomSheet('Hata: $error', isError: true);
      },
    );
  }

  Future<void> _showStatusBottomSheet(
    String message, {
    bool isError = false,
    VoidCallback? onOk,
  }) async {
    if (!mounted) return;
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
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(statusContext);
                      if (!isError && onOk != null) {
                        Future.delayed(const Duration(milliseconds: 300), onOk);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  void _showSehirBottomSheet() async {
    // 🔒 Enhanced focus control
    _egitimTeklifIcerikFocusNode.canRequestFocus = false;
    _ozelEgitimAdiFocusNode.canRequestFocus = false;
    FocusScope.of(context).unfocus();

    // 🔒 Critical: Wait 1 frame for focus state to settle
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    String searchQuery = '';

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredList = _sehirler.where((sehir) {
              final sehirAdi = sehir['sehirAdi'] as String? ?? '';
              return sehirAdi.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Şehir Seçiniz',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Search TextField
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Ara...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.gradientStart,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // List
                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(
                            child: Text(
                              'Şehir bulunamadı',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredList.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final sehir = filteredList[index];
                              final sehirAdi =
                                  sehir['sehirAdi'] as String? ?? '';
                              final isSelected = _secilenSehir == sehirAdi;

                              return ListTile(
                                title: Text(
                                  sehirAdi,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.gradientStart
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.gradientStart,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _secilenSehir = sehirAdi;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Ensure keyboard stays hidden after BottomSheet closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        _egitimTeklifIcerikFocusNode.canRequestFocus = true;
        _ozelEgitimAdiFocusNode.canRequestFocus = true;
      }
    });
  }
}
