import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/izin_istek/presentation/providers/izin_talep_providers.dart';
import 'package:esas_v1/common/widgets/app_selection_sheet.dart';
import 'package:esas_v1/common/widgets/section_header.dart';

class IzinTypeSelectorWidget extends ConsumerWidget {
  const IzinTypeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(izinTalepFormProvider);
    final izinSebepleriAsync = ref.watch(izinSebepleriProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'İzin Türü'),
        
        InkWell(
          onTap: () {
            izinSebepleriAsync.whenData((items) {
               AppSelectionSheet.show(
                 context,
                 title: 'İzin Türü Seçiniz',
                 items: items,
                 itemLabelBuilder: (item) {
                   // Assuming item is Map or Model
                   // Original: json['ad']
                   return item['ad'] ?? item['Ad'] ?? item['istekNedeni'] ?? 'Bilinmeyen';
                 },
                 onSelected: (item) {
                   // Check ID field
                   final id = item['id'] ?? item['ID'] ?? 0;
                   ref.read(izinTalepFormProvider.notifier).setIzinSebebi(id);
                 },
               );
            });
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'İzin Türü',
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              state.izinSebebiId == 0 
                  ? 'Seçiniz' 
                  : (izinSebepleriAsync.value?.firstWhere((e) => e['id'] == state.izinSebebiId, orElse: () => {'ad': 'Seçili İzin'})['ad'] ?? 'Seçili İzin (Yükleniyor)'),
            ),
          ),
        ),
      ],
    );
  }
}
