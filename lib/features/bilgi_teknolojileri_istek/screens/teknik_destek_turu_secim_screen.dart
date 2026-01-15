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
          'Yeni Teknik Destek İsteği',
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
            icon: Icons.home_repair_service,
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
          _buildMenuDivider(),
          _buildMenuItem(
            context,
            icon: Icons.handyman,
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
          _buildMenuDivider(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.primaryLight,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 55, right: 8),
      height: 1,
      color: Colors.grey.shade300,
    );
  }
}
