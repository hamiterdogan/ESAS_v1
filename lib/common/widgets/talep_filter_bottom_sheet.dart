import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class TalepFilterSelections {
  final String selectedDuration;
  final Set<String> selectedRequestTypes;
  final Set<String> selectedStatuses;

  const TalepFilterSelections({
    required this.selectedDuration,
    required this.selectedRequestTypes,
    required this.selectedStatuses,
  });
}

class TalepFilterBottomSheet extends StatefulWidget {
  const TalepFilterBottomSheet({
    super.key,
    required this.durationOptions,
    required this.initialSelectedDuration,
    required this.requestTypeOptions,
    required this.initialSelectedRequestTypes,
    required this.statusOptions,
    required this.initialSelectedStatuses,
    required this.onApply,
    this.showStatusSection = true,
    this.sheetTitle = 'Filtrele',
    this.durationTitle = 'Süre',
    this.requestTypeTitle = 'İstek Türü',
    this.statusTitle = 'Talep Durumu',
    this.allLabel = 'Tümü',
    this.requestTypeEmptyLabel = 'Henüz istek türü bilgisi yok',
  });

  final List<String> durationOptions;
  final String initialSelectedDuration;
  final List<String> requestTypeOptions;
  final Set<String> initialSelectedRequestTypes;
  final List<String> statusOptions;
  final Set<String> initialSelectedStatuses;
  final bool showStatusSection;
  final ValueChanged<TalepFilterSelections> onApply;
  final String sheetTitle;
  final String durationTitle;
  final String requestTypeTitle;
  final String statusTitle;
  final String allLabel;
  final String requestTypeEmptyLabel;

  @override
  State<TalepFilterBottomSheet> createState() => _TalepFilterBottomSheetState();
}

class _TalepFilterBottomSheetState extends State<TalepFilterBottomSheet> {
  String? _currentFilterPage;
  late String _selectedDuration;
  late Set<String> _selectedRequestTypes;
  late Set<String> _selectedStatuses;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialSelectedDuration;
    _selectedRequestTypes = {...widget.initialSelectedRequestTypes};
    _selectedStatuses = {...widget.initialSelectedStatuses};
  }

  String _getFilterTitle(String key) {
    switch (key) {
      case 'duration':
        return widget.durationTitle;
      case 'requestType':
        return widget.requestTypeTitle;
      case 'status':
        return widget.statusTitle;
      default:
        return widget.sheetTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.only(top: 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_currentFilterPage != null)
                  InkWell(
                    onTap: () {
                      setState(() => _currentFilterPage = null);
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 20),
                        SizedBox(width: 8),
                        Text('Geri', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  )
                else
                  const SizedBox(width: 64),
                const Spacer(),
                Builder(
                  builder: (context) {
                    final title = _currentFilterPage == null
                        ? widget.sheetTitle
                        : _getFilterTitle(_currentFilterPage!);
                    if (title.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const Spacer(),
                const SizedBox(width: 64),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final fadeAnimation = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                );
                return FadeTransition(opacity: fadeAnimation, child: child);
              },
              child: KeyedSubtree(
                key: ValueKey<String>(_currentFilterPage ?? 'main'),
                child: _currentFilterPage == null
                    ? _buildFilterMainPage()
                    : _buildFilterDetailPage(_currentFilterPage!),
              ),
            ),
          ),
          if (_currentFilterPage == null)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 50,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      TalepFilterSelections(
                        selectedDuration: _selectedDuration,
                        selectedRequestTypes: {..._selectedRequestTypes},
                        selectedStatuses: {..._selectedStatuses},
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Uygula',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentFilterPage != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 50,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _currentFilterPage = null);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterMainPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterMainItem(
          title: widget.durationTitle,
          selectedValue: _selectedDuration,
          onTap: () => setState(() => _currentFilterPage = 'duration'),
        ),
        if (widget.requestTypeTitle.trim().isNotEmpty &&
            widget.requestTypeOptions.isNotEmpty)
          _buildFilterMainItem(
            title: widget.requestTypeTitle,
            selectedValue: _selectedRequestTypes.isEmpty
                ? widget.allLabel
                : _selectedRequestTypes.join(', '),
            onTap: () => setState(() => _currentFilterPage = 'requestType'),
          ),
        if (widget.showStatusSection &&
            widget.statusTitle.trim().isNotEmpty &&
            widget.statusOptions.isNotEmpty)
          _buildFilterMainItem(
            title: widget.statusTitle,
            selectedValue: _selectedStatuses.isEmpty
                ? widget.allLabel
                : _selectedStatuses.join(', '),
            onTap: () => setState(() => _currentFilterPage = 'status'),
          ),
      ],
    );
  }

  Widget _buildFilterMainItem({
    required String title,
    required String selectedValue,
    required VoidCallback onTap,
  }) {
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (selectedValue != widget.allLabel) ...[
                    const SizedBox(height: 4),
                    Text(
                      selectedValue,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
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

  Widget _buildFilterDetailPage(String filterType) {
    switch (filterType) {
      case 'duration':
        return _buildDurationDetailPage();
      case 'requestType':
        if (widget.requestTypeTitle.trim().isEmpty ||
            widget.requestTypeOptions.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildRequestTypeDetailPage();
      case 'status':
        if (widget.statusTitle.trim().isEmpty || widget.statusOptions.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildStatusDetailPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDurationDetailPage() {
    return SingleChildScrollView(
      child: Column(
        children: widget.durationOptions
            .map(
              (option) => ListTile(
                dense: true,
                title: Text(
                  option,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: option == _selectedDuration
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: option == _selectedDuration
                        ? AppColors.primary
                        : AppColors.textPrimary87,
                  ),
                ),
                trailing: option == _selectedDuration
                    ? const Icon(
                        Icons.check,
                        color: AppColors.primary,
                        size: 22,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedDuration = option);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildRequestTypeDetailPage() {
    if (widget.requestTypeOptions.isEmpty) {
      return Center(child: Text(widget.requestTypeEmptyLabel));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedRequestTypes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      setState(() => _selectedRequestTypes.clear()),
                  child: const Text(
                    'Temizle',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.requestTypeOptions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              final option = widget.requestTypeOptions[index];
              final isSelected = _selectedRequestTypes.contains(option);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedRequestTypes.remove(option);
                    } else {
                      _selectedRequestTypes.add(option);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: AppColors.textOnPrimary,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDetailPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedStatuses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _selectedStatuses.clear()),
                  child: const Text(
                    'Temizle',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.statusOptions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              final option = widget.statusOptions[index];
              final isSelected = _selectedStatuses.contains(option);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedStatuses.remove(option);
                    } else {
                      _selectedStatuses.add(option);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: AppColors.textOnPrimary,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
