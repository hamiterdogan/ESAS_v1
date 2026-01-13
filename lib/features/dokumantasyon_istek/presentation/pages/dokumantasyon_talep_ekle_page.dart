import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/common/widgets/primary_app_bar.dart';
import 'package:esas_v1/common/widgets/app_dialogs.dart';
import 'package:esas_v1/common/widgets/section_header.dart';
import 'package:esas_v1/common/widgets/app_selection_sheet.dart';
import 'package:esas_v1/common/widgets/file_attachment_picker.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/theme/app_dimens.dart';
import 'package:esas_v1/features/dokumantasyon_istek/presentation/providers/dokumantasyon_providers.dart';
import 'package:intl/intl.dart';

class DokumantasyonTalepEklePage extends ConsumerWidget {
  const DokumantasyonTalepEklePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(dokumantasyonFormProvider, (previous, next) {
      if (next.isSuccess) {
        AppDialogs.showSuccess(
          context,
          'Talebiniz alındı.',
          onOk: () {
            Navigator.pop(context);
          },
        );
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppDialogs.showError(context, next.errorMessage!);
      }
    });

    final state = ref.watch(dokumantasyonFormProvider);
    final notifier = ref.read(dokumantasyonFormProvider.notifier);
    final dokumanTurleriAsync = ref.watch(dokumanTurleriProvider);

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Dokümantasyon Talebi',
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textOnPrimary),
          onPressed: () async {
            if (await AppDialogs.showFormExitConfirm(context)) {
              if (context.mounted) Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Baskı Detayları'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Doküman Türü'),
              subtitle: Text(
                state.dokumanTuru.isEmpty ? 'Seçiniz' : state.dokumanTuru,
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () {
                dokumanTurleriAsync.whenData((items) {
                  AppSelectionSheet.show(
                    context,
                    title: 'Doküman Türü',
                    items: items,
                    itemLabelBuilder: (i) => i['ad'] ?? '', // Verify API field
                    onSelected: (i) => notifier.setDokumanTuru(i['ad'] ?? ''),
                  );
                });
              },
            ),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Baskı Adedi'),
                    onChanged: (v) =>
                        notifier.setBaskiAdedi(int.tryParse(v) ?? 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        initialDate: state.teslimTarihi ?? DateTime.now(),
                      );
                      if (d != null) notifier.setTeslimTarihi(d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Teslim Tarihi',
                      ),
                      child: Text(
                        state.teslimTarihi != null
                            ? DateFormat(
                                'dd.MM.yyyy',
                              ).format(state.teslimTarihi!)
                            : 'Seç',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: state.kagitTalebi,
                    items: const [
                      DropdownMenuItem(value: 'A4', child: Text('A4')),
                      DropdownMenuItem(value: 'A3', child: Text('A3')),
                    ],
                    onChanged: (v) => notifier.setKagitTalebi(v!),
                    decoration: const InputDecoration(
                      labelText: 'Kağıt Boyutu',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: state.baskiTuru,
                    items: const [
                      DropdownMenuItem(
                        value: 'Siyah-Beyaz',
                        child: Text('Siyah-Beyaz'),
                      ),
                      DropdownMenuItem(value: 'Renkli', child: Text('Renkli')),
                    ],
                    onChanged: (v) => notifier.setBaskiTuru(v!),
                    decoration: const InputDecoration(labelText: 'Baskı Türü'),
                  ),
                ),
              ],
            ),

            SwitchListTile(
              title: const Text('Önü Arkalı'),
              value: state.onluArkali,
              onChanged: notifier.setOnluArkali,
            ),
            SwitchListTile(
              title: const Text('Kopya Elden'),
              value: state.kopyaElden,
              onChanged: notifier.setKopyaElden,
            ),

            const SectionHeader(title: 'Açıklama & Ekler'),
            TextFormField(
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              onChanged: notifier.setAciklama,
            ),
            const SizedBox(height: 16),
            FileAttachmentPicker(provider: dokumantasyonFileProvider),

            const SizedBox(height: AppDimens.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        final files = ref.read(dokumantasyonFileProvider).files;
                        notifier.submit(files);
                      },
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Talep Oluştur'),
              ),
            ),
            const SizedBox(height: AppDimens.xxl),
          ],
        ),
      ),
    );
  }
}
