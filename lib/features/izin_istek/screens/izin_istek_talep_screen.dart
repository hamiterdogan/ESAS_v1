import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import '../../personel/screens/personel_secim_screen.dart';

class IzinIstekTalepScreen extends ConsumerStatefulWidget {
  const IzinIstekTalepScreen({super.key});

  @override
  ConsumerState<IzinIstekTalepScreen> createState() =>
      _IzinIstekTalepScreenState();
}

class _IzinIstekTalepScreenState extends ConsumerState<IzinIstekTalepScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _baslikController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _dersSaatiController = TextEditingController();
  final TextEditingController _adresController = TextEditingController();
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;
  bool _kvkkOnay = false;

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    _dersSaatiController.dispose();
    _adresController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_baslangicTarihi ?? now) : (_bitisTarihi ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF014B92)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _baslangicTarihi = picked;
        } else {
          _bitisTarihi = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_baslangicTarihi == null || _bitisTarihi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarihleri seçiniz.')),
      );
      return;
    }
    if (_bitisTarihi!.isBefore(_baslangicTarihi!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitiş tarihi başlangıçtan önce olamaz.')),
      );
      return;
    }
    if (!_kvkkOnay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bilgilendirmeyi onaylayınız.')),
      );
      return;
    }

    // Simulate submit
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('İzin talebi oluşturuldu.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: const _GradientAppBar(title: 'İzin İstek', onBackLabel: 'back'),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 60),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Card(
                child: Column(
                  children: [
                    _SelectableRow(
                      title: 'Başkası adına istekte bulunuyorum',
                      onTap: () async {
                        final selectedPersonel = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PersonelSecimScreen(),
                          ),
                        );

                        if (selectedPersonel != null) {
                          // Seçilen personel bilgisi ile işlem yapılabilir
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${selectedPersonel.ad} ${selectedPersonel.soyad} seçildi',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const _SelectableRow(title: 'İzin Türü'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Açıklama',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _aciklamaController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Açıklama (opsiyonel)',
                        Icons.notes,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 6.0, right: 8),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Lütfen detaylı bir açıklama giriniz.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _RedInfo(
                      text:
                          '1 günlük izin isteğinde bulunmak için “Başlangıç Tarihi” ve “Bitiş Tarihi” aynı gün seçiniz.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Başlangıç Tarihi',
                            value: _baslangicTarihi,
                            onTap: () => _pickDate(isStart: true),
                            hint: 'gg.aa.yyyy',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'Bitiş Tarihi',
                            value: _bitisTarihi,
                            onTap: () => _pickDate(isStart: false),
                            hint: 'gg.aa.yyyy',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _dersSaatiController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        'Girilimeyen Toplam Ders Saati',
                        Icons.access_time,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adresController,
                      decoration: _inputDecoration(
                        'İzinde Bulunacağı Adres',
                        Icons.home,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'İzin Kullanma Yönergesine erişmek için ',
                          style: TextStyle(fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'tıklayınız',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF014B92),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Switch(
                          value: _kvkkOnay,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF014B92),
                          onChanged: (v) => setState(() => _kvkkOnay = v),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Okudum, anladım, onaylıyorum.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: _GradientButton(
                  onPressed: _submit,
                  enabled: _kvkkOnay,
                  child: const Text(
                    'Gönder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF014B92)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF014B92)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}

class _Card extends ConsumerWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DateField extends ConsumerWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? hint;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.calendar_today,
            color: Color(0xFF014B92),
          ),
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF014B92)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
        ),
        child: Text(
          value != null
              ? '${value!.day.toString().padLeft(2, '0')}.${value!.month.toString().padLeft(2, '0')}.${value!.year}'
              : 'Tarih seçin',
          style: TextStyle(
            color: value != null ? const Color(0xFF333333) : Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _RedInfo extends ConsumerWidget {
  final String text;
  const _RedInfo({required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 6.0, right: 8),
          child: Icon(Icons.circle, size: 8, color: Colors.red),
        ),
        Expanded(
          child: Text(
            '1 günlük izin isteğinde bulunmak için “Başlangıç Tarihi” ve “Bitiş Tarihi” aynı gün seçiniz.',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _SelectableRow extends ConsumerWidget {
  final String title;
  final VoidCallback? onTap;

  const _SelectableRow({required this.title, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

class _GradientAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String onBackLabel; // placeholder to keep const constructor
  const _GradientAppBar({required this.title, required this.onBackLabel});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
}

class _GradientButton extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  const _GradientButton({
    required this.child,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? AppColors.primaryGradient
            : LinearGradient(
                colors: [
                  AppColors.gradientStart.withValues(alpha: 0.2),
                  AppColors.gradientEnd.withValues(alpha: 0.2),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}
