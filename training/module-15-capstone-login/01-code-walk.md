# Code Walk — Capstone: Login Feature Deep Dive

> 📌 **Recap từ M0–M14:**
> M5 (AppNavigator, replaceAll, route guard) · M7 (BasePage, BaseViewModel, runCatching) · M8 (Riverpod StateNotifierProvider, ref.read/watch) · M9 (Page UI structure, CommonScaffold, Consumer) · M10 (Flutter Hooks) · M12 (AppApiService, RestApiClient, Dio) · M13 (Interceptor chain, error boundary) · M14 (AppPreferences, EncryptedSharedPreferences)
>
> Nếu bất kỳ concept nào chưa nắm vững → quay lại module tương ứng trước khi tiếp tục.

> ⚠️ **Mock vs Real API**
>
> Code walk này dùng mock interceptor để demo flow. Trong Exercise, bạn sẽ switch sang real API để trải nghiệm full interceptor chain.
>
> Để switch: cập nhật `dart_defines/develop.json`:
> ```json
> { "FLAVOR": "develop", "APP_DOMAIN": "https://api-dev.example.com" }
> ```
> Và chạy lại app với `--dart-define-from-file=dart_defines/develop.json`

---

## Walk Order — End-to-End Login Flow

```
LoginPage (UI layer)
    ↓ user taps Login button
LoginViewModel.login() (ViewModel layer)
    ↓ runCatching wraps async action
AppApiService.login() (API layer)
    ↓ Dio request through interceptor chain
Interceptor Chain (Network layer)
    ↓ response returns
AppPreferences.saveAccessToken/RefreshToken/IsLoggedIn (Storage layer)
    ↓ tokens persisted
AppNavigator.replaceAll([MainRoute()]) (Navigation layer)
    ↓ stack cleared, user sees home
```

---

## 1. LoginState — Data Contract (Freezed)

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/view_model/login_state.dart -->
```dart
@freezed
sealed class LoginState extends BaseState with _$LoginState {
  const LoginState._();

  const factory LoginState({
    @Default('') String email,
    @Default('') String password,
    @Default('') String onPageError,
  }) = _LoginState;

  bool get isLoginButtonEnabled => email.isNotEmpty && password.isNotEmpty;
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/page/login/view_model/login_state.dart`](../../base_flutter/lib/ui/page/login/view_model/login_state.dart)

- `extends BaseState` — contract mọi state phải extend (M7)
- `@freezed` + `sealed class` — immutable, `copyWith()` tự generate (M07)
- `@Default('')` — không bao giờ null, tránh null-check
- `isLoginButtonEnabled` — computed getter, derived từ `email` + `password`

`LoginState` được wrap trong `CommonState<LoginState>`:

```
provider → CommonState<LoginState>
  ├─ data: LoginState (email, password, onPageError)
  ├─ isLoading: bool
  ├─ isFirstLoading: bool
  ├─ appException: AppException?
  └─ doingAction: Map<String, bool>
```

---

## 2. CommonState — Wrapper Layer

<!-- AI_VERIFY: base_flutter/lib/ui/base/common_state.dart -->
```dart
@freezed
sealed class CommonState<T extends BaseState> with _$CommonState<T> {
  const CommonState._();

  const factory CommonState({
    required T data,
    AppException? appException,
    @Default(false) bool isLoading,
    @Default(false) bool isFirstLoading,
    @Default(<String, bool>{}) Map<String, bool> doingAction,
  }) = _CommonState;

  bool isDoingAction(String actionName) => doingAction[actionName] == true;
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/base/common_state.dart`](../../base_flutter/lib/ui/base/common_state.dart)

`CommonState` tách **page-specific data** (`LoginState`) khỏi **framework concerns** (loading, exception) — `BasePage` tự động handle loading overlay mà không cần page nào implement lại.

---

## 3. LoginViewModel — Business Logic Layer

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/view_model/login_view_model.dart -->
```dart
final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, CommonState<LoginState>>(
  (ref) => LoginViewModel(ref),
);

class LoginViewModel extends BaseViewModel<LoginState> {
  LoginViewModel(this._ref) : super(const CommonState(data: LoginState()));

  final Ref _ref;

  void setEmail(String email) {
    data = data.copyWith(
      email: email,
      onPageError: '',
    );
  }

  void setPassword(String password) {
    data = data.copyWith(
      password: password,
      onPageError: '',
    );
  }

  FutureOr<void> login() async {
    await runCatching(
      action: () async {
        final email = data.email.trim();
        // --- BYPASS API MOCK ---
        // final response = await _ref.read(appApiServiceProvider).login(
        //       email: email,
        //       password: data.password,
        //     );

        final deviceToken = await _ref.read(sharedViewModelProvider).deviceToken;
        Log.d('deviceToken: $deviceToken'.hardcoded);

        await Future.wait([
          _ref.read(appPreferencesProvider).saveAccessToken('mock_access_token'),
          _ref.read(appPreferencesProvider).saveRefreshToken('mock_refresh_token'),
          _ref.read(appPreferencesProvider).saveIsLoggedIn(true),
        ]);

        await _ref.read(appNavigatorProvider).replaceAll([MainRoute()]);
      },
      handleErrorWhen: (_) => false,
      doOnError: (e) async {
        data = data.copyWith(onPageError: e.message);
      },
    );
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/page/login/view_model/login_view_model.dart`](../../base_flutter/lib/ui/page/login/view_model/login_view_model.dart)

> 📌 `.hardcoded` là extension method (defined trong `lib/resource/`) chuyển đổi `String` thành type-safe locale string. Pattern này cho phép dễ dàng tìm và thay thế hardcoded strings bằng localized keys sau này. Xem [Module 11 — i18n](../module-11-i18n/00-overview.md).

### 3.1 Key Design Decisions

- `StateNotifierProvider.autoDispose` → khi page dispose, provider tự cleanup. `ref` inject vào VM cho phép đọc providers khác.
- `setEmail`/`setPassword` clear `onPageError` mỗi khi user type → UX: lỗi biến mất khi user sửa. Immutable `copyWith()` → Riverpod detect change → chỉ rebuild widgets đang watch.

### 3.2 login() — The Core Flow

#### Step 1: `runCatching` wraps toàn bộ action

```dart
await runCatching(
  action: () async { /* happy path */ },
  handleErrorWhen: (_) => false,  // ← Tự handle error, không hiện dialog mặc định
  doOnError: (e) async { /* set onPageError */ },
);
```

`runCatching` (M7): `showLoading()` → execute action → `hideLoading()`. Catch → wrap `AppException` → `doOnError`. `handleErrorWhen: false` = page tự xử lý error qua `onPageError` thay vì dialog.

#### Step 2: API Call (currently mocked — Development/Testing only)

> 🧪 **Development/Testing only**
>
> Code hiện tại bypass API call hoàn toàn — dùng `Future.delayed` + hardcoded tokens. Cách này chỉ phù hợp khi:
> - Chưa có backend API
> - Muốn test UI flow nhanh mà không cần network
> - Unit test isolated logic
>
> **Trong production code, bạn PHẢI dùng real API call.** Xem phần "Real Interceptor Chain" bên dưới.

Khi unmock, flow: `AppApiService.login()` → `RestApiClient` → `Dio` → Interceptor chain (M13).

#### Step 3: Save tokens (parallel)

```dart
await Future.wait([
  _ref.read(appPreferencesProvider).saveAccessToken('mock_access_token'),
  _ref.read(appPreferencesProvider).saveRefreshToken('mock_refresh_token'),
  _ref.read(appPreferencesProvider).saveIsLoggedIn(true),
]);
```

`Future.wait` — 3 storage operations song song. Tokens → `EncryptedSharedPreferences` (M14). `isLoggedIn` → `SharedPreferences` (plain bool cho route guard).

**So sánh Mock vs Production:**

| Aspect | Mock (hiện tại) | Production (khi có API) |
|--------|----------------|------------------------|
| Login call | `Future.delayed(1s)` → hardcoded token | `ref.read(appApiServiceProvider).login(email, password)` |
| Token | `'mock_access_token'` | Token thật từ server response |
| Error | Không có | `DioException` → `RemoteException` → UI error handling |
| Refresh | Không trigger | `RefreshTokenInterceptor` auto-refresh khi 401 |

#### Step 4: Navigate

`replaceAll([MainRoute()])` — clear toàn bộ stack → user không back về login.

#### Error Path

`doOnError` set `onPageError` → Consumer rebuild → hiện red text. `e.message` = user-friendly string (đã mapped từ `DioException` → `AppException`).

---

## 3.3 Real Interceptor Chain — Khi Dùng API Thật

Khi bạn unmock API call (`_ref.read(appApiServiceProvider).login(...)`), request đi qua **full interceptor chain** trong `base_flutter`. Đây là flow thực tế mà production app sẽ chạy:

### Request Flow (outgoing)

```
LoginViewModel.login()
    │
    ▼
AppApiService.login(email, password)
    │
    ▼
RestApiClient (Dio instance)
    │
    ▼ ─── Interceptor Chain (sorted by priority) ───
    │
    ├── 1. RetryOnErrorInterceptor (priority: 100)
    │     └── onRequest: gắn retryCount = maxRetries vào headers
    │
    ├── 2. ConnectivityInterceptor (priority: 99)
    │     └── onRequest: check network available
    │     └── NO network → reject DioException(RemoteExceptionKind.noInternet)
    │
    ├── 3. AccessTokenInterceptor (priority: 20)
    │     └── onRequest: đọc token từ AppPreferences → gắn Authorization header
    │
    ├── 4. HeaderInterceptor (priority: 10)
    │     └── onRequest: gắn common headers (device info, app version...)
    │
    └── 5. CustomLogInterceptor (priority: 1)
          └── onRequest: log request details
    │
    ▼
  ═══ NETWORK (HTTP Request to server) ═══
```

> 📝 `RefreshTokenInterceptor` chỉ handle `onError` (không có `onRequest`) — đứng sau chain, intercept 401 response để refresh token và retry.

```
```

### Response Flow (incoming — happy path)

```
  ═══ NETWORK (HTTP 200 OK) ═══
    │
    ▼
CustomLogInterceptor.onResponse → log response
    │
    ▼
Dio resolves Future<Response>
    │
    ▼
AppApiService parse JSON → LoginResponse
    │
    ▼
LoginViewModel nhận response → save tokens → navigate
```

### Error Flow (401 Unauthorized — Token Expired)

Đây là flow quan trọng nhất mà mock **không bao giờ trigger được**:

```
  ═══ NETWORK (HTTP 401 Unauthorized) ═══
    │
    ▼
RetryOnErrorInterceptor.onError
    │  401 ≠ timeout → pass through
    ▼
RefreshTokenInterceptor.onError
    │  statusCode == 401 → bắt đầu refresh flow:
    │
    ├── 1. Queue request hiện tại vào _queue
    ├── 2. Gọi RefreshTokenApiClient → POST /refresh-token
    ├── 3. Nhận new accessToken + refreshToken
    ├── 4. Save cả 2 vào AppPreferences (encrypted)
    ├── 5. Retry TẤT CẢ requests trong _queue với new token
    └── 6. Resolve response → caller không biết refresh đã xảy ra
    │
    ▼
LoginViewModel nhận response bình thường (transparent retry)
```

### Error Flow (Network Error — No Internet / Timeout)

```
  ═══ NETWORK ERROR (timeout / no connection) ═══
    │
    ▼
RetryOnErrorInterceptor.onError
    │  shouldRetry() == true (connectionTimeout, receiveTimeout, etc.)
    │
    ├── retryCount > 0?
    │   ├── YES → delay → retry request → retryCount - 1
    │   └── NO  → pass error to next interceptor
    │
    ▼
DioException → caught by runCatching
    │
    ▼
AppException mapping (M13)
    │
    ▼
doOnError → data.copyWith(onPageError: e.message)
```

### Interceptor Priority Table

| Interceptor | Priority | Phase | Chức năng |
|-------------|----------|-------|----------|
| `RetryOnErrorInterceptor` | 100 | Request + Error | Retry khi timeout/connection error |
| `ConnectivityInterceptor` | 99 | Request | Block request khi no internet |
| `BasicAuthInterceptor` | 40 | Request | Basic auth cho một số endpoints |
| `RefreshTokenInterceptor` | 30 | Error | Auto refresh token khi 401 |
| `AccessTokenInterceptor` | 20 | Request | Gắn Bearer token vào header |
| `HeaderInterceptor` | 10 | Request | Common headers |
| `CustomLogInterceptor` | 1 | All | Log request/response |

> 📌 **Priority cao hơn = thêm vào chain trước** (xử lý request trước, nhưng xử lý error sau). Xem `base_interceptor.dart` → `InterceptorType` enum.

### Switching Giữa Mock và Real API

Project dùng `dart_defines/` + `Env` class để cấu hình:

```
base_flutter/
├── dart_defines/
│   ├── develop.json    ← development (có thể dùng mock server)
│   ├── staging.json    ← staging API
│   ├── qa.json         ← QA API
│   └── production.json ← production API
└── lib/common/
    ├── env.dart         ← đọc APP_DOMAIN từ dart-define
    └── constant.dart    ← appApiBaseUrl = '${Env.appDomain}/api/'
```

**Bước chuyển từ mock → real API:**

1. Thêm `APP_DOMAIN` vào `dart_defines/develop.json`:
   ```json
   { "FLAVOR": "develop", "APP_DOMAIN": "https://your-api-domain.com" }
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

---

## 4. LoginPage — UI Layer

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/login_page.dart -->
```dart
@RoutePage()
class LoginPage extends BasePage<LoginState,
    AutoDisposeStateNotifierProvider<LoginViewModel, CommonState<LoginState>>> {
  const LoginPage({super.key});

  @override
  ScreenViewEvent get screenViewEvent => ScreenViewEvent(screenName: ScreenName.loginPage);

  @override
  AutoDisposeStateNotifierProvider<LoginViewModel, CommonState<LoginState>> get provider =>
      loginViewModelProvider;

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    // ... full UI implementation
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/page/login/login_page.dart`](../../base_flutter/lib/ui/page/login/login_page.dart)

### 4.1 Analytics Extension

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/login_page.dart -->
```dart
extension AnalyticsHelperOnLoginPage on AnalyticsHelper {
  void _logLoginButtonClickEvent() {
    logEvent(NormalEvent(
      screenName: ScreenName.loginPage,
      eventName: EventConstants.loginButtonClick,
    ));
  }

  void _logEyeIconClickEvent({required bool obscureText}) {
    logEvent(NormalEvent(
      screenName: ScreenName.loginPage,
      eventName: EventConstants.eyeIconClick,
      parameter: ObscureTextParameter(obscureText: obscureText),
    ));
  }
}
```
<!-- END_VERIFY -->

Analytics dùng **extension on `AnalyticsHelper`** — page-specific events scope chặt, `_` prefix = private trong file. Analytics thuộc **UI concerns** (what user clicked), không đặt trong ViewModel.

### 4.2 buildPage() — Widget Tree

```dart
CommonScaffold(
  body: Stack([
    CommonImage.asset(path: background, width: ∞, height: ∞, fit: cover),
    CommonScrollbarWithIosStatusBarTapDetector(
      routeName: LoginRoute.name,
      controller: scrollController,         // ← useScrollController() hook (M10)
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column([
          CommonText(l10n.login, style: ...),
          PrimaryTextField(                        // ← Email
            title: l10n.email,
            onChanged: (email) => ref.read(provider.notifier).setEmail(email),
          ),
          PrimaryTextField(                        // ← Password
            title: l10n.password,
            onChanged: (password) => ref.read(provider.notifier).setPassword(password),
            onEyeIconPressed: (obscureText) { ... }, // ← Analytics
          ),
          Consumer(/* onPageError visibility */),
          Consumer(/* login button */),
        ]),
      ),
    ),
  ]),
)
```

### 4.3 Consumer Widgets — Surgical Rebuilds

**Error display:**

```dart
Consumer(
  builder: (context, ref, child) {
    final onPageError = ref.watch(
      provider.select((value) => value.data.onPageError),
    );
    return Visibility(
      visible: onPageError.isNotEmpty,
      child: CommonText(onPageError, style: style(fontSize: 14, color: color.red1)),
    );
  },
),
```

**Login button:**

```dart
Consumer(
  builder: (context, ref, child) {
    final isLoginButtonEnabled = ref.watch(
      provider.select((value) => value.data.isLoginButtonEnabled),
    );
    return ElevatedButton(
      onPressed: isLoginButtonEnabled
          ? () {
              ref.read(analyticsHelperProvider)._logLoginButtonClickEvent();
              ref.read(provider.notifier).login();
            }
          : null,   // ← null → button disabled (Material built-in)
      // ... styling
    );
  },
),
```

- `ref.watch(provider.select(...))` → **chỉ rebuild** khi field cụ thể thay đổi
- `Consumer` tạo **rebuild boundary** — 2 Consumer watch fields khác nhau, không affect nhau
- `Visibility` widget giữ widget trong tree, toggle visibility — layout không shift

---

## 5. BaseViewModel.runCatching — Login-specific Usage

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_view_model.dart | lines 98-181 -->

Xem full `runCatching` implementation tại [M7 code walk](../module-07-base-viewmodel/01-code-walk.md).

Login-specific params:

| Parameter | Value | Ý nghĩa |
|-----------|-------|----------|
| `action` | API call + save tokens + navigate | Happy path |
| `handleErrorWhen` | `(_) => false` | Không hiện dialog, tự handle |
| `doOnError` | Set `onPageError` | Inline error text |
| `handleLoading` | `true` (default) | Loading overlay |
| `maxRetries` | `2` (default) | Retry 2 lần (skip vì `handleErrorWhen` = false) |

<!-- END_VERIFY -->

---

## 6. AppPreferences — Token Persistence

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->

Xem full implementation tại [M14 code walk](../module-14-local-storage/01-code-walk.md).

Login flow dùng:
- `saveAccessToken()` / `saveRefreshToken()` → `EncryptedSharedPreferences` (encrypted at rest)
- `saveIsLoggedIn(true)` → `SharedPreferences` (plain bool, đọc sync cho route guard)

<!-- END_VERIFY -->

---

## 7. AppNavigator.replaceAll — Post-Login Navigation

<!-- AI_VERIFY: base_flutter/lib/navigation/app_navigator.dart -->

`replaceAll([MainRoute()])`: xóa toàn bộ stack → push `MainRoute` làm root → user back button = exit app. Xem [M5 code walk](../module-05-navigation/01-code-walk.md).

<!-- END_VERIFY -->

---

## 8. Complete Flow Diagram

```
User nhập email/password
    │
    ├── PrimaryTextField.onChanged
    │     └── ref.read(provider.notifier).setEmail(email)
    │           └── data.copyWith(email, onPageError: '')
    │                 └── Riverpod notifies → Consumer rebuilds
    │
    ├── User taps Login button
    │     ├── analyticsHelper._logLoginButtonClickEvent()
    │     └── loginViewModel.login()
    │
    └── runCatching {
          ├── showLoading() → overlay
          ├── action:
          │     ├── AppApiService.login() [mocked]
          │     ├── Future.wait([saveAccessToken, saveRefreshToken, saveIsLoggedIn])
          │     └── appNavigator.replaceAll([MainRoute()])
          ├── hideLoading()
          └── ON ERROR:
                ├── doOnError: data.copyWith(onPageError: e.message)
                └── handleErrorWhen: false → no dialog
        }
```

---

## 9. File Dependency Map

```
login_page.dart
  ├── extends: BasePage (M7)
  ├── uses: CommonScaffold, PrimaryTextField, CommonText (UI components)
  └── uses: loginViewModelProvider, analyticsHelperProvider

login_view_model.dart
  ├── extends: BaseViewModel (M7)
  ├── uses: appApiServiceProvider (M12), appPreferencesProvider (M14), appNavigatorProvider (M5)
  └── imports: login_state.dart

login_state.dart
  ├── extends: BaseState (M7)
  └── @freezed (M07)
```

---

## Tổng kết

Login feature là **microcosm** của toàn bộ architecture:

1. **State-first design** — `LoginState` define shape, UI + VM react theo
2. **Separation of concerns** — UI render + dispatch, VM xử lý logic, state immutable
3. **Error boundary** — `runCatching` centralize loading/error
4. **Selective rebuilds** — `Consumer` + `provider.select()` tối ưu performance
5. **Layered dependencies** — VM access API, Storage, Navigation qua providers

→ **Tiếp theo**: [02-concept.md](./02-concept.md) — deep-dive từng concept pattern.

<!-- AI_VERIFY: generation-complete -->
