import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/arac_istek/widgets/generic_filter_widgets.dart';

/// Öğrenci filtresi için hierarchical filter page.
///
/// Okul → Seviye → Sınıf → Kulüp → Takım → Öğrenci
/// hiyerarşisinde çalışan generic filter widget.
class HierarchicalStringFilterPage extends StatefulWidget {
  const HierarchicalStringFilterPage({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.scrollController,
    required this.onSelectionChanged,
    required this.onClearDownstream,
    required this.onRefreshData,
    this.searchHint = 'Ara...',
    this.emptyMessage = 'Sonuç bulunamadı',
    this.noDataMessage = 'Veri bulunamadı',
  });

  /// Gösterilecek öğeler
  final List<String> items;

  /// Seçili öğeler
  final Set<String> selectedItems;

  /// Scroll controller
  final ScrollController scrollController;

  /// Seçim değiştiğinde (tek öğe için)
  final void Function(String item, bool selected) onSelectionChanged;

  /// Alt seviyeleri temizle
  final VoidCallback onClearDownstream;

  /// Veri yenileme callback
  final Future<void> Function() onRefreshData;

  /// Arama ipucu
  final String searchHint;

  /// Boş sonuç mesajı
  final String emptyMessage;

  /// Veri yok mesajı
  final String noDataMessage;

  @override
  State<HierarchicalStringFilterPage> createState() =>
      _HierarchicalStringFilterPageState();
}

class _HierarchicalStringFilterPageState
    extends State<HierarchicalStringFilterPage> {
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

  List<String> _applyFilter() {
    if (_searchQuery.isEmpty) return widget.items;
    final q = _searchQuery.toLowerCase();
    return widget.items.where((s) => s.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Center(child: Text(widget.noDataMessage));
    }

    final filtered = _applyFilter();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Field
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.searchHint,
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
          onClear: () {
            widget.selectedItems.clear();
            widget.onClearDownstream();
            widget.onRefreshData();
            setState(() {});
          },
          onSelectAll: () {
            widget.selectedItems
              ..clear()
              ..addAll(filtered);
            widget.onClearDownstream();
            widget.onRefreshData();
            setState(() {});
          },
        ),

        // List or Empty State
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.emptyMessage,
              style: const TextStyle(color: Colors.grey),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final isSelected = widget.selectedItems.contains(item);

                return CheckboxListTile(
                  dense: true,
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        widget.selectedItems.add(item);
                      } else {
                        widget.selectedItems.remove(item);
                      }
                    });
                    widget.onClearDownstream();
                    widget.onSelectionChanged(item, val ?? false);
                    widget.onRefreshData();
                  },
                  title: Text(
                    item.isEmpty ? 'Belirsiz' : item,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppColors.textPrimary,
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

/// Öğrenci filtre sheet için controller.
///
/// State yönetimini ve API çağrılarını merkezi hale getirir.
class OgrenciFilterController {
  OgrenciFilterController({required this.onRefreshData});

  final Future<void> Function({
    required Set<String> okul,
    required Set<String> seviye,
    required Set<String> sinif,
    required Set<String> kulup,
    required Set<String> takim,
    required Set<String> ogrenci,
    required StateSetter rebuild,
    bool updateSeviye,
    bool updateSinif,
    bool updateKulup,
    bool updateTakim,
    bool updateOgrenci,
    bool autoSelectAll,
  })
  onRefreshData;

  // Current selections
  final Set<String> selectedOkul = {};
  final Set<String> selectedSeviye = {};
  final Set<String> selectedSinif = {};
  final Set<String> selectedKulup = {};
  final Set<String> selectedTakim = {};
  final Set<String> selectedOgrenci = {};

  // Current page
  String currentPage = '';

  // Temp selection for detail pages
  final Set<String> tempSelection = {};

  void clearDownstreamFrom(String level) {
    switch (level) {
      case 'okul':
        selectedSeviye.clear();
        selectedSinif.clear();
        selectedKulup.clear();
        selectedTakim.clear();
        break;
      case 'seviye':
        selectedSinif.clear();
        selectedKulup.clear();
        selectedTakim.clear();
        break;
      case 'sinif':
        selectedKulup.clear();
        selectedTakim.clear();
        break;
      case 'kulup':
        selectedTakim.clear();
        break;
      case 'takim':
        // No downstream
        break;
    }
  }

  void commitTempSelection() {
    switch (currentPage) {
      case 'okul':
        selectedOkul
          ..clear()
          ..addAll(tempSelection);
        break;
      case 'seviye':
        selectedSeviye
          ..clear()
          ..addAll(tempSelection);
        break;
      case 'sinif':
        selectedSinif
          ..clear()
          ..addAll(tempSelection);
        break;
      case 'kulup':
        selectedKulup
          ..clear()
          ..addAll(tempSelection);
        break;
      case 'takim':
        selectedTakim
          ..clear()
          ..addAll(tempSelection);
        break;
      case 'ogrenci':
        selectedOgrenci
          ..clear()
          ..addAll(tempSelection);
        break;
    }
    tempSelection.clear();
  }

  void loadTempFromCurrent() {
    tempSelection.clear();
    switch (currentPage) {
      case 'okul':
        tempSelection.addAll(selectedOkul);
        break;
      case 'seviye':
        tempSelection.addAll(selectedSeviye);
        break;
      case 'sinif':
        tempSelection.addAll(selectedSinif);
        break;
      case 'kulup':
        tempSelection.addAll(selectedKulup);
        break;
      case 'takim':
        tempSelection.addAll(selectedTakim);
        break;
      case 'ogrenci':
        tempSelection.addAll(selectedOgrenci);
        break;
    }
  }

  void reset() {
    selectedOkul.clear();
    selectedSeviye.clear();
    selectedSinif.clear();
    selectedKulup.clear();
    selectedTakim.clear();
    selectedOgrenci.clear();
    currentPage = '';
    tempSelection.clear();
  }
}
