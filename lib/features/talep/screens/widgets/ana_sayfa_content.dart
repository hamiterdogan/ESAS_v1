import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/talep/models/talep_turu.dart';
import 'package:esas_v1/features/talep/screens/widgets/talep_turu_card.dart';

/// Ana Sayfa tab içeriği - Talep türlerinin grid görünümü
class AnaSayfaContent extends ConsumerWidget {
  const AnaSayfaContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talepTurleri = TalepTuru.getAll();

    return Container(
      color: const Color(0xFFEEF1F5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 4,
            childAspectRatio: 1.25,
          ),
          itemCount: talepTurleri.length,
          itemBuilder: (context, index) {
            final talep = talepTurleri[index];
            return TalepTuruCard(talep: talep);
          },
        ),
      ),
    );
  }
}
