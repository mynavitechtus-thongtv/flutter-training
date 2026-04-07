# Exercises — Thực hành Navigation & Routing

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 4](../module-04-exception-handling/) (ExceptionHandler dùng AppNavigator) và đọc xong [01-code-walk.md](./01-code-walk.md).

---

## ⭐ Exercise 1: Trace Route Tree & Navigation Stack

**Mục tiêu:** Vẽ route tree từ code, trace navigation stack khi user thao tác.

### Hướng dẫn

1. Mở [app_router.dart](../../base_flutter/lib/navigation/routes/app_router.dart).
2. Vẽ route tree diagram từ `routes` getter. Ghi chú route type (AutoRoute / CustomRoute) và transition cho mỗi node.
3. Trace navigation stack cho scenario sau:

**Scenario:** App launch → Splash → Login → Main(HomeTab) → push DetailRoute trong HomeTab → switch sang MyProfileTab → switch lại HomeTab.

### Template

Điền bảng trace:

| Step | Action | Root Stack | HomeTab Stack | MyProfileTab Stack | Active Tab |
|------|--------|-----------|---------------|-------------------|------------|
| 1 | App launch | `[SplashRoute]` | — | — | — |
| 2 | Splash → Login | `[?]` | — | — | — |
| 3 | Login → Main | `[?]` | `[?]` | `[?]` | ? |
| 4 | Push DetailRoute | `[?]` | `[?]` | `[?]` | ? |
| 5 | Switch MyProfileTab | `[?]` | `[?]` | `[?]` | ? |
| 6 | Switch HomeTab | `[?]` | `[?]` | `[?]` | ? |

**Câu hỏi:**
- Step 2: `replace` hay `push`? Tại sao không muốn user nhấn back quay lại Splash?
- Step 5: HomeTab stack có thay đổi khi switch tab không? (`maintainState: true` ảnh hưởng gì?)
- Step 6: DetailRoute còn ở HomeTab stack không?

### ✅ Checklist hoàn thành
- [ ] Vẽ route tree 3 levels (root → tab → page)
- [ ] Điền bảng 6 steps
- [ ] Trả lời 3 câu hỏi
- [ ] Hiểu `replaceAll` vs `push` trong auth flow

---

## ⭐ Exercise 2: Add a New Route

**Mục tiêu:** Thêm `SettingsRoute` dưới `MyProfileTab` — trải nghiệm full flow: page → router config → navigation call.

### Hướng dẫn

**Step 1:** Tạo page file `lib/ui/page/settings/settings_page.dart`:

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Page')),
    );
  }
}
```

**Step 2:** Chạy code generation:

```bash
cd base_flutter
dart run build_runner build --delete-conflicting-outputs
```

**Step 3:** Thêm route vào `app_router.dart`:

```dart
AutoRoute(
  page: MyProfileTab.page,
  maintainState: true,
  children: [
    AutoRoute(page: MyProfileRoute.page, initial: true),
    AutoRoute(page: SettingsRoute.page),  // ← THÊM
  ],
),
```

**Step 4:** Navigate từ MyProfilePage:

```dart
// Trong my_profile_page.dart
ref.read(appNavigatorProvider).push(const SettingsRoute());
```

**Step 5:** Verify — chạy app, navigate đến Settings từ Profile. Back button quay lại Profile.

### Câu hỏi suy nghĩ
- `SettingsRoute` nằm trong `MyProfileTab` children → navigate dùng root hay tab navigator? Tại sao?
- Nếu muốn `SettingsRoute` hiện **fullscreen** (cover cả bottom tab bar) → cần thay đổi gì?
- `initial: true` trên `SettingsRoute` có hợp lý không? Tại sao?

### ✅ Checklist hoàn thành
- [ ] File tạo đúng location + `@RoutePage()` annotation
- [ ] `build_runner` generate thành công (không error)
- [ ] Route thêm vào `app_router.dart` đúng vị trí (children of MyProfileTab)
- [ ] Navigate bằng `appNavigatorProvider.push()`
- [ ] Back button hoạt động đúng
- [ ] Trả lời 3 câu hỏi
- [ ] **Revert changes** nếu không merge

---

## ⭐⭐ Exercise 3: Implement a Feature-Flag Route Guard

**Mục tiêu:** Tạo `FeatureFlagGuard` — guard cho phép/chặn route dựa vào feature flag. Áp dụng pattern từ `RouteGuard`.

### Hướng dẫn

1. Tạo file `lib/navigation/middleware/feature_flag_guard.dart`.
2. Implement theo pattern từ [route_guard.dart](../../base_flutter/lib/navigation/middleware/route_guard.dart):

### Template

```dart
import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';

import '../../index.dart';

@Injectable()
class FeatureFlagGuard extends AutoRouteGuard {
  FeatureFlagGuard(this.appPreferences);

  final AppPreferences appPreferences;

  // TODO: override onNavigation
  // Logic:
  // 1. Check if feature flag is enabled (e.g., appPreferences.isFeatureXEnabled)
  // 2. If enabled → resolver.next(true)
  // 3. If disabled → show dialog "Feature coming soon" via router context
  //    then resolver.next(false)
}
```

3. Implement `onNavigation`:
   - Check feature flag enabled
   - If disabled → show notification (không redirect, chỉ block + thông báo)
   - `resolver.next(false)` để cancel navigation

4. Gắn guard vào route (test):

```dart
// Trong app_router.dart
AutoRoute(
  page: SettingsRoute.page,
  guards: [FeatureFlagGuard],  // ← gắn guard
),
```

5. Verify: navigate đến route khi flag disabled → bị block.

### Concrete Scenario: AuthGuard

Trước khi làm `FeatureFlagGuard`, hình dung concrete scenario cho auth guard:

> **Tạo AuthGuard:** nếu user chưa login → redirect `LoginRoute`, nếu đã login → cho qua.

```dart
@override
void onNavigation(NavigationResolver resolver, StackRouter router) {
  if (appPreferences.isLoggedIn) {
    resolver.next(true);   // ✅ đã login → cho qua
  } else {
    router.push(const LoginRoute());  // ❌ chưa login → redirect
    resolver.next(false);              // cancel navigation gốc
  }
}
```

Áp dụng tương tự cho `FeatureFlagGuard` — thay điều kiện `isLoggedIn` bằng `isFeatureEnabled`.

### Câu hỏi suy nghĩ
- `RouteGuard` redirect sang LoginRoute khi block. `FeatureFlagGuard` chỉ show thông báo. Tại sao behavior khác?
- Guard nhận `StackRouter router` → có thể access context qua `router.navigatorKey.currentContext`. An toàn dùng context này không?
- Nếu cần **async** check (fetch feature flags from API) → pattern thay đổi thế nào?
- Multiple guards: `[RouteGuard, FeatureFlagGuard]` — thứ tự quan trọng không? Nếu user chưa login, `FeatureFlagGuard` có chạy không?

### ✅ Checklist hoàn thành
- [ ] File tạo đúng location (`lib/navigation/middleware/`)
- [ ] `extends AutoRouteGuard` — đúng base class
- [ ] `@Injectable()` — DI inject `AppPreferences`
- [ ] `onNavigation` logic: check flag → allow/block
- [ ] `resolver.next(false)` khi block — cancel navigation
- [ ] Gắn guard vào route và test
- [ ] Trả lời 4 câu hỏi
- [ ] **Revert changes**

---

## ⭐⭐ Exercise 4: Trace Popup Lifecycle & Duplicate Prevention

**Mục tiêu:** Trace `_popups` map state qua sequence of dialog operations. Hiểu duplicate prevention và cleanup.

### Hướng dẫn

**Scenario:** 2 API calls fail cùng lúc, cả 2 trigger `ExceptionHandler.handleException()`.

Trace `_popups` map state:

| Step | Action | `_popups` state | UI |
|------|--------|----------------|-----|
| 1 | API 1 fail → `handleException(RemoteException(kind: timeout))` | `{}` | — |
| 2 | → `ExceptionHandler` switch → `showDialogWithRetry` | `{}` | — |
| 3 | → `appNavigator.showDialog(ErrorDialog(...), popupId: "error_dialog")` | `{"error_dialog": Completer}` | Dialog shown |
| 4 | API 2 fail → `handleException(RemoteException(kind: noInternet))` | ? | ? |
| 5 | → `appNavigator.showDialog(ErrorDialog(...), popupId: "error_dialog")` | ? | ? |
| 6 | User tap dismiss dialog | ? | ? |
| 7 | `PopScope.onPopInvokedWithResult` fires | ? | ? |

**Câu hỏi:**
- Step 4-5: API 2 cũng show dialog hay bị block? `_popups` state thay đổi gì?
- Step 6-7: Cleanup xảy ra ở đâu? `Completer` resolve với value gì?
- Nếu 2 errors có **khác `popupId`** → behavior thay đổi thế nào? 2 dialogs cùng lúc có issue gì?
- `replace()` và `replaceAll()` gọi `_popups.clear()`. Tại sao?

**Bonus:** Trace `showSnackBar` lifecycle — cleanup bằng `Future.delayed` khác gì `PopScope`?

### ✅ Checklist hoàn thành
- [ ] Điền bảng 7 steps
- [ ] Giải thích duplicate prevention mechanism
- [ ] Hiểu `Completer` pattern cho dialog result
- [ ] Trả lời 4 câu hỏi
- [ ] Bonus: SnackBar cleanup comparison

---

## ⭐⭐⭐ Exercise 5: AI Dojo — 🔄 Code Review

### 🤖 AI Dojo — Code Review cho Navigation

**Mục tiêu**: Dùng AI như code reviewer — phát hiện potential issues trong navigation code mà manual review dễ bỏ sót.

**Bước thực hiện**:

1. Copy nội dung [app_navigator.dart](../../base_flutter/lib/navigation/app_navigator.dart) và [route_guard.dart](../../base_flutter/lib/navigation/middleware/route_guard.dart) vào clipboard.

2. Gửi prompt sau cho AI:

```
Bạn là code reviewer senior Flutter. Review navigation code sau và tìm potential issues:
- Memory leaks: có Completer/Stream nào không được cleanup không?
- Deep link edge cases: nếu user tap deep link khi dialog đang hiển thị thì sao?
- Race condition: 2 navigation calls đồng thời có conflict không?
- Back button handling: system back pressed khi guard đang check → flow ra sao?

Chỉ báo issues CÓ THẬT, không suggest rewrite pattern hiện tại.

Code:
[PASTE app_navigator.dart + route_guard.dart]
```

3. Với mỗi issue AI tìm được, verify bằng cách đọc code thực tế:
   - Issue có thật không? Hay AI hallucinate dựa trên assumption sai?
   - Nếu issue thật → severity level (critical/medium/low)?

4. Hỏi follow-up: "Với issue nghiêm trọng nhất bạn tìm được, hãy viết fix code cụ thể."

**✅ Tiêu chí đánh giá**:
- [ ] AI tìm được ≥ 2 issues có giá trị (không phải nitpick style)
- [ ] Bạn verify mỗi issue AI nêu — phân biệt issue thật vs hallucination
- [ ] AI **KHÔNG** suggest bỏ wrapper pattern (AppNavigator) — đó là design decision, không phải bug
- [ ] Bạn viết 2-3 câu đánh giá: "AI review tốt ở..., miss ở..., sai ở..."

---

## Exercise Summary

| # | Bài tập | Độ khó | Concept chính | Output |
|---|---------|--------|--------------|--------|
| 1 | Trace Route Tree & Stack | ⭐ | Route configuration, stack ops | Diagram + bảng trace |
| 2 | Add a New Route | ⭐ | Code gen, route config, push | Working new route |
| 3 | Implement Feature Flag Guard | ⭐⭐ | Route guards, DI | Working guard |
| 4 | Trace Popup Lifecycle | ⭐⭐ | Popup management, Completer | Bảng trace + analysis |
| 5 | AI Dojo — Code Review | ⭐⭐⭐ | Navigation code review | AI evaluation |

**Tiếp theo:** [04-verify.md](./04-verify.md) — checklist tự đánh giá.

<!-- AI_VERIFY: generation-complete -->
