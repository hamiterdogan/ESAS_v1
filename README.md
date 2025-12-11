# ESAS - İzin İstek Uygulaması

## � Proje Özeti

Bu uygulama, **İzin İstek** sürecini yönetmek için geliştirilmiş bir Flutter uygulamasıdır. **Clean Architecture** ve **Riverpod 3** state management kullanılarak modern, ölçeklenebilir ve bakımı kolay bir yapıda tasarlanmıştır.

---

## 🏗️ Mimari Yapı

### **Clean Architecture (4 Katman)**

```
lib/
├── core/                              # 🔧 Paylaşılan modüller
│   ├── models/
│   │   └── result.dart               # Result pattern (Success/Failure/Loading)
│   ├── network/
│   │   └── dio_provider.dart        # HTTP client (Dio)
│   └── repositories/
│       └── base_repository.dart     # Ortak hata yönetimi
│
└── features/                          # 📦 Feature-based modüller
    └── izin_istek/                   # İzin İstek modülü
        ├── models/
        │   └── izin_istek_models.dart       # 5 model sınıfı
        ├── repositories/
        │   └── izin_istek_repository.dart   # API katmanı
        ├── providers/
        │   └── izin_istek_providers.dart    # State management
        └── screens/
            └── izin_istek_screen.dart       # UI katmanı
```

---

## 🌐 API Entegrasyonu

### **Base URL**
```
https://esasapi.eyuboglu.k12.tr/api/TalepYonetimi/
```

### **Endpoint'ler**

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/IzinSebepListesiGetir` | İzin sebepleri listesi |
| `GET` | `/DiniGunlerListesiGetir` | Dini günler listesi |
| `POST` | `/IzinIstekEkle` | Yeni izin talebi oluştur |
| `POST` | `/IzinIstekDetayGetir` | İzin detaylarını getir |
| `POST` | `/IzinIstekSil` | İzin talebini sil |

---

## 🔄 State Management (Riverpod 3)

### **1. Provider Yapısı**

```dart
// Repository Provider
final izinIstekRepositoryProvider = Provider<IzinIstekRepository>((ref) {
  return IzinIstekRepositoryImpl();
});

// İzin Sebepleri Provider
final izinSebepleriProvider = FutureProvider<List<IzinSebebi>>((ref) async {
  final repo = ref.watch(izinIstekRepositoryProvider);
  final result = await repo.getIzinSebepleri();
  
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw Exception(error),
    Loading() => throw Exception('Yükleniyor...'),
  };
});

// Form State Provider
final izinIstekFormProvider = StateNotifierProvider<IzinIstekFormNotifier, IzinIstekFormState>((ref) {
  return IzinIstekFormNotifier(ref);
});
```

### **2. Result Pattern**

```dart
sealed class Result<T> {}

class Success<T> extends Result<T> {
  final T data;
  Success(this.data);
}

class Failure<T> extends Result<T> {
  final String error;
  Failure(this.error);
}

class Loading<T> extends Result<T> {}
```

**Kullanım:**
```dart
final result = await repo.getIzinSebepleri();

switch (result) {
  case Success(:final data):
    print('Başarılı: ${data.length} sebep yüklendi');
    
  case Failure(:final error):
    print('Hata: $error');
    
  case Loading():
    print('Yükleniyor...');
}
```

---

## 📋 İzin İstek Modülü

### **Models (5 Adet)**

1. **IzinSebebi**: İzin sebepleri (`izinSebebiId`, `izinSebebiAd`, `saatGoster`)
2. **DiniGun**: Dini günler listesi
3. **IzinIstekEkleRequest**: İzin talebi oluşturma (24 alan)
4. **IzinIstekDetay**: İzin detayları (34 alan)
5. **IzinIstekSilResponse**: Silme yanıtı

### **Repository (5 Method)**

- `getIzinSebepleri()`: İzin sebepler listesi
- `getDiniGunler()`: Dini günler listesi
- `addIzinIstek()`: Yeni izin talebi
- `getIzinIstekDetay()`: Detay bilgileri
- `deleteIzinIstek()`: Talep silme

### **Providers**

- `izinSebepleriProvider`: İzin sebepleri listesi
- `diniGunlerProvider`: Dini günler listesi
- `izinIstekFormProvider`: Form state management (15+ update metodu)

### **Screen Features**

✅ Dinamik form (izin türüne göre değişen alanlar)  
✅ Saat/gün seçimi (izin türüne göre)  
✅ Otomatik süre hesaplama  
✅ Evlenme/Doğum/Hastalık için özel alanlar  
✅ Dini izin için özel tarih seçimi  
✅ Form validasyonu  
✅ Loading/error state yönetimi  

---

## 🚀 Kurulum ve Çalıştırma

### **1. Bağımlılıkları Yükle**
```bash
flutter pub get
```

### **2. Uygulamayı Çalıştır**
```bash
flutter run
```

### **3. Build Al**
```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

---

## 📚 Teknik Detaylar

### **Kullanılan Paketler**

```yaml
dependencies:
  flutter_riverpod: ^3.0.3
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  dio: ^5.9.3
  intl: ^0.20.2

dev_dependencies:
  build_runner: ^2.5.4
  freezed: ^2.5.8
  json_serializable: ^6.9.5
```

### **Dart Özellikleri**

- ✅ Dart 3 pattern matching
- ✅ Sealed classes
- ✅ Record types
- ✅ Destructuring syntax (`:final data`)
- ✅ Generic programming (`Result<T>`)

---

## 🎓 Öğrenilen Konseptler

### **1. Clean Architecture**
- 4 katmanlı yapı (Models, Repository, Providers, Screens)
- Separation of concerns
- Dependency injection

### **2. Result Pattern**
- Type-safe error handling
- Exhaustive pattern matching
- Loading/Success/Failure states

### **3. State Management**
- Riverpod 3.0 best practices
- StateNotifier pattern
- Provider composition

### **4. Modern Dart**
- Pattern matching
- Sealed classes
- Generic programming

---

## 📝 Notlar

- **API URL**: Production ortamda çalışıyor
- **Authentication**: Şu an mock user (`kullaniciId: 1`)
- **Platform**: Cross-platform (Android, iOS, Web, Desktop)
- **Min SDK**: Flutter 3.0+, Dart 3.0+

---

## 📞 İletişim

Proje ile ilgili sorularınız için: [GitHub Issues](https://github.com/yourusername/esas_v1/issues)

---

**Son Güncelleme**: Ekim 2025  
**Versiyon**: 1.0.0  
**Durum**: ✅ Aktif Geliştirme
- [x] Error handling ve loading states
- [x] İzin İstek formu (örnek)

### 🔄 Geliştirilecek
- [ ] Diğer süreç formları
- [ ] Authentication
- [ ] Unit testler
