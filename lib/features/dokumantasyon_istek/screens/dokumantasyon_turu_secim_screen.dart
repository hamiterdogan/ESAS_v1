import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_turu.dart';

class DokumantasyonTuruSecimScreen extends StatelessWidget {
  const DokumantasyonTuruSecimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final turler = DokumantasyonTuru.getAll();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Yeni İstek',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () => context.pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: turler.length,
        itemBuilder: (context, index) {
          final tur = turler[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(tur.routePath),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.textTertiary),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tur.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
