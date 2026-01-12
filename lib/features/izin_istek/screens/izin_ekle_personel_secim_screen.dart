import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class IzinEklePersonelSecimScreen extends ConsumerWidget {
  const IzinEklePersonelSecimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredPersonelAsync = ref.watch(filteredPersonelProvider);
    final searchQuery = ref.watch(personelSecimSearchQueryProvider);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: const Text(
            'Personel Seçin',
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
        body: Column(
          children: [
            // Arama Alanı
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ad veya Soyadı yazınız...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  ref
                      .read(personelSecimSearchQueryProvider.notifier)
                      .setQuery(value);
                },
              ),
            ),
            // Personel Listesi
            Expanded(
              child: filteredPersonelAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text('Hata: $error'),
                    ],
                  ),
                ),
                data: (personeller) {
                  if (personeller.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'Personel bulunamadı'
                                : 'Arama sonucu bulunamadı',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: personeller.length,
                    itemBuilder: (context, index) {
                      final personel = personeller[index];
                      return _buildPersonelTile(personel, context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonelTile(Personel personel, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context, personel),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.textTertiary)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${personel.ad} ${personel.soyad}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
