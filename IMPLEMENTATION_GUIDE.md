# 🚀 Kalan 8 Sürecin Implementation Guide

## 📊 Mevcut Durum

### ✅ TAMAMLANDI
**İzin İstek** - %100 Complete
- ✅ Models (izin_request.dart, izin_response.dart)
- ✅ Repository (izin_repository.dart)
- ✅ Providers (izin_providers.dart)
- ✅ Screen (izin_istek_screen.dart) - Full form UI

---

## 🔨 İMPLEMENTASYON GEREKLİ

### 1. **Araç İstek** - %75 Complete
**Mevcut:**
- ✅ Models: `arac_request.dart` (7 alan)
- ✅ Repository: `arac_repository.dart`
- ✅ Providers: `arac_providers.dart`
- ⏳ Screen: `arac_istek_screen.dart` (Placeholder, form yok)

**Gerekli:**
```dart
// Screen'de olması gerekenler:
- Dropdown: Araç Türü (Servis Aracı, Binek Araç, Minibüs, Ticari Araç)
- DatePicker: Kullanım Tarihi
- TimePicker: Kullanım Saati
- TextField: Gidilecek Yer
- TextField: Kullanım Amacı
- Dropdown: Şoför Gerekli mi? (Evet/Hayır)
- TextArea: Açıklama (Opsiyonel)
- Button: Gönder
```

---

### 2. **Bilgi Teknolojileri** - %60 Complete
**Mevcut:**
- ✅ Models: `bi_teknolojileri_request.dart`
  ```dart
  - talepTuru: String
  - oncelik: String  
  - aciklama: String
  - sistemBilgisi: String?
  - dosyaEki: String?
  ```
- ✅ Repository: `bi_teknolojileri_repository.dart`
- ⚠️ Providers: `bt_providers.dart` (Var ama hatalar var)
- ⏳ Screen: `bi_teknolojileri_screen.dart` (Placeholder)

**Gerekli:**
```dart
// Providers'ı düzelt:
- talepTuru: 'Yazılım', 'Donanım', 'Ağ', 'Kullanıcı Hesabı'
- oncelik: 'Düşük', 'Orta', 'Yüksek', 'Acil'
- aciklama: TextField
- sistemBilgisi: TextField (opsiyonel)

// Screen oluştur:
- Dropdown: Talep Türü
- Dropdown: Öncelik
- TextArea: Açıklama
- TextField: Sistem Bilgisi (optional)
- Button: Gönder
```

---

### 3. **Dokümantasyon İstek** - %20 Complete
**Mevcut:**
- ⏳ Screen: `dokumantasyon_istek_screen.dart` (Placeholder)
- ❌ Models yok
- ❌ Repository yok
- ❌ Providers yok

**Gerekli:**
```dart
// 1. Model oluştur: dokumantasyon_request.dart
class DokumantasyonRequest {
  final String dokumentTuru;      // Örn: Transkript, Diploma, Veli Mektubu
  final String teslimatSekli;     // Fiziksel, Dijital
  final int adet;                 // Kaç adet
  final String aciklama;
  final DateTime? teslimatTarihi;
}

// 2. Repository oluştur
// 3. Providers oluştur
// 4. Screen form UI oluştur
```

---

### 4. **Eğitim İstek** - %20 Complete
**Mevcut:**
- ⏳ Screen: `egitim_istek_screen.dart` (Placeholder)
- ❌ Models yok
- ❌ Repository yok
- ❌ Providers yok

**Gerekli:**
```dart
// 1. Model oluştur: egitim_request.dart
class EgitimRequest {
  final String egitimKonusu;      // Konu
  final String egitimTuru;        // Online, Yüz Yüze, Seminer
  final DateTime tercihEdilenTarih;
  final int katilimciSayisi;
  final String aciklama;
  final String? butce;           // Tahmini bütçe
}

// 2. Repository oluştur
// 3. Providers oluştur
// 4. Screen form UI oluştur
```

---

### 5. **Sarf Malzeme İstek** - %20 Complete
**Mevcut:**
- ⏳ Screen: `sarf_malzeme_istek_screen.dart` (Placeholder)
- ❌ Models yok
- ❌ Repository yok
- ❌ Providers yok

**Gerekli:**
```dart
// 1. Model oluştur: sarf_malzeme_request.dart
class SarfMalzemeRequest {
  final String malzemeAdi;        // Malzeme adı
  final String malzemeTuru;       // Kırtasiye, Temizlik, Teknik, Diğer
  final int miktar;               // Adet
  final String birim;             // Adet, Paket, Kutu
  final String kullanimAmaci;     // Nerede kullanılacak
  final String? aciklama;
  final DateTime? ihtiyacTarihi;  // Ne zaman gerekli
}

// 2. Repository oluştur
// 3. Providers oluştur
// 4. Screen form UI oluştur
```

---

### 6. **Satın Alma** - %20 Complete
**Mevcut:**
- ⏳ Screen: `satin_alma_screen.dart` (Placeholder)
- ❌ Models yok
- ❌ Repository yok
- ❌ Providers yok

**Gerekli:**
```dart
// 1. Model oluştur: satin_alma_request.dart
class SatinAlmaRequest {
  final String urunAdi;           // Ürün/hizmet adı
  final String kategori;          // Yazılım, Donanım, Hizmet, Diğer
  final int miktar;
  final String? tedarikci;        // Önerilen tedarikçi
  final double? tahminiTutar;     // Tahmini fiyat
  final String gerekce;           // Neden gerekli
  final DateTime? ihtiyacTarihi;
  final String? aciklama;
}

// 2. Repository oluştur
// 3. Providers oluştur
// 4. Screen form UI oluştur
```

---

### 7. **Teknik Destek** - %20 Complete
**Mevcut:**
- ⏳ Screen: `teknik_destek_screen.dart` (Placeholder)
- ❌ Models yok
- ❌ Repository yok
- ❌ Providers yok

**Gerekli:**
```dart
// 1. Model oluştur: teknik_destek_request.dart
class TeknikDestekRequest {
  final String sorunKategorisi;  // Donanım, Yazılım, Ağ, Diğer
  final String oncelik;          // Düşük, Orta, Yüksek, Acil
  final String sorunAciklamasi;
  final String? etkilenenCihaz;  // Bilgisayar, Yazıcı, vs.
  final String? konum;           // Sorunun olduğu yer
  final String? hataKodu;        // Varsa hata kodu/mesajı
  final bool uzaktanErisim;      // Uzaktan çözülebilir mi?
}

// 2. Repository oluştur
// 3. Providers oluştur
// 4. Screen form UI oluştur
```

---

### 8. **Yiyecek İçecek İstek** - %20 Complete
**Mevcut:**
- ⏳ Screen: `yiyecek_icecek_istek_screen.dart` (Placeholder)
- ❌ Models yok
- ❌ Repository yok
- ❌ Providers yok

**Gerekli:**
```dart
// 1. Model oluştur: yiyecek_icecek_request.dart
class YiyecekIcecekRequest {
  final String etkinlikAdi;      // Etkinlik adı
  final DateTime etkinlikTarihi;
  final DateTime etkinlikSaati;
  final int kisiSayisi;          // Kaç kişilik
  final String menuTercihi;      // Kahvaltı, Öğle, Akşam, Kokteyl
  final String? diyetIhtiyaclari;// Vejetaryen, Vegan, Alerjiler
  final String? ozelIstekler;
  final String? lokasyon;        // Nerede servis edilecek
  final double? butce;           // Kişi başı tahmini bütçe
}

// 2. Repository oluştur
// 3. Providers oluştur
// 4. Screen form UI oluştur
```

---

## 🎯 Implementation Pattern (Her Süreç İçin)

### Adım 1: Model Oluştur
```dart
// lib/features/[feature_name]/models/[feature]_request.dart

class FeatureRequest {
  final String field1;
  final int field2;
  // ... diğer alanlar

  const FeatureRequest({
    required this.field1,
    required this.field2,
  });

  Map<String, dynamic> toJson() {
    return {
      'field1': field1,
      'field2': field2,
    };
  }

  factory FeatureRequest.fromJson(Map<String, dynamic> json) {
    return FeatureRequest(
      field1: json['field1'] as String,
      field2: json['field2'] as int,
    );
  }
}

class FeatureResponse {
  final String id;
  final String status;
  final String? message;

  const FeatureResponse({
    required this.id,
    required this.status,
    this.message,
  });

  factory FeatureResponse.fromJson(Map<String, dynamic> json) {
    return FeatureResponse(
      id: json['id'] as String,
      status: json['status'] as String,
      message: json['message'] as String?,
    );
  }
}
```

### Adım 2: Repository Oluştur
```dart
// lib/features/[feature_name]/repositories/[feature]_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/repositories/base_repository.dart';
import '../../../core/models/result.dart';
import '../models/[feature]_request.dart';

abstract class FeatureRepository {
  Future<Result<FeatureResponse>> submitRequest(FeatureRequest request);
}

class FeatureRepositoryImpl extends BaseRepository
    implements FeatureRepository {
  final Dio _dio;

  FeatureRepositoryImpl(this._dio);

  @override
  Future<Result<FeatureResponse>> submitRequest(
    FeatureRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '[feature-endpoint]', // API endpoint
        data: request.toJson(),
      );

      return handleResponse(
        response,
        (data) => FeatureResponse.fromJson(data),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return Failure('Unexpected error: $e');
    }
  }
}

final featureRepositoryProvider = Provider<FeatureRepository>((ref) {
  final dio = ref.read(dioProvider);
  return FeatureRepositoryImpl(dio);
});
```

### Adım 3: Providers Oluştur
```dart
// lib/features/[feature_name]/providers/[feature]_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/result.dart';
import '../models/[feature]_request.dart';
import '../repositories/[feature]_repository.dart';

class FeatureFormState {
  final String? field1;
  final int? field2;
  final bool acceptedTerms;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const FeatureFormState({
    this.field1,
    this.field2,
    this.acceptedTerms = false,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  FeatureFormState copyWith({
    String? field1,
    int? field2,
    bool? acceptedTerms,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return FeatureFormState(
      field1: field1 ?? this.field1,
      field2: field2 ?? this.field2,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  bool get isValid {
    return field1 != null &&
        field1!.isNotEmpty &&
        field2 != null &&
        acceptedTerms;
  }
}

class FeatureFormNotifier extends Notifier<FeatureFormState> {
  @override
  FeatureFormState build() {
    return const FeatureFormState();
  }

  void updateField1(String? value) {
    state = state.copyWith(field1: value, errorMessage: null);
  }

  void updateField2(int? value) {
    state = state.copyWith(field2: value, errorMessage: null);
  }

  void updateAcceptedTerms(bool accepted) {
    state = state.copyWith(acceptedTerms: accepted, errorMessage: null);
  }

  Future<void> submitForm() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage: 'Lütfen tüm zorunlu alanları doldurun.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final request = FeatureRequest(
      field1: state.field1!,
      field2: state.field2!,
    );

    final repository = ref.read(featureRepositoryProvider);
    final result = await repository.submitRequest(request);

    switch (result) {
      case Success(data: final response):
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message ?? 'Başarılı!',
        );
      case Failure(message: final error):
        state = state.copyWith(
          isLoading: false,
          errorMessage: error,
        );
      case Loading():
        break;
    }
  }

  void reset() {
    state = const FeatureFormState();
  }
}

final featureFormProvider = NotifierProvider<FeatureFormNotifier, FeatureFormState>(
  () => FeatureFormNotifier(),
);
```

### Adım 4: Screen Oluştur
```dart
// İzin İstek screen'ini referans alarak aynı yapıyı kopyala
// Sadece alanları değiştir
```

---

## 🚀 Önerilen Sıralama

1. **Teknik Destek** (BT'ye benzer, basit)
2. **Dokümantasyon** (Az alan, kolay)
3. **Eğitim İstek** (Orta seviye)
4. **Sarf Malzeme** (Orta seviye)
5. **Satın Alma** (Orta seviye)
6. **Yiyecek İçecek** (Daha fazla alan)

---

## ⚡ Hızlı Start

Bir süreç seçin, ben 4 adımı sırayla implement edeyim:
1. Model
2. Repository  
3. Providers
4. Screen

**Hangisiyle başlayalım?**
