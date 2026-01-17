import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';

class OkulSecimWidget extends StatelessWidget {
  final AsyncValue<List<SatinAlmaBina>> binalarAsync;
  final Set<String> selectedBinaKodlari;
  final String Function(List<SatinAlmaBina> binalar) selectedTextBuilder;
  final VoidCallback onTap;
  final void Function(List<SatinAlmaBina> binalar)? onShowSelected;
  final String title;

  const OkulSecimWidget({
    super.key,
    required this.binalarAsync,
    required this.selectedBinaKodlari,
    required this.selectedTextBuilder,
    required this.onTap,
    this.onShowSelected,
    this.title = 'Satın Alma İsteğinde Bulunulan Okullar',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize:
                (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) + 1,
            color: AppColors.inputLabelColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: binalarAsync.when(
                    data: (binalar) => Text(
                      selectedTextBuilder(binalar),
                      style: TextStyle(
                        color: selectedBinaKodlari.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    loading: () => const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Yükleniyor...'),
                      ],
                    ),
                    error: (_, __) => const Text(
                      'Liste alınamadı',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (selectedBinaKodlari.isNotEmpty)
          binalarAsync.when(
            data: (binalar) => TextButton.icon(
              onPressed: onShowSelected == null
                  ? null
                  : () => onShowSelected!(binalar),
              icon: const Icon(Icons.list),
              label: Text(
                'Seçilen Okullar (${selectedBinaKodlari.length})',
                style: const TextStyle(fontSize: 15),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gradientStart,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class OkulSecimListItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const OkulSecimListItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.gradientStart
        : Colors.grey.shade400;
    final fillColor = isSelected ? AppColors.gradientStart : Colors.transparent;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize:
                      (Theme.of(context).textTheme.titleMedium?.fontSize ??
                          16) +
                      2,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
                color: fillColor,
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.textOnPrimary,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
