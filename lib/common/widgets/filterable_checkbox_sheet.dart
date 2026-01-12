import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';
import 'package:esas_v1/common/widgets/search_text_field.dart';
import 'package:esas_v1/common/widgets/bottom_sheet_container.dart';

/// Filtrelenebilir checkbox listesi bottom sheet widget'ı.
///
/// Birden fazla öğe seçimi için kullanılır.
/// Arama, tümünü seç/temizle, empty state destekler.
class FilterableCheckboxSheet<T> extends StatefulWidget {
  const FilterableCheckboxSheet({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onSelectionChanged,
    required this.itemLabel,
    required this.itemId,
    this.title,
    this.searchHint = 'Ara...',
    this.emptyMessage = 'Sonuç bulunamadı',
    this.showSelectAllClear = true,
    this.searchFilter,
  });

  final List<T> items;
  final Set<dynamic> selectedItems;
  final void Function(Set<dynamic>) onSelectionChanged;
  final String Function(T item) itemLabel;
  final dynamic Function(T item) itemId;
  final String? title;
  final String searchHint;
  final String emptyMessage;
  final bool showSelectAllClear;
  final bool Function(T item, String query)? searchFilter;

  /// Bottom sheet olarak göster.
  static Future<void> show<T>(
    BuildContext context, {
    required List<T> items,
    required Set<dynamic> selectedItems,
    required void Function(Set<dynamic>) onSelectionChanged,
    required String Function(T item) itemLabel,
    required dynamic Function(T item) itemId,
    String? title,
    String searchHint = 'Ara...',
    String emptyMessage = 'Sonuç bulunamadı',
    bool showSelectAllClear = true,
    bool Function(T item, String query)? searchFilter,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => FilterableCheckboxSheet<T>(
          items: items,
          selectedItems: selectedItems,
          onSelectionChanged: onSelectionChanged,
          itemLabel: itemLabel,
          itemId: itemId,
          title: title,
          searchHint: searchHint,
          emptyMessage: emptyMessage,
          showSelectAllClear: showSelectAllClear,
          searchFilter: searchFilter,
        ),
      ),
    );
  }

  @override
  State<FilterableCheckboxSheet<T>> createState() =>
      _FilterableCheckboxSheetState<T>();
}

class _FilterableCheckboxSheetState<T>
    extends State<FilterableCheckboxSheet<T>> {
  late TextEditingController _searchController;
  late Set<dynamic> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selected = Set.from(widget.selectedItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_query.isEmpty) return widget.items;

    final lower = _query.toLowerCase();
    return widget.items.where((item) {
      if (widget.searchFilter != null) {
        return widget.searchFilter!(item, _query);
      }
      return widget.itemLabel(item).toLowerCase().contains(lower);
    }).toList();
  }

  void _toggleItem(T item) {
    final id = widget.itemId(item);
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    widget.onSelectionChanged(_selected);
  }

  void _selectAll() {
    setState(() {
      for (final item in _filteredItems) {
        _selected.add(widget.itemId(item));
      }
    });
    widget.onSelectionChanged(_selected);
  }

  void _clearAll() {
    setState(() {
      for (final item in _filteredItems) {
        _selected.remove(widget.itemId(item));
      }
    });
    widget.onSelectionChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return BottomSheetContainer(
      title: widget.title,
      showCloseButton: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: SearchTextField(
              controller: _searchController,
              hintText: widget.searchHint,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),

          // Select All / Clear buttons
          if (widget.showSelectAllClear && filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text(
                      'Temizle',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selectAll,
                    child: const Text(
                      'Tümünü Seç',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1, color: AppColors.divider),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxxl),
                      child: Text(
                        widget.emptyMessage,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.massive),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final id = widget.itemId(item);
                      final isSelected = _selected.contains(id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleItem(item),
                        title: Text(
                          widget.itemLabel(item),
                          style: TextStyle(
                            fontSize: 15,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                        activeColor: AppColors.primary,
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: AppRadius.checkboxRadius,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tek seçimli filtrelenebilir liste.
class FilterableRadioSheet<T> extends StatefulWidget {
  const FilterableRadioSheet({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onSelectionChanged,
    required this.itemLabel,
    required this.itemId,
    this.title,
    this.searchHint = 'Ara...',
    this.emptyMessage = 'Sonuç bulunamadı',
  });

  final List<T> items;
  final dynamic selectedItem;
  final void Function(dynamic) onSelectionChanged;
  final String Function(T item) itemLabel;
  final dynamic Function(T item) itemId;
  final String? title;
  final String searchHint;
  final String emptyMessage;

  /// Bottom sheet olarak göster.
  static Future<void> show<T>(
    BuildContext context, {
    required List<T> items,
    required dynamic selectedItem,
    required void Function(dynamic) onSelectionChanged,
    required String Function(T item) itemLabel,
    required dynamic Function(T item) itemId,
    String? title,
    String searchHint = 'Ara...',
    String emptyMessage = 'Sonuç bulunamadı',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => FilterableRadioSheet<T>(
          items: items,
          selectedItem: selectedItem,
          onSelectionChanged: onSelectionChanged,
          itemLabel: itemLabel,
          itemId: itemId,
          title: title,
          searchHint: searchHint,
          emptyMessage: emptyMessage,
        ),
      ),
    );
  }

  @override
  State<FilterableRadioSheet<T>> createState() =>
      _FilterableRadioSheetState<T>();
}

class _FilterableRadioSheetState<T> extends State<FilterableRadioSheet<T>> {
  late TextEditingController _searchController;
  String _query = '';

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

  List<T> get _filteredItems {
    if (_query.isEmpty) return widget.items;

    final lower = _query.toLowerCase();
    return widget.items.where((item) {
      return widget.itemLabel(item).toLowerCase().contains(lower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return BottomSheetContainer(
      title: widget.title,
      showCloseButton: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: SearchTextField(
              controller: _searchController,
              hintText: widget.searchHint,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxxl),
                      child: Text(
                        widget.emptyMessage,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.massive),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final id = widget.itemId(item);
                      final isSelected = widget.selectedItem == id;

                      return RadioListTile<dynamic>(
                        value: id,
                        // ignore: deprecated_member_use
                        groupValue: widget.selectedItem,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          widget.onSelectionChanged(value);
                          Navigator.pop(context);
                        },
                        title: Text(
                          widget.itemLabel(item),
                          style: TextStyle(
                            fontSize: 15,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                        activeColor: AppColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
