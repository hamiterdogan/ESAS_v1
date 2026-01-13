import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/common/widgets/primary_app_bar.dart';
import 'package:esas_v1/common/widgets/app_dialogs.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/theme/app_dimens.dart';
import 'package:esas_v1/features/arac_istek/presentation/providers/arac_talep_providers.dart';
import 'package:esas_v1/features/arac_istek/presentation/widgets/route_selection_widget.dart';
import 'package:esas_v1/features/arac_istek/presentation/widgets/date_time_selection_widget.dart';
import 'package:esas_v1/features/arac_istek/presentation/widgets/passenger_selection_widget.dart';
import 'package:esas_v1/features/arac_istek/presentation/widgets/reason_and_description_widget.dart';

class AracTalepEklePage extends ConsumerWidget {
  const AracTalepEklePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for Success/Error
    ref.listen(aracTalepFormProvider, (previous, next) {
      if (next.isSuccess) {
        AppDialogs.showSuccess(
          context,
          'Araç talebiniz başarıyla oluşturuldu.',
          onOk: () {
            Navigator.pop(context);
          },
        );
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppDialogs.showError(context, next.errorMessage!);
      }
    });

    final isLoading = ref.watch(
      aracTalepFormProvider.select((s) => s.isLoading),
    );

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Araç Talebi Oluştur',
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textOnPrimary),
          onPressed: () async {
            final confirm = await AppDialogs.showFormExitConfirm(context);
            if (confirm && context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              children: [
                const RouteSelectionWidget(),
                const SizedBox(height: AppDimens.lg),
                const DateTimeSelectionWidget(),
                const SizedBox(height: AppDimens.lg),
                const PassengerSelectionWidget(),
                const SizedBox(height: AppDimens.lg),
                const ReasonAndDescriptionWidget(),
                const SizedBox(height: AppDimens.xxl),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            ref.read(aracTalepFormProvider.notifier).submit();
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Talep Oluştur'),
                  ),
                ),
                const SizedBox(height: AppDimens.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
