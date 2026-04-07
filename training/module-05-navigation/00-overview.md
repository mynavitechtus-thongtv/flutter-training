# Module 5: Navigation & Routing

## Tổng quan

Module này đi sâu vào **navigation layer** — hệ thống routing và navigation toàn app. Bạn sẽ đọc `AppRouter` (route tree definition), `AppNavigator` (navigation abstraction wrapper), `RouteGuard` (auth middleware), `AppNavigatorObserver` (debug logging) — hiểu cách routes được khai báo, navigate, bảo vệ, và observe.

**Cycle:** CODE (đọc navigation files) → EXPLAIN (hiểu patterns) → PRACTICE (trace + build + extend).

**Prerequisite:** Hoàn thành [Module 1 — App Entrypoint](../module-01-app-entrypoint/) (`MaterialApp.router`, `appRouter.delegate`), [Module 2 — Architecture](../module-02-architecture-barrel/) (DI `@LazySingleton`, `get_it`), [Module 3 — Common Layer](../module-03-common-layer/) (`Config` flags, `Log.d()` logging), và [Module 4 — Exception Handling](../module-04-exception-handling/) (`ExceptionHandler` dùng `AppNavigator` cho error dialogs).

---

## 🔄 Re-Anchor — Ôn lại M0-M4

Module 5 là **checkpoint** — nhiều concepts từ modules trước hội tụ ở đây. Trước khi bắt đầu, xác nhận bạn nắm vững:

| Module | Concept cần nhớ | Kết nối M5 |
|--------|-----------------|------------|
| **M0 — Dart Primer** | `async/await`, `Completer`, `extension` methods | `_popups` dùng `Completer`, `RouterUtils` extension |
| **M1 — App Entrypoint** | `MaterialApp.router`, `appRouter.delegate()`, `navigatorObservers` | M5 giải thích **chi tiết** router/delegate/observer mà M1 chỉ setup |
| **M2 — Architecture** | `@LazySingleton`, `getIt`, Riverpod Provider bridge | `AppRouter` + `AppNavigator` đều dùng DI + Provider pattern |
| **M4 — Exception Handling** | `ExceptionHandler` switch → `appNavigatorProvider.showDialog()` | M5 giải thích **popup system** mà M4 consume |

→ Nếu bất kỳ concept nào chưa rõ → quay lại module tương ứng trước khi tiếp tục.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Mô tả được auto_route code gen flow: `@RoutePage` → `.gr.dart` → `PageRouteInfo`?
2. Vẽ được route tree từ `app_router.dart` — phân biệt `AutoRoute` vs `CustomRoute`, nested tab structure?
3. Giải thích được tại sao `AppNavigator` wrap `AppRouter` thay vì dùng trực tiếp?
4. Thực hiện đúng `push`, `pop`, `replace`, `replaceAll` — biết khi nào dùng root vs tab navigator?
5. Trace được `_popups` map lifecycle: prevent duplicate dialogs, cleanup on dismiss?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 6 — Resource & Theme System](../module-06-resource-theme/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

8 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | auto_route Setup & Code Generation | 🟢 AI-GENERATE | Setup flow, build_runner, generated files — cần hiểu để thêm route mới |
| 2 | Route Configuration (AutoRoute vs CustomRoute) | 🔴 MUST-KNOW | Route tree, transitions, nested tabs |
| 3 | AppNavigator Wrapper | 🔴 MUST-KNOW | Abstraction, DI integration, testability |
| 4 | Navigation Operations (push/pop/replace) | 🔴 MUST-KNOW | Daily API, stack state management |
| 5 | Dialog & Popup Management | 🟡 SHOULD-KNOW | Duplicate prevention, popup lifecycle |
| 6 | Route Guards | 🟡 SHOULD-KNOW | Auth middleware, access control |
| 7 | Deep Link Configuration | 🟡 SHOULD-KNOW | Platform setup, URI scheme |
| 8 | Navigator Observer | 🟢 AI-GENERATE | Debug logging, analytics foundation |

**Phân bố:** 🔴 ~38% · 🟡 ~38% · 🟢 ~25%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc app_router → app_navigator → route_guard → observer | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 8 concepts từ navigation layer patterns | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 5 bài tập trace + add route + guard + popup + AI review | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + cross-check | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace Route Tree & Navigation Stack | ⭐ |
| 2 | Add a New Route | ⭐ |
| 3 | Implement Feature Flag Guard | ⭐⭐ |
| 4 | Trace Popup Lifecycle | ⭐⭐ |
| 5 | AI Prompt Dojo — Navigation Review | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [app_router.dart](../../base_flutter/lib/navigation/routes/app_router.dart) — route tree definition, AutoRoute vs CustomRoute (86 lines)
- [app_navigator.dart](../../base_flutter/lib/navigation/app_navigator.dart) — navigation wrapper, popup system, stack ops (423 lines)
- [route_guard.dart](../../base_flutter/lib/navigation/middleware/route_guard.dart) — auth guard pattern (21 lines)
- [app_navigator_observer.dart](../../base_flutter/lib/navigation/observer/app_navigator_observer.dart) — navigation event logging (52 lines)
- [my_app.dart](../../base_flutter/lib/ui/my_app.dart) — `MaterialApp.router` setup (M1)
- [main_page.dart](../../base_flutter/lib/ui/page/main/main_page.dart) — `AutoTabsScaffold` + tab binding
- [exception_handler.dart](../../base_flutter/lib/exception/exception_handler/exception_handler.dart) — dùng `appNavigatorProvider` cho error UI (M4)

---

## Unlocks (Module 7+)

Sau khi hoàn thành Module 5, bạn sẽ:

- **Module 7 — Base UI Framework:** ViewModel gọi `ref.read(appNavigatorProvider).push()`, `pop()`. `BasePage` lifecycle integration.
- **Module 9 — Page Structure:** Page structure dùng navigation patterns. `ErrorDialog`, `ConfirmDialog` — popup UI mà `AppNavigator` quản lý.
- **Module 14 — Deep Linking:** `deepLinkBuilder` trong `appRouter.delegate()` → map URL → route. Mở rộng route tree cho external navigation.

<!-- AI_VERIFY: generation-complete -->
