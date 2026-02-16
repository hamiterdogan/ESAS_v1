import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/bildirim/repositories/notification_repository.dart';
import 'package:esas_v1/features/bildirim/models/notification_model.dart';

// Repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationRepositoryImpl(dio: dio);
});

// Okunmamış bildirim sayısı
final okunmamisBildirimSayisiProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  final result = await repo.okunmamisSayisiGetir();

  return switch (result) {
    Success(:final data) => data,
    Failure() => 0,
    Loading() => 0,
  };
});

// -- PAGINATED BILDIRIM STATE --

class PaginatedBildirimState {
  final List<BildirimModel> bildirimler;
  final int pageIndex;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final bool isInitialLoading;

  const PaginatedBildirimState({
    this.bildirimler = const [],
    this.pageIndex = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.isInitialLoading = true,
  });

  PaginatedBildirimState copyWith({
    List<BildirimModel>? bildirimler,
    int? pageIndex,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool? isInitialLoading,
  }) {
    return PaginatedBildirimState(
      bildirimler: bildirimler ?? this.bildirimler,
      pageIndex: pageIndex ?? this.pageIndex,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    );
  }
}

class BildirimListNotifier extends Notifier<PaginatedBildirimState> {
  static const int _pageSize = 20;

  @override
  PaginatedBildirimState build() {
    // İlk yükleme başlat
    Future.microtask(() => loadInitial());
    return const PaginatedBildirimState();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, isInitialLoading: true);
    await _fetchPage(0);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    await _fetchPage(state.pageIndex + 1);
  }

  Future<void> refresh() async {
    state = const PaginatedBildirimState();
    await _fetchPage(0);
  }

  Future<void> _fetchPage(int pageIndex) async {
    state = state.copyWith(isLoading: true);

    final repo = ref.read(notificationRepositoryProvider);
    final result = await repo.bildirimListesiGetir(
      pageIndex: pageIndex,
      pageSize: _pageSize,
    );

    switch (result) {
      case Success(:final data):
        final newList = pageIndex == 0
            ? data.bildirimler
            : [...state.bildirimler, ...data.bildirimler];
        state = state.copyWith(
          bildirimler: newList,
          pageIndex: pageIndex,
          isLoading: false,
          hasMore: data.bildirimler.length >= _pageSize,
          isInitialLoading: false,
        );
      case Failure(:final message):
        state = state.copyWith(
          isLoading: false,
          errorMessage: message,
          isInitialLoading: false,
        );
      case Loading():
        break;
    }
  }

  /// Tek bir bildirimi okundu olarak işaretle (lokal state + API)
  Future<void> bildirimOkunduIsaretle(int bildirimId) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.okunduIsaretle(bildirimId: bildirimId);

    // Lokal listeyi güncelle
    final updatedList = state.bildirimler.map((b) {
      if (b.id == bildirimId) {
        return BildirimModel(
          id: b.id,
          baslik: b.baslik,
          mesaj: b.mesaj,
          bildirimTipi: b.bildirimTipi,
          talepId: b.talepId,
          onayTipi: b.onayTipi,
          onayKayitId: b.onayKayitId,
          aksiyonTipi: b.aksiyonTipi,
          okundu: true,
          olusturmaTarihi: b.olusturmaTarihi,
          gonderenAd: b.gonderenAd,
        );
      }
      return b;
    }).toList();

    state = state.copyWith(bildirimler: updatedList);
    // Badge sayısını da güncelle
    ref.invalidate(okunmamisBildirimSayisiProvider);
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> tumunuOkunduIsaretle() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.tumunuOkunduIsaretle();

    // Lokal tüm listeyi okundu yap
    final updatedList = state.bildirimler.map((b) {
      return BildirimModel(
        id: b.id,
        baslik: b.baslik,
        mesaj: b.mesaj,
        bildirimTipi: b.bildirimTipi,
        talepId: b.talepId,
        onayTipi: b.onayTipi,
        onayKayitId: b.onayKayitId,
        aksiyonTipi: b.aksiyonTipi,
        okundu: true,
        olusturmaTarihi: b.olusturmaTarihi,
        gonderenAd: b.gonderenAd,
      );
    }).toList();

    state = state.copyWith(bildirimler: updatedList);
    ref.invalidate(okunmamisBildirimSayisiProvider);
  }
}

final bildirimListProvider =
    NotifierProvider<BildirimListNotifier, PaginatedBildirimState>(
  BildirimListNotifier.new,
);
