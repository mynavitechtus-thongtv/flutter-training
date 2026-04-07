# Concepts — Local Storage & Secure Persistence

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

---

## 1. SharedPreferences — Simple Key-Value Persistence 🔴 MUST-KNOW

**WHY:** SharedPreferences là storage cơ bản nhất trên mobile — gần như mọi app đều dùng cho settings/flags. Hiểu sai sync/async behavior → crash hoặc data loss.

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
final SharedPreferences _sharedPreference;

Future<void> saveIsLoggedIn(bool isLoggedIn) async {
  await _sharedPreference.setBool(keyIsLoggedIn, isLoggedIn);
}

bool get isLoggedIn {
  return _sharedPreference.getBool(keyIsLoggedIn) ?? false;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § Flag & ID Methods](./01-code-walk.md#5-flag--id-methods--plain-storage)

**EXPLAIN:**

SharedPreferences hoạt động theo mô hình **async write, sync read**:

```
App Start:
  SharedPreferences.getInstance()     ← async, load ALL key-values into memory
  ↓
Runtime:
  .getBool('key')                     ← sync (memory lookup, microseconds)
  .setBool('key', value)              ← async (write to disk in background)
  .remove('key')                      ← async (remove from disk + memory)
```

**Limitations:**
- **Size:** Không giới hạn cứng, nhưng > 1MB performance giảm đáng kể
- **Types:** Chỉ hỗ trợ `String`, `int`, `double`, `bool`, `List<String>` — không có `Map`, `DateTime`, complex objects
- **Thread safety:** Single-process safe, nhưng **không thread-safe** cross-isolate (Dart isolates không share memory)
- **No encryption:** Values stored as **plain text** — root access / device backup → đọc được tất cả

**Platform mapping:**

| Platform | Backend | File Location |
|----------|---------|--------------|
| iOS | `NSUserDefaults` | `Library/Preferences/<bundle-id>.plist` |
| Android | `SharedPreferences` XML | `data/data/<package>/shared_prefs/*.xml` |
| Web | `localStorage` | Browser storage |

> 💡 **FE Perspective**: Tương tự `localStorage` (Web) / `AsyncStorage` (React Native). Điểm khác: Flutter **sync read** nhưng **async write** (Web localStorage sync cả hai).

**PRACTICE:** Mở [app_preferences.dart](../../base_flutter/lib/data_source/preference/app_preferences.dart). So sánh return type của `get isLoggedIn` (sync `bool`) vs `get accessToken` (async `Future<String>`). Giải thích tại sao khác nhau.

---

## 2. Encrypted Storage — EncryptedSharedPreferences 🔴 MUST-KNOW

**WHY:** Tokens, credentials, PII phải encrypted at rest. App bị sao lưu, device rooted → plain SharedPreferences bị đọc trong seconds. Encrypted storage là **baseline security** cho sensitive data.

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
_encryptedSharedPreferences = EncryptedSharedPreferences(prefs: _sharedPreference),

Future<void> saveAccessToken(String token) async {
  await _encryptedSharedPreferences.setString(keyAccessToken, token);
}

Future<String> get accessToken {
  return _encryptedSharedPreferences.getString(keyAccessToken);
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § Token Methods](./01-code-walk.md#4-token-methods--encrypted-storage)

**EXPLAIN:**

`EncryptedSharedPreferences` là **wrapper** trên `SharedPreferences`:

```
Write: value → AES encrypt → base64 encode → SharedPreferences.setString(key, encrypted)
Read:  SharedPreferences.getString(key) → base64 decode → AES decrypt → value
```

**Đặc điểm:**
- **Cùng file backend** — encryption ở application level, không phải OS level
- **Key cũng encrypted** — cả key name và value đều encrypted (tuỳ implementation)
- **Async read & write** — decryption cần compute time → `Future<String>` thay vì `String`
- **Transparent to existing code** — API giống SharedPreferences (`setString`, `getString`)

**Khi nào dùng Encrypted vs Plain?**

| Data | Encrypted? | Lý do |
|------|:----------:|-------|
| Access token | ✅ | Bearer token = full account access nếu leak |
| Refresh token | ✅ | Dùng để lấy access token mới — leak = persistent access |
| User ID | ❌ | Public identifier, non-sensitive |
| isLoggedIn | ❌ | Boolean flag, không có giá trị khai thác |
| API base URL | ❌ | Public information |
| User email/phone | ✅ | PII — GDPR/PDPA compliance |

**⚠️ Trade-off:** Encrypted read chậm hơn plain read ~10-100x. `AccessTokenInterceptor` gọi `await _appPreferences.accessToken` **mỗi API call** → latency thêm vài ms. Acceptable cho security nhưng không nên encrypt mọi thứ.

**PRACTICE:** Trace flow: login API success → save token → next API call → interceptor read token. Bao nhiêu async operations xảy ra?

> 💡 **FE Perspective**
> **Flutter:** `EncryptedSharedPreferences` — wrapper trên SharedPreferences, value được AES encrypt/base64 encode trước khi lưu. Async read & write (cần decrypt/encrypt time)
> **React/Vue tương đương:** Web: `localStorage` + manual AES encryption (`crypto-js`). React Native: `react-native-encrypted-storage`. Không có built-in encrypted storage trên Web
> **Khác biệt quan trọng:** Flutter encryption là **transparent wrapper** (cùng API `setString`/`getString`) — Web phải **tự implement** encrypt/decrypt. Web tokens thường dùng `httpOnly cookie` thay vì encrypted localStorage. Mobile có lợi thế platform-level encryption support.

---

## 3. FlutterSecureStorage — iOS Keychain & Android Keystore 🟡 SHOULD-KNOW

**WHY:** Encrypted SharedPreferences vẫn là software encryption — key management là app-level. FlutterSecureStorage tận dụng **hardware-backed keystore** → security level cao nhất trên mobile.

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
_secureStorage = const FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § Constructor](./01-code-walk.md#2-apppreferences--constructor--storage-tiers)

**EXPLAIN:**

**Platform implementation:**

| Platform | Backend | Security Level |
|----------|---------|:-------------:|
| iOS | **Keychain Services** | Hardware (Secure Enclave) |
| Android | **EncryptedSharedPreferences** (AndroidX) | Hardware (TEE/StrongBox) |
| Android (legacy) | KeyStore + AES | Hardware-backed |

**iOS Keychain Accessibility Levels:**

| Level | Nghĩa | Khi nào dùng |
|-------|--------|-------------|
| `when_unlocked` | Chỉ khi device unlocked | Highest security |
| `first_unlock` ← project dùng | Sau lần unlock đầu từ boot | Balance: push notification cần read token trước unlock |
| `always` | Luôn accessible | Background tasks, nhưng kém secure |

**Tại sao project dùng `first_unlock`?**
- Background push notification → app cần đọc token để authenticate API call
- `when_unlocked` → crash khi nhận push ở lock screen
- `always` → quá permissive, Keychain item accessible ngay cả khi device chưa từng unlock

**So sánh 3 tiers:**

| Aspect | SharedPreferences | EncryptedSharedPrefs | FlutterSecureStorage |
|--------|:---:|:---:|:---:|
| Encryption | ❌ | ✅ Software AES | ✅ Hardware-backed |
| Key storage | Plain file | App-managed | OS Keychain/Keystore |
| Rooted device | Readable | Decryptable (khó hơn) | **Protected** (hardware) |
| Backup include | ✅ | ✅ | ❌ (iOS), configurable (Android) |
| Performance | Fastest | Medium | Slowest |

**Lưu ý:** Trong project hiện tại, `_secureStorage` **chưa được sử dụng** (comment `// ignore: unused_field`). Tokens dùng `EncryptedSharedPreferences` — đủ cho hầu hết use cases. `FlutterSecureStorage` reserved cho future requirements (biometric auth, certificate pinning keys).

> 💡 **FE Perspective**
> **Flutter:** `FlutterSecureStorage` — iOS Keychain (Secure Enclave) + Android EncryptedSharedPreferences (TEE/StrongBox). Hardware-backed encryption, không được backup mặc định
> **React/Vue tương đương:** Web: **không có tương đương** — `SubtleCrypto` (Web Crypto API) cho encryption nhưng key management vẫn software-level. React Native: `react-native-keychain` → iOS Keychain + Android Keystore
> **Khác biệt quan trọng:** Mobile có **hardware-backed keystore** (Secure Enclave, TEE) — Web không có equivalent, tokens thường lưu trong `httpOnly cookie` (server-managed). Đây là lợi thế security lớn của mobile over web.

**PRACTICE:** Mở `app_preferences.dart`. `_secureStorage` chưa dùng — nếu cần lưu biometric auth token, bạn sẽ thêm methods nào? Sync hay async?

---

## 4. Security Tiers — Data Classification Matrix 🟡 SHOULD-KNOW

**WHY:** Chọn sai storage tier → hoặc security vulnerability (token plain text), hoặc over-engineering (encrypt boolean flags → latency waste). Matrix giúp quyết định nhanh.

**EXPLAIN:**

**Decision flowchart:**

```
Data cần lưu local?
    ↓
Sensitive? ─── No ──→ SharedPreferences (plain)
    │                   Examples: isLoggedIn, theme, language
   Yes
    ↓
Cần hardware protection? ─── No ──→ EncryptedSharedPreferences
    │                                Examples: tokens, session data
   Yes
    ↓
FlutterSecureStorage
    Examples: biometric keys, client certificates, payment tokens
```

**Extended matrix cho common data types:**

| Data Type | Tier | Read Frequency | Justification |
|-----------|:----:|:--------------:|---------------|
| Access token | 🔐 Encrypted | Every API call | High-value, balance perf/security |
| Refresh token | 🔐 Encrypted | On 401 only | High-value, less frequent |
| User ID | 📋 Plain | Frequent (DB queries) | Non-sensitive identifier |
| isLoggedIn | 📋 Plain | App start | Boolean, no exploit value |
| Theme preference | 📋 Plain | App start | User preference, non-sensitive |
| Biometric key | 🔒 Secure | On auth only | Requires hardware protection |
| API key (3rd party) | 🔒 Secure | Rare | Static secret, never changes |
| User email | 🔐 Encrypted | Occasional | PII, compliance requirement |

**PRACTICE:** Thêm field `lastLoginTimestamp` (DateTime dưới dạng milliseconds). Tier nào? Tại sao?

> 💡 **FE Perspective**
> **Flutter:** 3 storage tiers — Plain SharedPreferences (flags), EncryptedSharedPreferences (tokens), FlutterSecureStorage (biometric keys). Decision: sensitive? → encrypted. Cần hardware protection? → secure storage
> **React/Vue tương đương:** Web chỉ có 2 tiers: `localStorage` (plain) + manual encryption (`crypto-js`). Không có hardware-backed tier. Sensitive data → `httpOnly cookie` (server-managed)
> **Khác biệt quan trọng:** Mobile có **3 security levels rõ ràng** với hardware support — Web **không có** equivalent cho tier 3. Web dựa vào server-side security (`httpOnly`, `Secure` cookies) thay vì client-side encryption. Mobile dev cần đưa ra **đúng quyết định tier** cho từng data type.

---

## 5. AppPreferences as a Service — DI & Single Responsibility 🟡 SHOULD-KNOW

**WHY:** `AppPreferences` không phải utility class sử dụng directly — nó là **injectable service** trong DI graph. Pattern này enforce single instance, testability, loose coupling.

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
final appPreferencesProvider = Provider((ref) => getIt.get<AppPreferences>());

@LazySingleton()
class AppPreferences {
  AppPreferences(this._sharedPreference)
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § DI Registration](./01-code-walk.md#7-di-registration--lazysingleton--provider)

**EXPLAIN:**

**Dual-DI pattern:**

```
                     getIt (Injectable)
                    ╱                  ╲
        Interceptors              AppPreferences ←── SharedPreferences
        (M13)                          │
                    ╲                  ╱
                     Riverpod Provider
                         ↓
                   ViewModels / Widgets
```

**Tại sao `@LazySingleton()` chứ không phải `@Singleton()`?**
- `@Singleton()` — tạo ngay khi `getIt` init (eager)
- `@LazySingleton()` — tạo khi **first access** (lazy) → tiết kiệm startup time, chỉ init khi cần
- `AppPreferences` cần `SharedPreferences` instance → phải lazy vì `SharedPreferences.getInstance()` là async, phải resolve trước

**Single instance guarantee:**
- `getIt.get<AppPreferences>()` luôn trả **cùng instance** → data consistency
- Interceptor A save token → Interceptor B đọc token → cùng instance → guaranteed freshness

**Testability:**
```dart
// Test: mock AppPreferences
final mockPrefs = MockAppPreferences();
when(mockPrefs.accessToken).thenAnswer((_) async => 'test-token');
// Inject mock vào interceptor
final interceptor = AccessTokenInterceptor(mockPrefs);
```

> 💡 **FE Perspective**
> **Flutter:** `AppPreferences` là `@LazySingleton` injectable service, expose qua Riverpod `Provider`. Single instance guarantee cho data consistency giữa interceptors và ViewModels
> **React/Vue tương đương:** React Context + Provider pattern / Zustand store (singleton by default). Angular `@Injectable({ providedIn: 'root' })` = singleton service
> **Khác biệt quan trọng:** Flutter dùng **dual-DI** (getIt lifecycle + Riverpod access) — React/Vue thường chỉ 1 system. Flutter `@LazySingleton` = lazy init (không tạo cho đến khi cần) — React Context Provider render mỗi lần parent re-render (cần `useMemo`).

**PRACTICE:** Nếu `AppPreferences` là plain class (không DI) — interceptor và viewmodel tạo instance riêng → vấn đề gì xảy ra?

---

### Isar DB — Structured Local Database

`base_flutter` chỉ có **scaffold code** cho Isar (~15 dòng setup). Khi project cần lưu trữ structured data phức tạp (offline-first, full-text search), Isar là lựa chọn phù hợp.

<details>
<summary>📚 Đọc thêm: Isar concepts & patterns</summary>

**WHY:** SharedPreferences chỉ lưu key-value đơn giản. Khi cần query, sort, filter structured data (offline cache, user histories, complex models) → cần local database.

<!-- AI_VERIFY: base_flutter/lib/data_source/database/app_database.dart -->
```dart
@LazySingleton()
class AppDatabase {
  AppDatabase(this.appPreferences);
  final AppPreferences appPreferences;
  int get userId => appPreferences.userId;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § AppDatabase](./01-code-walk.md#8-appdatabase--isar-wrapper)

**EXPLAIN:**

**Isar quick overview:**
- **NoSQL** — schema-based collections, không có SQL tables/joins
- **Native performance** — written in Rust, compiled for each platform
- **Zero-copy reads** — data không cần deserialize khi đọc
- **Full query engine** — `where()`, `filter()`, `sortBy()`, `limit()`, indexes

**Isar vs SharedPreferences:**

| Feature | SharedPreferences | Isar |
|---------|:-:|:-:|
| Data model | `Map<String, primitive>` | Typed collections + schema |
| Query | `get(key)` only | Full query DSL |
| Relationships | ❌ | Links (1:1, 1:N) |
| Indexing | ❌ | Composite indexes |
| Watch changes | ❌ | Stream-based watchers |
| Encryption | Via wrapper | Built-in (optional) |
| Typical size | < 1 MB | GB scale |

**Project setup hints:**
- `default.isar` + `default.isar-lck` files tại project root → Isar database files
- `.isar-lck` = lock file cho concurrent access control

**Schema Migration trong Isar:**

Khi app update, schema có thể thay đổi (thêm/xóa field, đổi type). Isar xử lý migration **tự động** cho các thay đổi đơn giản:
- **Thêm field mới** → Isar tự gán default value, data cũ không bị mất
- **Xóa field** → Isar bỏ qua field cũ trong storage, không crash
- **Đổi tên field** → Isar coi như xóa field cũ + thêm field mới (data cũ mất)
- **Đổi type** (ví dụ `int` → `String`) → **không tương thích**, cần xóa collection hoặc clear database

Đối với migration phức tạp (transform data giữa versions), Isar không có built-in version migration như SQLite. Workaround: dùng `AppPreferences` lưu schema version number, check khi app start → run migration code thủ công nếu cần.

**Khi nào dùng Isar thay SharedPreferences:**
- ✅ Offline cache cho API responses (list users, products, messages)
- ✅ Search/filter locally (find user by name, filter by date)
- ✅ Large datasets (> 100 items, or items > 1KB each)
- ❌ Simple flags/tokens (overkill — dùng SharedPreferences)
- ❌ Data chỉ cần ở 1 session (dùng in-memory state)

> 💡 **FE Perspective**
> **Flutter:** Isar — NoSQL database viết bằng Rust, native performance, full query engine (`where`, `filter`, `sortBy`), stream-based watchers, optional encryption
> **React/Vue tương đương:** IndexedDB (Web) — cũng NoSQL, schema-based, async queries. React Native: Realm / WatermelonDB
> **Khác biệt quan trọng:** Isar query DSL **clean hơn nhiều** so với IndexedDB (`collection.filter().findAll()` vs `objectStore.openCursor()`). Isar native performance >> IndexedDB. Web thường dùng service worker + Cache API cho offline, mobile dùng local DB trực tiếp.

**PRACTICE:** Nếu cần cache API response `GET /v1/users` (100 items, mỗi item ~500 bytes) — SharedPreferences hay Isar? Justify.

### Decision Tree: SharedPreferences vs Isar

```
Cần lưu data local?
    ↓
Data dạng key-value đơn giản? (settings, flags, tokens)
    ├── Yes → SharedPreferences (hoặc Encrypted nếu sensitive)
    └── No  → Data có cấu trúc phức tạp?
              ├── Yes → Isar
              └── Chỉ cần cache JSON tạm → SharedPreferences + JSON string
```

| Criteria | SharedPreferences | Isar |
|----------|:-----------------:|:----:|
| **Data type** | Key-value primitives (`String`, `int`, `bool`) | Complex objects với typed schema |
| **Query** | Get by key only | Full query builder (`where`, `filter`, `sortBy`) |
| **Size** | Nhỏ (< 1MB, settings/flags) | Lớn (GB-scale, offline cache) |
| **Schema** | Không có schema | Typed schema + indexes |
| **Relationships** | ❌ | Links (1:1, 1:N) |
| **Watch changes** | ❌ | Stream-based watchers |
| **Setup** | Gần zero-config | Cần schema + code-gen |
| **Use case** | Auth state, preferences, small configs | Offline data cache, search, structured storage |

</details>

---

## 7. Logout & Clear Data Pattern 🟢 AI-GENERATE

**WHY:** Logout không chỉ là navigate về login screen — phải clear **tất cả** user-specific data. Miss một key → data leak giữa accounts, hoặc stale token gây 401 loop.

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
Future<void> clearCurrentUserData() async {
  await Future.wait([
    _sharedPreference.remove(keyAccessToken),
    _sharedPreference.remove(keyRefreshToken),
    _sharedPreference.remove(keyUserId),
    _sharedPreference.remove(keyIsLoggedIn),
  ]);
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § Logout Cleanup](./01-code-walk.md#6-clearcurrentuserdata--logout-cleanup)

**EXPLAIN:**

**Logout cleanup checklist — what to clear:**

| Layer | Action | Method |
|-------|--------|--------|
| Preferences | Remove user keys | `clearCurrentUserData()` |
| Database | Delete user-specific data | `appDatabase.clearUserData()` (if exists) |
| In-memory state | Reset Riverpod providers | `ref.invalidate(userProvider)` |
| API client | Cancel pending requests | `dio.close()` hoặc cancel tokens |
| Navigation | Pop to login | `router.replaceAll([LoginRoute()])` |
| Firebase | Unsubscribe topics | `messaging.unsubscribeFromTopic(userId)` |

**`Future.wait()` pattern:**
```dart
// ✅ Parallel (fast) — project pattern
await Future.wait([remove(a), remove(b), remove(c)]);

// ❌ Sequential (slow) — 3x latency
await remove(a);
await remove(b);
await remove(c);
```

**Selective vs Full clear:**
- `_sharedPreference.remove(key)` — selective, chỉ xóa user session keys
- `_sharedPreference.clear()` — xóa **tất cả** → mất cả app settings (theme, language, onboarding)
- Project chọn **selective** → đúng choice cho multi-concern storage

**PRACTICE:** Thêm `keyThemeMode` (app-level, không phải user-level). `clearCurrentUserData()` có nên xóa key này không? Tại sao?

---

> 📋 Badge summary → xem [00-overview.md](./00-overview.md)

→ Tiếp tục: [03-exercise.md](./03-exercise.md) — thực hành qua 5 bài tập.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
