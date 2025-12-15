import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_ekle_req.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/core/network/dio_provider.dart';

class MazeretIzinScreen extends ConsumerStatefulWidget {
  const MazeretIzinScreen({super.key});

  @override
  ConsumerState<MazeretIzinScreen> createState() => _MazeretIzinScreenState();
}

class _MazeretIzinScreenState extends ConsumerState<MazeretIzinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aciklamaController = TextEditingController();
  final _adresController = TextEditingController();
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;
  int _baslangicSaat = 8;
  int _baslangicDakika = 0;
  int _bitisSaat = 17;
  int _bitisDakika = 30;
  int _girileymeyenDersSaati = 0;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Mazeret İzni İstek',
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
                AciklamaFieldWidget(controller: _aciklamaController),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Switch(
                      value: _birGunlukIzin,
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
                      activeTrackColor: AppColors.gradientStart.withValues(
                        alpha: 0.5,
                      ),
                      activeThumbColor: AppColors.gradientEnd,
                    ),
                    const Text('1 günlük izin'),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: DatePickerBottomSheetWidget(
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
                                var nextDay = date.add(const Duration(days: 1));
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
                Row(
                  children: [
                    Expanded(
                      child: TimePickerBottomSheetWidget(
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
                            if (_birGunlukIzin) {
                              // Toggle açıkken başlangıç saati değişince bitişi 17:30'a sabitle
                              _bitisSaat = 17;
                              _bitisDakika = 30;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: TimePickerBottomSheetWidget(
                        key: ValueKey(
                          'end-time-${_baslangicSaat}-${_baslangicDakika}-${_birGunlukIzin}-${_baslangicTarihi}-${_bitisTarihi}-${_bitisSaat}-${_bitisDakika}',
                        ),
                        initialHour: _bitisSaat,
                        initialMinute: _bitisDakika,
                        minHour:
                            (_birGunlukIzin || _baslangicTarihi == _bitisTarihi)
                            ? _baslangicSaat
                            : 8,
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
                DersSaatiSpinnerWidget(
                  initialValue: _girileymeyenDersSaati,
                  onValueChanged: (value) {
                    setState(() {
                      _girileymeyenDersSaati = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'İzinde Bulunacağı Adres',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
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
                const SizedBox(height: 16),
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
      if (_baslangicTarihi == null) {
        _showStatusBottomSheet('Başlangıç tarihi seçiniz', isError: true);
        return;
      }

      // 1 günlük izin aktif ise başlangıç tarihi = bitiş tarihi
      DateTime bitisTarih;
      int bitisSaatValue;
      int bitisDakikaValue;

      if (_birGunlukIzin) {
        bitisTarih = _baslangicTarihi!;
        // Toggle açıkken varsayılan 17:30; kullanıcı widget üzerinden değiştirdiyse mevcut değeri kullan
        bitisSaatValue = _bitisSaat;
        bitisDakikaValue = _bitisDakika;
      } else {
        if (_bitisTarihi == null) {
          _showStatusBottomSheet('Bitiş tarihi seçiniz', isError: true);
          return;
        }
        bitisTarih = _bitisTarihi!;
        bitisSaatValue = _bitisSaat;
        bitisDakikaValue = _bitisDakika;
      }

      // Açıklama minimum 30 karakter kontrolü
      if (_aciklamaController.text.length < 30) {
        _showStatusBottomSheet(
          'Lütfen en az 30 karakter olacak şekilde açıklama giriniz',
          isError: true,
        );
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
        return;
      }

      // Başlangıç tarihi bitiş tarihinden sonra olamaz
      if (_baslangicTarihi!.isAfter(bitisTarih)) {
        _showStatusBottomSheet(
          'İzin başlangıç tarihi izin bitiş tarihinden küçük olmalıdır',
          isError: true,
        );
        return;
      }

      // Başlangıç ve bitiş saatleri aynı olamaz (1 günlük izin aktifken veya tarihler aynıyken)
      if ((_birGunlukIzin || _baslangicTarihi == _bitisTarihi) &&
          _baslangicSaat == _bitisSaat &&
          _baslangicDakika == _bitisDakika) {
        _showStatusBottomSheet(
          'Lütfen başlangıç saati ve bitiş saati değerlerini kontrol ediniz',
          isError: true,
        );
        return;
      }

      try {
        const int izinSebebiId = 5; // API: Mazeret İzni
        final currentPersonelId = ref.read(currentPersonelIdProvider);

        // Toggle aktif ise seçilen personel ID, değilse 0
        final int baskaPersonelIdValue =
            _basaksiAdinaIstekte && _secilenPersonel != null
            ? _secilenPersonel!.personelId
            : 0;

        print('✅ Mazeret İzni İstek - İzin Sebep ID: $izinSebebiId');
        print(
          '👤 baskaPersonelId: $baskaPersonelIdValue, dolduranPersonelId: $currentPersonelId',
        );

        final request = IzinIstekEkleReq(
          izinSebebiId: izinSebebiId,
          izinBaslangicTarihi: _baslangicTarihi!,
          izinBitisTarihi: bitisTarih,
          aciklama: _aciklamaController.text,
          izindeBulunacagiAdres: _adresController.text,
          izinBaslangicSaat: _baslangicSaat,
          izinBaslangicDakika: _baslangicDakika,
          izinBitisSaat: bitisSaatValue,
          izinBitisDakika: bitisDakikaValue,
          izindeGirilmeyenToplamDersSaati: _girileymeyenDersSaati,
          baskaPersonelId: baskaPersonelIdValue,
          dolduranPersonelId: currentPersonelId,
        );

        print('📤 Gönderilen istek: \${request.toJson()}');

        // Bottom sheet'te özet göster
        if (mounted) {
          final ozetItems = [
            IzinOzetItem(label: 'İzin Türü', value: 'Mazeret'),
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
          ];

          await showIzinOzetBottomSheet(
            context: context,
            request: request,
            izinTipi: 'Mazeret',
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
                'Mazeret izin talebi başarıyla gönderildi!',
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

