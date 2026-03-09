# Copilot instructions for ESAS V1

## Big picture
- This is a Flutter app with feature modules under `lib/features`, shared UI in `lib/common`, and cross-cutting infrastructure in `lib/core`.
- Navigation is centralized in `lib/core/routing/router.dart` using `GoRouter`; auth gating is driven by the global `authStateNotifier`, not by per-screen guards.
- App startup in `lib/main.dart` does real work before showing the router: migrate legacy tokens, load JWT from storage, set `tokenProvider`, initialize notifications, then remove the native splash.
- Firebase Messaging is intentionally skipped on iOS/macOS in startup and background handlers; preserve those platform checks when touching notification code.

## Auth, networking, and session flow
- Use `lib/core/network/dio_provider.dart` for authenticated API calls. It injects the bearer token per request and handles stale-401 detection; do not manually duplicate auth header logic in feature repositories.
- `dioProvider` must not watch `tokenProvider` during construction; token is read inside the interceptor to avoid rebuilding every repository on login.
- Login is special: `lib/features/auth/repositories/auth_repository.dart` uses its own bare `Dio` for `/Kullanici/GirisYap`, then `login_screen.dart` creates a fresh authorized `Dio` only for notification registration.
- Logout must go through `AuthService` so backend unregister, FCM cleanup, secure-storage cleanup, provider invalidation, and router redirect stay in sync.
- API constants belong in `lib/core/constants/app_constants.dart`; keep backend JSON keys exactly as the API expects (usually PascalCase like `IzinSebebiId`, `IzindeBulunacagiAdres`).

## State management patterns
- Prefer Riverpod 3 `NotifierProvider`/`Notifier` for mutable app state (`tokenProvider`, `authErrorProvider`, search queries).
- For read-heavy API data, the app commonly uses `FutureProvider.autoDispose` plus `ref.cacheFor(...)` to keep results warm for a few minutes; see `lib/features/izin_istek/providers/izin_istek_providers.dart`.
- API-facing repositories return `Result<T>` from `lib/core/models/result.dart`; consume them with Dart pattern matching (`switch` / `case Success(:final data)`).

## Feature implementation conventions
- The active production pattern is feature-local `screens/ + providers/ + repositories/ + models/`. In `features/izin_istek`, this path is used by routed screens.
- `features/izin_istek/data/domain/presentation` also exists, but it is a secondary architecture track. Do not migrate routed screens into it unless the touched code already depends on it.
- Many request payloads are assembled in request models such as `lib/features/izin_istek/models/izin_istek_ekle_req.dart`; prefer updating the model serializer instead of scattering backend field logic across screens.
- Several flows invalidate list providers after success (`devamEdenIsteklerimProvider`, `tamamlananIsteklerimProvider`, unread badges). Preserve these refresh points when changing submission or detail flows.

## UI and UX conventions
- Reuse the design system in `lib/core/theme/app_theme.dart` and `lib/core/constants/app_colors.dart`; avoid ad-hoc colors and spacing in new screens.
- Validation and feedback are usually bottom sheets, not snackbars: use `ValidationUyariWidget.goster`, `IstekBasariliWidget.goster`, and request summary sheets like `showIzinOzetBottomSheet`.
- Many form screens are large `ConsumerStatefulWidget`s with local `TextEditingController`, `FocusNode`, and boolean toggle state. Match that style when extending an existing form instead of introducing a new pattern mid-file.
- Preserve Turkish domain naming in UI and code. File/class names, labels, and backend terms are intentionally Turkish and often mirror API semantics.

## Useful workflows
- Primary local verification is `flutter analyze`; no substantial automated test suite is currently present in the repo.
- Common commands documented in the repo: `flutter pub get`, `flutter run`, `flutter analyze`, `flutter build apk`.
- Splash and app icon configuration live in `flutter_native_splash.yaml` and the `flutter_launcher_icons` section of `pubspec.yaml`; update those configs together when branding changes.
