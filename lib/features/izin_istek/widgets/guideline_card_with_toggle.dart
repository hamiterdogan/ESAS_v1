import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';

/// Yönerge PDF kartı ve onay toggle button widget'ı
///
/// İzin istek ekranlarında kullanılmak üzere tasarlanmış,
/// PDF yönergesi gösterimi ve kullanıcı onayı için toggle button içeren widget
class GuidelineCardWithToggle extends StatelessWidget {
  /// PDF başlığı (ekranda gösterilecek)
  final String pdfTitle;

  /// PDF URL adresi
  final String pdfUrl;

  /// Kart içinde gösterilecek buton metni
  final String cardButtonText;

  /// Toggle button yanında gösterilecek onay metni
  final String toggleText;

  /// Toggle button durumu (açık/kapalı)
  final bool toggleValue;

  /// Toggle button değiştiğinde çağrılacak fonksiyon
  final ValueChanged<bool> onToggleChanged;

  const GuidelineCardWithToggle({
    super.key,
    required this.pdfTitle,
    required this.pdfUrl,
    required this.cardButtonText,
    required this.toggleText,
    required this.toggleValue,
    required this.onToggleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // PDF Kartı
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PdfViewerScreen(title: pdfTitle, pdfUrl: pdfUrl),
                  ),
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.gradientStart,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cardButtonText,
                      style: TextStyle(
                        color: AppColors.gradientStart,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Onay Toggle Button
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Switch(
              value: toggleValue,
              inactiveTrackColor: Colors.white,
              onChanged: onToggleChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.gradientStart,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                toggleText,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
