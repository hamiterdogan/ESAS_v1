# Riverpod & Flutter Lifecycle Audit Report

**Codebase:** `lib/` — 298 Dart files across 14 feature modules + core + common  
**Date:** Auto-generated audit  
**Scope:** 10 anti-pattern categories, ordered by severity

---

## TABLE OF CONTENTS

1. [CRITICAL — Singleton Holding WidgetRef](#1-singleton-holding-widgetref)
2. [CRITICAL — Uncancelled Stream Subscriptions](#2-uncancelled-stream-subscriptions)
3. [HIGH — ref Usage After await Without mounted Check](#3-ref-usage-after-await-without-mounted-check)
4. [HIGH — ref.invalidate() Inside dispose()](#4-refinvalidate-inside-dispose)
5. [HIGH — FutureProviders Missing autoDispose](#5-futureproviders-missing-autodispose)
6. [MEDIUM — Family Provider With Record Type Parameter](#6-family-provider-with-record-type-parameter)
7. [LOW — ref.read() vs ref.watch() Misuse](#7-refread-vs-refwatch-misuse)
8. [INFO — Patterns That Are Correctly Applied](#8-patterns-correctly-applied)

---

## 1. SINGLETON HOLDING WidgetRef

**Severity:** 🔴 CRITICAL — Can cause crashes and memory leaks  
**Pattern:** Global singleton storing a `WidgetRef` reference that outlives the widget tree

### Finding 1.1 — NotificationService stores `WidgetRef? _ref`

**File:** `lib/core/services/notification_service.dart`  
**Lines:** 30–47

```dart
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ...
  WidgetRef? _ref;  // ← DANGEROUS: Singleton holds a widget-scoped ref
```

**Line 93 — setter:**
```dart
  void setRef(WidgetRef ref) {
    _ref = ref;
  }
```

**Why it's dangerous:** `WidgetRef` is tied to a specific widget's lifecycle. When that widget is disposed, Riverpod invalidates the ref. But the singleton lives forever — any subsequent `_ref!.read(...)` or `_ref!.invalidate(...)` will throw or silently operate on a stale ref.

**Recommendation:** Replace `WidgetRef` with a `ProviderContainer` reference (set once at app startup) or inject a `Ref` from a provider instead.

---

### Finding 1.2 — AuthService receives `WidgetRef` as method parameter (safe pattern)

**File:** `lib/core/services/auth_service.dart`  
**Lines:** 27–29

```dart
  Future<void> logout(WidgetRef ref) async {
```

**Assessment:** ✅ SAFE — `WidgetRef` is passed as a method parameter and used immediately within the same call stack. It's not stored. However, passing `WidgetRef` to a service layer is still an architectural smell; consider using `Ref` from a provider or `ProviderContainer` instead.

---

## 2. UNCANCELLED STREAM SUBSCRIPTIONS

**Severity:** 🔴 CRITICAL — Memory leak, duplicate handlers on hot restart

### Finding 2.1 — Firebase listeners without stored subscription

**File:** `lib/core/services/notification_service.dart`  
**Lines:** 77–80

```dart
    // Foreground mesaj dinle
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Bildirime tıklama (app background'dayken)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
```

**Problem:** These `.listen()` calls return `StreamSubscription` objects that are *not stored*. They can never be cancelled. On hot restart, `initialize()` can be called again, creating duplicate listeners.

### Finding 2.2 — Token refresh subscription (partially safe)

**File:** `lib/core/services/notification_service.dart`  
**Line:** 181

```dart
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) async {
```

**Assessment:** ✅ Stored in `_tokenRefreshSubscription` and can be cancelled via `resetRegistrationFlow()`. However, calling `getAndRegisterToken()` multiple times would overwrite the previous subscription reference without cancelling it first — potential leak.

---

## 3. ref USAGE AFTER `await` WITHOUT `mounted` CHECK

**Severity:** 🟠 HIGH — Can cause `StateError` if widget is unmounted during the await

This is the most widespread pattern in the codebase. The `ref.read()` call itself is captured before the await (which is fine), but `ref.invalidate()` and `ref.read()` calls *after* awaits without a `mounted` guard will crash if the widget is unmounted.

### Systematic Pattern — `ref.read() → await → ref.invalidate()`

This pattern repeats across **all** `*_detay_screen.dart` and `*_istek_screen.dart` files in onay durumu callbacks. Below are representative examples:

---

### Finding 3.1 — yiyecek_icecek_istek_screen.dart

**File:** `lib/features/yiyecek_icecek_istek/screens/yiyecek_icecek_istek_screen.dart`  
**Lines:** 878–899

```dart
        final repo = ref.read(yiyecekIcecekRepositoryProvider);    // ref.read before await ✓
        final emailService = ref.read(emailServiceProvider);        // ref.read before await ✓
        // ...
        final onayKayitId = await repo.yiyecekIstekEkle(req);       // await
        // ...
        await emailService.emailIcerikOlustur(...);                  // await
        // NO mounted check here
      },
      onSuccess: () async {
        if (!mounted) return;                                        // ✓ mounted check
        // ...
        ref.invalidate(yiyecekIstekDevamEdenTaleplerProvider);       // ← after await in onGonder
        ref.invalidate(yiyecekIstekTamamlananTaleplerProvider);
```

**Note:** The `onGonder` callback itself has no mounted check before calling `ref.invalidate()`. The `onSuccess` callback does check `mounted`. The risk is in `onGonder`.

---

### Finding 3.2 — teknik_destek_detay_screen.dart

**File:** `lib/features/teknik_destek_istek/screens/teknik_destek_detay_screen.dart`  
**Lines:** 935–997 (onCloseRequest callback)

```dart
  onCloseRequest: (aciklama, rating) async {
    try {
      final repo = ref.read(bilgiTeknolojileriIstekRepositoryProvider);
      // ... multiple awaits (aciklamaYaz, teknikDestekCozumDosyaYukle, surecTamamlandi) ...
      if (!context.mounted) return;   // ✓ check before ScaffoldMessenger
      // ...
      ref.read(devamEdenGelenKutusuProvider.notifier).refresh();   // ref.read AFTER await
      ref.invalidate(teknikDestekDetayProvider(widget.talepId));   // ← ref.invalidate AFTER await
```

**Lines:** 1024–1093 (onSend callback) — same pattern: `ref.read()` after multiple awaits with `context.mounted` checks before ScaffoldMessenger but `ref.invalidate()` after await at line 1093 without a dedicated mounted/ref guard.

---

### Finding 3.3 — egitim_istek_detay_screen.dart  

**File:** `lib/features/egitim_istek/screens/egitim_istek_detay_screen.dart`  
**Lines:** 425–443

```dart
  Future<void> _saveKurumUcret(int talepId) async {
    final repo = ref.read(egitimIstekRepositoryProvider);
    final result = await repo.egitimIstekGuncelle(...);

    if (!mounted) return;                                          // ✓ mounted check
    Navigator.of(context).pop();
    // ...
    ref.invalidate(egitimIstekDetayProvider(widget.talepId));      // ✓ after mounted check — SAFE
```

**Assessment:** ✅ This file correctly checks `mounted` before using ref.

---

### Finding 3.4 — bildirim_screen.dart

**File:** `lib/features/bildirim/screens/bildirim_screen.dart`  
**Lines:** 46–86

```dart
  Future<List<BildirimModel>> _fetchBildirimler() async {
    final repo = ref.read(notificationRepositoryProvider);       // ← ref.read in async method
    final result = await repo.bildirimListesiGetir(...);          // await
    // NO mounted check — but only parses data, doesn't use context
    return switch (result) { ... };
  }
```

**Assessment:** `_fetchBildirimler()` uses ref.read before await (safe capture) and doesn't use context or ref after await (safe). However, `_tumunuOkunduIsaretle()` at lines 71–101 correctly checks `mounted` ✓.

---

### Finding 3.5 — login_screen.dart

**File:** `lib/features/auth/screens/login_screen.dart`  
**Lines:** 56–94

```dart
  Future<void> _login() async {
    // ...
    ref.read(tokenProvider.notifier).setToken(token!);
    // ...
    if (!mounted) return;   // ✓ mounted check at line 65
    // ...
    ref.invalidate(dioProvider);                         // After mounted check — SAFE
    ref.invalidate(notificationRepositoryProvider);      // After mounted check — SAFE
```

**Assessment:** ✅ Correctly uses `mounted` check.

---

### Affected Files (ref.invalidate after await — partial list of files requiring verification):

| File | Lines with ref.invalidate after await |
|------|---------------------------------------|
| `features/dokumantasyon_istek/screens/dokumantasyon_istek_detay_screen.dart` | 251, 299–300, 2147, 2193 |
| `features/teknik_destek_istek/screens/teknik_destek_detay_screen.dart` | 997, 1093 |
| `features/satin_alma/screens/satin_alma_detay_screen.dart` | 364, 367, 658–659, 1536 |
| `features/satin_alma/screens/satin_alma_talep_screen.dart` | 2242–2243 |
| `features/egitim_istek/screens/egitim_talep_screen.dart` | 3573–3574 |
| `features/arac_istek/screens/arac_talep_ekle_screen.dart` | 1032–1033, 1071–1072 |
| `features/arac_istek/screens/arac_istek_yuk_ekle_screen.dart` | 809–810 |
| `features/izin_istek/screens/izin_ekle_screen.dart` | 2037–2038 |
| `features/izin_istek/screens/izin_turleri/dini_izin_screen.dart` | 700–701 |
| `features/izin_istek/screens/izin_turleri/evlilik_izin_screen.dart` | 646–647 |
| `features/izin_istek/screens/izin_turleri/kurum_gorevlendirmesi_screen.dart` | 686–687 |
| `features/izin_istek/screens/izin_turleri/vefat_izin_screen.dart` | 679–680 |
| `features/izin_istek/screens/izin_turleri/yillik_izin_screen.dart` | 688–689 |
| `features/izin_istek/screens/izin_turleri/mazeret_izin_screen.dart` | 685–686 |
| `features/izin_istek/screens/izin_turleri/hastalik_izin_screen.dart` | 845–846 |
| `features/izin_istek/screens/izin_turleri/dogum_izin_screen.dart` | 576–577 |
| `features/bilgi_teknolojileri_istek/screens/bilgi_teknolojileri_istek_screen.dart` | 377–378, 390–391 |
| `features/sarf_malzeme_istek/screens/sarf_turleri/kirtasiye_malzemesi_istek_screen.dart` | 330 |
| `features/sarf_malzeme_istek/screens/sarf_turleri/temizlik_malzemesi_istek_screen.dart` | 329 |
| `features/sarf_malzeme_istek/screens/sarf_turleri/promosyon_malzemesi_istek_screen.dart` | 330 |
| `features/dokumantasyon_istek/screens/a4_kagidi_istek_screen.dart` | 133–134 |
| `features/dokumantasyon_istek/screens/dokumantasyon_baski_istek_screen.dart` | 1003–1004 |

**Note:** Many of these calls are inside `onSuccess` or `onConfirm` callbacks passed to bottom sheets. If the parent widget was popped before the callback fires, the ref may be invalid. Each needs individual verification for a `mounted` or `context.mounted` guard *before* the `ref.invalidate()` call.

---

## 4. `ref.invalidate()` Inside `dispose()`

**Severity:** 🟠 HIGH — Triggers provider rebuild during teardown, may cause race conditions or errors

### Finding 4.1 — izin_ekle_screen.dart

**File:** `lib/features/izin_istek/screens/izin_ekle_screen.dart`  
**Lines:** 314–322

```dart
  @override
  void dispose() {
    _aciklamaFocusNode.dispose();
    _adresFocusNode.dispose();
    _esAdiFocusNode.dispose();
    _hastalikYazinizFocusNode.dispose();
    _diniGunAciklamaFocusNode.dispose();
    // Form state'i temizle ekran kapanırken
    ref.invalidate(izinEkleFormProvider);   // ← ref.invalidate inside dispose()
    super.dispose();
  }
```

**Problem:** Calling `ref.invalidate()` inside `dispose()` triggers a synchronous provider rebuild at the exact moment the widget is being torn down. If any widget is listening to `izinEkleFormProvider`, it may try to rebuild while the tree is in an inconsistent state. The correct approach is to use `autoDispose` on the provider so it's automatically cleaned up when no longer watched, or use `ref.onDispose()` inside the provider itself.

---

## 5. FutureProviders Missing `autoDispose`

**Severity:** 🟠 HIGH — Memory leak: provider data stays in memory forever after the screen using it is popped

### Comprehensive List of Affected Providers

| Provider | File | Line |
|----------|------|------|
| `yiyecekIstekDevamEdenTaleplerProvider` | `features/yiyecek_icecek_istek/providers/yiyecek_icecek_providers.dart` | 61 |
| `yiyecekIstekTamamlananTaleplerProvider` | `features/yiyecek_icecek_istek/providers/yiyecek_icecek_providers.dart` | 68 |
| `izinTalepleriProvider` | `features/izin_istek/providers/talep_yonetim_providers.dart` | 194 |
| `onayBekleyenTaleplerProvider` | `features/izin_istek/providers/talep_yonetim_providers.dart` | 208 |
| `onaylananTaleplerProvider` | `features/izin_istek/providers/talep_yonetim_providers.dart` | 222 |
| `gorevYerleriProvider` | `features/izin_istek/providers/talep_yonetim_providers.dart` | 372 |
| `personelBilgiProvider` | `features/izin_istek/providers/izin_istek_detay_provider.dart` | 49 |
| `izinSebepleriProvider` | `features/izin_istek/presentation/providers/izin_talep_providers.dart` | 23 |
| `binalarProvider` | `features/satin_alma/presentation/providers/satin_alma_providers.dart` | 25 |
| `anaKategorilerProvider` | `features/satin_alma/presentation/providers/satin_alma_providers.dart` | 29 |
| `birimlerProvider` | `features/satin_alma/presentation/providers/satin_alma_providers.dart` | 43 |
| `paraBirimleriProvider` | `features/satin_alma/presentation/providers/satin_alma_providers.dart` | 47 |
| `odemeSekilleriProvider` | `features/satin_alma/presentation/providers/satin_alma_providers.dart` | 54 |
| `aracTurleriProvider` | `features/arac_istek/presentation/providers/arac_talep_providers.dart` | 23 |
| `gidilecekYerlerProvider` | `features/arac_istek/presentation/providers/arac_talep_providers.dart` | 32 |

**Note:** `altKategorilerProvider` (line 36, satin_alma_providers.dart) uses `FutureProvider.family` without `autoDispose` — each unique `id` key creates a cached entry that persists permanently.

**Contrast with correct usage:**  
`ikramTurleriProvider` (line 56, yiyecek_icecek_providers.dart) uses `FutureProvider.autoDispose` with `ref.cacheFor(Duration(minutes: 5))` — this is the correct pattern.

**Recommendation:** Add `.autoDispose` to all the above providers. If data should persist for a period, combine with `ref.cacheFor()` or `ref.keepAlive()`.

---

## 6. Family Provider With Record Type Parameter

**Severity:** 🟡 MEDIUM — Record types in Dart have structural equality by default, so this is actually safe, but worth documenting

### Finding 6.1 — onayDurumuProvider uses a record type

**File:** `lib/features/izin_istek/providers/izin_istek_detay_provider.dart`  
**Lines:** 30–31

```dart
typedef OnayDurumuArgs = ({int talepId, String onayTipi});

final onayDurumuProvider =
    FutureProvider.family<OnayDurumuResponse, OnayDurumuArgs>((ref, args) async {
```

**Assessment:** ✅ SAFE — Dart records (`({int talepId, String onayTipi})`) have structural equality built-in. Both `==` and `hashCode` are derived from the fields. This is actually the recommended Riverpod pattern for multi-parameter families.

**Other `.family` providers** in the codebase all use `int` or `String` as the family parameter — these are primitives with proper equality. No issues found.

---

## 7. `ref.read()` vs `ref.watch()` Misuse

**Severity:** 🟢 LOW — No significant misuse found

### Analysis

- **`ref.watch()`** — 97 matches in screen files. All appear correctly inside `build()` methods.
- **`ref.read()`** — Used in `initState()`, callbacks (`onPressed`, `onTap`, `onSubmit`), and async methods. These are all correct Riverpod usage.

### One observation

**File:** `lib/features/izin_istek/screens/izin_istek_detay_screen.dart`  
**Lines:** 49–50

```dart
  @override
  void initState() {
    super.initState();
    _repo = ref.read(izinIstekDetayRepositoryProvider);   // Cache repo in initState
    _emailService = ref.read(emailServiceProvider);
```

**Assessment:** ✅ CORRECT — Caching a repository reference (a `Provider<T>`, not a `FutureProvider`) in `initState()` via `ref.read()` is safe. The repository object doesn't change during the widget's lifetime.

---

## 8. PATTERNS CORRECTLY APPLIED

These patterns are well-implemented across the codebase:

### ✅ Mounted checks before context usage
Most screens check `if (!mounted) return` or `if (!context.mounted) return` after awaits before using `ScaffoldMessenger` or `Navigator`. Examples:
- `login_screen.dart:65` — `if (!mounted) return;`
- `bildirim_screen.dart:83` — `if (!mounted) return;`  
- `teknik_destek_detay_screen.dart:998` — `if (!context.mounted) return;`
- `egitim_istek_detay_screen.dart:433` — `if (!mounted) return;`

### ✅ Proper controller disposal
Screens consistently dispose `TextEditingController`, `ScrollController`, `FocusNode`, and `PageController` in `dispose()`:
- `login_screen.dart:37–40` — disposes both `_usernameController` and `_passwordController`
- `home_screen.dart:55–63` — removes route listener, observer, and disposes `_pageController`
- `bildirim_screen.dart:33–36` — removes and disposes `_scrollController`
- `izin_ekle_screen.dart:314–320` — disposes 5 `FocusNode` objects

### ✅ FutureProvider.autoDispose used correctly in many places
59 providers use `FutureProvider.autoDispose` correctly, including detail providers, list providers, and category providers with `ref.cacheFor()` for controlled caching.

### ✅ DeviceRegistrationService singleton is clean
**File:** `lib/core/services/device_registration_service.dart` — Singleton stores only `SharedPreferences`-based flags and device metadata. No `Ref` or `WidgetRef` stored.

### ✅ No StateNotifierProvider found
The codebase has migrated away from `StateNotifierProvider` (0 matches) to `Notifier`/`NotifierProvider` — this is the modern Riverpod pattern.

---

## SUMMARY TABLE

| # | Pattern | Severity | Count | Status |
|---|---------|----------|-------|--------|
| 1 | Singleton holding WidgetRef | 🔴 CRITICAL | 1 | `NotificationService._ref` |
| 2 | Uncancelled stream listeners | 🔴 CRITICAL | 2 | `onMessage.listen`, `onMessageOpenedApp.listen` |
| 3 | ref after await without mounted | 🟠 HIGH | ~40+ locations | Systematic across all `*_istek_screen`, `*_detay_screen` |
| 4 | ref.invalidate in dispose | 🟠 HIGH | 1 | `izin_ekle_screen.dart:321` |
| 5 | FutureProvider missing autoDispose | 🟠 HIGH | 16 | Across 5 provider files |
| 6 | Family with non-primitive param | 🟡 MEDIUM | 1 | Uses record type (safe) |
| 7 | ref.read/watch misuse | 🟢 LOW | 0 | No misuse found |
| 8 | Correct patterns | ✅ INFO | — | Mounted checks, disposal, autoDispose widely used |

---

## PRIORITY REMEDIATION ORDER

1. **NotificationService._ref** → Replace with `ProviderContainer` or dependency injection
2. **Uncancelled Firebase listeners** → Store subscriptions, cancel in a cleanup method
3. **ref.invalidate in dispose()** → Move to `autoDispose` + `ref.onDispose()` pattern
4. **Missing autoDispose** → Add `.autoDispose` to 16 FutureProviders (quick fix)
5. **ref after await** → Add `if (!mounted) return;` before each `ref.invalidate()` call after async gaps (systematic but straightforward)
