import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import '../providers/personel_providers.dart';
import '../models/personel_models.dart';

class PersonelSecimScreen extends ConsumerStatefulWidget {
  const PersonelSecimScreen({super.key});

  @override
  ConsumerState<PersonelSecimScreen> createState() =>
      _PersonelSecimScreenState();
}

class _PersonelSecimScreenState extends ConsumerState<PersonelSecimScreen> {
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
      final email = personel.email?.toLowerCase() ?? '';
      final telefon = personel.telefon ?? '';
      final adres = personel.adres?.toLowerCase() ?? '';

      return fullName.contains(query) ||
          email.contains(query) ||
          telefon.contains(query) ||
          adres.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final personellerAsync = ref.watch(personellerProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Personel Seçimi',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
            onPressed: () {
              ref.invalidate(personellerProvider);
            },
          ),
        ],
      ),
      body: personellerAsync.when(
        data: (personeller) => _buildPersonelList(context, personeller),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Personeller yükleniyor...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        error: (error, stack) =>
            _buildErrorWidget(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildPersonelList(BuildContext context, List<Personel> personeller) {
    // Filtrelenmiş personel listesi
    final filteredPersoneller = _filterPersoneller(personeller);

    if (personeller.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Personel bulunamadı',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Arama kutusu
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Personel ara...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
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
              fillColor: AppColors.textOnPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
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

        // Personel sayısı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filteredPersoneller.length} personel listeleniyor${_searchQuery.isNotEmpty ? ' (${personeller.length} toplam)' : ''}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Personel listesi
        Expanded(
          child: filteredPersoneller.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Sonuç bulunamadı',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredPersoneller.length,
                  itemBuilder: (context, index) {
                    final personel = filteredPersoneller[index];
                    return _PersonelListTile(
                      personel: personel,
                      onTap: () => _onPersonelSelected(context, personel),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Personeller yüklenirken hata oluştu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(personellerProvider);
              },
              icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
              label: const Text(
                'Tekrar Dene',
                style: TextStyle(color: AppColors.textOnPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPersonelSelected(BuildContext context, Personel personel) {
    // Personel seçildiğinde geri dön ve personeli gönder
    Navigator.pop(context, personel);

    // Veya başka bir işlem yapılabilir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${personel.fullName} seçildi'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _PersonelListTile extends ConsumerWidget {
  final Personel personel;
  final VoidCallback onTap;

  const _PersonelListTile({required this.personel, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        title: Text(
          personel.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: personel.unvan != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  personel.unvan!,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.primary,
          size: 18,
        ),
      ),
    );
  }
}
