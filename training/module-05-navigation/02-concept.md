# Concepts — Navigation & Routing

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.
>
> ⚡ **Nếu bạn đang overwhelmed:** Focus vào concepts **🔴 MUST-KNOW** (#2, #3, #4) trước. Concepts 🟢 có thể quay lại sau khi cần.

---

## 1. auto_route Setup & Code Generation 🟢 AI-GENERATE

**WHY:** auto_route là foundation của toàn bộ navigation system. Hiểu config + code gen flow → biết files nào generated, cách thêm route mới, debug khi build fail.

<!-- AI_VERIFY: base_flutter/lib/navigation/routes/app_router.dart -->
```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
@LazySingleton()
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [ ... ];
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_router.dart](./01-code-walk.md#1-app_routerdart--route-tree-definition)

**EXPLAIN:**

**Code generation flow:**

```
@RoutePage() trên mỗi Page widget (LoginPage, HomePage, ...)
    ↓
dart run build_runner build
    ↓
app_router.gr.dart (generated)
    ↓
LoginRoute, HomeRoute, ... (PageRouteInfo classes)
    ↓
Dùng trong routes list & navigation calls
```

| Annotation | Đặt ở đâu | Tạo ra gì |
|-----------|----------|----------|
| `@RoutePage()` | Page widget class | Route class (`LoginRoute`) trong `.gr.dart` |
| `@AutoRouterConfig` | Router class | Route list types, route tree |
| `@RoutePage(name: 'HomeTab')` | Tab wrapper | Named tab route |

**`replaceInRouteName: 'Page,Route'`** — convention mapping:
- `LoginPage` → `LoginRoute` (PageRouteInfo)
- `HomePage` → `HomeRoute`
- `MainPage` → `MainRoute`

**`RouteType.adaptive()`** — default transition cho routes không dùng `CustomRoute`:
- iOS → `CupertinoPageRoute` (slide from right)
- Android → `MaterialPageRoute` (fade + slide up)
- Consistent UX per platform, zero config per route.

**Khi nào cần re-run build_runner?**
- Thêm/xóa `@RoutePage()` annotation
- Thay đổi route parameters (constructor params)
- Thêm/xóa routes trong `routes` getter
- **KHÔNG** cần re-run khi chỉ sửa page UI logic

> 💡 **FE Perspective**
> **Flutter:** auto_route code gen tạo type-safe route classes từ annotation `@RoutePage()` — khai báo route tree manually, code gen tạo wrappers với compile-time param checking.
> **React/Vue tương đương:** Next.js file-based routing (auto-generate routes từ file structure), `react-router-dom` v6 lazy routes.
> **Khác biệt quan trọng:** auto_route **explicit** hơn Next.js — bạn khai báo route tree manually, code gen chỉ tạo type-safe wrappers. Next.js infer routes từ file structure.

**PRACTICE:** Chạy `find lib -name "*.gr.dart"` → xem generated file. Mở `app_router.gr.dart` → tìm `LoginRoute` class và kiểm tra constructor params.

---

## 2. Route Configuration — AutoRoute vs CustomRoute 🔴 MUST-KNOW

**WHY:** Chọn sai route type → transition sai, state management lỗi, UX inconsistent. Hiểu khi nào dùng `AutoRoute` vs `CustomRoute` + nested tab pattern.

<!-- AI_VERIFY: base_flutter/lib/navigation/routes/app_router.dart -->
```dart
@override
List<AutoRoute> get routes => [
  AutoRoute(page: SplashRoute.page),                    // default adaptive
  buildCustomRoute(page: LoginRoute.page,                // custom fadeIn
      transitionsBuilder: TransitionsBuilders.fadeIn),
  buildCustomRoute(page: MainRoute.page,                 // custom fadeIn + children
      transitionsBuilder: TransitionsBuilders.fadeIn,
      children: [
        AutoRoute(page: HomeTab.page, maintainState: true,
          children: [AutoRoute(page: HomeRoute.page, initial: true)]),
        AutoRoute(page: MyProfileTab.page, maintainState: true,
          children: [AutoRoute(page: MyProfileRoute.page, initial: true)]),
      ]),
];
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_router.dart](./01-code-walk.md#1-app_routerdart--route-tree-definition)

**EXPLAIN:**

**AutoRoute vs CustomRoute:**

| Tính năng | `AutoRoute` | `CustomRoute` (via `buildCustomRoute`) |
|----------|------------|---------------------------------------|
| Transition | Platform adaptive | Custom (`fadeIn`, `bottomUp`, ...) |
| `fullscreenDialog` | `false` | `true` — iOS hiện close button thay back |
| Animation duration | Platform default | Configurable (300ms) |
| Use case | Normal pages, tab children | Feature entry points (Login, Main) |

**Nested Tab Architecture:**

```
MainRoute (CustomRoute)
├── HomeTab (AutoRoute, maintainState: true)      ← nested router
│   └── HomeRoute (initial: true)                 ← tab's initial page
│       └── DetailRoute (pushed within tab)       ← nested navigation
└── MyProfileTab (AutoRoute, maintainState: true) ← nested router
    └── MyProfileRoute (initial: true)
```

- `maintainState: true` → tab giữ **toàn bộ navigation stack** khi user switch tab. Quay lại tab → vẫn ở page cũ với state cũ.
- Mỗi tab là `AutoRouter` (extends `AutoRouter`) → có **own navigation stack**. `push()` trong tab chỉ affect tab đó.
- `initial: true` → page mặc định khi tab activate lần đầu.

> 💡 **FE Perspective**
> **Flutter:** Mỗi tab là `AutoRouter` với own navigation stack — `maintainState: true` giữ toàn bộ stack khi switch tab, `initial: true` set default page, `tabsRouter.setActiveIndex(i)` để switch.
> **React/Vue tương đương:** React Router nested `<Route>` + `<Outlet>` với `index` route, Vue `<router-view>` + `<KeepAlive>` cho state preservation.
> **Khác biệt quan trọng:** Flutter mỗi tab có own navigation stack native, React cần manual state preservation. Vue có `<KeepAlive>` built-in, React cần wrapper. Flutter switch tab bằng index, FE thường programmatic navigate to path.

**buildCustomRoute helper — DRY config:**

```dart
CustomRoute<void> buildCustomRoute({
  required PageInfo page,
  Widget Function(...)? transitionsBuilder,
  List<AutoRoute>? children,
}) {
  return CustomRoute(
    page: page,
    transitionsBuilder: transitionsBuilder ?? bottomUpTransitionBuilder,
    fullscreenDialog: true,
    barrierDismissible: false,
    duration: duration,          // 300ms
    reverseDuration: duration,   // 300ms
    children: children,
  );
}
```

→ Centralize default values. Mọi custom route dùng cùng duration, `fullscreenDialog: true`, `barrierDismissible: false`. Thay đổi 1 chỗ → affect tất cả.

**PRACTICE:** Vẽ route tree trên giấy gồm 3 levels (root → tab → page). Annotate mỗi node với route type (`AutoRoute` / `CustomRoute`) và transition.

#### Ví dụ: Route với Parameters

Trong thực tế, hầu hết các trang đều cần nhận dữ liệu từ trang trước. `auto_route` hỗ trợ route parameters natively:

> ⚠️ **Ví dụ mở rộng** (không có trong `base_flutter` — minh họa pattern cho parameterized routes):

```dart
// 1. Định nghĩa route với parameter trong Page
@RoutePage()
class UserDetailPage extends StatelessWidget {
  final int userId;
  const UserDetailPage({@PathParam('id') required this.userId});
  // ...
}

// 2. Khai báo trong router
AutoRoute(path: '/users/:id', page: UserDetailRoute.page),

// 3. Navigate với parameter
context.router.push(UserDetailRoute(userId: 42));
```

> 🔑 **Key takeaway:** Route parameters được type-safe nhờ code generation — không cần parse `String` thủ công.

---

## 3. AppNavigator Wrapper — Abstraction & DI Integration 🔴 MUST-KNOW

**WHY:** `AppNavigator` là **single entry point** cho mọi navigation trong app. Không dùng `AppRouter` trực tiếp → testable, mockable, consistent behavior.

<!-- AI_VERIFY: base_flutter/lib/navigation/app_navigator.dart -->
```dart
final appNavigatorProvider = Provider<AppNavigator>(
  (ref) => getIt.get<AppNavigator>(),
);

@LazySingleton()
class AppNavigator {
  AppNavigator(this._appRouter);      // AppRouter injected via DI
  final AppRouter _appRouter;          // private — không expose

  // ... push, pop, replace, showDialog, etc.
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_navigator.dart](./01-code-walk.md#2-app_navigatordart--navigation-abstraction-layer)

**EXPLAIN:**

**Tại sao wrap AppRouter?**

| Concern | Không wrap (dùng AppRouter trực tiếp) | Có AppNavigator wrapper |
|---------|--------------------------------------|------------------------|
| Testing | Mock `AppRouter` (auto_route internal) — khó | Mock `AppNavigator` — đơn giản |
| Popup tracking | Caller tự manage | Centralized `_popups` map |
| Root vs Tab routing | Caller tự quyết context | `isUseRootNavigator` auto-detect |
| Logging | Scattered `Log.d()` calls | Consistent per-method logging |
| DI access | `getIt.get<AppRouter>()` everywhere | `ref.read(appNavigatorProvider)` — idiomatic Riverpod |

**DI Integration — 2 layers:**

```
get_it (DI container)          Riverpod (state management)
  │                                │
  ├─ @LazySingleton()              ├─ appNavigatorProvider
  │   AppNavigator(AppRouter)      │   = Provider((ref) => getIt.get<AppNavigator>())
  │                                │
  └── AppRouter registered         └── appRouterProvider
      via @LazySingleton()             = Provider((ref) => getIt.get<AppRouter>())
```

**Consumer pattern:** ViewModel/UI đọc `ref.read(appNavigatorProvider)` → **không cần biết** DI implementation. Thay đổi DI framework → chỉ sửa Provider, consumers unchanged.

**Liên kết M4:** `ExceptionHandler` dùng `_ref.read(appNavigatorProvider).showDialog(...)` → error UI đi qua cùng navigation layer, consistent popup tracking + duplicate prevention.

> 💡 **FE Perspective**
> **Flutter:** `AppNavigator` wrapper pattern bọc `auto_route` API — thêm logic tracking, logging, simplify interface. Consumer dùng `ref.read(appNavigatorProvider)` không cần biết DI implementation.
> **React/Vue tương đương:** Custom hook `useNavigate()` wrapping `useNavigate` + `useLocation` trong React, hoặc composable `useRouter()` trong Vue.
> **Khác biệt quan trọng:** Flutter wrapper là class-based với DI inject, React/Vue dùng hook/composable pattern. Cùng idea: wrap framework API → thêm logic + simplify interface.

**PRACTICE:** Tìm tất cả nơi `appNavigatorProvider` được dùng: `grep -rn 'appNavigatorProvider' lib/`. Phân loại: navigation calls vs dialog calls vs tab calls.

### 🗺️ Navigation Flow

```mermaid
graph LR
    subgraph "AppNavigator"
        A[navigate] --> B{Route Type?}
        B -->|push| C[router.push]
        B -->|replace| D[router.replace]
        B -->|popUntil| E[router.popUntil]
    end
    
    subgraph "AppRouter"
        F[Route Tree] --> G[/login]
        F --> H[/home]
        F --> I[/home/detail/:id]
    end
    
    subgraph "Guards"
        J[AuthGuard] -->|check token| K{Authenticated?}
        K -->|yes| L[Allow]
        K -->|no| M[Redirect /login]
    end
    
    C --> F
    D --> F
    F --> J
```

---

## 4. Navigation Operations — Push, Pop, Replace, Tab Switching 🔴 MUST-KNOW

**WHY:** Đây là API bạn dùng hàng ngày. Chọn sai operation → UX bug (back button behavior, stack state).

<!-- AI_VERIFY: base_flutter/lib/navigation/app_navigator.dart -->
```dart
// push — thêm route lên stack
Future<T?> push<T>(PageRouteInfo routeInfo) => _appRouter.push<T>(routeInfo);

// replace — thay thế route hiện tại (clear popups)
Future<T?> replace<T>(PageRouteInfo routeInfo) {
  _popups.clear();
  return _appRouter.replace<T>(routeInfo);
}

// pop — smart pop (root vs tab)
Future<bool> pop<T>({T? result}) async {
  final useRootNavigator = isUseRootNavigator;
  return useRootNavigator
      ? _appRouter.maybePop<T>(result)
      : _currentTabRouterOrRootRouter.maybePop<T>(result);
}

// tab switch
void navigateToBottomTab({required int index, bool notify = true}) {
  tabsRouter?.setActiveIndex(index, notify: notify);
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § Stack Navigation](./01-code-walk.md#24-stack-navigation-operations)

**EXPLAIN:**

**Operation cheat sheet:**

| Operation | Stack before | Action | Stack after |
|-----------|------------|--------|-------------|
| `push(B)` | `[A]` | Thêm B lên top | `[A, B]` |
| `pop()` | `[A, B]` | Remove top | `[A]` |
| `replace(C)` | `[A, B]` | Thay B bằng C | `[A, C]` |
| `replaceAll([D])` | `[A, B, C]` | Clear & set | `[D]` |
| `popAndPush(E)` | `[A, B]` | Pop B rồi push E | `[A, E]` |
| `popUntilRoot()` | `[A, B, C]` | Pop đến root | `[A]` |
| `popUntilRouteName('B')` | `[A, B, C, D]` | Pop đến B | `[A, B]` |

> 💡 **FE Perspective**
> **Flutter:** Route params là typed constructor args (`push(UserRoute(id: 42))`) — code-gen tạo typed Route class, compile-time checked, không cần URL parsing.
> **React/Vue tương đương:** `navigate('/user/42')` + `useParams()` (React Router), `route.params.id` (Vue Router) — URL segments với string parsing.
> **Khác biệt quan trọng:** Flutter params là Dart objects (type-safe), FE params là URL strings phải parse (`useParams().id` returns `string`). Flutter không có URL concept, FE route = URL path.

**`maybePop` vs `pop`:**
- `maybePop` — check `canPop()` trước. Nếu stack chỉ còn 1 route → **không pop** (avoid empty navigator). Respect route guards.
- `pop` (forced) — pop bất kể. Có thể gây empty navigator → crash.
- `AppNavigator` luôn dùng `maybePop` → safe default.

**Dual navigator — khi nào root, khi nào tab:**

```
Đang ở MainRoute → HomeTab → DetailRoute
    push(SettingsRoute)  → root navigator (SettingsRoute covers tabs)
    pop() → ???

AppNavigator.isUseRootNavigator kiểm tra:
1. Có popup? → root
2. Ngoài MainRoute (Splash/Login)? → root
3. Stack ≤ 1 trong root? → tab
4. Previous route là tab? → tab. Else → root
```

**PRACTICE:** Viết pseudo-code cho flow: Login success → navigate to Main → user tap Home tab → push DetailRoute → pop back → switch to Profile tab. Mỗi step dùng operation nào?

---

## 5. Dialog & Popup Management 🟡 SHOULD-KNOW

**WHY:** Dialog/popup quản lý sai → duplicate dialogs, memory leak, dismiss handling lỗi. Pattern `_popups` map giải quyết hết.

<!-- AI_VERIFY: base_flutter/lib/navigation/app_navigator.dart -->
```dart
final _popups = <String, Completer<dynamic>>{};

Future<T?> showDialog<T>(BasePopup popup, {
  bool barrierDismissible = true,
  bool canPop = true,
}) async {
  if (_popups.containsKey(popup.popupId)) {
    return _popups[popup.popupId]!.future as Future<T?>;
  }
  _popups[popup.popupId] = Completer<T?>();
  // ... show dialog with PopScope cleanup
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § Dialog System](./01-code-walk.md#26-dialog--popup-system)

**EXPLAIN:**

**Duplicate prevention flow:**

```
API error 1 → ExceptionHandler → showDialog("error_dialog")
    → _popups["error_dialog"] = Completer → show dialog ✅

API error 2 (almost same time) → ExceptionHandler → showDialog("error_dialog")
    → _popups.containsKey("error_dialog") == true
    → return existing Completer.future → NO duplicate ✅
```

**Popup lifecycle:**

```
showDialog() → _popups[id] = Completer → Flutter showDialog()
    ↓
User dismisses (tap barrier, back button, programmatic pop)
    ↓
PopScope.onPopInvokedWithResult → _popups.remove(id)
    ↓
Completer resolves → caller receives result
```

> 💡 **FE tương đương**: `Completer<T>` = manually resolving a Promise. Giống `new Promise((resolve, reject) => { /* save resolve/reject for later */ })`. Dùng khi kết quả đến từ callback, không phải async function.

**3 dialog types managed:**

| Method | Flutter API | Use case | Cleanup |
|--------|-----------|----------|---------|
| `showDialog` | `material.showDialog` | Alert, confirm, error | `PopScope.onPopInvokedWithResult` |
| `showGeneralDialog` | `material.showGeneralDialog` | Custom animation dialog | `PopScope.onPopInvokedWithResult` |
| `showModalBottomSheet` | `material.showModalBottomSheet` | Bottom actions, filters | `PopScope.onPopInvokedWithResult` |
| `showSnackBar` | `ScaffoldMessenger.showSnackBar` | Brief messages | `Future.delayed(duration)` |

**`canPop: false` pattern:**
- `ExceptionHandler` → `showForceLogoutDialog` → `canPop: false, barrierDismissible: false`
- User **không thể dismiss** dialog → forced action required
- Dùng cho: token expired, server maintenance, critical errors

**PRACTICE:** Tìm `BasePopup` abstract class. Xem `popupId` là gì và subclasses override nó thế nào. Preview: [M9 — Page Structure](../module-09-page-structure/) đi sâu vào `ErrorDialog`, `ConfirmDialog`, `MaintenanceModeDialog`.

---

## 6. Route Guards — Access Control 🟡 SHOULD-KNOW

**WHY:** Route guard protect routes khỏi unauthorized access. Pattern này essential cho auth flow, onboarding, feature flag gates.

<!-- AI_VERIFY: base_flutter/lib/navigation/middleware/route_guard.dart -->
```dart
@Injectable()
class RouteGuard extends AutoRouteGuard {
  RouteGuard(this.appPreferences);
  final AppPreferences appPreferences;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (appPreferences.isLoggedIn) {
      resolver.next(true);
    } else {
      router.push(const LoginRoute());
      resolver.next(false);
    }
  }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § route_guard.dart](./01-code-walk.md#3-route_guarddart--auth-middleware)

**EXPLAIN:**

**Guard execution flow:**

```
User/code tries to navigate to ProtectedRoute
    ↓
auto_route checks: ProtectedRoute has guards: [RouteGuard]?
    ↓
RouteGuard.onNavigation(resolver, router)
    ↓
isLoggedIn? ──Yes──→ resolver.next(true) → navigate to ProtectedRoute ✅
    │
    No
    ↓
router.push(LoginRoute()) → redirect to login
resolver.next(false) → cancel original navigation ❌
```

**Gắn guard vào route:**

```dart
// Trong app_router.dart routes getter
AutoRoute(
  page: MainRoute.page,
  guards: [RouteGuard],  // ← gắn guard
  children: [...]
),
```

**DI injection:** `@Injectable()` → `AppPreferences` inject qua constructor. Guard **không** cần manual instantiation — auto_route gọi DI container tạo guard.

**Multiple guards:** Guards chạy **tuần tự**. Guard đầu block → guards sau không chạy.

```dart
AutoRoute(
  page: AdminRoute.page,
  guards: [RouteGuard, AdminRoleGuard],  // RouteGuard chạy trước
),
```

**Async guard pattern (nếu cần):**

```dart
@override
void onNavigation(NavigationResolver resolver, StackRouter router) async {
  final isValid = await apiClient.validateToken();  // async check
  resolver.next(isValid);
}
```

> 💡 **FE Perspective**
> **Flutter:** `AutoRouteGuard` declarative guard gắn per-route trong route config — check auth state, gọi `resolver.next()` (support async) để allow/redirect.
> **React/Vue tương đương:** React `<ProtectedRoute>` component pattern (`if (!isAuth) return <Navigate to="/login" />`), Vue Router `beforeEach()` guard.
> **Khác biệt quan trọng:** auto_route guard declarative hơn — define ở route config, không ở component level như React `<ProtectedRoute>`. Vue guard thường global, auto_route guard per-route.

**PRACTICE:** Thử gắn `RouteGuard` vào `MainRoute` trong `app_router.dart`. Chạy app chưa login → verify redirect sang `LoginRoute`. (Sau đó revert.)

### Redirect Logic & Common Guard Patterns

**Guard → Redirect → Login → Navigate back:**

```
User tap deep link → /main/profile/settings
    ↓
RouteGuard.onNavigation() → isLoggedIn == false
    ↓
router.push(LoginRoute())     ← redirect tới login
resolver.next(false)           ← cancel original navigation
    ↓
Login success → navigator.replaceAll([MainRoute()])
    ↓
User đến MainRoute (redirect back cần custom logic nếu muốn)
```

**Common guard patterns:**

| Pattern | Code | Use case |
|---------|------|----------|
| Simple auth | `if (isLoggedIn) resolver.next(true)` | Block unauthenticated access |
| Async validation | `final valid = await api.validateToken(); resolver.next(valid)` | Server-side token check |
| Role-based | `if (user.role == 'admin') resolver.next(true)` | Feature gating |
| Redirect with context | `router.push(LoginRoute(redirectTo: resolver.route.name))` | Redirect back after login |

> ⚠️ **Lưu ý:** `resolver.next()` **phải** được gọi — nếu quên, navigation sẽ hang vĩnh viễn. Guard không có timeout mặc định.

---

## 7. Deep Link & Universal Links 🟢 AI-GENERATE

> Deep link configuration là platform-specific setup nằm ngoài Flutter codebase chính. Module này chỉ giới thiệu khái niệm — chi tiết implementation xem [Module Optional B — Push & Deep Link](../module-optional-B-push-deeplink/00-overview.md).

**Khái niệm cốt lõi:**
- **Custom URI Scheme**: `yourapp://path` — dễ setup nhưng không verify được domain ownership
- **Universal Links (iOS) / App Links (Android)**: `https://domain.com/path` — cần server-side verification, production-ready

**Trong `base_flutter`:**
- File config: [AndroidManifest.xml](../../base_flutter/android/app/src/main/AndroidManifest.xml) và [Info.plist](../../base_flutter/ios/Runner/Info.plist)
- Hiện tại **chưa configure deep link** — đây là "blank slate" để practice ở Module Optional B

> 💡 **FE Perspective**
> **Flutter:** Deep link configuration nằm ở platform layer (AndroidManifest.xml, Info.plist), không phải trong Dart code
> **React/Vue tương đương:** Next.js routing tự handle URL matching; Flutter cần explicit platform config
> **Khác biệt quan trọng:** Web URLs "just work" vì browser handles routing. Mobile apps cần đăng ký URL scheme với OS trước

---

## 8. Navigator Observer — Debug & Analytics 🟢 AI-GENERATE

**WHY:** Observer = eyes on navigation stack. Debug routing bugs nhanh, foundation cho analytics (screen tracking). Codebase đã setup → bạn cần hiểu để đọc logs.

<!-- AI_VERIFY: base_flutter/lib/navigation/observer/app_navigator_observer.dart -->
```dart
class AppNavigatorObserver extends NavigatorObserver {
  static const _enableLog = Config.enableNavigatorObserverLog;

  @override
  void didPush(Route route, Route? previousRoute) {
    if (_enableLog) Log.d('didPush from ${previousRoute?.settings.name} to ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (_enableLog) Log.d('didPop ${route.settings.name}, back to ${previousRoute?.settings.name}');
  }
  // ... didRemove, didReplace
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_navigator_observer.dart](./01-code-walk.md#4-app_navigator_observerdart--navigation-event-logging)

**EXPLAIN:**

**4 navigation events:**

| Event | Triggered when | Log example |
|-------|---------------|-------------|
| `didPush` | Route added to stack | `didPush from LoginRoute to MainRoute` |
| `didPop` | Route removed (back) | `didPop DetailRoute, back to HomeRoute` |
| `didRemove` | Route removed (not top) | `didRemove SplashRoute, back to null` |
| `didReplace` | Route replaced | `didReplace LoginRoute by MainRoute` |

**Config-gated logging:**
- `Config.enableNavigatorObserverLog` — single boolean.
- `static const` — evaluated at compile time (tree-shaking friendly).
- Production → `false` → zero overhead.

**Gắn observer vào app — xem `my_app.dart`:**
```dart
MaterialApp.router(
  routerDelegate: appRouter.delegate(
    navigatorObservers: () => [AppNavigatorObserver()],
  ),
)
```

**Mở rộng: Analytics integration:**

```dart
@override
void didPush(Route route, Route? previousRoute) {
  super.didPush(route, previousRoute);
  analyticsService.logScreenView(route.settings.name ?? 'unknown');
}
```

→ Forward refs: [M7 — Base UI Framework](../module-07-base-viewmodel/) `ScreenViewEvent` integrated vào BasePage → auto track screen views.

**PRACTICE:** Bật `enableNavigatorObserverLog = true` trong Config. Chạy app, navigate qua vài screens → đọc console log. Trace push/pop sequence.

---

> 📋 Badge summary → xem [00-overview.md](./00-overview.md)

**Tiếp theo:** [03-exercise.md](./03-exercise.md) — thực hành navigation patterns.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
