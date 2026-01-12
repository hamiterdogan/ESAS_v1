import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/talep/models/talep_turu.dart';

/// Talep türü kartı - Ana sayfadaki grid içindeki kartlar
class TalepTuruCard extends ConsumerWidget {
  final TalepTuru talep;

  const TalepTuruCard({super.key, required this.talep});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        context.go(talep.routePath);
      },
      child: Card(
        color: Color.lerp(
          Theme.of(context).scaffoldBackgroundColor,
          AppColors.textOnPrimary,
          0.65,
        ) ?? AppColors.textOnPrimary,
        elevation: 3,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 6, right: 6, top: 8, bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon kutusu - daha büyük
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(talep.icon, size: 52, color: AppColors.textOnPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Etiket - kelimeleri satır bazında ayır
              Expanded(flex: 2, child: Center(child: _buildLabel(talep.label))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      textAlign: TextAlign.center,
      softWrap: true,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
