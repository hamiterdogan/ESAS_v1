import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/branded_loading_dialog.dart';
import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';

class PersonelSelectorWidget extends ConsumerStatefulWidget {
  final Future<Result<PersonelSecimData>> Function() fetchFunction;
  final Function(Set<int>) onSelectionChanged;
  final Function(PersonelSecimData)? onDataLoaded;
  final Function(Set<int> gorevYeriIds, Set<int> gorevIds)? onFilterChanged;
  final Set<int> initialSelection;
  final Set<int> initialSelectedGorevYeriIds;
  final Set<int> initialSelectedGorevIds;
  final String? overrideTitle;

  const PersonelSelectorWidget({
    super.key,
    required this.fetchFunction,
    required this.onSelectionChanged,
    this.onDataLoaded,
    this.onFilterChanged,
    this.initialSelection = const {},
    this.initialSelectedGorevYeriIds = const {},
    this.initialSelectedGorevIds = const {},
    this.overrideTitle,
  });

  @override
  ConsumerState<PersonelSelectorWidget> createState() =>
      _PersonelSelectorWidgetState();
}

class _PersonelSelectorWidgetState
    extends ConsumerState<PersonelSelectorWidget> {
  final Set<int> _selectedPersonelIds = {};

  // Data State
  List<GorevYeriItem> _gorevYerleri = [];
  List<GorevItem> _gorevler = [];
  List<PersonelItem> _personeller = [];

  // Sheet State
  bool _isLoading = false;
  String? _error;
  String _currentFilterPage = '';

  // Filter Selection State (Transient within sheet)
  final Set<int> _selectedGorevYeriIds = {};
  final Set<int> _selectedGorevIds = {};

  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _selectedPersonelIds.addAll(widget.initialSelection);
    _selectedGorevYeriIds.addAll(widget.initialSelectedGorevYeriIds);
    _selectedGorevIds.addAll(widget.initialSelectedGorevIds);
  }

  @override
  void didUpdateWidget(covariant PersonelSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelection != oldWidget.initialSelection) {
      _selectedPersonelIds.clear();
      _selectedPersonelIds.addAll(widget.initialSelection);
    }
    if (widget.initialSelectedGorevYeriIds !=
        oldWidget.initialSelectedGorevYeriIds) {
      _selectedGorevYeriIds.clear();
      _selectedGorevYeriIds.addAll(widget.initialSelectedGorevYeriIds);
    }
    if (widget.initialSelectedGorevIds != oldWidget.initialSelectedGorevIds) {
      _selectedGorevIds.clear();
      _selectedGorevIds.addAll(widget.initialSelectedGorevIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _openPersonelSecimBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _buildPersonelSummary(),
                    style: TextStyle(
                      color: _selectedPersonelIds.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: _selectedPersonelIds.isNotEmpty
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (_selectedPersonelIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 10),
            child: Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: _openSecilenPersonelListesiBottomSheet,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.list,
                      color: AppColors.gradientStart,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.overrideTitle ?? 'Seçilen personelleri listele'} (${_selectedPersonelIds.length})',
                      style: const TextStyle(
                        color: AppColors.gradientStart,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _buildPersonelSummary() {
    if (_selectedPersonelIds.isEmpty) {
      return 'Personel Seçiniz';
    }

    return 'Personel ekle';
  }

  void _openSecilenPersonelListesiBottomSheet() {
    // If data isn't loaded, we might want to load it first to show names
    // But typically user would have opened the selection sheet at least once or data provided?
    // In this flow, let's assume if they clicked this, they used the selection sheet.
    // If initial selection was passed but data not fetched, we might only have IDs.
    // For now, let's just attempt to show what we have or fetch if needed.

    if (_personeller.isEmpty) {
      _fetchData().then((_) {
        if (mounted && _personeller.isNotEmpty) {
          _showSelectedListSheet();
        }
      });
    } else {
      _showSelectedListSheet();
    }
  }

  void _showSelectedListSheet() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedIds = _selectedPersonelIds.toList();
            final filteredIds = searchQuery.isEmpty
                ? selectedIds
                : selectedIds.where((pId) {
                    final p = _personeller.firstWhere(
                      (element) => element.personelId == pId,
                      orElse: () => PersonelItem(
                        personelId: pId,
                        adi: 'Personel',
                        soyadi: '#$pId',
                        gorevId: null,
                        gorevYeriId: null,
                      ),
                    );
                    final fullName = '${p.adi} ${p.soyadi}'.toLowerCase();
                    final idText = '$pId'.toLowerCase();
                    final q = searchQuery.toLowerCase();
                    return fullName.contains(q) || idText.contains(q);
                  }).toList();
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * (2 / 3),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seçilen Personeller (${_selectedPersonelIds.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Dikkat'),
                              content: const Text(
                                'Tüm personel seçimleri kaldırılacaktır. Emin misiniz?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Vazgeç'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    setSheetState(() {
                                      _selectedPersonelIds.clear();
                                    });
                                    setState(() {}); // Update parent widget UI
                                    widget.onSelectionChanged({});
                                    Navigator.pop(context); // Close sheet
                                  },
                                  child: const Text(
                                    'Evet',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text(
                          'Tümü Sil',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_selectedPersonelIds.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Personel ara...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setSheetState(() => searchQuery = val);
                        },
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredIds.length,
                      itemBuilder: (context, index) {
                        final pId = filteredIds[index];
                        final p = _personeller.firstWhere(
                          (element) => element.personelId == pId,
                          orElse: () => PersonelItem(
                            personelId: pId,
                            adi: 'Personel',
                            soyadi: '#$pId',
                            gorevId: null,
                            gorevYeriId: null,
                          ),
                        );
                        return ListTile(
                          title: Text('${p.adi} ${p.soyadi}'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.textTertiary,
                            ),
                            onPressed: () {
                              setSheetState(() {
                                _selectedPersonelIds.remove(pId);
                              });
                              setState(() {});
                              widget.onSelectionChanged(_selectedPersonelIds);
                              if (_selectedPersonelIds.isEmpty) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      BrandedLoadingDialog.show(context);
      await Future.delayed(
        const Duration(milliseconds: 10),
      ); // Allow UI to update

      final result = await widget.fetchFunction();

      switch (result) {
        case Success(:final data):
          widget.onDataLoaded?.call(data);
          setState(() {
            _personeller = data.personeller;
            _gorevler = data.gorevler;
            _gorevYerleri = data.gorevYerleri;
            _isLoading = false;
          });
        case Failure(:final message):
          setState(() {
            _isLoading = false;
            _error = message;
          });
        case Loading():
          break; // Should not happen typically
      }
    } finally {
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        // If finished but still loading state due to logic error, fix it
        if (_isLoading && _error == null && _personeller.isNotEmpty) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _openPersonelSecimBottomSheet() async {
    if (_isActionInProgress) return;
    if (_isLoading) return;

    if (_personeller.isEmpty) {
      await _fetchData();
      if (_error != null || _personeller.isEmpty) {
        // Handle error (maybe show snackbar?)
        return;
      }
    }

    setState(() => _isActionInProgress = true);

    // Prepare filter state
    final localSelectedGorevYeri = {..._selectedGorevYeriIds};
    final localSelectedGorev = {..._selectedGorevIds};
    final localSelectedPersonel = {..._selectedPersonelIds};
    _currentFilterPage = '';

    if (!mounted) {
      _isActionInProgress = false;
      return;
    }

    try {
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.67,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => StatefulBuilder(
            builder: (context, setModalState) {
              Widget buildMain() {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterMainItem(
                      title: 'Görev Yeri',
                      selectedValue: _summaryForGorevYeri(
                        localSelectedGorevYeri,
                      ),
                      onTap: () =>
                          setModalState(() => _currentFilterPage = 'gorevYeri'),
                    ),
                    _buildFilterMainItem(
                      title: 'Görev',
                      selectedValue: _summaryForGorev(localSelectedGorev),
                      onTap: () =>
                          setModalState(() => _currentFilterPage = 'gorev'),
                    ),
                    _buildFilterMainItem(
                      title: 'Personel',
                      selectedValue: _summaryForPersonel(localSelectedPersonel),
                      onTap: () =>
                          setModalState(() => _currentFilterPage = 'personel'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 25,
                      ),
                      child: Text(
                        'Seçilen personel sayısı: ${localSelectedPersonel.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: localSelectedPersonel.isEmpty
                              ? AppColors.error
                              : AppColors.gradientStart,
                        ),
                      ),
                    ),
                  ],
                );
              }

              Widget buildDetail() {
                switch (_currentFilterPage) {
                  case 'gorevYeri':
                    return _buildGorevYeriFilterPage(
                      setModalState,
                      localSelectedGorevYeri,
                      localSelectedGorev,
                      localSelectedPersonel,
                    );
                  case 'gorev':
                    return _buildGorevFilterPage(
                      setModalState,
                      localSelectedGorev,
                      localSelectedGorevYeri,
                      localSelectedPersonel,
                    );
                  case 'personel':
                  default:
                    return _buildPersonelFilterPage(
                      setModalState,
                      localSelectedPersonel,
                      localSelectedGorev,
                      localSelectedGorevYeri,
                    );
                }
              }

              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_currentFilterPage.isNotEmpty)
                                Expanded(
                                  flex: 0,
                                  child: InkWell(
                                    onTap: () => setModalState(
                                      () => _currentFilterPage = '',
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.arrow_back, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Geri',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 0),
                              if (_currentFilterPage.isNotEmpty)
                                const SizedBox(width: 12),
                              Expanded(
                                child: Align(
                                  alignment: _currentFilterPage.isEmpty
                                      ? Alignment.centerLeft
                                      : Alignment.center,
                                  child: Text(
                                    _currentFilterPage.isEmpty
                                        ? 'Filtrele'
                                        : _getFilterTitle(_currentFilterPage),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              if (_currentFilterPage.isEmpty)
                                TextButton(
                                  onPressed: () => setModalState(() {
                                    localSelectedGorevYeri.clear();
                                    localSelectedGorev.clear();
                                    localSelectedPersonel.clear();
                                  }),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                  ),
                                  child: const Text(
                                    'Tüm filtreleri temizle',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                )
                              else
                                const SizedBox(width: 0),
                            ],
                          ),
                        ),
                        const Divider(),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child: _currentFilterPage.isEmpty
                              ? buildMain()
                              : buildDetail(),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: 16,
                    right: 16,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Detay sayfadayken (Görev Yeri/Görev/Personel): sheet kapanmasın,
                          // sadece ana "Filtrele" ekranına dönsün.
                          if (_currentFilterPage.isNotEmpty) {
                            setModalState(() => _currentFilterPage = '');
                            return;
                          }

                          // Ana sayfadayken: seçimleri uygula ve sheet'i kapat.
                          setState(() {
                            _selectedPersonelIds.addAll(localSelectedPersonel);

                            _selectedGorevYeriIds.clear();
                            _selectedGorevIds.clear();
                          });

                          widget.onSelectionChanged(_selectedPersonelIds);
                          widget.onFilterChanged?.call(<int>{}, <int>{});
                          final navigator = Navigator.of(
                            context,
                            rootNavigator: true,
                          );
                          if (navigator.canPop()) {
                            navigator.pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _currentFilterPage.isEmpty ? 'Uygula' : 'Uygula',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  // --- Helper Methods & Builders ---

  String _getFilterTitle(String key) {
    switch (key) {
      case 'gorevYeri':
        return 'Görev Yeri';
      case 'gorev':
        return 'Görev';
      case 'personel':
        return 'Personel';
      default:
        return 'Filtre';
    }
  }

  String _summaryForGorevYeri(Set<int> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    final names = _gorevYerleri
        .where((g) => ids.contains(g.id))
        .map((g) => g.gorevYeriAdi)
        .toList();
    if (names.isEmpty) return '${ids.length} görev yeri seçildi';
    if (names.length <= 2) return names.join(', ');
    return '${names.length} görev yeri seçildi';
  }

  String _summaryForGorev(Set<int> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    final names = _gorevler
        .where((g) => ids.contains(g.id))
        .map((g) => g.gorevAdi)
        .toList();
    if (names.isEmpty) return '${ids.length} görev türü seçildi';
    if (names.length <= 2) return names.join(', ');
    return '${names.length} görev türü seçildi';
  }

  String _summaryForPersonel(Set<int> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    // We can't access filtered text here efficiently without filtering again, or just generic.
    return '${ids.length} personel seçildi';
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
                    ),
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
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectActions({
    required VoidCallback onClear,
    required VoidCallback onSelectAll,
  }) {
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

  Widget _buildGorevYeriFilterPage(
    StateSetter setModalState,
    Set<int> localSelectedGorevYeri,
    Set<int> localSelectedGorev,
    Set<int> localSelectedPersonel,
  ) {
    if (_gorevYerleri.isEmpty) {
      return const Center(child: Text('Görev veri verisi bulunamadı'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSelectActions(
          onClear: () => setModalState(() {
            localSelectedGorevYeri.clear();
            _syncPersonelSelectionFromFilters(
              localSelectedGorevYeri,
              localSelectedGorev,
              localSelectedPersonel,
            );
          }),
          onSelectAll: () => setModalState(() {
            localSelectedGorevYeri.clear();
            localSelectedGorevYeri.addAll(_gorevYerleri.map((g) => g.id));
            _syncPersonelSelectionFromFilters(
              localSelectedGorevYeri,
              localSelectedGorev,
              localSelectedPersonel,
            );
          }),
        ),
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _gorevYerleri.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              final yer = _gorevYerleri[index];
              final isSelected = localSelectedGorevYeri.contains(yer.id);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(
                          yer.gorevYeriAdi,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              localSelectedGorevYeri.remove(yer.id);
                            } else {
                              localSelectedGorevYeri.add(yer.id);
                            }
                            _syncPersonelSelectionFromFilters(
                              localSelectedGorevYeri,
                              localSelectedGorev,
                              localSelectedPersonel,
                            );
                          });
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
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGorevFilterPage(
    StateSetter setModalState,
    Set<int> localSelectedGorev,
    Set<int> localSelectedGorevYeri,
    Set<int> localSelectedPersonel,
  ) {
    if (_gorevler.isEmpty) {
      return const Center(child: Text('Görev verisi bulunamadı'));
    }

    // Filter gorevler based on selected gorev yeri
    final Set<int> allowedGorevIdsByPersonel = localSelectedGorevYeri.isEmpty
        ? {}
        : _personeller
              .where(
                (p) => localSelectedGorevYeri.contains(p.gorevYeriId ?? -1),
              )
              .map((p) => p.gorevId)
              .whereType<int>()
              .where((id) => id >= 0)
              .toSet();

    final filteredGorevler = _gorevler.where((gorev) {
      if (localSelectedGorevYeri.isEmpty) return true;
      final gyId = gorev.gorevYeriId ?? -1;
      final matchByYeri = gyId >= 0 && localSelectedGorevYeri.contains(gyId);
      final matchByPersonel = allowedGorevIdsByPersonel.contains(gorev.id);
      return matchByYeri || matchByPersonel;
    }).toList();

    if (filteredGorevler.isEmpty) {
      return const Center(
        child: Text('Seçilen görev yerine ait görev bulunamadı'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSelectActions(
          onClear: () => setModalState(() {
            localSelectedGorev.clear();
            _syncPersonelSelectionFromFilters(
              localSelectedGorevYeri,
              localSelectedGorev,
              localSelectedPersonel,
            );
          }),
          onSelectAll: () => setModalState(() {
            localSelectedGorev.clear();
            localSelectedGorev.addAll(filteredGorevler.map((g) => g.id));
            _syncPersonelSelectionFromFilters(
              localSelectedGorevYeri,
              localSelectedGorev,
              localSelectedPersonel,
            );
          }),
        ),
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: filteredGorevler.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              final gorev = filteredGorevler[index];
              final isSelected = localSelectedGorev.contains(gorev.id);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(
                          gorev.gorevAdi,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              localSelectedGorev.remove(gorev.id);
                            } else {
                              localSelectedGorev.add(gorev.id);
                            }
                            _syncPersonelSelectionFromFilters(
                              localSelectedGorevYeri,
                              localSelectedGorev,
                              localSelectedPersonel,
                            );
                          });
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
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _syncPersonelSelectionFromFilters(
    Set<int> selectedGorevYeri,
    Set<int> selectedGorev,
    Set<int> selectedPersonel,
  ) {
    if (selectedGorevYeri.isEmpty && selectedGorev.isEmpty) {
      selectedPersonel.clear();
      return;
    }

    final personelIds = _personeller
        .where((p) {
          final gorevYeriId = p.gorevYeriId ?? -1;
          final gorevId = p.gorevId ?? -1;
          final matchGorevYeri =
              selectedGorevYeri.isEmpty ||
              selectedGorevYeri.contains(gorevYeriId);
          final matchGorev =
              selectedGorev.isEmpty || selectedGorev.contains(gorevId);
          return matchGorevYeri && matchGorev;
        })
        .map((p) => p.personelId)
        .toSet();

    selectedPersonel
      ..clear()
      ..addAll(personelIds);
  }

  Widget _buildPersonelFilterPage(
    StateSetter setModalState,
    Set<int> localSelectedPersonel,
    Set<int> localSelectedGorev,
    Set<int> localSelectedGorevYeri,
  ) {
    if (_personeller.isEmpty) {
      return const Center(child: Text('Personel verisi bulunamadı'));
    }

    // Use a hook or local state for search controller?
    // Since this is inside a StatefulBuilder's builder, reinstantiating controller every build is bad if it rebuilt frequently?
    // But `buildDetail()` is called on modal set state.
    // Better to keep controller outside or handled carefully.
    // For simplicity, let's just use a local variable within the `StatefulBuilder` of the *page* if possible.
    // But `_buildPersonelFilterPage` is just a method.
    // I'll wrap the content in another StatefulBuilder to handle search state locally.

    return StatefulBuilder(
      builder: (context, innerSetState) {
        // This innerSetState handles search text changes
        // How to access search query?
        // Need to store it so it persists?
        // Actually, if we use a text controller created here, it will be lost on parent rebuild.
        // But the parent is the Sheet's content builder.
        // We can use a controller stored in properties or passed in.
        // Let's create a controller on the fly? No.
        // Let's use a closure key or just a simple variable?
        // This is a common Flutter issue.
        // I will use a ref to hold the controller if possible or just use a ValueNotifier?
        // Simplest is to make a `_PersonelFilterView` widget. But I want to keep it in one file if small.
        // I'll make a helper widget `_PersonelSearchList`.
        return _PersonelSearchList(
          personeller: _personeller,
          selectedPersonelIds: localSelectedPersonel,
          selectedGorevIds: localSelectedGorev,
          selectedGorevYeriIds: localSelectedGorevYeri,
          onSelectionChanged: (ids) {
            setModalState(() {
              // The widget inside handles UI update for itself, but we need to update the Set instance
              // Actually passing the set by reference works.
            });
          },
        );
      },
    );
  }
}

class _PersonelSearchList extends StatefulWidget {
  final List<PersonelItem> personeller;
  final Set<int> selectedPersonelIds;
  final Set<int> selectedGorevIds;
  final Set<int> selectedGorevYeriIds;
  final Function(Set<int>) onSelectionChanged;

  const _PersonelSearchList({
    required this.personeller,
    required this.selectedPersonelIds,
    required this.selectedGorevIds,
    required this.selectedGorevYeriIds,
    required this.onSelectionChanged,
  });

  @override
  _PersonelSearchListState createState() => _PersonelSearchListState();
}

class _PersonelSearchListState extends State<_PersonelSearchList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.personeller.where((p) {
      final matchGorev =
          widget.selectedGorevIds.isEmpty ||
          widget.selectedGorevIds.contains(p.gorevId ?? -1);
      final matchGorevYeri =
          widget.selectedGorevYeriIds.isEmpty ||
          widget.selectedGorevYeriIds.contains(p.gorevYeriId ?? -1);
      final fullName = '${p.adi} ${p.soyadi}'.toLowerCase();
      final matchSearch =
          _searchQuery.isEmpty || fullName.contains(_searchQuery.toLowerCase());
      return matchGorev && matchGorevYeri && matchSearch;
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Personel ara...',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Seçilmiş: ${widget.selectedPersonelIds.length} / ${filtered.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => widget.selectedPersonelIds.clear());
                    widget.onSelectionChanged(widget.selectedPersonelIds);
                  },
                  child: const Text(
                    'Temizle',
                    style: TextStyle(fontSize: 14, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () {
                    setState(() {
                      widget.selectedPersonelIds.clear();
                      widget.selectedPersonelIds.addAll(
                        filtered.map((p) => p.personelId),
                      );
                    });
                    widget.onSelectionChanged(widget.selectedPersonelIds);
                  },
                  child: const Text(
                    'Tümü',
                    style: TextStyle(fontSize: 14, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sonuç bulunamadı',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColors.borderLight,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final kisi = filtered[index];
                final isSelected = widget.selectedPersonelIds.contains(
                  kisi.personelId,
                );
                return ListTile(
                  dense: true,
                  title: Text(
                    '${kisi.adi} ${kisi.soyadi}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          widget.selectedPersonelIds.remove(kisi.personelId);
                        } else {
                          widget.selectedPersonelIds.add(kisi.personelId);
                        }
                      });
                      widget.onSelectionChanged(widget.selectedPersonelIds);
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
                );
              },
            ),
          ),
      ],
    );
  }
}
