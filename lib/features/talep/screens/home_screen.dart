import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/talep/screens/widgets/ana_sayfa_content.dart';
import 'package:esas_v1/features/talep/screens/widgets/isteklerim_content.dart';
import 'package:esas_v1/features/talep/screens/widgets/gelen_kutusu_content.dart';

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

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _currentIndex != 0
            ? [
                // Filtreleme ikonu + label
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (_currentIndex == 1) {
                        _isteklerimKey.currentState?.showFilterBottomSheet();
                      } else if (_currentIndex == 2) {
                        _gelenKutusuKey.currentState?.showFilterBottomSheet();
                      }
                    },
                    child: const SizedBox(
                      height: kToolbarHeight,
                      width: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Filtrele',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const AnaSayfaContent(),
          IsteklerimContent(key: _isteklerimKey),
          GelenKutusuContent(key: _gelenKutusuKey),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 50),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 110,
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 33,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
