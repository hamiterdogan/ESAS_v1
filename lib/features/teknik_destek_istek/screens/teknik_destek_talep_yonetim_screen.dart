import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';

/// Teknik Destek talep yönetim ekranı.
/// 
/// Bu ekran [GenericTalepYonetimScreen] widget'ını kullanarak
/// ortak talep yönetim yapısını uygular.
/// 
/// TODO: Provider'lar ve modeller oluşturulduktan sonra
/// tam implementation eklenecek.
class TeknikDeskekTalepYonetimScreen extends ConsumerWidget {
  const TeknikDeskekTalepYonetimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenericTalepYonetimScreen<dynamic>(
      config: TalepYonetimConfig<dynamic>(
        title: 'Teknik Destek İsteklerini Yönet',
        addRoute: '/teknik_destek/ekle',
        devamEdenBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) => 
          _PlaceholderContent(helper: helper, message: 'Devam eden teknik destek talepleri'),
        tamamlananBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) => 
          _PlaceholderContent(helper: helper, message: 'Tamamlanan teknik destek talepleri'),
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({
    required this.helper,
    required this.message,
  });

  final TalepYonetimHelper helper;
  final String message;

  @override
  Widget build(BuildContext context) {
    return helper.buildEmptyState(
      message: message,
      onRefresh: () async {},
    );
  }
}
