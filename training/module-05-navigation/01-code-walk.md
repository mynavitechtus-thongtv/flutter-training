# Code Walk — Navigation & Routing

> 📌 **Recap từ modules trước:**
> - **M1:** `MaterialApp.router` + `appRouter.delegate()` — thiết lập declarative routing tại app entrypoint, `navigatorObservers` gắn `AppNavigatorObserver` ([M1 § my_app.dart](../module-01-app-entrypoint/01-code-walk.md))
> - **M2:** DI với `get_it` / `injectable` — `@LazySingleton()` cho `AppRouter` và `AppNavigator`, Riverpod Provider expose DI instance ([M2 § DI](../module-02-architecture-barrel/01-code-walk.md))
> - **M4:** `ExceptionHandler` dùng `appNavigatorProvider` để hiện error dialog/snackbar — mọi `AppExceptionAction` dispatch qua `AppNavigator.showDialog()`, `showSnackBar()` ([M4 § exception_handler.dart](../module-04-exception-handling/01-code-walk.md))
>
> Nếu chưa nắm vững → quay lại [Module 1](../module-01-app-entrypoint/), [Module 2](../module-02-architecture-barrel/) hoặc [Module 4](../module-04-exception-handling/) trước.

> ⚡ **Reading Guide — Module này dài hơn bình thường**
> Navigation là topic rộng. Đừng cố nhớ hết — hãy ưu tiên theo badge:
>
> | Ưu tiên | Sections | Badge | Hành động |
> |---------|----------|-------|-----------|
> | **Đọc kỹ** | §1 (app_router), §2.1–2.5 (app_navigator core) | 🔴 MUST-KNOW | Đọc + trace code |
> | **Đọc hiểu** | §2.6–2.8 (popup/dialog), §3 (route_guard) | 🟡 SHOULD-KNOW | Mở collapsed section khi cần |
> | **Skim** | §4 (observer) | 🟢 AI-GENERATE | Đọc overview, skip details |
>
> Quay lại sections 🟢 khi cần trong thực hành. Module 16 sẽ cover popup/dialog chi tiết hơn.

---

## Walk Order

```
app_router.dart (route tree definition)
    ↓
app_navigator.dart (navigation abstraction layer)
    ↓
route_guard.dart (auth middleware)
    ↓
app_navigator_observer.dart (logging/debugging)
```

Bắt đầu từ **route config** (what routes exist) → **navigator wrapper** (how to navigate) → **guard** (who can access) → **observer** (what happened).

---

## 1. app_router.dart — Route Tree Definition

<!-- AI_VERIFY: base_flutter/lib/navigation/routes/app_router.dart -->
```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../index.dart' hide PageInfo;

final appRouterProvider = Provider<AppRouter>(
  (ref) => getIt.get<AppRouter>(),
);

@AutoRouterConfig(
  replaceInRouteName: 'Page,Route',
)
@LazySingleton()
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  static const duration = Duration(milliseconds: 300);

  Widget bottomUpTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0))
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    );
  }

  CustomRoute<void> buildCustomRoute({
    required PageInfo page,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)? transitionsBuilder,
    List<AutoRoute>? children,
  }) {
    return CustomRoute(
      page: page,
      transitionsBuilder: transitionsBuilder ?? bottomUpTransitionBuilder,
      fullscreenDialog: true,
      barrierDismissible: false,
      duration: duration,
      reverseDuration: duration,
      children: children,
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: SplashRoute.page),
        buildCustomRoute(page: LoginRoute.page, transitionsBuilder: TransitionsBuilders.fadeIn),
        buildCustomRoute(
            page: MainRoute.page,
            transitionsBuilder: TransitionsBuilders.fadeIn,
            children: [
              AutoRoute(
                page: HomeTab.page,
                maintainState: true,
                children: [
                  AutoRoute(page: HomeRoute.page, initial: true),
                ],
              ),
              AutoRoute(
                page: MyProfileTab.page,
                maintainState: true,
                children: [
                  AutoRoute(page: MyProfileRoute.page, initial: true),
                ],
              ),
            ]),
      ];
}

@RoutePage(name: 'HomeTab')
class HomeTabPage extends AutoRouter {
  const HomeTabPage({super.key});
}

@RoutePage(name: 'MyProfileTab')
class MyProfileTabPage extends AutoRouter {
  const MyProfileTabPage({super.key});
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/navigation/routes/app_router.dart)

> 🔎 **Quan sát**
> - `@AutoRouterConfig(replaceInRouteName: 'Page,Route')` — code gen convention: `LoginPage` → `LoginRoute`. auto_route generate file `.gr.dart` chứa `PageRouteInfo` cho mỗi route.
> - `@LazySingleton()` — singleton qua DI (injectable), **không** tạo nhiều instance. `appRouterProvider` expose cho Riverpod.
> - `RootStackRouter` — base class từ auto_route, quản lý **root navigation stack**. Giống `BrowserRouter` ở FE.
> - `RouteType.adaptive()` — iOS dùng Cupertino transition, Android dùng Material transition. Tự detect platform.
> - `buildCustomRoute()` — helper tạo `CustomRoute` với default transition (bottom-up slide), `fullscreenDialog: true`, animation duration 300ms. Tránh duplicate config.
> - **Route tree structure:**
>   ```
>   / (root)
>   ├── SplashRoute        (AutoRoute — default adaptive)
>   ├── LoginRoute         (CustomRoute — fadeIn)
>   └── MainRoute          (CustomRoute — fadeIn)
>       ├── HomeTab        (nested tab — maintainState)
>       │   └── HomeRoute  (initial: true)
>       └── MyProfileTab   (nested tab — maintainState)
>           └── MyProfileRoute (initial: true)
>   ```
> - `maintainState: true` — tab giữ state khi switch qua tab khác. Nếu `false` → rebuild mỗi lần switch.
> - `HomeTabPage extends AutoRouter` + `@RoutePage(name: 'HomeTab')` — mỗi tab là một **nested router** (sub-stack). Có thể push nhiều pages trong cùng tab.
> - `initial: true` trên `HomeRoute` — trang mặc định khi vào tab.
> - **Hỏi:** `SplashRoute` dùng `AutoRoute` (default) trong khi `LoginRoute` dùng `buildCustomRoute` (CustomRoute). Tại sao khác nhau?
> - **Hỏi:** Nếu muốn thêm `SettingsRoute` dưới `MyProfileTab` → cần sửa ở đâu?

> 💡 **FE Perspective**
> **Flutter:** Route tree khai báo trong `app_router.dart` với nested `AutoRoute` children — auto_route dùng **code generation** (`.gr.dart`) tạo type-safe route params, compile-time check. `maintainState: true` giữ tab state alive khi switch.
> **React/Vue tương đương:** React Router v6 nested `<Routes>` + `<Route>` với `<Outlet>`, Vue Router nested routes config.
> **Khác biệt quan trọng:** auto_route dùng code generation → compile-time safety, React Router dùng string paths → runtime errors nếu typo. `maintainState` cần wrapper keep-alive trong React.

### Code Generation Output — `.gr.dart`

Khi chạy `dart run build_runner build`, auto_route generate file `app_router.gr.dart` chứa route classes:

```dart
// ============ GENERATED — KHÔNG SỬA TRỰC TIẾP ============
// app_router.gr.dart (auto-generated)

class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(LoginRoute.name, initialChildren: children);
  static const String name = 'LoginRoute';
  static const PageInfo page = PageInfo(name);
}

class HomeRoute extends PageRouteInfo<void> { /* tương tự */ }
class MainRoute extends PageRouteInfo<void> { /* tương tự */ }
```

> ⚠️ **Đây là code-gen — KHÔNG sửa trực tiếp file `.gr.dart`.** Mọi thay đổi sẽ bị overwrite khi chạy `build_runner` lần sau. Chỉ sửa source: `@RoutePage()` annotation trên Page widgets và `routes` getter trong `AppRouter`.

> 🏁 **Checkpoint – Route Tree & Code Generation**
>
> Trước khi tiếp tục, hãy tự kiểm tra:
> - [ ] Hiểu cấu trúc route tree: `SplashRoute` → `LoginRoute` → `MainRoute` với nested tabs (`HomeTab`, `MyProfileTab`)
> - [ ] Phân biệt được `AutoRoute` (default adaptive) vs `CustomRoute` (custom transition qua `buildCustomRoute`)
> - [ ] Biết `@AutoRouterConfig(replaceInRouteName: 'Page,Route')` sinh ra file `.gr.dart` — và **không bao giờ sửa trực tiếp** file generated
> - [ ] Hiểu `maintainState: true` giữ state khi switch tab, `initial: true` đánh dấu trang mặc định trong tab
>
> 👉 Nếu chưa chắc, hãy đọc lại phần trên trước khi tiếp tục.

---

## 2. app_navigator.dart — Navigation Abstraction Layer

<!-- AI_VERIFY: base_flutter/lib/navigation/app_navigator.dart -->

File 423 lines — đây là **core navigation wrapper**. Đi từng section.

### 2.1. Provider & Class Declaration

```dart
final appNavigatorProvider = Provider<AppNavigator>(
  (ref) => getIt.get<AppNavigator>(),
);

@LazySingleton()
class AppNavigator {
  AppNavigator(this._appRouter);

  final tabRoutes = const [HomeTab(), MyProfileTab()];
  TabsRouter? tabsRouter;
  final AppRouter _appRouter;
  final _popups = <String, Completer<dynamic>>{};
```

> 🔎 **Quan sát**
> - `appNavigatorProvider` — Riverpod Provider wrapping DI singleton. **Đây chính là cầu nối giữa DI layer (get_it) và state management (Riverpod).**
> - `_appRouter` là **private** — bên ngoài không access trực tiếp `AppRouter`. Mọi navigation phải qua `AppNavigator` methods → **abstraction layer** cho testability.
> - `tabRoutes` — khai báo thứ tự tabs tương ứng với `AutoTabsScaffold` trong `MainPage`.
> - `tabsRouter` — set bởi `MainPage` khi `AutoTabsScaffold` init. `nullable` vì chưa có khi app ở Splash/Login.
> - `_popups: Map<String, Completer>` — tracking active popups để **prevent duplicate dialogs**. Key = `popupId`, Value = `Completer` để await result.

### 2.2. Context & State Helpers

```dart
  StackRouter? get _currentTabRouter =>
      tabsRouter?.stackRouterOfIndex(currentBottomTab);
  StackRouter get _currentTabRouterOrRootRouter =>
      _currentTabRouter ?? _appRouter;

  BuildContext get rootRouterContext =>
      _appRouter.navigatorKey.currentContext!;
  BuildContext? get _currentTabRouterContext =>
      _currentTabRouter?.navigatorKey.currentContext;
  BuildContext get _currentTabContextOrRootContext =>
      _currentTabRouterContext ?? rootRouterContext;

  int get currentBottomTab {
    if (tabsRouter == null) {
      throw 'Not found any TabRouter';
    }

    return tabsRouter?.activeIndex ?? 0;
  }
  bool get canPopSelfOrChildren => _appRouter.canPop();
```

> 🔎 **Quan sát**
> - **Dual context system:** `rootRouterContext` (root navigator) vs `_currentTabRouterContext` (tab navigator). Dialog cần root context, tab navigation cần tab context.
> - `_currentTabRouterOrRootRouter` — fallback pattern: nếu đang ở Splash/Login (chưa có tab) → dùng root router.
> - `canPopSelfOrChildren` — check stack có route nào pop được không. Useful cho back button handling.

### 2.3. isUseRootNavigator — Smart Context Detection

> 🧠 **TL;DR:** Quyết định navigation target **full-screen** navigator hay **in-tab** navigator. Default: có popup → root navigator. Trong tab → tab navigator. Bạn hiếm khi cần hiểu chi tiết internals.

> 🔎 **Quan sát**
> - Logic phức tạp nhất trong file — quyết định **dùng root navigator hay tab navigator** cho mỗi thao tác.
> - Có popup (non-SnackBar) → root navigator (popup nằm trên root).
> - Không có `MainRoute` trong stack → đang ở Splash/Login → root.
> - Stack ≤ 1 → tab navigator (đang ở tab level).
> - Previous route thuộc tab → tab navigator. Ngược lại → root.
> - **Hỏi:** Tại sao SnackBar được exclude khỏi popup check? (hint: SnackBar không push route, dùng `ScaffoldMessenger`)

<details><summary>📖 Full implementation (click to expand)</summary>

```dart
  bool get isUseRootNavigator {
    final stack = _appRouter.current.router.stack;

    if (_popups.isNotEmpty && _popups.keys.any((key) => !key.contains('SnackBar')))
      return true;

    if (!stack.any((r) => r.routeData.name == _mainRoute)) return true;

    if (stack.length <= 1) return false;

    final previousRoute = stack[stack.length - 2];
    if (checkExistsRouteInStack(
      routeName: _mainRoute,
      routerData: previousRoute.routeData,
    )) {
      return !tabRoutes.any((tab) => tab.routeName == previousRoute.routeData.name);
    }
    return true;
  }
```

</details>

### 2.4. Stack Navigation Operations

```dart
  Future<T?> push<T extends Object?>(PageRouteInfo routeInfo, {String? name}) {
    if (Config.enableNavigatorObserverLog) Log.d('push $routeInfo');
    return _appRouter.push<T>(routeInfo.copyWith(name: name));
  }

  Future<void> pushAll(List<PageRouteInfo> listRouteInfo) {
    return _appRouter.pushAll(listRouteInfo);
  }

  Future<T?> replace<T extends Object?>(PageRouteInfo routeInfo) {
    _popups.clear();
    return _appRouter.replace<T>(routeInfo);
  }

  Future<void> replaceAll(List<PageRouteInfo> listRouteInfo, {
    bool updateExistingRoutes = true,
  }) {
    _popups.clear();
    return _appRouter.replaceAll(listRouteInfo, updateExistingRoutes: updateExistingRoutes);
  }

  Future<bool> pop<T extends Object?>({T? result}) async {
    final useRootNavigator = isUseRootNavigator;
    return useRootNavigator
        ? _appRouter.maybePop<T>(result)
        : _currentTabRouterOrRootRouter.maybePop<T>(result);
  }

  Future<T?> popAndPush<T extends Object?, R extends Object?>(
    PageRouteInfo routeInfo, {R? result}) {
    final useRootNavigator = isUseRootNavigator;
    return useRootNavigator
        ? _appRouter.popAndPush<T, R>(routeInfo, result: result)
        : _currentTabRouterOrRootRouter.popAndPush<T, R>(routeInfo, result: result);
  }

  void popUntilRoot() {
    final useRootNavigator = isUseRootNavigator;
    useRootNavigator
        ? _appRouter.popUntilRoot()
        : _currentTabRouterOrRootRouter.popUntilRoot();
  }

  void popUntilRouteName(String routeName) {
    _appRouter.popUntilRouteWithName(routeName);
  }
```

> 🔎 **Quan sát**
> - **`push`** — thêm route lên stack. `name` param optional override route name.
> - **`replace`** + **`replaceAll`** — thay thế route(s) hiện tại. **Chú ý:** `_popups.clear()` trước replace → dismiss tất cả popup khi navigate away.
> - **`pop`** — dùng `maybePop` (safe pop, check guard trước). Smart router selection: root vs tab.
> - **`popAndPush`** — pop rồi push liền → transition mượt hơn pop + push riêng.
> - **`popUntilRoot`** — clear stack về root. Ví dụ: logout → `popUntilRoot()` rồi `replace(LoginRoute())`.
> - **`popUntilRouteName`** — pop đến route cụ thể. Useful cho deep navigation flows.
> - **Pattern:** Mọi method đều check `Config.enableNavigatorObserverLog` → debug logging. Consistent across codebase.

> 💡 **FE Perspective**
> **Flutter:** Stack operations qua `AppNavigator` — `push()`, `replace()`, `pop()`, `popUntilRoot()` wrap `auto_route` API với thêm logging và popup tracking.
> **React/Vue tương đương:** `navigate('/home')` / `navigate(-1)` trong React Router v6, `router.push()` / `router.replace()` / `router.go(-1)` trong Vue Router.
> **Khác biệt quan trọng:** Flutter có **nested navigators** (tab-level vs root-level), FE SPA thường chỉ có 1 router. Flutter pattern giống Next.js parallel routes hoặc React Router `<Outlet>` nesting.

### 2.5. Tab Navigation

```dart
  void navigateToBottomTab({required int index, bool notify = true}) {
    if (tabsRouter == null) throw 'Not found any TabRouter';
    tabsRouter?.setActiveIndex(index, notify: notify);
  }

  void popUntilRootOfCurrentBottomTab() {
    if (_currentTabRouter?.canPop() == true) {
      _currentTabRouter?.popUntilRoot();
    }
  }
```

> 🔎 **Quan sát**
> - `navigateToBottomTab` — switch tab bằng index. `notify: true` trigger rebuild UI (BottomNavigationBar cập nhật active tab).
> - `popUntilRootOfCurrentBottomTab` — pop hết nested routes trong tab hiện tại, về trang root. Ví dụ: user tap Home tab khi đang ở `HomeRoute → DetailRoute → CommentRoute` → pop về `HomeRoute`.
> - Xem [main_page.dart](../../base_flutter/lib/ui/page/main/main_page.dart) — `AutoTabsScaffold` bind `tabRoutes` và set `tabsRouter` trong `bottomNavigationBuilder`.

> 🏁 **Checkpoint – AppNavigator Core (§2.1–2.5)**
>
> Trước khi tiếp tục, hãy tự kiểm tra:
> - [ ] Hiểu `appNavigatorProvider` là cầu nối giữa DI (`get_it`) và Riverpod — mọi navigation đều qua `AppNavigator`, không gọi `_appRouter` trực tiếp
> - [ ] Phân biệt được dual navigator: `rootRouterContext` (full-screen, dialogs) vs `_currentTabRouterContext` (in-tab navigation)
> - [ ] Biết `push`, `replace`, `pop` chọn root hay tab navigator dựa vào `isUseRootNavigator`
> - [ ] Hiểu `navigateToBottomTab(index:)` switch tab, `popUntilRootOfCurrentBottomTab()` clear stack trong tab hiện tại
>
> 👉 Nếu chưa chắc, hãy đọc lại phần trên trước khi tiếp tục.

---

> ⏸️ **Checkpoint — Dừng nghỉ 5 phút**
> 
> Bạn vừa đi qua phần phức tạp nhất của M5. Trước khi tiếp tục:
> - [ ] Bạn hiểu `AutoTabsRouter` wrap tab pages như thế nào?
> - [ ] Bạn biết `tabsRouter.setActiveIndex()` vs `AutoTabsRouter.of(context)` khác gì?
> - [ ] Mở `main_page.dart` trong IDE và trace tab switching flow
>
> ✅ OK → tiếp tục | ❌ Chưa rõ → đọc lại section trên

<details>
<summary>📚 Nội dung bổ sung — đọc khi cần | §2.6–2.8: Dialog, SnackBar & Popup Utilities</summary>

### 2.6. Dialog & Popup System

```dart
  Future<T?> showDialog<T extends Object?>(
    BasePopup popup, {
    bool barrierDismissible = true,
    bool useSafeArea = false,
    bool useRootNavigator = true,
    bool canPop = true,
  }) async {
    if (_popups.containsKey(popup.popupId)) {
      Log.d('Dialog $popup already shown');
      return _popups[popup.popupId]!.future as Future<T?>;
    }
    _popups[popup.popupId] = Completer<T?>();

    return m.showDialog<T>(
      context: useRootNavigator ? rootRouterContext : _currentTabContextOrRootContext,
      builder: (context) => m.PopScope(
        onPopInvokedWithResult: (didPop, result) async {
          _popups.remove(popup.popupId);
        },
        canPop: canPop,
        child: popup.build(context),
      ),
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      useSafeArea: useSafeArea,
    );
  }
```

> 🔎 **Quan sát**
> - **Duplicate prevention:** Check `_popups.containsKey(popup.popupId)` trước khi show. Nếu đã show → return existing `Completer.future`. Pattern này ngăn error dialog hiện 2 lần khi 2 API fail cùng lúc.
> - `BasePopup` — abstract contract cho popup, yêu cầu `popupId` và `build(context)`.
> - `PopScope` + `onPopInvokedWithResult` — cleanup popup khỏi `_popups` map khi user dismiss.
> - `canPop: false` → user **không thể** dismiss dialog (back button bị block). Dùng cho force logout, maintenance mode.
> - `useRootNavigator: true` (default) → dialog hiện **trên toàn app** (kể cả tabs). `false` → chỉ trong tab hiện tại.
> - **Tương tự cho `showGeneralDialog` (custom animation) và `showModalBottomSheet` (bottom sheet).**

### 2.7. SnackBar Management

```dart
  void showSnackBar(BasePopup popup, {BuildContext? context}) {
    if (_popups.containsKey(popup.popupId)) return;
    _popups[popup.popupId] = Completer<void>();

    final messengerState = m.ScaffoldMessenger.maybeOf(context ?? rootRouterContext);
    if (messengerState == null) return;
    messengerState.hideCurrentSnackBar();
    messengerState.showSnackBar(popup.build(context ?? rootRouterContext) as m.SnackBar);
    Future.delayed(Constant.snackBarDuration, () {
      _popups.remove(popup.popupId);
    });
  }
```

> 🔎 **Quan sát**
> - `hideCurrentSnackBar()` trước khi show mới → chỉ 1 snackbar tại 1 thời điểm.
> - Cleanup bằng `Future.delayed(Constant.snackBarDuration)` — không dùng `onPopInvokedWithResult` vì SnackBar không phải dialog.
> - **So sánh M4:** `ExceptionHandler` gọi `appNavigatorProvider.showSnackBar(CommonSnackBar.error(...))` khi `action == showSnackBar`.

### 2.8. Extension — popUntilNamedWithResult

```dart
extension RouterUtils<T extends Object?> on StackRouter {
  Future<void> popUntilNamedWithResult({
    required String routeName,
    T? result,
    bool forced = false,
  }) async {
    final targetRouteIndex = stackData.indexWhere((e) => e.name == routeName);
    if (targetRouteIndex == -1) return;

    for (var i = stackData.lastIndex; i > targetRouteIndex; i--) {
      if (i == targetRouteIndex + 1) {
        forced ? pop(result) : await maybePop(result);
      } else {
        forced ? pop() : await maybePop();
      }
    }
  }
}
```

> 🔎 **Quan sát**
> - Extension method trên `StackRouter` — **tách logic utility** khỏi class chính.
> - Pop từng route một từ top → target. Route cuối cùng (sát target) nhận `result`.
> - `forced: true` → `pop()` (skip guards), `false` → `maybePop()` (respect guards).
> - **Hỏi:** Tại sao pop **từng cái** thay vì dùng `popUntilRouteWithName`? (hint: `popUntilRouteWithName` không pass result cho intermediate routes)

</details>

---

<details>
<summary>📚 Nội dung bổ sung — đọc khi cần | §3: Route Guard (chưa gắn vào route tree)</summary>

## 3. route_guard.dart — Auth Middleware

<!-- AI_VERIFY: base_flutter/lib/navigation/middleware/route_guard.dart -->
```dart
import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';

import '../../index.dart';

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

→ [Mở file gốc](../../base_flutter/lib/navigation/middleware/route_guard.dart)

> 🔎 **Quan sát**
> - `AutoRouteGuard` — auto_route middleware interface. `onNavigation` được gọi **trước** khi navigate đến route có guard.
> - `resolver.next(true)` — cho phép navigate. `resolver.next(false)` — block navigation.
> - `appPreferences.isLoggedIn` — check auth state từ local storage (SharedPreferences). DI inject qua `@Injectable()`.
> - Nếu chưa login → `router.push(LoginRoute())` redirect + `resolver.next(false)` cancel original navigation.
> - **Chưa gắn vào route tree** — để gắn, thêm `guards: [RouteGuard]` vào `AutoRoute` trong `app_router.dart`. Hiện tại project dùng logic redirect ở Splash level.
> - **Hỏi:** Guard chạy sync (`void onNavigation`). Nếu cần async check (API validate token) → có `AutoRouteGuard.onNavigation` support async không? (hint: yes, dùng `resolver.next()` async)

> 💡 **FE Perspective**
> **Flutter:** `AutoRouteGuard` gắn per-route — check condition trong `onNavigation()`, gọi `resolver.next(true/false)` để allow hoặc redirect. Support async check (API validate token).
> **React/Vue tương đương:** Vue Router `beforeEach()` navigation guard, Next.js `middleware.ts`, React `<ProtectedRoute>` wrapper component.
> **Khác biệt quan trọng:** auto_route guard gắn **per-route** (declarative), Vue/Next guard thường global. Flutter guard là class-based, FE thường callback-based.

</details>

> 🏁 **Checkpoint – Navigator, Popups & Route Guard (§2.6–§3)**
>
> Trước khi tiếp tục, hãy tự kiểm tra:
> - [ ] Hiểu `_popups` map ngăn duplicate dialog — `popup.popupId` là key, `Completer` là value để await kết quả
> - [ ] Biết `showDialog` dùng `PopScope` + `onPopInvokedWithResult` để cleanup `_popups` khi dismiss
> - [ ] Hiểu `RouteGuard extends AutoRouteGuard` — check `appPreferences.isLoggedIn` trước khi cho navigate, redirect về `LoginRoute` nếu chưa login
> - [ ] Biết `showSnackBar` dùng `ScaffoldMessenger` (không push route) và tự cleanup sau `Constant.snackBarDuration`
>
> 👉 Nếu chưa chắc, hãy đọc lại phần trên trước khi tiếp tục.

---

<details>
<summary>📚 Nội dung bổ sung — đọc khi cần | §4: Navigator Observer (logging/debugging)</summary>

## 4. app_navigator_observer.dart — Navigation Event Logging

<!-- AI_VERIFY: base_flutter/lib/navigation/observer/app_navigator_observer.dart -->
```dart
class AppNavigatorObserver extends NavigatorObserver {
  AppNavigatorObserver();

  static const _enableLog = Config.enableNavigatorObserverLog;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (_enableLog) {
      Log.d('didPush from ${previousRoute?.settings.name} to ${route.settings.name}');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_enableLog) {
      Log.d('didPop ${route.settings.name}, back to ${previousRoute?.settings.name}');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (_enableLog) {
      Log.d('didRemove ${route.settings.name}, back to ${previousRoute?.settings.name}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (_enableLog) {
      Log.d('didReplace ${oldRoute?.settings.name} by ${newRoute?.settings.name}');
    }
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didStartUserGesture(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    super.didStopUserGesture();
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/navigation/observer/app_navigator_observer.dart)

> 🔎 **Quan sát**
> - `NavigatorObserver` — Flutter framework class. Override 6 lifecycle methods.
> - `Config.enableNavigatorObserverLog` — **single config flag** toggle all navigation logging. Production = off, debug = on.
> - 4 events logged: `didPush`, `didPop`, `didRemove`, `didReplace` — cover hết CRUD operations trên navigation stack.
> - `didStartUserGesture` / `didStopUserGesture` — iOS swipe-back gesture detection. Override trống (placeholder cho analytics).
> - Log format: `'didPush from ${previousRoute} to ${route}'` — biết route trước và route sau → trace flow dễ.
> - **Gắn vào app:** `my_app.dart` → `appRouter.delegate(navigatorObservers: () => [AppNavigatorObserver()])`.
> - **Hỏi:** Observer chỉ thấy **root navigator** events. Nested tab navigation events có bị miss không? (hint: mỗi nested `AutoRouter` có thể có observer riêng)

> 💡 **FE Perspective**
> **Flutter:** `NavigatorObserver` subclass hook vào `didPush`, `didPop`, `didReplace` lifecycle — gắn vào `appRouter.delegate()` cho logging và analytics.
> **React/Vue tương đương:** Vue Router `afterEach()` hook, Next.js `Router.events.on('routeChangeStart')`, React Router `useLocation` + `useEffect` listen changes.
> **Khác biệt quan trọng:** Flutter observer là class-based (OOP) gắn vào navigator instance, FE thường callback-based. Mỗi nested navigator cần observer riêng.

### 4.1. Mở rộng — Analytics Tracking với NavigatorObserver

Trong production, `AppNavigatorObserver` thường được mở rộng để gửi screen view events lên analytics (Firebase, Mixpanel, v.v.). Pattern phổ biến:

```dart
class AppNavigatorObserver extends NavigatorObserver {
  AppNavigatorObserver({this.analyticsService});

  final AnalyticsService? analyticsService;
  static const _enableLog = Config.enableNavigatorObserverLog;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // Debug logging (đã có trong base_flutter)
    if (_enableLog) {
      Log.d('didPush from ${previousRoute?.settings.name} to ${route.settings.name}');
    }
    // Analytics tracking — log screen view khi user navigate tới screen mới
    _trackScreenView(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_enableLog) {
      Log.d('didPop ${route.settings.name}, back to ${previousRoute?.settings.name}');
    }
    // Re-track previous screen khi user quay lại
    if (previousRoute != null) {
      _trackScreenView(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackScreenView(newRoute);
    }
  }

  void _trackScreenView(Route<dynamic> route) {
    final screenName = route.settings.name;
    if (screenName != null && screenName.isNotEmpty) {
      analyticsService?.logScreenView(screenName: screenName);
    }
  }
}
```

> 🔎 **Quan sát**
> - `_trackScreenView()` — private helper extract screen name từ `route.settings.name` và gửi lên analytics. Centralized → không cần gọi analytics ở từng page.
> - `didPop` re-track `previousRoute` — khi user back, analytics cần biết user đang xem screen nào (previous route trở thành visible).
> - `didReplace` cũng track — `replace` thay route hiện tại, screen mới cần được log.
> - `analyticsService` nullable — production inject service thật, test/debug truyền `null`.
> - **Gắn vào app:** Trong `my_app.dart`, thay `AppNavigatorObserver()` bằng `AppNavigatorObserver(analyticsService: getIt<AnalyticsService>())`.
> - **Lưu ý:** Observer chỉ thấy **root navigator** events. Nếu cần track navigation trong nested tabs, gắn thêm observer vào mỗi `AutoRouter` (tab router). Xem thêm [auto_route docs](https://pub.dev/packages/auto_route).

</details>

---

## 5. Kết nối — Full Navigation Flow

Trace từ user tap → UI update:

```
User tap "Home" tab in BottomNavigationBar
    ↓
MainPage.onTap(index)
    ↓
ref.read(appNavigatorProvider).navigateToBottomTab(index: 0)
    ↓
AppNavigator.tabsRouter?.setActiveIndex(0)
    ↓
AutoTabsScaffold rebuilds → HomeTab visible
    ↓
AppNavigatorObserver.didPush(HomeRoute, ...)  // nếu tab chưa init
```

Trace error dialog flow (kết nối M4):

```
API call fail → DioException
    ↓
DioExceptionMapper → RemoteException(kind: noInternet)
    ↓
ExceptionHandler.handleException(remoteException)
    ↓
switch(action) → showDialogWithRetry
    ↓
_ref.read(appNavigatorProvider).showDialog(ErrorDialog.errorWithRetry(...))
    ↓
AppNavigator._popups[popup.popupId] = Completer
    ↓
Flutter showDialog() → ErrorDialog visible
    ↓
PopScope.onPopInvokedWithResult → _popups.remove(popupId)
```

---

## Summary Table

| File | Lines | Vai trò | Pattern chính |
|------|-------|---------|---------------|
| `app_router.dart` | 86 | Route tree definition | Code gen, nested routes, custom transitions |
| `app_navigator.dart` | 423 | Navigation abstraction | Wrapper pattern, dual navigator, popup tracking |
| `route_guard.dart` | 21 | Auth middleware | Guard pattern, resolver-based |
| `app_navigator_observer.dart` | 52 | Debug logging | Observer pattern, config-gated |

**Tiếp theo:** [02-concept.md](./02-concept.md) — giải thích 7 concepts rút ra từ code walk.

<!-- AI_VERIFY: generation-complete -->
