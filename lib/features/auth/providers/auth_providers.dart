import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/auth/repositories/auth_repository.dart';
import 'package:esas_v1/core/services/auth_storage_service.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

final authStorageServiceProvider = Provider<AuthStorageService>(
  (_) => AuthStorageService(),
);
