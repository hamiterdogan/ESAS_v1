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
  late final PageController _pageController;

  // GlobalKey'ler filtre işlemlerine erişim için
  final GlobalKey<IsteklerimContentState> _isteklerimKey = GlobalKey();
  final GlobalKey<GelenKutusuContentState> _gelenKutusuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // Keyboard'u otomatik olarak kapat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        if (_currentIndex != 0) {
          _setTabIndex(0);
          return;
        }
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
                    icon: (_currentIndex == 1 &&
                                (_isteklerimKey.currentState?.isFilterActive ??
                                    false)) ||
                            (_currentIndex == 2 &&
                                (_gelenKutusuKey.currentState?.isFilterActive ??
                                    false))
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                  ),
                ]
              : null,
        ),
        // Slide transitions for all tabs
        body: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (index) {
            if (_currentIndex == index) return;
            setState(() => _currentIndex = index);
          },
          children: [
            const AnaSayfaContent(),
            IsteklerimContent(
              key: _isteklerimKey,
              onFilterStateChanged: () => setState(() {}),
            ),
            GelenKutusuContent(
              key: _gelenKutusuKey,
              onFilterStateChanged: () => setState(() {}),
            ),
          ],
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
                    onTap: () => _setTabIndex(0),
                  ),
                  // İsteklerim
                  _buildNavItem(
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment,
                    label: 'İsteklerim',
                    isSelected: _currentIndex == 1,
                    onTap: () => _setTabIndex(1),
                  ),
                  // Gelen Kutusu
                  _buildNavItem(
                    icon: Icons.inbox_outlined,
                    activeIcon: Icons.inbox,
                    label: 'Gelen Kutusu',
                    isSelected: _currentIndex == 2,
                    onTap: () => _setTabIndex(2),
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

  void _setTabIndex(int index) {
    if (_currentIndex == index) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showExitConfirmationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 60),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                // Icon
                const Icon(
                  Icons.power_settings_new_rounded,
                  color: AppColors.primaryDark,
                  size: 56,
                ),
                const SizedBox(height: 16),

                // Message
                const Text(
                  'Uygulamadan çıkmak istediğinize emin misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
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
          ),
        );
      },
    );
  }
}
