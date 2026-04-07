# Code Walk — Base Page, State & ViewModel

> 📌 **Recap:** M2 — DI `get_it`/`injectable`, Riverpod Provider bridge | M3 — `Result` type, `Log` utility | M4 — `AppException` hierarchy, `isForcedErrorToHandle`, `onRetry` | M5 — `AppNavigator` | M6 — `AppColors.of(context)`
> → Chưa nắm vững? Quay lại module tương ứng trước khi tiếp tục.

---

> ⚠️ **Về thứ tự Module 7 ↔ Module 8**
>
> Module này dùng Riverpod để kết nối ViewModel với UI. **Riverpod basics** (Provider types, ref API, autoDispose, Selector) được giải thích chi tiết ở [Module 08 — Riverpod State](../module-08-riverpod-state/02-concept.md). Ở đây bạn chỉ cần hiểu **đủ** để đọc code — bảng bên dưới cung cấp đúng mức đó.

> 📖 **Thuật ngữ cốt lõi cho M07 (chi tiết đầy đủ → [M08](../module-08-riverpod-state/02-concept.md))**
>
> | Thuật ngữ | Giải thích ngắn | FE tương đương |
> |-----------|----------------|----------------|
> | **StateNotifier** | Class giữ mutable state, tự thông báo khi thay đổi. ViewModel extends class này. | `useReducer` |
> | **StateNotifierProvider** | "Container" đăng ký StateNotifier vào Riverpod. | `createContext` + `Provider` wrap `useReducer` |
> | **ref.read(provider)** | Đọc **1 lần**, không lắng nghe. Dùng trong event handlers. | `store.getState()` |
> | **ref.watch(provider)** | Đọc **và rebuild** widget khi thay đổi. Dùng trong `build()`. | `useSelector(state => ...)` |
> | **autoDispose** | Tự dọn Provider khi không còn listener. Ngăn memory leak. | cleanup `useEffect` |
> | **CommonState** | Generic envelope wrap business data + loading/error flags. | `{ data, isLoading, error }` shape |

<details>
<summary>📚 Thuật ngữ nâng cao (xem đầy đủ tại M08)</summary>

> | Thuật ngữ | Giải thích ngắn | FE tương đương |
> |-----------|----------------|----------------|
> | **ref.listen(provider)** | Lắng nghe **side-effect** (không rebuild). Dùng cho snackbar, navigation. | `useEffect` + dependency |
> | **select()** | Lọc 1 phần state → widget chỉ rebuild khi phần đó thay đổi. | `useSelector(state => state.user.name)` |
> | **Consumer** | Widget cung cấp `ref` — chỉ phần bên trong rebuild. | `React.memo` + `useSelector` |
> | **freezed** | Code-gen tạo immutable data class với `copyWith`, `==`, pattern matching. | Immer.js + TS discriminated unions |
> | **@freezed** | Annotation đánh dấu class cho freezed xử lý. | Decorator `@Component` |
> | **part / part of** | Directive liên kết gen file với source file. Xem [M0 § Codegen](../module-00-dart-primer/02-concept.md#3-code-generation-pipeline--should-know). | Không tương đương — file splitting ở cấp compiler |
> | **copyWith()** | Tạo bản sao object với field chỉ định thay đổi. | `{ ...state, isLoading: true }` |
> | **build_runner / make gen** | Tool chạy code-gen — generate `.g.dart`, `.freezed.dart`. | Babel transform / TS compiler |

</details>

---

## Walk Order

```
base_state.dart (abstract marker)
    ↓
common_state.dart (generic state envelope)
    ↓
base_view_model.dart (StateNotifier + runCatching)
    ↓
base_page.dart (reactive UI binding)
    ↓
login example (concrete usage)
    ↓
app_provider_observer.dart (lifecycle debug)
    ↓
loading_state_provider.dart + base_popup.dart (phụ trợ)
```

State contract → state wrapper → ViewModel logic → Page binding → concrete example → observer → utilities.

---

## 1. base_state.dart — Abstract State Contract

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_state.dart -->
```dart
abstract class BaseState {
  const BaseState();
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/base/base_state.dart`](../../base_flutter/lib/ui/base/base_state.dart)

- `abstract` — mọi page state **phải** extend. `const` constructor — enable compile-time constant.
- Marker class constraint: `BaseViewModel<ST extends BaseState>` + `BasePage<ST, ...>` → compiler đảm bảo ViewModel và Page **luôn** match cùng state type.

---

## 2. common_state.dart — Generic State Envelope

<!-- AI_VERIFY: base_flutter/lib/ui/base/common_state.dart -->
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../index.dart';

part 'common_state.freezed.dart';

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

**Envelope pattern — tách "what" khỏi "how":**

| Field | Type | Vai trò |
|-------|------|---------|
| `data` | `T extends BaseState` | Business data — email, password, list items... |
| `appException` | `AppException?` | Error state (M4) |
| `isLoading` | `bool` | Global loading overlay |
| `isFirstLoading` | `bool` | First-load flag — skeleton vs spinner |
| `doingAction` | `Map<String, bool>` | Per-action loading — track từng button/API |

`required T data` — thiếu = compile error. Usage: `ref.watch(provider.select((s) => s.isDoingAction('login')))`.

🏁 **Checkpoint:** Đã đọc xong State layer (base_state + common_state). Tóm tắt 1 câu trước khi tiếp tục.

---

## 3. base_view_model.dart — StateNotifier + Lifecycle

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_view_model.dart -->
```dart
import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../index.dart';

abstract class BaseViewModel<ST extends BaseState> extends StateNotifier<CommonState<ST>> {
  BaseViewModel(CommonState<ST> initialState) : super(initialState) {
    this.initialState = initialState;
  }

  late final CommonState<ST> initialState;

  @override
  set state(CommonState<ST> value) {
    if (mounted) {
      super.state = value;
    } else {
      Log.e('Cannot set state when widget is not mounted');
    }
  }

  @override
  CommonState<ST> get state {
    if (mounted) {
      return super.state;
    } else {
      Log.e('Cannot get state when widget is not mounted');

      return initialState;
    }
  }

  set data(ST data) {
    if (mounted) {
      state = state.copyWith(data: data);
    } else {
      Log.e('Cannot set data when widget is not mounted');
    }
  }

  ST get data => state.data;

  int _loadingCount = 0;
  bool firstLoadingShown = false;

  set exception(AppException appException) {
    if (mounted) {
      state = state.copyWith(appException: appException);
    } else {
      Log.e('Cannot set exception when widget is not mounted');
    }
  }

  void startAction(String key) {
    if (mounted) {
      state = state.copyWith(doingAction: {...state.doingAction, key: true});
    } else {
      Log.e('Cannot start API calling when widget is not mounted', stackTrace: StackTrace.current);
    }
  }

  void stopAction(String key) {
    if (mounted) {
      state = state.copyWith(doingAction: {...state.doingAction, key: false});
    } else {
      Log.e('Cannot stop API calling when widget is not mounted', stackTrace: StackTrace.current);
    }
  }

  void showLoading() {
    if (_loadingCount <= 0) {
      state = state.copyWith(
        isLoading: true,
        isFirstLoading: !firstLoadingShown && _loadingCount == 0,
      );
      firstLoadingShown = true;
    }
    _loadingCount++;  // luôn increment
  }

  void hideLoading() {
    if (!mounted) return;
    if (_loadingCount <= 1) {
      state = state.copyWith(
        isLoading: false,
        isFirstLoading: false,
      );
    }
    _loadingCount--;  // luôn decrement
  }

  // ... runCatching (xem phần 3.1 bên dưới)
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/base/base_view_model.dart`](../../base_flutter/lib/ui/base/base_view_model.dart)

### Key patterns

- **`mounted` guard:** Mọi setter check `mounted` — async operation có thể return sau khi widget dispose → guard ngăn crash.
- **`_loadingCount` (reference counting):** Nhiều API song song → loading chỉ hide khi **tất cả** hoàn thành.
- **`data` shortcut:** `data = data.copyWith(email: 'new')` thay vì nested `state.copyWith(data: state.data.copyWith(...))`.
- **`startAction`/`stopAction`:** Per-action tracking → UI disable button cụ thể.
- **`exception` setter:** Dispatch `AppException` lên `BasePage.ref.listen` → trigger `ExceptionHandler`.

### 3a. `_loadingCount` Deep Dive — Tại sao counter, không phải bool?

**Vấn đề với bool:**
```dart
// ❌ Bool approach — race condition:
bool isLoading = false;

void fetchProfile() async {
  isLoading = true;   // → true
  await api.getProfile();
  isLoading = false;  // → false ← BUG! fetchNotifications vẫn đang chạy
}

void fetchNotifications() async {
  isLoading = true;   // → true
  await api.getNotifications();
  isLoading = false;  // → false
}

// Gọi song song:
fetchProfile();       // isLoading = true
fetchNotifications(); // isLoading = true (vẫn true)
// Profile done       // isLoading = false ← HẾT loading trong khi notifications CHƯA xong!
```

**Giải pháp — reference counting:**
```dart
int _loadingCount = 0;

void showLoading() {
  if (_loadingCount <= 0) {
    state = state.copyWith(isLoading: true, ...);
  }
  _loadingCount++;  // luôn tăng
}

void hideLoading() {
  if (_loadingCount <= 1) {
    state = state.copyWith(isLoading: false, ...);
  }
  _loadingCount--;  // luôn giảm
}
```

**Concrete trace — 2 API calls song song:**

```
┌─ Timeline ──────────────────────────────────────────────────────┐
│                                                                  │
│ t0: fetchProfile() starts                                        │
│     showLoading() → _loadingCount: 0→1, isLoading: false→TRUE    │
│                                                                  │
│ t1: fetchNotifications() starts                                  │
│     showLoading() → _loadingCount: 1→2, isLoading: TRUE (giữ)   │
│                                                                  │
│ t2: fetchProfile() done                                          │
│     hideLoading() → _loadingCount: 2→1, isLoading: TRUE (giữ!)  │
│     ↑ count=1 > 0 nên KHÔNG set false — notifications vẫn chạy  │
│                                                                  │
│ t3: fetchNotifications() done                                    │
│     hideLoading() → _loadingCount: 1→0, isLoading: TRUE→FALSE   │
│     ↑ count≤1 nên set false — TẤT CẢ API đã xong ✅             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Logic chi tiết:**
- `showLoading()`: chỉ set `isLoading: true` khi `_loadingCount <= 0` (lần đầu) → tránh emit state thừa
- `hideLoading()`: chỉ set `isLoading: false` khi `_loadingCount <= 1` (lần cuối) → đảm bảo tất cả API xong
- Counter **luôn** tăng/giảm bất kể điều kiện → đếm chính xác số operations đang chạy
- `isFirstLoading`: flag riêng cho lần load đầu tiên → UI có thể show skeleton thay vì spinner

---

### 3.1 runCatching — Centralized Error Handling

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_view_model.dart -->
```dart
  Future<void> runCatching({
    required Future<void> Function() action,
    Future<void> Function()? doOnRetry,
    Future<void> Function(AppException)? doOnError,
    Future<void> Function()? doOnSuccessOrError,
    Future<void> Function()? doOnCompleted,
    bool handleLoading = true,
    FutureOr<bool> Function(AppException)? handleRetryWhen,
    FutureOr<bool> Function(AppException)? handleErrorWhen,
    int? maxRetries = 2,
    String? actionName,
  }) async {
    assert(maxRetries == null || maxRetries >= 0, 'maxRetries must be positive');
    try {
      if (handleLoading) {
        showLoading();
        if (actionName != null) {
          startAction(actionName);
        }
      }

      await action.call();

      if (handleLoading) {
        hideLoading();
        if (actionName != null) {
          stopAction(actionName);
        }
      }
      await doOnSuccessOrError?.call();
    } on Object catch (e) {
      final appException = e is AppException
          ? e
          : AppUncaughtException(rootException: e);

      if (handleLoading) {
        hideLoading();
        if (actionName != null) {
          stopAction(actionName);
        }
      }
      await doOnSuccessOrError?.call();
      await doOnError?.call(appException);

      if (await handleErrorWhen?.call(appException) != false ||
          appException.isForcedErrorToHandle) {
        final shouldRetryAutomatically =
            await handleRetryWhen?.call(appException) != false &&
            (maxRetries == null || maxRetries - 1 >= 0);
        final shouldDoBeforeRetrying = doOnRetry != null;

        if (shouldRetryAutomatically || shouldDoBeforeRetrying) {
          appException.onRetry = () async {
            if (shouldDoBeforeRetrying) {
              await doOnRetry.call();
            }
            if (shouldRetryAutomatically) {
              await runCatching(
                action: action,
                doOnCompleted: doOnCompleted,
                doOnSuccessOrError: doOnSuccessOrError,
                doOnError: doOnError,
                doOnRetry: doOnRetry,
                handleErrorWhen: handleErrorWhen,
                handleLoading: handleLoading,
                handleRetryWhen: handleRetryWhen,
                maxRetries: maxRetries?.minus(1), // `minus(n)` là custom extension trên `num` — tương đương `- n`. Defined trong `lib/common/extension/`.
              );
            }
          };
        }

        exception = appException;
      }
    } finally {
      await doOnCompleted?.call();
    }
  }
```
<!-- END_VERIFY -->

**Flow:**

```
┌─ runCatching ──────────────────────────────────┐
│  try {                                          │
│    showLoading() + startAction(name)            │
│    await action()          ← business logic     │
│    hideLoading() + stopAction(name)             │
│    doOnSuccessOrError()                         │
│  } catch {                                      │
│    wrap → AppException                          │
│    hideLoading() + stopAction(name)             │
│    doOnSuccessOrError() → doOnError()           │
│    handleErrorWhen?                             │
│      true/forced → build retry + set exception  │
│      false → swallow (handle local)             │
│  } finally { doOnCompleted() }                  │
└─────────────────────────────────────────────────┘
```

**Key params:** `handleErrorWhen: (_) => false` → error không dispatch lên ExceptionHandler (handle local). `maxRetries: 2` → retry chain: fail → retry(1) → retry(0) → dispatch. `on Object catch (e)` — Dart cho phép throw bất kỳ Object nào.

> 📊 **Truth Table — `runCatching` × `CommonState` States**
>
> `runCatching` điều khiển 5 field trong `CommonState`. Bảng dưới mô tả **mọi trạng thái có thể xảy ra** và giá trị tương ứng:
>
> | State | `isLoading` | `isFirstLoading` | `data` | `appException` | `doingAction[name]` | Khi nào xảy ra? |
> |-------|:-----------:|:-----------------:|--------|:--------------:|:-------------------:|-----------------|
> | **Initial** | `false` | `false` | `T` (default) | `null` | `false` / absent | Chưa gọi `runCatching` — state khởi tạo từ constructor |
> | **Loading** | `true` | `true` (lần đầu) / `false` | previous `T` | `null` | `true` (nếu có `actionName`) | `runCatching` bắt đầu — `showLoading()` + `startAction()` đã gọi |
> | **Success** | `false` | `false` | updated `T` | `null` | `false` | `action()` hoàn thành không lỗi → `hideLoading()` + `stopAction()` |
> | **Error (global)** | `false` | `false` | previous `T` | `AppException` (có `onRetry`) | `false` | `action()` throw + `handleErrorWhen != false` → dispatch lên `ExceptionHandler` |
> | **Error (local)** | `false` | `false` | previous / updated `T` | `null` | `false` | `action()` throw + `handleErrorWhen: (_) => false` → chỉ chạy `doOnError`, **không** set `exception` |
>
> **Lưu ý quan trọng:**
> - **Error (global)** vs **(local)**: khác nhau ở `handleErrorWhen`. Global → dialog/snackbar qua `ExceptionHandler`. Local → xử lý inline (VD: `data.copyWith(onPageError: e.message)`).
> - `isFirstLoading` chỉ `true` **đúng 1 lần** (lần gọi `showLoading()` đầu tiên) → UI dùng cho skeleton placeholder.
> - `doingAction` chỉ được track khi truyền `actionName` — cho phép disable button cụ thể trong khi API đang chạy.
> - Ở state **Error (global)**, `appException.onRetry` chứa closure để retry — `BasePage.ref.listen` sẽ nhận và hiển thị dialog với nút Retry.

> 🔗 **FE Perspective — So sánh với React/JS**
>
> Trong React, bạn thường quản lý 3 state riêng biệt:
> ```js
> const [data, setData] = useState(null);
> const [loading, setLoading] = useState(false);
> const [error, setError] = useState(null);
> ```
> Vấn đề: 3 state rời rạc dễ **mất đồng bộ** — quên set `loading = false` khi error, hoặc quên clear `error` khi retry.
>
> Flutter's `runCatching` + `CommonState` gom **tất cả** vào 1 object duy nhất và **tự động** chuyển state:
> - `showLoading()` / `hideLoading()` — tương tự `setLoading(true/false)` nhưng **tự gọi** trong `runCatching`
> - `exception = appException` — tương tự `setError(err)` nhưng chỉ fire khi `handleErrorWhen` cho phép
> - `data = data.copyWith(...)` — tương tự `setData({...data, field: value})`
>
> → Tương đương gần nhất trong JS ecosystem: **`react-query` (`useQuery`)** hoặc **`SWR`** — cả hai cũng gom `{ data, isLoading, error }` vào 1 object và tự quản lý state transitions.

🏁 **Checkpoint:** Đã đọc xong `base_view_model.dart` — core ViewModel logic. Tóm tắt 1 câu trước khi tiếp tục.

---

## 4. base_page.dart — Reactive UI Binding

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_page.dart -->
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../index.dart';

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

    ref.listen(
      provider.select((value) => value.appException),
      (previous, next) {
        if (previous != next && next != null) {
          handleException(next, ref);
        }
      },
    );

    ref.listen(provider.select((value) => value.isLoading), (previous, next) {
      if (next == true && loadingOverlayEntry.value == null) {
        _showLoadingOverlay(
            context: context, loadingOverlayEntry: loadingOverlayEntry);
      } else if (previous == true &&
          next == false &&
          loadingOverlayEntry.value != null) {
        _hideLoadingOverlay(loadingOverlayEntry);
      }
    });

    return FocusDetector(
      key: Key(screenViewEvent.fullKey),
      onVisibilityGained: () => onVisibilityChanged(ref),
      child: buildPage(context, ref),
    );
  }

  Widget buildPage(BuildContext context, WidgetRef ref);

  Future<void> handleException(
      AppException appException, WidgetRef ref) async {
    await ref.read(exceptionHandlerProvider).handleException(appException);
  }

  void onVisibilityChanged(WidgetRef ref) {
    ref.read(analyticsHelperProvider).logScreenView(screenViewEvent);
  }

  Widget buildPageLoading() => const CommonProgressIndicator();

  // ... _showLoadingOverlay, _hideLoadingOverlay (Overlay management)
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/base/base_page.dart`](../../base_flutter/lib/ui/base/base_page.dart)

**`build()` — 3 responsibilities:**

1. **`AppColors.of(context)`** — Init theme colors (M6)
2. **`ref.listen` appException** — ViewModel set `exception` → `handleException()` → delegate `ExceptionHandler` (M4)
3. **`ref.listen` isLoading** — show/hide overlay spinner via `OverlayEntry` → **zero rebuild** cho content

**Abstract contract cho subclass:**

| Method | Required | Vai trò |
|--------|----------|---------|
| `provider` getter | ✅ | ViewModel provider |
| `screenViewEvent` getter | ✅ | Analytics screen name |
| `buildPage(context, ref)` | ✅ | Actual UI |
| `handleException` | Optional | Custom error handling |

---

## 5. Login Example — Concrete Implementation

### 5.1 login_state.dart

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/view_model/login_state.dart -->
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../index.dart';

part 'login_state.freezed.dart';

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

→ `extends BaseState` + `@freezed` → immutable, `copyWith`, `==`. Computed getter `isLoginButtonEnabled` reactive qua `ref.watch`.

### 5.2 login_view_model.dart

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/view_model/login_view_model.dart -->
```dart
import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../index.dart';

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
        final deviceToken =
            await _ref.read(sharedViewModelProvider).deviceToken;
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

**Key insights:**
- `autoDispose` → tự dispose khi không còn listener
- `setEmail`/`setPassword` clear `onPageError` → error biến mất khi user type
- `handleErrorWhen: (_) => false` → error **không** trigger dialog. `doOnError` set inline error → page-level handling thay vì global popup

🏁 **Checkpoint:** Đã đọc xong Login example — concrete implementation. Tóm tắt 1 câu trước khi tiếp tục.

---

## 6. app_provider_observer.dart — Lifecycle Debugging

<!-- AI_VERIFY: base_flutter/lib/ui/base/app_provider_observer.dart -->
```dart
// AppProviderObserver extends ProviderObserver
// Config-gated logging: didAddProvider, didDisposeProvider, didUpdateProvider, providerDidFail
// Each callback guarded by Config.logOn* flags
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/base/app_provider_observer.dart`](../../base_flutter/lib/ui/base/app_provider_observer.dart)

Usage: `ProviderScope(observers: [AppProviderObserver()], child: MyApp())`.

---

## 7. Phụ trợ — LoadingStateProvider + BasePopup

### 7.1 LoadingStateProvider

<!-- AI_VERIFY: base_flutter/lib/ui/base/loading_state_provider.dart -->
```dart
class LoadingStateProvider extends InheritedWidget {
  const LoadingStateProvider({
    required this.isLoading,
    required super.child,
    super.key,
  });

  final bool isLoading;

  static bool isLoadingOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LoadingStateProvider>()
        ?.isLoading ?? false;
  }

  @override
  bool updateShouldNotify(LoadingStateProvider oldWidget) =>
      isLoading != oldWidget.isLoading;
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/base/loading_state_provider.dart`](../../base_flutter/lib/ui/base/loading_state_provider.dart)

→ Propagate `isLoading` xuống widget tree **không cần Riverpod** — cho shared components.

### 7.2 BasePopup

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_popup.dart -->
```dart
abstract class BasePopup extends StatelessWidget {
  const BasePopup({required this.popupId, super.key});

  final String popupId;
  Widget buildPopup(BuildContext context);

  @override
  Widget build(BuildContext context) => buildPopup(context);
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/base/base_popup.dart`](../../base_flutter/lib/ui/base/base_popup.dart)

→ `popupId` cho phép kiểm tra popup đã hiển thị chưa → tránh duplicate dialog khi exception fire nhiều lần.

---

## Tổng kết Walk

| Layer | File | Vai trò |
|-------|------|---------|
| State contract | `base_state.dart` | Marker class — generic constraint |
| State envelope | `common_state.dart` | Generic wrapper (data + loading + error + actions) |
| ViewModel | `base_view_model.dart` | Business logic + mounted guard + runCatching |
| Page | `base_page.dart` | Reactive UI binding (loading overlay + error handling) |
| Example | `login_state.dart` + `login_view_model.dart` | Concrete implementation |
| Observer | `app_provider_observer.dart` | Config-gated lifecycle debug logging |
| Utilities | `loading_state_provider.dart` + `base_popup.dart` | InheritedWidget loading + dialog dedup |

**Tiếp theo:** [02-concept.md](./02-concept.md) — 7 concepts rút ra từ code walk.

<!-- AI_VERIFY: generation-complete -->
