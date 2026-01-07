import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';

class TalepYonetimScreen extends ConsumerStatefulWidget {
  const TalepYonetimScreen({super.key});

  @override
  ConsumerState<TalepYonetimScreen> createState() => _TalepYonetimScreenState();
}

class _TalepYonetimScreenState extends ConsumerState<TalepYonetimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/'); // Ana sayfaya git
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF1F5),
        appBar: AppBar(
          title: const Text('İzin İsteklerini Yönet'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.gradientEnd,
            labelColor: AppColors.gradientEnd,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Devam Eden'),
              Tab(text: 'Tamamlanan'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Devam eden talepler
            _buildTalepListesi(ref.watch(devamEdenIsteklerimProvider)),
            // Tamamlanan talepler
            _buildTalepListesi(ref.watch(tamamlananIsteklerimProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildTalepListesi(AsyncValue taleplerAsync) {
    return taleplerAsync.when(
      data: (talepResponse) {
        if (talepResponse.talepler.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Talep Bulunamadı',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: talepResponse.talepler.length,
          itemBuilder: (context, index) {
            final talep = talepResponse.talepler[index];
            return _buildTalepCard(talep);
          },
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandedLoadingIndicator(size: 48),
            const SizedBox(height: 16),
            Text(
              'Talepler Yükleniyor...',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Hata: ${error.toString()}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Refresh providers
                ref.invalidate(devamEdenIsteklerimProvider);
                ref.invalidate(tamamlananIsteklerimProvider);
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalepCard(dynamic talep) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          talep.olusturanKisi,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Oluşturma Tarihi',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatTarih(talep.olusturmaTarihi),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Durum',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(talep.onayDurumu),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          talep.onayDurumu,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kayıt ID: ${talep.onayKayitId}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          _showTalepDetay(talep);
        },
      ),
    );
  }

  void _showTalepDetay(dynamic talep) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İzin Talep Detayı',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(talep.onayDurumu),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              talep.onayDurumu,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Talep eden kişi bilgileri
                      _buildDetaySection(
                        icon: Icons.person_outline,
                        title: 'Talep Eden Kişi',
                        items: [
                          _buildDetayItem('Ad Soyad', talep.olusturanKisi),
                          if (talep.gorevYeri != null &&
                              talep.gorevYeri!.isNotEmpty)
                            _buildDetayItem('Görev Yeri', talep.gorevYeri!),
                          if (talep.gorevi != null && talep.gorevi!.isNotEmpty)
                            _buildDetayItem('Görevi', talep.gorevi!),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Talep bilgileri
                      _buildDetaySection(
                        icon: Icons.info_outline,
                        title: 'Talep Bilgileri',
                        items: [
                          _buildDetayItem('Talep Türü', talep.onayTipi),
                          _buildDetayItem(
                            'Kayıt ID',
                            talep.onayKayitId.toString(),
                          ),
                          _buildDetayItem(
                            'Oluşturma Tarihi',
                            _formatTarihDetay(talep.olusturmaTarihi),
                          ),
                          _buildDetayItem(
                            'İşlem Tarihi',
                            _formatTarihDetay(talep.islemTarihi),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Onay durumu bilgileri
                      _buildDetaySection(
                        icon: Icons.check_circle_outline,
                        title: 'Onay Durumu',
                        items: [
                          _buildDetayItem('Durum', talep.onayDurumu),
                          if (talep.beklemeDurumu != null &&
                              talep.beklemeDurumu!.isNotEmpty)
                            _buildDetayItem(
                              'Bekleme Durumu',
                              talep.beklemeDurumu!,
                            ),
                          _buildDetayItem(
                            'Onay Sırası',
                            talep.onaySirasi.toString(),
                          ),
                          if (talep.cevapVeren != null &&
                              talep.cevapVeren!.isNotEmpty)
                            _buildDetayItem('Cevap Veren', talep.cevapVeren!),
                          if (talep.bekletKademe != null &&
                              talep.bekletKademe!.isNotEmpty)
                            _buildDetayItem(
                              'Beklet Kademe',
                              talep.bekletKademe!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Ek bilgiler
                      _buildDetaySection(
                        icon: Icons.more_horiz,
                        title: 'Ek Bilgiler',
                        items: [
                          _buildDetayItem(
                            'Arşiv',
                            talep.arsiv ? 'Evet' : 'Hayır',
                          ),
                          _buildDetayItem(
                            'Geri Gönderildi',
                            talep.geriGonderildi ? 'Evet' : 'Hayır',
                          ),
                          if (talep.actionAdi != null &&
                              talep.actionAdi!.isNotEmpty)
                            _buildDetayItem('Aksiyon', talep.actionAdi!),
                          if (talep.toplamTutar > 0)
                            _buildDetayItem(
                              'Toplam Tutar',
                              '${talep.toplamTutar} ₺',
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetaySection({
    required IconData icon,
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gradientStart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.gradientStart),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildDetayItem(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Text(
              deger,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTarihDetay(String tarihi) {
    try {
      final date = DateTime.parse(tarihi);
      final gun = date.day.toString().padLeft(2, '0');
      final ay = date.month.toString().padLeft(2, '0');
      final yil = date.year;
      final saat = date.hour.toString().padLeft(2, '0');
      final dakika = date.minute.toString().padLeft(2, '0');
      return '$gun.$ay.$yil $saat:$dakika';
    } catch (e) {
      return tarihi;
    }
  }

  String _formatTarih(String tarihi) {
    try {
      final date = DateTime.parse(tarihi);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return tarihi;
    }
  }

  Color _getStatusColor(String durum) {
    switch (durum.toLowerCase()) {
      case 'onaylandı':
        return Colors.green;
      case 'reddedildi':
        return Colors.red;
      case 'bekleniyor':
        return Colors.orange;
      case 'taslak':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
