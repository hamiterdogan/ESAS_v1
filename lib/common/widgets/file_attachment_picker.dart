import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/theme/app_typography.dart';
import 'package:esas_v1/core/theme/app_dimens.dart';
import 'package:esas_v1/common/providers/file_attachment_provider.dart';
import 'package:esas_v1/common/widgets/app_dialogs.dart';

class FileAttachmentPicker extends ConsumerWidget {
  final dynamic provider;

  const FileAttachmentPicker({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider) as FileAttachmentState;

    // Listen for errors separately to show dialogs
    ref.listen<FileAttachmentState>(provider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppDialogs.showError(context, next.errorMessage!);
        // Optionally clear error after showing
        ref.read(provider.notifier).clearHelper();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pick Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: state.isPicking
                ? null
                : () => ref.read(provider.notifier).pickFiles(),
            icon: state.isPicking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
            label: Text(
              state.isPicking ? 'Dosyalar Seçiliyor...' : 'Dosya Ekle',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),

        if (state.files.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Eklenen Dosyalar (${state.files.length})',
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.files.length,
            itemBuilder: (context, index) {
              final file = state.files[index];
              final name = file.path.split(Platform.pathSeparator).last;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.description,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    name,
                    style: AppTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed: () =>
                        ref.read(provider.notifier).removeFile(index),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
