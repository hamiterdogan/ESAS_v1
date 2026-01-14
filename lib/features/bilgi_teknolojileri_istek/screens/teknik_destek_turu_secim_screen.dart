import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/screens/bilgi_teknolojileri_istek_screen.dart';

class TeknikDestekTuruSecimScreen extends StatelessWidget {
  const TeknikDestekTuruSecimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Teknik Destek Türü Seçin',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.gradientStart,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          _buildMenuItem(
            context,
            title: 'İç Hizmetler Destek',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BilgiTeknolojileriIstekScreen(
                    destekTuru: 'icHizmet',
                    baslik: 'İç Hizmetler İstek',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            title: 'Teknik Hizmetler Destek',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BilgiTeknolojileriIstekScreen(
                    destekTuru: 'teknik',
                    baslik: 'Teknik Hizmetler İstek',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        color: AppColors.textOnPrimary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
          ],
        ),
      ),
    );
  }
}
