# Code Walk — Riverpod & State Management

> � **Module này là canonical source cho Riverpod concepts.** Các module khác (đặc biệt [M07 — Base ViewModel](../module-07-base-viewmodel/01-code-walk.md)) forward-reference đến đây cho Provider types, ref API, autoDispose, và Selector. Nếu bạn đến từ M07 → bạn đúng chỗ.

<details>
<summary>📋 Recap: M1, M7, M3 concepts (click to expand)</summary>

> - **M1:** `ProviderScope` root — wrap toàn bộ app, single container cho mọi provider ([M1 § entrypoint](../module-01-app-entrypoint/01-code-walk.md))
> - **M7:** `BaseViewModel extends StateNotifier`, `CommonState` envelope, `runCatching` centralized error handling ([M7 § viewmodel](../module-07-base-viewmodel/01-code-walk.md))
> - **M3:** `Config` flags cho `AppProviderObserver` — toggle lifecycle logging ([M3 § config](../module-03-common-layer/01-code-walk.md))
>
> Nếu chưa nắm vững → quay lại module tương ứng trước khi tiếp tục.

</details>

---

## Walk Order

> ⏭ **Đã hiểu từ M01, M02, M07?** Section 1–2 là recap ngắn từ M01 (ProviderScope), M02 (DI Bridge), M07 (BaseViewModel). Nếu bạn đã nắm vững → nhảy đến [§3. SharedViewModel & Shared Providers](#3-sharedviewmodel--shared-providers--global-state) để bắt đầu nội dung mới.

```
main.dart (ProviderScope root setup)
    ↓
DI bridge providers (getIt → Provider wrappers)
    ↓
shared_view_model.dart + shared_providers.dart (global state)
    ↓
login_view_model.dart (StateNotifierProvider.autoDispose)
    ↓
base_page.dart (ref.listen + ref.watch patterns)
    ↓
app_provider_observer.dart (lifecycle debug)
```

Bắt đầu từ **container setup** (ProviderScope) → **DI bridge** (getIt ↔ Riverpod) → **shared state** (global) → **page state** (autoDispose) → **consumption** (ref API) → **debug** (observer).

---

## 1–2. ProviderScope & DI Bridge — Recap từ M01, M02, M07

> 📌 **Recap từ nhiều module**: ProviderScope root setup đã được phân tích tại [M01 § entrypoint](../module-01-app-entrypoint/01-code-walk.md), DI Bridge pattern (getIt → Provider wrapper) tại [M02 § architecture](../module-02-architecture-barrel/01-code-walk.md), và BaseViewModel / state tại [M07 § viewmodel](../module-07-base-viewmodel/01-code-walk.md). Phần dưới đây chỉ recap các điểm then chốt, rồi focus vào nội dung MỚI của M08.

**Recap nhanh (5 điểm):**
1. `ProviderScope` — root container tạo `ProviderContainer` ẩn, **phải** là ancestor cao nhất ([M01](../module-01-app-entrypoint/01-code-walk.md))
2. getIt init **trước** ProviderScope → DI sẵn sàng khi providers resolve (`WidgetsFlutterBinding → Firebase → getIt → ProviderScope → MyApp`) ([M02](../module-02-architecture-barrel/01-code-walk.md))
3. DI Bridge: `Provider((ref) => getIt.get<T>())` — wrap infrastructure services vào Riverpod → testable (override), observable ([M02](../module-02-architecture-barrel/01-code-walk.md))
4. `ref.read` = one-time access (event handlers), `ref.watch` = reactive subscription (chỉ trong `build()`)
5. `autoDispose` = tự cleanup khi không còn listener

**DI Bridge — quy tắc trong base_flutter:**
- **Infrastructure services** (Navigator, Preferences, Firebase): getIt register + Provider wrap
- **ViewModels**: Riverpod native (`StateNotifierProvider`)
- **Shared state**: Riverpod native (`StateProvider`, `Provider`)

→ Chi tiết: [M01 § ProviderScope](../module-01-app-entrypoint/01-code-walk.md) · [M02 § DI Bridge](../module-02-architecture-barrel/01-code-walk.md) · [M07 § BaseViewModel](../module-07-base-viewmodel/01-code-walk.md)

---

## 3. SharedViewModel & Shared Providers — Global State

### 3a. shared_providers.dart

<!-- AI_VERIFY: base_flutter/lib/ui/shared/shared_providers.dart -->
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../index.dart';

final currentUserProvider = StateProvider<UserData>((ref) => const UserData());
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/shared/shared_providers.dart`](../../base_flutter/lib/ui/shared/shared_providers.dart)

### Phân tích

| Aspect | Detail |
|--------|--------|
| `StateProvider` | Simple mutable state — read/write trực tiếp, **không** cần StateNotifier |
| `UserData` | Default `const UserData()` — empty user khi chưa login |
| **Không** `.autoDispose` | Global — sống suốt app lifecycle |
| Dùng `ref.read/watch` | Bất kỳ page nào cũng access: `ref.watch(currentUserProvider)` |

**Khi nào dùng `StateProvider`?**
- State đơn giản, primitive-like (user data, selected tab, theme mode)
- Không cần business logic phức tạp
- Nhiều nơi cần read/write

### 3b. shared_view_model.dart

<!-- AI_VERIFY: base_flutter/lib/ui/shared/shared_view_model.dart -->
```dart
final sharedViewModelProvider = Provider((_ref) => SharedViewModel(_ref));

class SharedViewModel {
  SharedViewModel(this._ref);

  final Ref _ref;

  Future<String> get deviceToken async {
    try {
      final deviceToken = await _ref.read(firebaseMessagingServiceProvider).deviceToken;
      return deviceToken ?? '';
    } catch (e) {
      Log.e('Error getting device token: $e');
      return '';
    }
  }

  Future<void> forceLogout() async {
    try {
      await _ref.read(appPreferencesProvider).clearCurrentUserData();
    } catch (e) {
      Log.e('force logout error: $e', errorObject: e);
    } finally {
      await _ref.read(appNavigatorProvider).replaceAll([const LoginRoute()]);
    }
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/shared/shared_view_model.dart`](../../base_flutter/lib/ui/shared/shared_view_model.dart)

### Phân tích

| Aspect | Detail |
|--------|--------|
| `Provider` (read-only) | **Không** cần mutable state — SharedViewModel là utility service |
| `Ref _ref` | Access mọi provider khác — bridge tới DI ecosystem |
| **Không** extend `BaseViewModel` | Không có UI state, không cần `CommonState` envelope |
| **Không** `.autoDispose` | Global — sống suốt app lifecycle (giống services) |

**So sánh SharedViewModel vs page ViewModel:**

| | SharedViewModel | LoginViewModel |
|---|---|---|
| Provider type | `Provider` | `StateNotifierProvider.autoDispose` |
| Extends | Nothing (plain class) | `BaseViewModel<LoginState>` |
| State | None (stateless utility) | `CommonState<LoginState>` |
| Lifecycle | App-wide | Page-scoped (auto dispose) |
| Use case | Cross-cutting: logout, deviceToken | Page-specific: login flow |

---

## 4. LoginViewModel Provider — StateNotifierProvider.autoDispose

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
    data = data.copyWith(email: email, onPageError: '');
  }

  void setPassword(String password) {
    data = data.copyWith(password: password, onPageError: '');
  }

  FutureOr<void> login() async {
    await runCatching(
      action: () async {
        final email = data.email.trim();
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

### Phân tích — Provider Declaration

```dart
StateNotifierProvider.autoDispose<LoginViewModel, CommonState<LoginState>>(
//                   ^^^^^^^^^^^  ^^^^^^^^^^^^^^  ^^^^^^^^^^^^^^^^^^^^^^^
//                   modifier     notifier type   state type
  (ref) => LoginViewModel(ref),
//  ^^^    factory — tạo VM instance, pass ref cho DI access
);
```

| Component | Vai trò |
|-----------|---------|
| `StateNotifierProvider` | Riverpod provider cho `StateNotifier` subclass |
| `.autoDispose` | Tự dispose khi **không còn listener** (page pop → VM dispose) |
| `<LoginViewModel, CommonState<LoginState>>` | Generic pair: notifier class + state type |
| `(ref) => LoginViewModel(ref)` | Factory — pass `ref` cho ViewModel DI access |

**autoDispose lifecycle:**
```
Page push → provider first read → LoginViewModel created
    ↓
Page visible → ref.watch/listen active → provider alive
    ↓
Page pop → no more listeners → autoDispose triggers → VM.dispose()
    ↓
Next push → fresh LoginViewModel created (clean state)
```

→ **Memory safe:** không leak state từ page trước.

> 💡 **FE Perspective**
> **Flutter:** `.autoDispose` — provider tự dispose khi page navigate away (không còn listener). Fresh instance mỗi lần navigate lại
> **React/Vue tương đương:** React `useEffect(() => () => cleanup(), [])` — component unmount trigger cleanup. Vue `onUnmounted()` — Pinia store destroyed khi scoped component unmount
> **Khác biệt quan trọng:** Riverpod `autoDispose` là **declarative modifier** (gắn trên provider definition) — React/Vue cleanup là **imperative code** trong lifecycle hooks. Riverpod đảm bảo **zero stale state** khi navigate back — React cần manual reset.

---

## 5. BasePage — ref.listen & ref.watch Patterns

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_page.dart -->
```dart
abstract class BasePage<ST extends BaseState, P extends ProviderListenable<CommonState<ST>>>
    extends HookConsumerWidget {
  const BasePage({super.key});

  P get provider;

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
        _showLoadingOverlay(context: context, loadingOverlayEntry: loadingOverlayEntry);
      } else if (previous == true && next == false && loadingOverlayEntry.value != null) {
        _hideLoadingOverlay(loadingOverlayEntry);
      }
    });

    return FocusDetector(
      key: Key(screenViewEvent.fullKey),
      onVisibilityGained: () => onVisibilityChanged(ref),
      child: buildPage(context, ref),
    );
  }
  // ...
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/base/base_page.dart`](../../base_flutter/lib/ui/base/base_page.dart)

### Phân tích — ref.listen vs ref.watch

| API | Behavior | Use case trong BasePage |
|-----|----------|------------------------|
| `ref.listen(provider.select(...))` | **Side-effect** — callback fires khi value thay đổi, **không** trigger rebuild | Exception dialog, loading overlay |
| `ref.watch(provider)` | **Rebuild** — widget rebuild khi state thay đổi | Data display trong `buildPage()` |
| `ref.read(provider)` | **One-shot** — lấy value hiện tại, **không** subscribe | Event handlers, callbacks |

**Selector pattern — `.select((value) => value.appException)`:**
```dart
// ❌ Không selector — listen MỌI state change (email, password, loading...):
ref.listen(provider, (prev, next) { ... });

// ✅ Selector — chỉ listen khi appException thay đổi:
ref.listen(provider.select((value) => value.appException), (prev, next) { ... });
```

→ **Granular rebuild:** chỉ fire callback khi field cụ thể thay đổi. User gõ email → `state.data.email` đổi → `appException` selector **không** fire → loading overlay **không** bị ảnh hưởng.

**BasePage consumption summary:**

```
┌─ BasePage.build() ────────────────────────────────────┐
│                                                        │
│  ref.listen(select: appException) → handleException()  │
│  ref.listen(select: isLoading)    → show/hide overlay  │
│                                                        │
│  buildPage(context, ref)  ← concrete page override     │
│    └─ ref.watch(provider.select(...)) → rebuild UI     │
│    └─ ref.read(provider.notifier)     → call VM method │
│                                                        │
└────────────────────────────────────────────────────────┘
```

> 💡 **FE Perspective**
> **Flutter:** `ref.listen` (side-effect callback, không rebuild), `ref.watch` (subscribe + rebuild widget), `ref.read` (one-shot, dùng trong callbacks)
> **React/Vue tương đương:** `ref.listen` ≈ `useEffect` with dependency. `ref.watch` ≈ `useSelector` (Redux). `ref.read` ≈ `dispatch` / `store.getState()`. Vue: `watch()`, `computed`, direct access
> **Khác biệt quan trọng:** Flutter **tách biệt rõ** 3 methods với rules nghiêm ngặt (watch chỉ trong build, listen cho side-effects) — React `useEffect` làm cả hai (subscribe + side-effect), dễ nhầm lẫn. Vue `watch()` và `computed` tách biệt tốt hơn React.

---

## 6. AppProviderObserver — Lifecycle Debug

<!-- AI_VERIFY: base_flutter/lib/ui/base/app_provider_observer.dart -->
```dart
class AppProviderObserver extends ProviderObserver {
  AppProviderObserver({
    this.logOnDidAddProvider = Config.logOnDidAddProvider,
    this.logOnDidDisposeProvider = Config.logOnDidDisposeProvider,
    this.logOnDidUpdateProvider = Config.logOnDidUpdateProvider,
    this.logOnProviderDidFail = Config.logOnProviderDidFail,
  });

  final bool logOnDidAddProvider;
  final bool logOnDidDisposeProvider;
  final bool logOnDidUpdateProvider;
  final bool logOnProviderDidFail;

  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value, ProviderContainer container) {
    if (logOnDidAddProvider) {
      Log.d('didAddProvider: $provider, value: $value, container: $container');
    }
    super.didAddProvider(provider, value, container);
  }

  @override
  void didDisposeProvider(ProviderBase<Object?> provider, ProviderContainer container) {
    if (logOnDidDisposeProvider) {
      Log.d('didDisposeProvider: $provider, container: $container');
    }
    super.didDisposeProvider(provider, container);
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (logOnDidUpdateProvider) {
      Log.d(
        'didUpdateProvider: $provider, previousValue: $previousValue, newValue: $newValue, container: $container',
      );
    }
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (logOnProviderDidFail) {
      Log.e(
        'providerDidFail: $provider, error: $error, stackTrace: $stackTrace, container: $container',
      );
    }
    super.providerDidFail(provider, error, stackTrace, container);
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/base/app_provider_observer.dart`](../../base_flutter/lib/ui/base/app_provider_observer.dart)

### Phân tích

| Lifecycle event | Khi nào fires | Config flag |
|-----------------|---------------|-------------|
| `didAddProvider` | Provider lần đầu được read/watch → created | `Config.logOnDidAddProvider` |
| `didDisposeProvider` | Provider disposed (autoDispose hoặc container dispose) | `Config.logOnDidDisposeProvider` |
| `didUpdateProvider` | State thay đổi (StateNotifier emit, StateProvider update) | `Config.logOnDidUpdateProvider` |
| `providerDidFail` | Provider factory throw exception | `Config.logOnProviderDidFail` |

**Tại sao Config-gated?**
- `didUpdateProvider` fire **rất nhiều** (mỗi state change) → log quá nhiều ở production
- `didAddProvider` + `didDisposeProvider` hữu ích cho debug memory leak → enable khi develop
- `providerDidFail` nên **luôn** enable → catch provider initialization errors

**Kết nối observer với autoDispose:**
```
Page push → didAddProvider(loginViewModelProvider)
User types → didUpdateProvider(loginViewModelProvider, prev, next) × N
Page pop  → didDisposeProvider(loginViewModelProvider)
```

→ Bật `logOnDidAddProvider` + `logOnDidDisposeProvider` → verify autoDispose hoạt động đúng.

---

## 7. Provider Landscape — Full Map

Tổng hợp tất cả provider types trong base_flutter:

| Provider Type | Instances | Lifecycle | Use case |
|---------------|-----------|-----------|----------|
| `Provider` (read-only) | `appNavigatorProvider`, `appPreferencesProvider`, `exceptionHandlerProvider`, `appApiServiceProvider`, `sharedViewModelProvider`, `analyticsHelperProvider`, `connectivityHelperProvider`, `crashlyticsHelperProvider`, `firebaseMessagingServiceProvider` | App-wide (no autoDispose) | DI bridge, service wrappers |
| `StateProvider` | `currentUserProvider` | App-wide | Simple mutable global state |
| `StateNotifierProvider.autoDispose` | `loginViewModelProvider`, `homeViewModelProvider`, `splashViewModelProvider`, `mainViewModelProvider`, `myProfileViewModelProvider` | Page-scoped | ViewModel + complex state |

### Vẽ dependency graph:

```
ProviderScope (root container)
├── Provider (DI bridges) ────────────────── getIt instances
│   ├── appNavigatorProvider              ← getIt.get<AppNavigator>()
│   ├── appPreferencesProvider            ← getIt.get<AppPreferences>()
│   ├── appApiServiceProvider             ← getIt.get<AppApiService>()
│   ├── exceptionHandlerProvider          ← ExceptionHandler(ref)
│   ├── firebaseMessagingServiceProvider  ← getIt.get<FirebaseMessagingService>()
│   ├── analyticsHelperProvider           ← getIt.get<AnalyticsHelper>()
│   ├── connectivityHelperProvider        ← getIt.get<ConnectivityHelper>()
│   └── crashlyticsHelperProvider         ← getIt.get<CrashlyticsHelper>()
│
├── Provider (shared logic)
│   └── sharedViewModelProvider           → reads: firebaseMessaging, preferences, navigator
│
├── StateProvider (global mutable)
│   └── currentUserProvider               → UserData
│
└── StateNotifierProvider.autoDispose (page VMs)
    ├── loginViewModelProvider            → reads: sharedVM, preferences, navigator
    ├── homeViewModelProvider             → page state
    ├── splashViewModelProvider           → page state
    ├── mainViewModelProvider             → page state
    └── myProfileViewModelProvider        → page state
```

→ Forward [M9 — Page Structure](../module-09-page-structure/): cách concrete pages consume providers trong `buildPage()`.
→ Forward [M18 — Testing](../module-18-testing/): override providers trong `ProviderScope` cho unit test.
→ Forward [M15 — Capstone](../module-15-capstone-login/): advanced state patterns với multiple providers.

<!-- AI_VERIFY: generation-complete -->
