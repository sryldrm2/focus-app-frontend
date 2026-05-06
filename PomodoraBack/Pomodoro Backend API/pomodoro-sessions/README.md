# 🍅 Pomodoro Session Endpoints - Bruno Test Collection

## Test Edecek Endpoint'ler

### 1. **Start Session** ✅
- **Yol**: `POST /api/pomodoro-session/start`
- **Açıklama**: Yeni bir Pomodoro seansı başlatır
- **Varsayılan Süreler**:
  - WorkSession: 25 dakika
  - ShortBreakSession: 5 dakika
  - LongBreakSession: 15 dakika
- **Custom Süreler**: 5-60 dakika arası
- **Request Body**:
```json
{
  "sessionType": 0,        // 0=Work, 1=ShortBreak, 2=LongBreak
  "durationMinute": 25,    // Seans süresi (dakika)
  "taskId": null,          // Opsiyonel: Görev ID'si
  "notes": "Kod yazıyorum" // Opsiyonel: Seans notları
}
```
- **Response**: Oluşturulan seans bilgileri + `pomo_id` otomatik kaydedilir

---

### 2. **Start Session (Custom 30 min)** ✅
- **Yol**: `POST /api/pomodoro-session/start`
- **Açıklama**: 30 dakikalık custom seans başlatır
- **Puan**: 30 puan (her dakika 1 puan)
- **Request Body**:
```json
{
  "sessionType": 0,
  "durationMinute": 30,
  "taskId": null,
  "notes": "30 dakikalık uzun çalışma"
}
```

---

### 3. **Complete Session** ✅
- **Yol**: `POST /api/pomodoro-session/{pomoId}/complete`
- **Açıklama**: Devam eden seansı başarıyla tamamlar
- **Puan Hesaplama**: DurationMinute × 1 puan
  - 25 dakika = 25 puan
  - 30 dakika = 30 puan
  - 45 dakika = 45 puan
- **Status Değişimi**: OnGoing (0) → Successful (1)
- **Otomatik İşlemler**:
  - `User.TotalPoints` güncellenir
  - `CompletedAt` zamanı kaydedilir
  - `PointsEarned` hesaplanır

---

### 4. **Cancel Session** ✅
- **Yol**: `POST /api/pomodoro-session/{pomoId}/cancel`
- **Açıklama**: Devam eden seansı iptal eder
- **Status Değişimi**: OnGoing (0) → Cancelled (3)
- **Puan**: 0 puan kazanılır

---

### 5. **Get Ongoing Session** ✅
- **Yol**: `GET /api/pomodoro-session/ongoing`
- **Açıklama**: Kullanıcının devam eden seansını getirir
- **Response**: Varsa seans bilgileri, yoksa error

---

### 6. **Get Completed Sessions** ✅
- **Yol**: `GET /api/pomodoro-session/completed`
- **Açıklama**: Tamamlanan tüm seansları getirir
- **Response**: Seans dizisi (CreatedAt'e göre tersten sıralı)

---

### 7. **Get Total Points** ✅
- **Yol**: `GET /api/pomodoro-session/total-points`
- **Açıklama**: Kullanıcının toplam kazandığı puanı getirir
- **Response**: Integer (puan sayısı)

---

### 8. **Get Sessions by Date Range** ✅
- **Yol**: `GET /api/pomodoro-session/date-range?startDate=2024-01-01&endDate=2025-12-31`
- **Açıklama**: Belirli tarih aralığındaki seansları getirir
- **Query Parameters**:
  - `startDate`: Başlangıç tarihi (yyyy-MM-dd)
  - `endDate`: Bitiş tarihi (yyyy-MM-dd)
- **Response**: Seans dizisi

---

### 9. **Get Task Sessions** ✅
- **Yol**: `GET /api/pomodoro-session/task/{taskId}`
- **Açıklama**: Belirli bir görevle ilişkili seansları getirir
- **Response**: Seans dizisi

---

### 10. **Get Task Session Count** ✅
- **Yol**: `GET /api/pomodoro-session/task/{taskId}/count`
- **Açıklama**: Görev için yapılan seans sayısını getirir
- **Response**: Integer (seans sayısı)

---

### 11. **Increment Break Count** ✅
- **Yol**: `POST /api/pomodoro-session/{pomoId}/break`
- **Açıklama**: Seansın ara verilme sayısını artırır
- **Kullanım**: Pause/Resume tuşu basıldığında
- **Response**: BreakCount arttırılmış seans

---

## 📊 Puan Sistemi Özeti

| Süresi | Standart | Custom | Puan |
|--------|----------|--------|------|
| 5 dk | ✅ ShortBreak | ✅ | 5 |
| 15 dk | ✅ LongBreak | ✅ | 15 |
| 25 dk | ✅ WorkSession | ✅ | 25 |
| 30 dk | ❌ | ✅ | 30 |
| 45 dk | ❌ | ✅ | 45 |
| 60 dk | ❌ | ✅ | 60 |

**KURAL**: Her 1 dakika = 1 puan

---

## 🧪 Test Sırası (Önerilen)

1. **Start Session** → `pomo_id` elde et
2. **Get Ongoing Session** → Seansı doğrula
3. **Increment Break Count** (optional) → Ara sayısını artır
4. **Complete Session** → Seansı tamamla
5. **Get Total Points** → Puanları kontrol et
6. **Get Completed Sessions** → Tamamlanan seansları listele

---

## 🔑 Variables (Bruno'da Otomatik Kaydedilir)

- `{{pomo_id}}` - Seans ID'si (Start Session'dan)
- `{{task_id}}` - Görev ID'si
- `{{total_points}}` - Toplam puan (Get Total Points'ten)

---

## 💡 Test Notları

- ✅ **Freestyle Seanslar**: TaskId boş bırakılabilir
- ✅ **Custom Süreler**: 5-60 dakika arası
- ✅ **Puan Hesaplaması**: Dinamik (dakika × 1)
- ✅ **Soft Delete**: Seanslar DeletedAt ile işaretlenir
- ✅ **Authorization**: Bearer token gerekli

---

## 🚀 Başlamak İçin

1. Bruno'yu aç
2. `Pomodoro Backend API` koleksiyonunu seç
3. `🍅 Pomodoro Sessions` klasörünü aç
4. **Start Session**'dan başla
5. Endpoint'leri sırasıyla çalıştır

**İyi testler!** 🎉
