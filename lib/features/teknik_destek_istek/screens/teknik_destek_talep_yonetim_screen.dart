import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_filter_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';

/// Teknik Destek talep yönetim ekranı.
///
/// Bu ekran [GenericTalepYonetimScreen] widget'ını kullanarak
/// ortak talep yönetim yapısını uygular.
///
/// TODO: Provider'lar ve modeller oluşturulduktan sonra
/// tam implementation eklenecek.
class TeknikDeskekTalepYonetimScreen extends ConsumerStatefulWidget {
  const TeknikDeskekTalepYonetimScreen({super.key});

  @override
  ConsumerState<TeknikDeskekTalepYonetimScreen> createState() =>
      _TeknikDeskekTalepYonetimScreenState();
}

class _TeknikDeskekTalepYonetimScreenState
    extends ConsumerState<TeknikDeskekTalepYonetimScreen> {
  String _selectedDuration = 'Tümü';
  final Set<String> _selectedRequestTypes = {};
  final Set<String> _selectedStatuses = {};

  final List<String> _durationOptions = const [
    'Tümü',
    '1 Hafta',
    '1 Ay',
    '3 Ay',
    '1 Yıl',
  ];

  void _showFilterBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => TalepFilterBottomSheet(
        durationOptions: _durationOptions,
        initialSelectedDuration: _selectedDuration,
        requestTypeOptions: const [],
        initialSelectedRequestTypes: _selectedRequestTypes,
        statusOptions: const [],
        initialSelectedStatuses: _selectedStatuses,
        onApply: (selections) {
          setState(() {
            _selectedDuration = selections.selectedDuration;
            _selectedRequestTypes
              ..clear()
              ..addAll(selections.selectedRequestTypes);
            _selectedStatuses
              ..clear()
              ..addAll(selections.selectedStatuses);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GenericTalepYonetimScreen<dynamic>(
      config: TalepYonetimConfig<dynamic>(
        title: 'Teknik Destek İsteklerini Yönet',
        addRoute: '/teknik_destek/ekle',
        enableFilter: true,
        onFilterTap: _showFilterBottomSheet,
        devamEdenBuilder:
            (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) =>
                _PlaceholderContent(
                  helper: helper,
                  message: 'Devam eden teknik destek talepleri',
                ),
        tamamlananBuilder:
            (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) =>
                _PlaceholderContent(
                  helper: helper,
                  message: 'Tamamlanan teknik destek talepleri',
                ),
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({required this.helper, required this.message});

  final TalepYonetimHelper helper;
  final String message;

  @override
  Widget build(BuildContext context) {
    return helper.buildEmptyState(message: message, onRefresh: () async {});
  }
}
