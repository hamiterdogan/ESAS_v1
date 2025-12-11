# İZİN İSTEK MODÜLÜ - GERÇEK API İMPLEMENTASYONU

## 📋 Genel Bakış
Bu dokümantasyon, İzin İstek modülünün gerçek API endpoint'leriyle yapılan implement edilmiş halini açıklar.

## 🎯 API Endpoint'leri
**Base URL:** `https://esasapi.eyuboglu.k12.tr/api/TalepYonetimi/`

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| POST | `/api/IzinIstek/IzinIstekDetay` | İzin istek detayını getirir |
| POST | `/api/IzinIstek/IzinIstekEkle` | Yeni izin isteği oluşturur |
| GET | `/api/IzinIstek/IzinSebebiDoldur` | İzin sebepleri listesini getirir (dropdown) |
| POST | `/api/IzinIstek/DiniGunDoldur` | Dini günler listesini getirir (dropdown) |
| POST | `/api/IzinIstek/IzinIstekSil` | İzin isteğini siler |

---

## 📁 Dosya Yapısı

```
lib/features/izin_istek/
├── models/izin_istek_models.dart         ✅ Tamamlandı
├── repositories/izin_istek_repository.dart  ✅ Tamamlandı
├── providers/izin_istek_providers.dart     ✅ Tamamlandı
└── screens/izin_istek_screen.dart        ✅ Tamamlandı
```

---

## 🔧 1. Model Katmanı (`izin_istek_models.dart`)

### Model Sınıfları:

#### **IzinSebebi** (İzin Sebepleri Dropdown)
```dart
class IzinSebebi {
  final int izinSebebiId;
  final String izinNedeni;
  final int izinKacGunSonraBaslayacak;
  final bool saatGoster; // Saat alanlarının gösterilip gösterilmeyeceğini belirler
}
```

#### **DiniGun** (Dini Günler Dropdown)
```dart
class DiniGun {
  final String izinGunu;
}
```

#### **IzinIstekEkleRequest** (24 Alan)
```dart
class IzinIstekEkleRequest {
  // Zorunlu Alanlar
  final int izinSebebiId;
  final bool doktorRaporu;
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final int? baslangicSaati;
  final int? baslangicDakika;
  final int? bitisSaati;
  final int? bitisDakika;
  final String adres;
  final String telefon;
  final String aciklama;
  final String adSoyad;
  
  // Opsiyonel Alanlar (İzin Sebebine Göre)
  final DateTime? evlilikTarihi;  // Evlenme izni için
  final DateTime? dogumTarihi;    // Doğum izni için
  final String? secilenDiniGun;   // Dini izin için
  final String? esAdi;            // Evlenme izni için
  final String? hastalik;         // Hastalık izni için
  final int? hesaplananGun;       // Otomatik hesaplanır
  final int? hesaplananSaat;      // Otomatik hesaplanır
  final int? dersSaati;
  final String? dosyaYolu;
  final String? dosyaAciklama;
}
```

#### **IzinIstekDetay** (34 Alan)
Detaylı izin bilgilerini içeren response modeli.

#### **IzinIstekSilResponse**
```dart
class IzinIstekSilResponse {
  final bool basarili;
}
```

---

## 🗄️ 2. Repository Katmanı (`izin_istek_repository.dart`)

### Interface:
```dart
abstract class IzinIstekRepository {
  Future<Result<List<IzinSebebi>>> getIzinSebepleri();
  Future<Result<List<DiniGun>>> getDiniGunler(int personelId);
  Future<Result<void>> izinIstekEkle(IzinIstekEkleRequest request);
  Future<Result<IzinIstekDetay>> getIzinDetay(int id);
  Future<Result<IzinIstekSilResponse>> izinIstekSil(int id);
}
```

### Implementasyon:
```dart
class IzinIstekRepositoryImpl extends BaseRepository implements IzinIstekRepository {
  @override
  Future<Result<List<IzinSebebi>>> getIzinSebepleri() async {
    // GET /IzinIstek/IzinSebebiDoldur
  }

  @override
  Future<Result<List<DiniGun>>> getDiniGunler(int personelId) async {
    // POST /IzinIstek/DiniGunDoldur
    // Body: { "personelId": 133 }
  }

  @override
  Future<Result<void>> izinIstekEkle(IzinIstekEkleRequest request) async {
    // POST /IzinIstek/IzinIstekEkle
    // Body: request.toJson()
  }

  @override
  Future<Result<IzinIstekDetay>> getIzinDetay(int id) async {
    // POST /IzinIstek/IzinIstekDetay
  }

  @override
  Future<Result<IzinIstekSilResponse>> izinIstekSil(int id) async {
    // POST /IzinIstek/IzinIstekSil
  }
}
```

---

## 🎯 3. Provider Katmanı (`izin_istek_providers.dart`)

### Providers:

#### **izinIstekRepositoryProvider**
Repository dependency injection.

#### **izinSebepleriProvider** (FutureProvider)
İzin sebepleri listesini asenkron olarak yükler.

#### **diniGunlerProvider** (FutureProvider.family)
Personel ID'ye göre dini günleri yükler.
```dart
final diniGunlerProvider = FutureProvider.family<List<DiniGun>, int>((ref, personelId) async {
  // personelId parametresi ile API çağrısı
});
```

#### **izinIstekFormProvider** (NotifierProvider)
Form state yönetimi.

### Form State (IzinIstekFormState):
```dart
class IzinIstekFormState {
  final IzinSebebi? secilenIzinSebebi;
  final bool doktorRaporu;
  final DateTime? baslangicTarihi;
  final int baslangicSaat;
  final int baslangicDakika;
  final DateTime? bitisTarihi;
  final int bitisSaat;
  final int bitisDakika;
  final DateTime? evlilikTarihi;
  final DateTime? dogumTarihi;
  final String? secilenDiniGun;
  final String esAdi;
  final String hastalik;
  final int hesaplananGun;
  final int hesaplananSaat;
  final String adres;
  final String telefon;
  final String aciklama;
  final String adSoyad;
  final int dersSaati;
  final String dosyaYolu;
  final String dosyaAciklama;
  final bool isLoading;
  final String? errorMessage;
  
  // Getter
  bool get saatGoster => secilenIzinSebebi?.saatGoster ?? false;
  
  // Dynamic Validation
  bool get isValid {
    // Base validation
    if (adSoyad.isEmpty || secilenIzinSebebi == null || 
        baslangicTarihi == null || bitisTarihi == null ||
        adres.isEmpty || telefon.isEmpty || aciklama.isEmpty) {
      return false;
    }
    
    // Conditional validation based on leave type
    if (secilenIzinSebebi?.izinNedeni == 'Evlenme') {
      if (esAdi.isEmpty || evlilikTarihi == null) return false;
    }
    if (secilenIzinSebebi?.izinNedeni == 'Doğum') {
      if (dogumTarihi == null) return false;
    }
    if (secilenIzinSebebi?.izinNedeni == 'Dini İzin') {
      if (secilenDiniGun == null || secilenDiniGun!.isEmpty) return false;
    }
    
    return true;
  }
}
```

### Form Notifier (IzinIstekFormNotifier):

**Update Metodları (15+):**
- `updateAdSoyad(String)`
- `updateIzinSebebi(IzinSebebi)` - İzin sebebi değişince saatGoster flag'ına göre UI güncellenir
- `updateDoktorRaporu(bool)`
- `updateBaslangicTarihi(DateTime)` - Değiştiğinde `_hesaplaIzinSuresi()` çağrılır
- `updateBaslangicSaat(int)` - Değiştiğinde `_hesaplaIzinSuresi()` çağrılır
- `updateBaslangicDakika(int)` - Değiştiğinde `_hesaplaIzinSuresi()` çağrılır
- `updateBitisTarihi(DateTime)` - Değiştiğinde `_hesaplaIzinSuresi()` çağrılır
- `updateBitisSaat(int)` - Değiştiğinde `_hesaplaIzinSuresi()` çağrılır
- `updateBitisDakika(int)` - Değiştiğinde `_hesaplaIzinSuresi()` çağrılır
- `updateEvlilikTarihi(DateTime)`
- `updateDogumTarihi(DateTime)`
- `updateDiniGun(String)`
- `updateEsAdi(String)`
- `updateHastalik(String)`
- `updateDersSaati(int)`
- `updateAdres(String)`
- `updateTelefon(String)`
- `updateAciklama(String)`

**Önemli Metodlar:**

1. **`_hesaplaIzinSuresi()`** - Otomatik Süre Hesaplama
```dart
void _hesaplaIzinSuresi() {
  if (state.baslangicTarihi == null || state.bitisTarihi == null) return;

  if (state.saatGoster) {
    // Saat bazlı hesaplama
    final baslangic = DateTime(
      state.baslangicTarihi!.year,
      state.baslangicTarihi!.month,
      state.baslangicTarihi!.day,
      state.baslangicSaat,
      state.baslangicDakika,
    );
    final bitis = DateTime(
      state.bitisTarihi!.year,
      state.bitisTarihi!.month,
      state.bitisTarihi!.day,
      state.bitisSaat,
      state.bitisDakika,
    );
    final fark = bitis.difference(baslangic);
    final saatFarki = fark.inHours;
    state = state.copyWith(hesaplananSaat: saatFarki, hesaplananGun: 0);
  } else {
    // Gün bazlı hesaplama
    final fark = state.bitisTarihi!.difference(state.baslangicTarihi!);
    final gunFarki = fark.inDays + 1; // +1 çünkü her iki gün de dahil
    state = state.copyWith(hesaplananGun: gunFarki, hesaplananSaat: 0);
  }
}
```

2. **`submitForm()`** - API'ye Gönderme
```dart
Future<void> submitForm() async {
  if (!state.isValid) {
    state = state.copyWith(errorMessage: 'Lütfen tüm gerekli alanları doldurun');
    return;
  }

  state = state.copyWith(isLoading: true, errorMessage: null);

  final request = IzinIstekEkleRequest(
    izinSebebiId: state.secilenIzinSebebi!.izinSebebiId,
    doktorRaporu: state.doktorRaporu,
    baslangicTarihi: state.baslangicTarihi!,
    bitisTarihi: state.bitisTarihi!,
    baslangicSaati: state.saatGoster ? state.baslangicSaat : null,
    baslangicDakika: state.saatGoster ? state.baslangicDakika : null,
    bitisSaati: state.saatGoster ? state.bitisSaat : null,
    bitisDakika: state.saatGoster ? state.bitisDakika : null,
    adres: state.adres,
    telefon: state.telefon,
    aciklama: state.aciklama,
    adSoyad: state.adSoyad,
    // Conditional fields
    evlilikTarihi: state.secilenIzinSebebi?.izinNedeni == 'Evlenme' ? state.evlilikTarihi : null,
    dogumTarihi: state.secilenIzinSebebi?.izinNedeni == 'Doğum' ? state.dogumTarihi : null,
    secilenDiniGun: state.secilenIzinSebebi?.izinNedeni == 'Dini İzin' ? state.secilenDiniGun : null,
    esAdi: state.secilenIzinSebebi?.izinNedeni == 'Evlenme' ? state.esAdi : null,
    hastalik: state.secilenIzinSebebi?.izinNedeni == 'Hastalık' ? state.hastalik : null,
    hesaplananGun: state.hesaplananGun,
    hesaplananSaat: state.hesaplananSaat,
    // ... other fields
  );

  final result = await ref.read(izinIstekRepositoryProvider).izinIstekEkle(request);

  switch (result) {
    case Success():
      state = state.copyWith(isLoading: false);
    case Failure(:final exception):
      state = state.copyWith(isLoading: false, errorMessage: exception.message);
    case Loading():
      break;
  }
}
```

---

## 🖥️ 4. Screen Katmanı (`izin_istek_screen.dart`)

### Dinamik UI Özellikleri:

#### **1. İzin Sebebine Göre Saatlik/Günlük Mod**
```dart
if (formState.saatGoster) ...[
  _buildTimeField('Başlangıç Saati *', ...),
  _buildTimeField('Bitiş Saati *', ...),
]
```

#### **2. Evlenme İzni İçin Özel Alanlar**
```dart
if (formState.secilenIzinSebebi?.izinNedeni == 'Evlenme') ...[
  _buildTextField('Eş Adı *', ...),
  _buildDateField('Evlilik Tarihi *', ...),
]
```

#### **3. Doğum İzni İçin Özel Alanlar**
```dart
if (formState.secilenIzinSebebi?.izinNedeni == 'Doğum') ...[
  _buildDateField('Doğum Tarihi *', ...),
]
```

#### **4. Dini İzin İçin Dini Gün Dropdown**
```dart
if (formState.secilenIzinSebebi?.izinNedeni == 'Dini İzin') ...[
  _buildDiniGunDropdown(ref, formNotifier, formState),
]
```

#### **5. Hastalık İzni İçin Açıklama Alanı**
```dart
if (formState.secilenIzinSebebi?.izinNedeni == 'Hastalık') ...[
  _buildTextField('Hastalık Açıklaması', maxLines: 3, ...),
]
```

#### **6. Otomatik Hesaplanan Süre Gösterimi**
```dart
if (formState.hesaplananGun > 0 || formState.hesaplananSaat > 0) ...[
  _buildCard(Container(
    child: Text(
      formState.saatGoster 
        ? 'Toplam: ${formState.hesaplananSaat} saat'
        : 'Toplam: ${formState.hesaplananGun} gün'
    ),
  )),
]
```

### Helper Widget'lar:

1. **`_buildCard(Widget child)`** - Beyaz kart container
2. **`_buildTextField(...)`** - Tekst input alanı
3. **`_buildDateField(...)`** - Tarih seçici
4. **`_buildTimeField(...)`** - Saat/dakika dropdown'ları
5. **`_buildDiniGunDropdown(...)`** - Dini gün dropdown (FutureProvider ile)

---

## 🔄 İş Akışı (Workflow)

### Form Doldurma Akışı:

1. **Ekran Açılır**
   - `izinSebepleriProvider` otomatik çalışır → İzin sebepleri yüklenir

2. **Kullanıcı İzin Sebebi Seçer**
   - `updateIzinSebebi()` çağrılır
   - `saatGoster` flag'ına göre UI güncellenir (saat alanları gösterilir/gizlenir)
   - İzin sebebine özel alanlar gösterilir (evlenme, doğum, dini izin, hastalık)

3. **Tarih/Saat Değişiklikleri**
   - Her tarih/saat değişikliğinde `_hesaplaIzinSuresi()` çağrılır
   - Otomatik olarak gün veya saat farkı hesaplanır
   - UI'da hesaplanan süre gösterilir

4. **Form Gönderimi**
   - Kullanıcı "Gönder" butonuna basar
   - `isValid` getter kontrolü yapılır (dinamik validasyon)
   - `submitForm()` çağrılır
   - Request oluşturulur (sadece ilgili opsiyonel alanlar dahil edilir)
   - API çağrısı yapılır
   - Başarı → Navigator.pop() + SnackBar
   - Hata → Error mesajı gösterilir

---

## ⚠️ Önemli Notlar

### 1. Personel ID
```dart
const int personelId = 133; // TODO: Gerçek personel ID kullanılacak
```
Şu anda hardcoded, ileride giriş yapan kullanıcıdan alınacak.

### 2. Dinamik Validasyon
Her izin sebebi farklı alanları gerektirir:
- **Evlenme:** esAdi + evlilikTarihi zorunlu
- **Doğum:** dogumTarihi zorunlu
- **Dini İzin:** secilenDiniGun zorunlu
- **Hastalık:** hastalik açıklaması (opsiyonel ama önerilir)

### 3. Otomatik Hesaplama
Tarih/saat değişikliklerinde otomatik hesaplama yapılır:
- **saatGoster = true:** Saat farkı hesaplanır
- **saatGoster = false:** Gün farkı hesaplanır (+1 ile, çünkü başlangıç ve bitiş günleri dahil)

### 4. Conditional Request Fields
`submitForm()` metodunda sadece ilgili alanlar gönderilir:
```dart
evlilikTarihi: state.secilenIzinSebebi?.izinNedeni == 'Evlenme' ? state.evlilikTarihi : null,
```

---

## 🧪 Test Senaryoları

### 1. Evlenme İzni
1. İzin sebebi: "Evlenme" seç
2. Eş adı gir
3. Evlilik tarihi seç
4. Diğer gerekli alanları doldur
5. Gönder

### 2. Saatlik İzin
1. İzin sebebi: Saatlik izin seç (saatGoster = true)
2. Saat/dakika alanları görünür
3. Başlangıç ve bitiş saatleri seç
4. Otomatik saat farkı hesaplanır
5. Gönder

### 3. Dini İzin
1. İzin sebebi: "Dini İzin" seç
2. Dini gün dropdown yüklenir (personelId ile)
3. Dini gün seç
4. Diğer alanları doldur
5. Gönder

---

## 📊 Başarı Kriterleri

✅ Tüm API endpoint'leri doğru şekilde map edildi
✅ Dinamik UI (saatGoster flag'ına göre)
✅ Conditional alanlar (izin sebebine göre)
✅ Otomatik süre hesaplama
✅ Dinamik validasyon
✅ Error handling
✅ Loading state
✅ Success feedback (SnackBar)

---

## 🚀 Sonraki Adımlar

1. **Personel ID Entegrasyonu:** Giriş yapan kullanıcının ID'sini kullan
2. **Dosya Upload:** Doktor raporu/evrak yükleme
3. **Tarih Kısıtlamaları:** İzin sebeplerinin `izinKacGunSonraBaslayacak` alanına göre başlangıç tarihini kısıtla
4. **Test:** Gerçek API ile test
5. **İzin Listesi Ekranı:** Mevcut izinleri listeleme
6. **İzin Detay Ekranı:** `getIzinDetay()` kullanarak detay gösterme
7. **İzin Silme:** `izinIstekSil()` ile silme işlemi

---

## 📝 Kod Kalitesi

- **Clean Architecture:** 4 katman (Model, Repository, Provider, Screen)
- **Result Pattern:** Success/Failure/Loading
- **Type Safety:** Güçlü tip kontrolü
- **Error Handling:** Try-catch ve DioException handling
- **Separation of Concerns:** Her katmanın sorumluluğu net
- **Reusability:** BaseRepository kullanımı
- **State Management:** Riverpod Notifier pattern

---

*✅ İzin İstek modülü gerçek API endpoint'leri ile başarıyla tamamlandı!*
