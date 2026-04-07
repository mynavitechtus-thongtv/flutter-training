# Module 8: Riverpod & State Management

## Tổng quan

Module này deep-dive vào **Riverpod** — hệ thống state management trong base_flutter. Bạn sẽ đọc `ProviderScope` root setup, DI bridge pattern (getIt → Provider), provider types taxonomy (Provider / StateProvider / StateNotifierProvider), ref API rules (read vs watch vs listen), autoDispose lifecycle cho page-scoped VMs, selector pattern cho granular rebuilds, và shared state vs page state separation — hiểu cách mọi provider kết nối tạo thành reactive data flow.

**Cycle:** CODE (đọc ProviderScope + providers + consumption patterns) → EXPLAIN (hiểu taxonomy + rules) → PRACTICE (trace + classify + build + optimize).

**Prerequisite:** Hoàn thành [Module 1 — App Entrypoint](../module-01-app-entrypoint/) (ProviderScope root), [Module 7 — Base ViewModel](../module-07-base-viewmodel/) (BaseViewModel + StateNotifier + runCatching), và [Module 3 — Common Layer](../module-03-common-layer/) (Config flags for observer).

> ⚠️ **Riverpod Version Note:** Nếu bạn Google 'Riverpod StateNotifier' và thấy articles nói 'deprecated' — đừng panic. Codebase dùng Riverpod **v1 API** (`StateNotifier` + `StateNotifierProvider`). Đây là quyết định có chủ đích — v1 pattern mature và production-proven. v2 (`Notifier` + `NotifierProvider`) là alternative mới hơn nhưng chưa migrate.

---

## 🔄 Re-Anchor — Ôn lại M1, M7, M3

| Module | Concept cần nhớ | Kết nối M8 |
|--------|-----------------|------------|
| **M1 — Entrypoint** | `ProviderScope` wrap root, `AppProviderObserver` attached | M8 deep-dive container, overrides, lifecycle |
| **M7 — ViewModel** | `BaseViewModel extends StateNotifier`, `CommonState` envelope, `runCatching` | M8 phân tích **tại sao** `StateNotifierProvider.autoDispose` |
| **M3 — Common** | `Config` flags gating observer logs | M8 dùng observer để trace provider lifecycle |

→ Nếu bất kỳ concept nào chưa rõ → quay lại module tương ứng trước khi tiếp tục.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Giải thích được `ProviderScope` tạo `ProviderContainer` ẩn, vai trò `overrides` cho testing?
2. Chọn đúng provider type (Provider / StateProvider / StateNotifierProvider / FutureProvider) trong 10 giây cho bất kỳ use case?
3. Phân biệt `ref.read` (one-shot) / `ref.watch` (rebuild) / `ref.listen` (side-effect) — rules nghiêm ngặt?
4. Giải thích `autoDispose` lifecycle: create → alive → no listeners → dispose?
5. Dùng `.select()` để tối ưu rebuild — biết khi nào cần, performance impact?
6. Phân biệt shared state (app-wide, `currentUserProvider`) vs page state (scoped, `loginViewModelProvider`)?

→ Nếu **6/6 Yes** — chuyển thẳng [Module 9 — Page Structure](../module-09-page-structure/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

7 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | ProviderScope & Container | 🔴 MUST-KNOW | Root setup, overrides for testing |
| 2 | Provider Types Taxonomy | 🔴 MUST-KNOW | Chọn đúng type — decision tree |
| 3 | DI Bridge Pattern | 🟡 SHOULD-KNOW | getIt → Provider wrapper, testability |
| 4 | ref API (read/watch/listen) | 🔴 MUST-KNOW | Rules nghiêm ngặt, dùng sai = bug |
| 5 | autoDispose & family | 🟡 SHOULD-KNOW | Page-scoped lifecycle, parameterized providers |
| 6 | Selector Pattern | 🔴 MUST-KNOW | Granular rebuilds, performance |
| 7 | Shared vs Page State | 🟡 SHOULD-KNOW | Separation, lifecycle, communication |

**Phân bố:** 🔴 ~57% · 🟡 ~43% · 🟢 0%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | ProviderScope → DI bridge → SharedViewModel → LoginVM provider → BasePage ref patterns → Observer | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 7 concepts: container, types, DI bridge, ref API, autoDispose, selectors, shared vs page | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 5 bài tập: trace lifecycle, classify types, build VM, selector optimization, AI dojo | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + exercise answers + cross-check | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace Provider Lifecycle | ⭐ |
| 2 | Identify Provider Types | ⭐ |
| 3 | Create SettingsViewModel | ⭐⭐ |
| 4 | Selector Optimization | ⭐⭐ |
| 5 | AI Prompt Dojo — Riverpod Deep Dive | ⭐⭐⭐ |

---

## 🔓 Unlocks

Hoàn thành Module 8 mở khóa:

| Module | Sử dụng gì từ M8 |
|--------|-------------------|
| **M9 — Page Structure** | Consume providers trong concrete pages, widget-level ref patterns |
| **M18 — Testing** | Override providers trong `ProviderScope`, mock DI services |
| **M15 — Capstone** | Advanced state patterns, multi-provider coordination |

---

## 🔗 Liên kết

- [main.dart](../../base_flutter/lib/main.dart) — ProviderScope root setup
- [app_navigator.dart](../../base_flutter/lib/navigation/app_navigator.dart) — DI bridge pattern (`Provider + getIt`)
- [shared_view_model.dart](../../base_flutter/lib/ui/shared/shared_view_model.dart) — Global utility ViewModel
- [shared_providers.dart](../../base_flutter/lib/ui/shared/shared_providers.dart) — `currentUserProvider` (StateProvider)
- [login_view_model.dart](../../base_flutter/lib/ui/page/login/view_model/login_view_model.dart) — `StateNotifierProvider.autoDispose` pattern
- [base_page.dart](../../base_flutter/lib/ui/base/base_page.dart) — ref.listen + ref.watch consumption
- [app_provider_observer.dart](../../base_flutter/lib/ui/base/app_provider_observer.dart) — Config-gated lifecycle logging

<!-- AI_VERIFY: generation-complete -->
