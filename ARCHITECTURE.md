# ESAS V1 - Feature-Based Architecture

Bu proje, 9 süreç için feature-based architecture kullanmaktadır.

## 📁 Proje Yapısı

```
lib/
├── core/                                    # Paylaşılan modüller
│   ├── models/
│   │   ├── result.dart                     # Success/Failure wrapper
│   │   ├── talep_adi.dart                  # API'den gelen süreç modeli
│   │   └── process_item.dart               # Deprecated
│   ├── network/
│   │   └── dio_provider.dart               # HTTP client
│   ├── repositories/
│   │   ├── base_repository.dart            # Ortak repository
│   │   └── talep_repository.dart           # Süreç listesi API'si
│   ├── providers/
│   │   └── talep_providers.dart            # Ana süreç listesi state
│   └── routing/
│       └── app_routes.dart                 # Dinamik routing
├── features/                               # Feature modülleri
│   ├── arac_istek/                        # 🚗 Araç İstek
│   │   ├── models/
│   │   │   └── arac_request.dart
│   │   ├── repositories/
│   │   │   └── arac_repository.dart
│   │   ├── providers/
│   │   │   └── arac_providers.dart
│   │   └── screens/
│   │       └── arac_istek_screen.dart
│   ├── bilgi_teknolojileri/               # 💻 Bilgi Teknolojileri
│   │   ├── models/
│   │   │   └── bi_teknolojileri_request.dart
│   │   ├── repositories/
│   │   │   └── bi_teknolojileri_repository.dart
│   │   └── screens/
│   │       └── bi_teknolojileri_screen.dart
│   ├── dokumantasyon_istek/               # 📄 Dokümantasyon İstek
│   │   └── screens/
│   │       └── dokumantasyon_istek_screen.dart
│   ├── egitim_istek/                      # 🎓 Eğitim İstek
│   │   └── screens/
│   │       └── egitim_istek_screen.dart
│   ├── izin_istek/                        # 🏖️ İzin İstek (FULL)
│   │   ├── models/
│   │   │   └── izin_request.dart
│   │   ├── repositories/
│   │   │   └── izin_repository.dart
│   │   ├── providers/
│   │   │   └── izin_providers.dart
│   │   └── screens/
│   │       └── izin_istek_screen.dart
│   ├── sarf_malzeme_istek/                # 📦 Sarf Malzeme İstek
│   │   └── screens/
│   │       └── sarf_malzeme_istek_screen.dart
│   ├── satin_alma/                        # 🛒 Satın Alma
│   │   └── screens/
│   │       └── satin_alma_screen.dart
│   ├── teknik_destek/                     # 🔧 Teknik Destek
│   │   └── screens/
│   │       └── teknik_destek_screen.dart
│   └── yiyecek_icecek_istek/              # 🍽️ Yiyecek İçecek İstek
│       └── screens/
│           └── yiyecek_icecek_istek_screen.dart
├── screens/
│   ├── processes_main_screen.dart          # Ana süreç seçim ekranı
│   └── api_test_screen.dart               # API test ekranı
└── main.dart
```

## 🎯 Feature Implementation Status

### ✅ Fully Implemented
- **İzin İstek**: Full CRUD with Riverpod state management
- **API Integration**: Dynamic process loading
- **Routing System**: Auto-route generation

### 🏗️ Basic Structure Ready
- **Araç İstek**: Models, repositories, providers ready
- **Bilgi Teknolojileri**: Models, repositories ready
- **Dokümantasyon İstek**: Screen ready
- **Eğitim İstek**: Screen ready
- **Sarf Malzeme İstek**: Screen ready
- **Satın Alma**: Screen ready
- **Teknik Destek**: Screen ready
- **Yiyecek İçecek İstek**: Screen ready

## 🚀 Development Workflow

### Bir Feature'ı Tamamlamak İçin:

1. **Models Oluştur** (varsa atla):
```dart
// lib/features/[feature_name]/models/[feature]_request.dart
class FeatureRequest {
  // Request model fields
}

class FeatureResponse {
  // Response model fields
}
```

2. **Repository Oluştur** (varsa atla):
```dart
// lib/features/[feature_name]/repositories/[feature]_repository.dart
abstract class FeatureRepository {
  Future<Result<FeatureResponse>> submitRequest(FeatureRequest request);
}
```

3. **Providers Oluştur** (varsa atla):
```dart
// lib/features/[feature_name]/providers/[feature]_providers.dart
class FeatureFormNotifier extends Notifier<FeatureFormState> {
  // State management logic
}
```

4. **UI Tamamla**:
```dart
// lib/features/[feature_name]/screens/[feature]_screen.dart
// Form fields, validation, submission logic
```

## 🔗 API Endpoints

- **Base URL**: `https://esasapi.eyuboglu.k12.tr/api/TalepYonetimi/`
- **Süreç Listesi**: `GET /TalepAdlari`
- **Her süreç için**: `POST /[process-endpoint]`

## 🛠️ Commands

```bash
# Run app
flutter run -d chrome

# Test API
http://localhost:port/#/api-test

# Analyze code
flutter analyze

# Clean & rebuild
flutter clean && flutter pub get
```

## 📋 Next Steps

1. Her feature için form UI'ını tamamla
2. API endpoint'lerini implement et
3. Validation logic ekle
4. Unit testler yaz
5. Integration testler ekle