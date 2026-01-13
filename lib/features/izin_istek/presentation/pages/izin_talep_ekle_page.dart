import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/common/widgets/primary_app_bar.dart';
import 'package:esas_v1/common/widgets/app_dialogs.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/theme/app_dimens.dart';
import 'package:esas_v1/features/izin_istek/presentation/providers/izin_talep_providers.dart';
import 'package:esas_v1/features/izin_istek/presentation/widgets/izin_type_selector_widget.dart';
import 'package:esas_v1/features/izin_istek/presentation/widgets/date_duration_selector_widget.dart';
import 'package:esas_v1/features/izin_istek/presentation/widgets/dynamic_fields_widget.dart';

class IzinTalepEklePage extends ConsumerWidget {
  const IzinTalepEklePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(izinTalepFormProvider, (previous, next) {
      if (next.isSuccess) {
        AppDialogs.showSuccess(
          context,
          'İzin talebiniz başarıyla oluşturuldu.',
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
      izinTalepFormProvider.select((s) => s.isLoading),
    );

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'İzin Talebi Oluştur',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          children: [
            const IzinTypeSelectorWidget(),
            const SizedBox(height: AppDimens.lg),
            const DateDurationSelectorWidget(),
            const SizedBox(height: AppDimens.lg),
            const DynamicFieldsWidget(), // Contains logic to show/hide based on type
            const SizedBox(height: AppDimens.xxl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        ref.read(izinTalepFormProvider.notifier).submit();
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
    );
  }
}
