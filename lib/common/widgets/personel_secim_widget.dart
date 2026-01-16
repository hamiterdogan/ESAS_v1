import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/features/izin_istek/screens/personel_secim_modal.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/custom_switch_widget.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';

class PersonelSecimWidget extends ConsumerStatefulWidget {
  final Function(Personel?)? onPersonelSelected;
  final Function(bool)? onToggleChanged;
  final Personel? initialPersonel;
  final bool initialToggleState;

  const PersonelSecimWidget({
    super.key,
    this.onPersonelSelected,
    this.onToggleChanged,
    this.initialPersonel,
    this.initialToggleState = false,
  });

  @override
  ConsumerState<PersonelSecimWidget> createState() =>
      _PersonelSecimWidgetState();
}

class _PersonelSecimWidgetState extends ConsumerState<PersonelSecimWidget> {
  late Personel? _secilenPersonel;
  late bool _basaksiAdinaIstekte;

  @override
  void initState() {
    super.initState();
    _secilenPersonel = widget.initialPersonel;
    _basaksiAdinaIstekte = widget.initialToggleState;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Button
        CustomSwitchWidget(
          value: _basaksiAdinaIstekte,
          label: 'Başkası adına istekte bulunuyorum',
          onChanged: (value) {
            setState(() {
              _basaksiAdinaIstekte = value;
              if (!value) {
                _secilenPersonel = null;
              }
            });
            // Filtre sıfırla
            ref.read(personelSecimSearchQueryProvider.notifier).setQuery('');
            widget.onToggleChanged?.call(value);
            widget.onPersonelSelected?.call(value ? _secilenPersonel : null);
          },
        ),
        const SizedBox(height: 8),
        // Personel Seçim Widget (toggle aktif olduğunda göster)
        if (_basaksiAdinaIstekte) ...[
          _buildPersonelSecimButton(),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildPersonelSecimButton() {
    return GestureDetector(
      onTap: () async {
        // Filtre sıfırla
        ref.read(personelSecimSearchQueryProvider.notifier).setQuery('');
        final result = await Navigator.push<Personel>(
          context,
          MaterialPageRoute(builder: (context) => const PersonelSecimModal()),
        );
        if (result != null) {
          setState(() {
            _secilenPersonel = result;
          });
          widget.onPersonelSelected?.call(result);
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
