# Concepts — Base Page, State & ViewModel

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

> 📌 **Prerequisite:** Module này tập trung vào **BaseViewModel pattern** — cách project wrap Riverpod để tạo ViewModel base class. Các khái niệm Riverpod cốt lõi (Provider types, ref API, autoDispose, Selector) → xem [Module 08 — Riverpod State](../module-08-riverpod-state/02-concept.md). Ở đây chỉ giải thích **đủ** để hiểu pattern, không deep-dive Riverpod.

---

## 1. BaseState Contract — Abstract Marker Class 🟢 AI-GENERATE

**WHY:** Không có constraint → bất kỳ type nào cũng truyền vào `BaseViewModel<T>`. Một `int` hay `String` làm state → mất structure, `copyWith` không hoạt động, team inconsistency.

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_state.dart -->
```dart
abstract class BaseState {
  const BaseState();
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § base_state.dart](./01-code-walk.md#1-base_statedart--abstract-state-contract)

**EXPLAIN:**

| Aspect | Detail |
|--------|--------|
| **Marker pattern** | Không có method/field — chỉ đánh dấu "đây là state class" |
| **`abstract`** | Không instantiate trực tiếp — compiler báo lỗi nếu cố `BaseState()` |
| **`const` constructor** | Cho phép state subclass có `const factory` → compile-time constants |
| **Generic constraint** | `<ST extends BaseState>` trong ViewModel + Page → type-safe pipeline |

**So sánh với alternatives:**

```dart
// ❌ Không dùng marker — mọi type đều pass
class BaseViewModel<ST> extends StateNotifier<CommonState<ST>> { }
// → BaseViewModel<int> compiles! Nhưng int không có copyWith...

// ✅ Marker constraint — chỉ state classes:
class BaseViewModel<ST extends BaseState> extends StateNotifier<CommonState<ST>> { }
// → BaseViewModel<int> → COMPILE ERROR
```

**Khi nào tạo state mới?** Mỗi page/feature cần state riêng → extend `BaseState`, thêm `@freezed`:
```dart
@freezed
sealed class ProfileState extends BaseState with _$ProfileState {
  const factory ProfileState({
    @Default('') String name,
    @Default('') String avatar,
  }) = _ProfileState;
}
```

> 💡 **FE Perspective**
> **Flutter:** `BaseState` abstract class là marker type cho generic constraint — mọi page state (LoginState, ProfileState) phải extend nó để dùng với `CommonState<T>` và `BaseViewModel<T>`.
> **React/Vue tương đương:** TypeScript `interface BaseState {}` marker (React), base state type mà mọi store extend trong Pinia (Vue), abstract class cho Angular `ComponentStore`.
> **Khác biệt quan trọng:** Dart enforce constraint tại compile-time với real generics (reified), TypeScript generics bị erased at runtime.

---

## 2. CommonState — Generic Envelope Pattern 🔴 MUST-KNOW

**WHY:** Nếu mỗi page state tự define `isLoading`, `error`, `doingAction` → duplicate code, inconsistent naming, base framework không generalize được.

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
→ Đã đọc trong [01-code-walk § common_state.dart](./01-code-walk.md#2-common_statedart--generic-state-envelope)

**EXPLAIN:**

**Envelope = wrapper tách concerns:**

```
┌─ CommonState<LoginState> ──────────────┐
│  data: LoginState(email, password)     │ ← Business data (varies per page)
│  appException: null                     │ ← Error state (shared)
│  isLoading: false                       │ ← Loading state (shared)
│  isFirstLoading: false                  │ ← First-load flag (shared)
│  doingAction: {'login': true}           │ ← Per-action tracking (shared)
└─────────────────────────────────────────┘
```

**Tại sao wrap thay vì extend?**

```dart
// ❌ Extend approach — mỗi state tự define:
@freezed class LoginState {
  String email;
  String password;
  bool isLoading;        // duplicate!
  AppException? error;   // naming inconsistent
}

// ✅ Wrap approach — tách rõ ràng:
CommonState<LoginState>(
  data: LoginState(email: '', password: ''),  // business
  isLoading: false,                            // infra
)
```

Benefits:
- **BaseViewModel** chỉ operate trên `CommonState` fields (`isLoading`, `appException`) → generalize logic
- **Business state** (`LoginState`) chỉ chứa domain data → clean, testable
- **UI** `ref.watch(provider.select((s) => s.isLoading))` → consistent across ALL pages

**`doingAction` — Map-based action tracking:**

```dart
// Set:
state = state.copyWith(doingAction: {...state.doingAction, 'login': true});

// Query:
state.isDoingAction('login') // → true

// UI:
ref.watch(provider.select((s) => s.isDoingAction('login')))
// → disable login button khi đang submit
```

→ Nhiều action đồng thời? `{'login': true, 'refreshProfile': true}` — track independent.

**`isFirstLoading` — skeleton pattern:**

Lần load đầu tiên → `isFirstLoading = true` → show shimmer/skeleton. Các lần sau → spinner thường. UX tối ưu: user thấy content shape trước khi data arrive.

---

## 3. BaseViewModel Lifecycle — Mounted Guard + State Accessors 🔴 MUST-KNOW

**WHY:** Async operations chạy sau khi widget dispose → `setState()` crash. Không có base class → mỗi ViewModel tự handle → inconsistent, bug-prone.

**Lifecycle Diagram:**

```
┌──────────────────────────────────────────────────────────┐
│              BaseViewModel Lifecycle                      │
│                                                          │
│  Widget mount                                            │
│      ↓                                                   │
│  ┌─────────┐    ┌──────────────────────────┐             │
│  │  init()  │ →  │  active (mounted=true)   │             │
│  └─────────┘    │  ├─ showLoading/hide      │             │
│                  │  ├─ runCatching → action  │             │
│                  │  ├─ set data / state      │             │
│                  │  └─ error → exception     │             │
│                  └──────────┬───────────────┘             │
│                             ↓                             │
│                  Widget unmount (navigate away)           │
│                             ↓                             │
│                  ┌──────────────────────┐                 │
│                  │  dispose()            │                 │
│                  │  mounted = false       │                 │
│                  │  state set → Log.e     │                 │
│                  └──────────┬───────────┘                 │
│                             ↓                             │
│                     Garbage Collected                     │
└──────────────────────────────────────────────────────────┘
```

**Khi nào `dispose()` được gọi trong Flutter widget lifecycle:**

| Trigger | Giải thích |
|---------|------------|
| Navigate away + `autoDispose` | Không còn listener → Riverpod dispose provider → `StateNotifier.dispose()` |
| `ref.invalidate(provider)` | Force dispose + recreate |
| Widget unmount (tab switch, route pop) | Nếu `autoDispose` → dispose khi last listener gone |

→ Sau `dispose()`, mọi `set state` bị guard bởi `mounted` check → log error thay vì crash.

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_view_model.dart -->
```dart
abstract class BaseViewModel<ST extends BaseState>
    extends StateNotifier<CommonState<ST>> {
  BaseViewModel(CommonState<ST> initialState) : super(initialState) {
    this.initialState = initialState;
  }
  late final CommonState<ST> initialState;

  @override
  set state(CommonState<ST> value) {
    if (mounted) { super.state = value; }
    else { Log.e('Cannot set state when widget is not mounted'); }
  }

  set data(ST data) {
    if (mounted) { state = state.copyWith(data: data); }
    else { Log.e('Cannot set data when widget is not mounted'); }
  }

  ST get data => state.data;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § base_view_model.dart](./01-code-walk.md#3-base_view_modeldart--statenotifier--lifecycle)

**EXPLAIN:**

**`mounted` guard — defensive programming:**

```
Timeline:
t0: User opens LoginPage → LoginViewModel created, mounted = true
t1: login() called → API request starts (async)
t2: User presses Back → LoginPage disposed → mounted = false
t3: API response arrives → set state → 💥 (without guard)
```

Với guard:
```dart
set state(CommonState<ST> value) {
  if (mounted) { super.state = value; }    // ✅ safe update
  else { Log.e('...'); }                    // ⚠️ log, don't crash
}
```

> ⚠️ **Flutter không auto-cancel async khi widget unmount** (khác React useEffect cleanup). Trong BaseViewModel, `dispose()` được gọi — nhưng pending Futures vẫn complete. Dùng `CancelToken` (Dio) hoặc check `mounted` trước setState.

**`data` convenience accessor:**

```dart
// Without convenience:
state = state.copyWith(data: state.data.copyWith(email: 'new@mail.com'));

// With convenience:
data = data.copyWith(email: 'new@mail.com');
// → data setter internally: state = state.copyWith(data: newData)
```

→ Giảm boilerplate, code dễ đọc hơn.

**`initialState` — fallback pattern:**

```dart
@override
CommonState<ST> get state {
  if (mounted) return super.state;
  else { Log.e('...'); return initialState; }  // fallback
}
```

→ Nếu code cố read state sau dispose → trả `initialState` thay vì crash. Not ideal (data stale) nhưng safe.

**Loading reference counting:**

```dart
int _loadingCount = 0;

void showLoading() {
  if (_loadingCount <= 0) {
    state = state.copyWith(isLoading: true, ...);
  }
  _loadingCount++;  // luôn increment
}

void hideLoading() {
  if (_loadingCount <= 1) {
    state = state.copyWith(isLoading: false, ...);
  }
  _loadingCount--;  // luôn decrement
}
```

Parallel calls scenario:
```
fetchProfile() → showLoading() → count=1, isLoading=true
fetchNotifications() → showLoading() → count=2
fetchProfile done → hideLoading() → count=1 (isLoading vẫn true!)
fetchNotifications done → hideLoading() → count=0, isLoading=false ✅
```

> 💡 **FE Perspective**
> **Flutter:** `BaseViewModel` dùng loading counter (`showLoading`/`hideLoading`) cho concurrent requests và `mounted` flag chống setState-after-dispose. `autoDispose` lifecycle tự cleanup khi widget unmount.
> **React/Vue tương đương:** React `useRef` for mounted check + `useReducer` aggregate state (React 18 auto-batches), Vue `onBeforeUnmount` flag + `ref()` composable, Angular `takeUntilDestroyed()` pipe.
> **Khác biệt quan trọng:** Flutter cần manual batching qua loading count, React 18 auto-batches. Vue auto-handles unmount cleanup via `watchEffect` scope, Flutter cần explicit `mounted` check.

---

## 4. runCatching — Centralized Error Handling Pattern 🔴 MUST-KNOW

**WHY:** Mỗi ViewModel method cần try/catch + loading + error dispatch → massive duplication. Thay đổi error strategy → sửa N chỗ.

> 🧠 **Mental Model:** Think of `runCatching` as `useQuery({ retry: 2, onError, onSettled })` from React Query — but for any async action, not just data fetching.

> Chi tiết parameters xem [Code Walk § runCatching](./01-code-walk.md#31-runcatching--centralized-error-handling). Dưới đây chia làm 2 phần: **Basic** (pattern cơ bản) và **Advanced** (parameters nâng cao).

### 4a. Basic Pattern — try → success → catch → failure

**Before (không dùng runCatching):**
```dart
// ❌ Mỗi method tự handle — 30+ lines boilerplate:
Future<void> login() async {
  try {
    showLoading();
    startAction('login');
    await _doLogin();
    hideLoading();
    stopAction('login');
  } catch (e) {
    hideLoading();
    stopAction('login');
    final appException = e is AppException
        ? e
        : AppUncaughtException(rootException: e);
    exception = appException; // dispatch lên ExceptionHandler
  }
}

Future<void> fetchProfile() async {
  try {
    showLoading();
    await _fetchProfile();
    hideLoading();
  } catch (e) {
    hideLoading();
    // ... lại cùng pattern — DUPLICATE!
  }
}
```

**After (dùng runCatching):**
```dart
// ✅ Centralized — chỉ khai báo business logic:
Future<void> login() async {
  await runCatching(
    action: () async => await _doLogin(),
    actionName: 'login',
  );
}

Future<void> fetchProfile() async {
  await runCatching(
    action: () async => await _fetchProfile(),
  );
}
```

→ Loading, error wrap, retry, action tracking — tất cả được `runCatching` handle. Thay đổi error strategy → sửa 1 chỗ (base_view_model.dart), không sửa N methods.

**Flow cơ bản:**
```
try {  showLoading → action() → hideLoading → doOnSuccessOrError  }
catch { wrap AppException → hideLoading → doOnSuccessOrError → doOnError → set exception }
finally { doOnCompleted }
```

**3 error handling strategies qua `handleErrorWhen`:**

| Strategy | `handleErrorWhen` | `doOnError` | Kết quả |
|----------|-------------------|-------------|---------|
| **Global dialog** | `null` (default true) | `null` | Exception → `ExceptionHandler` → dialog |
| **Inline error** | `(_) => false` | set `onPageError` | Error hiển thị trên form, không popup |
| **Mixed** | conditional | set local + partial global | Một số error inline, một số popup |

**Login example — inline strategy:**
```dart
await runCatching(
  action: () async { ... },
  handleErrorWhen: (_) => false,    // suppress global dialog
  doOnError: (e) async {
    data = data.copyWith(onPageError: e.message);  // inline error trên form
  },
);
```

### 4b. Advanced — retry, timeout, handleLoading

> 📖 Full parameter list → xem [01-code-walk §3.1 — runCatching](./01-code-walk.md#31-runcatching--centralized-error-handling)

**Retry chain — recursive pattern:**

```
runCatching(maxRetries: 2)
  └→ fail → appException.onRetry = () {
       doOnRetry()              // e.g. refresh token
       runCatching(maxRetries: 1)  // recursive
         └→ fail → appException.onRetry = () {
              doOnRetry()
              runCatching(maxRetries: 0)  // last attempt
                └→ fail → no retry, dispatch error
            }
     }
```

→ User tap "Retry" trên error dialog → `appException.onRetry()` → chain execute. `maxRetries` đếm ngược đến 0 → stop.

**`handleLoading` parameter:**

| `handleLoading` | `showLoading` / `hideLoading` | `startAction` / `stopAction` | Use case |
|-----------------|-------------------------------|------------------------------|----------|
| `true` (default) | ✅ Gọi | ✅ Gọi (nếu có `actionName`) | Hầu hết actions |
| `false` | ❌ Không | ❌ Không | Background sync, silent refresh |

> ⚠️ **Gotcha: `handleLoading: false` cũng disable `startAction`/`stopAction`**
> `startAction(actionName)` nằm **bên trong** `if (handleLoading)` block. Nếu cần track action mà không cần loading overlay → phải tự gọi `startAction`/`stopAction` trong action closure.

**`doOnSuccessOrError` vs `doOnCompleted`:**

| Callback | Khi nào chạy | Trong block nào |
|----------|-------------|-----------------|
| `doOnSuccessOrError` | Sau success **hoặc** sau error | `try` / `catch` |
| `doOnCompleted` | **Luôn luôn** (cả success, error, exception trong callbacks) | `finally` |

→ `doOnSuccessOrError`: cleanup sau business logic (e.g., close modal). `doOnCompleted`: guaranteed cleanup (e.g., release resources).

**`on Object catch (e)` — comprehensive catching:**

Dart cho phép `throw 'string'` hoặc `throw 42`. Chỉ `catch (e)` bắt `Exception` + `Error`. `on Object` bắt **mọi thứ** — defensive pattern cho production code nơi third-party libs có thể throw non-standard types.

### Decision Matrix — Khi nào dùng gì?

| Scenario | Method | Ví dụ |
|----------|--------|-------|
| Swallow specific error, continue flow | `handleErrorWhen` | Network timeout → show cached data |
| Side effect on error (log, track) | `doOnError` | Log error → Crashlytics |
| Transform error type | `mapError` | `DioException` → `AppException` |
| Transform success data | `map` | `Response` → `UserModel` |
| Ignore error entirely | `handleError` | Background sync failure |

---

## 5. BasePage — Reactive UI Binding 🔴 MUST-KNOW

**WHY:** Mỗi page cần reactive listen exception, loading, analytics. Không có BasePage → mỗi page tự wire → 20-30 lines boilerplate × N pages.

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_page.dart -->
```dart
abstract class BasePage<ST extends BaseState,
        P extends ProviderListenable<CommonState<ST>>>
    extends HookConsumerWidget {
  const BasePage({super.key});

  P get provider;
  ScreenViewEvent get screenViewEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppColors.of(context);
    final loadingOverlayEntry = useState<OverlayEntry?>(null);

    ref.listen(provider.select((v) => v.appException), (prev, next) {
      if (prev != next && next != null) handleException(next, ref);
    });

    ref.listen(provider.select((v) => v.isLoading), (prev, next) { ... });

    return FocusDetector(
      onVisibilityGained: () => onVisibilityChanged(ref),
      child: buildPage(context, ref),
    );
  }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § base_page.dart](./01-code-walk.md#4-base_pagedart--reactive-ui-binding)

**EXPLAIN:**

**HookConsumerWidget — best of both:**

| Base class | Riverpod | Hooks | Use case |
|-----------|----------|-------|----------|
| `ConsumerWidget` | ✅ `ref` | ❌ | Simple read/watch |
| `HookWidget` | ❌ | ✅ `useState` | Local state |
| `HookConsumerWidget` | ✅ | ✅ | **BasePage** — cần cả hai |

**`ref.listen` vs `ref.watch` trong BasePage:**

> 📌 **ref API** (`ref.read`, `ref.watch`, `ref.listen`) và **`.select()`** được giải thích chi tiết ở [M08 § ref API](../module-08-riverpod-state/02-concept.md#4-ref-api--read-vs-watch-vs-listen--must-know) và [M08 § Selector](../module-08-riverpod-state/02-concept.md#6-selector-pattern--granular-rebuilds--must-know).
> Tóm tắt: `ref.listen` = side-effect callback (không rebuild). `ref.watch` = subscribe + rebuild widget. `.select()` = chỉ react khi field cụ thể thay đổi.

→ BasePage dùng `ref.listen` cho exception + loading → **side-effects** (show dialog, show overlay). Subclass dùng `ref.watch` trong `buildPage()` cho **reactive UI**.

**Loading overlay lifecycle:**
```
isLoading: false → true  → _showLoadingOverlay() → OverlayEntry inserted
isLoading: true → false  → _hideLoadingOverlay() → OverlayEntry removed
```

`useState<OverlayEntry?>` giữ reference → đảm bảo remove đúng entry.

**Override points cho subclass:**

| Method | Default | Override khi |
|--------|---------|-------------|
| `handleException` | Delegate to `ExceptionHandler` | Custom error UI cho specific page |
| `buildPageLoading` | `CommonProgressIndicator` | Custom loading widget |
| `onVisibilityChanged` | Log screen view | Additional analytics / refresh data |

---

## 6. Provider Wiring — StateNotifierProvider Pattern 🟡 SHOULD-KNOW

**WHY:** Provider declaration kết nối ViewModel vào Riverpod ecosystem. Sai pattern → memory leak, stale state, DI mismatch.

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/view_model/login_view_model.dart -->
```dart
final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, CommonState<LoginState>>(
  (ref) => LoginViewModel(ref),
);
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § login_view_model.dart](./01-code-walk.md#52-login_view_modeldart)

**EXPLAIN:**

> 📌 **Provider types** (Provider, StateProvider, StateNotifierProvider, FutureProvider) và **autoDispose** modifier được giải thích chi tiết ở [M08 § Provider Types](../module-08-riverpod-state/02-concept.md#2-provider-types-taxonomy--when-to-use-each--must-know) và [M08 § autoDispose](../module-08-riverpod-state/02-concept.md#5-autodispose--family-modifiers--should-know).
> Ở đây chỉ cần hiểu: `StateNotifierProvider.autoDispose` = Riverpod container cho ViewModel, tự dispose khi page navigate away.

→ Rule: **Mọi page-level ViewModel nên dùng `.autoDispose`**. Shared/global ViewModel (e.g., `sharedViewModelProvider`) không dùng.

**Provider getter pattern trong BasePage:**

```dart
class LoginPage extends BasePage<LoginState,
    StateNotifierProvider<LoginViewModel, CommonState<LoginState>>> {

  @override
  P get provider => loginViewModelProvider;
  // → BasePage dùng provider cho ref.listen
}
```

→ `P` generic constraint đảm bảo `provider` return type match `CommonState<ST>`.

**Ref injection — access other providers:**

```dart
class LoginViewModel extends BaseViewModel<LoginState> {
  LoginViewModel(this._ref) : super(...);
  final Ref _ref;

  FutureOr<void> login() async {
    await _ref.read(appNavigatorProvider).replaceAll([MainRoute()]);
    //       ↑ DI access qua Ref (M2)
  }
}
```

→ Forward ref: [M8 — State Management](../module-08-riverpod-state/) sẽ deep-dive Riverpod provider types và lifecycle.

> 💡 **FE Perspective** — So sánh chi tiết Provider types và autoDispose → xem [M08 § Provider Types](../module-08-riverpod-state/02-concept.md#2-provider-types-taxonomy--when-to-use-each--must-know) FE Perspective.
> Tóm tắt: Riverpod `autoDispose` ≈ React `useEffect` cleanup / Vue `onUnmounted` — nhưng **declarative** (modifier trên provider), không phải imperative code.

---

## 7. AppProviderObserver — Lifecycle Logging 🟢 AI-GENERATE

**WHY:** Riverpod providers tạo/dispose silently. Debug state issue → cần visibility vào lifecycle events.

<!-- AI_VERIFY: base_flutter/lib/ui/base/app_provider_observer.dart -->
```dart
class AppProviderObserver extends ProviderObserver {
  AppProviderObserver({
    this.logOnDidAddProvider = Config.logOnDidAddProvider,
    this.logOnDidDisposeProvider = Config.logOnDidDisposeProvider,
    this.logOnDidUpdateProvider = Config.logOnDidUpdateProvider,
    this.logOnProviderDidFail = Config.logOnProviderDidFail,
  });
  // ...
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_provider_observer.dart](./01-code-walk.md#6-app_provider_observerdart--lifecycle-debugging)

**EXPLAIN:**

**4 lifecycle hooks:**

| Hook | Event | Ý nghĩa |
|------|-------|---------|
| `didAddProvider` | Provider initialized | Track creation order, detect unexpected init |
| `didDisposeProvider` | Provider disposed | Confirm cleanup, detect leaks |
| `didUpdateProvider` | State changed | Debug state transitions, trace bugs |
| `providerDidFail` | Provider threw error | Catch unhandled errors, crash reporting |

**Config-gated — production không log:**

```dart
// develop.json:
{ "logOnDidUpdateProvider": true }

// production.json:
{ "logOnDidUpdateProvider": false }
```

→ Zero overhead trong production. Full visibility trong debug.

**Debugging workflow:**
1. Bật `logOnDidUpdateProvider` = true
2. Reproduce bug
3. Đọc console → thấy state transitions
4. Identify unexpected state change
5. Trace ngược ViewModel method

→ Forward ref: [M18 — Testing](../module-18-testing/) sẽ dùng observer pattern cho integration test assertions.

---

> 📋 Badge summary → xem [00-overview.md](./00-overview.md)

---

**Tiếp theo:** [03-exercise.md](./03-exercise.md) — thực hành 5 bài tập từ trace flow đến AI Prompt Dojo.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
