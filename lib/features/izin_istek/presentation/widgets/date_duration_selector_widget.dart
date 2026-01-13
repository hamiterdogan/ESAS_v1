import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/izin_istek/presentation/providers/izin_talep_providers.dart';
import 'package:esas_v1/common/widgets/section_header.dart';
import 'package:esas_v1/core/theme/app_typography.dart';
import 'package:intl/intl.dart';

class DateDurationSelectorWidget extends ConsumerWidget {
  const DateDurationSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(izinTalepFormProvider);
    final notifier = ref.read(izinTalepFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Tarih Bilgileri'),
        
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: state.izinBaslangicTarihi ?? DateTime.now(),
                  );
                  if (date != null) {
                    notifier.setIzinBaslangicTarihi(date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Başlangıç',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    state.izinBaslangicTarihi != null
                        ? DateFormat('dd.MM.yyyy').format(state.izinBaslangicTarihi!)
                        : 'Seçiniz',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: state.izinBitisTarihi ?? DateTime.now(),
                  );
                  if (date != null) {
                    notifier.setIzinBitisTarihi(date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Bitiş',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    state.izinBitisTarihi != null
                        ? DateFormat('dd.MM.yyyy').format(state.izinBitisTarihi!)
                        : 'Seçiniz',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
