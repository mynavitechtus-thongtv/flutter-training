# Concepts — Riverpod & State Management

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

> 📘 **Đây là canonical source cho Riverpod concepts** trong training path. [Module 07 — Base ViewModel](../module-07-base-viewmodel/02-concept.md) dạy cách project wrap Riverpod thành BaseViewModel pattern — module này dạy bản thân Riverpod. Nếu bạn chưa đọc M07 → nên đọc trước để hiểu **tại sao** cần custom ViewModel wrapper.

---

## 1. ProviderScope & Container — Root Setup 🔴 MUST-KNOW

**WHY:** Không có `ProviderScope` → mọi `ref.read/watch/listen` crash. Đặt sai vị trí → provider resolve trước DI init → crash.

<!-- AI_VERIFY: base_flutter/lib/main.dart -->
```dart
runApp(ProviderScope(
  observers: [AppProviderObserver()],
  child: MyApp(initialResource: initialResource),
));
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § main.dart](./01-code-walk.md#1-maindart--providerscope-root-setup)

**EXPLAIN:**

| Aspect | Detail |
|--------|--------|
| **ProviderScope** | Widget tạo `ProviderContainer` — in-memory store cho tất cả providers |
| **Single root** | Chỉ 1 ProviderScope (root) — nested scopes cho override (testing) |
| **observers** | List `ProviderObserver` — hook vào lifecycle events (add, update, dispose, fail) |
| **overrides** | Dùng trong test: `ProviderScope(overrides: [providerX.overrideWithValue(...)])` |

**ProviderContainer — invisible state store:**
```
ProviderScope
└── ProviderContainer (hidden)
    ├── appNavigatorProvider → AppNavigator instance
    ├── currentUserProvider → UserData value
    ├── loginViewModelProvider → LoginViewModel + CommonState
    └── ... mọi provider khác
```

→ Container **lazy-create** providers — chỉ resolve khi lần đầu `ref.read/watch` gọi tới.

**Overrides cho testing (forward M12):**
```dart
// Unit test — override DI bridge:
ProviderScope(
  overrides: [
    appNavigatorProvider.overrideWithValue(mockNavigator),
    appPreferencesProvider.overrideWithValue(mockPrefs),
  ],
  child: TestWidget(),
)
```

> 💡 **FE Perspective**
> **Flutter:** `ProviderScope` — root widget tạo `ProviderContainer` in-memory, hỗ trợ `overrides` array cho testing, `observers` cho lifecycle debug
> **React/Vue tương đương:** React Redux `<Provider store={store}>` / Vue `app.use(createPinia())` — root wrapper inject state management context. Test override: mock store (Redux) / `createTestingPinia({ initialState })` (Pinia)
> **Khác biệt quan trọng:** Riverpod override ở **provider level** (granular) — React/Vue override ở **store level** (toàn bộ). Riverpod `observers` hook lifecycle trực tiếp — Redux cần middleware, Pinia cần plugin.

---

## 2. Provider Types Taxonomy — When to Use Each 🔴 MUST-KNOW

**WHY:** Chọn sai provider type → overcomplicate code hoặc thiếu reactivity. Quy tắc chọn trong 10 giây.

> ⚠️ **Deprecation Note**: `StateNotifierProvider` là **legacy API** — Riverpod v2 thay bằng `NotifierProvider` / `AsyncNotifierProvider`. Tuy nhiên, patterns bạn học ở đây (state class, mutation methods, select/watch) **transfer 100%** sang Notifier v2. Codebase hiện tại dùng StateNotifier — khi migrate, chỉ đổi base class.
>
> **Tại sao vẫn dùng StateNotifier?** Codebase production dùng API cũ vì stability + migration cost. Khi bạn Google Riverpod, sẽ thấy `NotifierProvider` — **cả hai đều hoạt động**, pattern tương tự.
>
> **Quy tắc:**
> - Trong `base_flutter` → dùng `StateNotifierProvider` (theo convention hiện tại)
> - Project mới → xem xét `NotifierProvider` (API mới hơn, less boilerplate)
> - Core concepts (provider types, ref API, autoDispose) **giống nhau** giữa hai API

**Taxonomy trong base_flutter:**

| Type | Mutable? | Dispose? | Dùng cho | Ví dụ thực tế |
|------|----------|----------|----------|----------------|
| `Provider` | ❌ Read-only | ❌ App-wide | DI bridges, services, computed values | `appNavigatorProvider`, `sharedViewModelProvider` |
| `StateProvider` | ✅ Simple | ❌ App-wide | Primitive state, flags | `currentUserProvider` |
| `StateNotifierProvider` | ✅ Complex | `.autoDispose` | ViewModel + business logic | `loginViewModelProvider` |
| `FutureProvider` | ❌ Async read | Optional | One-shot async data | Config load, initial fetch |
| `StreamProvider` | ❌ Async stream | Optional | Real-time data (WebSocket, Firestore) | Không dùng trong project, available cho real-time data |

**Decision tree:**

```
Cần mutable state?
├── NO → Provider (read-only)
│   └── DI service? → Provider((ref) => getIt.get<T>())
│   └── Computed? → Provider((ref) => ref.watch(a) + ref.watch(b))
│
└── YES → Cần business logic?
    ├── NO → StateProvider (simple set/get)
    │   └── currentUserProvider, selectedTabProvider
    │
    └── YES → StateNotifierProvider
        └── Page-scoped? → .autoDispose
        └── App-wide? → no modifier
```

**Khi nào `.autoDispose`?**
- **Page ViewModel**: Luôn `.autoDispose` → dispose khi navigate away
- **Global state**: Không `.autoDispose` → persist across navigation
- **Rule of thumb**: Nếu state chỉ relevant cho 1 screen → autoDispose

**Khi nào `FutureProvider`?**
```dart
// Read-once async data — không cần setState:
final configProvider = FutureProvider<AppConfig>((ref) async {
  return await loadConfig();
});

// Trong widget:
ref.watch(configProvider).when(
  data: (config) => Text(config.apiUrl),
  loading: () => CircularProgressIndicator(),
  error: (e, s) => Text('Error: $e'),
);
```

> 💡 **FE Perspective**
> **Flutter:** 4 provider types phân biệt — `Provider` (read-only DI), `StateProvider` (simple mutable), `StateNotifierProvider` (complex logic + dispose), `FutureProvider` (async one-shot)
> **React/Vue tương đương:** `Provider` ≈ `useContext`/`provide-inject`. `StateProvider` ≈ `useState`/`ref()`. `StateNotifierProvider` ≈ `useReducer`/Pinia `defineStore`. `FutureProvider` ≈ React Query `useQuery`/`useAsyncData`
> **Khác biệt quan trọng:** Riverpod enforce pattern qua **type system** (chọn sai type → compiler cảnh báo) — React/Vue dùng chung hook primitives rồi compose theo convention. Riverpod có `.autoDispose` modifier built-in, React cần manual cleanup trong `useEffect`.

---

## 3. DI Bridge Pattern — getIt → Provider Wrapper 🟡 SHOULD-KNOW

**WHY:** base_flutter dùng **2 DI systems** — getIt (infrastructure) + Riverpod (state). Bridge pattern thống nhất access qua `ref` API, giúp **testable** + **observable**.

**Tại sao cần bridge thay vì dùng getIt trực tiếp?**

```dart
// ❌ Direct getIt — hard dependency, không override được trong test
final navigator = getIt.get<AppNavigator>();

// ✅ Bridge qua Provider — injectable, override via ProviderScope
_ref.read(appNavigatorProvider).replaceAll([...]);
```

**Ví dụ testing override:**

```dart
// In test:
ProviderScope(
  overrides: [
    apiClientProvider.overrideWithValue(MockApiClient()),
    appNavigatorProvider.overrideWithValue(MockNavigator()),
    appPreferencesProvider.overrideWithValue(MockPreferences()),
  ],
  child: MyApp(),
);
```

> 💡 **FE Perspective**: Tương tự React Context Provider wrapping mock values trong test — `<AuthContext.Provider value={mockAuth}>`. Flutter override ở **provider level** (granular per-dependency) thay vì store level.

**Quy tắc bridge:**
- **Infrastructure services** (Navigator, Preferences, Firebase): getIt register + Provider wrap
- **ViewModels**: Riverpod native (`StateNotifierProvider`) — không cần bridge
- **Shared state**: Riverpod native (`StateProvider`, `Provider`)

→ Chi tiết pattern + code examples: [01-code-walk § DI Bridge](./01-code-walk.md#2-di-bridge-providers--getit--riverpod)

---

## 4. ref API — read vs watch vs listen 🔴 MUST-KNOW

**WHY:** Dùng sai ref method → missing updates, unnecessary rebuilds, hoặc crash. Mỗi method có rules nghiêm ngặt.

**3 methods:**

| Method | Behavior | Khi nào dùng | Ví dụ |
|--------|----------|-------------|-------|
| `ref.read(p)` | One-shot, **không** subscribe | Event handlers, callbacks, ViewModel methods | `_ref.read(appNavigatorProvider).pop()` |
| `ref.watch(p)` | Subscribe + **rebuild** widget khi value đổi | `build()` method — display data | `ref.watch(provider.select((s) => s.data.email))` |
| `ref.listen(p, cb)` | Subscribe + **callback** khi value đổi, **không** rebuild | Side effects: dialog, navigation, analytics | `ref.listen(provider.select((s) => s.appException), ...)` |

**Rules — QUAN TRỌNG:**

```dart
// ✅ ĐÚNG — ref.watch trong build():
Widget build(context, ref) {
  final email = ref.watch(provider.select((s) => s.data.email));
  return Text(email);
}

// ❌ SAI — ref.watch trong callback:
onPressed: () {
  final email = ref.watch(provider); // CRASH! — watch ngoài build
}

// ✅ ĐÚNG — ref.read trong callback:
onPressed: () {
  ref.read(provider.notifier).login(); // OK — one-shot read
}
```

> 🚨 **Trap cho FE devs quen React hooks:**
> Trong React, `useSelector()` chỉ dùng trong component body — nhưng nếu dùng sai chỉ có warning. Flutter **crash thực sự** nếu gọi `ref.watch()` ngoài `build()` method.
>
> **Lỗi thường gặp:**
> ```dart
> // ❌ Gọi ref.watch trong button callback — CRASH:
> ElevatedButton(
>   onPressed: () {
>     final vm = ref.watch(loginViewModelProvider.notifier);
>     //              ^^^ Throws: "ref.watch" was called from outside build()
>     vm.login();
>   },
> )
>
> // ✅ Fix: dùng ref.read trong callback:
> ElevatedButton(
>   onPressed: () {
>     ref.read(loginViewModelProvider.notifier).login();
>   },
> )
> ```
>
> **Rule nhớ:** `ref.watch` = **build only** (subscribe + rebuild). `ref.read` = **callbacks, event handlers** (one-shot, no subscribe).

**ref.listen trong BasePage:**
```dart
// Side-effect: show dialog khi exception thay đổi
ref.listen(
  provider.select((value) => value.appException),
  (previous, next) {
    if (previous != next && next != null) {
      handleException(next, ref);  // ← side-effect, not rebuild
    }
  },
);
```

→ `ref.listen` **không** trigger rebuild — chỉ fire callback. Perfect cho: show dialog, navigate, log analytics.

> 💡 **FE Perspective**
> **Flutter:** 3 ref methods — `ref.read` (one-shot, callbacks), `ref.watch` (subscribe + rebuild, build only), `ref.listen` (subscribe + callback, side-effects) — rules nghiêm ngặt về context sử dụng
> **React/Vue tương đương:** `ref.read` ≈ `store.getState()`/direct access. `ref.watch` ≈ `useSelector()`/`computed`. `ref.listen` ≈ `useEffect` with dependency/`watch()`
> **Khác biệt quan trọng:** Flutter **crash** nếu dùng `ref.watch` ngoài `build()` — React `useSelector` cũng chỉ dùng trong component nhưng không crash mà chỉ warning. `ref.listen` tách biệt side-effects khỏi rebuild — React cần `useEffect` kết hợp cả hai.

---

## 5. autoDispose & family Modifiers 🟡 SHOULD-KNOW

**WHY:** Thiếu `autoDispose` → memory leak khi navigate away. `family` cho phép parameterized providers — reuse logic cho nhiều instances.

**autoDispose — page-scoped VM:**

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/view_model/login_view_model.dart -->
```dart
final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, CommonState<LoginState>>(
  (ref) => LoginViewModel(ref),
);
```
<!-- END_VERIFY -->

**Lifecycle:**
```
Navigate to LoginPage → ref.watch(loginViewModelProvider) lần đầu
    → Provider created → LoginViewModel() → state = CommonState(data: LoginState())
    → didAddProvider fires (observer)

Navigate away → no more listeners
    → autoDispose triggers → LoginViewModel.dispose()
    → didDisposeProvider fires (observer)
    → state wiped clean

Navigate back → fresh instance created (no stale state)
```

`.family` cho phép tạo provider với parameter — mỗi argument value tạo instance riêng biệt. Codebase hiện tại không dùng `.family`, nhưng bạn sẽ gặp khi cần provider phụ thuộc vào argument (ví dụ: `UserDetailProvider(userId)`).

> 💡 **FE Perspective**
> **Flutter:** `.autoDispose` — provider tự dispose khi không còn listener. `.family` — parameterized provider tạo instance riêng per argument
> **React/Vue tương đương:** `autoDispose` ≈ `useEffect` cleanup. `family` ≈ factory hook `useItemStore(id)`
> **Khác biệt quan trọng:** Riverpod modifiers là **declarative** (gắn trên provider definition) — React/Vue là **imperative** (code trong lifecycle hooks)

<details>
<summary>📚 Đọc thêm: `.family` modifier chi tiết</summary>

**`.family` modifier — parameterized providers:**

`.family` tạo provider factory nhận parameter → mỗi parameter value tạo **instance riêng biệt**. Ví dụ: `FutureProvider.autoDispose.family<UserData, String>((ref, userId) => ...)` — mỗi `userId` khác nhau tạo provider instance độc lập. Kết hợp `.autoDispose.family` cho detail pages: navigate away → auto disposed, navigate lại với param khác → fresh provider.

**Khi nào cần `.family`:** Detail page cần ID (`itemViewModelProvider(itemId)`), tab-specific state, multi-instance patterns (chat rooms). Parameter phải implement `==` và `hashCode` (primitives, freezed classes OK).

</details>

---

## 6. Selector Pattern — Granular Rebuilds 🔴 MUST-KNOW

**WHY:** Không dùng selector → widget rebuild mỗi khi **bất kỳ** field trong state thay đổi. 10 fields → 10x unnecessary rebuilds.

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_page.dart -->
```dart
ref.listen(
  provider.select((value) => value.appException),
  (previous, next) { ... },
);

ref.listen(
  provider.select((value) => value.isLoading),
  (previous, next) { ... },
);
```
<!-- END_VERIFY -->

**EXPLAIN:**

```dart
// State có nhiều fields:
CommonState<LoginState>(
  data: LoginState(email: 'a@b.com', password: '123', onPageError: ''),
  appException: null,
  isLoading: false,
  doingAction: {},
)

// ❌ Không selector — rebuild khi BẤT KỲ field đổi:
final state = ref.watch(loginViewModelProvider);
// User gõ email → rebuild. Loading change → rebuild. Exception → rebuild.

// ✅ Selector — chỉ rebuild khi email đổi:
final email = ref.watch(loginViewModelProvider.select((s) => s.data.email));
// Password change → KHÔNG rebuild. Loading → KHÔNG rebuild.
```

**Performance impact:**

| Pattern | User gõ 10 ký tự email | Build count cho Text('password') |
|---------|------------------------|----------------------------------|
| `ref.watch(provider)` | 10 rebuilds | ❌ 10 rebuilds (unnecessary) |
| `ref.watch(provider.select((s) => s.data.password))` | 0 rebuilds | ✅ 0 (only rebuilds when password changes) |

**Selector rule of thumb:**
- **Luôn** dùng `.select()` khi watch — trừ khi widget cần **toàn bộ** state
- Selector return type phải implement `==` (freezed classes, primitives — OK)
- Multiple fields? → Multiple `ref.watch` calls, mỗi cái select field riêng

```dart
// ✅ Granular — 2 separate watches:
final email = ref.watch(provider.select((s) => s.data.email));
final isLoading = ref.watch(provider.select((s) => s.isLoading));

// ❌ Combine vào 1 watch không selector:
final state = ref.watch(provider);
final email = state.data.email;
final isLoading = state.isLoading;
```

> 💡 **FE Perspective**
> **Flutter:** `.select()` modifier — subscribe chỉ 1 field cụ thể, widget chỉ rebuild khi field đó thay đổi. Nhiều fields → nhiều `ref.watch` calls riêng biệt
> **React/Vue tương đương:** React `useSelector(state => state.email)` (Redux) / `useMemo` + shallow compare. Vue `computed(() => store.email)` — tự động granular
> **Khác biệt quan trọng:** Vue computed **tự động** granular (dependency tracking) — không cần selector. React `useSelector` cần **manual** selector function giống Flutter. Flutter `.select()` dùng `==` comparison — cần freezed/equatable classes, React dùng `===` reference check.

---

## 7. Shared State vs Page State 🟡 SHOULD-KNOW

**WHY:** Mix global state với page state → memory leak, stale data, unintended side effects. Clear separation = predictable behavior.

**2 patterns trong base_flutter:**

| | Shared State | Page State |
|---|---|---|
| **Provider** | `Provider`, `StateProvider` | `StateNotifierProvider.autoDispose` |
| **Lifecycle** | App-wide (create once) | Page-scoped (create/dispose per navigation) |
| **Access** | Mọi page `ref.read/watch` | Chỉ page owner `ref.watch` |
| **Ví dụ** | `currentUserProvider`, `sharedViewModelProvider` | `loginViewModelProvider`, `homeViewModelProvider` |
| **Reset** | Manual (`ref.invalidate` hoặc set new value) | Automatic (autoDispose on navigate away) |

**Shared state — global mutable:**
```dart
// Bất kỳ ViewModel nào cũng update:
_ref.read(currentUserProvider.notifier).state = userData;

// Bất kỳ page nào cũng read:
final user = ref.watch(currentUserProvider);
```

**Page state — isolated:**
```dart
// Chỉ LoginPage watch:
final loginState = ref.watch(loginViewModelProvider.select((s) => s.data));

// Navigate away → loginViewModelProvider auto-disposed
// Navigate back → fresh LoginState() — no stale email/password
```

**Communication pattern — page → shared → other pages:**
```
LoginPage login success
    → LoginViewModel: _ref.read(currentUserProvider.notifier).state = user
    → currentUserProvider update
    → HomePage ref.watch(currentUserProvider) → rebuild with new user
    → MyProfilePage ref.watch(currentUserProvider) → rebuild with new user
```

→ Forward [M9](../module-09-page-structure/): concrete pages consume shared + page providers.
→ Forward [M15](../module-15-capstone-login/): advanced multi-provider coordination.

> 💡 **FE Perspective**
> **Flutter:** Shared state = `Provider`/`StateProvider` (app-wide, manual reset). Page state = `StateNotifierProvider.autoDispose` (page-scoped, auto cleanup khi navigate away)
> **React/Vue tương đương:** Shared ≈ Redux global store / Pinia global store. Page ≈ `useState`/`useReducer` (component-local) / `ref()`/`reactive()` in `setup()`
> **Khác biệt quan trọng:** Flutter page state **tự động** clean khi navigate away (`.autoDispose`) — React component state cũng tự clean khi unmount, nhưng global store cần manual reset. Communication pattern: Flutter page → shared provider → other pages rebuild. React: dispatch → Redux store → connected components re-render.

---

> 📋 Badge summary → xem [00-overview.md](./00-overview.md)
---

📖 [Glossary](../_meta/glossary.md)
<!-- AI_VERIFY: generation-complete -->
