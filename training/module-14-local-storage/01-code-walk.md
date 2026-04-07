# Code Walk — Local Storage: AppPreferences & AppDatabase

> 📌 **Recap từ modules trước:**
> - **M12:** `AppApiService` facade, data layer structure — `lib/data_source/` chia thành `api/`, `preference/`, `database/`, `firebase/` ([M12 § code-walk](../module-12-data-layer/01-code-walk.md))
> - **M13:** Interceptor chain, token management — `AccessTokenInterceptor` đọc token từ `AppPreferences`, `RefreshTokenInterceptor` save token mới sau refresh ([M13 § code-walk](../module-13-middleware-interceptor-chain/01-code-walk.md))
>
> Nếu chưa nắm vững → quay lại [Module 12](../module-12-data-layer/) hoặc [Module 13](../module-13-middleware-interceptor-chain/) trước.

---

## Walk Order

```
Data Layer Structure (bird's-eye view)
    ↓
AppPreferences — Constructor & 3 Storage Tiers
    ↓
Keys & Security Classification
    ↓
Token Methods (encrypted) — saveAccessToken / get accessToken
    ↓
Flag Methods (plain) — saveIsLoggedIn / get isLoggedIn
    ↓
ID Methods (plain) — saveUserId / get userId
    ↓
clearCurrentUserData() — Logout Cleanup
    ↓
DI Registration — @LazySingleton + Provider
    ↓
AppDatabase — Isar Wrapper
    ↓
Consumer Integration — AccessTokenInterceptor reads from AppPreferences
```

Bắt đầu từ **big picture** → **constructor** phân tích 3 storage tier → **methods** theo security level → **DI** → **database** → **integration point**.

---

## 1. Data Source Layer — Bird's-Eye View

```
lib/data_source/
├── preference/
│   └── app_preferences.dart    ← SharedPreferences + Encrypted + Secure (M14)
├── database/
│   └── app_database.dart       ← Isar DB wrapper (M14)
├── api/                        ← RestApiClient, interceptors (M12/M13)
└── firebase/                   ← FCM, Crashlytics (other modules)
```

Module 12 cover `api/`. Module 14 focus vào **`preference/`** và **`database/`** — hai cơ chế persistence chính cho local data.

**Tại sao cần local storage?**
- **Token persistence:** User login → save token → app restart → vẫn authenticated
- **User flags:** `isLoggedIn`, dark mode, onboarding completed, language preference
- **Offline data:** Cache API responses cho offline-first UX
- **Performance:** Đọc preference nhanh hơn API call (microseconds vs milliseconds)

---

## 2. AppPreferences — Constructor & Storage Tiers

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../index.dart';

final appPreferencesProvider = Provider((ref) => getIt.get<AppPreferences>());

@LazySingleton()
class AppPreferences {
  AppPreferences(this._sharedPreference)
      : _encryptedSharedPreferences = EncryptedSharedPreferences(prefs: _sharedPreference),
        _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  final SharedPreferences _sharedPreference;
  final EncryptedSharedPreferences _encryptedSharedPreferences;
  // ignore: unused_field
  final FlutterSecureStorage _secureStorage;
```
<!-- END_VERIFY -->

**Key observations:**

**Constructor pattern — 1 input, 3 tiers:**
- Parameter: `SharedPreferences` — injected qua DI (registered elsewhere khi app bootstrap)
- `_encryptedSharedPreferences` — tạo từ `SharedPreferences` instance (wrapper, cùng underlying storage nhưng values encrypted)
- `_secureStorage` — tạo mới, **hoàn toàn tách biệt** SharedPreferences (iOS: Keychain, Android: EncryptedSharedPreferences native)

**3 Storage Tiers:**

| Tier | Field | Backend | Use Case |
|:----:|-------|---------|----------|
| 1 — Plain | `_sharedPreference` | NSUserDefaults (iOS) / SharedPreferences (Android) | Non-sensitive flags: `isLoggedIn`, `userId` |
| 2 — Encrypted | `_encryptedSharedPreferences` | Same file nhưng value encrypted (AES) | Sensitive nhưng cần read thường xuyên: tokens |
| 3 — Secure | `_secureStorage` | iOS Keychain / Android EncryptedSharedPreferences | High-security: biometric-protected data, API keys |

**Platform-specific config:**
- `AndroidOptions(encryptedSharedPreferences: true)` — dùng Android `EncryptedSharedPreferences` (AES-256 GCM) thay vì deprecated KeyStore approach
- `IOSOptions(accessibility: KeychainAccessibility.first_unlock)` — Keychain item accessible sau lần unlock đầu tiên (cân bằng giữa security và usability — app cold start trước khi user unlock không đọc được)

> 💡 **FE Perspective**
> **Flutter:** 3 storage tiers trong 1 class — `SharedPreferences` (plain), `EncryptedSharedPreferences` (AES wrapper), `FlutterSecureStorage` (iOS Keychain / Android Keystore)
> **React/Vue tương đương:** `localStorage` (plain) / `localStorage` + `crypto-js` (encrypted) / **không có tương đương** hardware-backed trên Web. React Native: `AsyncStorage` / `react-native-encrypted-storage` / `react-native-keychain`
> **Khác biệt quan trọng:** Web `localStorage` **không encrypted** — tokens trên web thường dùng `httpOnly cookie` thay vì localStorage. Mobile có hardware-backed keystore nên secure storage khả thi hơn.

---

## 3. Keys — Security Classification

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
  // keys should be removed when logout
  static const keyAccessToken = 'accessToken';
  static const keyRefreshToken = 'refreshToken';
  static const keyUserId = 'userId';
  static const keyIsLoggedIn = 'isLoggedIn';
```
<!-- END_VERIFY -->

**Phân loại bảo mật:**

| Key | Storage Tier | Lý do |
|-----|:----------:|-------|
| `accessToken` | 🔐 Encrypted | Token ngắn hạn, đọc **mỗi API call** (interceptor) → cần nhanh nhưng vẫn encrypted |
| `refreshToken` | 🔐 Encrypted | Token dài hạn, đọc ít hơn (chỉ khi 401) → encrypted |
| `userId` | 📋 Plain | Non-sensitive identifier, đọc **sync** → plain SharedPreferences |
| `isLoggedIn` | 📋 Plain | Boolean flag, non-sensitive → plain SharedPreferences |

**Comment `// keys should be removed when logout`** → documentation cho `clearCurrentUserData()` — tất cả keys trên đều là user-session data, logout phải xóa.

**Static const pattern:**
- Keys là `static const` → không cần instance, accessible cho testing
- Naming convention: `key` prefix + camelCase → dễ tìm, autocomplete friendly

---

## 4. Token Methods — Encrypted Storage

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
  Future<void> saveAccessToken(String token) async {
    await _encryptedSharedPreferences.setString(
      keyAccessToken,
      token,
    );
  }

  Future<String> get accessToken {
    return _encryptedSharedPreferences.getString(keyAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _encryptedSharedPreferences.setString(
      keyRefreshToken,
      token,
    );
  }

  Future<String> get refreshToken {
    return _encryptedSharedPreferences.getString(keyRefreshToken);
  }
```
<!-- END_VERIFY -->

**Key observations:**

- **Cả save và get đều `Future`** — encrypted storage operations are async (encryption/decryption I/O)
- `saveAccessToken` → `Future<void>` — caller phải `await` để đảm bảo write hoàn tất
- `get accessToken` → `Future<String>` — caller phải `await` khi đọc

**So sánh với plain storage (section 5):**

| Aspect | Encrypted Token | Plain Flag |
|--------|:--------------:|:---------:|
| Save | `Future<void>` (async) | `Future<bool>` (async write) |
| Read | `Future<String>` (async decrypt) | `bool` (**sync** read) |
| Null handling | Returns `""` (empty string) | Returns default via `?? false` |

→ Encrypted read is **async** (decryption overhead). Plain read is **sync** (in-memory cache của SharedPreferences).

**Kết nối M13 — AccessTokenInterceptor:**

```dart
// Từ access_token_interceptor.dart (M13)
class AccessTokenInterceptor extends BaseInterceptor {
  AccessTokenInterceptor(this._appPreferences) : super(InterceptorType.accessToken);
  final AppPreferences _appPreferences;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _appPreferences.accessToken;  // ← async read từ encrypted storage
    if (token.isNotEmpty) {
      options.headers[Constant.basicAuthorization] = '${Constant.bearer} $token';
    }
    handler.next(options);
  }
}
```

→ `onRequest` phải là **`Future<void>`** vì `_appPreferences.accessToken` trả `Future<String>`. Interceptor `await` token → gắn `Bearer` header → `handler.next()`.

→ Forward ref **M15 (Capstone Login):** Login flow sẽ gọi `saveAccessToken()` + `saveRefreshToken()` sau khi nhận response từ login API.

---

## 5. Flag & ID Methods — Plain Storage

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
  Future<void> saveIsLoggedIn(bool isLoggedIn) async {
    await _sharedPreference.setBool(keyIsLoggedIn, isLoggedIn);
  }

  bool get isLoggedIn {
    return _sharedPreference.getBool(keyIsLoggedIn) ?? false;
  }

  Future<bool> saveUserId(int userId) {
    return _sharedPreference.setInt(keyUserId, userId);
  }

  int get userId {
    return _sharedPreference.getInt(keyUserId) ?? -1;
  }
```
<!-- END_VERIFY -->

**Observations:**

**Sync read cho plain storage:**
- `isLoggedIn` → `bool` (sync, not `Future<bool>`)
- `userId` → `int` (sync)
- Lý do: `SharedPreferences` load tất cả key-value vào memory khi `getInstance()` → subsequent reads là memory lookup, không cần async

**Async write:**
- `saveIsLoggedIn` → `Future<void>` (write to disk is async)
- `saveUserId` → `Future<bool>` (returns success/failure)
- Pattern: SharedPreferences write operations luôn async — flush to disk happens asynchronously

**Default values pattern:**
- `?? false` cho bool → safe default: chưa login
- `?? -1` cho int → invalid sentinel value: chưa có userId

**Return type inconsistency — intentional:**
- `saveIsLoggedIn` → `Future<void>` — caller không cần biết success/fail (fire-and-forget vibes)
- `saveUserId` → `Future<bool>` — caller có thể check success (nhưng thực tế ít khi check)
- Cả hai pattern đều acceptable — team convention

---

## 6. clearCurrentUserData() — Logout Cleanup

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
  Future<void> clearCurrentUserData() async {
    await Future.wait(
      [
        _sharedPreference.remove(keyAccessToken),
        _sharedPreference.remove(keyRefreshToken),
        _sharedPreference.remove(keyUserId),
        _sharedPreference.remove(keyIsLoggedIn),
      ],
    );
  }
}
```
<!-- END_VERIFY -->

**Key patterns:**

- **`Future.wait()`** — parallel removal, không sequential → nhanh hơn 4 lần `await` riêng lẻ
- **Explicit keys** — chỉ xóa 4 keys liên quan user session, **không xóa hết** `_sharedPreference.clear()` → bảo toàn app-level settings (theme, language, onboarding flag nếu có)
- **Dùng `_sharedPreference.remove()`** cho tất cả keys — kể cả token keys đã save qua `_encryptedSharedPreferences`. Điều này hoạt động vì `EncryptedSharedPreferences` là wrapper trên cùng `SharedPreferences` instance → `remove()` xóa cả raw key

**⚠️ Observation:** `clearCurrentUserData()` chỉ xóa qua `_sharedPreference` — nếu tương lai có data save qua `_secureStorage` (FlutterSecureStorage) thì cần thêm `_secureStorage.delete(key: ...)` vào đây. Hiện tại `_secureStorage` chưa được dùng (đã thấy `// ignore: unused_field`).

> 💡 **FE Perspective**
> **Flutter:** `clearCurrentUserData()` dùng `Future.wait()` xóa parallel các session keys. Selective remove (không clear hết) — giữ app-level settings
> **React/Vue tương đương:** Web `localStorage.removeItem('key')` hoặc `localStorage.clear()`. React Native `AsyncStorage.multiRemove([...])` — tương tự `Future.wait()` pattern
> **Khác biệt quan trọng:** Nếu dùng `httpOnly cookie` trên Web → **server phải invalidate** (client không xóa được). Mobile kiểm soát toàn bộ client-side. Common pitfall: quên clear cached data ngoài token → user B thấy data user A.

---

## 7. DI Registration — @LazySingleton + Provider

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->
```dart
final appPreferencesProvider = Provider((ref) => getIt.get<AppPreferences>());

@LazySingleton()
class AppPreferences {
  AppPreferences(this._sharedPreference)
```
<!-- END_VERIFY -->

**DI pattern — dual registration:**

1. **Injectable `@LazySingleton()`** — `getIt.get<AppPreferences>()` cho non-Riverpod consumers (interceptors, services)
2. **Riverpod `Provider`** — `appPreferencesProvider` cho widget/viewmodel layer

**Tại sao cả hai?**
- Interceptors (M13) registered bằng `getIt` → cần access `AppPreferences` qua `getIt`
- ViewModels/Widgets dùng Riverpod → access qua `ref.read(appPreferencesProvider)`
- `appPreferencesProvider` delegate sang `getIt` → single instance, shared across both DI systems

**Constructor injection — SharedPreferences:**
- `AppPreferences(this._sharedPreference)` — `SharedPreferences` instance injected
- `SharedPreferences.getInstance()` called once during app bootstrap, registered vào `getIt` → injectable cung cấp cho `AppPreferences` constructor

---

## 8. AppDatabase — Isar Wrapper 🟢 AI-GENERATE

<!-- AI_VERIFY: base_flutter/lib/data_source/database/app_database.dart -->
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../index.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => getIt.get<AppDatabase>());

@LazySingleton()
class AppDatabase {
  AppDatabase(this.appPreferences);

  final AppPreferences appPreferences;

  int get userId => appPreferences.userId;
}
```
<!-- END_VERIFY -->

**Observations:**

- **Minimal wrapper:** 15 lines — hiện tại `AppDatabase` chỉ delegate `userId` từ `AppPreferences`
- **Isar integration implied:** Project root có `default.isar` + `default.isar-lck` files → Isar database đang được dùng, nhưng schema/collection chưa defined (placeholder cho future development)
- **Same DI pattern:** `@LazySingleton()` + Riverpod `Provider` — consistent với `AppPreferences`
- **Dependency:** `AppDatabase` nhận `AppPreferences` qua constructor → cùng `getIt` dependency graph

**SharedPreferences vs Isar — khi nào dùng gì:**

| Criteria | SharedPreferences | Isar |
|----------|:----------------:|:----:|
| Data structure | Key-value (flat) | Collections/objects (structured) |
| Query capability | Get by key only | Full query engine, indexes, sort |
| Data volume | Small (< 1MB recommended) | Large (MB–GB) |
| Use case | Settings, tokens, flags | Offline cache, user data, complex models |
| Read performance | Sync (in-memory) | Async (but very fast — native) |

> 💡 **FE Perspective**
> **Flutter:** Isar — NoSQL native (Rust), full query engine, zero-copy reads. `collection.where().findAll()` DSL
> **React/Vue tương đương:** IndexedDB (Web) — NoSQL, schema-based, async. React Native: Realm / WatermelonDB
> **Khác biệt quan trọng:** Isar native performance >> IndexedDB. Isar query DSL clean (`collection.filter().findAll()`) — IndexedDB verbose (`objectStore.openCursor()`). Web thường dùng service worker + Cache API hơn là IndexedDB trực tiếp.

> ℹ️ **NOTE:** Codebase hiện tại chỉ scaffold `AppDatabase` — Isar collections chưa được định nghĩa, không có schema hay query nào trong project. Khi project cần offline cache cho structured data (e.g., user profiles, chat history, offline queue), Isar sẽ được integrate tại đây.

> 💡 **FE Perspective — Storage Decision Matrix**
>
> | Nhu cầu | Flutter | Web / React |
> |---------|---------|-------------|
> | Key-value đơn giản | `SharedPreferences` | `localStorage` |
> | Key-value encrypted | `EncryptedSharedPreferences` | `httpOnly cookie` / manual AES |
> | Secrets (tokens) | `FlutterSecureStorage` (Keychain/Keystore) | `httpOnly secure cookie` |
> | Structured data + queries | **Isar** / Hive / Drift | IndexedDB / Dexie.js |
> | Full offline-first | Isar + sync engine | IndexedDB + service worker |

---

## 9. Integration Map — Ai dùng AppPreferences?

```
┌─────────────────────────────────────────────────┐
│                  App Bootstrap                   │
│  SharedPreferences.getInstance() → getIt.register│
│                      ↓                           │
│              AppPreferences(@LazySingleton)       │
│         ┌──────────┼──────────────┐              │
│         ↓          ↓              ↓              │
│  AccessToken    RefreshToken    AppDatabase       │
│  Interceptor    Interceptor    (userId proxy)     │
│  (M13: read     (M13: save     (M14)             │
│   token for      new tokens                      │
│   Bearer header) after refresh)                  │
│         ↓          ↓              ↓              │
│      API calls  Token refresh   DB queries       │
│                      ↓                           │
│              Login Flow (M15)                    │
│  saveAccessToken + saveRefreshToken + saveUserId │
│  saveIsLoggedIn(true)                            │
│                      ↓                           │
│              Logout Flow                         │
│  clearCurrentUserData() → remove all 4 keys     │
└─────────────────────────────────────────────────┘
```

→ `AppPreferences` là **central preference hub** — interceptors (M13), database (M14), login/logout (M15) đều phụ thuộc vào nó.

---

## 10. Full File Summary

| Line | Section | Pattern |
|:----:|---------|---------|
| 1-7 | Imports | 3 storage packages + Riverpod + Injectable |
| 9 | Provider | `appPreferencesProvider` — Riverpod bridge to getIt |
| 11-12 | Class + Annotation | `@LazySingleton()` + `AppPreferences` |
| 13-21 | Constructor | 1 param → 3 storage tiers (plain, encrypted, secure) |
| 23-26 | Fields | 3 private storage instances |
| 28-33 | Keys | 4 static const keys + security note |
| 35-41 | saveAccessToken | Encrypted write (async) |
| 43-45 | get accessToken | Encrypted read (async) |
| 47-49 | saveIsLoggedIn | Plain write (async) |
| 51-53 | get isLoggedIn | Plain read (**sync**) |
| 55-62 | saveRefreshToken | Encrypted write (async) |
| 64-66 | get refreshToken | Encrypted read (async) |
| 68-70 | saveUserId | Plain write (async) |
| 72-74 | get userId | Plain read (**sync**) |
| 76-84 | clearCurrentUserData | `Future.wait()` parallel remove |

**Đọc thêm:**
- [app_preferences.dart](../../base_flutter/lib/data_source/preference/app_preferences.dart) — full source (84 lines)
- [app_database.dart](../../base_flutter/lib/data_source/database/app_database.dart) — Isar wrapper (15 lines)
- [access_token_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/access_token_interceptor.dart) — consumer of AppPreferences (19 lines)
- [refresh_token_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/refresh_token_interceptor.dart) — consumer of AppPreferences (140 lines)

→ Tiếp tục: [02-concept.md](./02-concept.md) — 7 concepts trích từ code walk.

<!-- AI_VERIFY: generation-complete -->
