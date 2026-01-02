import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/satin_alma/models/odeme_turu.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/common/widgets/branded_loading_dialog.dart';

class OdemeSekliWidget extends ConsumerStatefulWidget {
  final OdemeTuru? selectedOdemeTuru;
  final Function(OdemeTuru) onOdemeTuruSelected;
  final String title;
  final VoidCallback? onBeforeShowSheet;
  final VoidCallback? onAfterHideSheet;

  const OdemeSekliWidget({
    Key? key,
    required this.selectedOdemeTuru,
    required this.onOdemeTuruSelected,
    this.title = 'Ödeme Şekli',
    this.onBeforeShowSheet,
    this.onAfterHideSheet,
  }) : super(key: key);

  @override
  ConsumerState<OdemeSekliWidget> createState() => _OdemeSekliWidgetState();
}

class _OdemeSekliWidgetState extends ConsumerState<OdemeSekliWidget> {
  bool _showingLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize:
                (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) + 1,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showOdemeSekliBottomSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.selectedOdemeTuru?.isim ?? 'Seçiniz',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.selectedOdemeTuru == null
                        ? Colors.grey.shade500
                        : Colors.black,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showOdemeSekliBottomSheet() async {
    FocusScope.of(context).unfocus();
    widget.onBeforeShowSheet?.call();

    // Check if we already have data
    if (ref.read(odemeTurleriProvider).hasValue) {
      _openBottomSheet();
      return;
    }

    BrandedLoadingDialog.show(context);

    try {
      // Wait for the future to complete
      await ref.read(odemeTurleriProvider.future);

      if (mounted) {
        BrandedLoadingDialog.hide(context);
        setState(() {
          _showingLoading = false;
        });
        _openBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        setState(() {
          _showingLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme türleri yüklenemedi: $e')),
        );
      }
    }
  }

  void _openBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final asyncOdemeTurleri = ref.watch(odemeTurleriProvider);

              return asyncOdemeTurleri.when(
                loading: () => SizedBox(
                  height: 240,
                  child: Center(child: BrandedLoadingIndicator(size: 56)),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Ödeme türleri alınamadı',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ),
                data: (odemeTurleri) {
                  final sheetHeight = (120 + odemeTurleri.length * 56.0).clamp(
                    220.0,
                    MediaQuery.of(ctx).size.height * 0.65,
                  );

                  return SizedBox(
                    height: sheetHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Ödeme Şekli Seçiniz',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      (Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.fontSize ??
                                          16) +
                                      2,
                                ),
                          ),
                        ),
                        Expanded(
                          child: odemeTurleri.isEmpty
                              ? Center(
                                  child: Text(
                                    'Kayıt bulunamadı',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: odemeTurleri.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = odemeTurleri[index];
                                    final isSelected =
                                        widget.selectedOdemeTuru?.id == item.id;
                                    return ListTile(
                                      title: Text(
                                        item.isim,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppColors.gradientStart
                                              : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: AppColors.gradientStart,
                                            )
                                          : null,
                                      onTap: () {
                                        widget.onOdemeTuruSelected(item);
                                        FocusScope.of(context).unfocus();
                                        Navigator.pop(context);
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
      widget.onAfterHideSheet?.call();
    });
  }
}
