import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/models/teknik_destek_talep_models.dart';

/// Teknik Destek özet satırı için model
class TeknikDestekOzetItem {
  final String label;
  final String value;
  final bool multiLine;

  const TeknikDestekOzetItem({
    required this.label,
    required this.value,
    this.multiLine = true,
  });
}

/// Teknik Destek talep özeti için bottom sheet widget'ı
class TeknikDestekOzetBottomSheet extends ConsumerStatefulWidget {
  final TeknikDestekTalepEkleRequest request;
  final String talepTipi;
  final List<TeknikDestekOzetItem> ozetItems;
  final Future<void> Function() onGonder;
  final VoidCallback onSuccess;
  final void Function(String error) onError;

  const TeknikDestekOzetBottomSheet({
    super.key,
    required this.request,
    required this.talepTipi,
    required this.ozetItems,
    required this.onGonder,
    required this.onSuccess,
    required this.onError,
  });

  @override
  ConsumerState<TeknikDestekOzetBottomSheet> createState() =>
      _TeknikDestekOzetBottomSheetState();
}

class _TeknikDestekOzetBottomSheetState
    extends ConsumerState<TeknikDestekOzetBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: AppColors.textOnPrimary,
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.textOnPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Accordion Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gradientStart.withValues(
                              alpha: 0.05,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.gradientStart.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  size: 24,
                                  color: AppColors.gradientStart,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Talep Detayları',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content - Özet Satırları
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildOzetRows(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer - Butonlar
              _buildFooter(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${widget.talepTipi} Talebini Gönder',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildOzetRows() {
    final List<Widget> rows = [];

    for (int i = 0; i < widget.ozetItems.length; i++) {
      final item = widget.ozetItems[i];

      rows.add(
        _buildInfoRow(
          item.label,
          item.value,
          isLast: false,
          multiLine: item.multiLine,
        ),
      );
    }

    return rows;
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isLast = false,
    bool multiLine = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (multiLine) ...[
            // Çok satırlı görünüm - başlık ve değer ayrı satırda
            Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.textPrimary,
              ),
            ),
          ] else ...[
            // Tek satırlı görünüm - başlık ve değer aynı satırda
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isLast) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.gradientEnd),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Düzenle',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGonder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientEnd,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textOnPrimary,
                            ),
                          ),
                        )
                      : const Text(
                          'Gönder',
                          style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Future<void> _handleGonder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onGonder();
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        var errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        widget.onError(errorMessage);
      }
    }
  }
}

/// Teknik Destek özet bottom sheet'i göstermek için yardımcı fonksiyon
Future<void> showTeknikDestekOzetBottomSheet({
  required BuildContext context,
  required TeknikDestekTalepEkleRequest request,
  required String talepTipi,
  required List<TeknikDestekOzetItem> ozetItems,
  required Future<void> Function() onGonder,
  required VoidCallback onSuccess,
  required void Function(String error) onError,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext sheetContext) {
      return TeknikDestekOzetBottomSheet(
        request: request,
        talepTipi: talepTipi,
        ozetItems: ozetItems,
        onGonder: onGonder,
        onSuccess: onSuccess,
        onError: onError,
      );
    },
  );
}
