# Module 9: Page Structure & Widgets

## Tổng quan

Module này đi sâu vào **page-level architecture** — cách mỗi page được cấu thành từ `@RoutePage` + `BasePage`, lifecycle init pattern, `Consumer` selective rebuilds, `CommonScaffold` shared layout, form inputs, và tab navigation host. Bạn sẽ đọc `splash_page.dart` (simplest), `login_page.dart` (form + analytics), `main_page.dart` (tabs) — hiểu page anatomy pattern và 14 shared component families.

**Cycle:** CODE (đọc page files) → EXPLAIN (hiểu patterns) → PRACTICE (trace + build + optimize).

**Prerequisite:** Hoàn thành [Module 5 — Navigation](../module-05-navigation/) (routes, AppNavigator), [Module 6 — Resource & Theme](../module-06-resource-theme/) (AppColors, style(), l10n), [Module 7 — Base UI Framework](../module-07-base-viewmodel/) (BasePage, buildPage lifecycle), và [Module 8 — State Management](../module-08-riverpod-state/) (ref.watch/read, providers).

---

## 🔄 Re-Anchor — Ôn lại M5-M8

| Module | Concept cần nhớ | Kết nối M9 |
|--------|-----------------|------------|
| **M5 — Navigation** | `@RoutePage()`, `AppNavigator`, `push/pop/replace` | M9 page anatomy dùng `@RoutePage`, tab navigation qua `AutoTabsScaffold` |
| **M6 — Resource & Theme** | `AppColors`, `style()`, `color.xxx`, `l10n.xxx` | M9 mọi page dùng `style()` + `color.` + `l10n.` cho text/color/i18n |
| **M7 — Base UI Framework** | `BasePage<S,P>`, `buildPage(context, ref)`, loading/exception | M9 giải thích **chi tiết** page anatomy mà M7 đặt nền tảng |
| **M8 — State Management** | `ref.watch/read`, `StateNotifierProvider`, `select` | M9 dùng `Consumer` + `select` cho selective rebuilds trong pages |

→ Nếu bất kỳ concept nào chưa rõ → quay lại module tương ứng trước khi tiếp tục.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Liệt kê được 4 pieces bắt buộc khi tạo page mới (`@RoutePage`, `extends BasePage<S,P>`, `provider`, `screenViewEvent`)?
2. Giải thích tại sao `useEffect` + `Future.microtask` thay vì gọi `init()` trực tiếp?
3. Phân biệt khi nào dùng `Consumer` widget vs `ref.watch` trực tiếp — và lý do performance?
4. Mô tả `CommonScaffold` widget tree (Scaffold → IgnorePointer → SafeArea → Shimmer → body)?
5. Trace data flow: `PrimaryTextField.onChanged` → `ref.read(notifier)` → State → Consumer rebuild?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 10 — Hooks](../module-10-hooks/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

7 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | Page Anatomy (@RoutePage + BasePage) | 🔴 MUST-KNOW | Foundation — mọi page tuân theo pattern này |
| 2 | useEffect + microtask Init Pattern | 🔴 MUST-KNOW | Lifecycle hook — dùng ở mọi page có data init |
| 3 | Consumer Widget — Selective Rebuilds | 🔴 MUST-KNOW | Performance — granular render control |
| 4 | CommonScaffold & Shared Layout | 🟡 SHOULD-KNOW | Layout wrapper — SafeArea, shimmer, keyboard |
| 5 | Form Input Pattern (PrimaryTextField) | 🟡 SHOULD-KNOW | Data flow — user input → ViewModel → UI |
| 6 | Tab Navigation (AutoTabsScaffold) | 🟡 SHOULD-KNOW | UX pattern — tab host page structure |
| 7 | Analytics Extension Pattern | 🟢 AI-GENERATE | Clean separation — page-scoped analytics |

**Phân bố:** 🔴 ~43% · 🟡 ~43% · 🟢 ~14%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc splash → login → main → components | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 7 concepts từ page structure patterns | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 5 bài tập trace + add field + build page + refactor + AI | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + cross-check | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace Splash Page Lifecycle | ⭐ |
| 2 | Add Form Field to Login Page | ⭐ |
| 3 | Build Settings Page (full pattern) | ⭐⭐ |
| 4 | Consumer Refactor — Optimize Login | ⭐⭐ |
| 5 | AI Prompt Dojo — Page Structure Review | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [splash_page.dart](../../base_flutter/lib/ui/page/splash/splash_page.dart) — minimal page skeleton, useEffect init (37 lines)
- [login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart) — form inputs, Consumer, analytics extension (157 lines)
- [main_page.dart](../../base_flutter/lib/ui/page/main/main_page.dart) — AutoTabsScaffold + BottomNavigationBar (94 lines)
- [home_page.dart](../../base_flutter/lib/ui/page/home/home_page.dart) — data display, shimmer, pagination (133 lines)
- [my_profile_page.dart](../../base_flutter/lib/ui/page/my_profile/my_profile_page.dart) — profile display, dialog actions (107 lines)
- [base_page.dart](../../base_flutter/lib/ui/base/base_page.dart) — BasePage abstract class, exception/loading/analytics (M7)
- [common_scaffold.dart](../../base_flutter/lib/ui/component/common_scaffold/common_scaffold.dart) — layout wrapper
- [primary_text_field.dart](../../base_flutter/lib/ui/component/primary_text_field/primary_text_field.dart) — form input component

---

## Unlocks (Module 10+)

Sau khi hoàn thành Module 9, bạn sẽ:

- **Module 10 — Hooks:** Deep dive Flutter Hooks — `useEffect`, `useScrollController`, `useMemoized` lifecycle patterns.
- **Module 11 — i18n:** `slang` localization — ARB files, plural, select → localized strings mà pages consume.
- **Module 12 — Data Layer:** API layer → data fetch trong `init()` → UI display trong `buildPage`.
- **Module 13 — Error Handling:** Exception flow từ API → `BasePage.ref.listen(appException)` → error UI.

<!-- AI_VERIFY: generation-complete -->
