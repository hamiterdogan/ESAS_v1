import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

/// Generic selectable list filter page.
///
/// Okul, Seviye, Sınıf, Kulüp, Takım gibi benzer yapıdaki
/// filter page'leri için ortak widget.
class GenericFilterListPage<T> extends StatefulWidget {
  const GenericFilterListPage({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onSelectionChanged,
    required this.getItemLabel,
    required this.scrollController,
    this.searchHint = 'Ara...',
    this.emptyMessage = 'Sonuç bulunamadı',
    this.noDataMessage = 'Veri bulunamadı',
    this.showSelectActions = true,
    this.onClear,
    this.onSelectAll,
  });

  /// Tüm öğeler listesi
  final List<T> items;

  /// Seçili öğeler
  final Set<T> selectedItems;

  /// Seçim değiştiğinde çağrılır
  final void Function(Set<T> newSelection) onSelectionChanged;

  /// Öğe etiketini döndüren fonksiyon
  final String Function(T item) getItemLabel;

  /// Scroll controller
  final ScrollController scrollController;

  /// Arama ipucu
  final String searchHint;

  /// Boş sonuç mesajı
  final String emptyMessage;

  /// Veri yok mesajı
  final String noDataMessage;

  /// Seçim action'larını göster (Temizle/Tümü)
  final bool showSelectActions;

  /// Temizle callback
  final VoidCallback? onClear;

  /// Tümünü seç callback
  final VoidCallback? onSelectAll;

  @override
  State<GenericFilterListPage<T>> createState() =>
      _GenericFilterListPageState<T>();
}

class _GenericFilterListPageState<T> extends State<GenericFilterListPage<T>> {
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

  List<T> _applyFilter() {
    if (_searchQuery.isEmpty) return widget.items;
    final q = _searchQuery.toLowerCase();
    return widget.items.where((item) {
      final label = widget.getItemLabel(item).toLowerCase();
      return label.contains(q);
    }).toList();
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
        if (widget.showSelectActions)
          FilterSelectActions(
            onClear:
                widget.onClear ??
                () {
                  widget.onSelectionChanged({});
                },
            onSelectAll:
                widget.onSelectAll ??
                () {
                  widget.onSelectionChanged(filtered.toSet());
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
                final label = widget.getItemLabel(item);

                return ListTile(
                  dense: true,
                  title: Text(
                    label.isEmpty ? 'Belirsiz' : label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: GestureDetector(
                    onTap: () {
                      final newSelection = Set<T>.from(widget.selectedItems);
                      if (isSelected) {
                        newSelection.remove(item);
                      } else {
                        newSelection.add(item);
                      }
                      widget.onSelectionChanged(newSelection);
                    },
                    child: Container(
                      width: 40,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primaryLight,
                          width: 1.5,
                        ),
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? Center(
                              child: Icon(
                                Icons.check,
                                color: AppColors.textOnPrimary,
                                size: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                  onTap: () {
                    final newSelection = Set<T>.from(widget.selectedItems);
                    if (isSelected) {
                      newSelection.remove(item);
                    } else {
                      newSelection.add(item);
                    }
                    widget.onSelectionChanged(newSelection);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Filter sayfaları için Temizle/Tümü action butonları.
class FilterSelectActions extends StatelessWidget {
  const FilterSelectActions({
    super.key,
    required this.onClear,
    required this.onSelectAll,
  });

  final VoidCallback onClear;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Temizle', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSelectAll,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Tümü', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

/// Filter ana menü öğesi.
class FilterMainMenuItem extends StatelessWidget {
  const FilterMainMenuItem({
    super.key,
    required this.title,
    required this.selectedValue,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String selectedValue;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (selectedValue != 'Seçiniz') ...[
                    const SizedBox(height: 4),
                    Text(
                      selectedValue,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gradientStart,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// Seçilebilir liste öğesi (BottomSheet içinde).
class SelectableListItem extends StatelessWidget {
  const SelectableListItem({
    super.key,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.primaryLight,
              width: 1.5,
            ),
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          child: isSelected
              ? Center(
                  child: Icon(
                    Icons.check,
                    color: AppColors.textOnPrimary,
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
      onTap: onTap,
    );
  }
}
