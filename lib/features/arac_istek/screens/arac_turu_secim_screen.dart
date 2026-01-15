import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';

class AracTuruSecimScreen extends ConsumerWidget {
  const AracTuruSecimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aracTurleriAsync = ref.watch(aracTurleriProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Yeni Araç İsteği',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () => context.pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: aracTurleriAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 153,
            height: 153,
            child: BrandedLoadingIndicator(size: 153, strokeWidth: 24),
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 72,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Araç türleri yüklenemedi\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(aracTurleriProvider),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
        data: (aracTurleri) {
          if (aracTurleri.isEmpty) {
            return const Center(child: Text('Araç türü bulunamadı'));
          }

          return ListView.builder(
            itemCount: aracTurleri.length,
            itemBuilder: (context, index) {
              final item = aracTurleri[index];

              // Araç türüne göre ikon belirleme
              IconData icon;
              if (item.tur.toLowerCase().contains('binek')) {
                icon = Icons.directions_car;
              } else if (item.tur.toLowerCase().contains('kamyon') ||
                  item.tur.toLowerCase().contains('yük')) {
                icon = Icons.local_shipping;
              } else if (item.tur.toLowerCase().contains('minibüs')) {
                icon = Icons.airport_shuttle;
              } else if (item.tur.toLowerCase().contains('otobüs')) {
                icon = Icons.directions_bus;
              } else {
                icon = Icons.drive_eta;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/arac/ekle/${item.id}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                color: AppColors.primaryLight,
                                size: 30,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.tur,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.primaryLight,
                              ),
                            ],
                          ),
                        ),
                        // Çizgi - soldan 55px, sağdan 8px içerde
                        Container(
                          margin: const EdgeInsets.only(left: 55, right: 8),
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
