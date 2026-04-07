# Verification — Kiểm tra kết quả Module 5

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi mô tả được auto_route code gen flow: `@RoutePage` → `build_runner` → `.gr.dart` → `PageRouteInfo`? | auto_route Setup | 🟢 |
| 2 | Tôi phân biệt `AutoRoute` vs `CustomRoute` — khi nào dùng cái nào, transition behavior? | Route Configuration | 🔴 |
| 3 | Tôi giải thích được tại sao `AppNavigator` wrap `AppRouter` thay vì dùng trực tiếp? (testing, DI, popup tracking) | AppNavigator Wrapper | 🔴 |
| 4 | Tôi thực hiện đúng `push`, `pop`, `replace`, `replaceAll`, `popAndPush` — biết stack state trước/sau mỗi operation? | Navigation Operations | 🔴 |
| 5 | Tôi trace được `_popups` map lifecycle: add → check duplicate → cleanup on dismiss? | Dialog & Popup Mgmt | 🟡 |
| 6 | Tôi implement được route guard: `extends AutoRouteGuard`, `resolver.next(true/false)`, gắn vào route config? | Route Guards | 🟡 |
| 7 | Tôi hiểu `NavigatorObserver` lifecycle events (`didPush/didPop/didRemove/didReplace`) và config-gated logging? | Navigator Observer | 🟢 |

> 📝 **Note:** Deep Link concepts đã được chuyển sang [Module Optional B — Push & Deep Link](../module-optional-B-push-deeplink/). Self-assessment này cover 7 core navigation concepts của M05.

**Target:** 3/3 Yes cho 🔴 MUST-KNOW, tối thiểu 6/7 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace Route Tree ⭐

Đáp án tham khảo:

| Step | Action | Root Stack | HomeTab Stack | MyProfileTab Stack | Active Tab |
|------|--------|-----------|---------------|-------------------|------------|
| 1 | App launch | `[SplashRoute]` | — | — | — |
| 2 | Splash → Login | `[LoginRoute]` | — | — | — |
| 3 | Login → Main | `[MainRoute]` | `[HomeRoute]` | `[MyProfileRoute]` | Home (0) |
| 4 | Push DetailRoute | `[MainRoute]` | `[HomeRoute, DetailRoute]` | `[MyProfileRoute]` | Home (0) |
| 5 | Switch MyProfileTab | `[MainRoute]` | `[HomeRoute, DetailRoute]` | `[MyProfileRoute]` | MyProfile (1) |
| 6 | Switch HomeTab | `[MainRoute]` | `[HomeRoute, DetailRoute]` | `[MyProfileRoute]` | Home (0) |

**Verification points:**
- [ ] Step 2: `replaceAll([LoginRoute()])` — Splash → Login dùng **replace** không push. Lý do: user không nên back về Splash.
- [ ] Step 3: `replaceAll([MainRoute()])` — Login → Main cũng replace. Lý do: user không nên back về Login sau khi authenticated.
- [ ] Step 5: HomeTab stack **KHÔNG thay đổi** (`maintainState: true`). DetailRoute vẫn ở top.
- [ ] Step 6: Quay lại HomeTab → DetailRoute vẫn visible. `maintainState: true` giữ toàn bộ nested stack.

### Exercise 2 — Add New Route ⭐

- [ ] File location: `lib/ui/page/settings/settings_page.dart`
- [ ] `@RoutePage()` annotation present
- [ ] `build_runner` chạy thành công → `SettingsRoute` xuất hiện trong `app_router.gr.dart`
- [ ] Route thêm đúng vị trí: children of `MyProfileTab`, **sau** `MyProfileRoute`
- [ ] Navigate bằng `ref.read(appNavigatorProvider).push(const SettingsRoute())`
- [ ] Back button hoạt động → pop về MyProfileRoute

**Cross-check:**
- [ ] `SettingsRoute` nằm trong tab → push dùng tab navigator (within bottom tab)
- [ ] Muốn fullscreen (cover tabs) → move `SettingsRoute` ra khỏi `MainRoute.children`, đặt ở root level
- [ ] `initial: true` trên SettingsRoute → **KHÔNG** hợp lý (MyProfileRoute nên là initial, SettingsRoute là secondary page)

### Exercise 3 — Feature Flag Guard ⭐⭐

- [ ] File location: `lib/navigation/middleware/feature_flag_guard.dart`
- [ ] `extends AutoRouteGuard` — đúng base class
- [ ] `@Injectable()` — DI inject `AppPreferences`
- [ ] `onNavigation` kiểm tra feature flag → `resolver.next(true)` hoặc `resolver.next(false)`
- [ ] Khi block: show thông báo (SnackBar hoặc dialog qua router context) → `resolver.next(false)`

**Câu hỏi answers:**
- [ ] `RouteGuard` redirect (push LoginRoute) vs `FeatureFlagGuard` chỉ block — khác behavior vì auth cần fallback destination, feature flag chỉ cần thông báo.
- [ ] `router.navigatorKey.currentContext` — có thể `null` nếu navigator chưa mounted. Check `null` before use.
- [ ] Async check: `onNavigation` body dùng `async`, `await` API call, rồi `resolver.next()`. auto_route support async guards.
- [ ] Multiple guards chạy tuần tự: `RouteGuard` chạy trước, nếu `resolver.next(false)` → `FeatureFlagGuard` **KHÔNG** chạy.

### Exercise 4 — Popup Lifecycle ⭐⭐

Đáp án:

| Step | Action | `_popups` state | UI |
|------|--------|----------------|-----|
| 1 | API 1 fail → handleException | `{}` | — |
| 2 | → showDialogWithRetry | `{}` | — |
| 3 | → showDialog(popupId: "error_dialog") | `{"error_dialog": Completer<T?>}` | Error dialog visible |
| 4 | API 2 fail → handleException | `{"error_dialog": Completer<T?>}` | Error dialog visible |
| 5 | → showDialog(popupId: "error_dialog") | `{"error_dialog": Completer<T?>}` (unchanged) | **NO duplicate** — return existing future |
| 6 | User tap dismiss | `{"error_dialog": Completer<T?>}` | Dialog dismissing |
| 7 | PopScope.onPopInvokedWithResult | `{}` (removed) | Dialog gone |

**Verification:**
- [ ] Step 4-5: API 2 bị **block** — `_popups.containsKey` returns `true` → return existing `Completer.future`, **KHÔNG** show dialog mới.
- [ ] Step 7: `_popups.remove(popup.popupId)` trong `onPopInvokedWithResult` callback.
- [ ] Khác `popupId` → 2 dialogs show cùng lúc → **có thể overlap**. Design decision: `popupId` quyết định grouping.
- [ ] `replace/replaceAll` clear `_popups` → navigate away = dismiss tất cả popups. Avoid orphaned dialogs.
- [ ] SnackBar cleanup: `Future.delayed(Constant.snackBarDuration)` — time-based, không event-based. Vì SnackBar auto-dismiss sau duration, không có `PopScope`.

### Exercise 5 — AI Prompt Dojo ⭐⭐⭐

- [ ] AI output ≥ 4/6 tiêu chí pass
- [ ] AI hiểu wrapper pattern justified (testing, DI, popup tracking)
- [ ] AI nhận diện popup edge case (ví dụ: `Completer` never resolves nếu dialog route bị pop bất thường)
- [ ] AI nhận xét `isUseRootNavigator` complex/fragile
- [ ] AI **KHÔNG** suggest rewrite toàn bộ bằng Navigator 2.0 raw API
- [ ] Bạn identify được ≥ 1 điểm AI output sai hoặc thiếu context

---

## 3. Concept Cross-Check

| # | Scenario | Đáp án đúng | Concept |
|---|----------|-------------|---------|
| 1 | `push(DetailRoute())` → stack `[Home, Detail]`. Back button → ? | `pop()` → stack `[Home]` via `maybePop` | Navigation Ops |
| 2 | `replaceAll([LoginRoute()])` từ Main → `_popups` state? | `_popups.clear()` → empty map | Popup Mgmt |
| 3 | `RouteGuard.onNavigation` — user chưa login → ? | `router.push(LoginRoute())` + `resolver.next(false)` | Route Guards |
| 4 | `maintainState: true` → switch tab rồi quay lại → state? | State preserved (widget tree giữ nguyên) | Route Config |
| 5 | Observer `didReplace` trigger khi nào? | `AppNavigator.replace(newRoute)` → old route bị thay | Observer |
| 6 | `showDialog(popup)` khi `_popups` đã chứa `popup.popupId`? | Return existing `Completer.future` → no duplicate | Popup Mgmt |

---

## 4. Architecture Cross-Check

| Component | File | DI | Riverpod Provider | Used by |
|-----------|------|----|-------------------|---------|
| `AppRouter` | `app_router.dart` | `@LazySingleton` | `appRouterProvider` | `MyApp`, `AppNavigator` |
| `AppNavigator` | `app_navigator.dart` | `@LazySingleton` | `appNavigatorProvider` | ViewModels, `ExceptionHandler`, UI |
| `RouteGuard` | `route_guard.dart` | `@Injectable` | — (auto_route creates) | Route config `guards:` |
| `AppNavigatorObserver` | `app_navigator_observer.dart` | — (manual) | — | `appRouter.delegate(navigatorObservers:)` |

**Kiểm tra:**
- [ ] `AppRouter` → `AppNavigator` → UI/ViewModels: dependency flow một chiều
- [ ] `ExceptionHandler` (M4) → `appNavigatorProvider` → dialog/snackbar: error system dùng cùng navigation layer
- [ ] `MyApp` (M1) → `appRouterProvider` → `MaterialApp.router`: app entrypoint setup routing

---

## 5. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Dùng `Navigator.of(context).push()` thay vì `appNavigatorProvider` | Bypass popup tracking, miss logging, inconsistent | Luôn dùng `AppNavigator` methods |
| 2 | Push route dùng root navigator khi nên dùng tab navigator | Route hiện fullscreen thay vì trong tab | Kiểm route nằm trong tab children hay root |
| 3 | Quên `@RoutePage()` annotation trên page class | `build_runner` không generate route → compile error | Luôn thêm annotation trước run build_runner |
| 4 | Guard gọi `resolver.next()` nhiều lần | Undefined behavior — navigation state corrupt | Đảm bảo `resolver.next()` gọi **đúng 1 lần** per guard call |
| 5 | Show dialog không qua `AppNavigator` | Không có duplicate prevention, không cleanup | Dùng `appNavigatorProvider.showDialog()` |
| 6 | Dùng `pop()` thay `maybePop()` trên stack chỉ có 1 route | Empty navigator → black screen / crash | `AppNavigator.pop()` đã dùng `maybePop` — safe |

---

## ✅ Module Complete

Hoàn thành khi:
- Self-assessment: ≥ 6/7 Yes (bắt buộc 3/3 🔴 MUST-KNOW)
- Exercises: ≥ 4/5 hoàn thành (bắt buộc Ex1 + Ex2)
- Cross-check: ≥ 5/6 đúng

**Next:** [Module 6 — Resource & Theme System](../module-06-resource-theme/) — Colors, themes, typography, fonts và assets management.

<!-- AI_VERIFY: generation-complete -->
