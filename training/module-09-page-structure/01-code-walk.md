# Code Walk — Page Structure & Widgets

> 📌 **Recap:** M5 (AppRouter, AppNavigator, @RoutePage) · M6 (AppColors, style(), l10n) · M7 (BasePage, buildPage, loading/exception) · M8 (ref.watch/read, StateNotifierProvider)
>
> Nếu chưa nắm vững → quay lại module tương ứng trước.

---

## Walk Order

```
splash_page.dart (simplest — lifecycle init pattern)
    ↓
login_page.dart (form inputs, analytics, Consumer selective rebuild)
    ↓
main_page.dart (tab navigation, AutoTabsScaffold)
    ↓
Component overview (CommonScaffold, CommonText, CommonImage, PrimaryTextField, ...)
```

---

## 1. splash_page.dart — Minimal Page Skeleton

<!-- AI_VERIFY: base_flutter/lib/ui/page/splash/splash_page.dart -->
```dart
@RoutePage()
class SplashPage extends BasePage<SplashState,
    AutoDisposeStateNotifierProvider<SplashViewModel, CommonState<SplashState>>> {
  const SplashPage({super.key});

  @override
  ScreenViewEvent get screenViewEvent => ScreenViewEvent(screenName: ScreenName.splashPage);

  @override
  AutoDisposeStateNotifierProvider<SplashViewModel, CommonState<SplashState>> get provider =>
      splashViewModelProvider;

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    useEffect(
      () {
        Future.microtask(() {
          ref.read(provider.notifier).init();
        });
        return null;
      },
      [],
    );

    return const CommonScaffold(
      body: SizedBox(),
    );
  }
}
```
<!-- END_VERIFY -->
→ Source: [splash_page.dart](../../base_flutter/lib/ui/page/splash/splash_page.dart) (37 lines)

> ⏩ **Forward Reference:** `flutter_hooks` giải thích chi tiết ở [Module 10](../module-10-hooks/). Ở đây: hooks = lifecycle utilities tự động, tương đương React Hooks.

### Breakdown — 4 Required Pieces per Page

| # | Piece | Purpose |
|---|-------|---------|
| 1 | `@RoutePage()` | auto_route code gen → tạo `SplashRoute` (M5) |
| 2 | `extends BasePage<S, P>` | Kế thừa loading overlay, exception handling, analytics (M7) |
| 3 | `screenViewEvent` getter | Analytics tracking — `FocusDetector.onVisibilityGained` (M7) |
| 4 | `provider` getter | Kết nối page → ViewModel via Riverpod (M8) |

**`useEffect` + `Future.microtask` init pattern:**

```dart
useEffect(() {
  Future.microtask(() { ref.read(provider.notifier).init(); });
  return null;  // ← no cleanup
}, []);         // ← empty deps = run once
```

`Future.microtask` defer execution ra khỏi synchronous build phase — gọi `init()` trực tiếp có thể trigger state change **trong build** → assertion error. Tương đương `WidgetsBinding.instance.addPostFrameCallback` nhưng ngắn gọn hơn.

---

## 2. login_page.dart — Form Inputs, Analytics & Consumer

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/login_page.dart -->

### 2a. Analytics Extension

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

Analytics methods định nghĩa **trong extension trên `AnalyticsHelper`** ngay file page — thuộc UI concerns. `_` prefix → private trong file.

### 2b. Page Declaration + buildPage Layout

Cùng pattern 4 pieces như Splash. Generic types: `LoginState` + `AutoDisposeStateNotifierProvider<LoginViewModel, CommonState<LoginState>>`.

```dart
@override
Widget buildPage(BuildContext context, WidgetRef ref) {
  final scrollController = useScrollController();  // ← auto-dispose hook (M10)

  return CommonScaffold(
    body: Stack(
      children: [
        CommonImage.asset(path: image.imageBackground, width: double.infinity,
            height: double.infinity, fit: BoxFit.cover),
        CommonScrollbarWithIosStatusBarTapDetector(
          routeName: LoginRoute.name,
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(l10n.login, style: style(fontSize: 30, fontWeight: FontWeight.w700)),
                const SizedBox(height: 50),
                PrimaryTextField(
                  title: l10n.email,
                  hintText: l10n.email,
                  onChanged: (email) => ref.read(provider.notifier).setEmail(email),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 24),
                PrimaryTextField(
                  title: l10n.password,
                  hintText: l10n.password,
                  onChanged: (password) => ref.read(provider.notifier).setPassword(password),
                  keyboardType: TextInputType.visiblePassword,
                  onEyeIconPressed: (obscureText) {
                    ref.read(analyticsHelperProvider)._logEyeIconClickEvent(obscureText: obscureText);
                  },
                ),
                // ... Consumer widgets below
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
```

**Key:** `ref.read(provider.notifier).setEmail(email)` — **read** (not watch) vì `onChanged` là event handler. `keyboardType: TextInputType.visiblePassword` → auto eye icon toggle.

### 2c. Consumer — Selective Rebuilds

**Tại sao `Consumer`?** Wrap phần UI cần reactive → chỉ Consumer.builder rebuild, không phải toàn page.

**Error display:**

```dart
Consumer(
  builder: (context, ref, child) {
    final onPageError = ref.watch(
      provider.select((value) => value.data.onPageError),
    );
    return Visibility(
      visible: onPageError.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: CommonText(onPageError, style: style(fontSize: 14, color: color.red1)),
      ),
    );
  },
),
```

- `ref.watch(provider.select(...))` — subscribe chỉ field cụ thể → rebuild khi **field đó** thay đổi
- `Visibility` giữ widget trong tree, toggle visibility — layout không shift
- Login page dùng **2 Consumer widgets**: error message + login button — mỗi cái watch field khác nhau

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
          : null,  // ← null → disabled (Material built-in)
      // ... styling
    );
  },
),
```

---

## 3. main_page.dart — Tab Navigation Host

<!-- AI_VERIFY: base_flutter/lib/ui/page/main/main_page.dart -->
```dart
@RoutePage()
class MainPage extends BasePage<MainState,
    AutoDisposeStateNotifierProvider<MainViewModel, CommonState<MainState>>> {
  MainPage({super.key});

  @override
  ScreenViewEvent get screenViewEvent => ScreenViewEvent(screenName: ScreenName.mainPage);

  @override
  AutoDisposeStateNotifierProvider<MainViewModel, CommonState<MainState>> get provider =>
      mainViewModelProvider;

  final _bottomBarKey = GlobalKey();

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() { ref.read(provider.notifier).init(); });
      return () {};
    }, []);

    return AutoTabsScaffold(
      routes: ref.read(appNavigatorProvider).tabRoutes,
      bottomNavigationBuilder: (_, tabsRouter) {
        ref.read(appNavigatorProvider).tabsRouter = tabsRouter;

        return BottomNavigationBar(
          key: _bottomBarKey,
          currentIndex: tabsRouter.activeIndex,
          onTap: (index) {
            if (index == tabsRouter.activeIndex) {
              ref.read(appNavigatorProvider).popUntilRootOfCurrentBottomTab();
            }
            tabsRouter.setActiveIndex(index);
          },
          items: BottomTab.values
              .map((tab) => BottomNavigationBarItem(
                    label: tab.title, icon: tab.icon, activeIcon: tab.activeIcon,
                  ))
              .toList(),
        );
      },
    );
  }
}
```
<!-- END_VERIFY -->
→ Source: [main_page.dart](../../base_flutter/lib/ui/page/main/main_page.dart) (94 lines)

**`BottomTab`** — enhanced enum (Dart 3), mỗi value chứa icon + localized title. Thêm/xóa tab = thêm enum value + update route tree (M5).

**`AutoTabsScaffold`** — auto_route quản lý tab content tự động. `tabsRouter` expose cho `AppNavigator` → global tab control. `popUntilRootOfCurrentBottomTab()` = tap active tab → pop to root (iOS convention).

---

## 4. Component Overview — Shared UI Building Blocks

<!-- AI_VERIFY: base_flutter/lib/ui/component/ directory listing -->

| Component | Type | Key Props |
|-----------|------|-----------|
| **CommonScaffold** | `StatelessWidget` | `body`, `appBar`, `shimmerEnabled`, `hideKeyboardWhenTouchOutside` |
| **CommonText** | Widget | String + `style()` from M6 |
| **CommonImage** | Widget | `.asset()`, `.network()` named constructors |
| **CommonAppBar** | `PreferredSizeWidget` | `text`, `leadingIcon` |
| **PrimaryTextField** | `StatefulWidget` | `title`, `hintText`, `onChanged`, `keyboardType`, `onEyeIconPressed` |
| **CommonProgressIndicator** | Widget | Loading state |
| **Shimmer** | Widget | Skeleton loading animation |
| **AvatarView** | Widget | `text` → generates initials |
| **PagedView** / `InfiniteList` | Widget | `itemCount`, `hasReachedMax`, `onFetchData` |
| **CommonScrollbarWithIosStatusBarTapDetector** | Widget | Tap status bar → scroll to top |

### CommonScaffold Deep Dive

<!-- AI_VERIFY: base_flutter/lib/ui/component/common_scaffold/common_scaffold.dart -->
```dart
class CommonScaffold extends StatelessWidget {
  const CommonScaffold({
    required this.body,
    this.appBar,
    this.hideKeyboardWhenTouchOutside = true,     // ← tap outside → dismiss keyboard
    this.shimmerEnabled = false,                   // ← wrap body in Shimmer
    this.showBanner = true,                        // ← flavor banner (dev/qa/staging)
    this.useSafeArea = true,                       // ← notch handling
    this.preventActionWhenLoading = true,           // ← IgnorePointer khi loading
    // ...
  });
```
<!-- END_VERIFY -->

Wraps `Scaffold` + SafeArea + IgnorePointer (when loading) + optional Shimmer. `preventActionWhenLoading: true` → user không tap được button trong khi API call.

### PrimaryTextField Deep Dive

<!-- AI_VERIFY: base_flutter/lib/ui/component/primary_text_field/primary_text_field.dart -->

`StatefulWidget` vì quản lý `FocusNode` + `_obscureText` toggle **nội bộ** — không expose ra ViewModel. `keyboardType: TextInputType.visiblePassword` → auto eye icon mode. Component quản lý **UI state** (focus, obscure), parent quản lý **business state** (field values).

<!-- END_VERIFY -->

---

## 5. Supplementary Pages

### home_page.dart — Pagination Pattern

<!-- AI_VERIFY: base_flutter/lib/ui/page/home/home_page.dart -->
```dart
@override
Widget buildPage(BuildContext context, WidgetRef ref) {
  final notifications = ref.watch(provider.select((value) => value.data.notifications));

  return CommonScaffold(
    shimmerEnabled: true,
    appBar: CommonAppBar(text: l10n.home, leadingIcon: LeadingIcon.none),
    body: RefreshIndicator(
      onRefresh: () => ref.read(provider.notifier).refresh(),
      child: InfiniteList(
        itemCount: notifications.data.length,
        hasReachedMax: notifications.isLastPage,
        onFetchData: () { ref.read(provider.notifier).fetchNotifications(...); },
        itemBuilder: (context, index) { /* notification card */ },
      ),
    ),
  );
}
```
<!-- END_VERIFY -->

**Key patterns:**
- `shimmerEnabled: true` → skeleton loading while data fetches (M4 component)
- `ref.watch` trực tiếp trong `buildPage` (không qua `Consumer`) — OK vì toàn page phụ thuộc notifications list
- `InfiniteList` component — `onFetchData` trigger khi scroll gần bottom, `hasReachedMax` stop pagination
- `RefreshIndicator` — pull-to-refresh gọi `notifier.refresh()` (reset page → re-fetch từ page 1)
- Pagination state (`notifications.data`, `notifications.isLastPage`) quản lý bởi `PagingExecutor` pattern (xem [M13 § PagingExecutor](../module-13-middleware-interceptor-chain/02-concept.md))
  (Đừng lo về PagingExecutor internals bây giờ — Module 13 sẽ cover chi tiết. Hiện tại chỉ cần biết nó quản lý việc load more data.)

> 💡 **FE Perspective**: `InfiniteList` / `LoadMore` pattern trong Flutter ≈ React `useInfiniteQuery` + `IntersectionObserver`. Flutter dùng `ScrollController` + `NotificationListener<ScrollNotification>` (wrapped bởi `InfiniteList`) thay vì DOM observer. `RefreshIndicator` ≈ native pull-to-refresh — không cần third-party library.

### my_profile_page.dart — Dialog Actions

<!-- AI_VERIFY: base_flutter/lib/ui/page/my_profile/my_profile_page.dart -->

**Key patterns:**
- `useEffect` + `Future.microtask` init → fetch user profile data on mount
- `ref.watch` user data → rebuild `AvatarView` (initials từ user name) + profile info display
- Logout flow: `ListTile` onTap → `appNavigator.showDialog(ConfirmDialog.logOut(doOnConfirm: logout))` — dialog qua `AppNavigator` (M5)
- `AvatarView(text: user.name)` → component tự generate initials từ name string
- Page đơn giản (no pagination, no form) — good ví dụ về minimal page chỉ hiển thị data + single action

<!-- END_VERIFY -->

---

## Summary — Page Structure Pattern

```
┌──────────────────────────────────────────────┐
│  @RoutePage()                                │ ← M5: auto_route
│  class XxxPage extends BasePage<State, P>    │ ← M7: base lifecycle
│                                              │
│  provider → xxxViewModelProvider             │ ← M8: Riverpod
│  screenViewEvent → ScreenViewEvent(...)      │ ← M7: analytics
│                                              │
│  buildPage(context, ref) {                   │
│    useEffect(() {                            │
│      Future.microtask(() { init(); });       │ ← Init pattern
│    }, []);                                   │
│                                              │
│    return CommonScaffold(                    │ ← Shared wrapper
│      body: ...(                              │
│        Consumer(builder: (_, ref, _) {       │ ← Selective rebuild
│          ref.watch(provider.select(...))     │ ← Granular watch
│        }),                                   │
│      ),                                      │
│    );                                        │
│  }                                           │
└──────────────────────────────────────────────┘
```

→ **Next:** [02-concept.md](./02-concept.md) — 7 concepts rút ra từ code walk.

<!-- AI_VERIFY: generation-complete -->
