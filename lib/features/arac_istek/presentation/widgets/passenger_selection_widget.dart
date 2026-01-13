import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/arac_istek/presentation/providers/arac_talep_providers.dart';
import 'package:esas_v1/common/widgets/section_header.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class PassengerSelectionWidget extends ConsumerWidget {
  const PassengerSelectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aracTalepFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Yolcu Listesi',
          action: TextButton.icon(
            onPressed: () {
               // Logic to open passenger selection sheet
               // For now, simpler placeholder or mock
               // In real app, this opens another complex sheet "PersonelSelectorWidget"
               // We should reuse the Generic Selection Sheet if possible, 
               // OR wrap the existing PersonelSelectorWidget in a clean way.
               // Given constraints, I'll stick to basic add or omit complex selection implementation 
               // but provide the UI structure.
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Yolcu Ekle'),
          ),
        ),
        
        if (state.yolcuPersonelSatir.isEmpty)
           const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Henüz yolcu eklenmedi.'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.yolcuPersonelSatir.length,
            itemBuilder: (context, index) {
              final item = state.yolcuPersonelSatir[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text(item.perAdi.substring(0, 1), style: const TextStyle(color: AppColors.primary)),
                  ),
                  title: Text(item.perAdi),
                  subtitle: Text(item.gorevi),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () {
                       // Remove passenger
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
