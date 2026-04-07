# Module 7: Base Page, State & ViewModel

## Tổng quan

Module này đi sâu vào **base UI framework** — hệ thống `BaseState`, `CommonState`, `BaseViewModel`, và `BasePage` tạo nên foundation cho mọi page trong app. Bạn sẽ đọc abstract state contract, generic state envelope (data + loading + exception + action tracking), ViewModel lifecycle (mounted guard, loading count, `runCatching` centralized error handling), Page reactive binding (`ref.listen` cho exception/loading overlay), và concrete Login example end-to-end — hiểu cách mọi thành phần kết nối tạo thành full reactive pipeline.

**Cycle:** CODE (đọc base files + login example) → EXPLAIN (hiểu patterns) → PRACTICE (trace + build + analyze).

**Prerequisite:** Hoàn thành [Module 2 — Architecture](../module-02-architecture-barrel/) (DI + getIt), [Module 3 — Common Layer](../module-03-common-layer/) (Result type, Log), [Module 4 — Exception Handling](../module-04-exception-handling/) (AppException hierarchy), [Module 5 — Navigation](../module-05-navigation/) (AppNavigator), và [Module 6 — Resource & Theme](../module-06-resource-theme/) (AppColors.of(context)).

> ⚠️ Xem bảng thuật ngữ Riverpod tại [01-code-walk.md § Thuật ngữ](./01-code-walk.md#thuật-ngữ-riverpod) trước khi đọc module này.

---

## 🔄 Re-Anchor — Ôn lại M2-M6

| Module | Concept cần nhớ | Kết nối M7 |
|--------|-----------------|------------|
| **M2 — Architecture** | DI với `get_it`, Riverpod Provider expose DI | M7 ViewModel dùng `Ref` để read providers (DI access) |
| **M3 — Common Layer** | `Log` utility, `Config` flags | M7 `mounted` guard dùng `Log.e()`, `AppProviderObserver` gated by `Config` |
| **M4 — Exception** | `AppException` hierarchy, `isForcedErrorToHandle`, `onRetry` | M7 `runCatching` wrap exceptions, build retry chain |
| **M5 — Navigation** | `AppNavigator`, `replaceAll`, `pop` | M7 LoginViewModel navigate sau login success |
| **M6 — Resource** | `AppColors.of(context)` init trong `build()` | M7 `BasePage.build()` gọi `AppColors.of(context)` đầu tiên |

→ Nếu bất kỳ concept nào chưa rõ → quay lại module tương ứng trước khi tiếp tục.

---

## ⏭️ Skip Path

> 🎯 **Trust Checkpoint:** Module này dùng `ref.watch` (reactive subscription), `ref.listen` (callback), `select()` (filter). M08 sẽ giải thích chi tiết. Nếu chưa hiểu — **đó là bình thường** — quay lại đây sau khi học M08.

> 🚨 **Checkpoint bắt buộc:** Học viên phải giải thích được **loading counter pattern** (`_loadingCount`, `showLoading`/`hideLoading`, tại sao counter chứ không phải bool) **TRƯỚC KHI sang M08**. Nếu chưa giải thích được → quay lại [01-code-walk § 3a](./01-code-walk.md#3a-_loadingcount-deep-dive--tại-sao-counter-không-phải-bool).

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Giải thích được `CommonState<T>` envelope pattern — tại sao wrap `data + isLoading + appException` thay vì extend?
2. Trace được `mounted` guard trong BaseViewModel — setter/getter check, `Log.e()` fallback?
3. Giải thích được `runCatching` flow: action → catch → `handleErrorWhen` → retry chain → `exception` setter?
4. Hiểu `handleErrorWhen: (_) => false` suppress global error + `doOnError` handle local?
5. Trace được `BasePage.ref.listen` cho `appException` → `ExceptionHandler` và `isLoading` → Overlay?
6. Viết được `StateNotifierProvider.autoDispose` declaration cho ViewModel mới?

→ Nếu **6/6 Yes** — chuyển thẳng [Module 8 — State Management](../module-08-riverpod-state/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

7 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | BaseState Contract | 🟢 AI-GENERATE | Abstract marker, generic constraint |
| 2 | CommonState Envelope | 🔴 MUST-KNOW | Generic wrapper: data + infra fields |
| 3 | BaseViewModel Lifecycle | 🔴 MUST-KNOW | Mounted guard, loading count, state accessors |
| 4 | runCatching Pattern | 🔴 MUST-KNOW | Centralized error handling, retry chain |
| 5 | BasePage Reactive Binding | 🔴 MUST-KNOW | ref.listen, loading overlay, exception dispatch |
| 6 | Provider Wiring | 🟡 SHOULD-KNOW | StateNotifierProvider.autoDispose pattern |
| 7 | AppProviderObserver | 🟢 AI-GENERATE | Config-gated lifecycle logging |

**Phân bố:** 🔴 ~57% · 🟡 ~14% · 🟢 ~29%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc base_state → common_state → base_view_model (runCatching) → base_page → login example → observer | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 7 concepts: state contract, envelope, lifecycle, runCatching, page binding, provider, observer | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 5 bài tập trace + action tracking + build ViewModel + multi-action + AI dojo | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + exercise answers + cross-check | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace Login Flow End-to-End | ⭐ |
| 2 | Add Action Tracking to Login | ⭐ |
| 3 | Create a ProfileViewModel | ⭐⭐ |
| 4 | Multiple Actions Tracking | ⭐⭐ |
| 5 | AI Prompt Dojo — runCatching Deep Dive | ⭐⭐⭐ |

---

## 🔓 Unlocks

Hoàn thành Module 7 mở khóa:

| Module | Sử dụng gì từ M7 |
|--------|-------------------|
| **M8 — State Management** | Deep-dive Riverpod providers, `ProviderScope`, `autoDispose` lifecycle |
| **M9 — Page Structure** | Concrete pages extend `BasePage`, ViewModel patterns trong practice |
| **M18 — Testing** | Unit test ViewModel methods, mock `runCatching` behavior |

---

## 🔗 Liên kết

- [base_state.dart](../../base_flutter/lib/ui/base/base_state.dart) — abstract marker class (3 lines)
- [common_state.dart](../../base_flutter/lib/ui/base/common_state.dart) — generic state envelope (20 lines)
- [base_view_model.dart](../../base_flutter/lib/ui/base/base_view_model.dart) — StateNotifier + runCatching (177 lines)
- [base_page.dart](../../base_flutter/lib/ui/base/base_page.dart) — reactive UI binding (92 lines)
- [login_state.dart](../../base_flutter/lib/ui/page/login/view_model/login_state.dart) — concrete state example (19 lines)
- [login_view_model.dart](../../base_flutter/lib/ui/page/login/view_model/login_view_model.dart) — concrete ViewModel example (58 lines)
- [app_provider_observer.dart](../../base_flutter/lib/ui/base/app_provider_observer.dart) — lifecycle debug observer (63 lines)
- [loading_state_provider.dart](../../base_flutter/lib/ui/base/loading_state_provider.dart) — InheritedWidget loading propagation (24 lines)
- [base_popup.dart](../../base_flutter/lib/ui/base/base_popup.dart) — dialog deduplication base (15 lines)

<!-- AI_VERIFY: generation-complete -->
