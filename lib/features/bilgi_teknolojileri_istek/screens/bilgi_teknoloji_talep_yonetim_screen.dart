import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';

/// Bilgi Teknoloji talep yönetim ekranı.
/// 
/// Bu ekran [GenericTalepYonetimScreen] widget'ını kullanarak
/// ortak talep yönetim yapısını uygular.
/// 
/// TODO: Provider'lar ve modeller oluşturulduktan sonra
/// tam implementation eklenecek.
class BilgiTeknolojiBilgiTalepYonetimScreen extends ConsumerWidget {
  const BilgiTeknolojiBilgiTalepYonetimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenericTalepYonetimScreen<dynamic>(
      config: TalepYonetimConfig<dynamic>(
        title: 'Bilgi Teknoloji İsteklerini Yönet',
        addRoute: '/bilgi_teknolojileri/ekle',
        devamEdenBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) => 
          _PlaceholderContent(helper: helper, message: 'Devam eden bilgi teknoloji talepleri'),
        tamamlananBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) => 
          _PlaceholderContent(helper: helper, message: 'Tamamlanan bilgi teknoloji talepleri'),
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
