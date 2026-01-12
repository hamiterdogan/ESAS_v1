import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';

/// Gidilecek yer listesi bölümü.
class GidilecekYerSection<T> extends StatelessWidget {
  const GidilecekYerSection({
    super.key,
    required this.entries,
    required this.onYerEkle,
    required this.onYerSil,
    required this.getYerAdi,
    required this.getAdresController,
    required this.getFocusNode,
    required this.isAdresRequired,
  });

  final List<T> entries;
  final VoidCallback onYerEkle;
  final void Function(int index) onYerSil;
  final String Function(T entry) getYerAdi;
  final TextEditingController Function(T entry) getAdresController;
  final FocusNode Function(T entry) getFocusNode;
  final bool Function(T entry) isAdresRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gidilecek Yer',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize:
                (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) + 1,
          ),
        ),
        const SizedBox(height: 16),

        // Yer Ekle Button
        InkWell(
          onTap: onYerEkle,
          borderRadius: AppRadius.inputRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.inputRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_location_alt_outlined,
                  color: AppColors.gradientStart,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Yer Ekle',
                  style: TextStyle(
                    color: AppColors.gradientStart,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Entries List
        if (entries.isEmpty)
          const Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Henüz yer eklenmedi.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          )
        else
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final yerAdi = getYerAdi(entry);
                    final showAdres = isAdresRequired(entry);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  yerAdi,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.textTertiary,
                                ),
                                onPressed: () => onYerSil(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 22,
                              ),
                            ],
                          ),
                          if (showAdres)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 12,
                              ),
                              child: TextField(
                                focusNode: getFocusNode(entry),
                                controller: getAdresController(entry),
                                decoration: InputDecoration(
                                  hintText: 'Semt ve adres giriniz',
                                  prefixIcon: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          const Divider(height: 16, thickness: 0.8),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tahmini mesafe bölümü.
class TahminiMesafeSection extends StatelessWidget {
  const TahminiMesafeSection({
    super.key,
    required this.mesafe,
    required this.controller,
    required this.onMesafeChanged,
    required this.onInfoTap,
    this.minValue = 1,
    this.maxValue = 9999,
  });

  final int mesafe;
  final TextEditingController controller;
  final void Function(int newValue) onMesafeChanged;
  final VoidCallback onInfoTap;
  final int minValue;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tahmini Mesafe (km)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                    1,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onInfoTap,
              child: const Icon(
                Icons.info_outline,
                color: AppColors.gradientStart,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decrease button
            GestureDetector(
              onTap: mesafe > minValue
                  ? () {
                      FocusScope.of(context).unfocus();
                      onMesafeChanged(mesafe - 1);
                    }
                  : null,
              child: Container(
                width: 50,
                height: 46,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  color: AppColors.textOnPrimary,
                ),
                child: Icon(
                  Icons.remove,
                  color: mesafe > minValue
                      ? AppColors.textPrimary
                      : Colors.grey.shade300,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Input field
            Container(
              width: 64,
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                color: AppColors.textOnPrimary,
              ),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                onChanged: (value) {
                  final intVal = int.tryParse(value);
                  if (intVal != null &&
                      intVal >= minValue &&
                      intVal <= maxValue) {
                    onMesafeChanged(intVal);
                  }
                },
                onSubmitted: (value) {
                  final intVal = int.tryParse(value);
                  if (intVal == null || intVal < minValue) {
                    controller.text = minValue.toString();
                    onMesafeChanged(minValue);
                  } else if (intVal > maxValue) {
                    controller.text = maxValue.toString();
                    onMesafeChanged(maxValue);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),

            // Increase button
            GestureDetector(
              onTap: mesafe < maxValue
                  ? () {
                      FocusScope.of(context).unfocus();
                      onMesafeChanged(mesafe + 1);
                    }
                  : null,
              child: Container(
                width: 50,
                height: 46,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  color: AppColors.textOnPrimary,
                ),
                child: Icon(
                  Icons.add,
                  color: mesafe < maxValue
                      ? AppColors.textPrimary
                      : Colors.grey.shade300,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tarih ve saat seçim bölümü.
class TarihSaatSection extends StatelessWidget {
  const TarihSaatSection({
    super.key,
    required this.tarih,
    required this.gidisSaat,
    required this.gidisDakika,
    required this.donusSaat,
    required this.donusDakika,
    required this.onTarihSecildi,
    required this.onGidisSaatSecildi,
    required this.onDonusSaatSecildi,
    required this.formatDateShort,
    required this.formatTime,
  });

  final DateTime? tarih;
  final int gidisSaat;
  final int gidisDakika;
  final int donusSaat;
  final int donusDakika;
  final VoidCallback onTarihSecildi;
  final VoidCallback onGidisSaatSecildi;
  final VoidCallback onDonusSaatSecildi;
  final String Function(DateTime date) formatDateShort;
  final String Function(int hour, int minute) formatTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tarih ve Saat',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize:
                (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) + 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Tarih
            Expanded(
              child: _DateTimePickerTile(
                icon: Icons.calendar_today,
                label: tarih != null ? formatDateShort(tarih!) : 'Tarih seç',
                onTap: onTarihSecildi,
              ),
            ),
            const SizedBox(width: 12),
            // Gidiş saati
            Expanded(
              child: _DateTimePickerTile(
                icon: Icons.access_time,
                label: formatTime(gidisSaat, gidisDakika),
                subtitle: 'Gidiş',
                onTap: onGidisSaatSecildi,
              ),
            ),
            const SizedBox(width: 12),
            // Dönüş saati
            Expanded(
              child: _DateTimePickerTile(
                icon: Icons.access_time_filled,
                label: formatTime(donusSaat, donusDakika),
                subtitle: 'Dönüş',
                onTap: onDonusSaatSecildi,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateTimePickerTile extends StatelessWidget {
  const _DateTimePickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.gradientStart),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçim bölümü kartı (Personel, Öğrenci, Neden seçimi için).
class SelectionSectionCard extends StatelessWidget {
  const SelectionSectionCard({
    super.key,
    required this.title,
    required this.selectedSummary,
    required this.onTap,
    this.icon = Icons.people_outline,
  });

  final String title;
  final String selectedSummary;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        selectedSummary.isNotEmpty &&
        selectedSummary != 'Seçiniz' &&
        !selectedSummary.contains('seçiniz');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasSelection ? AppColors.gradientStart : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasSelection
                  ? AppColors.gradientStart
                  : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasSelection ? selectedSummary : 'Seçim yapınız',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasSelection
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: hasSelection
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
