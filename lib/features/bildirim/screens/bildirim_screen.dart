import 'package:esas_v1/common/widgets/custom_switch_widget.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/bildirim/models/notification_model.dart';
import 'package:esas_v1/features/bildirim/providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BildirimScreen extends ConsumerStatefulWidget {
  const BildirimScreen({super.key});

  @override
  ConsumerState<BildirimScreen> createState() => _BildirimScreenState();
}

class _BildirimScreenState extends ConsumerState<BildirimScreen> {
  bool _sadeceOkunmayanlar = false;
  bool _tumunuOkunduIsaretliyor = false;
  final Set<int> _expandedIds = <int>{};
  final ScrollController _scrollController = ScrollController();
  late Future<List<BildirimModel>> _bildirimFuture;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _bildirimFuture = _fetchBildirimler();
    _scrollController.addListener(_handleScrollChange);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollChange() {
    if (_scrollController.hasClients) {
      _lastScrollOffset = _scrollController.offset;
    }
  }

  Future<List<BildirimModel>> _fetchBildirimler() async {
    final repo = ref.read(notificationRepositoryProvider);
    final result = await repo.bildirimListesiGetir(
      sadeceOkunmayan: _sadeceOkunmayanlar,
      take: 40,
    );

    return switch (result) {
      Success(:final data) =>
        _sadeceOkunmayanlar
            ? data.bildirimler.where((item) => !item.okundu).toList()
            : data.bildirimler,
      Failure(:final message) => throw Exception(message),
      Loading() => throw Exception('Bildirimler yüklenemedi'),
    };
  }

  Future<void> _yenile() async {
    setState(() {
      _bildirimFuture = _fetchBildirimler();
    });
    await _bildirimFuture;
  }

  Future<void> _tumunuOkunduIsaretle() async {
    if (_tumunuOkunduIsaretliyor) return;

    setState(() {
      _tumunuOkunduIsaretliyor = true;
    });

    final repo = ref.read(notificationRepositoryProvider);
    final result = await repo.tumunuOkunduIsaretle();

    if (!mounted) return;

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm bildirimler okundu işaretlendi')),
        );
        ref.invalidate(okunmamisBildirimSayisiProvider);
        setState(() {
          _expandedIds.clear();
          _bildirimFuture = _fetchBildirimler();
        });
      case Failure(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $message')));
      case Loading():
        break;
    }

    if (mounted) {
      setState(() {
        _tumunuOkunduIsaretliyor = false;
      });
    }
  }

  Future<bool> _showTumunuOkunduConfirmation() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                const Icon(
                  Icons.done_all,
                  color: AppColors.primaryDark,
                  size: 56,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tüm bildirimler okundu olarak işaretlenecektir',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: AppColors.primaryDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Vazgeç',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
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

    return result == true;
  }

  Future<void> _tumunuOkunduIsaretleOnayli() async {
    if (_tumunuOkunduIsaretliyor) return;
    final confirmed = await _showTumunuOkunduConfirmation();
    if (!confirmed || !mounted) return;
    await _tumunuOkunduIsaretle();
  }

  void _lokaldeOkunduGuncelle(int bildirimId) {
    setState(() {
      _bildirimFuture = _bildirimFuture.then((items) {
        final guncelListe = items.map((item) {
          if (item.id != bildirimId) return item;
          return BildirimModel(
            id: item.id,
            baslik: item.baslik,
            mesaj: item.mesaj,
            deepLink: item.deepLink,
            bildirimTipi: item.bildirimTipi,
            talepId: item.talepId,
            onayTipi: item.onayTipi,
            onayKayitId: item.onayKayitId,
            aksiyonTipi: item.aksiyonTipi,
            okundu: true,
            olusturmaTarihi: item.olusturmaTarihi,
            gonderenAd: item.gonderenAd,
          );
        }).toList();

        if (_sadeceOkunmayanlar) {
          return guncelListe.where((item) => !item.okundu).toList();
        }
        return guncelListe;
      });
    });
  }

  Future<void> _bildirimDetayinaGit(BildirimModel bildirim) async {
    final previousOffset = _scrollController.hasClients
        ? _scrollController.offset
        : _lastScrollOffset;
    final route = bildirim.deepLinkRoute;
    if (route == null || route.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu bildirim için detay sayfası bulunamadı'),
        ),
      );
      return;
    }

    final repo = ref.read(notificationRepositoryProvider);
    final result = await repo.okunduIsaretle(bildirimId: bildirim.id);

    if (mounted) {
      switch (result) {
        case Success():
          _lokaldeOkunduGuncelle(bildirim.id);
          ref.invalidate(okunmamisBildirimSayisiProvider);
        case Failure():
          break;
        case Loading():
          break;
      }
    }

    if (route.startsWith('/dokumantasyon/detay/')) {
      await context.push(route, extra: bildirim.onayTipi);
    } else {
      await context.push(route);
    }

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxOffset = _scrollController.position.maxScrollExtent;
      final targetOffset = previousOffset.clamp(0.0, maxOffset);
      _scrollController.jumpTo(targetOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Bildirimler',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: _tumunuOkunduIsaretliyor
                ? null
                : _tumunuOkunduIsaretleOnayli,
            padding: const EdgeInsets.only(right: 16),
            icon: _tumunuOkunduIsaretliyor
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textOnPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.done_all, color: AppColors.textOnPrimary),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 16, top: 8),
            child: CustomSwitchWidget(
              value: _sadeceOkunmayanlar,
              onChanged: (value) {
                setState(() {
                  _sadeceOkunmayanlar = value;
                  _expandedIds.clear();
                  _bildirimFuture = _fetchBildirimler();
                });
              },
              label: 'Sadece okunmayanları listele',
              padding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BildirimModel>>(
              future: _bildirimFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Bildirimler alınamadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _yenile,
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final bildirimler = snapshot.data ?? <BildirimModel>[];

                if (bildirimler.isEmpty) {
                  return const Center(
                    child: Text(
                      'Gösterilecek bildirim bulunamadı',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _yenile,
                  child: ListView.separated(
                    key: const PageStorageKey<String>('bildirimler_listesi'),
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: bildirimler.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final bildirim = bildirimler[index];
                      final isExpanded = _expandedIds.contains(bildirim.id);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _bildirimDetayinaGit(bildirim),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textOnPrimary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        bildirim.baslik,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: bildirim.okundu ? 15 : 16,
                                          fontWeight: bildirim.okundu
                                              ? FontWeight.w400
                                              : FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedIds.remove(bildirim.id);
                                          } else {
                                            _expandedIds.add(bildirim.id);
                                          }
                                        });
                                      },
                                      icon: Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bildirim.mesaj,
                                  maxLines: isExpanded ? null : 1,
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                    fontWeight: bildirim.okundu
                                        ? FontWeight.w400
                                        : FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
