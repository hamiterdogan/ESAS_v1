import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_ekle_req.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';

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
    _baslangicTarihi = today;
    _bitisTarihi = _getNextSelectableDay(today);
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF1F5),
        appBar: AppBar(
          title: const Text(
            'Evlilik İzni İstek',
            style: TextStyle(color: Colors.white),
          ),
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
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
                            ),
                        onDateChanged: (date) {
                          setState(() {
                            _baslangicTarihi = date;
                            if (_bitisTarihi == null ||
                                date.isAfter(_bitisTarihi!)) {
                              var nextDay = date.add(const Duration(days: 1));
                              if (nextDay.weekday == DateTime.sunday) {
                                nextDay = nextDay.add(const Duration(days: 1));
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
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  focusNode: _esAdiFocusNode,
                  controller: _esAdiController,
                  decoration: InputDecoration(
                    hintText: 'Lütfen eşinizin adını giriniz.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _esAdiHatali
                            ? const Color(0xFFB57070)
                            : Colors.grey,
                        width: _esAdiHatali ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _esAdiHatali
                            ? const Color(0xFFB57070)
                            : AppColors.gradientEnd,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  minLines: 3,
                  maxLines: 5,
                  onChanged: (value) {
                    if (_esAdiHatali && value.isNotEmpty) {
                      setState(() {
                        _esAdiHatali = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Girilmeyen Ders Saati Spinner
                DersSaatiSpinnerWidget(
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
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _adresHatali
                            ? const Color(0xFFB57070)
                            : Colors.grey,
                        width: _adresHatali ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _adresHatali
                            ? const Color(0xFFB57070)
                            : AppColors.gradientEnd,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PdfViewerScreen(
                                title: 'İzin Kullanma Yönergesi',
                                pdfUrl:
                                    'https://esas.eyuboglu.k12.tr/yonerge/izin_kullanma_esaslari_yonergesi.pdf',
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.description,
                              color: Color(0xFF014B92),
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'İzin kullanma yönergesi',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Divider(color: Colors.grey[400], height: 1),
                      const SizedBox(height: 6),
                      OnayToggleWidget(
                        initialValue: _onay,
                        onChanged: (value) {
                          setState(() {
                            _onay = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                        color: Colors.white,
                        fontSize: 16,
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
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Form validasyonları
      if (_baslangicTarihi == null) {
        _showStatusBottomSheet('Başlangıç tarihi seçiniz', isError: true);
        return;
      }

      if (_bitisTarihi == null) {
        _showStatusBottomSheet('Bitiş tarihi seçiniz', isError: true);
        return;
      }

      if (_evlilikTarihi == null) {
        _showStatusBottomSheet('Evlilik tarihi seçiniz', isError: true);
        return;
      }

      // Açıklama minimum 30 karakter kontrolü
      if (_aciklamaController.text.length < 30) {
        _showStatusBottomSheet(
          'Lütfen en az 30 karakter olacak şekilde açıklama giriniz',
          isError: true,
        );
        _aciklamaFocusNode.requestFocus();
        return;
      }

      // Adres boş kontrolü
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

      // Eş adı boş kontrolü
      if (_esAdiController.text.isEmpty) {
        setState(() {
          _esAdiHatali = true;
        });
        _showStatusBottomSheet('Lütfen eşinizin adını giriniz', isError: true);
        _esAdiFocusNode.requestFocus();
        return;
      }

      // Başlangıç tarihi bitiş tarihinden sonra olamaz
      if (_baslangicTarihi!.isAfter(_bitisTarihi!)) {
        _showStatusBottomSheet(
          'İzin başlangıç tarihi izin bitiş tarihinden küçük olmalıdır',
          isError: true,
        );
        return;
      }

      try {
        // Token'dan personel ID'sini al
        final dolduranPersonelId = ref.read(currentPersonelIdProvider);

        // Evlilik izin sebep ID: 2
        const int izinSebebiId = 2;

        print('✅ Seçilen izin sebep ID: $izinSebebiId');
        print('📝 Dolduran Personel ID: $dolduranPersonelId');
        print('📝 Başkası adına istekte: $_basaksiAdinaIstekte');
        print('📝 Seçilen Personel: ${_secilenPersonel?.personelId}');

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

        print('📤 Gönderilen istek: ${request.toJson()}');

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
            onSuccess: () {
              _showStatusBottomSheet(
                'Evlilik izni talebi başarıyla gönderildi!',
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showStatusBottomSheet(String message, {bool isError = false}) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext statusContext) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                size: 64,
                color: isError ? Colors.red : Colors.green,
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
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }
}
