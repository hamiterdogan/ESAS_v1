import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';

/// Standart bottom sheet container wrapper'ı.
///
/// Tutarlı köşe, padding ve stil sağlar.
class BottomSheetContainer extends StatelessWidget {
  const BottomSheetContainer({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.showDragHandle = true,
    this.showCloseButton = false,
    this.onClose,
    this.padding,
    this.maxHeight,
    this.backgroundColor,
  });

  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final bool showDragHandle;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry? padding;
  final double? maxHeight;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight!)
          : null,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppRadius.bottomSheetRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          if (showDragHandle)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Title bar
          if (title != null || titleWidget != null || showCloseButton)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                showDragHandle ? AppSpacing.lg : AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child:
                        titleWidget ??
                        Text(
                          title ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                  ),
                  if (showCloseButton)
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: onClose ?? () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: AppColors.iconSecondary,
                    ),
                ],
              ),
            ),

          // Content
          Flexible(
            child: Padding(
              padding:
                  padding ??
                  const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.massive,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bilgi/durum gösterim bottom sheet'i.
class StatusBottomSheet extends StatelessWidget {
  const StatusBottomSheet({
    super.key,
    required this.message,
    this.isError = false,
    this.buttonText = 'Tamam',
    this.onButtonPressed,
  });

  final String message;
  final bool isError;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      showDragHandle: false,
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 64,
            color: isError ? AppColors.error : AppColors.success,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onButtonPressed ?? () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonRadius,
                ),
              ),
              child: Text(buttonText),
            ),
          ),
          const SizedBox(height: AppSpacing.massive),
        ],
      ),
    );
  }

  /// Status bottom sheet'i göstermek için helper method.
  static Future<void> show(
    BuildContext context, {
    required String message,
    bool isError = false,
    String buttonText = 'Tamam',
    VoidCallback? onButtonPressed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => StatusBottomSheet(
        message: message,
        isError: isError,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
      ),
    );
  }
}

/// Info bottom sheet.
class InfoBottomSheet extends StatelessWidget {
  const InfoBottomSheet({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.buttonText = 'Tamam',
  });

  final String title;
  final String message;
  final IconData icon;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      showDragHandle: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.xxxl,
        AppSpacing.xxxl,
        AppSpacing.massive,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonRadius,
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  /// Info bottom sheet'i göstermek için helper method.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    String buttonText = 'Tamam',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => InfoBottomSheet(
        title: title,
        message: message,
        icon: icon,
        buttonText: buttonText,
      ),
    );
  }
}
