import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/routing/router.dart';
import 'package:esas_v1/core/services/auth_storage_service.dart';
import 'package:esas_v1/core/services/notification_service.dart';
import 'package:esas_v1/core/utils/jwt_decoder.dart';
import 'package:esas_v1/features/auth/providers/auth_providers.dart';
import 'package:esas_v1/features/auth/repositories/auth_repository.dart';
import 'package:esas_v1/features/bildirim/providers/notification_providers.dart';
import 'package:esas_v1/features/bildirim/repositories/notification_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // Varsayılan kimlik bilgileri boş bırakılır
  final _kullaniciAdiController = TextEditingController(text: '');
  final _sifreController = TextEditingController(text: '');
  bool _sifreGizli = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    final kullaniciAdi = _kullaniciAdiController.text.trim();
    final sifre = _sifreController.text;

    // Validasyon
    if (kullaniciAdi.isEmpty || sifre.isEmpty) {
      _showHataBilgisi('Kullanıcı adı ve şifre alanı boş bırakılamaz');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.girisYap(
        kullaniciAdi: kullaniciAdi,
        sifre: sifre,
      );

      if (!mounted) return;

      if (response == null) {
        // 401 – yanlış kullanıcı adı / şifre
        _showHataBilgisi('Kullanıcı adı veya şifre hatalı.');
        return;
      }

      if (!response.basarili) {
        _showHataBilgisi(
          response.token.isEmpty
              ? 'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.'
              : 'Giriş yapılamadı. Lütfen tekrar deneyin.',
        );
        return;
      }

      // Başarılı giriş: bilgileri kaydet ve state'leri güncelle
      final storage = ref.read(authStorageServiceProvider);

      // Yeni oturum başlamadan önce eski token/cache izlerini temizle
      await storage.clear();
      ref.read(tokenProvider.notifier).setToken('');
      ref.invalidate(dioProvider);
      ref.invalidate(notificationRepositoryProvider);

      await storage.saveLogin(response);
      ref.read(tokenProvider.notifier).setToken(response.token);
      authStateNotifier.value = true;

      // Yeni JWT ile Dio/Repository instance'larını zorunlu olarak yeniden oluştur
      ref.invalidate(dioProvider);
      ref.invalidate(notificationRepositoryProvider);

      // ⚡ KRİTİK: Riverpod provider zincirine güvenmiyoruz.
      // Yeni JWT ile doğrudan yeni bir Dio + Repository oluşturup
      // RegisterToken'ı bu taze instance ile çağırıyoruz.
      final freshDio = Dio(
        BaseOptions(
          baseUrl: 'https://esasapi.eyuboglu.k12.tr/api',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${response.token}',
          },
        ),
      );

      if (kDebugMode) {
        freshDio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/Notification/RegisterToken') {
                final authHeader =
                    options.headers['Authorization']?.toString() ?? '';
                final token = authHeader.startsWith('Bearer ')
                    ? authHeader.substring(7)
                    : authHeader;
                final masked = token.length > 20
                    ? '${token.substring(0, 10)}...${token.substring(token.length - 10)}'
                    : token;
                final pid = JwtDecoder.getPersonelId(token);
                final kullaniciAdi = JwtDecoder.getKullaniciAdi(token);
                print(
                  '🛰️ RegisterToken Authorization (masked): Bearer $masked',
                );
                print(
                  '🧾 RegisterToken JWT çözümleme → personelId: $pid, kullaniciAdi: $kullaniciAdi',
                );
              }
              handler.next(options);
            },
          ),
        );
      }

      final freshRepo = NotificationRepositoryImpl(dio: freshDio);

      if (kDebugMode) {
        print('🔑 RegisterToken çağrısı yeni JWT ile yapılıyor...');
        print('   PersonelId: ${response.personelId}');
        print('   KullanıcıAdı: ${response.kullaniciAdi}');
      }

      final registeredFcmToken = await NotificationService()
          .getAndRegisterToken(freshRepo, forceRefresh: true);

      if (registeredFcmToken == null || registeredFcmToken.isEmpty) {
        _showHataBilgisi(
          'Bildirim kaydı tamamlanamadı. Lütfen internet bağlantınızı kontrol edip tekrar giriş yapın.',
        );
        return;
      }

      if (!mounted) return;
      context.go('/');
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('süre')) {
        _showHataBilgisi(
          'Bağlantı zaman aşımı. Lütfen internet bağlantınızı kontrol edin.',
        );
      } else if (msg.contains('connection') || msg.contains('socket')) {
        _showHataBilgisi(
          'Sunucuya ulaşılamıyor. Lütfen internet bağlantınızı kontrol edin.',
        );
      } else {
        _showHataBilgisi('Bağlantı hatası oluştu. Lütfen tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showHataBilgisi(String mesaj) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 56),
              const SizedBox(height: 16),
              Text(
                mesaj,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/eek_logo_yatay.png',
                      width: 380,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Başlık
                  const Text(
                    'ESAS Kullanıcı Girişi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Kullanıcı Adı
                  _buildLabel('Kullanıcı Adı'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _kullaniciAdiController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('TC Kimlik veya E-posta'),
                  ),
                  const SizedBox(height: 20),

                  // Şifre
                  _buildLabel('Şifre'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _sifreController,
                    obscureText: _sifreGizli,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _girisYap(),
                    decoration: _inputDecoration('').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _sifreGizli
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () =>
                            setState(() => _sifreGizli = !_sifreGizli),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Giriş butonu
                  _GradientButton(
                    label: 'Giriş',
                    onPressed: _isLoading ? () {} : _girisYap,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Şifremi Unuttum
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const SifremiUnuttumBottomSheet(),
                      );
                    },
                    child: const Text(
                      'Şifremi Unuttum',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

/// Diğer formlardaki "Gönder" butonuyla aynı gradient stil
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

class SifremiUnuttumBottomSheet extends StatefulWidget {
  const SifremiUnuttumBottomSheet({super.key});

  @override
  State<SifremiUnuttumBottomSheet> createState() =>
      _SifremiUnuttumBottomSheetState();
}

class _SifremiUnuttumBottomSheetState extends State<SifremiUnuttumBottomSheet> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear any previous error
    });

    final repo = AuthRepository();
    final mesaj = await repo.sifremiUnuttum(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (mesaj == 'Şifreniz mail adresinize gönderildi.') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Şifreniz belirttiğiniz mail adresinize gönderilmiştir.',
          ),
        ),
      );
    } else if (mesaj ==
        'Girdiğiniz mail adresiyle eşleşen bir kayıt bulunamadı.') {
      // Inline error message
      setState(() {
        _errorMessage = 'Girdiğiniz mail adresi bulunamadı.';
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mesaj)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const defaultPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 24);
    final insets = MediaQuery.of(context).viewInsets;

    return Container(
      padding: defaultPadding.copyWith(
        bottom: defaultPadding.bottom + insets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Şifremi Unuttum',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'E-mail',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    style: const TextStyle(fontSize: 17),
                    decoration: const InputDecoration(
                      hintText: 'ad.soyad',
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                  ),
                ),
                Container(width: 1, color: const Color(0xFF9FA8BF)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDF4), // Light gray from design
                    border: Border.all(
                      color: const Color(0xFF9FA8BF),
                      width: 1.3,
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '@eyuboglu.k12.tr',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFD35B5B), // Muted, softer red
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 24),
          ],
          _GradientButton(
            label: 'Gönder',
            isLoading: _isLoading,
            onPressed: _isLoading ? () {} : _gonder,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Geri Dön',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
