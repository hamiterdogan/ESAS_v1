import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/features/izin_istek/screens/personel_secim_modal.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/common/widgets/numeric_spinner_widget.dart';
import 'package:esas_v1/core/network/dio_provider.dart';

class OnayFormContent extends ConsumerStatefulWidget {
  final Function(String aciklama)? onApprove;
  final Function(String aciklama)? onReject;
  final Function(String aciklama)? onReturn;
  final Function(String aciklama, Personel? selectedPersonel)?
  onAssign; // Görev atama için açıklama ve personel
  final Function(String aciklama, int bekletKademe)?
  onHold; // Bekletme için açıklama ve kademe

  final bool gorevAtamaEnabled;

  const OnayFormContent({
    super.key,
    this.onApprove,
    this.onReject,
    this.onReturn,
    this.onAssign,
    this.onHold,
    this.gorevAtamaEnabled = true,
  });

  @override
  ConsumerState<OnayFormContent> createState() => _OnayFormContentState();
}

class _OnayFormContentState extends ConsumerState<OnayFormContent> {
  Personel? _secilenPersonel;
  final TextEditingController _aciklamaController = TextEditingController();
  int _bekletKademe = 1;

  @override
  void dispose() {
    _aciklamaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kullaniciAdi = ref.watch(currentKullaniciAdiProvider);
    final isSpecificUser = kullaniciAdi == 'CEYUBOGLU';

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
          controller: _aciklamaController,
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
                  onPressed: () {
                    _showConfirmationSheet(
                      context,
                      'Onayla',
                      AppColors.success,
                      () {
                        if (widget.onApprove != null) {
                          widget.onApprove!(_aciklamaController.text);
                        }
                      },
                    );
                  },
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
                  onPressed: () {
                    _showConfirmationSheet(
                      context,
                      'Reddet',
                      AppColors.error,
                      () {
                        if (widget.onReject != null) {
                          widget.onReject!(_aciklamaController.text);
                        }
                      },
                    );
                  },
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
                  onPressed: () {
                    _showConfirmationSheet(
                      context,
                      'Geri Gönder',
                      AppColors.warning,
                      () {
                        if (widget.onReturn != null) {
                          widget.onReturn!(_aciklamaController.text);
                        }
                      },
                    );
                  },
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
        if (isSpecificUser) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              NumericSpinnerWidget(
                onValueChanged: (value) {
                  setState(() {
                    _bekletKademe = value;
                  });
                },
                initialValue: _bekletKademe,
                minValue: 1,
                maxValue: 10,
                compact: true,
                label: 'Bekletme Kademesi',
              ),
              const SizedBox(width: 32),
              SizedBox(
                width: 105,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    _showConfirmationSheet(
                      context,
                      'Beklet',
                      Colors.blueGrey,
                      () {
                        if (widget.onHold != null) {
                          widget.onHold!(
                            _aciklamaController.text,
                            _bekletKademe,
                          );
                        }
                      },
                      customMessage:
                          'Süreci $_bekletKademe gün bekletmek istediğinizden emin misiniz?',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  child: const Text('Beklet'),
                ),
              ),
            ],
          ),
        ],
        if (widget.gorevAtamaEnabled) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 22),
          const Text(
            'Atanacak Personel',
            style: TextStyle(
              fontSize: 17,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          _buildPersonelSecimButton(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.onAssign != null) {
                    if (_secilenPersonel == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen atanacak personeli seçiniz'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }
                    widget.onAssign!(
                      _aciklamaController.text,
                      _secilenPersonel,
                    );
                  }
                },
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

  void _showConfirmationSheet(
    BuildContext context,
    String actionName,
    Color color,
    VoidCallback onConfirm, {
    String? customMessage,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              customMessage ?? _getConfirmationMessage(actionName),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.textTertiary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Vazgeç',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close sheet
                        onConfirm(); // Execute action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        actionName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
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

  String _getConfirmationMessage(String actionName) {
    switch (actionName.toLowerCase()) {
      case 'onayla':
        return 'Süreci ONAYLAMAK istediğinizden emin misiniz?';
      case 'reddet':
        return 'Süreci REDDETMEK istediğinizden emin misiniz?';
      case 'geri gönder':
        return 'Süreci GERİ GÖNDERMEK istediğinizden emin misiniz?';
      default:
        return 'Süreci ${actionName.toUpperCase()}MEK istediğinizden emin misiniz?';
    }
  }
}
