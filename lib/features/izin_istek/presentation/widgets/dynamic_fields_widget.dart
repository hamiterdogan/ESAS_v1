import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/izin_istek/presentation/providers/izin_talep_providers.dart';
import 'package:esas_v1/common/widgets/section_header.dart';
import 'package:intl/intl.dart';

class DynamicFieldsWidget extends ConsumerWidget {
  const DynamicFieldsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch specific fields to avoid rebuilds of this widget 
    // when only unrelated fields change? 
    // Actually, we need to rebuild when `izinSebebiId` changes.
    final izinSebebiId = ref.watch(izinTalepFormProvider.select((s) => s.izinSebebiId));
    final notifier = ref.read(izinTalepFormProvider.notifier);

    // 1: Yıllık, 2: Evlilik, 3: Vefat, 4: Hastalık, 5: Mazeret, 6: Dini, 7: Doğum, 8: Kurum
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (izinSebebiId == 2) ...[
          const SectionHeader(title: 'Evlilik Bilgileri'),
          _buildDateField(
            context,
            label: 'Evlilik Tarihi',
            selectedDate: ref.watch(izinTalepFormProvider.select((s) => s.evlilikTarihi)),
            onSelect: notifier.setEvlilikTarihi,
          ),
          const SizedBox(height: 12),
          TextFormField(
             decoration: const InputDecoration(labelText: 'Eş Adı'),
             onChanged: notifier.setEsAdi,
          ),
        ],

        if (izinSebebiId == 4) ...[
          const SectionHeader(title: 'Rapor Durumu'),
          SwitchListTile(
            title: const Text('Doktor Raporu Var'),
            value: ref.watch(izinTalepFormProvider.select((s) => s.doktorRaporu)),
            onChanged: notifier.setDoktorRaporu,
          ),
        ],

        if (izinSebebiId == 6) ...[
          const SectionHeader(title: 'Dini Gün'),
           TextFormField(
             decoration: const InputDecoration(labelText: 'Dini Gün Adı'),
             onChanged: notifier.setDiniGun,
          ),
        ],

        if (izinSebebiId == 7) ...[
          const SectionHeader(title: 'Doğum Bilgileri'),
           _buildDateField(
            context,
            label: 'Doğum Tarihi',
            selectedDate: ref.watch(izinTalepFormProvider.select((s) => s.dogumTarihi)),
            onSelect: notifier.setDogumTarihi,
          ),
        ],
        
        const SizedBox(height: 16),
        
        TextFormField(
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Açıklama',
            hintText: 'Varsa ek açıklama...',
            alignLabelWithHint: true,
          ),
          onChanged: notifier.setAciklama,
        ),
         const SizedBox(height: 16),
         TextFormField(
          decoration: const InputDecoration(
            labelText: 'İzinde Bulunacağı Adres',
          ),
          onChanged: notifier.setIzindeBulunacagiAdres,
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onSelect,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime(1900),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDate: selectedDate ?? DateTime.now(),
        );
        if (date != null) {
          onSelect(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? DateFormat('dd.MM.yyyy').format(selectedDate)
              : 'Seçiniz',
        ),
      ),
    );
  }
}
