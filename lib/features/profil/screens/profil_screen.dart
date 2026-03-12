import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esas_v1/common/widgets/validation_uyari_widget.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/core/services/auth_service.dart';
import 'package:esas_v1/core/services/auth_storage_service.dart';
import 'package:esas_v1/core/services/device_registration_service.dart';
import 'package:esas_v1/features/bildirim/providers/notification_providers.dart';

/// Kullanıcı profil bilgileri ve logout işlemi
class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  static const String _bildirimleriKapatKey = 'profil_bildirimleri_kapat_aktif';

  _ProfilData? _profilData;
  bool _bildirimleriKapat = false;
  bool _isBildirimTercihiLoading = false;
  bool _isLogoutLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    final storage = AuthStorageService();
    final adi = await storage.getAdi();
    final soyadi = await storage.getSoyadi();
    final kullaniciAdi = await storage.getKullaniciAdi();
    final email = await storage.getEmail();
    final prefs = await SharedPreferences.getInstance();
    final bildirimleriKapat = prefs.getBool(_bildirimleriKapatKey) ?? false;

    if (mounted) {
      setState(() {
        _profilData = _ProfilData(
          adSoyad: '${adi ?? ''} ${soyadi ?? ''}'.trim(),
          kullaniciAdi: kullaniciAdi ?? '-',
          email: email,
        );
        _bildirimleriKapat = bildirimleriKapat;
      });
    }
  }

  Future<void> _bildirimTercihiniGuncelle(bool value) async {
    if (_isBildirimTercihiLoading) return;

    final oncekiDeger = _bildirimleriKapat;

    setState(() {
      _bildirimleriKapat = value;
      _isBildirimTercihiLoading = true;
    });

    final repo = ref.read(notificationRepositoryProvider);
    final deviceId = await DeviceRegistrationService().getDeviceId();
    final result = await repo.bildirimTercihiGuncelle(
      deviceId: deviceId,
      notification: value,
    );

    if (!mounted) return;

    switch (result) {
      case Success():
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_bildirimleriKapatKey, value);
      case Failure(:final message):
        setState(() {
          _bildirimleriKapat = oncekiDeger;
        });
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Bildirim tercihi güncellenemedi. $message',
        );
      case Loading():
        break;
    }

    if (mounted) {
      setState(() {
        _isBildirimTercihiLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await _showLogoutConfirmation();
    if (!confirmed || !mounted) return;

    setState(() => _isLogoutLoading = true);
    await AuthService().logout(ref);
    // logout() içinde appRouter.go('/login') çağrıldığı için burada bir şey yapmaya gerek yok
  }

  Future<bool> _showLogoutConfirmation() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 60),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                const Icon(
                  Icons.logout_rounded,
                  color: AppColors.primaryDark,
                  size: 56,
                ),
                const SizedBox(height: 16),

                // Message
                const Text(
                  'Oturumu kapatmak istediğinize emin misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Vazgeç Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: AppColors.primaryDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Vazgeç',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Devam Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Devam',
                          style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Profilim',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: _profilData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + Ad kart
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            _getInitials(_profilData!.adSoyad),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profilData!.adSoyad.isEmpty
                              ? '-'
                              : _profilData!.adSoyad,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bilgi kartı
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Kullanıcı Adı',
                        value: _profilData!.kullaniciAdi,
                      ),
                      if (_profilData!.email != null) ...[
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'E-posta',
                          value: _profilData!.email!,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Switch(
                        value: !_bildirimleriKapat,
                        onChanged: _isBildirimTercihiLoading
                            ? null
                            : (value) => _bildirimTercihiniGuncelle(!value),
                        activeTrackColor: AppColors.gradientStart.withValues(
                          alpha: 0.5,
                        ),
                        activeThumbColor: AppColors.gradientEnd,
                        inactiveTrackColor: AppColors.textOnPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              !_bildirimleriKapat
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_off_rounded,
                              color: !_bildirimleriKapat
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                (!_bildirimleriKapat)
                                    ? 'Bildirimler açık'
                                    : 'Bildirimler kapalı',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (_isBildirimTercihiLoading) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Çıkış Yap butonu
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _isLogoutLoading
                            ? LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.4),
                                  AppColors.primaryDark.withValues(alpha: 0.4),
                                ],
                              )
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLogoutLoading ? null : _logout,
                        icon: _isLogoutLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(
                          _isLogoutLoading ? 'Çıkış yapılıyor...' : 'Çıkış Yap',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getInitials(String adSoyad) {
    if (adSoyad.isEmpty) return '?';
    final parts = adSoyad.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return adSoyad[0].toUpperCase();
  }
}

class _ProfilData {
  final String adSoyad;
  final String kullaniciAdi;
  final String? email;

  const _ProfilData({
    required this.adSoyad,
    required this.kullaniciAdi,
    this.email,
  });
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
