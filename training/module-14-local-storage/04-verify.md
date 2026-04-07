# Verification — Kiểm tra kết quả Module 14

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi phân biệt được `SharedPreferences` sync read vs async write? | SharedPreferences | 🔴 |
| 2 | Tôi giải thích được `EncryptedSharedPreferences` encrypt/decrypt flow (AES → base64 → SharedPreferences)? | Encrypted Storage | 🔴 |
| 3 | Tôi biết `FlutterSecureStorage` dùng iOS Keychain (`first_unlock`) + Android EncryptedSharedPreferences? | FlutterSecureStorage | 🟡 |
| 4 | Tôi phân loại được data vào đúng tier (plain / encrypted / secure) dựa trên sensitivity? | Security Tiers | 🟡 |
| 5 | Tôi hiểu dual-DI pattern: `@LazySingleton()` cho getIt + `Provider` cho Riverpod? | DI Service | 🟡 |
| 6 | Tôi biết khi nào dùng Isar thay SharedPreferences (structured vs key-value)?  | Isar Database | 🟡 |
| 7 | Tôi mô tả được `clearCurrentUserData()` — selective remove + `Future.wait()` parallel pattern? | Logout Cleanup | 🟢 |

**Target:** 2/2 Yes cho 🔴 MUST-KNOW, tối thiểu 6/7 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Read & Trace AppPreferences Usage ⭐

- [ ] Phần A: `saveAccessToken` → Encrypted, async, ✅ encrypted
- [ ] Phần A: `saveRefreshToken` → Encrypted, async, ✅ encrypted
- [ ] Phần A: `saveUserId` → Plain `_sharedPreference`, async write, ❌ not encrypted
- [ ] Phần A: `saveIsLoggedIn` → Plain `_sharedPreference`, async write, ❌ not encrypted
- [ ] Phần B: `get accessToken` trả `Future<String>` — async vì encrypted storage cần decrypt
- [ ] Phần B: Interceptor `await` token → set `Authorization: Bearer` header
- [ ] Phần C: 4 keys removed — `keyAccessToken`, `keyRefreshToken`, `keyUserId`, `keyIsLoggedIn`
- [ ] Trả lời: `_sharedPreference.remove()` hoạt động cho encrypted keys vì `EncryptedSharedPreferences` wrap cùng `SharedPreferences` instance → remove raw key xóa cả encrypted value
- [ ] Trả lời: Nếu `saveAccessToken()` fail → next API call thiếu token → 401 → refresh loop hoặc force logout
- [ ] Trả lời: `userId` sync vì plain SharedPreferences (in-memory); `accessToken` async vì EncryptedSharedPreferences cần decrypt

### Exercise 2 — Add New Preference Key ⭐

- [ ] Key: `static const keyLanguageCode = 'languageCode'`
- [ ] Storage: `_sharedPreference` (plain) — language code non-sensitive
- [ ] Save: `Future<bool> saveLanguageCode(String code) => _sharedPreference.setString(keyLanguageCode, code)`
- [ ] Get: `String get languageCode => _sharedPreference.getString(keyLanguageCode) ?? 'en'` — sync, default `'en'`
- [ ] `clearCurrentUserData()` — **không thêm** `keyLanguageCode` (app-level setting, persist across users)
- [ ] Trả lời: `languageCode` là app setting (thiết bị) chứ không phải user preference. Logout → language giữ nguyên. Nếu cần per-user → prefix key với `userId`: `"languageCode_42"`
- [ ] **Đã revert changes**

**Cross-check [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md):**

| Rule | Expected |
|------|----------|
| Const: camelCase prefix `key` | `keyLanguageCode` ✅ |
| Method: camelCase | `saveLanguageCode` ✅ |
| Getter: camelCase | `languageCode` ✅ |

### Exercise 3 — Key Migration Strategy ⭐⭐

- [ ] Migration reads plain → saves encrypted → removes plain
- [ ] Null guard: `if (plainValue != null)` → skip nếu đã migrated hoặc chưa từng set
- [ ] `get isLoggedIn` thay đổi: `bool` (sync) → `Future<bool>` (async) — **breaking change**
- [ ] Consumers affected: mọi nơi dùng `prefs.isLoggedIn` phải thêm `await`
- [ ] `EncryptedSharedPreferences` chỉ support `String` → convert: `saveIsLoggedIn(true)` → `setString(key, 'true')`; `get isLoggedIn` → `getString(key)` then `== 'true'`
- [ ] Migration idempotent: ✅ — lần 2 chạy, plain value null → skip
- [ ] Crash safety: nếu save OK nhưng remove fail → data duplicate (cả plain lẫn encrypted) — **not data loss**, migration chạy lại sẽ overwrite encrypted (idempotent)
- [ ] Migration location: app startup, **trước** first read (ví dụ: `main()` hoặc splash screen init)
- [ ] **Đã revert changes**

### Exercise 4 — Add Encrypted Field with FlutterSecureStorage ⭐⭐

- [ ] Key: `static const keyPinCode = 'pinCode'`
- [ ] `savePinCode()` validate 6 digits: `RegExp(r'^\d{6}$').hasMatch(pin)` → throw/return early nếu invalid
- [ ] `_secureStorage.write(key: keyPinCode, value: pinCode)` — dùng secure storage (hardware-backed)
- [ ] `get pinCode` → `Future<String?>` — nullable (pin chưa set → `null`, khác `""`)
- [ ] `deletePinCode()` → `_secureStorage.delete(key: keyPinCode)`
- [ ] `clearCurrentUserData()` thêm `_secureStorage.delete(key: keyPinCode)` vào `Future.wait()`
- [ ] Trả lời nullable: `FlutterSecureStorage.read()` trả `null` nếu key không tồn tại; `EncryptedSharedPreferences.getString()` trả `""` — different semantics, check accordingly
- [ ] Trả lời tier: PIN code = sensitive credential → `_secureStorage` đúng choice (hardware-backed); `_encryptedSharedPreferences` cũng acceptable nhưng software encryption kém hơn
- [ ] Trả lời Face ID: `FlutterSecureStorage` **không yêu cầu** biometric — nó dùng Keychain. Biometric chỉ cần nếu set `IOSOptions(accessibility: .whenPasscodeSetThisDeviceOnly)` kết hợp `authenticationRequired: true`. Config hiện tại (`first_unlock`) **không cần** biometric
- [ ] **Đã revert changes**

### Exercise 5 — AI Prompt Dojo ⭐⭐⭐

- [ ] AI response cover 4 khía cạnh: security, data leak, error handling, scalability
- [ ] AI identify: `_secureStorage` unused (`// ignore: unused_field`)
- [ ] AI discuss: tokens nên dùng `FlutterSecureStorage` thay `EncryptedSharedPreferences` cho hardware-backed protection — đúng lý thuyết, nhưng migration cost + performance trade-off
- [ ] AI discuss: `clearCurrentUserData()` chỉ clear `_sharedPreference` → nếu có secure storage data thì miss
- [ ] AI suggest ≥2 improvements (examples):
  - Migrate tokens → `FlutterSecureStorage`
  - Add error handling cho encrypted write failures
  - Split `AppPreferences` thành `TokenStorage` + `UserSettings` (SRP)
  - Thêm `clearAll()` method xóa tất cả storage tiers
  - Observer pattern cho preference changes (Riverpod `StateNotifier`)
- [ ] Reflection ≥3 câu — justify đồng ý/không đồng ý
- [ ] Identify 1 actionable improvement

---

## 3. Quick Quiz

<details>
<summary>Q1: <code>SharedPreferences.getString()</code> là sync — tại sao <code>setString()</code> lại async?</summary>

`SharedPreferences` load **toàn bộ** key-value vào **in-memory HashMap** khi khởi tạo (`SharedPreferences.getInstance()`). `getString()` đọc từ HashMap → instant, sync. Nhưng `setString()` cần **write xuống disk** (XML trên Android, plist trên iOS) → I/O operation → async. Đây là pattern "sync read / async write" — optimize cho read-heavy use case (đọc token mỗi API call, viết token chỉ khi login).
</details>

<details>
<summary>Q2: Tokens lưu trong <code>EncryptedSharedPreferences</code> thay vì plain — tại sao?</summary>

Plain SharedPreferences lưu dạng **XML không mã hóa** (Android) hoặc **plist** (iOS). Trên rooted/jailbroken device, bất kỳ app nào cũng đọc được file này → **token leak**. `EncryptedSharedPreferences` encrypt value bằng **AES** trước khi lưu → ngay cả khi đọc được file, attacker chỉ thấy ciphertext. Flow: `saveAccessToken(token)` → AES encrypt → base64 encode → `SharedPreferences.setString(key, ciphertext)`. Read: `getString(key)` → base64 decode → AES decrypt → plain token.
</details>

<details>
<summary>Q3: <code>FlutterSecureStorage</code> vs <code>EncryptedSharedPreferences</code> — khi nào chọn cái nào?</summary>

**FlutterSecureStorage** dùng **hardware-backed** keystore (iOS Keychain, Android Keystore). Key material nằm trong **secure enclave** — không extract được ngay cả khi root. Chọn cho: biometric tokens, PIN codes, sensitive credentials. **EncryptedSharedPreferences** dùng **software** encryption — key lưu trong app sandbox, nhanh hơn nhưng kém an toàn hơn. Chọn cho: access/refresh tokens (cần đọc thường xuyên, trade-off performance vs security). Cả hai đều async read (cần decrypt), khác plain SharedPreferences (sync read).
</details>

<details>
<summary>Q4: <code>clearCurrentUserData()</code> dùng <code>Future.wait()</code> — tại sao không await tuần tự?</summary>

`Future.wait()` chạy tất cả remove operations **song song** → nhanh hơn sequential. Nếu 5 keys cần xóa: sequential = 5 × I/O latency, parallel ≈ 1 × I/O latency (I/O operations independent). Thêm nữa, các remove operations **không phụ thuộc nhau** (xóa key A không ảnh hưởng key B) → safe to parallelize. Pattern quan trọng: method chỉ clear **user-specific** data (tokens, userId) — **không** clear app-level settings (language, theme) vì chúng persist across users.
</details>

---

## 4. Kết nối với Modules tiếp theo

| Module tiếp | Pattern từ M14 sẽ dùng |
|------------|------------------------|
| **M15 — Capstone Login** | Full login flow: API → save tokens (`saveAccessToken`, `saveRefreshToken`) → save userId → `saveIsLoggedIn(true)`. Logout: `clearCurrentUserData()` → navigate login |
| **M16 — Popup/Dialog/Paging** | Preferences cho UI state: saved scroll position, dismissed dialogs, pagination cache |
| **M17 — Performance** | SharedPreferences read latency, encrypted storage impact on API call chain |

→ Quay lại: [00-overview.md](./00-overview.md) — tổng quan module.

---

## ➡️ Next Module

Hoàn thành Module 14! Bạn đã nắm vững local storage, SharedPreferences, Isar.

→ Tiến sang **[Module 15 — Capstone: Login Flow](../module-15-capstone-login/)** để học end-to-end login implementation combining all learned concepts.

---

## ✅ Module Complete

Hoàn thành khi:

- [ ] Self-assessment: ≥ 6/7 Yes (2/2 🔴 bắt buộc)
- [ ] Exercise 1 + 2 hoàn thành
- [ ] Quick Quiz trả lời đúng ≥ 3/4

<!-- AI_VERIFY: generation-complete -->
