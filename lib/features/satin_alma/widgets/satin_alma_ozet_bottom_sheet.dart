import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_ekle_req.dart';

/// Satın alma özet satırı için model
class SatinAlmaOzetItem {
  final String label;
  final String value;
  final bool multiLine;

  const SatinAlmaOzetItem({
    required this.label,
    required this.value,
    this.multiLine = true,
  });
}

/// Satın alma talep özeti için bottom sheet
class SatinAlmaOzetBottomSheet extends ConsumerStatefulWidget {
  final SatinAlmaEkleReq request;
  final String talepTipi;
  final List<SatinAlmaOzetItem> ozetItems;
  final Future<void> Function() onGonder;
  final VoidCallback onSuccess;
  final void Function(String error) onError;
  final Map<String, dynamic>? customJsonSnapshot;

  const SatinAlmaOzetBottomSheet({
    super.key,
    required this.request,
    required this.talepTipi,
    required this.ozetItems,
    required this.onGonder,
    required this.onSuccess,
    required this.onError,
    this.customJsonSnapshot,
  });

  @override
  ConsumerState<SatinAlmaOzetBottomSheet> createState() =>
      _SatinAlmaOzetBottomSheetState();
}

class _SatinAlmaOzetBottomSheetState
    extends ConsumerState<SatinAlmaOzetBottomSheet> {
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
              _buildHeader(context),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
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
                                      Icons.receipt_long_outlined,
                                      size: 24,
                                      color: AppColors.gradientStart,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Satın Alma Talebi Detayları',
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
                    ],
                  ),
                ),
              ),
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
    final rows = <Widget>[];

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

    // API Request Data Section
    rows.add(const SizedBox(height: 16));
    rows.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Request Data',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Text(
                _formatJsonData(
                  widget.customJsonSnapshot ?? widget.request.toJson(),
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return rows;
  }

  String _formatJsonData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    _formatJsonValue(data, buffer, 0);
    return buffer.toString();
  }

  void _formatJsonValue(dynamic value, StringBuffer buffer, int indent) {
    final indentStr = '  ' * indent;
    final nextIndentStr = '  ' * (indent + 1);

    if (value is Map) {
      if (value.isEmpty) {
        buffer.write('{}');
        return;
      }
      buffer.write('{\n');
      final entries = value.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.write('$nextIndentStr"${entry.key}": ');
        _formatJsonValue(entry.value, buffer, indent + 1);
        if (i < entries.length - 1) {
          buffer.write(',');
        }
        buffer.write('\n');
      }
      buffer.write('$indentStr}');
    } else if (value is List) {
      if (value.isEmpty) {
        buffer.write('[]');
        return;
      }
      buffer.write('[\n');
      for (int i = 0; i < value.length; i++) {
        buffer.write(nextIndentStr);
        _formatJsonValue(value[i], buffer, indent + 1);
        if (i < value.length - 1) {
          buffer.write(',');
        }
        buffer.write('\n');
      }
      buffer.write('$indentStr]');
    } else if (value is String) {
      buffer.write('"$value"');
    } else if (value is num || value is bool) {
      buffer.write(value);
    } else if (value == null) {
      buffer.write('null');
    } else {
      buffer.write('"$value"');
    }
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

Future<void> showSatinAlmaOzetBottomSheet({
  required BuildContext context,
  required SatinAlmaEkleReq request,
  required String talepTipi,
  required List<SatinAlmaOzetItem> ozetItems,
  required Future<void> Function() onGonder,
  required VoidCallback onSuccess,
  required void Function(String error) onError,
  Map<String, dynamic>? customJsonSnapshot,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SatinAlmaOzetBottomSheet(
        request: request,
        talepTipi: talepTipi,
        ozetItems: ozetItems,
        onGonder: onGonder,
        onSuccess: onSuccess,
        onError: onError,
        customJsonSnapshot: customJsonSnapshot,
      );
    },
  );
}
