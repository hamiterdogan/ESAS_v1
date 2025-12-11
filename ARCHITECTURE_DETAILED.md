# 🏗️ ESAS V1 - Detaylı Mimari Açıklaması

## 📚 İçindekiler
1. [Mimari Genel Bakış](#mimari-genel-bakış)
2. [Katmanlı Mimari](#katmanlı-mimari)
3. [Core Katmanı](#core-katmanı)
4. [Feature Katmanı](#feature-katmanı)
5. [State Management (Riverpod 3)](#state-management)
6. [Veri Akışı](#veri-akışı)
7. [Neden Bu Mimari?](#neden-bu-mimari)

---

## 🎯 Mimari Genel Bakış

### Kullanılan Mimari Pattern: **Feature-Based Clean Architecture**

```
┌─────────────────────────────────────────────────────────┐
│                     PRESENTATION                         │
│  (Screens, Widgets, UI Components)                      │
│  - processes_main_screen.dart                           │
│  - izin_istek_screen.dart                               │
└──────────────────┬──────────────────────────────────────┘
                   │ user interaction
                   ↓
┌─────────────────────────────────────────────────────────┐
│              STATE MANAGEMENT (Riverpod 3)              │
│  (Providers, Notifiers, State Classes)                  │
│  - TalepAdlariNotifier (süreç listesi)                  │
│  - IzinFormNotifier (form state)                        │
└──────────────────┬──────────────────────────────────────┘
                   │ state updates
                   ↓
┌─────────────────────────────────────────────────────────┐
│                   BUSINESS LOGIC                         │
│  (Repositories, Use Cases)                              │
│  - TalepRepository (API calls)                          │
│  - IzinRepository (izin işlemleri)                      │
└──────────────────┬──────────────────────────────────────┘
                   │ data operations
                   ↓
┌─────────────────────────────────────────────────────────┐
│                    DATA LAYER                            │
│  (Network, Local Storage, Models)                       │
│  - Dio HTTP Client                                      │
│  - Result<T> wrapper                                    │
│  - JSON Models                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 🏛️ Katmanlı Mimari

### 1️⃣ **CORE Katmanı** (Paylaşılan Altyapı)
**Amaç:** Tüm feature'lar tarafından kullanılan ortak kod ve altyapı

#### 📁 `lib/core/network/`
**Ne yapar?** HTTP istekleri için Dio client yapılandırması

**Neden gerekli?**
- ✅ **Tek Nokta Yapılandırma:** Base URL, timeout, header'lar tek yerden yönetilir
- ✅ **Merkezi Hata Yönetimi:** Tüm API hataları aynı şekilde ele alınır
- ✅ **Authentication:** Token injection (şu an yorum satırında, ileride aktif olacak)
- ✅ **Logging:** Tüm istekler otomatik loglanır (debugging için)

```dart
// dio_provider.dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  
  // Base URL - Tüm API çağrıları bu URL'i kullanır
  dio.options.baseUrl = 'https://esasapi.eyuboglu.k12.tr/api/TalepYonetimi/';
  
  // Timeout ayarları - 30 saniye sonra timeout
  dio.options.connectTimeout = Duration(seconds: 30);
  
  // Interceptors - Her request/response'u yakalayıp işleyebiliriz
  dio.interceptors.add(LogInterceptor()); // Loglama
  dio.interceptors.add(AuthInterceptor()); // Token ekleme (gelecekte)
  
  return dio;
});
```

**Avantajları:**
- Eğer API base URL değişirse, sadece bu dosyayı değiştiriyoruz
- Her feature kendi Dio instance'ı oluşturmak zorunda kalmıyor
- Timeout, retry gibi ayarlar merkezi

---

#### 📁 `lib/core/models/`
**Ne yapar?** Ortak veri modelleri

**1. `result.dart` - Result Pattern**

**Neden gerekli?**
- ✅ **Type-Safe Hata Yönetimi:** Compile-time'da hataları yakalarız
- ✅ **Null Safety:** Dart'ın null safety özelliğiyle uyumlu
- ✅ **Loading State:** Kullanıcıya yükleniyor gösterebiliriz
- ✅ **Explicit Error Handling:** Her durum (success/failure/loading) açıkça ele alınır

```dart
// Result Pattern - Functional Programming'den ilham alındı
sealed class Result<T> {
  const Result();
}

// Başarılı durum - Data var
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

// Hata durumu - Mesaj ve detaylar var
class Failure<T> extends Result<T> {
  final String message;
  final int? statusCode;
  const Failure(this.message, {this.statusCode});
}

// Yükleniyor durumu
class Loading<T> extends Result<T> {
  const Loading();
}
```

**Kullanım Örneği:**
```dart
// Repository'de
Future<Result<List<TalepAdi>>> getTalepAdlari() async {
  try {
    final response = await dio.get('/TalepAdlari');
    return Success(response.data); // ✅ Başarılı
  } on DioException catch (e) {
    return Failure(e.message); // ❌ Hata
  }
}

// UI'da
final result = await repository.getTalepAdlari();
switch (result) {
  case Success(data: final processes):
    // 🎉 Verileri göster
    showProcesses(processes);
  case Failure(message: final error):
    // ❌ Hata mesajı göster
    showError(error);
  case Loading():
    // ⏳ Yükleniyor göster
    showLoader();
}
```

**Alternatif Yaklaşımlar (Neden kullanmadık?):**
- ❌ `try-catch` her yerde: Kod tekrarı, hata yönetimi karmaşık
- ❌ `null` döndürme: Hata mesajı alamayız
- ❌ Exception fırlatma: Unhandled exception riski

---

**2. `talep_adi.dart` - API Process Model**

**Neden gerekli?**
- ✅ **Type Safety:** API'den gelen JSON'u strongly-typed objeye çeviriyoruz
- ✅ **Business Logic:** Icon mapping, route generation gibi ek özellikler
- ✅ **Validation:** Aktif/pasif süreç filtresi

```dart
class TalepAdi {
  final int id;
  final String talepAdi;
  final bool aktif;
  
  // JSON'dan obje oluştur
  factory TalepAdi.fromJson(Map<String, dynamic> json) => TalepAdi(
    id: json['id'] as int,
    talepAdi: json['talepAdi'] as String,
    aktif: json['aktif'] as bool? ?? true,
  );
  
  // Routing için: "İzin İstek" → "izin-istek"
  String get routeName => talepAdi
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll(' ', '-');
  
  // UI için emoji icon mapping
  String get displayIcon {
    if (talepAdi.contains('İzin')) return '🏖️';
    if (talepAdi.contains('Araç')) return '🚗';
    // ... diğer mappings
    return '📋';
  }
}
```

**Avantajları:**
- API değişirse, sadece model'i güncelliyoruz
- Business logic (icon, route) model içinde - tek sorumluluk
- Type-safe: Yanlış field'a erişemeyiz

---

#### 📁 `lib/core/repositories/`
**Ne yapar?** API çağrıları ve veri işlemleri

**1. `base_repository.dart` - Ortak Repository Logic**

**Neden gerekli?**
- ✅ **DRY Principle:** Hata yönetimi kodu tekrar etmez
- ✅ **Consistent Error Handling:** Tüm repository'ler aynı şekilde hata yönetir
- ✅ **Reusability:** Her repository bu base class'ı extend eder

```dart
abstract class BaseRepository {
  // HTTP response'u Result<T>'ye çevir
  Result<T> handleResponse<T>(
    Response response,
    T Function(dynamic data) fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Success(fromJson(response.data)); // ✅ Başarılı
    }
    return Failure('Error: ${response.statusCode}'); // ❌ Hata
  }
  
  // DioException'ı Result<T>'ye çevir
  Result<T> handleError<T>(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Failure('Bağlantı zaman aşımı');
      case DioExceptionType.connectionError:
        return Failure('İnternet bağlantısı yok');
      // ... diğer error types
    }
  }
}
```

**Kullanım:**
```dart
// Her repository bu base'i extend eder
class IzinRepository extends BaseRepository {
  Future<Result<IzinResponse>> submitRequest(IzinRequest request) async {
    try {
      final response = await dio.post('/IzinIstek', data: request.toJson());
      return handleResponse(response, IzinResponse.fromJson); // Base method
    } on DioException catch (e) {
      return handleError(e); // Base method
    }
  }
}
```

---

**2. `talep_repository.dart` - Process List Repository**

**Neden gerekli?**
- ✅ **Single Responsibility:** Sadece süreç listesi API'si ile ilgilenir
- ✅ **Testable:** Mock edilebilir interface
- ✅ **Separation of Concerns:** Network logic UI'dan ayrı

```dart
class TalepRepository extends BaseRepository {
  final Dio dio;
  
  // Süreç listesini getir
  Future<Result<List<TalepAdi>>> getTalepAdlari() async {
    try {
      final response = await dio.get('/TalepAdlari');
      final List data = response.data as List;
      
      // JSON array'i model listesine çevir
      final processes = data.map((e) => TalepAdi.fromJson(e)).toList();
      
      // Sadece aktif süreçleri filtrele
      final activeProcesses = processes.where((p) => p.aktif).toList();
      
      return Success(activeProcesses);
    } on DioException catch (e) {
      return handleError(e);
    }
  }
}
```

---

#### 📁 `lib/core/providers/`
**Ne yapar?** Riverpod state management providers

**`talep_providers.dart` - Process List State**

**Neden gerekli?**
- ✅ **Global State:** Tüm app'te süreç listesi erişilebilir
- ✅ **Caching:** Bir kez yükle, her yerde kullan
- ✅ **Reactive:** State değişince UI otomatik güncellenir
- ✅ **Async Handling:** Loading/error states otomatik

```dart
// Riverpod 3 - AsyncNotifier pattern
class TalepAdlariNotifier extends AsyncNotifier<List<TalepAdi>> {
  @override
  Future<List<TalepAdi>> build() async {
    // İlk yüklemede API'yi çağır
    final repository = ref.read(talepRepositoryProvider);
    final result = await repository.getTalepAdlari();
    
    return switch (result) {
      Success(data: final processes) => processes,
      Failure(message: final error) => throw Exception(error),
      Loading() => [],
    };
  }
  
  // Manuel refresh
  Future<void> refresh() async {
    state = const AsyncLoading(); // Loading state
    state = await AsyncValue.guard(() => build()); // Re-fetch
  }
}

// Provider tanımı
final talepAdlariProvider = AsyncNotifierProvider<TalepAdlariNotifier, List<TalepAdi>>(
  TalepAdlariNotifier.new,
);
```

**UI'da Kullanım:**
```dart
class ProcessesMainScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processesAsync = ref.watch(talepAdlariProvider);
    
    // AsyncValue pattern matching
    return processesAsync.when(
      data: (processes) => GridView.builder(...), // ✅ Data ready
      loading: () => CircularProgressIndicator(), // ⏳ Loading
      error: (error, stack) => ErrorWidget(error), // ❌ Error
    );
  }
}
```

---

#### 📁 `lib/core/routing/`
**Ne yapar?** Dinamik route yönetimi

**`app_routes.dart` - Dynamic Routing**

**Neden gerekli?**
- ✅ **Dynamic:** API'den gelen süreç adlarına göre route oluşturur
- ✅ **Turkish Character Handling:** "İzin İstek" → "izin-istek"
- ✅ **Fallback:** Tanımsız route'lar için placeholder screen

```dart
class AppRoutes {
  // Sabit route'lar - Her süreç için multiple alias
  static final Map<String, Widget Function()> specificRoutes = {
    'izin-istek': () => IzinIstekScreen(),
    'izin': () => IzinIstekScreen(), // Alternatif
    'leave-request': () => IzinIstekScreen(), // English
    
    'arac-istek': () => AracIstekScreen(),
    // ... diğer süreçler
  };
  
  // Dinamik route resolver
  static Widget? getRouteWidget(String? routeName) {
    if (routeName == null) return null;
    
    // Normalize: küçük harf, Türkçe karakter düzeltme
    final normalized = routeName.toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
    
    // Önce sabit route'lara bak
    if (specificRoutes.containsKey(normalized)) {
      return specificRoutes[normalized]!();
    }
    
    // Bulunamazsa placeholder göster
    return DynamicPlaceholderScreen(routeName: routeName);
  }
}
```

**Navigator'da Kullanım:**
```dart
MaterialApp(
  onGenerateRoute: (settings) {
    final widget = AppRoutes.getRouteWidget(settings.name);
    return MaterialPageRoute(builder: (_) => widget ?? NotFoundScreen());
  },
);
```

---

## 🎨 Feature Katmanı

### Feature-Based Organization Nedir?

**Klasik Yaklaşım (Katmana göre):**
```
lib/
  models/
    izin_request.dart
    arac_request.dart
    bi_request.dart
  repositories/
    izin_repository.dart
    arac_repository.dart
  screens/
    izin_screen.dart
    arac_screen.dart
```

**Problem:**
- ❌ Bir feature için 4 farklı klasöre girmek gerekir
- ❌ Dosya sayısı arttıkça karmaşıklaşır
- ❌ Feature silmek/eklemek zor

**Feature-Based Yaklaşım:**
```
lib/
  features/
    izin_istek/
      models/
      repositories/
      providers/
      screens/
    arac_istek/
      models/
      repositories/
      providers/
      screens/
```

**Avantajları:**
- ✅ Her feature bağımsız modül
- ✅ Feature silmek = klasörü sil
- ✅ Parallel development: Birden fazla developer aynı anda farklı feature'larda çalışabilir
- ✅ Code organization: İlgili her şey bir yerde

---

### 📁 Feature İçi Yapı (Örnek: `izin_istek/`)

#### 1️⃣ **models/** - Veri Modelleri

```dart
// izin_request.dart
class IzinRequest {
  final String izinTuru;        // Yıllık, mazeret, vs.
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final String aciklama;
  
  // JSON'a çevir (API'ye gönderirken)
  Map<String, dynamic> toJson() => {
    'izinTuru': izinTuru,
    'baslangicTarihi': baslangicTarihi.toIso8601String(),
    'bitisTarihi': bitisTarihi.toIso8601String(),
    'aciklama': aciklama,
  };
}

class IzinResponse {
  final int id;
  final String durum; // Onaylandı, reddedildi
  final String mesaj;
  
  // JSON'dan obje oluştur (API'den gelirken)
  factory IzinResponse.fromJson(Map<String, dynamic> json) => IzinResponse(
    id: json['id'],
    durum: json['durum'],
    mesaj: json['mesaj'],
  );
}
```

**Neden iki model?**
- `Request`: Client → Server (gönderilen data)
- `Response`: Server → Client (dönen data)
- Farklı field'lar olabilir: Request'te `userId` yok ama Response'ta `id` var

---

#### 2️⃣ **repositories/** - API İşlemleri

```dart
// izin_repository.dart
class IzinRepository extends BaseRepository {
  final Dio dio;
  
  // İzin talebini gönder
  Future<Result<IzinResponse>> submitRequest(IzinRequest request) async {
    try {
      final response = await dio.post(
        '/IzinIstek',
        data: request.toJson(), // Model → JSON
      );
      
      return handleResponse(
        response,
        (data) => IzinResponse.fromJson(data), // JSON → Model
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }
  
  // Kullanıcının izin geçmişini getir
  Future<Result<List<IzinResponse>>> getMyRequests() async {
    try {
      final response = await dio.get('/IzinIstek/Benimkiler');
      final List data = response.data;
      
      final requests = data.map((e) => IzinResponse.fromJson(e)).toList();
      return Success(requests);
    } on DioException catch (e) {
      return handleError(e);
    }
  }
}
```

**Sorumluluklar:**
- ✅ API endpoint çağrıları
- ✅ JSON ↔ Model dönüşümü
- ✅ Error handling
- ❌ UI logic (burada olmamalı)
- ❌ State management (provider'da olacak)

---

#### 3️⃣ **providers/** - State Management

```dart
// izin_providers.dart

// Form state class
class IzinFormState {
  final String izinTuru;
  final DateTime? baslangicTarihi;
  final DateTime? bitisTarihi;
  final String aciklama;
  final bool isSubmitting;
  final String? errorMessage;
  
  // Copyenumerata - Immutable state updates
  IzinFormState copyWith({...}) => IzinFormState(...);
}

// Riverpod Notifier (Synchronous state)
class IzinFormNotifier extends Notifier<IzinFormState> {
  @override
  IzinFormState build() => IzinFormState.initial();
  
  // İzin türünü değiştir
  void updateIzinTuru(String yeniTur) {
    state = state.copyWith(izinTuru: yeniTur);
  }
  
  // Tarihleri değiştir
  void updateDates(DateTime baslangic, DateTime bitis) {
    state = state.copyWith(
      baslangicTarihi: baslangic,
      bitisTarihi: bitis,
    );
  }
  
  // Formu gönder
  Future<void> submitForm() async {
    // Validation
    if (!_validateForm()) {
      state = state.copyWith(errorMessage: 'Lütfen tüm alanları doldurun');
      return;
    }
    
    // Set loading
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    
    // Create request
    final request = IzinRequest(
      izinTuru: state.izinTuru,
      baslangicTarihi: state.baslangicTarihi!,
      bitisTarihi: state.bitisTarihi!,
      aciklama: state.aciklama,
    );
    
    // Call repository
    final repository = ref.read(izinRepositoryProvider);
    final result = await repository.submitRequest(request);
    
    // Handle result
    switch (result) {
      case Success(data: final response):
        state = state.copyWith(isSubmitting: false);
        // Show success message
      case Failure(message: final error):
        state = state.copyWith(isSubmitting: false, errorMessage: error);
    }
  }
}

// Provider tanımları
final izinFormProvider = NotifierProvider<IzinFormNotifier, IzinFormState>(
  IzinFormNotifier.new,
);
```

**Neden Notifier kullanıyoruz?**
- ✅ **Immutable State:** State değişmez, yeni instance oluşturulur
- ✅ **Predictable:** State değişimi her zaman `copyWith` ile
- ✅ **Testable:** Mock edilebilir, unit test kolay
- ✅ **Reactive:** State değişince UI otomatik render

---

#### 4️⃣ **screens/** - UI Katmanı

```dart
// izin_istek_screen.dart
class IzinIstekScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // State'i izle (watch)
    final formState = ref.watch(izinFormProvider);
    final formNotifier = ref.read(izinFormProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(title: Text('İzin İstek')),
      body: Form(
        child: Column(
          children: [
            // İzin türü dropdown
            DropdownButton<String>(
              value: formState.izinTuru,
              items: ['Yıllık', 'Mazeret', 'Ücretsiz'].map((tur) =>
                DropdownMenuItem(value: tur, child: Text(tur))
              ).toList(),
              onChanged: (newValue) {
                formNotifier.updateIzinTuru(newValue!);
              },
            ),
            
            // Başlangıç tarihi picker
            DatePickerField(
              value: formState.baslangicTarihi,
              onChanged: (date) {
                if (formState.bitisTarihi != null) {
                  formNotifier.updateDates(date, formState.bitisTarihi!);
                }
              },
            ),
            
            // Açıklama text field
            TextField(
              onChanged: formNotifier.updateAciklama,
              decoration: InputDecoration(
                labelText: 'Açıklama',
                errorText: formState.errorMessage,
              ),
            ),
            
            // Submit button
            ElevatedButton(
              onPressed: formState.isSubmitting ? null : () {
                formNotifier.submitForm();
              },
              child: formState.isSubmitting
                ? CircularProgressIndicator()
                : Text('Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**UI Sorumlulukları:**
- ✅ Widget rendering
- ✅ User interaction handling
- ✅ Loading/error state gösterimi
- ❌ Business logic (provider'da)
- ❌ API calls (repository'de)

---

## 🔄 State Management (Riverpod 3)

### Neden Riverpod?

**Alternatifler:**
1. **setState:** ❌ Sadece local state, global state yok, rebuild kontrolsüz
2. **Provider (original):** ❌ Eski, InheritedWidget wrapper, verbose
3. **Bloc:** ❌ Çok boilerplate, karmaşık event/state sistemi
4. **GetX:** ❌ Magic strings, global state kontrolsüz
5. **Riverpod:** ✅ Compile-time safe, no context, testable, minimal boilerplate

### Riverpod 3 Özellikleri

**1. Provider Types:**

```dart
// Static değer
final apiUrlProvider = Provider<String>((ref) {
  return 'https://api.example.com';
});

// Async değer (Future)
final userProvider = FutureProvider<User>((ref) async {
  final api = ref.read(apiProvider);
  return await api.fetchUser();
});

// Stream
final chatMessagesProvider = StreamProvider<List<Message>>((ref) {
  return chatRepository.messagesStream();
});

// Mutable state (Notifier)
final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);

// Async mutable state (AsyncNotifier)
final processesProvider = AsyncNotifierProvider<ProcessesNotifier, List<Process>>(
  ProcessesNotifier.new,
);
```

**2. ref - Dependency Injection:**

```dart
class MyNotifier extends Notifier<int> {
  @override
  int build() {
    // Diğer provider'ları oku
    final dio = ref.read(dioProvider);
    final repository = ref.read(repositoryProvider);
    
    // Provider'ı dinle (watch)
    final user = ref.watch(userProvider);
    
    return 0;
  }
}
```

**3. ConsumerWidget - UI Integration:**

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider'ı izle - değişince rebuild
    final count = ref.watch(counterProvider);
    
    // Provider'ı oku - rebuild yok
    final notifier = ref.read(counterProvider.notifier);
    
    return Text('Count: $count');
  }
}
```

---

## 📊 Veri Akışı (Data Flow)

### Örnek: İzin Talebini Gönderme

```
USER ACTION (Button Click)
  ↓
┌──────────────────────────────────────┐
│ UI Layer (izin_istek_screen.dart)   │
│ formNotifier.submitForm()            │
└──────────────┬───────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ State Layer (izin_providers.dart)   │
│ IzinFormNotifier.submitForm()       │
│ - Validation                         │
│ - Set loading state                  │
│ - Create request model               │
└──────────────┬───────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ Repository (izin_repository.dart)   │
│ submitRequest(request)               │
│ - Convert model to JSON              │
│ - Make API call                      │
│ - Handle response                    │
└──────────────┬───────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ Network (dio_provider.dart)          │
│ POST /IzinIstek                      │
│ - Add auth token                     │
│ - Log request                        │
│ - Send to server                     │
└──────────────┬───────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ API SERVER                           │
│ https://esasapi.eyuboglu.k12.tr     │
└──────────────┬───────────────────────┘
               ↓ Response
┌──────────────────────────────────────┐
│ Repository                           │
│ - Parse JSON to IzinResponse         │
│ - Return Result<IzinResponse>        │
└──────────────┬───────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ State Layer                          │
│ - Update state (success/error)       │
│ - Notify listeners                   │
└──────────────┬───────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ UI Layer                             │
│ - Rebuild widget                     │
│ - Show success/error message         │
│ - Navigate back                      │
└──────────────────────────────────────┘
```

---

## 🎯 Neden Bu Mimari?

### ✅ Avantajlar

**1. Separation of Concerns (SoC)**
- Her katman kendi işini yapar
- UI, business logic, data layer ayrı
- Değişiklik yapmak kolay

**2. Testability**
- Her katman ayrı test edilebilir
- Mock dependency injection kolay
- Unit test, integration test, widget test

**3. Scalability**
- Yeni feature eklemek = yeni klasör
- Feature silmek = klasörü sil
- Parallel development mümkün

**4. Maintainability**
- Kod okunabilir ve organize
- Standart yapı - her developer aynı şeyi bekler
- Bug fix yapmak kolay

**5. Reusability**
- Core katmanı tüm feature'lar kullanır
- BaseRepository - DRY principle
- Provider'lar compose edilebilir

### ⚠️ Tradeoffs (Ödünler)

**1. Learning Curve**
- Riverpod öğrenmek gerekir
- Katmanlı mimari anlaşılmalı
- İlk başta karmaşık görünebilir

**2. Boilerplate**
- Basit feature için bile çok dosya
- Model, repository, provider, screen
- Küçük projeler için over-engineering

**3. Initial Setup**
- İlk kurulum zaman alır
- Folder structure oluşturma
- Dependencies kurulumu

### 📊 Bu Proje İçin Neden Uygun?

✅ **9 farklı süreç** - Feature-based ideal
✅ **Büyüme potansiyeli** - İleride daha fazla süreç eklenebilir
✅ **Team collaboration** - Multiple developers
✅ **Enterprise app** - Kalite ve maintainability önemli
✅ **API integration** - Repository pattern gerekli
✅ **Complex state** - Riverpod gerekli

---

## 📚 Best Practices

### 1. Naming Conventions

```dart
// Files: snake_case
izin_istek_screen.dart
talep_repository.dart

// Classes: PascalCase
class IzinIstekScreen
class TalepRepository

// Variables: camelCase
final talepAdlari = [];
final izinTuru = 'Yıllık';

// Constants: camelCase with const
const apiTimeout = Duration(seconds: 30);

// Providers: Descriptive + Provider suffix
final talepAdlariProvider = ...
final izinFormProvider = ...
```

### 2. Folder Organization

```
feature/
  models/           # Data models (request, response, entities)
  repositories/     # API calls and data operations
  providers/        # State management
  screens/          # UI components
  widgets/          # Reusable widgets (optional)
```

### 3. Error Handling

```dart
// Always use Result pattern
Future<Result<T>> apiCall() async {
  try {
    // ... API call
    return Success(data);
  } on DioException catch (e) {
    return handleError(e);
  } catch (e) {
    return Failure('Unexpected error: $e');
  }
}

// Never throw unhandled exceptions in repositories
```

### 4. State Management

```dart
// Use AsyncNotifier for async operations
class DataNotifier extends AsyncNotifier<Data> {
  @override
  Future<Data> build() async {
    return await fetchData();
  }
}

// Use Notifier for synchronous state
class FormNotifier extends Notifier<FormState> {
  @override
  FormState build() => FormState.initial();
}
```

### 5. Testing Strategy

```dart
// Unit tests: Repositories, Providers
test('getTalepAdlari returns success', () async {
  final repository = TalepRepository(mockDio);
  final result = await repository.getTalepAdlari();
  expect(result, isA<Success>());
});

// Widget tests: Screens
testWidgets('IzinIstekScreen shows form', (tester) async {
  await tester.pumpWidget(ProviderScope(child: IzinIstekScreen()));
  expect(find.text('İzin Türü'), findsOneWidget);
});

// Integration tests: End-to-end flows
testWidgets('Submit izin request flow', (tester) async {
  // Fill form → Submit → Verify success
});
```

---

## 🎓 Öğrenme Kaynakları

1. **Riverpod Docs:** https://riverpod.dev
2. **Clean Architecture:** Robert C. Martin
3. **Feature-Sliced Design:** https://feature-sliced.design
4. **Flutter Best Practices:** https://flutter.dev/docs/development/best-practices

---

## 🚀 Sonraki Adımlar

1. ✅ **Mimari anlaşıldı** - Bu döküman
2. ⏳ **İzin İstek implementasyonu** - Örnek feature
3. ⏳ **Diğer 8 feature** - Aynı pattern'i takip et
4. ⏳ **Testing** - Unit, widget, integration tests
5. ⏳ **CI/CD** - Automated testing and deployment
6. ⏳ **Monitoring** - Error tracking, analytics

---

**Hazırlayan:** GitHub Copilot  
**Tarih:** 14 Ekim 2025  
**Proje:** ESAS V1 - İşyeri Süreç Yönetimi
