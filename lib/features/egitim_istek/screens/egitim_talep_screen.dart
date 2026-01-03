import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/time_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/duration_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/features/egitim_istek/screens/egitim_ucretleri_screen.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';

import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';
import 'package:esas_v1/features/egitim_istek/screens/egitim_sonrasi_paylasim_screen.dart';

class EgitimTalepScreen extends ConsumerStatefulWidget {
  const EgitimTalepScreen({super.key});

  @override
  ConsumerState<EgitimTalepScreen> createState() => _EgitimTalepScreenState();
}

class _EgitimTalepScreenState extends ConsumerState<EgitimTalepScreen> {
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
  List<String> _egitimTurleri = [];
  bool _egitimTurleriYuklendi = false;
  double _aldigiEgitimUcreti = 0;
  bool _ucretYukleniyor = true;
  bool _agreeWithDocuments = false;

  final Set<int> _selectedPersonelIds = {};
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

  @override
  void initState() {
    super.initState();
    _baslangicTarihi = DateTime.now();
    _bitisTarihi = DateTime.now().add(const Duration(days: 7));
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
                color: Colors.white,
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
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
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                          color: Colors.white,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dosya seçimi başarısız: $e')));
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF1F5),
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'Eğitim İsteği',
                    style: TextStyle(
                      color: Colors.white,
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
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          // 🔒 Enhanced focus control
                          _egitimTeklifIcerikFocusNode.canRequestFocus = false;
                          _ozelEgitimAdiFocusNode.canRequestFocus = false;
                          FocusScope.of(context).unfocus();

                          // 🔒 Critical: Wait 1 frame for focus state to settle
                          await Future.delayed(Duration.zero);

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
                                  color: Colors.white,
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
                                        color: Color(0xFF2D3748),
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
                                            color: Colors.white,
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
                  DersSaatiSpinnerWidget(
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
                          _selectedPersonelIds.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_topluIstekte)
                    PersonelSelectorWidget(
                      initialSelection: _selectedPersonelIds,
                      fetchFunction: () => ref
                          .read(aracTalepRepositoryProvider)
                          .personelSecimVerisiGetir(),
                      onSelectionChanged: (ids) {
                        setState(() {
                          _selectedPersonelIds.clear();
                          _selectedPersonelIds.addAll(ids);
                        });
                      },
                      onDataLoaded: (data) {
                        setState(() {
                          _personeller = data.personeller;
                          _gorevler = data.gorevler;
                          _gorevYerleri = data.gorevYerleri;
                        });
                      },
                    ),
                  if (_topluIstekte) const SizedBox(height: 24),
                  Column(
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
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
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
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade600,
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
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
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
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _secilenEgitimTuru ?? 'Türü seçiniz',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _secilenEgitimTuru != null
                                              ? Colors.black
                                              : Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade600,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _egitimSirketiAdi,
                        onChanged: (value) {
                          setState(() {
                            _egitimSirketiAdi = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Eğitim şirketinin adını giriniz',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
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
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _webSitesi,
                        onChanged: (value) {
                          setState(() {
                            _webSitesi = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Web sitesi adresini giriniz',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
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
                      });
                    },
                  ),
                  if (_egitimYeriYurtDisi) ...[
                    const SizedBox(height: 16),
                    Column(
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
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _egitimUlkeSehir,
                          onChanged: (value) {
                            setState(() {
                              _egitimUlkeSehir = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Ülke / Şehir bilgisini giriniz',
                            filled: true,
                            fillColor: Colors.white,
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
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[300]!),
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
                                          ? Colors.black
                                          : Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade600,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TextFormField(
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
                            filled: true,
                            fillColor: Colors.white,
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
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[300]!),
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
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade600,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EgitimSonrasiPaylasimsScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
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
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade600,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickFiles,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
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
                                  color: Colors.grey.shade600,
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
                                      color: Colors.red,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _egitimTeklifIcerikController,
                        decoration: InputDecoration(
                          hintText: 'Dosya içeriği hakkında bilgi veriniz',
                          contentPadding: const EdgeInsets.all(12),
                          filled: true,
                          fillColor: Colors.white,
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
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
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
                          color: Colors.grey.shade300,
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
                        inactiveTrackColor: Colors.white,
                        onChanged: (value) {
                          setState(() {
                            _agreeWithDocuments = value;
                          });
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.gradientStart,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Genelgeyi ve protokolü okudum, anladım, onaylıyorum',
                          style: TextStyle(
                            color: Colors.grey.shade800,
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
                            color: Colors.white,
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

    String searchQuery = '';

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                color: Colors.white,
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
                        color: Colors.grey[300],
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
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
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
                                        : Colors.black,
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

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: const BoxDecoration(
            color: Colors.white,
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
                    color: Colors.grey[300],
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
                                    : Colors.black,
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
      print('❌ Eğitim adları yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eğitim adları yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      print('❌ Eğitim türleri yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eğitim türleri yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      print('❌ Şehirler yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şehirler yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      print('❌ Alınan eğitim ücreti yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _ucretYukleniyor = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    // DİĞER seçildiğinde eğitim adı zorunlu validasyonu
    if (_secilenEgitimAdi == 'DİĞER' && _ozelEgitimAdiController.text.isEmpty) {
      // Validation hatasını widget ile göster
      if (mounted) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen eğitimin adını giriniz',
        );
      }
      return;
    }

    // Form gönderme işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eğitim talep başarıyla gönderildi!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSehirBottomSheet() async {
    // 🔒 Enhanced focus control
    _egitimTeklifIcerikFocusNode.canRequestFocus = false;
    _ozelEgitimAdiFocusNode.canRequestFocus = false;
    FocusScope.of(context).unfocus();

    // 🔒 Critical: Wait 1 frame for focus state to settle
    await Future.delayed(Duration.zero);

    String searchQuery = '';

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                color: Colors.white,
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
                        color: Colors.grey[300],
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
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
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
                              style: TextStyle(color: Colors.grey.shade600),
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
                                        : Colors.black,
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
