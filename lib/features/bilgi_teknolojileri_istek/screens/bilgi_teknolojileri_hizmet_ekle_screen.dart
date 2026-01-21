import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/repositories/bilgi_teknolojileri_istek_repository.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/models/bilgi_teknolojileri_hizmet_data.dart';

class BilgiTeknolojileriHizmetEkleScreen extends ConsumerStatefulWidget {
  final BilgiTeknolojileriHizmetData? existingData;
  final String destekTuru;

  const BilgiTeknolojileriHizmetEkleScreen({
    super.key,
    this.existingData,
    this.destekTuru = 'bilgiTek',
  });

  @override
  ConsumerState<BilgiTeknolojileriHizmetEkleScreen> createState() =>
      _BilgiTeknolojileriHizmetEkleScreenState();
}

class _BilgiTeknolojileriHizmetEkleScreenState
    extends ConsumerState<BilgiTeknolojileriHizmetEkleScreen> {
  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _hizmetDetayiController = TextEditingController();
  final FocusNode _aciklamaFocusNode = FocusNode();
  final FocusNode _kategoriFocusNode = FocusNode();
  String? _selectedHizmetKategorisi;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      // Initialize form fields with existing data
      _selectedHizmetKategorisi = widget.existingData!.kategori;
      _hizmetDetayiController.text = widget.existingData!.hizmetDetayi;
      _aciklamaController.text = widget.existingData!.aciklama;
    }
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _hizmetDetayiController.dispose();
    _aciklamaFocusNode.dispose();
    _kategoriFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showWarningBottomSheet(String message) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.textOnPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showHizmetKategorisiBottomSheet() async {
    FocusScope.of(context).unfocus();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final asyncKategoriler = ref.watch(
                hizmetKategorileriProvider(widget.destekTuru),
              );
              return asyncKategoriler.when(
                loading: () => const SizedBox(
                  height: 240,
                  child: BrandedLoadingOverlay(
                    indicatorSize: 64,
                    strokeWidth: 6,
                  ),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hizmet kategorileri alınamadı',
                          style: TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.refresh(
                            hizmetKategorileriProvider(widget.destekTuru),
                          ),
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (kategoriler) {
                  return SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hizmet Kategorisi Seçin',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.fontSize ??
                                              16) +
                                          4,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        Expanded(
                          child: kategoriler.isEmpty
                              ? Center(
                                  child: Text(
                                    'Kayıt bulunamadı',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: kategoriler.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    thickness: 0.6,
                                    color: Colors.grey.shade300,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = kategoriler[index];
                                    final isSelected =
                                        _selectedHizmetKategorisi == item;
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize:
                                              (Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.fontSize ??
                                                  16) +
                                              2,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: AppColors.gradientStart,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedHizmetKategorisi = item;
                                        });
                                        Navigator.pop(ctx);
                                      },
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
          ),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            widget.destekTuru == 'teknik'
                ? 'Teknik Hizmet Ekle'
                : widget.destekTuru == 'icHizmet'
                ? 'İç Hizmet Ekle'
                : 'Bilgi Teknolojileri Hizmet Ekle',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hizmet Kategorisi Widget
                Text(
                  'Hizmet Kategorisi',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inputLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showHizmetKategorisiBottomSheet,
                  child: Focus(
                    focusNode: _kategoriFocusNode,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                              _selectedHizmetKategorisi ?? 'Seçiniz',
                              style: TextStyle(
                                color: _selectedHizmetKategorisi == null
                                    ? Colors.grey.shade600
                                    : AppColors.textPrimary,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Hizmet Detayı Widget
                Text(
                  'Hizmet Detayı',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inputLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _hizmetDetayiController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Hizmet detayını giriniz...',
                    filled: true,
                    fillColor: AppColors.textOnPrimary,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // Hizmet kategorisi kontrolü
                if (_selectedHizmetKategorisi == null) {
                  await _showWarningBottomSheet(
                    'Lütfen hizmet kategorisi seçiniz',
                  );
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_kategoriFocusNode.canRequestFocus) {
                      _kategoriFocusNode.requestFocus();
                    }
                  });
                  return;
                }

                // Verileri hazırla ve geri dön
                final data = BilgiTeknolojileriHizmetData(
                  kategori: _selectedHizmetKategorisi!,
                  hizmetDetayi: _hizmetDetayiController.text.trim(),
                  aciklama: _aciklamaController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context, data);
                }
              },
              child: const Text(
                'Tamam',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
