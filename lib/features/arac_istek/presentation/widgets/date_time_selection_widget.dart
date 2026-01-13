import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/arac_istek/presentation/providers/arac_talep_providers.dart';
import 'package:esas_v1/common/widgets/section_header.dart';
import 'package:esas_v1/core/theme/app_typography.dart';
import 'package:intl/intl.dart';

class DateTimeSelectionWidget extends ConsumerWidget {
  const DateTimeSelectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aracTalepFormProvider);
    final notifier = ref.read(aracTalepFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Tarih ve Saat Seçimi'),

        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              initialDate: state.gidilecekTarih ?? DateTime.now(),
            );
            if (date != null) {
              notifier.setGidilecekTarih(date);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Gidilecek Tarih',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              state.gidilecekTarih != null
                  ? DateFormat('dd.MM.yyyy').format(state.gidilecekTarih!)
                  : 'Seçiniz',
              style: AppTypography.bodyLarge,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: int.parse(state.gidisSaat),
                      minute: int.parse(state.gidisDakika),
                    ),
                  );
                  if (time != null) {
                    notifier.setGidisSaat(
                      time.hour.toString().padLeft(2, '0'),
                      time.minute.toString().padLeft(2, '0'),
                    );
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Gidiş Saati',
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    '${state.gidisSaat}:${state.gidisDakika}',
                    style: AppTypography.bodyLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: int.parse(state.donusSaat),
                      minute: int.parse(state.donusDakika),
                    ),
                  );
                  if (time != null) {
                    notifier.setDonusSaat(
                      time.hour.toString().padLeft(2, '0'),
                      time.minute.toString().padLeft(2, '0'),
                    );
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Dönüş Saati',
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    '${state.donusSaat}:${state.donusDakika}',
                    style: AppTypography.bodyLarge,
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
