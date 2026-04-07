# Exercises — Capstone: Login Feature Deep Dive

> ⚠️ Exercise 1–3 dùng mock API để focus vào logic. **Exercise 4 (Real API)** yêu cầu bạn switch sang real API endpoint để trải nghiệm full interceptor chain — đây là phần quan trọng nhất của module này.

📌 **Recap:** M7 (BasePage/BaseViewModel) · M8 (Riverpod) · M9 (Page structure) · M12 (Data layer) · M13 (Interceptor chain) · M14 (Local storage)

---

## Exercise 1 — ⭐ Trace Login Flow (Đọc hiểu + Diagram)

<!-- AI_VERIFY: exercise-1 -->

Trace end-to-end flow qua actual source files.

### Task 1.1: Flow Trace Table

Tạo file `analysis/login_flow_trace.md`, điền cột **File** và **Line (approx)**:

| Step | Action | File | Line (approx) | Module |
|------|--------|------|----------------|--------|
| 1 | User nhập email | `login_page.dart` | ? | M9 |
| 2 | `setEmail()` called | `login_view_model.dart` | ? | M7 |
| 3 | State updated, `onPageError` cleared | `login_view_model.dart` | ? | M8 |
| 4 | `isLoginButtonEnabled` recalculated | `login_state.dart` | ? | M8 |
| 5 | Consumer rebuild login button | `login_page.dart` | ? | M9 |
| 6 | User taps Login | `login_page.dart` | ? | M9 |
| 7 | Analytics event logged | `login_page.dart` | ? | — |
| 8 | `login()` called | `login_view_model.dart` | ? | M7 |
| 9 | `runCatching` starts, `showLoading()` | `base_view_model.dart` | ? | M7 |
| 10 | API call (mocked) | `login_view_model.dart` | ? | M12 |
| 11 | `saveAccessToken()` | `app_preferences.dart` | ? | M14 |
| 12 | `replaceAll([MainRoute()])` | `login_view_model.dart` | ? | M5 |

### Task 1.2: Error Path Diagram

Vẽ diagram cho **error path**: API error → `doOnError` → `onPageError` → Consumer rebuild → red text → user types → error cleared.

### Acceptance Criteria
- [ ] 12 rows điền đủ file path + line number
- [ ] Error path diagram ≥ 6 steps

---

## Exercise 2 — ⭐⭐ Remember Me Feature

<!-- AI_VERIFY: exercise-2 -->

Extend login flow: "Remember Me" checkbox + form validation + persist preference.

### Requirements

1. `LoginState` += `isRememberMe` field (bool, default false)
2. `LoginViewModel` += `toggleRememberMe()`, `validateEmail()`, `validatePassword()`
3. Login thành công + remember me → save email encrypted (`AppPreferences`)
4. LoginPage init → pre-fill saved email
5. UI: Checkbox + field-specific errors dưới mỗi `PrimaryTextField`
6. **Validation:** email regex, password min 8 chars + ≥1 uppercase + ≥1 digit
7. Disable login button khi có validation error

### Files cần sửa

- `login_state.dart` — thêm fields
- `login_view_model.dart` — thêm methods
- `app_preferences.dart` — thêm `saveRememberEmail` / `removeRememberEmail`
- `login_page.dart` — thêm Checkbox widget

<details>
<summary>💡 Gợi ý (mở khi stuck > 15 phút)</summary>

- Thêm field vào State, dùng `copyWith` để toggle
- Lưu email vào `EncryptedSharedPreferences` (PII)
- UI: `Consumer` + `Checkbox` bind vào state field
- Validation: email format check + password length/complexity check

</details>

### Acceptance Criteria
- [ ] `LoginState` có `isRememberMe` field
- [ ] Checkbox hoạt động toggle đúng
- [ ] Login thành công + remember me → email saved encrypted
- [ ] Mở lại app → email pre-filled
- [ ] Uncheck remember me → email cleared from storage
- [ ] Email validation + password validation hiển thị error inline

---

## Exercise 3 — ⭐⭐ Error Handling Variants

<!-- AI_VERIFY: exercise-3 -->

Hiểu sâu `runCatching` bằng cách thay đổi error handling strategy.

### Task 3.1: Dialog Error thay vì Inline Error

Chuyển login error handling từ inline error (`doOnError` + `onPageError`) sang dialog error (`handleErrorWhen: (_) => true`).

**Phân tích:**
- Khi `handleErrorWhen: (_) => true`, flow đi qua đâu trong `BasePage`?
- Dialog error có tự clear khi user type không?
- Khi nào nên dùng dialog vs inline error?

### Task 3.2: Retry with Different Max Retries

Thêm retry logic cho login API call — retry chỉ cho network errors, max 3 lần.

**Phân tích:**
- Trace `runCatching` source — khi nào `onRetry` callback được gọi?
- Tại sao chỉ retry cho network error?
- `maxRetries: null` thì behavior thế nào?

### Acceptance Criteria
- [ ] Task 3.1: Login dùng dialog error, trace được flow qua `BasePage.handleException`
- [ ] Task 3.2: Trả lời 3 câu hỏi analysis kèm line references
- [ ] Viết comparison table: inline vs dialog vs retry

---

## Exercise 4 — ⭐⭐ Real API Integration: Full Interceptor Chain 🔥

<!-- AI_VERIFY: exercise-4-real-api -->

> 🚀 **Đây là exercise cốt lõi của M15.** Bạn sẽ switch từ mock sang real API và trải nghiệm full interceptor chain — thứ mà mock KHÔNG BAO GIỜ trigger được.

### Bối cảnh

Trong production, login flow đi qua **7 interceptors** trước khi đến server và khi quay về. Mock bypass toàn bộ chain này → bạn không thấy được:
- `ConnectivityInterceptor` reject request khi mất mạng
- `AccessTokenInterceptor` gắn Bearer token
- `RefreshTokenInterceptor` auto refresh khi 401
- `RetryOnErrorInterceptor` retry khi timeout
- Error mapping từ HTTP status → `AppException`

### Task 4.1: Cấu hình Real API Endpoint

> 💡 **Chọn 1 trong 3 options tuỳ môi trường:**
>
> | Option | Khi nào dùng | Setup |
> |--------|-------------|-------|
> | **A. reqres.in** (Recommended) | Không có backend riêng. Public mock API, free, no signup | `APP_DOMAIN` = `https://reqres.in` |
> | **B. Project API** | Team đã có staging API | `APP_DOMAIN` = URL staging API thật |
> | **C. Local mock** | Khi cần custom responses | Chạy local server (xem hướng dẫn bên dưới) |
>
> **Option A — reqres.in (quickstart):**
> - Login: `POST https://reqres.in/api/login` với body `{"email": "eve.holt@reqres.in", "password": "cityslicka"}` → returns `{"token": "QpwL5tke4Pnpja7X4"}`
> - Login fail: dùng email/password sai → returns `400 {"error": "user not found"}`
> - ⚠️ reqres.in không có refresh token endpoint → Task 4.4 (Token Refresh) cần dùng Option B hoặc C
> - Bạn cần tạo adapter mapping `reqres.in` response sang app's expected format
>
> ⚠️ **Lưu ý**: `reqres.in` trả response format khác với standard REST API (e.g., token nằm trực tiếp trong body thay vì wrapped trong `data` field). Cần đọc kỹ [reqres.in docs](https://reqres.in/) để adjust `ApiDecoder` hoặc response model cho phù hợp.

1. Mở `dart_defines/develop.json`, thêm `APP_DOMAIN`:
   ```json
   { "FLAVOR": "develop", "APP_DOMAIN": "https://reqres.in" }
   ```

2. Trong `login_view_model.dart`, uncomment real API call:
   ```dart
   final response = await _ref.read(appApiServiceProvider).login(
     email: email,
     password: data.password,
   );
   ```

3. Thay hardcoded tokens bằng response data:
   ```dart
   await Future.wait([
     _ref.read(appPreferencesProvider).saveAccessToken(response.data?.accessToken ?? ''),
     _ref.read(appPreferencesProvider).saveRefreshToken(response.data?.refreshToken ?? ''),
     _ref.read(appPreferencesProvider).saveIsLoggedIn(true),
   ]);
   ```

4. Chạy app:
   ```bash
   flutter run --dart-define-from-file=dart_defines/develop.json
   ```

### Task 4.2: Happy Path — Login Thành Công

1. Nhập valid credentials → tap Login
2. Mở DevTools / terminal → quan sát log từ `CustomLogInterceptor`:
   - Request: method, URL, headers (có Bearer token không?)
   - Response: status code, body
3. Verify: tokens được save vào `EncryptedSharedPreferences`, navigate đến home

### Task 4.3: Error Path — Invalid Credentials (401/403)

1. Nhập email/password sai → tap Login
2. Quan sát:
   - HTTP status code trả về là gì?
   - `DioException` được map thành `AppException` loại nào?
   - Error message hiển thị cho user từ đâu?
3. Trace flow: `DioException` → interceptor chain → `runCatching` → `doOnError` → `onPageError`

### Task 4.4: Token Refresh Flow (401 → Refresh → Retry)

> Đây là flow phức tạp nhất — mock không bao giờ trigger được.

1. Login thành công → nhận tokens
2. Giả lập token expired (tuỳ chọn):
   - **Cách 1:** Chờ token tự expire (nếu API có short-lived tokens)
   - **Cách 2:** Manually sửa saved token thành invalid string qua DevTools
   - **Cách 3:** Gọi một authenticated API endpoint sau khi xoá token khỏi storage
3. Trigger một API call → quan sát log:
   - Request đầu tiên → 401
   - `RefreshTokenInterceptor` bắt 401 → gọi refresh endpoint
   - Nhận new tokens → save → retry original request
   - Response trả về bình thường → **user không biết refresh đã xảy ra**
4. Trả lời: nếu refresh token cũng expired thì flow đi đâu?

### Task 4.5: Network Error — Airplane Mode

1. Bật Airplane mode (hoặc tắt WiFi)
2. Tap Login → quan sát:
   - `ConnectivityInterceptor` reject request ngay lập tức hay Dio timeout?
   - Error message hiển thị cho user là gì?
   - Có retry tự động không?
3. Bật lại network → tap Login lại → verify app recover bình thường

<details>
<summary>💡 Gợi ý (mở khi stuck > 15 phút)</summary>

- `Env.appDomain` đọc từ `--dart-define` → check `env.dart` và `constant.dart`
- Login API endpoint thường là `POST /api/auth/login` — kiểm tra `AppApiService` definition
- Log interceptor output xem trong terminal (Debug Console) hoặc DevTools Logging tab
- Token refresh: xem `RefreshTokenInterceptor._onExpiredToken()` — nó queue requests và retry sau refresh
- Network error: `ConnectivityInterceptor` check trước khi gửi request, `RetryOnErrorInterceptor` retry khi timeout

</details>

### Acceptance Criteria
- [ ] App hit real API endpoint (không phải mock)
- [ ] Login với valid credentials → nhận token → navigate to home
- [ ] Login với invalid credentials → hiển thị error dialog/message
- [ ] Token expired → automatic refresh → không interrupt user
- [ ] No network → hiển thị error message phù hợp
- [ ] Giải thích được flow khi refresh token cũng expired
- [ ] Chụp screenshot/log của ít nhất 3 scenarios: success, invalid credentials, network error

---

## Exercise 5 — ⭐⭐ Trace Logout Flow 🔍

<!-- AI_VERIFY: exercise-5 -->

> 📝 Đây là exercise trace code — không cần viết code mới, chỉ cần đọc hiểu flow.

**Objective:** Hiểu complete logout flow từ UI → data cleanup → navigation.

**Steps:**

1. Tìm logout button trong `SettingsPage` (hoặc drawer). Nó gọi method nào?
2. Trace qua ViewModel: logout method thực hiện những bước gì?
3. Token cleanup: method nào dùng để xóa (`delete` vs `deleteAll`)?
4. Navigation: sau logout, navigate bằng cách nào?
5. Edge case: API logout fail → app vẫn logout locally hay show error?

**Deliverable:** Viết 1 đoạn mô tả ngắn (5-7 câu) giải thích complete logout flow.

### Acceptance Criteria
- [ ] Trace được logout trigger point trong UI
- [ ] Mô tả đúng thứ tự cleanup steps
- [ ] Xác định navigation method
- [ ] Trả lời edge case: API fail behavior
- [ ] Deliverable: đoạn mô tả 5-7 câu

---

## Exercise 6 — ⭐⭐⭐ Implement Forgot Password Flow

<!-- AI_VERIFY: exercise-6 -->

Build feature mới: `ForgotPasswordPage` / `ViewModel` / `State` theo login pattern.

### Requirements

- Tạo 3 files trong `lib/ui/page/forgot_password/`: page + `view_model/` (state + VM)
- Flow: nhập email → tap Reset → mock API call → success/error UI
- Thêm `ForgotPasswordRoute` + link từ LoginPage
- Follow đúng pattern: `BasePage` / `BaseViewModel` / `BaseState` + Freezed
- `runCatching` cho API call, error handling giống login

### Acceptance Criteria
- [ ] 3 files đúng structure, extends `BasePage`/`BaseViewModel`/`BaseState`
- [ ] `runCatching` pattern đúng
- [ ] Error → red text, success → green text hoặc navigation
- [ ] `build_runner build` pass
- [ ] Route accessible từ LoginPage

<details>
<summary>💡 Gợi ý (mở khi stuck > 15 phút)</summary>

- Copy toàn bộ login pattern 1:1 → thay field names + logic
- State: `email`, `onPageError`, `isSuccess` fields
- ViewModel: `setEmail()` + `resetPassword()` methods
- Page: `@RoutePage()` + extends `BasePage<ForgotPasswordState, ...>`
- Route: `AutoRoute(page: ForgotPasswordRoute.page)` trong `app_router.dart`
- Chạy `dart run build_runner build` sau khi thêm `@RoutePage()` + `@freezed`

</details>

---

## Exercise 7 — ⭐⭐⭐ Cross-Layer Integration: Terms Dialog

<!-- AI_VERIFY: exercise-7 -->

**Scenario:** "Login lần đầu → show Terms dialog. Accept → navigate. Decline → stay."

### Requirements

1. `AppPreferences` += `hasAcceptedTerms` (bool)
2. `LoginViewModel.login()`: sau save tokens, check terms → show dialog nếu chưa accept
3. Terms Dialog: `AppNavigator.showDialog()` return `bool`
4. Accept → save + navigate; Decline → inline error, stay on login
5. Subsequent logins skip dialog nếu đã accept

### Acceptance Criteria
- [ ] First login → Terms dialog appears
- [ ] Accept → navigate to Main, subsequent logins skip
- [ ] Decline → inline error, stay on login
- [ ] Terms dialog là separate widget file

<details>
<summary>💡 Gợi ý (mở khi stuck > 15 phút)</summary>

- Dialog triggered từ ViewModel (business logic), không phải UI
- Dùng `AppNavigator.showDialog<bool>()` để hiện và nhận kết quả
- Decline → set state error, KHÔNG throw exception
- Lưu trạng thái accept vào `AppPreferences`

</details>

---

## 💡 Graduated Hints

Nếu bạn bị stuck, tham khảo hints theo thứ tự — từ gợi ý chung đến cụ thể:

### Exercise 2 — Remember Me

| Level | Hint |
|-------|------|
| 🟢 Direction | Thêm field vào State, method vào ViewModel, storage methods vào AppPreferences |
| 🟡 Which files | Sửa 4 files: `login_state.dart`, `login_view_model.dart`, `app_preferences.dart`, `login_page.dart` |
| 🔴 Code snippet | `_encryptedSharedPreferences.setString(keyRememberEmail, email)` cho save |

### Exercise 4 — Real API Integration

| Level | Hint |
|-------|------|
| 🟢 Direction | Thêm `APP_DOMAIN` vào dart_defines, uncomment API call, thay hardcoded tokens |
| 🟡 Key files | `dart_defines/develop.json`, `env.dart`, `login_view_model.dart`, các interceptor trong `middleware/` |
| 🔴 Code snippet | `final response = await _ref.read(appApiServiceProvider).login(email: email, password: data.password);` |

### Exercise 6 — Forgot Password

| Level | Hint |
|-------|------|
| 🟢 Direction | Copy toàn bộ pattern từ Login, thay field names và logic |
| 🟡 Which files | Tạo 3 files mới + thêm route trong `app_router.dart` |
| 🔴 Code snippet | `@RoutePage() class ForgotPasswordPage extends BasePage<ForgotPasswordState, ...>` |

### Exercise 7 — Terms Dialog

| Level | Hint |
|-------|------|
| 🟢 Direction | Dialog triggered từ ViewModel, dùng `AppNavigator.showDialog<bool>()` |
| 🟡 Which files | `app_preferences.dart`, `login_view_model.dart`, `terms_dialog.dart` (NEW) |
| 🔴 Code snippet | `final accepted = await _ref.read(appNavigatorProvider).showDialog<bool>(...)` |

---

## Tổng kết Exercises

| # | Difficulty | Focus | Layers touched |
|---|-----------|-------|---------------|
| 1 | ⭐ | Trace & understand | Read-only across all |
| 2 | ⭐⭐ | State + Storage | State, VM, Storage, UI |
| 3 | ⭐⭐ | Error handling depth | VM, Base framework |
| 4 | ⭐⭐ | **Real API + Interceptor chain** | **Config, Network, All interceptors** |
| 5 | ⭐⭐ | Trace logout flow | Read-only: UI, VM, Storage, Navigation |
| 6 | ⭐⭐⭐ | Full feature clone | All 6 layers |
| 7 | ⭐⭐⭐ | Cross-layer modification | Storage, VM, Navigation, UI |

Hoàn thành Exercise 1-4 là **minimum requirement**. Exercise 5-7 cho bạn sẵn sàng build feature độc lập.

→ **Tiếp theo**: [04-verify.md](./04-verify.md) — Verification checklist.

<!-- AI_VERIFY: generation-complete -->
