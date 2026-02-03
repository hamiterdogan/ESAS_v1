import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/common/widgets/onay_form_content.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';
import 'package:esas_v1/core/screens/image_viewer_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_istek_detay_model.dart';
import 'package:esas_v1/features/dokumantasyon_istek/providers/dokumantasyon_istek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/repositories/talep_yonetim_repository.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/core/models/result.dart'; // Add Result model import
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_istek_guncelle_req.dart';
import 'package:esas_v1/features/dokumantasyon_istek/repositories/dokumantasyon_istek_repository.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokuman_tur_model.dart'; // Needed? No, just logic
import 'package:esas_v1/features/dokumantasyon_istek/providers/dokumantasyon_talep_providers.dart'; // For refreshing lists
import 'package:esas_v1/common/widgets/validation_uyari_widget.dart';
import 'package:esas_v1/common/widgets/istek_basarili_widget.dart';
import 'package:esas_v1/common/widgets/numeric_spinner_widget.dart'; // Import NumericSpinnerWidget
import 'package:intl/intl.dart';

class DokumantasyonIstekDetayScreen extends ConsumerStatefulWidget {
  final int talepId;
  final String? onayTipi;

  const DokumantasyonIstekDetayScreen({
    super.key,
    required this.talepId,
    this.onayTipi,
  });

  @override
  ConsumerState<DokumantasyonIstekDetayScreen> createState() =>
      _DokumantasyonIstekDetayScreenState();
}

class _DokumantasyonIstekDetayScreenState
    extends ConsumerState<DokumantasyonIstekDetayScreen> {
  bool _personelExpanded = true;
  bool _detayExpanded = true;
  bool _onayExpanded = true;
  bool _onayFormExpanded = true;
  bool _bildirimExpanded = true;

  // Edit variables
  TextEditingController? _baskiAdediController;
  TextEditingController? _sayfaSayisiController;
  int _paketAdedi = 0; // State for A4 package count
  String? _baskiBoyutu; // kagitTalebi
  int? _lastInitTalepId;
  List<String> _baskiBoyutlari = [];
  bool _isLoadingBaskiBoyutlari = false;
  bool _isUpdating = false;

  @override
  void dispose() {
    _baskiAdediController?.dispose();
    _sayfaSayisiController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detayAsync = ref.watch(
      dokumantasyonIstekDetayProvider(widget.talepId),
    );

    final isLoading = detayAsync.isLoading;
    final body = detayAsync.when(
      data: (detay) => _buildContent(context, detay),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => _buildError(context, error),
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: AppBar(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dokümantasyon İstek Detayı (${widget.talepId})',
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textOnPrimary,
                ),
                onPressed: () {
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    context.go('/dokumantasyon_istek');
                  }
                },
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              ),
              elevation: 0,
            ),
            body: body,
          ),
          if (isLoading) const BrandedLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Detay yüklenemedi\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(dokumantasyonIstekDetayProvider(widget.talepId));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, DokumantasyonIstekDetayResponse detay) {
    
    // Initialize controllers if needed
    if (_lastInitTalepId != detay.id) {
      _lastInitTalepId = detay.id;
      _baskiAdediController = TextEditingController(text: detay.baskiAdedi?.toString() ?? '1');
      _sayfaSayisiController = TextEditingController(text: detay.sayfaSayisi?.toString() ?? '1');
      _paketAdedi = (detay.paket != null && detay.paket! > 0) ? detay.paket! : 1; // Initialize paket
      
      // Listen for changes to update totals
      _baskiAdediController?.addListener(() => setState(() {}));
      _sayfaSayisiController?.addListener(() => setState(() {}));
      
      _baskiBoyutu = detay.kagitTalebi.isNotEmpty ? detay.kagitTalebi : 'A4';
      _fetchBaskiBoyutlari();
    }
    
    final resolvedOnayTipi = (widget.onayTipi ?? '').trim().isNotEmpty
        ? widget.onayTipi!.trim()
        : 'Dokümantasyon İstek';

    final onayDurumuAsync = ref.watch(
      onayDurumuProvider((talepId: widget.talepId, onayTipi: resolvedOnayTipi)),
    );

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dokumantasyonIstekDetayProvider(widget.talepId));
        ref.invalidate(
          onayDurumuProvider((
            talepId: widget.talepId,
            onayTipi: resolvedOnayTipi,
          )),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 40),
        children: [
          // 1. Personel Bilgileri
          _buildAccordion(
            icon: Icons.person_outline,
            title: 'Personel Bilgileri',
            isExpanded: _personelExpanded,
            onTap: () => setState(() => _personelExpanded = !_personelExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Ad Soyad',
                  detay.adSoyad.isNotEmpty ? detay.adSoyad : '-',
                ),
                _buildInfoRow(
                  'Görev Yeri',
                  detay.gorevYeri?.isNotEmpty == true ? detay.gorevYeri! : '-',
                ),
                _buildInfoRow(
                  'Görevi',
                  detay.gorevi?.isNotEmpty == true ? detay.gorevi! : '-',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Süreç Detayı
          _buildAccordion(
            icon: Icons.description_outlined,
            title: 'Süreç Detayı',
            isExpanded: _detayExpanded,
            onTap: () => setState(() => _detayExpanded = !_detayExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildSurecDetayiRows(detay),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Onay Süreci
          onayDurumuAsync.when(
            data: (onayDurumu) => _buildAccordion(
              icon: Icons.approval_outlined,
              title: 'Onay Süreci',
              isExpanded: _onayExpanded,
              onTap: () => setState(() => _onayExpanded = !_onayExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildOnaySureciContent(onayDurumu),
              ),
            ),
            loading: () => _buildAccordion(
              icon: Icons.approval_outlined,
              title: 'Onay Süreci',
              isExpanded: _onayExpanded,
              onTap: () => setState(() => _onayExpanded = !_onayExpanded),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            error: (error, _) => _buildAccordion(
              icon: Icons.approval_outlined,
              title: 'Onay Süreci',
              isExpanded: _onayExpanded,
              onTap: () => setState(() => _onayExpanded = !_onayExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Onay süreci yüklenemedi',
                  style: TextStyle(color: AppColors.error, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          onayDurumuAsync.when(
            data: (onayDurumu) {
              if (!onayDurumu.onayFormuGoster) {
                return const SizedBox(height: 16);
              }

              return Column(
                children: [
                  _buildAccordion(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Onay',
                    isExpanded: _onayFormExpanded,
                    onTap: () =>
                        setState(() => _onayFormExpanded = !_onayFormExpanded),
                    child: OnayFormContent(
                      onApprove: (aciklama) async {
                        final onaySureciId = onayDurumu
                            .siradakiOnayVerecekPersonel
                            ?.onaySureciId;
                        if (onaySureciId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Onay süreci ID bulunamadı!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        try {
                          final repository = ref.read(
                            talepYonetimRepositoryProvider,
                          );
                          final request = OnayDurumuGuncelleRequest(
                            onayTipi: resolvedOnayTipi,
                            onayKayitId: widget.talepId,
                            onaySureciId: onaySureciId,
                            onay: true,
                            beklet: false,
                            geriDon: false,
                            aciklama: aciklama,
                          );

                          final result = await repository.onayDurumuGuncelle(
                            request,
                          );

                          if (!context.mounted) return;

                          switch (result) {
                            case Success():
                              // Listeyi yenile ve geri dön
                              ref
                                  .read(devamEdenGelenKutusuProvider.notifier)
                                  .refresh();
                              Navigator.pop(context);
                            case Failure(message: final message):
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $message'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            case Loading():
                              break;
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      onReject: (aciklama) async {
                        final onaySureciId = onayDurumu
                            .siradakiOnayVerecekPersonel
                            ?.onaySureciId;
                        if (onaySureciId == null) return;

                        try {
                          final repository = ref.read(
                            talepYonetimRepositoryProvider,
                          );
                          final request = OnayDurumuGuncelleRequest(
                            onayTipi: resolvedOnayTipi,
                            onayKayitId: widget.talepId,
                            onaySureciId: onaySureciId,
                            onay: false,
                            beklet: false,
                            geriDon: false,
                            aciklama: aciklama,
                          );

                          final result = await repository.onayDurumuGuncelle(
                            request,
                          );

                          if (!context.mounted) return;

                          switch (result) {
                            case Success():
                              ref
                                  .read(devamEdenGelenKutusuProvider.notifier)
                                  .refresh();
                              Navigator.pop(context);
                            case Failure(message: final message):
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $message'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            case Loading():
                              break;
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      onReturn: (aciklama) async {
                        final onaySureciId = onayDurumu
                            .siradakiOnayVerecekPersonel
                            ?.onaySureciId;
                        if (onaySureciId == null) return;

                        try {
                          final repository = ref.read(
                            talepYonetimRepositoryProvider,
                          );
                          final request = OnayDurumuGuncelleRequest(
                            onayTipi: resolvedOnayTipi,
                            onayKayitId: widget.talepId,
                            onaySureciId: onaySureciId,
                            onay: false,
                            beklet: false,
                            geriDon: true,
                            aciklama: aciklama,
                          );

                          final result = await repository.onayDurumuGuncelle(
                            request,
                          );

                          if (!context.mounted) return;

                          switch (result) {
                            case Success():
                              ref
                                  .read(devamEdenGelenKutusuProvider.notifier)
                                  .refresh();
                              Navigator.pop(context);
                            case Failure(message: final message):
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $message'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            case Loading():
                              break;
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      onAssign: (aciklama, selectedPersonel) async {
                        if (selectedPersonel == null) return;
                        final onaySureciId = onayDurumu
                            .siradakiOnayVerecekPersonel
                            ?.onaySureciId;
                        if (onaySureciId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Onay süreci ID bulunamadı!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        try {
                          final repository = ref.read(
                            talepYonetimRepositoryProvider,
                          );
                          final request = OnayDurumuGuncelleRequest(
                            onayTipi: resolvedOnayTipi,
                            onayKayitId: widget.talepId,
                            onaySureciId: onaySureciId,
                            onay: true,
                            beklet: false,
                            geriDon: false,
                            aciklama: aciklama,
                            atanacakPersonelId: selectedPersonel.personelId,
                          );

                          final result = await repository.onayDurumuGuncelle(
                            request,
                          );

                          if (!context.mounted) return;

                          switch (result) {
                            case Success():
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Görev atama başarıyla gerçekleşti',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              ref
                                  .read(devamEdenGelenKutusuProvider.notifier)
                                  .refresh();
                              Navigator.pop(context);
                            case Failure(message: final message):
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $message'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            case Loading():
                              break;
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      onHold: (aciklama, bekletKademe) async {
                        final onaySureciId = onayDurumu
                            .siradakiOnayVerecekPersonel
                            ?.onaySureciId;
                        if (onaySureciId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Onay süreci ID bulunamadı!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        try {
                          final repository = ref.read(
                            talepYonetimRepositoryProvider,
                          );
                          final request = OnayDurumuGuncelleRequest(
                            onayTipi: resolvedOnayTipi,
                            onayKayitId: widget.talepId,
                            onaySureciId: onaySureciId,
                            onay: false,
                            beklet: true,
                            geriDon: false,
                            aciklama: aciklama,
                            bekletKademe: bekletKademe,
                          );

                          final result = await repository.onayDurumuGuncelle(
                            request,
                          );

                          if (!context.mounted) return;

                          switch (result) {
                            case Success():
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Bekleme işlemi başarıyla gerçekleşti',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              ref
                                  .read(devamEdenGelenKutusuProvider.notifier)
                                  .refresh();
                              Navigator.pop(context);
                            case Failure(message: final message):
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $message'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            case Loading():
                              break;
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      gorevAtamaEnabled: onayDurumu.atamaGoster,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 16),
            error: (_, __) => const SizedBox(height: 16),
          ),
          const SizedBox(height: 20),

          // 4. Bildirim Gidecekler
          onayDurumuAsync.when(
            data: (onayDurumu) => _buildAccordion(
              icon: Icons.notifications_outlined,
              title: 'Bildirim Gidecekler',
              isExpanded: _bildirimExpanded,
              onTap: () =>
                  setState(() => _bildirimExpanded = !_bildirimExpanded),
              childLeftPadding: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildBildirimContent(onayDurumu),
              ),
            ),
            loading: () => _buildAccordion(
              icon: Icons.notifications_outlined,
              title: 'Bildirim Gidecekler',
              isExpanded: _bildirimExpanded,
              onTap: () =>
                  setState(() => _bildirimExpanded = !_bildirimExpanded),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            error: (error, _) => _buildAccordion(
              icon: Icons.notifications_outlined,
              title: 'Bildirim Gidecekler',
              isExpanded: _bildirimExpanded,
              onTap: () =>
                  setState(() => _bildirimExpanded = !_bildirimExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Bildirim gidecekler yüklenemedi',
                  style: TextStyle(color: AppColors.error, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSurecDetayiRows(DokumantasyonIstekDetayResponse detay) {
    final currentUser = ref.watch(currentKullaniciAdiProvider);
    final isAuthorized = currentUser == 'MUYILMAZ';
    final isEditable = isAuthorized && !detay.a4Talebi; // dokumanTuru != null implies a4Talebi == false typically, user said "not a4Talebi" effectively

    // dokumanTuru null ise (veya a4Talebi true) sadece belirli alanları göster
    if (detay.a4Talebi) {
      final rows = <Widget>[];

      // 1. İstek Türü
      rows.add(_buildInfoRow('İstek Türü', 'Boş A4 Kağıdı'));

      // 2. Oluşturma Tarihi
      rows.add(
        _buildInfoRow(
            'Oluşturma Tarihi', _formatDateTime(detay.olusturmaTarihi)),
      );

      // 3. Teslim Edilecek Tarih
      rows.add(
        _buildInfoRow('Teslim Edilecek Tarih', _formatDate(detay.teslimTarihi)),
      );

      // 4. Paket Adedi (paket) - Editable
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               NumericSpinnerWidget(
                 label: 'Paket Adedi',
                 initialValue: _paketAdedi,
                 minValue: 1,
                 maxValue: 100,
                 compact: true,
                 onValueChanged: (val) {
                   setState(() => _paketAdedi = val);
                 },
               ),
              const SizedBox(height: 10),
              Container(height: 1, color: AppColors.border),
            ],
          ),
        ),
      );
      
      // Update Button for A4
      rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : () => _updateA4Istek(detay),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isUpdating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Güncelle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      );

      return rows;
    }

    // Editable Mode for MUYILMAZ
    if (isEditable) {
       final rows = <Widget>[];
       // 1. İstek Türü (Read-only)
       rows.add(_buildInfoRow('İstek Türü', detay.a4Talebi ? 'A4 Kağıdı İstek' : 'Dokümantasyon Baskı İstek'));
       // 2. Oluşturma Tarihi
       rows.add(_buildInfoRow('Oluşturma Tarihi', _formatDateTime(detay.olusturmaTarihi)));
       // 3. Teslim Edilecek Tarih
       rows.add(_buildInfoRow('Teslim Edilecek Tarih', _formatDate(detay.teslimTarihi)));
       // 4. Doküman Türü
       rows.add(_buildInfoRow('Doküman Türü', detay.dokumanTuru?.isNotEmpty == true ? detay.dokumanTuru! : '-'));
       
       // Helper for edit rows
       Widget _buildEditRow(String label, Widget input) {
         return Padding(
           padding: const EdgeInsets.only(bottom: 12),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 label,
                 style: const TextStyle(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                   color: AppColors.textSecondary,
                 ),
               ),
               const SizedBox(height: 8),
               input,
               const SizedBox(height: 10),
               Container(height: 1, color: AppColors.border),
             ],
           ),
         );
       }

       // 5. Baskı Adedi (Editable)
       rows.add(
         _buildEditRow(
           'Baskı Adedi',
           TextField(
             controller: _baskiAdediController,
             keyboardType: TextInputType.number,
             decoration: const InputDecoration(
               border: OutlineInputBorder(),
               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               isDense: true,
             ),
           ),
         ),
       );

       // 6. Sayfa Sayısı (Editable)
       rows.add(
         _buildEditRow(
           'Sayfa Sayısı',
           TextField(
             controller: _sayfaSayisiController,
             keyboardType: TextInputType.number,
             decoration: const InputDecoration(
               border: OutlineInputBorder(),
               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               isDense: true,
             ),
           ),
         ),
       );

       // 7. Baskı Boyutu (Editable Selector)
       rows.add(
         _buildEditRow(
           'Baskı Boyutu',
           InkWell(
              onTap: _showBaskiBoyutuBottomSheet,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                  isDense: true,
                ),
                child: Text(_baskiBoyutu ?? 'Seçiniz'),
              ),
            ),
         ),
       );

       // 8. Toplam Sayfa (Calculated)
       final baskiAdedi = int.tryParse(_baskiAdediController?.text ?? '0') ?? 0;
       final sayfaSayisi = int.tryParse(_sayfaSayisiController?.text ?? '0') ?? 0;
       final toplamSayfa = baskiAdedi * sayfaSayisi;
       
       rows.add(_buildInfoRow('Toplam Sayfa', '$toplamSayfa'));
       
       // ... Other read-only fields ...
       rows.add(_buildInfoRow('Açıklama', detay.aciklama.isNotEmpty ? detay.aciklama : '-', multiLine: true));
       rows.add(_buildInfoRow('Baskı Türü', detay.baskiTuru.isNotEmpty ? detay.baskiTuru : '-'));
       rows.add(_buildInfoRow('Arkalı Önlü Baskı', detay.onluArkali ? 'Evet' : 'Hayır'));
       rows.add(_buildInfoRow('Çoğaltılacak kopya elden gönderilecektir', detay.kopyaElden ? 'Evet' : 'Hayır'));
       
       // ... Files and Classes ...
       if (detay.dosyaAdlari.isNotEmpty) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Dosyalar:',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ),
          );
          for (int i = 0; i < detay.dosyaAdlari.length; i++) {
             rows.add(_buildClickableFileRow(detay.dosyaAdlari[i], detay.dosyaAdlari[i], isLast: i == detay.dosyaAdlari.length - 1 && detay.dosyaAciklama?.isEmpty != false && detay.okullarSatir.isEmpty));
          }
       } else {
          rows.add(_buildInfoRow('Dosyalar', '-'));
       }

       if (detay.dosyaAciklama?.isNotEmpty == true) {
         rows.add(_buildInfoRow('Dosya İçeriği', detay.dosyaAciklama!, multiLine: true));
       }

       if (detay.okullarSatir.isNotEmpty) {
          // Simplified logic for brevity, ideally reuse the one below or refactor to helper
          final siniflar = detay.okullarSatir.map((o) => '• ${o.okulKodu ?? '-'} - ${o.sinif ?? '-'}').join('\n'); // Simplified for now
          rows.add(_buildInfoRow('Seçilen Sınıflar', siniflar, isLast: true, multiLine: true));
       } else {
          rows.add(_buildInfoRow('Seçilen Sınıflar', '-', isLast: true));
       }
       
        // Update Button
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : () => _updateIstek(detay),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isUpdating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Güncelle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        );

       return rows;
    }

    // dokumanTuru null değilse mevcut yapıyı koru (Standard View)
    final rows = <Widget>[];

    // 1. İstek Türü
    rows.add(
      _buildInfoRow(
        'İstek Türü',
        detay.a4Talebi ? 'A4 Kağıdı İstek' : 'Dokümantasyon Baskı İstek',
      ),
    );

    // 2. Oluşturma Tarihi
    rows.add(
      _buildInfoRow('Oluşturma Tarihi', _formatDateTime(detay.olusturmaTarihi)),
    );

    // 3. Teslim Edilecek Tarih
    rows.add(
      _buildInfoRow('Teslim Edilecek Tarih', _formatDate(detay.teslimTarihi)),
    );

    // 4. Doküman Türü
    rows.add(
      _buildInfoRow(
        'Doküman Türü',
        detay.dokumanTuru?.isNotEmpty == true ? detay.dokumanTuru! : '-',
      ),
    );

    // 5. Baskı Adedi
    rows.add(
      _buildInfoRow(
        'Baskı Adedi',
        detay.baskiAdedi != null ? '${detay.baskiAdedi}' : '-',
      ),
    );

    // 6. Sayfa Sayısı
    rows.add(
      _buildInfoRow(
        'Sayfa Sayısı',
        detay.sayfaSayisi != null ? '${detay.sayfaSayisi}' : '-',
      ),
    );

    // 7. Baskı Boyutu (Kullanıcının isteği: Baskı Boyutu olarak göster, veri kagitTalebi)
    rows.add(
      _buildInfoRow(
        'Baskı Boyutu',
        detay.kagitTalebi.isNotEmpty ? detay.kagitTalebi : '-',
      ),
    );

    // 8. Toplam Sayfa
    rows.add(
      _buildInfoRow(
        'Toplam Sayfa',
        detay.toplamSayfa != null ? '${detay.toplamSayfa}' : '-',
      ),
    );

    // 9. Açıklama
    rows.add(
      _buildInfoRow(
        'Açıklama',
        detay.aciklama.isNotEmpty ? detay.aciklama : '-',
        multiLine: true,
      ),
    );

    // 10. Baskı Türü
    rows.add(
      _buildInfoRow(
        'Baskı Türü',
        detay.baskiTuru.isNotEmpty ? detay.baskiTuru : '-',
      ),
    );

    // 11. Arkalı Önlü Baskı
    rows.add(
      _buildInfoRow('Arkalı Önlü Baskı', detay.onluArkali ? 'Evet' : 'Hayır'),
    );

    // 12. Çoğaltılacak kopya elden gönderilecektir
    rows.add(
      _buildInfoRow(
        'Çoğaltılacak kopya elden gönderilecektir',
        detay.kopyaElden ? 'Evet' : 'Hayır',
      ),
    );

    // 13. Dosyalar
    if (detay.dosyaAdlari.isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Dosyalar:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
      for (int i = 0; i < detay.dosyaAdlari.length; i++) {
        final fileName = detay.dosyaAdlari[i];
        rows.add(
          _buildClickableFileRow(
            fileName,
            fileName, // Assuming file name is displayed as label too
            isLast:
                i == detay.dosyaAdlari.length - 1 &&
                detay.dosyaAciklama?.isEmpty != false &&
                detay.okullarSatir.isEmpty,
          ),
        );
      }
    } else {
      rows.add(_buildInfoRow('Dosyalar', '-'));
    }

    // 14. Dosya İçeriği (dosyaAciklama)
    if (detay.dosyaAciklama?.isNotEmpty == true) {
      rows.add(
        _buildInfoRow('Dosya İçeriği', detay.dosyaAciklama!, multiLine: true),
      );
    }

    // 15. Seçilen Sınıflar
    if (detay.okullarSatir.isNotEmpty) {
      final siniflar = detay.okullarSatir
          .map((o) {
            final sinifLabel = (o.sinif ?? '').isNotEmpty ? o.sinif : '-';
            final okulLabel = (o.okulKodu ?? '').isNotEmpty ? o.okulKodu : '-';
            final seviye = (o.seviye ?? '').isNotEmpty ? ' (${o.seviye})' : '';
            final numara = (o.numara ?? '').isNotEmpty ? ' • ${o.numara}' : '';
            final isim =
                ((o.adi ?? '').isNotEmpty || (o.soyadi ?? '').isNotEmpty)
                ? ' • ${(o.adi ?? '').trim()} ${(o.soyadi ?? '').trim()}'
                : '';
            return '• $okulLabel - $sinifLabel$seviye$numara$isim';
          })
          .join('\n');
      rows.add(
        _buildInfoRow(
          'Seçilen Sınıflar',
          siniflar,
          isLast: true,
          multiLine: true,
        ),
      );
    } else {
      rows.add(_buildInfoRow('Seçilen Sınıflar', '-', isLast: true));
    }

    return rows;
  }

  List<Widget> _buildOnaySureciContent(OnayDurumuResponse onayDurumu) {
    final List<Widget> widgets = [];

    // 1. Talep Eden Personel (En üstte)
    widgets.add(
      _buildTalepEdenCard(
        personelAdi: onayDurumu.talepEdenPerAdi,
        gorevYeri: onayDurumu.talepEdenPerGorevYeri,
        gorevi: onayDurumu.talepEdenPerGorev,
        tarih: onayDurumu.talepEdenTarih,
        isLast: onayDurumu.onayVerecekler.isEmpty,
      ),
    );

    // 2. Onay Verecekler listesi
    for (int i = 0; i < onayDurumu.onayVerecekler.length; i++) {
      final personel = onayDurumu.onayVerecekler[i];

      // Onay durumuna göre ikon ve renk belirle
      IconData icon;
      Color iconColor;

      if (personel.onay == true) {
        icon = Icons.check_circle;
        iconColor = AppColors.success;
      } else if (personel.onay == false) {
        icon = Icons.cancel;
        iconColor = AppColors.error;
      } else if (personel.geriGonderildi) {
        icon = Icons.replay;
        iconColor = AppColors.warning;
      } else {
        icon = Icons.hourglass_empty;
        iconColor = AppColors.warning;
      }

      widgets.add(
        _buildOnaySureciCard(
          personelAdi: personel.personelAdi,
          gorevYeri: personel.gorevYeri,
          gorevi: personel.gorevi,
          tarih: personel.islemTarihi,
          durum: personel.onayDurumu,
          aciklama: personel.aciklama,
          icon: icon,
          iconColor: iconColor,
          isLast: i == onayDurumu.onayVerecekler.length - 1,
        ),
      );
    }

    return widgets;
  }

  Widget _buildTalepEdenCard({
    required String personelAdi,
    required String gorevYeri,
    required String gorevi,
    DateTime? tarih,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 70, color: AppColors.textTertiary),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personelAdi,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_task,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Talep Oluşturuldu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gorevYeri,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  gorevi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (tarih != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(tarih),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnaySureciCard({
    required String personelAdi,
    required String gorevYeri,
    required String gorevi,
    DateTime? tarih,
    required String durum,
    String? aciklama,
    required IconData icon,
    required Color iconColor,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            if (!isLast)
              Container(width: 2, height: 80, color: AppColors.textTertiary),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personelAdi,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gorevYeri,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  gorevi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    durum,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: iconColor,
                    ),
                  ),
                ),
                if (tarih != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(tarih),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
                if (aciklama != null && aciklama.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Not: $aciklama',
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBildirimContent(OnayDurumuResponse onayDurumu) {
    if (onayDurumu.bildirimGidecekler.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Bildirim gidecek kişi bulunmuyor',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ),
      ];
    }

    return [
      ...onayDurumu.bildirimGidecekler.asMap().entries.map((entry) {
        final idx = entry.key;
        final personel = entry.value;
        final isLast = idx == onayDurumu.bildirimGidecekler.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                personel.personelAdi,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                personel.gorevi,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                personel.gorevYeri,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textTertiary,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(height: 10),
                Container(height: 0.5, color: AppColors.border),
              ],
            ],
          ),
        );
      }),
    ];
  }

  Widget _buildAccordion({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
    double childLeftPadding = 16,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.06),
                    end: Offset.zero,
                  ).animate(curved),
                  child: SizeTransition(
                    sizeFactor: curved,
                    axisAlignment: -1,
                    child: child,
                  ),
                ),
              );
            },
            child: isExpanded
                ? Column(
                    key: const ValueKey('expanded'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderLight,
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          childLeftPadding,
                          12,
                          16,
                          16,
                        ),
                        child: child,
                      ),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('collapsed')),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isLast = false,
    bool multiLine = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (multiLine) ...[
            // Alt satıra yazılacak format
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.textPrimary,
              ),
            ),
          ] else ...[
            // İki nokta üst üsteden sonra boşluk bırakılıp yazılacak format
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    value.isNotEmpty ? value : '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isLast) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  Widget _buildClickableFileRow(
    String label,
    String fileName, {
    bool isLast = false,
  }) {
    const String baseUrl =
        'https://esas.eyuboglu.k12.tr/TestDosyalar/DokumantasyonIstek/';
    final String fileUrl = '$baseUrl$fileName';

    // Dosya uzantısını kontrol et
    final extension = fileName.toLowerCase().split('.').last;
    final isPdf = extension == 'pdf';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tıklanabilir dosya adı
          GestureDetector(
            onTap: () async {
              final lowerFileName = fileName.toLowerCase();
              final isImage =
                  lowerFileName.endsWith('.png') ||
                  lowerFileName.endsWith('.jpg') ||
                  lowerFileName.endsWith('.jpeg') ||
                  lowerFileName.endsWith('.bmp');

              if (isPdf) {
                // PDF ise ortak PDF viewer'a yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PdfViewerScreen(title: fileName, pdfUrl: fileUrl),
                  ),
                );
              } else if (isImage) {
                // Image dosyaları için image viewer'a yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ImageViewerScreen(title: fileName, imageUrl: fileUrl),
                  ),
                );
              } else {
                // Diğer dosyalar için tarayıcıda aç
                final uri = Uri.parse(fileUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: Row(
              children: [
                Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                  size: 20,
                  color: AppColors.gradientStart,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gradientStart,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  // Helper Methods for Edit
  Future<void> _fetchBaskiBoyutlari() async {
    setState(() => _isLoadingBaskiBoyutlari = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/DokumantasyonIstek/BaskiBoyutuGetir');
      if (response.statusCode == 200) {
         final List<dynamic> data = response.data is List ? response.data : [];
         if (mounted) {
           setState(() {
             _baskiBoyutlari = data.map((e) => e.toString()).toList();
           });
         }
      }
    } catch (e) {
      debugPrint('Baskı boyutları yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBaskiBoyutlari = false);
    }
  }

  void _showBaskiBoyutuBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Baskı Boyutu Seçiniz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              if (_isLoadingBaskiBoyutlari)
                const CircularProgressIndicator()
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _baskiBoyutlari.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _baskiBoyutlari[index];
                      return ListTile(
                        leading: _baskiBoyutu == item ? const Icon(Icons.check, color: AppColors.primary) : const SizedBox(width: 24),
                        title: Text(item),
                        onTap: () {
                          setState(() => _baskiBoyutu = item);
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
  }

  Future<void> _updateIstek(DokumantasyonIstekDetayResponse detay) async {
    if (_isUpdating) return;
    
    final baskiAdedi = int.tryParse(_baskiAdediController?.text ?? '');
    final sayfaSayisi = int.tryParse(_sayfaSayisiController?.text ?? '');
    
    if (baskiAdedi == null || sayfaSayisi == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen geçerli sayısal değerler giriniz.')));
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final req = DokumantasyonIstekGuncelleReq(
        id: detay.id,
        baskiAdedi: baskiAdedi,
        kagitTalebi: _baskiBoyutu ?? 'A4',
        dokumanTuru: detay.dokumanTuru ?? '',
        sayfaSayisi: sayfaSayisi,
        toplamSayfa: baskiAdedi * sayfaSayisi,
      );

      final repo = ref.read(dokumantasyonIstekRepositoryProvider);
      final result = await repo.dokumantasyonIstekGuncelle(request: req);

      if (!mounted) return;

      if (result is Success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İstek başarıyla güncellendi.'), backgroundColor: AppColors.success));
        ref.invalidate(dokumantasyonIstekDetayProvider(widget.talepId)); // Refresh details
      } else if (result is Failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${result.message}'), backgroundColor: AppColors.error));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateA4Istek(DokumantasyonIstekDetayResponse detay) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final req = DokumantasyonIstekGuncelleReq(
        id: detay.id,
        paket: _paketAdedi,
      );

      final repo = ref.read(dokumantasyonIstekRepositoryProvider);
      final result = await repo.dokumantasyonIstekGuncelle(request: req);

      if (!mounted) return;

      if (result is Success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İstek başarıyla güncellendi.'), backgroundColor: AppColors.success));
        ref.invalidate(dokumantasyonIstekDetayProvider(widget.talepId)); // Refresh details
      } else if (result is Failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${result.message}'), backgroundColor: AppColors.error));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}
