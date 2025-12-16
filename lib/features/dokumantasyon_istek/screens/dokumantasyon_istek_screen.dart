import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class DokumantasyonIstekScreen extends StatelessWidget {
  const DokumantasyonIstekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dokümantasyon İstek',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF014B92),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Dokümantasyon İstek',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni dokümantasyon talebi oluşturmak için\naşağıdaki butonu kullanın.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dokumantasyon/turu_secim'),
        backgroundColor: const Color(0xFF014B92),
        icon: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
        label: const Text(
          'Yeni Dokümantasyon İstek',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
