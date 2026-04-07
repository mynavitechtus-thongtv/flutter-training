# Module 10: Hooks & Custom Hooks

## Tổng quan

Module này đi sâu vào **Flutter Hooks** — hệ thống quản lý state & lifecycle trong `build()` method. Bạn sẽ hiểu tại sao `BasePage` extends `HookConsumerWidget`, cách dùng built-in hooks (`useState`, `useEffect`, `useScrollController`, `useFocusNode`, `useRef`), và cách viết custom hooks (`useBackBlocker`, `useFocusNodeRefocusOnResume`). Cuối module, bạn sẽ tự viết custom hook `useDebounce`.

**Cycle:** CODE (đọc hook files) → EXPLAIN (hiểu patterns & rules) → PRACTICE (identify + build custom hooks).

**Prerequisite:** Hoàn thành [Module 7 — Base UI Framework](../module-07-base-viewmodel/) (BasePage extends HookConsumerWidget), [Module 8 — State Management](../module-08-riverpod-state/) (ref API), và [Module 9 — Page Structure](../module-09-page-structure/) (useEffect, useScrollController in pages).

---

## 🔄 Re-Anchor — Ôn lại M7-M9

| Module | Concept cần nhớ | Kết nối M10 |
|--------|-----------------|-------------|
| **M7 — Base UI Framework** | `BasePage` extends `HookConsumerWidget`, `buildPage(context, ref)` | M10 giải thích **tại sao** HookConsumerWidget, hook lifecycle |
| **M8 — State Management** | `ref.watch/read` API, providers | M10: hooks **complement** Riverpod — local state vs global state |
| **M9 — Page Structure** | `useEffect([], ...)` init, `useScrollController()` in pages | M10 deep-dive **cách hooks work** và **custom hook extraction** |

→ Nếu bất kỳ concept nào chưa rõ → quay lại module tương ứng trước khi tiếp tục.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Giải thích tại sao `BasePage` dùng `HookConsumerWidget` thay vì `ConsumerWidget`?
2. Liệt kê 5 built-in hooks trong codebase và purpose mỗi hook?
3. Phân biệt 3 modes `useEffect` dựa trên dependency keys (`[]`, `[deps]`, `null`)?
4. Mô tả custom hook pattern — naming, khi nào extract, file placement?
5. Trace `useBackBlocker` flow: Back → block → confirm → `addPostFrameCallback` → pop?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 11 — i18n](../module-11-i18n/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

7 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | flutter_hooks & HookConsumerWidget | 🔴 MUST-KNOW | Foundation — tại sao hooks work |
| 2 | Built-in Hooks (5 hooks) | 🔴 MUST-KNOW | Core tools — dùng ở mọi page |
| 3 | useEffect Lifecycle | 🔴 MUST-KNOW | Most complex hook — mount/deps/cleanup |
| 4 | Custom Hook Pattern | 🟡 SHOULD-KNOW | Extract reusable hook logic |
| 5 | useBackBlocker (PopScope) | 🟡 SHOULD-KNOW | Real custom hook — navigation guard |
| 6 | useFocusNodeRefocusOnResume | 🟡 SHOULD-KNOW | Hook composition + controller pattern |
| 7 | Hook Rules & Limitations | 🟢 AI-GENERATE | Constraints — avoid runtime bugs |

**Phân bố:** 🔴 ~43% · 🟡 ~43% · 🟢 ~14%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc HookConsumerWidget → built-in hooks → custom hooks | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 7 concepts từ hook patterns | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 4 bài tập identify + cleanup + custom hook + AI | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + cross-check | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Identify & Classify Hooks | ⭐ |
| 2 | useEffect Cleanup — Stream Subscription | ⭐ |
| 3 | Custom Hook — useDebounce | ⭐⭐ |
| 4 | AI Prompt Dojo — Hook Architecture Review | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [use_back_blocker.dart](../../base_flutter/lib/common/hook/use_back_blocker.dart) — custom hook, PopScope integration (83 lines)
- [use_focus_node_refocus_on_resume.dart](../../base_flutter/lib/common/hook/use_focus_node_refocus_on_resume.dart) — custom hook, lifecycle + controller (26 lines)
- [refocus_on_resume_controller.dart](../../base_flutter/lib/common/controller/refocus_on_resume_controller.dart) — business logic for refocus
- [base_page.dart](../../base_flutter/lib/ui/base/base_page.dart) — HookConsumerWidget base, useState for loading overlay
- [splash_page.dart](../../base_flutter/lib/ui/page/splash/splash_page.dart) — useEffect init pattern (37 lines)
- [login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart) — useScrollController (157 lines)
- [main_page.dart](../../base_flutter/lib/ui/page/main/main_page.dart) — useEffect with empty cleanup (94 lines)

## Unlocks (Module 11+)

Sau khi hoàn thành Module 10, bạn sẽ:

- **Module 11 — i18n:** Internationalization patterns dùng hooks cho locale switching và dynamic text.
- **Module 12 — Data Layer:** API integration với `useEffect` init pattern đã học trong M10.
- **Module 13 — Error Handling:** Error states interact với hooks lifecycle — `useEffect` cleanup khi error navigation.
- **Module 14 — Local Storage:** SharedPreferences/Isar access patterns dùng hooks cho reactive data binding.

<!-- AI_VERIFY: generation-complete -->
