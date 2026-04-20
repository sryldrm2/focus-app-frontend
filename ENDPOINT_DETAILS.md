# 📖 Pomodoro Backend API - Tüm Endpoint'ler Detaylı Rehber

## 📑 İçindekiler
1. [🔐 Authentication](#-authentication)
2. [👥 Users](#-users)
3. [👫 Friend Requests](#-friend-requests)
4. [🤝 Friendships](#-friendships)
5. [📊 Veri Modelleri](#-veri-modelleri)
6. [🔑 Hata Kodları](#-hata-kodları)

---

## 🔐 Authentication

### 1. Register (Kayıt Ol)

**Endpoint:** `POST /api/auth/register`

**Auth Gerekli:** ❌ Hayır

**Açıklama:** Yeni bir kullanıcı hesabı oluştur

**Request Body:**
```json
{
  "name": "Ahmet",
  "surname": "Yılmaz",
  "nickname": "ahmetyilmaz",
  "email": "ahmet@example.com",
  "password": "Securepass123",
  "confirmPassword": "Securepass123"
}
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "message": "Kayıt başarılı.",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "accessTokenExpiration": "2026-01-15T12:30:00Z",
    "refreshTokenExpiration": "2026-02-15T12:00:00Z",
    "user": {
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Ahmet",
      "surname": "Yılmaz",
      "nickname": "ahmetyilmaz",
      "email": "ahmet@example.com",
      "currentStatus": false,
      "totalPoints": 0,
      "lastSeen": "2026-01-15T12:00:00Z",
      "deletedAt": null
    }
  }
}
```

**Hata Response (400):**
```json
{
  "success": false,
  "message": "Bu email adresi zaten kayıtlı."
}
```

**Validasyon Kuralları:**
- ✅ Name: Max 20 karakter
- ✅ Surname: Max 20 karakter
- ✅ Nickname: Benzersiz olmalı
- ✅ Email: Benzersiz ve geçerli format
- ✅ Password: Min 6, Max 30 karakter
- ✅ ConfirmPassword: Password ile aynı olmalı

---

### 2. Login (Giriş Yap)

**Endpoint:** `POST /api/auth/login`

**Auth Gerekli:** ❌ Hayır

**Açıklama:** Kullanıcı hesabına giriş yap

**Request Body:**
```json
{
  "emailOrNickname": "ahmetyilmaz",
  "password": "Securepass123"
}
```

*veya email ile:*
```json
{
  "emailOrNickname": "ahmet@example.com",
  "password": "Securepass123"
}
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "message": "Giriş başarılı.",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "accessTokenExpiration": "2026-01-15T12:30:00Z",
    "refreshTokenExpiration": "2026-02-15T12:00:00Z",
    "user": { ... }
  }
}
```

**Hata Responses:**
```json
// Kullanıcı bulunamadı
{
  "success": false,
  "message": "Kullanıcı bulunamadı."
}

// Şifre hatalı
{
  "success": false,
  "message": "Şifre hatalı."
}
```

---

### 3. Refresh Token (Token Yenile)

**Endpoint:** `POST /api/auth/refresh-token`

**Auth Gerekli:** ❌ Hayır

**Açıklama:** Süresi dolan access token yerine yeni token al

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "message": "Token yenilendi.",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "accessTokenExpiration": "2026-01-15T12:30:00Z",
    "refreshTokenExpiration": "2026-02-15T12:00:00Z",
    "user": { ... }
  }
}
```

**Hata Response:**
```json
{
  "success": false,
  "message": "Geçersiz veya süresi dolmuş refresh token."
}
```

---

### 4. Logout (Çıkış Yap)

**Endpoint:** `POST /api/auth/logout`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**Açıklama:** Hesaptan çıkış yap, tüm refresh token'lar revoke edilir

**Başarılı Response (200):**
```json
{
  "success": true,
  "message": "Çıkış başarılı."
}
```

---

### 5. Get Current User (Mevcut Kullanıcı)

**Endpoint:** `GET /api/auth/me`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**Açıklama:** Oturum açmış kullanıcının bilgisini getir

**Başarılı Response (200):**
```json
{
  "success": true,
  "data": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "email": "ahmet@example.com",
    "nickname": "ahmetyilmaz"
  }
}
```

---

## 👥 Users

### 1. Get All Users (Tüm Kullanıcıları Listele)

**Endpoint:** `GET /api/users`

**Auth Gerekli:** ❌ Hayır

**Açıklama:** Sistemdeki tüm kullanıcıları listele

**Başarılı Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Ahmet",
      "surname": "Yılmaz",
      "nickname": "ahmetyilmaz",
      "email": "ahmet@example.com",
      "currentStatus": true,
      "totalPoints": 150,
      "lastSeen": "2026-01-15T12:00:00Z",
      "deletedAt": null,
      "isOnline": true
    },
    { ... }
  ]
}
```

---

### 2. Get User by ID (Kullanıcı Bilgisi)

**Endpoint:** `GET /api/users/{userId}`

**Auth Gerekli:** ❌ Hayır

**URL Parameters:**
```
userId: "550e8400-e29b-41d4-a716-446655440000"
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "data": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Ahmet",
    "surname": "Yılmaz",
    "nickname": "ahmetyilmaz",
    "email": "ahmet@example.com",
    "currentStatus": true,
    "totalPoints": 150,
    "lastSeen": "2026-01-15T12:00:00Z",
    "deletedAt": null,
    "isOnline": true
  }
}
```

**Hata Response (404):**
```json
{
  "success": false,
  "message": "Kullanıcı bulunamadı."
}
```

---

### 3. Update User (Kullanıcı Güncelle)

**Endpoint:** `PUT /api/users/{userId}`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**URL Parameters:**
```
userId: "550e8400-e29b-41d4-a716-446655440000"
```

**Request Body (tüm alanlar isteğe bağlı):**
```json
{
  "name": "Ahmet",
  "surname": "Kaya",
  "nickname": "ahmetkaya",
  "email": "ahmetkaya@example.com"
}
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "message": "Kullanıcı güncellendi.",
  "data": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Ahmet",
    "surname": "Kaya",
    "nickname": "ahmetkaya",
    "email": "ahmetkaya@example.com",
    "currentStatus": true,
    "totalPoints": 150,
    "lastSeen": "2026-01-15T12:00:00Z",
    "deletedAt": null
  }
}
```

**Hata Responses:**
```json
// Kullanıcı bulunamadı
{
  "success": false,
  "message": "Kullanıcı bulunamadı."
}

// Email zaten kullanılıyor
{
  "success": false,
  "message": "Bu email adresi zaten kullanılıyor."
}
```

---

### 4. Delete User (Kullanıcı Sil)

**Endpoint:** `DELETE /api/users/{userId}`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
```
userId: "550e8400-e29b-41d4-a716-446655440000"
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "message": "Kullanıcı silindi."
}
```

**Hata Response:**
```json
{
  "success": false,
  "message": "Kullanıcı bulunamadı."
}
```

---

## 👫 Friend Requests

### 1. Send Friend Request (İstek Gönder)

**Endpoint:** `POST /api/friendrequest/send`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "receiverId": "550e8400-e29b-41d4-a716-446655440001"
}
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "message": "Arkadaş isteği gönderildi.",
  "data": {
    "friendRequestId": "550e8400-e29b-41d4-a716-446655440002",
    "consignerId": "550e8400-e29b-41d4-a716-446655440000",
    "receiverId": "550e8400-e29b-41d4-a716-446655440001",
    "status": false,
    "createdAt": "2026-01-15T12:00:00Z"
  }
}
```

**Hata Responses:**
```json
// Kendinize istek gönderemezsiniz
{
  "success": false,
  "message": "Kendinize arkadaş isteği gönderemezsiniz."
}

// Zaten arkadaş
{
  "success": false,
  "message": "Zaten bu kullanıcının arkadaşısınız."
}

// Zaten istek var
{
  "success": false,
  "message": "Bu kullanıcıya zaten bir istek gönderilmiş veya sizden bir istek bekleniyor."
}
```

---

### 2. Accept Friend Request (İstek Kabul Et)

**Endpoint:** `POST /api/friendrequest/{friendRequestId}/accept`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
```
friendRequestId: "550e8400-e29b-41d4-a716-446655440002"
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "message": "Arkadaş isteği kabul edildi.",
  "data": {
    "friendRequestId": "550e8400-e29b-41d4-a716-446655440002",
    "consignerId": "550e8400-e29b-41d4-a716-446655440000",
    "receiverId": "550e8400-e29b-41d4-a716-446655440001",
    "status": true,
    "createdAt": "2026-01-15T12:00:00Z",
    "updatedAt": "2026-01-15T12:05:00Z"
  }
}
```

**Hata Response:**
```json
{
  "success": false,
  "message": "Arkadaş isteği bulunamadı."
}
```

---

### 3. Reject Friend Request (İstek Reddet)

**Endpoint:** `POST /api/friendrequest/{friendRequestId}/reject`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
```
friendRequestId: "550e8400-e29b-41d4-a716-446655440002"
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "message": "Arkadaş isteği reddedildi.",
  "data": { ... }
}
```

---

### 4. Get Pending Requests (Beklemede İstekler)

**Endpoint:** `GET /api/friendrequest/pending`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**Açıklama:** Gelen beklemede arkadaş isteklerini getir

**Başarılı Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "friendRequestId": "550e8400-e29b-41d4-a716-446655440002",
      "consignerId": "550e8400-e29b-41d4-a716-446655440000",
      "receiverId": "550e8400-e29b-41d4-a716-446655440001",
      "status": false,
      "createdAt": "2026-01-15T12:00:00Z"
    }
  ]
}
```

**Boş Response (200):**
```json
{
  "success": true,
  "message": "Beklemede istek bulunamadı.",
  "data": []
}
```

---

### 5. Get Sent Requests (Gönderilen İstekler)

**Endpoint:** `GET /api/friendrequest/sent`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**Açıklama:** Gönderilen beklemede arkadaş isteklerini getir

**Başarılı Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "friendRequestId": "550e8400-e29b-41d4-a716-446655440002",
      "consignerId": "550e8400-e29b-41d4-a716-446655440000",
      "receiverId": "550e8400-e29b-41d4-a716-446655440001",
      "status": false,
      "createdAt": "2026-01-15T12:00:00Z"
    }
  ]
}
```

---

## 🤝 Friendships

### 1. Get My Friends (Benim Arkadaşlarım)

**Endpoint:** `GET /api/friendship/my-friends`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "friendshipId": "550e8400-e29b-41d4-a716-446655440003",
      "firstUserId": "550e8400-e29b-41d4-a716-446655440000",
      "secondUserId": "550e8400-e29b-41d4-a716-446655440001",
      "createdAt": "2026-01-15T12:05:00Z",
      "deletedAt": null,
      "firstUser": {
        "userId": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Ahmet",
        "surname": "Yılmaz",
        "nickname": "ahmetyilmaz",
        "email": "ahmet@example.com",
        "currentStatus": true,
        "totalPoints": 150,
        "lastSeen": "2026-01-15T12:00:00Z",
        "deletedAt": null
      },
      "secondUser": {
        "userId": "550e8400-e29b-41d4-a716-446655440001",
        "name": "Mehmet",
        "surname": "Kaya",
        "nickname": "mehmetkaya",
        "email": "mehmet@example.com",
        "currentStatus": false,
        "totalPoints": 200,
        "lastSeen": "2026-01-15T11:00:00Z",
        "deletedAt": null
      }
    }
  ]
}
```

**Boş Response (200):**
```json
{
  "success": true,
  "message": "Arkadaş bulunamadı.",
  "data": []
}
```

---

### 2. Get User Friends (Kullanıcının Arkadaşları)

**Endpoint:** `GET /api/friendship/{userId}/friends`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
```
userId: "550e8400-e29b-41d4-a716-446655440001"
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "data": [ ... ]
}
```

---

### 3. Check Friendship (Arkadaşlık Kontrol Et)

**Endpoint:** `GET /api/friendship/{friendId}/check`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
```
friendId: "550e8400-e29b-41d4-a716-446655440001"
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "data": {
    "friendshipId": "550e8400-e29b-41d4-a716-446655440003",
    "firstUserId": "550e8400-e29b-41d4-a716-446655440000",
    "secondUserId": "550e8400-e29b-41d4-a716-446655440001",
    "createdAt": "2026-01-15T12:05:00Z",
    "deletedAt": null,
    "firstUser": { ... },
    "secondUser": { ... }
  }
}
```

**Hata Response:**
```json
{
  "success": false,
  "message": "Arkadaşlık ilişkisi bulunamadı."
}
```

---

### 4. Are Friends (Arkadaş Mı)

**Endpoint:** `GET /api/friendship/{friendId}/are-friends`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
```
friendId: "550e8400-e29b-41d4-a716-446655440001"
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "data": true
}
```

**Arkadaş Değilse:**
```json
{
  "success": true,
  "data": false
}
```

---

### 5. Remove Friend (Arkadaş Kaldır)

**Endpoint:** `DELETE /api/friendship/{friendId}`

**Auth Gerekli:** ✅ Evet

**Header:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
```
friendId: "550e8400-e29b-41d4-a716-446655440001"
```

**Başarılı Response (200):**
```json
{
  "success": true,
  "message": "Arkadaş kaldırıldı."
}
```

**Hata Response:**
```json
{
  "success": false,
  "message": "Arkadaşlık ilişkisi bulunamadı."
}
```

---

## 📊 Veri Modelleri

### UserDto
```json
{
  "userId": "string (GUID)",
  "name": "string",
  "surname": "string",
  "nickname": "string",
  "email": "string",
  "currentStatus": "boolean",
  "totalPoints": "decimal",
  "lastSeen": "datetime",
  "deletedAt": "datetime | null",
  "isOnline": "boolean"
}
```

### FriendRequestDto
```json
{
  "friendRequestId": "string (GUID)",
  "consignerId": "string (GUID)",
  "receiverId": "string (GUID)",
  "status": "boolean",
  "createdAt": "datetime",
  "updatedAt": "datetime | null",
  "consigner": "UserDto | null",
  "receiver": "UserDto | null"
}
```

### FriendshipDto
```json
{
  "friendshipId": "string (GUID)",
  "firstUserId": "string (GUID)",
  "secondUserId": "string (GUID)",
  "createdAt": "datetime",
  "deletedAt": "datetime | null",
  "firstUser": "UserDto",
  "secondUser": "UserDto"
}
```

### AuthResponseDto
```json
{
  "accessToken": "string (JWT)",
  "refreshToken": "string (JWT)",
  "accessTokenExpiration": "datetime",
  "refreshTokenExpiration": "datetime",
  "user": "UserDto"
}
```

---

## 🔑 Hata Kodları

| HTTP Status | Açıklama | Örnek |
|-------------|----------|-------|
| 200 OK | İşlem başarılı | Başarılı response |
| 400 Bad Request | Geçersiz istek | Email zaten kullanılıyor |
| 401 Unauthorized | Kimlik doğrulama başarısız | Token geçersiz/süresi doldu |
| 404 Not Found | Kaynak bulunamadı | Kullanıcı bulunamadı |
| 500 Server Error | Sunucu hatası | Beklenmeyen hata |

---

**Son Güncelleme:** 15 Nisan 2026
