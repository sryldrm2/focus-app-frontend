# 📚 Pomodoro Backend API - Bruno Setup Rehberi

## 🚀 Hızlı Başlangıç

### 1️⃣ Backend'i Çalıştır

```bash
# PomodoraBack klasörüne git
cd PomodoraBack

# Gerekli paketleri yükle
dotnet restore

# Migration'ları uygula
dotnet ef database update

# Backend'i çalıştır
dotnet run
```

**Backend çalıştıktan sonra:**
- 🌐 API Base URL: `http://localhost:5000`
- 📖 Swagger UI: `http://localhost:5000` (kök dizinde açılır)

---

## 🔧 Bruno İçin Setup

### Adım 1: Collection'ı İçe Aktar

1. **Bruno'yu aç** → Yeni workspace oluştur veya mevcut workspace'ı aç
2. **"Import Collection"** butonuna tıkla
3. **`Pomodoro_API_Collection.postman_collection.json`** dosyasını seç
4. ✅ Collection başarıyla içe aktarıldı!

---

### Adım 2: Environment Variables'ları Ayarla

Collection açıldığında, sağ üstte **"Variables"** sekmesini aç:

| Variable | Default | Açıklama |
|----------|---------|----------|
| `base_url` | `http://localhost:5000` | API sunucusu adresi |
| `access_token` | *(boş)* | Login sonrası otomatik set edilir |
| `refresh_token` | *(boş)* | Login sonrası otomatik set edilir |
| `user_id` | *(boş)* | Test için kullanıcı ID |
| `target_user_id` | *(boş)* | Hedef kullanıcı ID |
| `friend_id` | *(boş)* | Arkadaş ID |
| `friend_request_id` | *(boş)* | İstek ID |

---

## 📝 Test Senaryosu

### Senaryo 1: Temel Auth Flow

```
1. Register (Kayıt Ol)
   ├─ İsim, Soyad, Nickname, Email, Password gir
   └─ Response'dan: access_token ve user_id'yi not et

2. Login (Giriş Yap)
   ├─ Nickname/Email ve Password gir
   └─ access_token ve refresh_token'ı kaydet

3. Get Current User (Mevcut Kullanıcı)
   ├─ Authorization: Bearer {{access_token}} header'ını kullan
   └─ Kullanıcı bilgisini gör

4. Logout (Çıkış Yap)
   └─ Token'lar revoke edilir
```

---

### Senaryo 2: Arkadaş İstekleri

```
1. İlk kullanıcı olarak login yap
   └─ access_token'ı kaydet

2. Send Friend Request
   ├─ {{target_user_id}} (ikinci kullanıcının ID'si) gir
   └─ friend_request_id'yi not et

3. İkinci kullanıcı olarak login yap (yeni access_token al)
   
4. Get Pending Requests
   └─ Beklemede isteği gör

5. Accept Friend Request
   ├─ {{friend_request_id}} kullan
   └─ Arkadaş isteği kabul edildi
```

---

### Senaryo 3: Arkadaş Yönetimi

```
1. Get My Friends
   └─ Tüm arkadaşlarınızı görün

2. Check Friendship
   ├─ {{friend_id}} (arkadaş ID'si) gir
   └─ Arkadaşlık ilişkisinin detaylarını gör

3. Are Friends
   ├─ {{friend_id}} gir
   └─ Boolean (true/false) yanıt al

4. Remove Friend
   ├─ {{friend_id}} gir
   └─ Arkadaşlık ilişkisini sil
```

---

## 🔄 Token Yönetimi

### Access Token Süresi Dolmuşsa

Access token'ın süresi 15 dakika sonra dolar. Yeni token almak için:

```
POST /api/auth/refresh-token
Body: {
  "refreshToken": "{{refresh_token}}"
}
```

Response'dan yeni `accessToken`'ı kopyala ve `{{access_token}}` variable'ına set et.

---

## 📊 Response Yapıları

### Başarılı Response (200)
```json
{
  "success": true,
  "message": "İşlem başarılı",
  "data": { ... }
}
```

### Hata Response (400/401)
```json
{
  "success": false,
  "message": "Hata açıklaması"
}
```

---

## 🆔 Variable Değerlerini Otomatik Ayarla

### Login Response'ından Token Almak İçin

**Post-request Script** ekle (Tests sekmesinde):

```javascript
const jsonData = pm.response.json();
if (jsonData.data) {
    pm.environment.set("access_token", jsonData.data.accessToken);
    pm.environment.set("refresh_token", jsonData.data.refreshToken);
    pm.environment.set("user_id", jsonData.data.user.userId);
}
```

---

## 🔐 JWT Token Yapısı

Token Header'daki format:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## ⚡ Hızlı İpuçları

✅ **Her test öncesinde:**
- API çalışıyor mu kontrol et (`http://localhost:5000`)
- Doğru `access_token` ayarlandı mı kontrol et

✅ **Token ile ilgili sorunlar:**
- Token'ın süresi dolmuş olabilir → Refresh token kullan
- Token'ı yanlış kopyalamış olabilirsin → Tekrar login yap

✅ **Kullanıcı bulunamadı hatası:**
- `user_id` veya `target_user_id` yanlış olabilir
- ID'yi bir önceki request'in response'ından kopyala

---

## 📞 Sorun Giderme

| Sorun | Çözüm |
|-------|-------|
| 401 Unauthorized | Access token'ını kontrol et, eski olabilir |
| 400 Bad Request | Request body'nin formatını kontrol et |
| 404 Not Found | Endpoint URL'ini kontrol et |
| CORS hatası | Backend'in CORS ayarları kontrol et |
| Bağlantı reddedildi | Backend çalışıyor mu kontrol et |

---

## 🎯 Sonraki Adımlar

1. ✅ Tüm Auth endpoint'lerini test et
2. ✅ User endpoint'lerini test et
3. ✅ Friend Request flow'unu test et
4. ✅ Friendship endpoint'lerini test et

---

**Sorularınız varsa, aşağıda belirtilen endpoint'lerin response'larını kontrol edin! 🚀**
