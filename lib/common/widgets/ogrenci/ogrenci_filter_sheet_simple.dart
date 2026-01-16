import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';
import 'package:esas_v1/common/widgets/ogrenci/generic_filter_widgets.dart';

/// Öğrenci filtreleme sheet'i için state yönetimi (Basit).
///
/// Okul → Seviye → Sınıf → Öğrenci
/// hiyerarşisinde çalışan basit filtre yapısı.
class OgrenciFilterStateSimple {
  OgrenciFilterStateSimple({
    Set<String>? selectedOkulKodu,
    Set<String>? selectedSeviye,
    Set<String>? selectedSinif,
    Set<String>? selectedOgrenciIds,
    List<String>? okulKoduList,
    List<String>? seviyeList,
    List<String>? sinifList,
    List<FilterOgrenciItem>? ogrenciList,
  }) : selectedOkulKodu = selectedOkulKodu ?? {},
       selectedSeviye = selectedSeviye ?? {},
       selectedSinif = selectedSinif ?? {},
       selectedOgrenciIds = selectedOgrenciIds ?? {},
       okulKoduList = okulKoduList ?? [],
       seviyeList = seviyeList ?? [],
       sinifList = sinifList ?? [],
       ogrenciList = ogrenciList ?? [];

  final Set<String> selectedOkulKodu;
  final Set<String> selectedSeviye;
  final Set<String> selectedSinif;
  final Set<String> selectedOgrenciIds;
  final List<String> okulKoduList;
  final List<String> seviyeList;
  final List<String> sinifList;
  final List<FilterOgrenciItem> ogrenciList;

  OgrenciFilterStateSimple copyWith({
    Set<String>? selectedOkulKodu,
    Set<String>? selectedSeviye,
    Set<String>? selectedSinif,
    Set<String>? selectedOgrenciIds,
    List<String>? okulKoduList,
    List<String>? seviyeList,
    List<String>? sinifList,
    List<FilterOgrenciItem>? ogrenciList,
  }) {
    return OgrenciFilterStateSimple(
      selectedOkulKodu: selectedOkulKodu ?? Set.from(this.selectedOkulKodu),
      selectedSeviye: selectedSeviye ?? Set.from(this.selectedSeviye),
      selectedSinif: selectedSinif ?? Set.from(this.selectedSinif),
      selectedOgrenciIds:
          selectedOgrenciIds ?? Set.from(this.selectedOgrenciIds),
      okulKoduList: okulKoduList ?? List.from(this.okulKoduList),
      seviyeList: seviyeList ?? List.from(this.seviyeList),
      sinifList: sinifList ?? List.from(this.sinifList),
      ogrenciList: ogrenciList ?? List.from(this.ogrenciList),
    );
  }
}

/// Öğrenci filter için summary helper metodları (Basit).
class OgrenciFilterSummaryHelperSimple {
  const OgrenciFilterSummaryHelperSimple._();

  static String summaryForSet(Set<String> ids, String itemName) {
    if (ids.isEmpty) return 'Seçiniz';
    if (ids.length <= 2) return ids.join(', ');
    return '${ids.length} $itemName seçildi';
  }

  static String summaryForOkul(Set<String> ids) => summaryForSet(ids, 'okul');
  static String summaryForSeviye(Set<String> ids) =>
      summaryForSet(ids, 'seviye');
  static String summaryForSinif(Set<String> ids) => summaryForSet(ids, 'sınıf');

  static String summaryForOgrenci(
    Set<String> ids,
    List<FilterOgrenciItem> ogrenciList,
  ) {
    if (ids.isEmpty) return 'Seçiniz';
    if (ids.length > 2) return '${ids.length} öğrenci seçildi';

    final Map<String, String> numaraToName = {};
    for (final o in ogrenciList) {
      final numara = '${o.numara}';
      if (!ids.contains(numara)) continue;

      final name = '${o.adi} ${o.soyadi}'.trim();
      if (name.isEmpty) continue;

      numaraToName.putIfAbsent(numara, () => name);
    }

    final names = numaraToName.values.toList();
    if (names.length == ids.length && names.isNotEmpty) {
      return names.join(', ');
    }

    return '${ids.length} öğrenci seçildi';
  }
}

/// Öğrenci seçim butonu etiketi (Basit).
class OgrenciSelectionButtonLabelSimple {
  const OgrenciSelectionButtonLabelSimple._();

  static String build(Set<String> ids) {
    if (ids.isEmpty) return 'Öğrenci seçiniz';
    return 'Öğrenci ekle';
  }
}

/// Öğrenci filter sheet ana menüsü (Basit).
class OgrenciFilterMainMenuSimple extends StatelessWidget {
  const OgrenciFilterMainMenuSimple({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onPageSelected,
  });

  final OgrenciFilterStateSimple state;
  final ScrollController scrollController;
  final void Function(String page) onPageSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        FilterMainMenuItem(
          title: 'Okul',
          selectedValue: OgrenciFilterSummaryHelperSimple.summaryForOkul(
            state.selectedOkulKodu,
          ),
          onTap: () => onPageSelected('okul'),
        ),
        FilterMainMenuItem(
          title: 'Seviye',
          selectedValue: OgrenciFilterSummaryHelperSimple.summaryForSeviye(
            state.selectedSeviye,
          ),
          onTap: () => onPageSelected('seviye'),
        ),
        FilterMainMenuItem(
          title: 'Sınıf',
          selectedValue: OgrenciFilterSummaryHelperSimple.summaryForSinif(
            state.selectedSinif,
          ),
          onTap: () => onPageSelected('sinif'),
        ),
        FilterMainMenuItem(
          title: 'Öğrenci',
          selectedValue: OgrenciFilterSummaryHelperSimple.summaryForOgrenci(
            state.selectedOgrenciIds,
            state.ogrenciList,
          ),
          onTap: () => onPageSelected('ogrenci'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Seçilen öğrenci sayısı: ${state.selectedOgrenciIds.length}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: state.selectedOgrenciIds.isEmpty
                  ? AppColors.error
                  : AppColors.gradientStart,
            ),
          ),
        ),
      ],
    );
  }
}

/// Öğrenci seçim filter page (Basit) - Öğrenci listesi.
class OgrenciListFilterPageSimple extends StatefulWidget {
  const OgrenciListFilterPageSimple({
    super.key,
    required this.ogrenciList,
    required this.selectedIds,
    required this.scrollController,
    required this.onSelectionChanged,
    this.onClear,
    this.onSelectAll,
  });

  final List<FilterOgrenciItem> ogrenciList;
  final Set<String> selectedIds;
  final ScrollController scrollController;
  final void Function(Set<String> newSelection) onSelectionChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSelectAll;

  @override
  State<OgrenciListFilterPageSimple> createState() =>
      _OgrenciListFilterPageSimpleState();
}

class _OgrenciListFilterPageSimpleState
    extends State<OgrenciListFilterPageSimple> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FilterOgrenciItem> _applyFilter() {
    if (_searchQuery.isEmpty) return widget.ogrenciList;
    final q = _searchQuery.toLowerCase();
    return widget.ogrenciList.where((o) {
      final fullName = '${o.adi} ${o.soyadi}'.toLowerCase();
      final numara = '${o.numara}'.toLowerCase();
      return fullName.contains(q) || numara.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ogrenciList.isEmpty) {
      return const Center(child: Text('Öğrenci verisi bulunamadı'));
    }

    final filtered = _applyFilter();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Öğrenci ara...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.gradientStart),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // Select Actions
        FilterSelectActions(
          onClear:
              widget.onClear ??
              () {
                widget.onSelectionChanged({});
              },
          onSelectAll:
              widget.onSelectAll ??
              () {
                final allIds = filtered.map((o) => '${o.numara}').toSet();
                widget.onSelectionChanged(allIds);
              },
        ),

        // List
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sonuç bulunamadı',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(12, 0, 0, 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final ogrenci = filtered[index];
                final numara = '${ogrenci.numara}';
                final isSelected = widget.selectedIds.contains(numara);
                final fullName = '${ogrenci.adi} ${ogrenci.soyadi}'.trim();

                return CheckboxListTile(
                  dense: true,
                  value: isSelected,
                  onChanged: (val) {
                    final newSelection = Set<String>.from(widget.selectedIds);
                    if (val == true) {
                      newSelection.add(numara);
                    } else {
                      newSelection.remove(numara);
                    }
                    widget.onSelectionChanged(newSelection);
                  },
                  title: Text(
                    fullName.isEmpty ? 'Öğrenci $numara' : fullName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'No: $numara - ${ogrenci.sinif}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  activeColor: AppColors.primary,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
