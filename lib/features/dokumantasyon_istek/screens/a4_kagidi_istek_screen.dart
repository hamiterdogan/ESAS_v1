import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class A4KagidiIstekScreen extends StatefulWidget {
  const A4KagidiIstekScreen({super.key});

  @override
  State<A4KagidiIstekScreen> createState() => _A4KagidiIstekScreenState();
}

class _A4KagidiIstekScreenState extends State<A4KagidiIstekScreen> {
  late DateTime _teslimTarihi;
  int _paketAdedi = 1;
  late final TextEditingController _paketController;
  late final TextEditingController _aciklamaController;

  @override
  void initState() {
    super.initState();
    _teslimTarihi = DateTime.now().add(const Duration(days: 2));
    _paketController = TextEditingController(text: _paketAdedi.toString());
    _aciklamaController = TextEditingController();
  }

  @override
  void dispose() {
    _paketController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  void _updatePaketAdedi(int value) {
    if (value < 1 || value > 9999) return;
    setState(() {
      _paketAdedi = value;
      _paketController.text = value.toString();
      _paketController.selection = TextSelection.fromPosition(
        TextPosition(offset: _paketController.text.length),
      );
    });
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A4 kağıdı isteği hazırlandı (placeholder)'),
      ),
    );
  }

  void _showDateInfo() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 40, color: AppColors.gradientEnd),
            const SizedBox(height: 16),
            const Text(
              'Teslim Edilecek Tarih',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'En erken 2 iş günü sonrasını seçebilirsiniz.',
              style: TextStyle(fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientEnd,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tamam',
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'A4 Kağıdı İstek',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        ),
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teslim edilecek tarih',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                      1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: DatePickerBottomSheetWidget(
                      // Label is handled externally for alignment purposes
                      label: null,
                      initialDate: _teslimTarihi,
                      minDate: DateTime.now().add(const Duration(days: 2)),
                      maxDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (date) {
                        setState(() {
                          _teslimTarihi = date;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _showDateInfo,
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Paket Adedi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                      1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _paketAdedi > 1
                        ? () => _updatePaketAdedi(_paketAdedi - 1)
                        : null,
                    child: Container(
                      width: 50,
                      height: 46,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.remove,
                        color: _paketAdedi > 1
                            ? Colors.black
                            : Colors.grey.shade300,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 64,
                    height: 46,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _paketController,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      style: const TextStyle(fontSize: 17, color: Colors.black),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(bottom: 9),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        final intValue = int.tryParse(value);
                        if (intValue == null) return;
                        if (intValue < 1) {
                          _updatePaketAdedi(1);
                        } else if (intValue > 9999) {
                          _updatePaketAdedi(9999);
                        } else {
                          _updatePaketAdedi(intValue);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _paketAdedi < 9999
                        ? () => _updatePaketAdedi(_paketAdedi + 1)
                        : null,
                    child: Container(
                      width: 50,
                      height: 46,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.add,
                        color: _paketAdedi < 9999
                            ? Colors.black
                            : Colors.grey.shade300,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AciklamaFieldWidget(controller: _aciklamaController),
              const SizedBox(height: 32),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Gönder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
