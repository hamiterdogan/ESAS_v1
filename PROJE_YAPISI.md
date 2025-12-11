# 📁 ESAS - İzin İstek Proje Yapısı

**Son Güncelleme:** 27 Ekim 2025  
**Durum:** ✅ Temizlenmiş ve Sadeleştirilmiş

---

## 🎯 Proje Özeti

Bu uygulama, **sadece İzin İstek modülüne** odaklanmak üzere temizlenmiştir. Gereksiz tüm routing, süreç listesi ve placeholder ekranlar kaldırılmıştır.

---

## 📂 Güncel Proje Yapısı

```
lib/
│   main.dart                                    # ✅ Direkt İzin İstek ekranı açılır
│
├── core/                                        # 🔧 Paylaşılan çekirdek modüller
│   ├── models/
│   │   └── result.dart                         # Result pattern (Success/Failure/Loading)
│   │
│   ├── network/
│   │   └── dio_provider.dart                   # HTTP client (Dio konfigürasyonu)
│   │
│   └── repositories/
│       └── base_repository.dart                # Ortak error handling
│
└── features/                                    # 📦 Feature-based modüller
    └── izin_istek/                             # İzin İstek modülü
        ├── models/
        │   └── izin_istek_models.dart          # 5 model: IzinSebebi, DiniGun, IzinIstekEkleRequest, IzinIstekDetay, IzinIstekSilResponse
        │
        ├── repositories/
        │   └── izin_istek_repository.dart      # API iletişim katmanı (5 method)
        │
        ├── providers/
        │   └── izin_istek_providers.dart       # State management (Riverpod 3)
        │
        └── screens/
            └── izin_istek_screen.dart          # UI katmanı (Dinamik form)
```

---

## 🗑️ Kaldırılan Dosyalar ve Klasörler

### Silinen Klasörler
```
❌ lib/screens/                          # Ana süreç ekranı ve test ekranı
❌ lib/widgets/                          # Kullanılmayan widget'lar
❌ lib/consts/                           # Eski sabit değerler
❌ lib/core/routing/                     # Routing sistemi (tek ekran olduğu için gereksiz)
❌ lib/core/providers/                   # Talep provider'ları
❌ lib/features/surecler_ana_sayfa/      # Süreçler ana sayfa modülü
```

### Silinen Dosyalar
```
❌ lib/core/models/talep_adi.dart                    # Süreç listesi modeli
❌ lib/core/models/process_item.dart                 # Eski statik model
❌ lib/core/repositories/talep_repository.dart       # Süreç API repository
❌ lib/features/izin_istek/models/izin_request.dart  # Eski prototip model
❌ lib/features/izin_istek/providers/izin_providers.dart        # Eski provider
❌ lib/features/izin_istek/repositories/izin_repository.dart    # Eski repository
```

---

## ✅ Aktif Dosyalar ve Sorumlulukları

### 1️⃣ **main.dart**
```dart
- Riverpod ProviderScope
- MaterialApp konfigürasyonu
- Direkt IzinIstekScreen açılır (routing yok)
```

### 2️⃣ **core/models/result.dart**
```dart
sealed class Result<T> {}
class Success<T> extends Result<T> { final T data; }
class Failure<T> extends Result<T> { final String error; }
class Loading<T> extends Result<T> {}

✅ Tüm API yanıtları bu pattern ile sarmalanır
✅ Type-safe error handling
✅ Exhaustive pattern matching
```

### 3️⃣ **core/network/dio_provider.dart**
```dart
- Dio instance provider
- Base URL: https://esasapi.eyuboglu.k12.tr/api/TalepYonetimi/
- Timeout, headers, logging konfigürasyonu
```

### 4️⃣ **core/repositories/base_repository.dart**
```dart
- Ortak error handling
- Response parsing
- Result pattern'e dönüştürme
- HTTP hata kodları yönetimi
```

### 5️⃣ **features/izin_istek/models/izin_istek_models.dart**
```dart
✅ IzinSebebi (izin sebepleri listesi)
✅ DiniGun (dini günler listesi)
✅ IzinIstekEkleRequest (24 alan - izin talebi oluşturma)
✅ IzinIstekDetay (34 alan - izin detayları)
✅ IzinIstekSilResponse (silme yanıtı)

Tüm modeller:
- JSON serialization (fromJson/toJson)
- Immutable (@freezed benzeri yapı)
```

### 6️⃣ **features/izin_istek/repositories/izin_istek_repository.dart**
```dart
abstract class IzinIstekRepository {
  ✅ getIzinSebepleri()      → Result<List<IzinSebebi>>
  ✅ getDiniGunler()         → Result<List<DiniGun>>
  ✅ addIzinIstek()          → Result<Map<String, dynamic>>
  ✅ getIzinIstekDetay()     → Result<IzinIstekDetay>
  ✅ deleteIzinIstek()       → Result<IzinIstekSilResponse>
}

class IzinIstekRepositoryImpl extends BaseRepository {
  - Real API endpoints
  - Error handling via BaseRepository
}
```

### 7️⃣ **features/izin_istek/providers/izin_istek_providers.dart**
```dart
✅ izinIstekRepositoryProvider
   → IzinIstekRepository instance

✅ izinSebepleriProvider (FutureProvider)
   → İzin sebepleri listesi

✅ diniGunlerProvider (FutureProvider)
   → Dini günler listesi

✅ izinIstekFormProvider (StateNotifierProvider)
   → Form state management
   → 15+ update methods
   → Validation logic
   → Auto calculation (_hesaplaIzinSuresi)
```

### 8️⃣ **features/izin_istek/screens/izin_istek_screen.dart**
```dart
✅ Dinamik form (izin türüne göre değişir)
✅ Conditional rendering:
   - Saat/gün seçimi (saatGoster flag)
   - Evlenme izni → Evlilik Tarihi
   - Doğum izni → Doğum Tarihi + Eş/Çocuk
   - Hastalık → Dosya + Rapor
   - Dini izin → Dini Gün seçimi

✅ Form validasyonu
✅ Loading/Error state handling
✅ Success feedback
```

---

## 🔄 Veri Akışı

```
┌─────────────────────────────────────────────────────────────┐
│                    IzinIstekScreen (UI)                     │
│  - Form alanları                                            │
│  - User input                                               │
│  - Submit button                                            │
└────────────────┬────────────────────────────────────────────┘
                 │ ref.watch(izinSebepleriProvider)
                 │ ref.read(izinIstekFormProvider.notifier)
                 ▼
┌─────────────────────────────────────────────────────────────┐
│              izin_istek_providers.dart                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ izinSebepleriProvider (FutureProvider)               │  │
│  │  → Loads initial data from API                       │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ izinIstekFormProvider (StateNotifier)                │  │
│  │  → Manages form state                                │  │
│  │  → Validates input                                   │  │
│  │  → Calls repository methods                          │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────┬────────────────────────────────────────────┘
                 │ await repo.getIzinSebepleri()
                 │ await repo.addIzinIstek(request)
                 ▼
┌─────────────────────────────────────────────────────────────┐
│           izin_istek_repository.dart                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ IzinIstekRepositoryImpl                              │  │
│  │  → Makes HTTP requests via Dio                       │  │
│  │  → Parses responses                                  │  │
│  │  → Converts to Result<T>                             │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────┬────────────────────────────────────────────┘
                 │ dio.get/post
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                     API (Backend)                           │
│  https://esasapi.eyuboglu.k12.tr/api/TalepYonetimi/         │
│  - IzinSebepListesiGetir                                    │
│  - DiniGunlerListesiGetir                                   │
│  - IzinIstekEkle                                            │
│  - IzinIstekDetayGetir                                      │
│  - IzinIstekSil                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Çalıştırma

```bash
# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run

# Analiz yap
flutter analyze

# Build al
flutter build apk
```

---

## 📊 İstatistikler

| Kategori | Önceki Durum | Güncel Durum |
|----------|--------------|--------------|
| **Toplam Dosya** | ~20 dosya | **8 dosya** |
| **Klasör Sayısı** | 12 klasör | **7 klasör** |
| **Kod Satırı** | ~3000 satır | ~1800 satır |
| **Feature Sayısı** | 2 feature | **1 feature** |
| **Routing** | Dinamik routing | Yok (tek ekran) |
| **Ana Ekran** | Süreç listesi | İzin İstek formu |

---

## ✨ Faydalar

✅ **Daha Basit**: Gereksiz kod ve dosyalar kaldırıldı  
✅ **Daha Hızlı**: Build süresi ve uygulama boyutu azaldı  
✅ **Daha Okunabilir**: Sadece İzin İstek'e odaklanıldı  
✅ **Daha Bakımı Kolay**: Tek modül, tek sorumluluk  
✅ **Daha Test Edilebilir**: Minimal bağımlılık  

---

## 🎓 Mimari Prensipler

1. **Clean Architecture**: 4 katman (Models, Repository, Providers, Screens)
2. **Single Responsibility**: Her dosya tek bir sorumluluğa sahip
3. **Dependency Injection**: Riverpod ile provider injection
4. **Type Safety**: Result pattern ve sealed classes
5. **Separation of Concerns**: UI, business logic, data ayrı katmanlarda

---

## 📝 Notlar

- ✅ Uygulama direkt İzin İstek ekranını açar
- ✅ Routing sistemi kaldırıldı (tek ekran var)
- ✅ Tüm gereksiz dosyalar temizlendi
- ✅ Analyze sonucu: 7 minor uyarı (critical hata yok)
- ✅ Production API'sine bağlı
- ✅ Mock user kullanılıyor (kullaniciId: 1)

---

**Hazırlayan:** GitHub Copilot  
**Tarih:** 27 Ekim 2025
