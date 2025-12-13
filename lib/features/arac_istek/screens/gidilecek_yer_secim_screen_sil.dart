import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/arac_istek/models/gidilecek_yer_model.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';

class GidilecekYerSecimScreen extends ConsumerStatefulWidget {
  final List<GidilecekYer> initiallySelected;

  const GidilecekYerSecimScreen({super.key, this.initiallySelected = const []});

  @override
  ConsumerState<GidilecekYerSecimScreen> createState() =>
      _GidilecekYerSecimScreenState();
}

class _GidilecekYerSecimScreenState
    extends ConsumerState<GidilecekYerSecimScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<TextEditingController> _digerAddressControllers = [];
  final Map<String, TextEditingController> _selectedAddressControllers = {};
  late Set<String> _selectedIds;
  String _query = '';
  bool _digerEnabled = false;
  late ScrollController _listScrollController;

  @override
  void initState() {
    super.initState();
    _listScrollController = ScrollController();
    _selectedIds = widget.initiallySelected.map((e) => e.id).toSet();
    _digerAddressControllers.add(TextEditingController());
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    for (var controller in _digerAddressControllers) {
      controller.dispose();
    }
    for (final controller in _selectedAddressControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yerlerAsync = ref.watch(gidilecekYerlerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gidilecek Yer Seçimi',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Switch(
                  value: _digerEnabled,
                  onChanged: (value) {
                    setState(() {
                      _digerEnabled = value;
                      if (value && _digerAddressControllers.isEmpty) {
                        _digerAddressControllers.add(TextEditingController());
                      }
                    });
                  },
                  activeTrackColor: AppColors.gradientStart.withValues(
                    alpha: 0.5,
                  ),
                  activeColor: AppColors.gradientEnd,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Diğer', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          if (_digerEnabled)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _digerAddressControllers[0],
                              decoration: InputDecoration(
                                hintText: 'Semt ve Adres Giriniz',
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _digerAddressControllers[0].clear();
                                _digerAddressControllers.removeAt(0);
                                if (_digerAddressControllers.isEmpty) {
                                  _digerEnabled = false;
                                }
                              });
                            },
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_digerAddressControllers.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            for (
                              int i = 1;
                              i < _digerAddressControllers.length;
                              i++
                            )
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _digerAddressControllers[i],
                                        decoration: InputDecoration(
                                          hintText: 'Semt ve Adres Giriniz',
                                          prefixIcon: const Icon(
                                            Icons.location_on,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _digerAddressControllers[i].dispose();
                                          _digerAddressControllers.removeAt(i);
                                          if (_digerAddressControllers
                                              .isEmpty) {
                                            _digerEnabled = false;
                                          }
                                        });
                                      },
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.grey,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _digerAddressControllers.add(
                                TextEditingController(),
                              );
                            });
                          },
                          child: const Text(
                            'Yer Ekle',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_digerEnabled) const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    _digerEnabled ? 0 : 0,
                    16,
                    0,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Yer ara...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _query = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: yerlerAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Yerler yüklenemedi\n$error',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    data: (yerler) {
                      final filtered = yerler
                          .where((y) => y.ad.toLowerCase().contains(_query))
                          .toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('Sonuç bulunamadı'));
                      }

                      return ListView.separated(
                        controller: _listScrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 0.5, thickness: 0.5),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = _selectedIds.contains(item.id);
                          final shouldShowInput =
                              isSelected && !item.ad.contains('Eyüboğlu');
                          final controller = shouldShowInput
                              ? (_selectedAddressControllers[item.id] ??=
                                    TextEditingController())
                              : null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                onTap: () => _toggle(item.id),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                title: Text(
                                  item.ad,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 17,
                                    color: Colors.black87,
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) {
                                    _toggle(item.id);
                                    // Scroll down by 60px only for non-Eyüboğlu items
                                    if (!item.ad.contains('Eyüboğlu')) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (_listScrollController
                                                .hasClients) {
                                              final currentOffset =
                                                  _listScrollController.offset;
                                              final newOffset =
                                                  (currentOffset + 60).clamp(
                                                    0.0,
                                                    _listScrollController
                                                        .position
                                                        .maxScrollExtent,
                                                  );
                                              _listScrollController.animateTo(
                                                newOffset,
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeOut,
                                              );
                                            }
                                          });
                                    }
                                  },
                                  activeColor: AppColors.gradientStart,
                                ),
                              ),
                              if (shouldShowInput && controller != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    8,
                                    10,
                                    12,
                                  ),
                                  child: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: 'Semt ve Adres giriniz',
                                      prefixIcon: const Icon(Icons.location_on),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              if (shouldShowInput)
                                const Divider(height: 0.5, thickness: 0.5),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final yerler = yerlerAsync.value ?? [];
                    final secilenler = yerler
                        .where((y) => _selectedIds.contains(y.id))
                        .toList();
                    Navigator.of(context).pop(secilenler);
                  },
                  child: Text(
                    'Seçimi Tamamla (${_selectedIds.length})',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectedAddressControllers[id]?.dispose();
        _selectedAddressControllers.remove(id);
      } else {
        _selectedIds.add(id);
        _selectedAddressControllers[id] = TextEditingController();
      }
    });
  }
}
