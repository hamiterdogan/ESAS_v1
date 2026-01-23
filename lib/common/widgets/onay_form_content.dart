import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/features/izin_istek/screens/personel_secim_modal.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';

class OnayFormContent extends ConsumerStatefulWidget {
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onReturn;
  final VoidCallback? onAssign;
  final bool gorevAtamaEnabled;

  const OnayFormContent({
    super.key,
    this.onApprove,
    this.onReject,
    this.onReturn,
    this.onAssign,
    this.gorevAtamaEnabled = true,
  });

  @override
  ConsumerState<OnayFormContent> createState() => _OnayFormContentState();
}

class _OnayFormContentState extends ConsumerState<OnayFormContent> {
  Personel? _secilenPersonel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Açıklama',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Açıklama giriniz',
            filled: true,
            fillColor: AppColors.textOnPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: widget.onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 17),
                  ),
                  child: const Text('Onayla'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: widget.onReject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 17),
                  ),
                  child: const Text('Reddet'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: widget.onReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 17),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Geri Gönder'),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.gorevAtamaEnabled) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _buildPersonelSecimButton(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: widget.onAssign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientStart,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Görev Ata'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPersonelSecimButton() {
    return GestureDetector(
      onTap: () async {
        ref.read(personelSecimSearchQueryProvider.notifier).setQuery('');
        final result = await Navigator.push<Personel>(
          context,
          MaterialPageRoute(builder: (context) => const PersonelSecimModal()),
        );
        if (result != null) {
          setState(() {
            _secilenPersonel = result;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.textOnPrimary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _secilenPersonel == null
                        ? 'Personel seçiniz'
                        : 'Seçilen Personel',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_secilenPersonel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_secilenPersonel!.ad} ${_secilenPersonel!.soyad}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
