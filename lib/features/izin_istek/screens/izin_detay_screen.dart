import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class IzinDetayScreen extends ConsumerWidget {
  final int izinId;

  const IzinDetayScreen({super.key, required this.izinId});

  void _silIstekDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İzin İsteğini Sil'),
        content: const Text(
          'Bu izin isteğini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              // Silme işlemi yap
              ref.read(izinIstekRepositoryProvider).izinIstekSil(izinId);
              context.pop(); // Dialog'u kapat
              context.go('/izin/liste'); // Talep listesine git
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('İzin isteği başarıyla silindi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detayAsyncValue = ref.watch(izinDetayProvider(izinId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'İzin İstek Detayı',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/izin_istek'),
        ),
      ),
      body: detayAsyncValue.when(
        loading: () => const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF014B92)),
            ),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata: $error'),
            ],
          ),
        ),
        data: (detay) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personel Bilgileri
                _buildSection('Personel Bilgileri', [
                  _buildRow('Ad Soyad', detay.personelAdi ?? 'N/A'),
                  _buildRow('Personel ID', detay.personelId.toString()),
                ]),
                const SizedBox(height: 24),

                // İzin Bilgileri
                _buildSection('İzin Bilgileri', [
                  _buildRow('İzin Sebebi', detay.izinSebebiAd ?? 'N/A'),
                  _buildRow(
                    'Başlangıç Tarihi',
                    detay.baslangicTarih != null
                        ? DateFormat('dd/MM/yyyy').format(detay.baslangicTarih!)
                        : 'N/A',
                  ),
                  _buildRow(
                    'Bitiş Tarihi',
                    detay.bitisTarih != null
                        ? DateFormat('dd/MM/yyyy').format(detay.bitisTarih!)
                        : 'N/A',
                  ),
                ]),
                const SizedBox(height: 24),

                // Açıklama
                const Text(
                  'Açıklama',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Text(
                    detay.aciklama ?? 'Açıklama yok',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Onay Durumu
                _buildSection('Onay Durumu', [
                  _buildRow('Durum', detay.onayDurumu ?? 'Bekleniyor'),
                  if (detay.onayanPersonel != null)
                    _buildRow('Onayan Personel', detay.onayanPersonel!),
                  if (detay.onaySebebi != null)
                    _buildRow('Onay Sebebi', detay.onaySebebi!),
                ]),
                const SizedBox(height: 32),

                // Sil Butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _silIstekDialog(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'İzin İsteğini Sil',
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
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
