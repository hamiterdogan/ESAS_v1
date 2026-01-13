import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/arac_istek/presentation/providers/arac_talep_providers.dart';
import 'package:esas_v1/common/widgets/section_header.dart';
import 'package:esas_v1/common/widgets/app_selection_sheet.dart';

class ReasonAndDescriptionWidget extends ConsumerWidget {
  const ReasonAndDescriptionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aracTalepFormProvider);
    final notifier = ref.read(aracTalepFormProvider.notifier);
    
    // Static list for simplicity, should come from provider if dynamic
    final reasons = ['Toplantı', 'Müşteri Ziyareti', 'Servis', 'Eğitim', 'Diğer'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'İstek Nedeni ve Açıklama'),
        
        InkWell(
          onTap: () {
            AppSelectionSheet.show(
              context,
              title: 'İstek Nedeni',
              items: reasons,
              itemLabelBuilder: (item) => item,
              searchable: false,
              onSelected: (item) => notifier.setIstekNedeni(item),
            );
          },
          child: InputDecorator(
             decoration: const InputDecoration(
              labelText: 'İstek Nedeni',
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              state.istekNedeni.isEmpty ? 'Seçiniz' : state.istekNedeni,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          initialValue: state.aciklama,
          onChanged: notifier.setAciklama,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Açıklama',
            hintText: 'Detaylı açıklama giriniz...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
