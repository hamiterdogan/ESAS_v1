import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/personel/providers/personel_providers.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';

/// Talep Eden Seçim Widget'ı - BottomSheet içinde kullanılır
class TalepEdenSecimWidget extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final String selectedTalepEden;
  final Function(String) onSelected;

  const TalepEdenSecimWidget({
    super.key,
    required this.scrollController,
    required this.selectedTalepEden,
    required this.onSelected,
  });

  @override
  ConsumerState<TalepEdenSecimWidget> createState() =>
      _TalepEdenSecimWidgetState();
}

class _TalepEdenSecimWidgetState extends ConsumerState<TalepEdenSecimWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Personel> _filterPersoneller(List<Personel> personeller) {
    if (_searchQuery.isEmpty) {
      return personeller;
    }

    final query = _searchQuery.toLowerCase().trim();
    return personeller.where((personel) {
      final fullName = personel.fullName.toLowerCase();
      final unvan = personel.unvan?.toLowerCase() ?? '';
      return fullName.contains(query) || unvan.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final personellerAsync = ref.watch(personellerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Başlık
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Talep Eden Seçin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          // Arama kutusu
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Personel ara...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF014B92)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF014B92),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Personel listesi
          Expanded(
            child: personellerAsync.when(
              data: (personeller) {
                final filteredPersoneller = _filterPersoneller(personeller);

                if (filteredPersoneller.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Sonuç bulunamadı',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: widget.scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: filteredPersoneller.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (context, index) {
                    final personel = filteredPersoneller[index];
                    final isSelected =
                        widget.selectedTalepEden == personel.fullName;

                    return ListTile(
                      onTap: () => widget.onSelected(personel.fullName),
                      tileColor: isSelected
                          ? const Color(0xFF014B92).withValues(alpha: 0.1)
                          : null,
                      title: Text(
                        personel.fullName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 15,
                          color: isSelected
                              ? const Color(0xFF014B92)
                              : Colors.black87,
                        ),
                      ),
                      subtitle: personel.unvan != null
                          ? Text(
                              personel.unvan!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF014B92))
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hata: $error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
