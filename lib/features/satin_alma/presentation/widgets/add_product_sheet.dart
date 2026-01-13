import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/satin_alma/domain/entities/satin_alma_talep_entity.dart';
import 'package:esas_v1/features/satin_alma/presentation/providers/satin_alma_providers.dart';
import 'package:esas_v1/common/widgets/app_selection_sheet.dart';
import 'package:esas_v1/core/theme/app_dimens.dart';

class AddProductSheet extends ConsumerStatefulWidget {
  final Function(SatinAlmaUrunSatirEntity) onAdd;

  const AddProductSheet({super.key, required this.onAdd});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  int? _anaKategoriId;
  int? _altKategoriId;
  String? _anaKategoriAd;
  String? _altKategoriAd;
  
  final TextEditingController _detayController = TextEditingController();
  final TextEditingController _miktarController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController(); // Birim Fiyat

  // Units
  int? _birimId;
  String? _birimAd;
  
  @override
  void dispose() {
    _detayController.dispose();
    _miktarController.dispose();
    _fiyatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anaKategorilerAsync = ref.watch(anaKategorilerProvider);
    final altKategorilerAsync = _anaKategoriId == null ? const AsyncValue.data([]) : ref.watch(altKategorilerProvider(_anaKategoriId!));
    final birimlerAsync = ref.watch(birimlerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(AppDimens.lg),
        color: Colors.white, // Theme color
        child: ListView(
          controller: scrollController,
          children: [
            const Text('Ürün Ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Ana Kategori
            ListTile(
              title: const Text('Ana Kategori'),
              subtitle: Text(_anaKategoriAd ?? 'Seçiniz'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () {
                anaKategorilerAsync.whenData((items) {
                   AppSelectionSheet.show(
                     context,
                     title: 'Ana Kategori',
                     items: items,
                     itemLabelBuilder: (item) => item['ad'] ?? '',
                     onSelected: (item) {
                       setState(() {
                         _anaKategoriId = item['id'];
                         _anaKategoriAd = item['ad'];
                         _altKategoriId = null;
                         _altKategoriAd = null;
                       });
                     },
                   );
                });
              },
            ),
            
            // Alt Kategori
            ListTile(
              title: const Text('Alt Kategori'),
              subtitle: Text(_altKategoriAd ?? 'Seçiniz'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _anaKategoriId == null ? null : () {
                // If using family provider, ref.watch ensures it triggers fetch if not cached
                // `altKategorilerAsync` is watched above.
                if (altKategorilerAsync is AsyncData) {
                    AppSelectionSheet.show(
                     context,
                     title: 'Alt Kategori',
                     items: altKategorilerAsync.value as List,
                     itemLabelBuilder: (item) => item['ad'] ?? '',
                     onSelected: (item) {
                       setState(() {
                         _altKategoriId = item['id'];
                         _altKategoriAd = item['ad'];
                       });
                     },
                   );
                }
              },
            ),
            
            TextField(
              controller: _detayController,
              decoration: const InputDecoration(labelText: 'Ürün Detayı'),
            ),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _miktarController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Miktar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Birim'),
                    subtitle: Text(_birimAd ?? 'Seç'),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () {
                        birimlerAsync.whenData((items) {
                            AppSelectionSheet.show(
                                context,
                                items: items, 
                                title: 'Birim',
                                itemLabelBuilder: (i) => i['ad'] ?? '',
                                onSelected: (i) {
                                  setState(() {
                                    _birimId = i['id'];
                                    _birimAd = i['ad'];
                                  });
                                }
                            );
                        });
                    },
                  ),
                ),
              ],
            ),
            
            TextField(
              controller: _fiyatController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Birim Fiyat'),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_anaKategoriId == null || _miktarController.text.isEmpty) {
                  return; // Show toast
                }
                
                final satir = SatinAlmaUrunSatirEntity(
                  satinAlmaAnaKategoriId: _anaKategoriId,
                  satinAlmaAltKategoriId: _altKategoriId,
                  urunDetay: _detayController.text,
                  miktar: int.tryParse(_miktarController.text) ?? 0,
                  birimId: _birimId,
                  birimFiyati: double.tryParse(_fiyatController.text) ?? 0,
                );
                
                widget.onAdd(satir);
                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
