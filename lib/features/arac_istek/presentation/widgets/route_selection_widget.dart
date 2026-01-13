import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/arac_istek/domain/entities/arac_talep.dart';
import 'package:esas_v1/features/arac_istek/presentation/providers/arac_talep_providers.dart';
import 'package:esas_v1/common/widgets/app_selection_sheet.dart';
import 'package:esas_v1/common/widgets/section_header.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class RouteSelectionWidget extends ConsumerWidget {
  const RouteSelectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aracTalepFormProvider);
    final gidilecekYerlerAsync = ref.watch(gidilecekYerlerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Gidilecek Yerler',
          action: TextButton.icon(
            onPressed: () {
              gidilecekYerlerAsync.whenData((items) {
                AppSelectionSheet.show(
                  context,
                  title: 'Gidilecek Yer Seçiniz',
                  items: items,
                  itemLabelBuilder: (item) => item
                      .toString(), // Assuming dynamic is just name for now or Map
                  onSelected: (item) {
                    // Need to map dynamic or Model to Entity
                    // Assuming item has 'yerAdi' etc.
                    // For 'dynamic' list, I'll assume it's Map or Model.
                    // In a real scenario, use proper type.
                    final name = item['yerAdi'] ?? item['ad'] ?? '';
                    ref
                        .read(aracTalepFormProvider.notifier)
                        .addGidilecekYer(
                          GidilecekYerSatir(gidilecekYer: name, semt: ''),
                        );
                  },
                );
              });
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ekle'),
          ),
        ),

        if (state.gidilecekYerSatir.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Henüz yer seçilmedi.'), // Style comes from theme
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.gidilecekYerSatir.length,
            itemBuilder: (context, index) {
              final item = state.gidilecekYerSatir[index];
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                  ),
                  title: Text(item.gidilecekYer),
                  subtitle: item.semt.isNotEmpty ? Text(item.semt) : null,
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed: () {
                      ref
                          .read(aracTalepFormProvider.notifier)
                          .removeGidilecekYer(index);
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
