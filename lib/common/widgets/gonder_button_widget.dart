import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

/// Ortak "Gönder" butonu widget'ı
///
/// Tüm form ekranlarında kullanılan standardize edilmiş gönder butonudur.
/// Gradient arka plan, özelleştirilebilir callback ve loading durumunu destekler.
class GonderButtonWidget extends StatelessWidget {
  /// Butona basıldığında çalışacak callback fonksiyon
  final VoidCallback? onPressed;

  /// Butonun diğer adı (buttonLabel yerine daha özgün ad)
  /// Varsayılan olarak "Gönder"
  final String buttonLabel;

  /// Butonun loading durumda olup olmadığını belirtir
  final bool isLoading;

  /// Buton boyutu (padding ve border radius için)
  final double padding;

  /// Border radius değeri
  final double borderRadius;

  /// GlobalKey - ekran içinde scroll etmek için kullanılabilir
  final Key? buttonKey;

  /// TextStyle özelleştirmesi (isteğe bağlı)
  final TextStyle? textStyle;

  /// Arka plan rengi - eğer null ise gradient kullanılır
  final Color? backgroundColor;

  /// Gradient arka plan - eğer backgroundColor null değilse ignored
  final Gradient? backgroundGradient;

  /// Buton aktif/pasif durumu
  final bool enabled;

  const GonderButtonWidget({
    Key? key,
    this.onPressed,
    this.buttonLabel = 'Gönder',
    this.isLoading = false,
    this.padding = 16.0,
    this.borderRadius = 12.0,
    this.buttonKey,
    this.textStyle,
    this.backgroundColor,
    this.backgroundGradient,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasGradient = backgroundColor == null;
    final effectiveEnabled = enabled && !isLoading;

    final decoration = hasGradient
        ? BoxDecoration(
            gradient: effectiveEnabled
                ? (backgroundGradient ?? AppColors.primaryGradient)
                : LinearGradient(
                    colors: [
                      AppColors.gradientStart.withValues(alpha: 0.2),
                      AppColors.gradientEnd.withValues(alpha: 0.2),
                    ],
                  ),
            borderRadius: BorderRadius.circular(borderRadius),
          )
        : BoxDecoration(
            color: effectiveEnabled
                ? backgroundColor
                : backgroundColor?.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(borderRadius),
          );

    return DecoratedBox(
      key: buttonKey,
      decoration: decoration,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (effectiveEnabled) ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: padding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            disabledBackgroundColor: Colors.transparent,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  buttonLabel,
                  style:
                      textStyle ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                ),
        ),
      ),
    );
  }
}
