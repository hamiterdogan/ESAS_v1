import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_icecek_ikram_data.dart';
import 'package:esas_v1/common/widgets/time_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/providers/yiyecek_icecek_providers.dart';

class YiyecekIcecekIkramEkleScreen extends ConsumerStatefulWidget {
  final YiyecekIcecekIkramData? existingData;

  const YiyecekIcecekIkramEkleScreen({super.key, this.existingData});

  @override
  ConsumerState<YiyecekIcecekIkramEkleScreen> createState() =>
      _YiyecekIcecekIkramEkleScreenState();
}

class _YiyecekIcecekIkramEkleScreenState
    extends ConsumerState<YiyecekIcecekIkramEkleScreen> {
  int _kurumIciAdet = 0;
  int _kurumDisiAdet = 0;
  late final TextEditingController _kurumIciController;
  late final TextEditingController _kurumDisiController;
  late final TextEditingController _toplamController;
  final TextEditingController _ikramSecinizController = TextEditingController();
  final FocusNode _ikramFocusNode = FocusNode();

  // Validation Focus Nodes
  final FocusNode _kurumIciFocusNode = FocusNode();
  final FocusNode _ikramSecimiFocusNode = FocusNode();

  List<String> _selectedIkramlar = [];
  int _baslangicSaat = 8;
  int _baslangicDakika = 0;
  int _bitisSaat = 17;
  int _bitisDakika = 30;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _kurumIciAdet = widget.existingData!.kurumIciAdet;
      _kurumDisiAdet = widget.existingData!.kurumDisiAdet;
      _selectedIkramlar = List.from(widget.existingData!.secilenIkramlar);

      // Parse time
      final startParts = widget.existingData!.baslangicSaati.split(':');
      if (startParts.length == 2) {
        _baslangicSaat = int.parse(startParts[0]);
        _baslangicDakika = int.parse(startParts[1]);
      }

      final endParts = widget.existingData!.bitisSaati.split(':');
      if (endParts.length == 2) {
        _bitisSaat = int.parse(endParts[0]);
        _bitisDakika = int.parse(endParts[1]);
      }

      // Handle custom text for 'Diğer'
      for (var ikram in _selectedIkramlar) {
        if (ikram.startsWith('Diğer: ')) {
          _ikramSecinizController.text = ikram.substring(7);
          // Replace 'Diğer: ...' with just 'Diğer' in list for checkbox logic
          int index = _selectedIkramlar.indexOf(ikram);
          _selectedIkramlar[index] = 'Diğer';
        }
      }
    }

    _kurumIciController = TextEditingController(text: _kurumIciAdet.toString());
    _kurumDisiController = TextEditingController(
      text: _kurumDisiAdet.toString(),
    );
    _toplamController = TextEditingController(
      text: '${_kurumIciAdet + _kurumDisiAdet} kişi',
    );
  }

  @override
  void dispose() {
    _kurumIciController.dispose();
    _kurumDisiController.dispose();
    _toplamController.dispose();
    _ikramSecinizController.dispose();
    _ikramFocusNode.dispose();
    _kurumIciFocusNode.dispose();
    _ikramSecimiFocusNode.dispose();
    super.dispose();
  }

  void _updateToplam() {
    final total = _kurumIciAdet + _kurumDisiAdet;
    _toplamController.text = '$total kişi';
  }

  void _updateKurumIciAdet(int value) {
    FocusScope.of(context).unfocus();
    if (value < 0 || value > 9999) return;
    setState(() {
      _kurumIciAdet = value;
      _kurumIciController.text = value.toString();
      _kurumIciController.selection = TextSelection.fromPosition(
        TextPosition(offset: _kurumIciController.text.length),
      );
      _updateToplam();
    });
  }

  void _updateKurumDisiAdet(int value) {
    FocusScope.of(context).unfocus();
    if (value < 0 || value > 9999) return;
    setState(() {
      _kurumDisiAdet = value;
      _kurumDisiController.text = value.toString();
      _kurumDisiController.selection = TextSelection.fromPosition(
        TextPosition(offset: _kurumDisiController.text.length),
      );
      _updateToplam();
    });
  }

  Widget _buildSpinnerRow(
    int value,
    TextEditingController controller,
    Function(int) onUpdate, {
    FocusNode? focusNode,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: value > 0 ? () => onUpdate(value - 1) : null,
          child: Container(
            width: 44,
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              color: AppColors.textOnPrimary,
            ),
            child: Icon(
              Icons.remove,
              color: value > 0 ? AppColors.textPrimary : Colors.grey.shade300,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              color: AppColors.textOnPrimary,
            ),
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: const TextStyle(
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 9),
              ),
              onChanged: (val) {
                if (val.isEmpty) return;
                final intValue = int.tryParse(val);
                if (intValue == null) return;
                if (intValue < 0) {
                  onUpdate(0);
                } else if (intValue > 9999) {
                  onUpdate(9999);
                } else {
                  onUpdate(intValue);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: value < 9999 ? () => onUpdate(value + 1) : null,
          child: Container(
            width: 44,
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              color: AppColors.textOnPrimary,
            ),
            child: Icon(
              Icons.add,
              color: value < 9999
                  ? AppColors.textPrimary
                  : Colors.grey.shade300,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIkramSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showIkramSelectionBottomSheet,
          borderRadius: BorderRadius.circular(8),
          child: Focus(
            focusNode: _ikramSecimiFocusNode,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedIkramlar.isEmpty
                        ? 'İkram Seçiniz'
                        : '${_selectedIkramlar.length} İkram Seçildi',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedIkramlar.isEmpty
                          ? Colors.grey.shade600
                          : AppColors.textPrimary,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        if (_selectedIkramlar.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _showSelectedIkramlarBottomSheet,
              icon: const Icon(Icons.list, size: 19),
              label: const Text(
                'Seçilen İkramlar',
                style: TextStyle(fontSize: 15),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gradientStart,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showIkramSelectionBottomSheet({
    bool scrollToBottom = false,
    String? validationError,
  }) {
    bool hasScrolled = false;
    // Local state to manage error visibility inside the sheet
    String? currentError = validationError;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.textOnPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final ikramTurleriAsync = ref.watch(ikramTurleriProvider);

                if (scrollToBottom && !hasScrolled) {
                  hasScrolled = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_ikramFocusNode.canRequestFocus) {
                      _ikramFocusNode.requestFocus();
                    }
                    if (scrollController.hasClients) {
                      scrollController.animateTo(
                        scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }

                // Calculate bottom padding for keyboard
                final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

                return Container(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardHeight),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        'İkram Seçiniz',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ikramTurleriAsync.when(
                          data: (ikramTurleri) {
                            return StatefulBuilder(
                              builder: (context, setSheetState) {
                                return ListView.builder(
                                  controller: scrollController,
                                  itemCount: ikramTurleri.length,
                                  itemBuilder: (context, index) {
                                    final ikram = ikramTurleri[index];
                                    final isSelected = _selectedIkramlar
                                        .contains(ikram);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CheckboxListTile(
                                          title: Text(ikram),
                                          value: isSelected,
                                          activeColor: AppColors.gradientStart,
                                          onChanged: (bool? value) {
                                            setSheetState(() {
                                              if (value == true) {
                                                _selectedIkramlar.add(ikram);
                                              } else {
                                                _selectedIkramlar.remove(ikram);
                                              }
                                              // Clear error if user changes selection (optional, but good UX)
                                              if (currentError != null) {
                                                currentError = null;
                                              }
                                            });
                                            // Update main screen as well
                                            setState(() {});
                                          },
                                        ),
                                        if (ikram == 'Diğer' && isSelected)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                TextField(
                                                  controller:
                                                      _ikramSecinizController,
                                                  focusNode: _ikramFocusNode,
                                                  onChanged: (value) {
                                                    // Clear error when user types
                                                    if (currentError != null &&
                                                        value.isNotEmpty) {
                                                      setSheetState(() {
                                                        currentError = null;
                                                      });
                                                    }
                                                  },
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'İkramı belirtiniz',
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            currentError != null
                                                            ? AppColors.error
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                      ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                currentError !=
                                                                    null
                                                                ? AppColors
                                                                      .error
                                                                : Colors
                                                                      .grey
                                                                      .shade300,
                                                          ),
                                                        ),
                                                    fillColor:
                                                        AppColors.textOnPrimary,
                                                    filled: true,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: BrandedLoadingIndicator()),
                          error: (error, stack) =>
                              Center(child: Text('Hata: $error')),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gradientStart,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Tamam',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSelectedIkramlarBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Seçilen İkramlar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedIkramlar.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Henüz ikram seçilmedi.'),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _selectedIkramlar.length,
                        itemBuilder: (context, index) {
                          final ikram = _selectedIkramlar[index];
                          String displayText = ikram;
                          if (ikram == 'Diğer' &&
                              _ikramSecinizController.text.isNotEmpty) {
                            displayText =
                                'Diğer: ${_ikramSecinizController.text}';
                          }
                          return ListTile(
                            title: Text(displayText),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setSheetState(() {
                                  _selectedIkramlar.removeAt(index);
                                });
                                // Update main screen state
                                setState(() {});
                                if (_selectedIkramlar.isEmpty) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showWarningBottomSheet(String message) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
          decoration: const BoxDecoration(
            color: AppColors.textOnPrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'İkram Ekle',
            style: TextStyle(
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
                Text(
                  'Katılımcı Sayıları',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    color: AppColors.inputLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kurum İçi',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontSize:
                                      (Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.fontSize ??
                                          14) +
                                      1,
                                  color: AppColors.inputLabelColor,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _buildSpinnerRow(
                            _kurumIciAdet,
                            _kurumIciController,
                            _updateKurumIciAdet,
                            focusNode: _kurumIciFocusNode,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kurum Dışı',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontSize:
                                      (Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.fontSize ??
                                          14) +
                                      1,
                                  color: AppColors.inputLabelColor,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _buildSpinnerRow(
                            _kurumDisiAdet,
                            _kurumDisiController,
                            _updateKurumDisiAdet,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Toplam Input
                Text(
                  'Toplam',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    color: AppColors.inputLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.5,
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _toplamController,
                    readOnly: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.textOnPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TimePickerBottomSheetWidget(
                        labelStyle: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(
                              fontSize:
                                  (Theme.of(
                                        context,
                                      ).textTheme.titleSmall?.fontSize ??
                                      14) +
                                  1,
                              color: AppColors.inputLabelColor,
                            ),
                        initialHour: _baslangicSaat,
                        initialMinute: _baslangicDakika,
                        minHour: 0,
                        maxHour: 23,
                        allowedMinutes: const [
                          0,
                          5,
                          10,
                          15,
                          20,
                          25,
                          30,
                          35,
                          40,
                          45,
                          50,
                          55,
                        ],
                        label: 'Başlangıç Saati',
                        onTimeChanged: (hour, minute) {
                          setState(() {
                            _baslangicSaat = hour;
                            _baslangicDakika = minute;

                            // Eğer başlangıç saati bitiş saatinden büyük veya eşitse
                            // Bitiş saatini başlangıç saatinden sonraya ayarla (5 dk ekle)
                            if (_baslangicSaat > _bitisSaat ||
                                (_baslangicSaat == _bitisSaat &&
                                    _baslangicDakika >= _bitisDakika)) {
                              // 5 dakika ekle
                              int nextMinute = _baslangicDakika + 5;
                              int nextHour = _baslangicSaat;

                              if (nextMinute >= 60) {
                                nextMinute -= 60;
                                nextHour += 1;
                              }

                              if (nextHour > 23) {
                                // Gün sonuna geldik, en son saati seçelim
                                nextHour = 23;
                                nextMinute = 55;
                                // Eğer hala başlangıç >= bitiş ise (başlangıç da 23:55 ise) yapacak bir şey yok, eşit kalabilir
                                // veya başlangıç saatini geri çekebiliriz.
                                // Kullanıcı deneyimi için basitçe set edelim.
                              }

                              _bitisSaat = nextHour;
                              _bitisDakika = nextMinute;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TimePickerBottomSheetWidget(
                        labelStyle: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(
                              fontSize:
                                  (Theme.of(
                                        context,
                                      ).textTheme.titleSmall?.fontSize ??
                                      14) +
                                  1,
                              color: AppColors.inputLabelColor,
                            ),
                        initialHour: _bitisSaat,
                        initialMinute: _bitisDakika,
                        minHour: _baslangicSaat,
                        maxHour: 23,
                        allowedMinutes: const [
                          0,
                          5,
                          10,
                          15,
                          20,
                          25,
                          30,
                          35,
                          40,
                          45,
                          50,
                          55,
                        ],
                        label: 'Bitiş Saati',
                        onTimeChanged: (hour, minute) {
                          // Bitiş saati başlangıç saatinden küçük olamaz kontrolü
                          if (hour < _baslangicSaat ||
                              (hour == _baslangicSaat &&
                                  minute <= _baslangicDakika)) {
                            // Validasyon
                            return;
                          }
                          setState(() {
                            _bitisSaat = hour;
                            _bitisDakika = minute;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildIkramSelection(),
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
              onPressed: () {
                // 1. Katılımcı sayısı kontrolü
                if (_kurumIciAdet + _kurumDisiAdet == 0) {
                  _showWarningBottomSheet(
                    "Lütfen katılımcı sayılarını belirtiniz",
                  ).then((_) {
                    // Warning kapandıktan sonra focuslan
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_kurumIciFocusNode.canRequestFocus) {
                        _kurumIciFocusNode.requestFocus();
                      }
                    });
                  });
                  return;
                }

                // 2. İkram seçimi kontrolü
                if (_selectedIkramlar.isEmpty) {
                  _showWarningBottomSheet("Lütfen ikram seçiniz").then((_) {
                    // Warning kapandıktan sonra focuslan
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_ikramSecimiFocusNode.canRequestFocus) {
                        _ikramSecimiFocusNode.requestFocus();
                      }
                    });
                  });
                  return;
                }

                // 3. Diğer İkram Input Kontrolü
                if (_selectedIkramlar.contains('Diğer') &&
                    _ikramSecinizController.text.trim().isEmpty) {
                  _showIkramSelectionBottomSheet(
                    scrollToBottom: true,
                    validationError: "Lütfen ikramı belirtiniz",
                  );
                  return;
                }

                final data = YiyecekIcecekIkramData(
                  kurumIciAdet: _kurumIciAdet,
                  kurumDisiAdet: _kurumDisiAdet,
                  baslangicSaati:
                      '${_baslangicSaat.toString().padLeft(2, '0')}:${_baslangicDakika.toString().padLeft(2, '0')}',
                  bitisSaati:
                      '${_bitisSaat.toString().padLeft(2, '0')}:${_bitisDakika.toString().padLeft(2, '0')}',
                  secilenIkramlar: _selectedIkramlar.map((e) {
                    if (e == 'Diğer' &&
                        _ikramSecinizController.text.isNotEmpty) {
                      return 'Diğer: ${_ikramSecinizController.text}';
                    }
                    return e;
                  }).toList(),
                );
                Navigator.pop(context, data);
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
