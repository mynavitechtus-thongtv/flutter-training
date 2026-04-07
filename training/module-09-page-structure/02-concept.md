# Concepts — Page Structure & Widgets

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

---

## 1. Page Anatomy — @RoutePage + BasePage Integration 🔴 MUST-KNOW

**WHY:** Mọi page trong app đều tuân theo cùng 1 skeleton. Hiểu sai → page không nhận exception handling, không track analytics, không connect đúng ViewModel.

<!-- AI_VERIFY: base_flutter/lib/ui/page/splash/splash_page.dart -->
```dart
@RoutePage()
class SplashPage extends BasePage<SplashState,
    AutoDisposeStateNotifierProvider<SplashViewModel, CommonState<SplashState>>> {

  @override ScreenViewEvent get screenViewEvent => ...;
  @override AutoDisposeStateNotifierProvider<...> get provider => splashViewModelProvider;
  @override Widget buildPage(BuildContext context, WidgetRef ref) { ... }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § splash_page.dart](./01-code-walk.md#1-splash_pagedart--minimal-page-skeleton)

**EXPLAIN:**

**4 required pieces cho mỗi page:**

```
@RoutePage()                  ← [1] auto_route annotation
class XxxPage extends BasePage<
  XxxState,                   ← [2a] State type
  AutoDisposeStateNotifierProvider<
    XxxViewModel,             ← [2b] ViewModel type
    CommonState<XxxState>     ← [2c] Wrapped state
  >
> {
  provider → xxxViewModelProvider   ← [3] Riverpod provider
  screenViewEvent → ...              ← [4] Analytics screen name
  buildPage(context, ref) → Widget   ← Override: actual UI
}
```

**Inheritance chain:**

```
BasePage<ST, P> extends HookConsumerWidget
  ├── build(context, ref)          ← BasePage.build (DON'T override)
  │   ├── AppColors.of(context)    ← init theme (M6)
  │   ├── ref.listen → appException → handleException  ← auto error handling (M4/M7)
  │   ├── ref.listen → isLoading → overlay  ← auto loading overlay (M7)
  │   └── FocusDetector → onVisibilityGained → logScreenView  ← auto analytics
  └── buildPage(context, ref)      ← YOUR code goes here
```

→ Bạn **chỉ cần override `buildPage`** — tất cả cross-cutting concerns (exception, loading, analytics) đã được `BasePage.build` xử lý.

**`HookConsumerWidget`** = Flutter Hooks (`useEffect`, `useState`, `useScrollController`) + Riverpod Consumer (`ref`). Cả hai available trong `buildPage`.

| BasePage provides | You provide |
|-------------------|-------------|
| Exception handling | `provider` getter → kết nối state |
| Loading overlay | `screenViewEvent` → analytics name |
| Analytics auto-log | `buildPage()` → UI code |
| Theme init | — |

> 💡 **FE Perspective**
> **Flutter:** `BasePage` cung cấp error boundary + loading overlay + analytics tracker qua class inheritance — mọi page chỉ cần override `buildPage()`.
> **React/Vue tương đương:** React: HOC wrappers (`withErrorBoundary`, `withLoading`). Vue: composables (`useAuth`, `useAnalytics`) trong `<script setup>`.
> **Khác biệt quan trọng:** Flutter dùng **class inheritance** thay vì **composition** (HOC/composables) — tất cả cross-cutting concerns gói trong 1 base class.

> 💡 **Composition vs Inheritance**: Trong Flutter community, nhiều người ưu tiên composition (mixins, wrapper widgets) hơn class inheritance. `BasePage` dùng inheritance ở đây vì: (1) đảm bảo MỌI page tuân thủ cùng lifecycle/error handling, (2) giảm boilerplate khi cross-cutting concerns (loading, error, dispose) áp dụng cho TẤT CẢ pages. Composition là valid alternative nhưng cần nhiều boilerplate hơn cho cross-cutting concerns.

**PRACTICE:** Mở bất kỳ page nào (`home_page.dart`, `my_profile_page.dart`) → xác nhận đủ 4 pieces. Đọc `BasePage.build()` → trace exception listener path.

---

## 2. useEffect + Future.microtask Init Pattern 🔴 MUST-KNOW

**WHY:** Pattern init dùng ở **mọi page** có data cần fetch lúc mount. Sai cách → state change trong build phase → crash.

<!-- AI_VERIFY: base_flutter/lib/ui/page/splash/splash_page.dart -->
```dart
useEffect(
  () {
    Future.microtask(() {
      ref.read(provider.notifier).init();
    });
    return null;
  },
  [],
);
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § splash_page.dart](./01-code-walk.md#1-splash_pagedart--minimal-page-skeleton)

**EXPLAIN:**

**Execution timeline:**

```
Frame N:
  1. build() called           ← synchronous
  2. buildPage() called       ← synchronous
  3. useEffect scheduled      ← registered, NOT executed yet
  4. Widget tree committed    ← frame complete

Post-frame:
  5. useEffect callback runs  ← after build
  6. Future.microtask queued  ← pushed to microtask queue
  7. init() executes          ← safe to modify state
  8. State change → schedule next frame
```

**Tại sao cần `Future.microtask`?**

| Approach | Kết quả |
|----------|---------|
| `ref.read(notifier).init()` trực tiếp trong `useEffect` | ⚠️ Có thể trigger `setState` / `notifyListeners` **trong build phase** → assertion error |
| `Future.microtask(() => init())` | ✅ Defer sang microtask → after frame build → safe |
| `WidgetsBinding.addPostFrameCallback` | ✅ Cũng safe nhưng verbose hơn |
| `Future.delayed(Duration.zero)` | ⚠️ Chạy **sau** microtask queue → chậm hơn cần thiết |

**Cleanup function:**

```dart
return null;     // ← Splash: no cleanup needed
return () {};    // ← Main: empty cleanup (equivalent to null)
```

- Return function → được gọi khi widget **unmount** hoặc dependency thay đổi.
- Dùng cho: cancel subscriptions, dispose controllers, stop timers.
- `null` vs `() {}` → same behavior cho "no cleanup". Codebase dùng cả hai.

**Dependency array `[]`:**
- `[]` = run once on mount (giống React `useEffect(fn, [])`).
- `[someValue]` = re-run khi `someValue` thay đổi.
- **Không có** dependency array (omit) → run **every build** → hầu như không bao giờ dùng.

> 💡 **FE Perspective**
> **Flutter:** `useEffect(fn, [])` chạy 1 lần on mount, return function là cleanup khi unmount — API gần identical React hooks.
> **React/Vue tương đương:** React `useEffect(fn, [])` — identical. Vue: `onMounted()` + `onUnmounted()`.
> **Khác biệt quan trọng:** Flutter cần `Future.microtask` wrapping để tránh state change trong build phase; React `useEffect` tự chạy sau commit nên không cần.

**PRACTICE:** Tìm tất cả `useEffect` trong codebase (`grep -rn "useEffect" lib/ui/page/`). Kiểm tra mỗi cái: dependency array là gì? Có cleanup không? Có dùng `Future.microtask` không?

---

## 3. Consumer Widget — Selective Rebuild Boundaries 🔴 MUST-KNOW

**WHY:** Rebuild toàn bộ page khi chỉ 1 field thay đổi → janky UI, wasted renders. `Consumer` + `select` → **surgical rebuilds** — critical cho performance.

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/login_page.dart -->
```dart
Consumer(
  builder: (context, ref, child) {
    final isLoginButtonEnabled = ref.watch(
      provider.select((value) => value.data.isLoginButtonEnabled),
    );
    return ElevatedButton(
      onPressed: isLoginButtonEnabled ? () { ... } : null,
      // ...
    );
  },
),
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § login_page.dart](./01-code-walk.md#2e-consumer--selective-rebuilds-lines-101-155)

**EXPLAIN:**

**Khi nào dùng `Consumer` vs `ref.watch` trực tiếp?**

| Scenario | Approach | Lý do |
|----------|----------|-------|
| Page phụ thuộc **toàn bộ** data (home_page) | `ref.watch` trực tiếp trong `buildPage` | Rebuild toàn trang cũng cần vì tất cả data thay đổi |
| Chỉ **1 phần** page reactive (login button) | `Consumer` + `ref.watch(select(...))` | Giới hạn rebuild scope |
| Multiple **independent** reactive sections | Nhiều `Consumer` widgets | Mỗi cái watch field riêng |
| Static UI (labels, titles) | Không dùng `ref.watch` | Không cần reactive |

**Rebuild flow comparison:**

```
WITHOUT Consumer (ref.watch in buildPage):
  email changes → LoginState updates → buildPage rebuilds
    → CommonScaffold rebuilds
      → Stack rebuilds
        → Background image rebuilds (WASTED)
        → ScrollView rebuilds (WASTED)
          → Login text rebuilds (WASTED)
          → Email field rebuilds (WASTED)
          → Password field rebuilds (WASTED)
          → Error text rebuilds (WASTED)
          → Login button rebuilds (NEEDED)

WITH Consumer (ref.watch inside Consumer):
  isLoginButtonEnabled changes → Consumer.builder rebuilds
    → ElevatedButton rebuilds (NEEDED, nothing else)
```

**`provider.select((value) => value.data.isLoginButtonEnabled)`:**
- `select` extract **derived value** từ state.
- Riverpod só sánh old vs new **derived value** (not full state).
- Chỉ rebuild khi derived value **actually changed** → tránh false positives.

**Login page dùng 2 Consumers:**

| Consumer | Watches | Rebuilds when |
|----------|---------|---------------|
| Error text | `value.data.onPageError` | Error message thay đổi |
| Login button | `value.data.isLoginButtonEnabled` | Button state thay đổi |

→ User type email → `setEmail()` → state update → nhưng nếu `isLoginButtonEnabled` **không đổi** (vd: password vẫn trống) → login button Consumer **KHÔNG rebuild**.

> 💡 **FE Perspective**
> **Flutter:** `Consumer` widget tạo manual render boundary, `select` extract derived value để chỉ rebuild khi field cụ thể thay đổi.
> **React/Vue tương đương:** Redux `useSelector` / Reselect `createSelector`. Vue: `computed` property.
> **Khác biệt quan trọng:** Flutter cần manual `Consumer` wrapping; Vue `computed` tự động track — không cần explicit boundary.

**PRACTICE:** Mở `login_page.dart` → thêm `print('LOGIN BUTTON REBUILDS')` trong login button Consumer → type chỉ email field → check console: login button có rebuild không? (Expected: rebuild chỉ khi `isLoginButtonEnabled` thay đổi).

---

## 4. CommonScaffold & Shared Layout Components 🟡 SHOULD-KNOW

**WHY:** Mọi page dùng `CommonScaffold` — hiểu props → control SafeArea, shimmer, keyboard behavior, loading block. Dùng sai → UI bugs khó debug.

<!-- AI_VERIFY: base_flutter/lib/ui/component/common_scaffold/common_scaffold.dart -->
```dart
class CommonScaffold extends StatelessWidget {
  const CommonScaffold({
    required this.body,
    this.hideKeyboardWhenTouchOutside = true,
    this.shimmerEnabled = false,
    this.useSafeArea = true,
    this.preventActionWhenLoading = true,
    // ...
  });
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § Component Overview](./01-code-walk.md#4-component-overview--shared-ui-building-blocks)

**EXPLAIN:**

**CommonScaffold widget tree:**

```
CommonScaffold
  └── Scaffold (Material)
      └── IgnorePointer (preventActionWhenLoading)
          └── SafeArea (useSafeArea)
              └── Shimmer? (shimmerEnabled)
                  └── body (your content)
      └── AppBar? (appBar)
      └── FloatingActionButton? (fab)
      └── Drawer? (drawer)
  └── Banner? (showBanner — non-production)
  └── GestureDetector? (hideKeyboardWhenTouchOutside)
```

**Common props sử dụng thường xuyên:**

| Prop | Default | Usage |
|------|---------|-------|
| `body` | required | Page content |
| `appBar` | null | `CommonAppBar` hoặc custom `PreferredSizeWidget` |
| `shimmerEnabled` | `false` | `true` → body wrapped in shimmer (skeleton loading) |
| `hideKeyboardWhenTouchOutside` | `true` | Touch ngoài TextField → dismiss keyboard |
| `useSafeArea` | `true` | Respect notch/rounded corners |
| `preventActionWhenLoading` | `true` | Block user touch khi loading overlay visible |
| `isLoading` | null | Override loading state (null → from `LoadingStateProvider`) |

**Khi nào tắt defaults:**
- `useSafeArea: false` → khi page cần edge-to-edge content (full-screen image, video).
- `hideKeyboardWhenTouchOutside: false` → khi có multi-field form cần giữ keyboard visible.
- `preventActionWhenLoading: false` → khi user vẫn cần interact (e.g., cancel button during loading).

**PRACTICE:** So sánh `splash_page.dart` (bare minimum) vs `home_page.dart` (`shimmerEnabled: true`, `appBar`, `SafeArea`) → liệt kê props khác nhau và lý do.

---

## 5. Form Input Pattern — PrimaryTextField + ViewModel Binding 🟡 SHOULD-KNOW

**WHY:** Form inputs là interaction core của mobile app. Hiểu data flow `TextField → ViewModel → State → UI` → build bất kỳ form nào.

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/login_page.dart -->
```dart
PrimaryTextField(
  title: l10n.email,
  hintText: l10n.email,
  onChanged: (email) => ref.read(provider.notifier).setEmail(email),
  keyboardType: TextInputType.text,
  suffixIcon: const Icon(Icons.email),
),
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § Form Inputs](./01-code-walk.md#2d-form-inputs--primarytextfield-lines-75-100)

**EXPLAIN:**

**One-way data flow:**

```
User types → onChanged(text) → ref.read(notifier).setField(text) → State updates
                                                                         ↓
UI ← Consumer.ref.watch(state.select(derivedValue)) ← State changed notification
```

- `onChanged` → `ref.read` (not `ref.watch`) — event handler, one-shot read.
- `setEmail(email)` → ViewModel method → update `LoginState.email`.
- `LoginState` recalculates derived fields: `isLoginButtonEnabled = email.isNotEmpty && password.isNotEmpty`.
- `Consumer` watching `isLoginButtonEnabled` → rebuild button.

**PrimaryTextField encapsulation:**

| Responsibility | Owner | Ví dụ |
|---------------|-------|-------|
| Focus management | PrimaryTextField (internal `FocusNode`) | Auto-focus, refocus on resume |
| Obscure text toggle | PrimaryTextField (internal `_obscureText`) | Eye icon tap |
| Text value | ViewModel (via `onChanged` callback) | `setEmail(email)` |
| Validation result | ViewModel → State → Consumer | `isLoginButtonEnabled` |
| Analytics | Page (via `onEyeIconPressed` callback) | `_logEyeIconClickEvent` |

→ **PrimaryTextField không biết gì về ViewModel** — pure UI component, communicate qua callbacks.

**Password field — `keyboardType: TextInputType.visiblePassword`:**
- Triggers `PrimaryTextField` internal logic: show eye icon, default `_obscureText = true`.
- `onEyeIconPressed: (obscureText) { ... }` — callback khi user tap eye icon → page log analytics.

> 💡 **FE Perspective**
> **Flutter:** `PrimaryTextField` + `onChanged` callback tạo one-way data flow: user input → ViewModel → State → UI rebuild.
> **React/Vue tương đương:** React controlled component `<input value={state} onChange={handler} />`. Vue: `v-model` two-way binding.
> **Khác biệt quan trọng:** Flutter **không có two-way binding** — luôn one-way qua callbacks, giống React controlled pattern.

**PRACTICE:** Trong `login_page.dart`, thêm 1 field mới (e.g., `PrimaryTextField` cho "Username") → wire `onChanged` → `ref.read(provider.notifier).setUsername(...)`. Check build thành công (không cần ViewModel method thực tế — chỉ validate wiring).

---

## 6. Tab Navigation Page — AutoTabsScaffold + BottomNavigationBar 🟡 SHOULD-KNOW

**WHY:** Tab navigation là **core UX pattern** của hầu hết mobile apps. Hiểu `AutoTabsScaffold` integration → thêm/sửa tabs cho features mới.

<!-- AI_VERIFY: base_flutter/lib/ui/page/main/main_page.dart -->
```dart
return AutoTabsScaffold(
  routes: ref.read(appNavigatorProvider).tabRoutes,
  bottomNavigationBuilder: (_, tabsRouter) {
    ref.read(appNavigatorProvider).tabsRouter = tabsRouter;
    return BottomNavigationBar(
      currentIndex: tabsRouter.activeIndex,
      onTap: (index) { ... },
      items: BottomTab.values.map((tab) => BottomNavigationBarItem(...)).toList(),
    );
  },
);
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § main_page.dart](./01-code-walk.md#3-main_pagedart--tab-navigation-host)

**EXPLAIN:**

**Architecture layers:**

```
auto_route Config (M5)           MainPage UI (M9)
┌──────────────────┐         ┌────────────────────┐
│ MainRoute         │         │ AutoTabsScaffold   │
│   ├── HomeTab     │────────→│   routes: tabRoutes │
│   └── MyProfileTab│         │   bottomNavBuilder  │
└──────────────────┘         └────────────────────┘
                                     ↕
                              AppNavigator (M5)
                              ┌────────────────┐
                              │ tabRoutes       │
                              │ tabsRouter      │
                              │ popUntilRoot()  │
                              └────────────────┘
```

**3-way integration:**
1. **Route config** (M5): `MainRoute` children define tab routes.
2. **AppNavigator** (M5): exposes `tabRoutes` list + stores `tabsRouter` reference.
3. **MainPage** (M9): renders `AutoTabsScaffold` + `BottomNavigationBar`.

**`onTap` logic:**

```dart
onTap: (index) {
  if (index == tabsRouter.activeIndex) {
    // Tap current tab → pop to root (iOS convention)
    ref.read(appNavigatorProvider).popUntilRootOfCurrentBottomTab();
  }
  tabsRouter.setActiveIndex(index);
},
```

- Tap **khác tab** → switch tab.
- Tap **cùng tab** → pop toàn bộ stack, quay lại root page của tab. Ví dụ: Home → Detail → Detail → tap Home tab → quay lại Home.
- `maintainState: true` (M5) → switch tab rồi quay lại → stack preserved.

**BottomTab enum — single source of truth:**

```dart
enum BottomTab {
  home(icon: Icon(Icons.home), activeIcon: Icon(Icons.home)),
  myProfile(icon: Icon(Icons.people), activeIcon: Icon(Icons.people));
  // ...
  String get title {
    switch (this) {
      case BottomTab.home:
        return l10n.home;
      case BottomTab.myProfile:
        return l10n.myPage;
    }
  }
}
```

Thêm tab = thêm enum value + route config + tab page. **3 chỗ cần sửa**, enum-driven → ít miss.

> 💡 **FE Perspective**
> **Flutter:** `AutoTabsScaffold` quản lý tab routes + `BottomNavigationBar` UI, mỗi tab giữ separate navigation stack.
> **React/Vue tương đương:** React Router `<Outlet>` + Material UI `<BottomNavigation>`. Vue Router: nested `<router-view>` + tab component.
> **Khác biệt quan trọng:** Flutter tabs giữ **separate navigation stacks per tab** — web routing thường dùng single stack, switch tab = replace route.

**PRACTICE:** Thêm tab thứ 3 (`BottomTab.settings`) vào enum → xem compile error chỉ bạn cần sửa ở đâu (route config, tab page).

---

## 7. Analytics Integration — Extension Pattern 🟢 AI-GENERATE

**WHY:** Analytics tracking trong mọi page nhưng **không pollute** ViewModel/BasePage. Extension pattern → clean separation, page-scoped.

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/login_page.dart -->
```dart
extension AnalyticsHelperOnLoginPage on AnalyticsHelper {
  void _logLoginButtonClickEvent() {
    logEvent(NormalEvent(
      screenName: ScreenName.loginPage,
      eventName: EventConstants.loginButtonClick,
    ));
  }
}

// Usage trong page:
ref.read(analyticsHelperProvider)._logLoginButtonClickEvent();
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § Analytics Extension](./01-code-walk.md#2a-analytics-extension-lines-1-32)

**EXPLAIN:**

**Tại sao extension thay vì method trong ViewModel?**

| Approach | Pros | Cons |
|----------|------|------|
| Method trong ViewModel | Testable, centralized | Bloat ViewModel, mix analytics + business logic |
| Extension trên AnalyticsHelper | Page-scoped, separated concerns | Private methods cannot be tested individually |
| Standalone analytics service | Fully decoupled | Over-engineering cho simple events |

Codebase chọn **extension** — analytics methods khai báo **per-page**, gần nơi chúng được gọi. `_` prefix → private → chỉ dùng trong file page.

**Pattern:**

```
1. Định nghĩa extension trên AnalyticsHelper ở đầu page file
2. Methods dùng private _ prefix → scope hẹp
3. Gọi qua ref.read(analyticsHelperProvider)._methodName()
4. screenViewEvent (BasePage) logs screen view tự động
5. Custom events log thủ công qua extension methods
```

**Auto screen tracking (M7) vs manual event tracking (M9):**

| Tracking | Mechanism | Code |
|----------|-----------|------|
| Screen view | `BasePage.onVisibilityChanged` → auto | `screenViewEvent` getter |
| Button click | Manual trong `onPressed` handler | `ref.read(analyticsHelperProvider)._log...()` |
| Toggle action | Manual trong callback | `onEyeIconPressed` → analytics extension |

> 💡 **FE Perspective**
> **Flutter:** Dart extension trên `AnalyticsHelper` khai báo analytics methods per-page — `_` prefix giữ scope hẹp, gần nơi sử dụng.
> **React/Vue tương đương:** React: custom hook `useLoginAnalytics()`. Vue: composable `useLoginTracking()`. JS/TS: module-scoped functions.
> **Khác biệt quan trọng:** Dart extension **extends class API** mà không subclass — cleaner than utility functions, nhưng private methods không test riêng được.

**PRACTICE:** Mở `login_page.dart` → trace analytics flow: `_logLoginButtonClickEvent()` được gọi ở đâu? Event name là gì? Screen name inject thế nào?

---

> 📋 Badge summary → xem [00-overview.md](./00-overview.md)

---

**Next:** [03-exercise.md](./03-exercise.md) — 5 bài tập thực hành.

---

## ℹ️ Appendix: Accessibility — Semantics Widget

> Scope: INFO — nằm ngoài core training, nhưng quan trọng cho production apps.

**Mọi custom widget cần thông tin cho screen reader (TalkBack / VoiceOver) phải wrap trong `Semantics`:**

```dart
Semantics(
  label: 'Close dialog',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.close),
    onPressed: () => Navigator.pop(context),
  ),
)
```

> 💡 **FE Perspective — Accessibility**
>
> | Flutter | Web (React / Vue) |
> |---------|-------------------|
> | `Semantics(label: '...')` | `aria-label="..."` |
> | `Semantics(button: true)` | `role="button"` |
> | `ExcludeSemantics(child: ...)` | `aria-hidden="true"` |
> | `MergeSemantics(child: ...)` | Grouping elements for screen reader |
> | Built-in widgets (`ElevatedButton`, `TextField`) | Native HTML elements (`<button>`, `<input>`) |
>
> **Rule of thumb:** Flutter built-in widgets (`ElevatedButton`, `Text`, `TextField`) đã có semantics tự động — chỉ cần add `Semantics` cho **custom widgets** (icon buttons không có label, decorative images, complex gestures).

**Checklist nhanh cho production:**
- [ ] Mọi `IconButton` có `tooltip` hoặc `Semantics(label:)`
- [ ] Images decorative → `excludeFromSemantics: true`
- [ ] Touch targets ≥ 48x48 dp (Material guideline)
- [ ] Color contrast ratio ≥ 4.5:1 (WCAG AA)

> 📚 **Tham khảo:** [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
