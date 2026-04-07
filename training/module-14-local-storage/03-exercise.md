# Exercises — Thực hành Local Storage

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 12](../module-12-data-layer/) (data layer structure), [Module 13](../module-13-middleware-interceptor-chain/) (interceptors dùng AppPreferences) và đọc xong [01-code-walk.md](./01-code-walk.md).

---

## ⭐ Exercise 1: Read & Trace AppPreferences Usage

**Mục tiêu:** Trace data flow từ login → save token → interceptor đọc token → API call.

### Hướng dẫn

1. Mở [app_preferences.dart](../../base_flutter/lib/data_source/preference/app_preferences.dart).
2. Mở [access_token_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/access_token_interceptor.dart).
3. Mở [refresh_token_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/refresh_token_interceptor.dart).

### Template

**Phần A — Login Flow (write path):**

Giả sử login API trả `{ "access_token": "abc123", "refresh_token": "xyz789", "user_id": 42 }`.

| Step | Method | Storage Tier | Sync/Async | Encrypted? |
|:----:|--------|:----------:|:----------:|:----------:|
| 1 | `saveAccessToken("abc123")` | ? | ? | ? |
| 2 | `saveRefreshToken("xyz789")` | ? | ? | ? |
| 3 | `saveUserId(42)` | ? | ? | ? |
| 4 | `saveIsLoggedIn(true)` | ? | ? | ? |

**Phần B — API Call Flow (read path):**

Giả sử sau login, app gọi `GET /v1/me`.

| Step | Component | Operation | Return Type | Notes |
|:----:|-----------|-----------|:-----------:|-------|
| 1 | `AccessTokenInterceptor.onRequest` | `await _appPreferences.accessToken` | ? | Tại sao `await`? |
| 2 | Set header | `Authorization: Bearer abc123` | — | Token từ bước 1 |
| 3 | Server trả 401 | — | — | Token expired |
| 4 | `RefreshTokenInterceptor.onError` | `appPreferences.saveAccessToken(newToken)` | ? | Token mới |
| 5 | Retry request | `await _appPreferences.accessToken` | ? | Đọc token mới |

**Phần C — Logout Flow:**

| Step | Method | Keys Removed | Storage Used |
|:----:|--------|:----------:|:----------:|
| 1 | `clearCurrentUserData()` | ? (list all 4) | `_sharedPreference.remove()` |

**Câu hỏi:**
- Tại sao `clearCurrentUserData()` dùng `_sharedPreference.remove()` cho token keys mà không dùng `_encryptedSharedPreferences`? Có an toàn không?
- Nếu `saveAccessToken()` thất bại (disk full) nhưng login flow tiếp tục — hậu quả gì?
- `get userId` trả `int` (sync) nhưng `get accessToken` trả `Future<String>` (async) — tại sao khác nhau?

### ✅ Checklist hoàn thành
- [ ] Điền đủ Phần A (4 save operations, đúng tier + sync/async)
- [ ] Điền đủ Phần B (trace 5 steps, đúng return type)
- [ ] Điền Phần C (list 4 keys, đúng storage)
- [ ] Trả lời 3 câu hỏi

---

## ⭐ Exercise 2: Add New Preference Key

**Mục tiêu:** Thêm `languageCode` key vào `AppPreferences` — lưu ngôn ngữ user chọn (vi/en/ja).

### Yêu cầu

Thêm vào `AppPreferences`:
- Static const key cho `languageCode`
- Save method — chọn đúng storage tier (plain hay encrypted?) và return type
- Get method — sync hay async? Default value khi chưa set?
- Quyết định: `clearCurrentUserData()` có nên xóa `languageCode` không?

**Câu hỏi:**
- `languageCode` là user preference hay app setting? Phân biệt ảnh hưởng logout behavior thế nào?
- Nếu user A chọn "vi", logout, user B login → user B thấy gì? Expected behavior?
- Nếu cần support multiple languages per user trên cùng device → design thế nào?

<details>
<summary>💡 Gợi ý (mở khi stuck > 15 phút)</summary>

- `languageCode` không phải sensitive data → dùng plain `SharedPreferences` (sync read)
- Return type getter: `String` (sync, vì plain storage)
- Default: `'en'` hoặc `'vi'`
- **Không** xóa trong `clearCurrentUserData()` vì đây là app-level setting, không phải user session data

</details>

### ✅ Checklist hoàn thành
- [ ] Key added: `static const keyLanguageCode`
- [ ] Save method: đúng storage tier (plain — non-sensitive)
- [ ] Get method: sync return với default value
- [ ] Decision: không xóa trong `clearCurrentUserData()`
- [ ] Trả lời 3 câu hỏi
- [ ] **Đã revert changes**

---

## ⭐⭐ Exercise 3: Key Migration Strategy

**Mục tiêu:** Migrate key `isLoggedIn` từ plain → encrypted storage, handle backward compatibility.

### Context

Security audit yêu cầu `isLoggedIn` phải encrypted (vì reveals user state). Existing users đã có value trong plain storage → cần migration.

### Yêu cầu

1. Viết `migrateIsLoggedInToEncrypted()` — đọc plain → save encrypted → remove plain, skip nếu null
2. Update `saveIsLoggedIn` và `get isLoggedIn` cho encrypted storage
3. Handle: `EncryptedSharedPreferences` chỉ hỗ trợ `String` → cần convert `bool` ↔ `String`
4. Xác định nơi gọi migration (startup? lazy? explicit screen?)

**Câu hỏi:**
- `get isLoggedIn` đổi từ sync `bool` → async `Future<bool>` — những consumer nào sẽ break? Cách handle?
- Migration idempotent không? Gọi 2 lần có an toàn?
- Nếu migration crash giữa chừng (save encrypted OK, remove plain fail) → data state ra sao?

<details>
<summary>💡 Gợi ý (mở khi stuck > 15 phút)</summary>

- Migration steps: `_sharedPreference.getBool(key)` → nếu non-null → `_encryptedSharedPreferences.setString(key, value.toString())` → `_sharedPreference.remove(key)`
- Idempotent: lần 2 plain value = null → skip. An toàn.
- Migration location: app startup (trước first read) — gọi trong `AppInitializer`
- Crash giữa chừng → data tồn tại ở CẢ HAI storage → migration lần sau sẽ overwrite encrypted (safe)

</details>

### ✅ Checklist hoàn thành
- [ ] Migration method: đọc plain → save encrypted → remove plain
- [ ] Null check: skip nếu plain value null
- [ ] Updated getter: async, parse String → bool
- [ ] Updated setter: convert bool → String
- [ ] Migration location xác định
- [ ] Trả lời 3 câu hỏi
- [ ] **Đã revert changes**

---

## ⭐⭐ Exercise 4: Add Encrypted Field with FlutterSecureStorage

**Mục tiêu:** Sử dụng `_secureStorage` (hiện chưa dùng) để lưu `pinCode` — mã PIN 6 số.

### Yêu cầu

Thêm vào `AppPreferences`:
- `savePinCode(String)` — validate 6 digits + write vào `_secureStorage`
- `get pinCode` → `Future<String?>` (nullable — chưa set)
- `deletePinCode()` → xóa từ `_secureStorage`
- Update `clearCurrentUserData()` — thêm cleanup cho secure storage
- Validation function: chỉ accept exactly 6 digits

**Câu hỏi:**
- `FlutterSecureStorage.read()` trả `String?` nhưng `EncryptedSharedPreferences.getString()` trả `String` — tại sao khác? Ảnh hưởng error handling?
- PIN code nên lưu ở `_secureStorage` hay `_encryptedSharedPreferences`? Justify security tier choice.
- iOS user có Face ID nhưng chưa setup → `FlutterSecureStorage` behavior ra sao?

<details>
<summary>💡 Gợi ý (mở khi stuck > 15 phút)</summary>

- Dùng `_secureStorage` (Keychain/Keystore) vì PIN là highest-sensitivity data
- Validation: `RegExp(r'^\d{6}$').hasMatch(pin)`
- `clearCurrentUserData()`: thêm `_secureStorage.delete(key: keyPinCode)` vào `Future.wait`
- `FlutterSecureStorage.read` returns `null` khi key chưa set — KHÁC với `EncryptedSharedPreferences` trả empty string

</details>

### ✅ Checklist hoàn thành
- [ ] `savePinCode()` validate + `_secureStorage.write()`
- [ ] `get pinCode` → `Future<String?>` (nullable)
- [ ] `deletePinCode()` → `_secureStorage.delete()`
- [ ] `clearCurrentUserData()` updated
- [ ] Validation: 6 digits only
- [ ] Trả lời 3 câu hỏi
- [ ] **Đã revert changes**

---

## ⭐⭐⭐ Exercise 5: AI Dojo — 📊 Data Migration Strategy

### 🤖 AI Dojo — Schema Migration cho Local Storage

**Mục tiêu**: Mô tả schema change cho AI → AI viết migration strategy → đánh giá data preservation.

**Bước thực hiện**:

1. Mô tả scenario migration cho AI:
```
Flutter app dùng 3-tier storage: SharedPreferences (plain),
EncryptedSharedPreferences, FlutterSecureStorage.

Current schema:
- accessToken: String (EncryptedSharedPreferences)
- refreshToken: String (EncryptedSharedPreferences)
- userId: int (SharedPreferences)
- isLoggedIn: bool (SharedPreferences)
- isDarkMode: bool (SharedPreferences)

Required migration (v2):
1. Move isLoggedIn từ plain → encrypted (security audit requirement)
2. Thêm field tokenExpiry: DateTime (cần lưu kèm accessToken)
3. Rename isDarkMode → themeMode: String (support "light"/"dark"/"system")
4. userId đổi type từ int → String (backend migrate sang UUID)

Viết migration strategy:
- Migration function cho từng field
- Backward compatibility: user cũ update app → data không mất
- Error handling: migration fail giữa chừng → rollback hay skip?
- Migration ordering: field nào migrate trước/sau?
- Testing: verify migration thành công bằng cách nào?
```

2. Đánh giá AI migration strategy:
   - **Data preservation**: user cũ có mất session không? (isLoggedIn migrate fail → bị logout?)
   - **Idempotent**: chạy migration 2 lần có an toàn không?
   - **Atomic**: nếu crash giữa migration → data ở state nào?

3. So sánh với Exercise 3 (Key Migration) — AI strategy có consistent với pattern bạn đã practice?

**✅ Tiêu chí đánh giá**:
- [ ] AI viết migration cho ≥ 3/4 field changes
- [ ] AI đề cập backward compatibility (check old key trước khi migrate)
- [ ] AI handle error case: migration fail → data không bị corrupt
- [ ] Bạn identify ≥ 1 risk AI thiếu (thường: DateTime serialization format, int→String type conversion edge case)

→ Kiểm tra kết quả: [04-verify.md](./04-verify.md)

<!-- AI_VERIFY: generation-complete -->
