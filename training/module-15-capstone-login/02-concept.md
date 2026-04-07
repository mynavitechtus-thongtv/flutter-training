# Concepts — Capstone: Login Feature Deep Dive

> 📌 **Recap từ M0–M14:**
> - **M7:** `BasePage` auto-handle loading/exception, `BaseViewModel.runCatching` error boundary ([M7](../module-07-base-viewmodel/02-concept.md))
> - **M8:** Riverpod `StateNotifierProvider`, `ref.read()` vs `ref.watch()`, `select()` optimization ([M8](../module-08-riverpod-state/02-concept.md))
> - **M9:** Page UI structure, `buildPage()`, `Consumer` widget isolation ([M9](../module-09-page-structure/02-concept.md))
> - **M12:** REST API integration, Dio + interceptor chain, request/response pipeline ([M12](../module-12-data-layer/02-concept.md))
> - **M13:** Exception mapping, `DioExceptionMapper`, `RemoteException` hierarchy ([M13](../module-13-middleware-interceptor-chain/02-concept.md))
> - **M14:** `AppPreferences`, encrypted token storage, route guard auth check ([M14](../module-14-local-storage/02-concept.md))

---

## Concept 1 — End-to-End Feature Flow Architecture 🔴 MUST-KNOW

**WHY:** Mọi feature mới đều đi qua flow này — sai flow = sai architecture.

### Pattern: Unidirectional Data Flow qua nhiều layer

Login flow minh họa **unidirectional data flow** xuyên suốt architecture:

```
UI (input) → ViewModel (logic) → API (network) → Storage (persist) → Navigation (output)
     ↑                                                                        │
     └────────────── State updates (error / loading) ─────────────────────────┘
```

Mỗi layer chỉ biết layer kế tiếp — không có circular dependency:

| Layer | File | Responsibility | Knows about |
|-------|------|---------------|-------------|
| UI | `login_page.dart` | Render + dispatch actions | ViewModel provider |
| ViewModel | `login_view_model.dart` | Orchestrate business logic | API, Storage, Navigator |
| State | `login_state.dart` | Data shape + computed | Nothing (pure data) |
| API | `AppApiService` | HTTP calls | Dio + interceptors |
| Storage | `AppPreferences` | Persist tokens | EncryptedSharedPrefs |
| Navigation | `AppNavigator` | Route management | AutoRoute |

### Tại sao pattern này quan trọng?

1. **Testability** — mock từng layer độc lập
2. **Debuggability** — trace flow theo 1 hướng, biết data đi từ đâu đến đâu
3. **Scalability** — thêm feature mới chỉ cần follow same pattern

> 💡 **FE Perspective — React equivalent:**
```
Component (dispatch) → Redux Thunk/Saga → API call → localStorage → React Router
     ↑                                                                     │
     └──────────────── Redux state updates ───────────────────────────────┘
```

Flutter base project dùng Riverpod thay Redux, nhưng **mental model giống nhau**: UI dispatch, middleware xử lý, state update, UI react.

---

## Concept 2 — `runCatching` as Error Boundary Pattern 🔴 MUST-KNOW

**WHY:** Error handling chạy xuyên suốt mọi API call — hiểu sai `runCatching` = silent failures.

### Vấn đề: Async error handling phức tạp

Mỗi async operation có thể fail: API timeout, storage full, navigation guard block. Nếu mỗi VM tự try-catch:

```dart
// ❌ Anti-pattern: manual try-catch everywhere
Future<void> login() async {
  try {
    setState(loading: true);
    await api.login(...);
    setState(loading: false);
    await saveTokens();
    navigate();
  } catch (e) {
    setState(loading: false);
    setState(error: e.message);
  }
}
```

Vấn đề: loading logic lặp, error handling inconsistent, dễ quên `hideLoading` trong error path.

### Solution: `runCatching` centralized

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_view_model.dart -->
```dart
await runCatching(
  action: () async { /* happy path */ },
  handleErrorWhen: (_) => false,    // skip dialog
  doOnError: (e) async { ... },     // custom error handling
  handleLoading: true,              // auto loading overlay
  maxRetries: 2,                    // auto retry
);
```
<!-- END_VERIFY -->

**Execution timeline:**

```
runCatching called
├── showLoading()              ← automatic
├── try { action() }           ← your business logic
│   ├── success → hideLoading()
│   └── error → hideLoading()
│       ├── doOnError(e)       ← your error handler
│       ├── handleErrorWhen?   ← should BasePage handle?
│       │   ├── true → exception = e → BasePage shows dialog
│       │   └── false → skip dialog (login uses this)
│       └── retry logic        ← automatic retry if configured
└── doOnSuccessOrError()       ← cleanup regardless
```

### Login-specific configuration

```dart
handleErrorWhen: (_) => false  // → Tự handle error qua onPageError
doOnError: (e) async {
  data = data.copyWith(onPageError: e.message);  // → Inline error text
}
```

Login **opt-out** khỏi default error dialog vì muốn hiện error inline trên form — better UX cho login flow.

> 💡 **FE Perspective:**
```javascript
// React equivalent: custom hook wrapping try-catch
const useAsyncAction = () => {
  const [loading, setLoading] = useState(false);
  const run = async (action, { onError } = {}) => {
    setLoading(true);
    try { await action(); }
    catch (e) { onError?.(e); }
    finally { setLoading(false); }
  };
  return { loading, run };
};
```

---

## Concept 3 — Form State Management Pattern 🔴 MUST-KNOW

**WHY:** Form validation là daily task — phải tự viết được, AI thường gen sai validation logic.

### Immutable state + computed getters

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

### Key principles

**1. Single source of truth** — Form values sống trong `LoginState`, không phải `TextEditingController`.

```dart
// UI dispatches:
onChanged: (email) => ref.read(provider.notifier).setEmail(email)

// VM updates state:
data = data.copyWith(email: email, onPageError: '')

// UI reacts:
ref.watch(provider.select((v) => v.data.isLoginButtonEnabled))
```

**2. Computed properties as getters** — `isLoginButtonEnabled` derived từ state, không stored riêng. Mỗi khi `email` hoặc `password` change → getter tự recalculate.

**3. Side-effect on update** — `setEmail()` clear `onPageError`. User bắt đầu type → error biến mất. Đây là intentional UX pattern.

**4. No nullable fields** — `@Default('')` thay vì `String?`. Tránh null-check ở UI layer. `onPageError.isNotEmpty` thay vì `onPageError != null && onPageError.isNotEmpty`.

### Comparison: TextEditingController vs State-based

| Aspect | TextEditingController | State-based (project pattern) |
|--------|-----------------------|-------------------------------|
| Source of truth | Widget tree | ViewModel state |
| Cross-field validation | Manual sync | Computed getter |
| Testability | Need widget test | Unit test state directly |
| Error clearing | Manual listener | Built into setter |
| Integration với VM | Extract values manually | Already in state |

---

## Concept 4 — Login API Contract & Token Lifecycle 🟡 SHOULD-KNOW

**WHY:** Token flow vary theo project, cần hiểu flow tổng quát nhưng chi tiết API thay đổi.

### Request → Response → Storage pipeline

```
LoginViewModel.login()
    │
    ├── AppApiService.login(email, password)
    │     └── POST /auth/login { email, password }
    │           └── Response: { accessToken, refreshToken, userId }
    │
    ├── Future.wait([
    │     saveAccessToken(response.accessToken),
    │     saveRefreshToken(response.refreshToken),
    │     saveIsLoggedIn(true),
    │   ])
    │
    └── appNavigator.replaceAll([MainRoute()])
```

### Token storage strategy

| Token | Storage | Encryption | Reason |
|-------|---------|------------|--------|
| `accessToken` | `EncryptedSharedPreferences` | AES-encrypted | Short-lived, sensitive |
| `refreshToken` | `EncryptedSharedPreferences` | AES-encrypted | Long-lived, highly sensitive |
| `isLoggedIn` | `SharedPreferences` | Plain text | Boolean flag for sync route guard check |

### Tại sao `Future.wait` thay vì sequential?

```dart
// ✅ Parallel — faster
await Future.wait([
  saveAccessToken(...),
  saveRefreshToken(...),
  saveIsLoggedIn(true),
]);

// ❌ Sequential — unnecessary wait
await saveAccessToken(...);
await saveRefreshToken(...);
await saveIsLoggedIn(true);
```

3 operations **independent** nhau → chạy song song, giảm latency ~60%.

> 💡 **FE Perspective:**
```javascript
// React equivalent: Promise.all
await Promise.all([
  localStorage.setItem('accessToken', token),
  localStorage.setItem('refreshToken', refresh),
  localStorage.setItem('isLoggedIn', 'true'),
]);
```

---

## Concept 5 — Post-Login Navigation Pattern 🟡 SHOULD-KNOW

**WHY:** Navigation setup là one-time per feature, pattern quen thuộc sau lần đầu.

### `replaceAll` vs `push` vs `pushAndRemoveUntil`

```dart
await _ref.read(appNavigatorProvider).replaceAll([MainRoute()]);
```

| Method | Stack trước | Stack sau | Back button |
|--------|-------------|-----------|-------------|
| `push(MainRoute())` | `[Splash, Login]` | `[Splash, Login, Main]` | → Login |
| `pushAndRemoveUntil` | `[Splash, Login]` | `[Main]` | → Exit app |
| `replaceAll([MainRoute()])` | `[Splash, Login]` | `[Main]` | → Exit app |

Login dùng `replaceAll` vì:
1. User đã authenticated → không nên back về login
2. Clear toàn bộ stack → clean memory
3. `MainRoute` trở thành root → consistent navigation state

### Security implication

Nếu dùng `push` thay `replaceAll`:
- Back button → login page → form còn data cũ
- Route guard phải re-check auth
- Memory leak: login page widgets still in memory

> 💡 **FE Perspective:**
```javascript
// React Router v6
navigate('/home', { replace: true });
// Hoặc clear history hoàn toàn:
window.history.replaceState({}, '', '/home');
```

---

## Concept 6 — Analytics Integration Pattern 🟢 AI-GENERATE

**WHY:** Analytics integration là boilerplate — copy pattern từ existing page, AI gen chính xác.

### Extension-based analytics

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

### Design decisions

**1. Extension thay vì method trong AnalyticsHelper base class:**
- Mỗi page define events riêng → không bloat shared class
- Private methods (`_log...`) → chỉ accessible trong file define extension
- Compile-time guarantee — không call nhầm event từ page khác

**2. Screen view auto-logged bởi BasePage:**
```dart
@override
ScreenViewEvent get screenViewEvent => ScreenViewEvent(screenName: ScreenName.loginPage);
```
`BasePage.onVisibilityChanged()` gọi `logScreenView()` tự động mỗi khi page visible → không cần manual tracking.

**3. Event types:**

| Type | Trigger | Example |
|------|---------|---------|
| `ScreenViewEvent` | Page visible | Auto by `BasePage` |
| `NormalEvent` | User action | Button click, toggle eye icon |

### Analytics flow trong login:

```
Page visible → screenViewEvent auto-logged
User types email → (no event)
User taps eye icon → _logEyeIconClickEvent(obscureText: true/false)
User taps Login → _logLoginButtonClickEvent() → then login()
```

---

## Concept 7 — Error Display Pattern: `onPageError` 🔴 MUST-KNOW

**WHY:** Error display trực tiếp ảnh hưởng UX — phải hiểu `onPageError` lifecycle để customize.

### Inline error vs Dialog error

Project có 2 error display mechanisms:

| Mechanism | Trigger | UI | Use case |
|-----------|---------|-----|----------|
| `BasePage` exception handler | `handleErrorWhen` returns `true` | Dialog / SnackBar | Network errors, server errors |
| `onPageError` in state | `doOnError` sets field | Inline red text | Form validation, login failed |

Login chọn **inline error** vì:
- User đang focus trên form → dialog interrupts flow
- Error message ngắn (e.g., "Invalid credentials")
- User cần thấy error **cạnh** input fields

### Implementation trace

```dart
// 1. VM catches error, sets state
doOnError: (e) async {
  data = data.copyWith(onPageError: e.message);
}

// 2. UI Consumer watches specific field
final onPageError = ref.watch(
  provider.select((value) => value.data.onPageError),
);

// 3. Visibility toggle
return Visibility(
  visible: onPageError.isNotEmpty,
  child: CommonText(onPageError, style: style(color: color.red1)),
);

// 4. Error cleared when user types again
void setEmail(String email) {
  data = data.copyWith(email: email, onPageError: '');  // ← clear here
}
```

### Error lifecycle

```
API fail → AppException → e.message
  → doOnError → data.copyWith(onPageError: "Invalid credentials")
    → Consumer rebuild → red text visible
      → User types new email
        → setEmail() → onPageError: ''
          → Consumer rebuild → red text hidden
```

> 💡 **FE Perspective:**
```jsx
// React equivalent
{error && <p className="text-red-500">{error}</p>}
// Clear on input change:
const handleChange = (e) => { setEmail(e.target.value); setError(''); };
```

---

## Tổng kết Concepts

7 concepts này kết hợp tạo nên **complete feature pattern** có thể replicate cho bất kỳ feature nào:

1. **Flow architecture** → biết data đi đâu
2. **Error boundary** → không bao giờ quên handle error
3. **Form state** → reactive, testable, no-null
4. **API contract** → clear request/response/storage pipeline
5. **Navigation** → security-aware route management
6. **Analytics** → non-intrusive, auto + manual events
7. **Error display** → appropriate UX per context

Tiếp theo → [03-exercise.md](./03-exercise.md) để practice áp dụng patterns này.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
