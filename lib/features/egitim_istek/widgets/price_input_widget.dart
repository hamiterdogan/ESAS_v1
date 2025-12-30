import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class PriceInputWidget extends StatelessWidget {
  final String title;
  final TextEditingController mainController;
  final TextEditingController decimalController;
  final Function(String)? onMainChanged;
  final Function(String)? onDecimalChanged;
  final double inputsOffset;

  const PriceInputWidget({
    Key? key,
    required this.title,
    required this.mainController,
    required this.decimalController,
    this.onMainChanged,
    this.onDecimalChanged,
    this.inputsOffset = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize:
                  (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) + 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Transform.translate(
          offset: Offset(0, -inputsOffset),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: mainController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: onMainChanged,
                  decoration: InputDecoration(
                    hintText: '0',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.gradientStart,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                child: Text(
                  ',',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: decimalController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(2),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: onDecimalChanged,
                  decoration: InputDecoration(
                    hintText: '00',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.gradientStart,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
