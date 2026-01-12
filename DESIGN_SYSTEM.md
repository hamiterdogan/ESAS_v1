# ESAS App Design System

## 📦 Oluşturulan Dosyalar

### 1. Core Constants

#### `lib/core/constants/app_colors.dart`
Tüm renk tanımları:
- **Primary Colors**: `primary`, `primaryDark`, `primaryLight`
- **Background Colors**: `scaffoldBackground`, `surface`, `cardBackground`
- **Text Colors**: `textPrimary`, `textSecondary`, `textTertiary`, `textDisabled`, `textOnPrimary`
- **Border Colors**: `border`, `borderLight`, `borderFocused`, `borderError`
- **Semantic Colors**: `success`, `error`, `warning`, `info` + background variants
- **Status Colors**: `statusBeklemede`, `statusOnaylandi`, `statusReddedildi`, `statusIptalEdildi`
- **Icon Colors**: `iconPrimary`, `iconSecondary`, `iconOnPrimary`
- **Gradients**: `primaryGradient`, `headerGradient`
- **Utility Methods**: `getStatusColor()`, `getStatusBackgroundColor()`

```dart
import 'package:esas_v1/core/constants/app_colors.dart';

// Kullanım
Container(color: AppColors.primary);
Text('Hata!', style: TextStyle(color: AppColors.error));
decoration: BoxDecoration(gradient: AppColors.primaryGradient);
```

#### `lib/core/constants/app_spacing.dart`
Spacing ve border radius sabitleri:

**AppSpacing:**
- Değerler: `xxs(2)`, `xs(4)`, `sm(6)`, `md(8)`, `lg(12)`, `xl(16)`, `xxl(20)`, `xxxl(24)`, `huge(32)`, `massive(48)`
- EdgeInsets: `screenPadding`, `cardPadding`, `inputPadding`, `buttonPadding`, `allXs/Sm/Md/Lg/Xl`
- SizedBox helpers: `verticalXs`, `verticalSm`, `horizontalMd`, etc.

**AppRadius:**
- Değerler: `xs(4)`, `sm(6)`, `md(8)`, `lg(12)`, `xl(16)`, `xxl(20)`, `full(999)`
- BorderRadius getters: `cardRadius`, `buttonRadius`, `inputRadius`, `checkboxRadius`, `bottomSheetRadius`, `modalRadius`

```dart
import 'package:esas_v1/core/constants/app_spacing.dart';

// Kullanım
Padding(padding: AppSpacing.cardPadding);
SizedBox(height: AppSpacing.lg);
AppSpacing.verticalMd; // SizedBox(height: 8)
Container(decoration: BoxDecoration(borderRadius: AppRadius.cardRadius));
```

### 2. Theme

#### `lib/core/theme/app_theme.dart`
Tam kapsamlı ThemeData:
- `AppTheme.light` - Ana tema getter'ı
- ColorScheme
- AppBarTheme
- CardTheme
- Button Themes (Elevated, Text, Outlined, FAB)
- InputDecorationTheme
- Checkbox/Switch Themes
- TabBarTheme
- BottomSheet/Dialog Themes
- Divider/SnackBar Themes
- TextTheme

```dart
// main.dart'ta kullanımı
import 'package:esas_v1/core/theme/app_theme.dart';

MaterialApp(
  theme: AppTheme.light,
  // ...
);
```

### 3. Form Widgets

#### `lib/common/widgets/form/app_text_field.dart`
- **AppTextField**: Tam özellikli text input
- **AppTextArea**: Multiline variant

```dart
import 'package:esas_v1/common/widgets/form/form_widgets.dart';

AppTextField(
  label: 'Ad Soyad',
  isRequired: true,
  controller: nameController,
  prefixIcon: Icon(Icons.person),
  validator: (v) => v!.isEmpty ? 'Zorunlu alan' : null,
);

AppTextArea(
  label: 'Açıklama',
  maxLines: 5,
  hintText: 'Detaylı açıklama yazın...',
);
```

#### `lib/common/widgets/form/app_dropdown_field.dart`
- **AppDropdownField<T>**: Generic dropdown
- **AppSimpleDropdown**: String list için basit dropdown

```dart
AppDropdownField<String>(
  label: 'Departman',
  isRequired: true,
  value: selectedDepartment,
  onChanged: (v) => setState(() => selectedDepartment = v),
  items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
);

AppSimpleDropdown(
  label: 'Öncelik',
  items: ['Düşük', 'Normal', 'Yüksek'],
  value: priority,
  onChanged: (v) => setState(() => priority = v),
);
```

#### `lib/common/widgets/form/app_checkbox.dart`
- **AppCheckbox**: Checkbox with optional label
- **AppSwitch**: Toggle switch with label
- **AppRadioGroup<T>**: Radio button group
- **RadioItem<T>**: Radio item model

```dart
AppCheckbox(
  value: isAccepted,
  onChanged: (v) => setState(() => isAccepted = v ?? false),
  label: 'Şartları kabul ediyorum',
);

AppSwitch(
  value: isEnabled,
  onChanged: (v) => setState(() => isEnabled = v),
  label: 'Bildirimleri aç',
  subtitle: 'Yeni taleplerde bildirim alın',
);

AppRadioGroup<String>(
  label: 'Öncelik',
  items: [
    RadioItem(value: 'low', label: 'Düşük'),
    RadioItem(value: 'normal', label: 'Normal'),
    RadioItem(value: 'high', label: 'Yüksek'),
  ],
  value: priority,
  onChanged: (v) => setState(() => priority = v),
);
```

#### `lib/common/widgets/form/app_form_section.dart`
- **AppFormSection**: Section wrapper
- **AppFormCard**: Card wrapper
- **AppFormRow**: Horizontal layout
- **AppFormActions**: Submit/cancel buttons
- **AppFormInfoBanner**: Info/warning/error messages

```dart
AppFormCard(
  title: 'Kişisel Bilgiler',
  subtitle: 'Ad, soyad ve iletişim bilgilerinizi girin',
  isRequired: true,
  child: Column(
    children: [
      AppFormRow(
        children: [
          AppTextField(label: 'Ad', controller: firstNameController),
          AppTextField(label: 'Soyad', controller: lastNameController),
        ],
      ),
      AppSpacing.verticalMd,
      AppTextField(label: 'E-posta', controller: emailController),
    ],
  ),
);

AppFormActions(
  primaryText: 'Kaydet',
  primaryIcon: Icons.save,
  onPrimaryPressed: _submit,
  secondaryText: 'İptal',
  onSecondaryPressed: () => Navigator.pop(context),
  isLoading: isSubmitting,
);

AppFormInfoBanner(
  message: 'Form başarıyla kaydedildi',
  type: InfoBannerType.success,
);
```

## 📁 Export Dosyası

```dart
// Tüm form widget'larını tek import ile kullan
import 'package:esas_v1/common/widgets/form/form_widgets.dart';
```

## ✅ main.dart Entegrasyonu

```dart
import 'core/theme/app_theme.dart';

MaterialApp.router(
  theme: AppTheme.light,
  // ...
);
```

## 🎨 Renk Kullanım Rehberi

| Kullanım Alanı | Renk |
|----------------|------|
| Primary buton | `AppColors.primary` |
| Başlık metni | `AppColors.textPrimary` |
| Açıklama metni | `AppColors.textSecondary` |
| Form label | `AppColors.labelColor` |
| Hata mesajı | `AppColors.error` |
| Başarı mesajı | `AppColors.success` |
| Kart arka planı | `AppColors.cardBackground` |
| Sayfa arka planı | `AppColors.scaffoldBackground` |
| Border | `AppColors.border` |

## 📐 Spacing Rehberi

| Değer | Kullanım |
|-------|----------|
| `xxs (2)` | İkon ile metin arası |
| `xs (4)` | Çok küçük boşluk |
| `sm (6)` | Label ile input arası |
| `md (8)` | Standart boşluk |
| `lg (12)` | Section içi boşluk |
| `xl (16)` | Section arası boşluk |
| `xxl (20)` | Büyük section arası |
| `huge (32)` | Sayfa padding |
