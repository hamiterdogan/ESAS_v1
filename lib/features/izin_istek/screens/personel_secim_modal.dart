import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';

class PersonelSecimModal extends ConsumerWidget {
  const PersonelSecimModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredPersonelAsync = ref.watch(filteredPersonelProvider);
    final searchQuery = ref.watch(personelSecimSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personel Seçin',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: Column(
        children: [
          // Arama kutusu
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                ref
                    .read(personelSecimSearchQueryProvider.notifier)
                    .setQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Ad veya Soyadı arayınız...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref
                              .read(personelSecimSearchQueryProvider.notifier)
                              .setQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Personel listesi
          Expanded(
            child: filteredPersonelAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
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
                    child: Text(
                      searchQuery.isEmpty
                          ? 'Personel bulunamadı'
                          : 'Aramanıza uygun personel bulunamadı',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: personeller.length,
                  itemBuilder: (context, index) {
                    final personel = personeller[index];
                    return ListTile(
                      title: Text('${personel.ad} ${personel.soyad}'),
                      onTap: () {
                        Navigator.pop(context, personel);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
