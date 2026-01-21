import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/talep/screens/widgets/ana_sayfa_content.dart';
import 'package:esas_v1/features/talep/screens/widgets/isteklerim_content.dart';
import 'package:esas_v1/features/talep/screens/widgets/gelen_kutusu_content.dart';
import 'package:esas_v1/common/widgets/common_appbar_action_button.dart';

/// Ana sayfa - Tab navigation ile Ana Sayfa, İsteklerim ve Gelen Kutusu
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // GlobalKey'ler filtre işlemlerine erişim için
  final GlobalKey<IsteklerimContentState> _isteklerimKey = GlobalKey();
  final GlobalKey<GelenKutusuContentState> _gelenKutusuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Keyboard'u otomatik olarak kapat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tab'a göre başlık belirleme
    String appBarTitle;
    switch (_currentIndex) {
      case 1:
        appBarTitle = 'İsteklerim';
        break;
      case 2:
        appBarTitle = 'Gelen Kutusu';
        break;
      default:
        appBarTitle = 'ESAS';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _showExitConfirmationBottomSheet();
      },
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: Text(
            appBarTitle,
            style: const TextStyle(color: AppColors.textOnPrimary),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
          actions: _currentIndex != 0
              ? [
                  CommonAppBarActionButton(
                    label: 'Filtrele',
                    onTap: () {
                      if (_currentIndex == 1) {
                        _isteklerimKey.currentState?.showFilterBottomSheet();
                      } else if (_currentIndex == 2) {
                        _gelenKutusuKey.currentState?.showFilterBottomSheet();
                      }
                    },
                  ),
                ]
              : null,
        ),
        body: Builder(
          builder: (context) {
            // Sadece aktif tab'ı render et - gereksiz API çağrılarını önler
            switch (_currentIndex) {
              case 0:
                return const AnaSayfaContent();
              case 1:
                return IsteklerimContent(key: _isteklerimKey);
              case 2:
                return GelenKutusuContent(key: _gelenKutusuKey);
              default:
                return const AnaSayfaContent();
            }
          },
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 50),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Ana Sayfa
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Ana Sayfa',
                    isSelected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                  // İsteklerim
                  _buildNavItem(
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment,
                    label: 'İsteklerim',
                    isSelected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  // Gelen Kutusu
                  _buildNavItem(
                    icon: Icons.inbox_outlined,
                    activeIcon: Icons.inbox,
                    label: 'Gelen Kutusu',
                    isSelected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62, minWidth: 44),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 33,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textOnPrimary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.textOnPrimary.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              const Icon(Icons.exit_to_app, color: AppColors.error, size: 60),
              const SizedBox(height: 16),

              // Message
              const Text(
                'Uygulamadan çıkmak istediğinize emin misiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Vazgeç Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textTertiary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Vazgeç',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Devam Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        exit(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Devam',
                        style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
