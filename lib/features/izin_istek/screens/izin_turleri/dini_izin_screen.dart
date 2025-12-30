import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_ekle_req.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/core/models/result.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF1F5),
        appBar: AppBar(
          title: const Text(
            'Dini İzin İstek',
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
                      inactiveTrackColor: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          '1 günlük izin',
                          style: TextStyle(fontSize: 16),
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
                              labelStyle: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontSize:
                                        (Theme.of(
                                              context,
                                            ).textTheme.titleSmall?.fontSize ??
                                            14) +
                                        1,
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
                            (Theme.of(context).textTheme.titleSmall?.fontSize ??
                                14) +
                            1,
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
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
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
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.black,
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
                                  Color(0xFF014B92),
                                ),
                              ),
                            ),
                          ),
                          error: (error, stack) => Text(
                            'Hata: $error',
                            style: const TextStyle(
                              color: Colors.red,
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

  void _showDiniGunBottomSheet(List<dynamic> gunler) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: Colors.white,
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
                              : Colors.black,
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
  }
}
