import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/repositories/talep_yonetim_repository.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/models/izin_talepleri_model.dart';
import 'package:esas_v1/features/izin_istek/models/gorev_model.dart';
import 'package:esas_v1/features/izin_istek/models/gorev_yeri_model.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/repositories/bilgi_teknolojileri_istek_repository.dart';

final talepYonetimRepositoryProvider = Provider<TalepYonetimRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TalepYonetimRepositoryImpl(dio: dio);
});

// -- PAGINATION STATE --
class PaginatedTalepState {
  final List<Talep> talepler;
  final int pageIndex;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final bool isInitialLoading;

  const PaginatedTalepState({
    this.talepler = const [],
    this.pageIndex = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.isInitialLoading = false,
  });

  PaginatedTalepState copyWith({
    List<Talep>? talepler,
    int? pageIndex,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool? isInitialLoading,
  }) {
    return PaginatedTalepState(
      talepler: talepler ?? this.talepler,
      pageIndex: pageIndex ?? this.pageIndex,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage:
          errorMessage, // Reset error on new state unless explicitly set
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    );
  }
}

class _PaginatedTalepNotifier extends Notifier<PaginatedTalepState> {
  static const int _pageSize = 20;
  final int tip;

  _PaginatedTalepNotifier(this.tip);

  @override
  PaginatedTalepState build() {
    return const PaginatedTalepState();
  }

  Future<void> loadInitial() async {
    // If already initialized or loading, skip
    if (state.isInitialLoading || (state.talepler.isNotEmpty && !state.hasMore))
      return;

    state = state.copyWith(isInitialLoading: true, errorMessage: null);
    await _fetchPage(0);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    await _fetchPage(state.pageIndex + 1);
  }

  Future<void> refresh() async {
    state = const PaginatedTalepState();
    await loadInitial();
  }

  Future<void> _fetchPage(int pageIndex) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final repository = ref.read(talepYonetimRepositoryProvider);

    final result = await repository.taleplerimiGetir(
      tip: tip, // Use the tip field instead of arg
      pageIndex: pageIndex,
      pageSize: _pageSize,
    );

    if (!ref.mounted) return;

    switch (result) {
      case Success(data: final data):
        final newTalepler = data.talepler;
        final isLastPage = newTalepler.isEmpty;

        state = state.copyWith(
          talepler: pageIndex == 0
              ? newTalepler
              : [...state.talepler, ...newTalepler],
          pageIndex: pageIndex,
          isLoading: false,
          isInitialLoading: false,
          hasMore: !isLastPage,
        );
      case Failure(message: final message):
        state = state.copyWith(
          isLoading: false,
          isInitialLoading: false,
          errorMessage: message,
        );
      case Loading():
        // Should not happen here usually
        break;
    }
  }
}

// Talep cache'i tuple halde saklamak için notifier
class TalepCacheNotifier extends Notifier<Map<int, List<Talep>>> {
  @override
  Map<int, List<Talep>> build() {
    return {};
  }

  void setCache(int tip, List<Talep> talepler) {
    state = {...state, tip: List<Talep>.unmodifiable(talepler)};
  }

  void clear([int? tip]) {
    if (tip == null) {
      state = {};
      return;
    }
    final next = {...state};
    next.remove(tip);
    state = next;
  }
}

final talepCacheProvider =
    NotifierProvider<TalepCacheNotifier, Map<int, List<Talep>>>(() {
      return TalepCacheNotifier();
    });

// Yeni endpoint: IzinTaleplerimiGetir (parametresiz)
final izinTalepleriProvider = FutureProvider<IzinTalepleriResponse>((
  ref,
) async {
  final repo = ref.watch(talepYonetimRepositoryProvider);
  final result = await repo.izinTaleplerimiGetir();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

// Onay Bekliyor Talepler (tip: 0)
final onayBekleyenTaleplerProvider = FutureProvider<IzinTalepleriResponse>((
  ref,
) async {
  final repo = ref.watch(talepYonetimRepositoryProvider);
  final result = await repo.izinTaleplerimiGetirByTip(tip: 0);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

// Onaylanmış Talepler (tip: 1)
final onaylananTaleplerProvider = FutureProvider<IzinTalepleriResponse>((
  ref,
) async {
  final repo = ref.watch(talepYonetimRepositoryProvider);
  final result = await repo.izinTaleplerimiGetirByTip(tip: 1);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

// Devam eden talepler (tip: 0) - İsteklerim tabı için (PAGINATED)
final devamEdenIsteklerimProvider =
    NotifierProvider.autoDispose<_PaginatedTalepNotifier, PaginatedTalepState>(
      () => _PaginatedTalepNotifier(0),
    );

// Legacy provider for backward compatibility with non-paginated screens
final devamEdenIsteklerimLegacyProvider =
    FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
      final repository = ref.watch(talepYonetimRepositoryProvider);
      final result = await repository.taleplerimiGetir(
        tip: 0,
        pageIndex: 0,
        pageSize: 100,
      );

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

// Wrapper provider to initialize fetching for tip 0
final devamEdenIsteklerimInitProvider = Provider.autoDispose((ref) {
  final notifier = ref.read(devamEdenIsteklerimProvider.notifier);
  // Using explicit delay or post frame to avoid build updating state directly conflicts
  Future.microtask(() => notifier.loadInitial());
});

// Tamamlanan talepler (tip: 1) - İsteklerim tabı için (PAGINATED)
final tamamlananIsteklerimProvider =
    NotifierProvider.autoDispose<_PaginatedTalepNotifier, PaginatedTalepState>(
      () => _PaginatedTalepNotifier(1),
    );

// Legacy provider for backward compatibility with non-paginated screens
final tamamlananIsteklerimLegacyProvider =
    FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
      final repository = ref.watch(talepYonetimRepositoryProvider);
      final result = await repository.taleplerimiGetir(
        tip: 1,
        pageIndex: 0,
        pageSize: 100,
      );

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

// Bilgi Teknolojileri taleplerinin onayKayitId seti
final bilgiTeknolojileriOnayKayitIdSetProvider =
    FutureProvider.autoDispose<Set<int>>((ref) async {
      final repo = ref.watch(bilgiTeknolojileriIstekRepositoryProvider);

      Future<Set<int>> fetchIds(int tip) async {
        final result = await repo.teknikDestekTaleplerimiGetir(
          tip: tip,
          hizmetTuru: 1,
        );

        return switch (result) {
          Success(data: final data) =>
            data.talepler.map((t) => t.onayKayitId).toSet(),
          Failure() => <int>{},
          Loading() => <int>{},
        };
      }

      final devamEdenIds = await fetchIds(0);
      final tamamlananIds = await fetchIds(1);

      return {...devamEdenIds, ...tamamlananIds};
    });

// Devam eden talepler (tip: 2) - Gelen Kutusu tabı için (PAGINATED)
final devamEdenGelenKutusuProvider =
    NotifierProvider.autoDispose<_PaginatedTalepNotifier, PaginatedTalepState>(
      () => _PaginatedTalepNotifier(2),
    );

// Tamamlanan talepler (tip: 3) - Gelen Kutusu tabı için (PAGINATED)
final tamamlananGelenKutusuProvider =
    NotifierProvider.autoDispose<_PaginatedTalepNotifier, PaginatedTalepState>(
      () => _PaginatedTalepNotifier(3),
    );

// Görev listesi provider - GorevDoldur endpoint'i
final gorevlerProvider = FutureProvider.autoDispose<List<Gorev>>((ref) async {
  final repo = ref.watch(talepYonetimRepositoryProvider);
  final result = await repo.gorevleriGetir();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

// Görev Yeri listesi provider - GorevYeriDoldur endpoint'i
final gorevYerleriProvider = FutureProvider<List<GorevYeri>>((ref) async {
  final repo = ref.watch(talepYonetimRepositoryProvider);
  final result = await repo.gorevYerleriniGetir();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});
