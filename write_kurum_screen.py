#!/usr/bin/env python3
# Write kurum_gorevlendirmesi_izin_screen.dart file

content = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_ekle_req.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';

class KurumGorevlendirmesiIzinScreen extends ConsumerStatefulWidget {
  const KurumGorevlendirmesiIzinScreen({super.key});

  @override
  ConsumerState<KurumGorevlendirmesiIzinScreen> createState() =>
      _KurumGorevlendirmesiIzinScreenState();
}

class _KurumGorevlendirmesiIzinScreenState
    extends ConsumerState<KurumGorevlendirmesiIzinScreen> {
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

  @override
  void dispose() {
    _aciklamaController.dispose();
    _adresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kurum Görevlendirmesi İstek',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
              DateRangePickerWidget(
                initialStartDate: _baslangicTarihi,
                initialEndDate: _bitisTarihi,
                hideEndDate: _birGunlukIzin,
                startDateLabel: 'Başlangıç Tarihi',
                onDatesChanged: (start, end) {
                  setState(() {
                    _baslangicTarihi = start;
                    if (_birGunlukIzin) {
                      _bitisTarihi = start;
                    } else {
                      _bitisTarihi = end;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Başlangıç Saati',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TimeRangePickerWidget(
                            initialHour: _baslangicSaat,
                            initialMinute: _baslangicDakika,
                            minHour: 8,
                            maxHour: 18,
                            allowedMinutes: const [0, 30],
                            onTimeChanged: (hour, minute) {
                              setState(() {
                                _baslangicSaat = hour;
                                _baslangicDakika = minute;
                                if (_birGunlukIzin) {
                                  _bitisSaat = hour;
                                  _bitisDakika = minute;
                                } else {
                                  _bitisSaat = 17;
                                  _bitisDakika = 30;
                                }
                              });
                            },
                          ),
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
                          'Bitiş Saati',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TimeRangePickerWidget(
                            key: ValueKey(
                              'end-time-${_baslangicSaat}-${_baslangicDakika}',
                            ),
                            initialHour:
                                _bitisSaat > _baslangicSaat ||
                                    (_bitisSaat == _baslangicSaat &&
                                        _bitisDakika > _baslangicDakika)
                                ? _bitisSaat
                                : _baslangicSaat,
                            initialMinute: _bitisSaat > _baslangicSaat
                                ? _bitisDakika
                                : (_bitisSaat == _baslangicSaat
                                      ? _bitisDakika > _baslangicDakika
                                            ? _bitisDakika
                                            : 30
                                      : 0),
                            minHour: _baslangicSaat,
                            minMinute: _bitisSaat == _baslangicSaat
                                ? _baslangicDakika
                                : 0,
                            maxHour: 18,
                            allowedMinutes: const [0, 30],
                            onTimeChanged: (hour, minute) {
                              setState(() {
                                if (_birGunlukIzin) {
                                  int startTimeInMinutes =
                                      _baslangicSaat * 60 + _baslangicDakika;
                                  int endTimeInMinutes = hour * 60 + minute;

                                  if (endTimeInMinutes <= startTimeInMinutes) {
                                    startTimeInMinutes += 30;
                                    _bitisSaat = startTimeInMinutes ~/ 60;
                                    _bitisDakika = startTimeInMinutes % 60;
                                  } else {
                                    _bitisSaat = hour;
                                    _bitisDakika = minute;
                                  }
                                } else {
                                  _bitisSaat = hour;
                                  _bitisDakika = minute;
                                }
                              });
                            },
                          ),
                        ),
                      ],
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
                  filled: true,
                  fillColor: Colors.white,
                ),
                minLines: 3,
                maxLines: 5,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Adres gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              OnayToggleWidget(
                initialValue: _onay,
                onChanged: (value) {
                  setState(() {
                    _onay = value;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Divider(color: Colors.blueGrey, thickness: 1),
              ),
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
                  children: [
                    const Icon(
                      Icons.description,
                      color: Color.fromARGB(255, 97, 97, 97),
                      size: 30,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'İzin kullanma yönergesi',
                      style: TextStyle(
                        color: Color.fromARGB(255, 97, 97, 97),
                        fontSize: 15,
                      ),
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
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_baslangicTarihi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Başlangıç tarihi seçiniz')),
        );
        return;
      }

      if (_bitisTarihi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitiş tarihi seçiniz')),
        );
        return;
      }

      if (_aciklamaController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Açıklama giriniz')),
        );
        return;
      }

      try {
        const int izinSebebiId = 8;
        print('✅ Seçilen izin sebep ID: $izinSebebiId');

        final request = IzinIstekEkleReq(
          izinSebebiId: izinSebebiId,
          izinBaslangicTarihi: _baslangicTarihi!,
          izinBitisTarihi: _bitisTarihi!,
          aciklama: _aciklamaController.text,
          izindeBulunacagiAdres: _adresController.text,
          izinBaslangicSaat: _baslangicSaat,
          izinBaslangicDakika: _baslangicDakika,
          izinBitisSaat: _bitisSaat,
          izinBitisDakika: _bitisDakika,
          izindeGirilmeyenToplamDersSaati: _girileymeyenDersSaati,
          baskaPersonelId: _secilenPersonel?.personelId,
        );

        print('📤 Gönderilen istek: ${request.toJson()}');

        final repo = ref.read(izinIstekRepositoryProvider);
        final result = await repo.izinIstekEkle(request);

        if (mounted) {
          switch (result) {
            case Success():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '✅ Kurum görevlendirmesi izni talebi başarıyla gönderildi!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              Future.delayed(
                const Duration(milliseconds: 500),
                () {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            case Failure(:final message):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Hata: $message'),
                  backgroundColor: Colors.red,
                ),
              );
            case Loading():
              break;
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
"""

output_path = r'c:\Users\User\Desktop\projects\flutter\esas_v1\lib\features\izin_istek\screens\izin_turleri\kurum_gorevlendirmesi_izin_screen.dart'
with open(output_path, 'w', encoding='utf-8') as f:
    f.write(content)
print(f"✅ File created successfully: {output_path}")
