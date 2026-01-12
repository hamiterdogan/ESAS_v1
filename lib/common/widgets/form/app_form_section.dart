import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';

/// Form bölümü wrapper widget'ı.
///
/// Tutarlı başlık, açıklama ve içerik düzeni sağlar.
/// Tüm form bölümleri için bu widget kullanılmalıdır.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.trailing,
    this.isRequired = false,
    this.padding,
    this.margin,
    this.divider = false,
  });

  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? trailing;
  final bool isRequired;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || titleWidget != null) ...[
            Row(
              children: [
                Expanded(
                  child:
                      titleWidget ??
                      Row(
                        children: [
                          Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isRequired)
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
          child,
          if (divider) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

/// Kart içinde form bölümü.
class AppFormCard extends StatelessWidget {
  const AppFormCard({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.trailing,
    this.isRequired = false,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation = 0,
    this.borderColor,
  });

  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? trailing;
  final bool isRequired;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double elevation;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? AppSpacing.cardPadding,
        child: AppFormSection(
          title: title,
          titleWidget: titleWidget,
          subtitle: subtitle,
          trailing: trailing,
          isRequired: isRequired,
          child: child,
        ),
      ),
    );
  }
}

/// Form satırı - yatay düzende birden fazla widget.
class AppFormRow extends StatelessWidget {
  const AppFormRow({
    super.key,
    required this.children,
    this.spacing = AppSpacing.lg,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.flexible = true,
  });

  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (flexible) Expanded(child: children[i]) else children[i],
          if (i < children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// Form eylem butonları satırı.
class AppFormActions extends StatelessWidget {
  const AppFormActions({
    super.key,
    this.primaryText,
    this.primaryIcon,
    this.onPrimaryPressed,
    this.secondaryText,
    this.secondaryIcon,
    this.onSecondaryPressed,
    this.tertiaryText,
    this.onTertiaryPressed,
    this.isLoading = false,
    this.alignment = MainAxisAlignment.end,
    this.spacing = AppSpacing.md,
  });

  final String? primaryText;
  final IconData? primaryIcon;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryText;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondaryPressed;
  final String? tertiaryText;
  final VoidCallback? onTertiaryPressed;
  final bool isLoading;
  final MainAxisAlignment alignment;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        if (tertiaryText != null) ...[
          TextButton(
            onPressed: isLoading ? null : onTertiaryPressed,
            child: Text(tertiaryText!),
          ),
          const Spacer(),
        ],
        if (secondaryText != null) ...[
          OutlinedButton.icon(
            onPressed: isLoading ? null : onSecondaryPressed,
            icon: secondaryIcon != null
                ? Icon(secondaryIcon, size: 18)
                : const SizedBox.shrink(),
            label: Text(secondaryText!),
          ),
          SizedBox(width: spacing),
        ],
        if (primaryText != null)
          ElevatedButton.icon(
            onPressed: isLoading ? null : onPrimaryPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : (primaryIcon != null
                      ? Icon(primaryIcon, size: 18)
                      : const SizedBox.shrink()),
            label: Text(primaryText!),
          ),
      ],
    );
  }
}

/// Bilgi banner'ı - form içinde bilgi gösterimi.
class AppFormInfoBanner extends StatelessWidget {
  const AppFormInfoBanner({
    super.key,
    required this.message,
    this.type = InfoBannerType.info,
    this.icon,
    this.action,
    this.onActionPressed,
    this.dismissible = false,
    this.onDismiss,
  });

  final String message;
  final InfoBannerType type;
  final IconData? icon;
  final String? action;
  final VoidCallback? onActionPressed;
  final bool dismissible;
  final VoidCallback? onDismiss;

  Color get _backgroundColor {
    switch (type) {
      case InfoBannerType.info:
        return AppColors.infoBackground;
      case InfoBannerType.success:
        return AppColors.successBackground;
      case InfoBannerType.warning:
        return AppColors.warningBackground;
      case InfoBannerType.error:
        return AppColors.errorBackground;
    }
  }

  Color get _foregroundColor {
    switch (type) {
      case InfoBannerType.info:
        return AppColors.info;
      case InfoBannerType.success:
        return AppColors.success;
      case InfoBannerType.warning:
        return AppColors.warning;
      case InfoBannerType.error:
        return AppColors.error;
    }
  }

  IconData get _defaultIcon {
    switch (type) {
      case InfoBannerType.info:
        return Icons.info_outline_rounded;
      case InfoBannerType.success:
        return Icons.check_circle_outline_rounded;
      case InfoBannerType.warning:
        return Icons.warning_amber_rounded;
      case InfoBannerType.error:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: _foregroundColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon ?? _defaultIcon, color: _foregroundColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: _foregroundColor),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onActionPressed,
              style: TextButton.styleFrom(
                foregroundColor: _foregroundColor,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(action!),
            ),
          ],
          if (dismissible) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close_rounded,
                color: _foregroundColor,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

enum InfoBannerType { info, success, warning, error }
