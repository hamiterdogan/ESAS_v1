import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/theme/app_typography.dart';
import 'package:esas_v1/core/theme/app_dimens.dart';

class AppMultiSelectionSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) itemLabelBuilder;
  final Function(List<T>) onConfirm;

  const AppMultiSelectionSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.itemLabelBuilder,
    required this.onConfirm,
  });

  static Future<void> show<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required List<T> selectedItems,
    required String Function(T) itemLabelBuilder,
    required Function(List<T>) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (context) => AppMultiSelectionSheet<T>(
        title: title,
        items: items,
        selectedItems: selectedItems,
        itemLabelBuilder: itemLabelBuilder,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<AppMultiSelectionSheet<T>> createState() => _AppMultiSelectionSheetState<T>();
}

class _AppMultiSelectionSheetState<T> extends State<AppMultiSelectionSheet<T>> {
  late List<T> _currentSelected;

  @override
  void initState() {
    super.initState();
    _currentSelected = [...widget.selectedItems];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: AppTypography.headlineSmall),
                TextButton(
                  onPressed: () {
                    widget.onConfirm(_currentSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('Tamam'),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = _currentSelected.contains(item); // Needs distinct objects or equate
                // For simplified usage, assumes reference equality or == override.
                // If items are Maps, might fail reference check if they are re-created differently.
                // But typically lists come from same provider source.
                
                return CheckboxListTile(
                  title: Text(widget.itemLabelBuilder(item)),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _currentSelected.add(item);
                      } else {
                        _currentSelected.remove(item);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
