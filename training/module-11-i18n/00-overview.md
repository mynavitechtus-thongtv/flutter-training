# Module 11: Internationalization & Localization

## Tổng quan

Module này đi sâu vào **i18n pipeline** của codebase — cách `slang` package biến JSON translation source thành typed Dart code, `l10n` accessor pattern cho compile-safe string access, `TranslationProvider` widget integration, và workflow thêm/quản lý strings. Bạn sẽ đọc `slang.yaml` (config), `ja.i18n.json` (46 keys), `app_string.g.dart` (generated output), `my_app.dart` (integration point) — hiểu toàn bộ i18n data flow từ source đến UI.

**Cycle:** CODE (đọc config + generated files) → EXPLAIN (hiểu patterns) → PRACTICE (trace + add strings + AI review).

**Prerequisite:** Hoàn thành [Module 0 — Dart Primer](../module-00-dart-primer/) (slang.yaml intro, make ln), [Module 6 — Resource & Theme](../module-06-resource-theme/) (TranslationProvider in MyApp, l10n setup), và [Module 9 — Page Structure](../module-09-page-structure/) (l10n.xxx usage in pages).

---

## 🔄 Re-Anchor — Ôn lại M0, M6, M9

| Module | Concept cần nhớ | Kết nối M11 |
|--------|-----------------|-------------|
| **M0 — Dart Primer** | `slang.yaml` config, `make ln` command | M11 deep-dive config keys, codegen pipeline chi tiết |
| **M6 — Resource & Theme** | `TranslationProvider` wraps `MyApp`, `l10n` accessor | M11 giải thích **Method A vs Method B**, locale management |
| **M9 — Page Structure** | `l10n.login`, `l10n.email` trong pages | M11 trace full data flow: JSON → codegen → l10n.key → UI |

→ Nếu bất kỳ concept nào chưa rõ → quay lại module tương ứng trước khi tiếp tục.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Mô tả được 9 config keys trong `slang.yaml` và vai trò?
2. Phân biệt simple string vs parameterized string (`$param`) trong JSON source?
3. Liệt kê pipeline: JSON → `make ln` → `.g.dart` → `l10n.key` — biết khi nào phải re-generate?
4. Phân biệt Method A (`l10n.key`) vs Method B (`context.l10n.key`) — khi nào dùng?
5. Thực hiện được workflow thêm string mới end-to-end?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 12 — Data Layer](../module-12-data-layer/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

8 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | slang Setup (YAML Config) | 🔴 MUST-KNOW | 9 lines config controls entire i18n pipeline |
| 2 | Translation Source Format | 🔴 MUST-KNOW | JSON key = Dart getter, `$param` = compile-safe |
| 3 | Code Generation Flow | 🔴 MUST-KNOW | JSON → `make ln` → `.g.dart` → typed access |
| 4 | l10n Accessor Pattern | 🟡 SHOULD-KNOW | Method A (global) vs B (context) — use case |
| 5 | Locale Fallback Behavior | 🟡 SHOULD-KNOW | Missing key = compile error, locale fallback chain |
| 6 | ARB vs slang Comparison | 🟢 AI-GENERATE | Trade-off format, speed, type safety |
| 7 | TranslationProvider & Locale Mgmt | 🟡 SHOULD-KNOW | Widget tree integration, delegates, runtime switch |
| 8 | Adding New Strings Workflow | 🟢 AI-GENERATE | 4-step process: JSON → make ln → use → verify |

**Phân bố:** 🔴 ~38% · 🟡 ~38% · 🟢 ~25%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc slang.yaml → JSON → generated → my_app → pages | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 8 concepts từ i18n pipeline patterns | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 4 bài tập trace + add string + parameterized + AI | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + cross-check | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace l10n Data Flow | ⭐ |
| 2 | Add a New Simple String | ⭐ |
| 3 | Add Parameterized String | ⭐⭐ |
| 4 | AI Prompt Dojo — i18n Architecture Review | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [slang.yaml](../../base_flutter/slang.yaml) — i18n codegen config (9 lines)
- [ja.i18n.json](../../base_flutter/lib/resource/l10n/ja.i18n.json) — Japanese translations (46 keys)
- [app_string.g.dart](../../base_flutter/lib/generated/app_string.g.dart) — generated infrastructure (AppLocale, l10n, TranslationProvider)
- [app_string_ja.g.dart](../../base_flutter/lib/generated/app_string_ja.g.dart) — generated locale strings (AppString class)
- [my_app.dart](../../base_flutter/lib/ui/my_app.dart) — TranslationProvider integration + LocaleSettings
- [login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart) — l10n.login, l10n.email, l10n.password usage
- [main_page.dart](../../base_flutter/lib/ui/page/main/main_page.dart) — l10n.home, l10n.myPage tab labels
- [makefile](../../base_flutter/makefile) — `make ln` = `dart run slang`

---

## Unlocks (Module 12+)

Sau khi hoàn thành Module 11, bạn sẽ:

- **Module 12 — Data Layer:** i18n strings cho error messages, API response localization, localized UI feedback.
- **Module 13 — Error Handling:** Localized exception messages, `AppExceptionAction` descriptions in user's locale.
- **Module 14 — Local Storage:** Persist user's locale preference qua `AppPreferences` (SharedPreferences) → restore locale khi app restart.
- **Optional Module B — Push & Deep Links:** Locale-aware deep link routing, localized push notification content, `AppLocaleUtils` cho locale detection từ URL parameters.
- **Multi-locale expansion:** Foundation để thêm `en.i18n.json`, `vi.i18n.json` → runtime locale switch → settings page language picker.

<!-- AI_VERIFY: generation-complete -->
