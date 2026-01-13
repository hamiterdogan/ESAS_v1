import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/theme/app_dimens.dart';
import 'package:esas_v1/core/theme/app_typography.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';

class AppSelectionSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final void Function(T) onSelected;
  final bool searchable;
  final bool isLoading;
  final String? emptyMessage;

  const AppSelectionSheet({
    super.key,
    required this.title,
    required this.items,
    required this.itemLabelBuilder,
    required this.onSelected,
    this.searchable = true,
    this.isLoading = false,
    this.emptyMessage,
  });

  static Future<void> show<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required String Function(T) itemLabelBuilder,
    required void Function(T) onSelected,
    bool searchable = true,
    bool isLoading = false,
    String? emptyMessage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLg),
        ),
      ),
      builder: (context) => AppSelectionSheet<T>(
        title: title,
        items: items,
        itemLabelBuilder: itemLabelBuilder,
        onSelected: onSelected,
        searchable: searchable,
        isLoading: isLoading,
        emptyMessage: emptyMessage,
      ),
    );
  }

  @override
  State<AppSelectionSheet<T>> createState() => _AppSelectionSheetState<T>();
}

class _AppSelectionSheetState<T> extends State<AppSelectionSheet<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(covariant AppSelectionSheet<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filterItems(_searchController.text);
    }
  }

  void _filterItems(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = widget.items;
      });
    } else {
      setState(() {
        _filteredItems = widget.items.where((item) {
          final label = widget.itemLabelBuilder(item).toLowerCase();
          return label.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          
          if (widget.isLoading)
             const Padding(
               padding: EdgeInsets.all(32.0),
               child: Center(child: BrandedLoadingIndicator()),
             )
          else ...[
            // Search Bar
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.scaffoldBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          widget.emptyMessage ?? 'Sonuç bulunamadı',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          title: Text(widget.itemLabelBuilder(item)),
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            widget.onSelected(item);
                            Navigator.pop(context);
                          },
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textTertiary,
                            size: 20,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
