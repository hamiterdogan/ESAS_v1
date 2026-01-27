import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cache extension for AutoDispose providers
/// Keeps providers in cache for a specified duration
///
/// Example usage:
/// ```dart
/// final myProvider = FutureProvider.autoDispose<List<Item>>((ref) async {
///   ref.cacheFor(const Duration(minutes: 5));
///   final repo = ref.watch(repositoryProvider);
///   return repo.getItems();
/// });
/// ```
extension CacheExtension on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, () => link.close());
    onDispose(() => timer.cancel());
  }
}
