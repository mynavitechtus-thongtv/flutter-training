# Verify — Capstone: Login Feature Deep Dive

> Checklist này kiểm tra kiến thức end-to-end login flow. Trả lời **không mở source code** trước, sau đó verify bằng source.

---

## Section A — Flow Understanding (8 câu)

### A1. Login button state
**Q:** `isLoginButtonEnabled` computed từ đâu? Nếu `email = "a"`, `password = ""` → button enabled hay disabled?

**Expected:** Computed getter trong `LoginState`: `email.isNotEmpty && password.isNotEmpty`. Với email="a", password="" → `false` → **disabled**.

---

### A2. Error clearing
**Q:** Khi nào `onPageError` được clear về `''`? Trace chính xác method.

**Expected:** Trong `setEmail()` và `setPassword()` — `data.copyWith(onPageError: '')`. Mỗi khi user type vào bất kỳ field nào → error cleared.

---

### A3. runCatching configuration
**Q:** Login dùng `handleErrorWhen: (_) => false`. Điều gì xảy ra nếu đổi thành `(_) => true`?

**Expected:** `BasePage.build()` listener detect `appException` change → gọi `handleException()` → `ExceptionHandler` hiện error dialog/snackbar thay vì inline red text.

---

### A4. Token storage
**Q:** Tại sao `accessToken` dùng `EncryptedSharedPreferences` nhưng `isLoggedIn` dùng `SharedPreferences` thường?

**Expected:** Token là sensitive data, cần encrypt at rest. `isLoggedIn` là plain boolean flag, được đọc synchronously bởi route guard để check auth state nhanh — `SharedPreferences.getBool()` là sync getter.

---

### A5. Navigation post-login
**Q:** Nếu dùng `push(MainRoute())` thay vì `replaceAll([MainRoute()])`, user experience khác gì?

**Expected:** `push` → login page vẫn trong stack → user back button → quay lại login page (còn form data). `replaceAll` clear stack → back → exit app. Security + UX issue nếu dùng `push`.

---

### A6. Provider type
**Q:** `loginViewModelProvider` là `StateNotifierProvider.autoDispose`. `autoDispose` có vai trò gì khi user navigate away từ LoginPage?

**Expected:** Khi không còn listener (LoginPage disposed) → provider tự dispose → `LoginViewModel.dispose()` called → state cleaned up, không memory leak. Quay lại login → fresh instance.

---

### A7. Loading overlay
**Q:** Ai trigger loading overlay? Trace từ `login()` → overlay visible.

**Expected:** `runCatching` → `showLoading()` → `state = state.copyWith(isLoading: true)` → `BasePage.build()` listener `ref.listen(provider.select((v) => v.isLoading), ...)` → `_showLoadingOverlay()` → `OverlayEntry` inserted.

---

### A8. Consumer isolation
**Q:** LoginPage có 2 `Consumer` widgets. Khi `onPageError` thay đổi, login button Consumer có rebuild không? Tại sao?

**Expected:** **Không**. Mỗi Consumer dùng `provider.select()` khác nhau — error Consumer select `value.data.onPageError`, button Consumer select `value.data.isLoginButtonEnabled`. Riverpod chỉ notify khi selected value thay đổi. `onPageError` change không affect `isLoginButtonEnabled` (trừ khi email/password cũng change).

---

## Section B — Architecture Decisions (4 câu)

### B1. State design
**Q:** Tại sao `LoginState` dùng `@Default('')` thay vì `String?` cho `onPageError`?

**Expected:** Avoid null-check tại UI layer. `onPageError.isNotEmpty` thay vì `onPageError != null && onPageError!.isNotEmpty`. Convention consistent: empty string = no error, non-empty = has error.

---

### B2. Analytics placement
**Q:** Analytics events được define ở đâu? Tại sao dùng extension thay vì method trong `AnalyticsHelper`?

**Expected:** Extension `AnalyticsHelperOnLoginPage on AnalyticsHelper` trong `login_page.dart`. Extension giữ page-specific events scope trong file, private methods không leak ra ngoài, không bloat base class.

---

### B3. Future.wait usage
**Q:** `login()` dùng `Future.wait([saveAccessToken, saveRefreshToken, saveIsLoggedIn])`. Nếu `saveRefreshToken` fail, chuyện gì xảy ra với `saveAccessToken` đã thành công?

**Expected:** `Future.wait` throw first error nhưng **tất cả futures vẫn chạy**. `saveAccessToken` đã complete thành công — data đã written. Đây là potential inconsistency: access token saved nhưng refresh token không. Production code nên consider transaction-like pattern hoặc cleanup on failure.

> 💡 **Fix hint:** Nếu `saveRefreshToken` fails sau khi `saveAccessToken` thành công → state inconsistent. Consider: (1) wrap cả hai trong transaction-like pattern, (2) nếu 1 fails → clear cả hai + retry login, hoặc (3) dùng `Future.wait([saveAccess, saveRefresh])` để fail-fast.

> ⚠️ **Codebase Limitation**: Đây không chỉ là bài tập — đây là **vấn đề thật** trong codebase. `Future.wait` partial failure có thể để lại state inconsistent. Trong production, nên wrap cả 2 save operations trong một transaction hoặc dùng rollback pattern: nếu 1 save fail → revert cái đã save thành công.

---

### B4. CommonState wrapper
**Q:** Tại sao không merge `isLoading`, `appException` vào `LoginState` trực tiếp mà phải wrap qua `CommonState`?

**Expected:** Separation of concerns: `CommonState` là framework-level state (loading, error, action tracking) — mọi page đều cần. `LoginState` là page-specific data. `BasePage` tự động handle `CommonState` fields → pages không cần duplicate logic. Thay đổi framework behavior (e.g., thêm `isRefreshing`) chỉ sửa `CommonState`, không sửa 50+ state files.

---

## Section C — Cross-Module References (4 câu)

### C1. Module mapping
**Q:** Map mỗi component sau về đúng module:

| Component | Module |
|-----------|--------|
| `@RoutePage()` | ? |
| `runCatching` | ? |
| `ref.watch()` | ? |
| `@freezed` | ? |
| `EncryptedSharedPreferences` | ? |
| `ConnectivityInterceptor` | ? |

**Expected:**
| Component | Module |
|-----------|--------|
| `@RoutePage()` | M5 (Navigation) |
| `runCatching` | M7 (BaseViewModel) |
| `ref.watch()` | M8 (Riverpod) |
| `@freezed` | M7 (BaseViewModel) |
| `EncryptedSharedPreferences` | M14 (Local Storage) |
| `ConnectivityInterceptor` | M13 (Middleware & Interceptors) |

---

### C2. Error flow trace
**Q:** Nếu API trả 401 Unauthorized, trace error từ Dio → LoginPage red text. Đi qua bao nhiêu layers?

**Expected:** Dio response → `DioExceptionMapper` maps to `RemoteException` (M13) → throw → `runCatching.catch` → wraps as `AppException` → `doOnError` callback → `data.copyWith(onPageError: e.message)` → `CommonState` update → `Consumer` rebuild → `CommonText` with red color. **4 layers**: Network → VM error boundary → State → UI.

---

### C3. Interceptor relevance
**Q:** Khi login, interceptor chain nào **có ý nghĩa** và interceptor nào **không relevant**?

**Expected:**
- **Relevant:** `CustomLogInterceptor` (log), `ConnectivityInterceptor` (check internet), `HeaderInterceptor` (device info)
- **Not relevant at login time:** `AccessTokenInterceptor` (chưa có token), `RefreshTokenInterceptor` (chưa có token to refresh)
- `BasicAuthInterceptor` — depends on API design (có thể cần cho login endpoint)

---

### C4. Hook usage
**Q:** `useScrollController()` trong LoginPage — tại sao dùng hook thay vì manual `ScrollController` + `dispose()`?

**Expected:** `BasePage` extends `HookConsumerWidget` → hooks available. `useScrollController()` tự manage lifecycle (create on build, dispose on unmount). Manual approach cần `initState` + `dispose` → nhưng `HookConsumerWidget` không có lifecycle methods như `StatefulWidget`. Hooks là idiomatic approach trong base project này.

---

## Scoring

| Section | Questions | Points |
|---------|-----------|--------|
| A: Flow Understanding | 8 | 40 |
| B: Architecture Decisions | 4 | 30 |
| C: Cross-Module References | 4 | 30 |
| **Total** | **16** | **100** |

**Pass: ≥ 70 points.** Dưới 70 → review lại [01-code-walk.md](./01-code-walk.md) và [02-concept.md](./02-concept.md).

---

## Quay lại

- [01-code-walk.md](./01-code-walk.md) — Trace toàn bộ source code
- [02-concept.md](./02-concept.md) — 7 concept patterns
- [03-exercise.md](./03-exercise.md) — Hands-on exercises

---

## ➡️ Next Module

Hoàn thành Module 15! Bạn đã nắm vững capstone login flow implementation.

→ Tiến sang **[Module 16 — Popup, Dialog & Paging](../module-16-popup-dialog-paging/)** để học dialog management, popup patterns, pagination.

<!-- AI_VERIFY: generation-complete -->
