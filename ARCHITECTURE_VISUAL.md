# 🎨 ESAS V1 - Görsel Mimari Diyagramları

## 1️⃣ Genel Mimari - Big Picture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MAIN.DART                                │
│  • ProviderScope (Riverpod container)                           │
│  • MaterialApp (Navigator, Theme)                               │
│  • Initial route: ProcessesMainScreen                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                  PROCESSES MAIN SCREEN                          │
│                                                                 │
│  [🚗 Araç]  [💻 BT]  [📄 Dok]                                  │
│  [🎓 Eğit]  [🏖️ İzin] [📦 Sarf]                                │
│  [🛒 Satın] [🔧 Teknik] [🍽️ Yiyecek]                          │
│                                                                 │
│  ↑ API'den dinamik yüklenir                                    │
│  ↑ talepAdlariProvider (Riverpod)                              │
└────────────────────────────┬────────────────────────────────────┘
                             │ User clicks "İzin İstek"
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                    FEATURE SCREEN                               │
│               (izin_istek_screen.dart)                          │
│                                                                 │
│  ┌─────────────────────────────────────────┐                   │
│  │  İzin Türü: [Yıllık ▼]                 │                   │
│  │  Başlangıç: [📅 12.10.2025]            │                   │
│  │  Bitiş:     [📅 15.10.2025]            │                   │
│  │  Açıklama:  [____________]             │                   │
│  │            [GÖNDER]                     │                   │
│  └─────────────────────────────────────────┘                   │
│                                                                 │
│  ↑ izinFormProvider (Riverpod state)                           │
└────────────────────────────┬────────────────────────────────────┘
                             │ User clicks "Gönder"
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                    STATE LAYER                                  │
│              (izin_providers.dart)                              │
│                                                                 │
│  IzinFormNotifier.submitForm()                                 │
│  ├─ 1. Validate form                                           │
│  ├─ 2. Set loading state                                       │
│  ├─ 3. Create IzinRequest model                                │
│  └─ 4. Call repository                                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                  REPOSITORY LAYER                               │
│             (izin_repository.dart)                              │
│                                                                 │
│  submitRequest(IzinRequest) {                                  │
│    ├─ Convert model to JSON                                    │
│    ├─ dio.post('/IzinIstek', data)                             │
│    ├─ Handle response                                          │
│    └─ Return Result<IzinResponse>                              │
│  }                                                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                    NETWORK LAYER                                │
│               (dio_provider.dart)                               │
│                                                                 │
│  Dio Client                                                    │
│  ├─ Base URL: https://esasapi.eyuboglu.k12.tr                 │
│  ├─ Timeout: 30s                                               │
│  ├─ Interceptors (Auth, Logging)                              │
│  └─ POST /api/TalepYonetimi/IzinIstek                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                      API SERVER                                 │
│         https://esasapi.eyuboglu.k12.tr                        │
│                                                                 │
│  Response: { id: 123, durum: "Onaylandı" }                    │
└────────────────────────────┬────────────────────────────────────┘
                             │ Response comes back
                             ↓
                    ┌────────────────┐
                    │  UI Updates!   │
                    │  ✅ Success    │
                    └────────────────┘
```

---

## 2️⃣ Klasör Yapısı - Directory Tree

```
esas_v1/
│
├── 📱 lib/
│   │
│   ├── 🏛️ core/                              ← PAYLAŞILAN ALTYAPI
│   │   │
│   │   ├── 🌐 network/
│   │   │   └── dio_provider.dart             ← HTTP client (Dio)
│   │   │       • Base URL konfigürasyonu
│   │   │       • Timeout ayarları
│   │   │       • Auth interceptor (token ekleme)
│   │   │       • Logging interceptor
│   │   │
│   │   ├── 📦 models/
│   │   │   ├── result.dart                   ← Success/Failure/Loading wrapper
│   │   │   │   • Tip güvenli hata yönetimi
│   │   │   │   • Pattern matching
│   │   │   │
│   │   │   └── talep_adi.dart               ← Süreç listesi modeli
│   │   │       • JSON parsing
│   │   │       • Icon mapping
│   │   │       • Route generation
│   │   │
│   │   ├── 🗄️ repositories/
│   │   │   ├── base_repository.dart          ← Ortak repository logic
│   │   │   │   • handleResponse<T>()
│   │   │   │   • handleError<T>()
│   │   │   │
│   │   │   └── talep_repository.dart        ← Süreç listesi API
│   │   │       • getTalepAdlari()
│   │   │       • Aktif süreç filtresi
│   │   │
│   │   ├── 🔌 providers/
│   │   │   └── talep_providers.dart          ← Global state (süreç listesi)
│   │   │       • TalepAdlariNotifier
│   │   │       • AsyncNotifierProvider
│   │   │       • refresh() method
│   │   │
│   │   └── 🗺️ routing/
│   │       └── app_routes.dart               ← Dinamik routing
│   │           • Route name → Screen mapping
│   │           • Türkçe karakter normalizasyon
│   │           • Fallback placeholder screen
│   │
│   ├── 🎨 features/                           ← ÖZELLIKLER (9 adet)
│   │   │
│   │   ├── 🚗 arac_istek/                    ← ARAÇ İSTEK
│   │   │   ├── models/
│   │   │   │   └── arac_request.dart
│   │   │   ├── repositories/
│   │   │   │   └── arac_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── arac_providers.dart
│   │   │   └── screens/
│   │   │       └── arac_istek_screen.dart
│   │   │
│   │   ├── 💻 bilgi_teknolojileri/           ← BİLGİ TEKNOLOJİLERİ
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── screens/
│   │   │
│   │   ├── 📄 dokumantasyon_istek/           ← DOKÜMANTASYON
│   │   │   └── screens/
│   │   │
│   │   ├── 🎓 egitim_istek/                  ← EĞİTİM İSTEK
│   │   │   └── screens/
│   │   │
│   │   ├── 🏖️ izin_istek/                    ← İZİN İSTEK ✅ TAMAMLANDI
│   │   │   ├── models/
│   │   │   │   └── izin_request.dart         ← Request & Response models
│   │   │   ├── repositories/
│   │   │   │   └── izin_repository.dart      ← API çağrıları
│   │   │   ├── providers/
│   │   │   │   └── izin_providers.dart       ← Form state management
│   │   │   └── screens/
│   │   │       └── izin_istek_screen.dart    ← Full UI form
│   │   │
│   │   ├── 📦 sarf_malzeme_istek/            ← SARF MALZEME
│   │   │   └── screens/
│   │   │
│   │   ├── 🛒 satin_alma/                    ← SATIN ALMA
│   │   │   └── screens/
│   │   │
│   │   ├── 🔧 teknik_destek/                 ← TEKNİK DESTEK
│   │   │   └── screens/
│   │   │
│   │   └── 🍽️ yiyecek_icecek_istek/          ← YİYECEK İÇECEK
│   │       └── screens/
│   │
│   ├── 📺 screens/                            ← GENEL EKRANLAR
│   │   ├── processes_main_screen.dart        ← Ana süreç seçim ekranı
│   │   └── api_test_screen.dart              ← API test ekranı
│   │
│   └── 🚀 main.dart                           ← APP GİRİŞ NOKTASI
│       • ProviderScope wrapper
│       • MaterialApp
│       • onGenerateRoute
│
├── 📄 pubspec.yaml                            ← DEPENDENCIES
│   • flutter_riverpod: ^3.0.3
│   • dio: ^5.4.0
│   • json_annotation: ^4.8.1
│
├── 📚 ARCHITECTURE.md                         ← Mimari özet döküman
├── 📖 ARCHITECTURE_DETAILED.md                ← Bu detaylı açıklama
└── 🎨 ARCHITECTURE_VISUAL.md                  ← Görsel diyagramlar
```

---

## 3️⃣ Veri Akışı - Data Flow (Adım Adım)

### 📥 API'den Veri Çekme (GET)

```
STEP 1: App Başlatılır
┌──────────────────┐
│   main.dart      │
│  ProviderScope   │  ← Riverpod container oluştur
└────────┬─────────┘
         │
         ↓
STEP 2: Ana Ekran Yüklenir
┌──────────────────┐
│ processes_main   │
│    _screen       │  ← ref.watch(talepAdlariProvider)
└────────┬─────────┘
         │
         ↓
STEP 3: Provider Tetiklenir
┌──────────────────┐
│ TalepAdlari      │
│   Notifier       │  ← build() method çağrılır
│  .build()        │
└────────┬─────────┘
         │
         ↓
STEP 4: Repository Çağrılır
┌──────────────────┐
│ TalepRepository  │
│ .getTalepAdlari()│  ← API call
└────────┬─────────┘
         │
         ↓
STEP 5: HTTP İsteği
┌──────────────────┐
│  Dio Client      │
│  GET /TalepAd    │  ← https://esasapi.eyuboglu.k12.tr
│       lari       │
└────────┬─────────┘
         │
         ↓
STEP 6: Response Gelir
┌──────────────────┐
│  JSON Array      │
│ [{id:1, talep    │  ← [{"id":1,"talepAdi":"Araç İstek"}, ...]
│  Adi:"..."}]     │
└────────┬─────────┘
         │
         ↓
STEP 7: JSON → Model
┌──────────────────┐
│  TalepAdi        │
│ .fromJson()      │  ← List<TalepAdi> oluştur
└────────┬─────────┘
         │
         ↓
STEP 8: Result Wrapper
┌──────────────────┐
│ Result<List>     │
│ Success(data)    │  ← Type-safe wrapper
└────────┬─────────┘
         │
         ↓
STEP 9: State Güncellenir
┌──────────────────┐
│ AsyncValue       │
│   .data()        │  ← Notifier state = data
└────────┬─────────┘
         │
         ↓
STEP 10: UI Rebuild
┌──────────────────┐
│  GridView        │
│  9 Process       │  ← Screen otomatik yeniden render
│  Cards           │
└──────────────────┘
```

---

### 📤 Veri Gönderme (POST)

```
STEP 1: User Form Doldurur
┌──────────────────┐
│ İzin Türü: Yıllık│
│ Tarih: 12.10     │  ← TextField, DatePicker, etc.
│ [GÖNDER]         │
└────────┬─────────┘
         │ onPressed
         ↓
STEP 2: Validation
┌──────────────────┐
│ FormNotifier     │
│ .submitForm()    │  ← Tarih boş mu? İzin türü seçildi mi?
│ _validateForm()  │
└────────┬─────────┘
         │ ✅ Valid
         ↓
STEP 3: Loading State
┌──────────────────┐
│ state =          │
│ state.copyWith   │  ← isSubmitting: true
│ (isSubmitting:   │    UI'da CircularProgressIndicator göster
│  true)           │
└────────┬─────────┘
         │
         ↓
STEP 4: Model Oluştur
┌──────────────────┐
│ IzinRequest(     │
│  izinTuru:       │  ← Form state → Request model
│  "Yıllık",       │
│  baslangic: ...  │
│ )                │
└────────┬─────────┘
         │
         ↓
STEP 5: JSON'a Çevir
┌──────────────────┐
│ request          │
│ .toJson()        │  ← Map<String, dynamic>
│                  │    {"izinTuru": "Yıllık", ...}
└────────┬─────────┘
         │
         ↓
STEP 6: Repository Call
┌──────────────────┐
│ IzinRepository   │
│ .submitRequest   │  ← API çağrısı
│ (request)        │
└────────┬─────────┘
         │
         ↓
STEP 7: HTTP POST
┌──────────────────┐
│ dio.post(        │
│  '/IzinIstek',   │  ← POST https://esasapi.../IzinIstek
│  data: json      │    Body: {"izinTuru": "Yıllık", ...}
│ )                │
└────────┬─────────┘
         │
         ↓
STEP 8: Server İşler
┌──────────────────┐
│   API SERVER     │
│ • DB'ye kaydet   │  ← İzin talebi veritabanına eklenir
│ • Onay mail'i    │    Yöneticiye mail gönderilir
│ • Response oluş  │
└────────┬─────────┘
         │
         ↓
STEP 9: Response Gelir
┌──────────────────┐
│ JSON Response    │
│ {id: 123,        │  ← {"id": 123, "durum": "Beklemede",
│  durum: "Bekleme│     "mesaj": "Talebiniz alındı"}
│  de"}            │
└────────┬─────────┘
         │
         ↓
STEP 10: JSON → Model
┌──────────────────┐
│ IzinResponse     │
│ .fromJson(data)  │  ← IzinResponse object
└────────┬─────────┘
         │
         ↓
STEP 11: Result Wrapper
┌──────────────────┐
│ Success(         │
│  IzinResponse    │  ← Ya Success ya Failure
│ )                │
└────────┬─────────┘
         │
         ↓
STEP 12: State Update (Success)
┌──────────────────┐
│ state =          │
│ state.copyWith(  │  ← isSubmitting: false
│  isSubmitting:   │    errorMessage: null
│  false           │
│ )                │
└────────┬─────────┘
         │
         ↓
STEP 13: UI Feedback
┌──────────────────┐
│ ✅ SnackBar      │
│ "Talebiniz       │  ← Kullanıcıya başarı mesajı
│  alındı!"        │    Navigator.pop() - geri dön
└──────────────────┘
```

---

## 4️⃣ Katman Sorumlulukları

```
┌─────────────────────────────────────────────────────────────┐
│                    UI LAYER (Screens)                       │
├─────────────────────────────────────────────────────────────┤
│ SORUMLULUKLARI:                                             │
│  ✅ Widget rendering (TextField, Button, etc.)             │
│  ✅ User interaction (onPressed, onChanged)                │
│  ✅ Navigation (Navigator.push, pop)                       │
│  ✅ UI state gösterimi (loading, error)                    │
│                                                             │
│ YAPMAMASI GEREKENLER:                                       │
│  ❌ Business logic                                          │
│  ❌ API calls                                               │
│  ❌ Direct Dio usage                                        │
│  ❌ JSON parsing                                            │
│                                                             │
│ ÖRNEK:                                                      │
│  ElevatedButton(                                            │
│    onPressed: () => notifier.submitForm(), // ✅ OK        │
│    child: Text('Gönder')                                   │
│  )                                                          │
└─────────────────────────────────────────────────────────────┘
         │ refs provider
         ↓
┌─────────────────────────────────────────────────────────────┐
│              STATE LAYER (Providers/Notifiers)              │
├─────────────────────────────────────────────────────────────┤
│ SORUMLULUKLARI:                                             │
│  ✅ State management (form data, loading, errors)          │
│  ✅ Business logic (validation, calculations)              │
│  ✅ Orchestration (call repository, update UI)             │
│  ✅ Error handling (convert errors to UI messages)         │
│                                                             │
│ YAPMAMASI GEREKENLER:                                       │
│  ❌ Direct HTTP calls                                       │
│  ❌ UI rendering                                            │
│  ❌ Navigation logic                                        │
│                                                             │
│ ÖRNEK:                                                      │
│  Future<void> submitForm() async {                         │
│    if (!_validate()) return; // ✅ Validation             │
│    state = state.copyWith(loading: true); // ✅ State      │
│    final result = await repo.submit(); // ✅ Call repo     │
│    _handleResult(result); // ✅ Update state               │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
         │ calls repository
         ↓
┌─────────────────────────────────────────────────────────────┐
│            REPOSITORY LAYER (Repositories)                  │
├─────────────────────────────────────────────────────────────┤
│ SORUMLULUKLARI:                                             │
│  ✅ API calls (dio.get, dio.post)                          │
│  ✅ JSON ↔ Model conversion                                │
│  ✅ Error handling (try-catch, Result wrapper)             │
│  ✅ Data caching (optional)                                │
│                                                             │
│ YAPMAMASI GEREKENLER:                                       │
│  ❌ UI updates                                              │
│  ❌ State management                                        │
│  ❌ Business logic (validation, calculations)              │
│  ❌ Navigation                                              │
│                                                             │
│ ÖRNEK:                                                      │
│  Future<Result<T>> getData() async {                       │
│    try {                                                    │
│      final response = await dio.get('/api'); // ✅ HTTP    │
│      final data = Model.fromJson(response); // ✅ Parse    │
│      return Success(data); // ✅ Result wrapper            │
│    } on DioException catch (e) {                           │
│      return handleError(e); // ✅ Error handling           │
│    }                                                        │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
         │ uses Dio client
         ↓
┌─────────────────────────────────────────────────────────────┐
│              NETWORK LAYER (Dio Provider)                   │
├─────────────────────────────────────────────────────────────┤
│ SORUMLULUKLARI:                                             │
│  ✅ HTTP client configuration                              │
│  ✅ Base URL, headers, timeout                             │
│  ✅ Interceptors (auth, logging)                           │
│  ✅ Request/response transformation                        │
│                                                             │
│ YAPMAMASI GEREKENLER:                                       │
│  ❌ Business logic                                          │
│  ❌ Model parsing                                           │
│  ❌ State management                                        │
│                                                             │
│ ÖRNEK:                                                      │
│  final dio = Dio(                                           │
│    BaseOptions(                                             │
│      baseUrl: 'https://api...', // ✅ Config              │
│      timeout: Duration(seconds: 30), // ✅ Config          │
│    )                                                        │
│  );                                                         │
│  dio.interceptors.add(AuthInterceptor()); // ✅ Auth       │
└─────────────────────────────────────────────────────────────┘
```

---

## 5️⃣ Riverpod Provider Tipleri

```
┌─────────────────────────────────────────────────────────────┐
│              PROVIDER (Sabit/Computed Değer)                │
├─────────────────────────────────────────────────────────────┤
│ KULLANIM: Static konfigürasyon, dependency injection       │
│                                                             │
│ final dioProvider = Provider<Dio>((ref) {                  │
│   return Dio(BaseOptions(...));                            │
│ });                                                         │
│                                                             │
│ ÖZELLİKLER:                                                │
│  • Immutable                                                │
│  • Lazy initialization                                     │
│  • Cache edilir                                             │
│  • Override edilebilir (test için)                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│          FUTURE PROVIDER (Async Tek Seferlik)               │
├─────────────────────────────────────────────────────────────┤
│ KULLANIM: Bir kez yüklenip değişmeyen async data           │
│                                                             │
│ final configProvider = FutureProvider<Config>((ref) async {│
│   return await loadConfig();                               │
│ });                                                         │
│                                                             │
│ ÖZELLİKLER:                                                │
│  • AsyncValue<T> döner                                     │
│  • Auto-loading state                                      │
│  • Error handling built-in                                 │
│  • Rebuild etmek için ref.invalidate()                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│        STREAM PROVIDER (Realtime Data Stream)               │
├─────────────────────────────────────────────────────────────┤
│ KULLANIM: WebSocket, Firebase, continuous data             │
│                                                             │
│ final messagesProvider = StreamProvider<Message>((ref) {   │
│   return chatRepository.messagesStream();                  │
│ });                                                         │
│                                                             │
│ ÖZELLİKLER:                                                │
│  • AsyncValue<T> döner                                     │
│  • Otomatik subscription                                   │
│  • Dispose otomatik                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│      NOTIFIER PROVIDER (Mutable Synchronous State)          │
├─────────────────────────────────────────────────────────────┤
│ KULLANIM: Form state, counter, UI state                    │
│                                                             │
│ class CounterNotifier extends Notifier<int> {              │
│   @override                                                 │
│   int build() => 0; // Initial state                       │
│                                                             │
│   void increment() => state++;                             │
│ }                                                           │
│                                                             │
│ final counterProvider =                                     │
│   NotifierProvider<CounterNotifier, int>(                  │
│     CounterNotifier.new                                     │
│   );                                                        │
│                                                             │
│ ÖZELLİKLER:                                                │
│  • Mutable state                                            │
│  • Synchronous                                              │
│  • Methods ekleyebilirsin                                   │
│  • State değişince UI rebuild                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│   ASYNC NOTIFIER PROVIDER (Mutable Async State)            │
├─────────────────────────────────────────────────────────────┤
│ KULLANIM: API data + mutations (CRUD operations)           │
│                                                             │
│ class TodosNotifier extends AsyncNotifier<List<Todo>> {    │
│   @override                                                 │
│   Future<List<Todo>> build() async {                       │
│     return await api.getTodos(); // Initial load           │
│   }                                                         │
│                                                             │
│   Future<void> addTodo(Todo todo) async {                  │
│     state = AsyncLoading(); // Set loading                 │
│     await api.createTodo(todo);                            │
│     state = AsyncData(await build()); // Reload            │
│   }                                                         │
│ }                                                           │
│                                                             │
│ final todosProvider =                                       │
│   AsyncNotifierProvider<TodosNotifier, List<Todo>>(        │
│     TodosNotifier.new                                       │
│   );                                                        │
│                                                             │
│ ÖZELLİKLER:                                                │
│  • Async operations (Future)                               │
│  • Auto loading/error states                               │
│  • Mutations (add, update, delete)                         │
│  • AsyncValue<T> state                                     │
└─────────────────────────────────────────────────────────────┘
```

### Hangi Provider'ı Ne Zaman Kullanmalı?

```
┌─────────────────────┬──────────────────────┬─────────────────┐
│     Senaryo         │    Provider Tipi     │     Örnek       │
├─────────────────────┼──────────────────────┼─────────────────┤
│ Dio instance        │ Provider             │ dioProvider     │
│ Repository instance │ Provider             │ repoProvider    │
│ Config yükleme      │ FutureProvider       │ configProvider  │
│ Tek API call        │ FutureProvider       │ userProvider    │
│ WebSocket messages  │ StreamProvider       │ chatProvider    │
│ Counter, toggle     │ NotifierProvider     │ counterProvider │
│ Form state          │ NotifierProvider     │ formProvider    │
│ CRUD operations     │ AsyncNotifier        │ todosProvider   │
│ Infinite scroll     │ AsyncNotifier        │ postsProvider   │
└─────────────────────┴──────────────────────┴─────────────────┘
```

---

## 6️⃣ Result Pattern - Hata Yönetimi

### Neden try-catch yeterli değil?

```dart
// ❌ KÖTÜ YAKLAŞIM: try-catch her yerde
try {
  final response = await dio.get('/api');
  // Success - ama data tipi belirsiz
  return response.data;
} catch (e) {
  // Error - ama hangi tip error? Ne gösterelim?
  print('Error: $e');
  return null; // ❌ Null döndürmek kötü
}

// UI'da:
final data = await fetchData();
if (data == null) {
  // Error mi yoksa empty mi?
  // Hangi error mesajını gösterelim?
}
```

### ✅ Result Pattern ile:

```dart
// Repository
Future<Result<User>> getUser() async {
  try {
    final response = await dio.get('/user');
    return Success(User.fromJson(response.data));
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return Failure('Bağlantı zaman aşımı');
    } else if (e.response?.statusCode == 404) {
      return Failure('Kullanıcı bulunamadı', statusCode: 404);
    }
    return Failure('Beklenmeyen hata: ${e.message}');
  }
}

// UI'da:
final result = await repository.getUser();

switch (result) {
  case Success(data: final user):
    // ✅ Kesinlikle user var, tip güvenli
    print('Name: ${user.name}');
    
  case Failure(message: final error, statusCode: final code):
    // ✅ Kesinlikle error var, mesaj mevcut
    showSnackBar(error);
    if (code == 404) {
      showNotFoundScreen();
    }
    
  case Loading():
    // ✅ Yükleniyor durumu
    showLoader();
}
```

### Pattern Matching Gücü:

```dart
// Method 1: Switch expression (Dart 3.0+)
final message = switch (result) {
  Success(data: final user) => 'Hoş geldin ${user.name}',
  Failure(message: final error) => 'Hata: $error',
  Loading() => 'Yükleniyor...',
};

// Method 2: if-case (Dart 3.0+)
if (result case Success(data: final user)) {
  print(user.name);
} else if (result case Failure(message: final error)) {
  print(error);
}

// Method 3: When helper
result.when(
  success: (user) => showUserProfile(user),
  failure: (error, code) => showErrorDialog(error),
  loading: () => showSpinner(),
);
```

---

## 7️⃣ Dependency Injection (Riverpod ile)

```dart
// ❌ KÖTÜ: Hard-coded dependencies
class IzinRepository {
  final dio = Dio(); // ❌ Test edilemez
  
  Future<Result> submit() async {
    return await dio.post(...);
  }
}

// ✅ İYİ: Dependency injection
class IzinRepository {
  final Dio dio; // ✅ Constructor'dan inject edilir
  
  IzinRepository(this.dio);
  
  Future<Result> submit() async {
    return await dio.post(...);
  }
}

// Riverpod ile provider:
final izinRepositoryProvider = Provider<IzinRepository>((ref) {
  final dio = ref.read(dioProvider); // Dependency al
  return IzinRepository(dio); // Inject et
});

// Notifier'da kullan:
class IzinFormNotifier extends Notifier<IzinFormState> {
  @override
  IzinFormState build() {
    // Repository'yi al (dependency injection)
    repository = ref.read(izinRepositoryProvider);
    return IzinFormState.initial();
  }
  
  late final IzinRepository repository;
}
```

### Test'te Override:

```dart
// Unit test
test('submitForm success', () async {
  final container = ProviderContainer(
    overrides: [
      // Mock repository inject et
      izinRepositoryProvider.overrideWithValue(MockIzinRepository()),
    ],
  );
  
  final notifier = container.read(izinFormProvider.notifier);
  await notifier.submitForm();
  
  expect(notifier.state.isSubmitting, false);
});
```

---

## 8️⃣ İleri Seviye: Computed Providers

```dart
// Süreçleri kategorilere ayır
final categoryProvider = Provider<String>((ref) => 'Tümü');

final filteredProcessesProvider = Provider<List<TalepAdi>>((ref) {
  // Tüm süreçleri al
  final allProcesses = ref.watch(talepAdlariProvider);
  
  // Seçili kategoriyi al
  final category = ref.watch(categoryProvider);
  
  // Filtrele
  return allProcesses.when(
    data: (processes) {
      if (category == 'Tümü') return processes;
      return processes.where((p) => p.category == category).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// UI'da:
// Kategori değişince otomatik filtreler
final processes = ref.watch(filteredProcessesProvider);
```

---

**Umarım bu görsel açıklamalar mimariyi anlamanıza yardımcı olur! 🚀**
