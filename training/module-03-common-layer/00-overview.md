# Module 3: Common Layer Deep Dive

## Tổng quan

Module này đi sâu vào **common layer** — tầng nền tảng mà mọi layer khác trong project phụ thuộc. Bạn sẽ đọc `config.dart`, `constant.dart`, `env.dart`, `log.dart`, `result.dart`, extension methods, helper classes — hiểu configuration patterns, environment management, logging system, Result union type, và utility architecture.

**Cycle:** CODE (đọc common layer files) → EXPLAIN (hiểu patterns) → PRACTICE (trace + build + extend).

**Prerequisite:** Hoàn thành [Module 0 — Dart Primer](../module-00-dart-primer/) (lint rules, codegen), [Module 1 — App Entrypoint](../module-01-app-entrypoint/) (Config usage in main, DI init), và [Module 2 — Architecture & Barrel](../module-02-architecture-barrel/) (barrel pattern, layer structure).

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Giải thích được `Config` pattern: tại sao dùng `static const` + `kDebugMode` và tree-shaking effect?
2. Trace được flow: `dart_defines/*.json` → `--dart-define` → `Env.flavor` → `Env.init()`?
3. Phân biệt `Log.d()` (static) vs `logD()` (LogMixin) và khi nào dùng `dev.log()` vs `print()`?
4. Mô tả `Result<T>` union type, `when()`/`map()` pattern matching? Khi nào dùng `Result<T>` thay vì try-catch trực tiếp?
5. Viết được extension method trên nullable type và hiểu `safeCast` / `let` pattern?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 4 — Exception Layer](../module-04-exception-handling/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

7 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | Configuration Pattern | 🔴 MUST-KNOW | Mọi feature flag phụ thuộc Config |
| 2 | Constants & Magic Numbers | 🔴 MUST-KNOW | Vi phạm = code review reject |
| 3 | Environment Management | 🔴 MUST-KNOW | Multi-flavor build standard |
| 4 | Logging System | 🟡 SHOULD-KNOW | Debug tool #1, dùng hàng ngày |
| 5 | Result Type & Sealed Classes | 🟡 SHOULD-KNOW | Foundation cho error handling toàn app |
| 6 | Extensions & Utility Patterns | 🟡 SHOULD-KNOW | Productivity boost, dùng everywhere |
| 7 | Helper Architecture | 🟢 AI-GENERATE | Biết đặt platform code ở đâu |

**Phân bố:** 🔴 ~43% · 🟡 ~43% · 🟢 ~14%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc config → constant → env → log → result → extension → object_util → helper/ | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 7 concepts từ common layer patterns | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 5 bài tập trace + build + extend + AI review | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + cross-check docs | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace Config Usage Chain | ⭐ |
| 2 | Env Flavor Investigation | ⭐ |
| 3 | Build Result Pattern Consumer | ⭐⭐ |
| 4 | Write Extension Method | ⭐⭐ |
| 5 | AI Prompt Dojo — Common Layer Review | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [config.dart](../../base_flutter/lib/common/config.dart) — debug flags, feature toggles
- [constant.dart](../../base_flutter/lib/common/constant.dart) — app-wide constants (~128 lines)
- [env.dart](../../base_flutter/lib/common/env.dart) — flavor enum, dart-define integration
- [log.dart](../../base_flutter/lib/common/util/log.dart) — Log class + LogMixin (~146 lines)
- [result.dart](../../base_flutter/lib/common/type/result.dart) — freezed Result<T> union type
- [extension.dart](../../base_flutter/lib/common/util/extension.dart) — collection/context extensions
- [object_util.dart](../../base_flutter/lib/common/util/object_util.dart) — safeCast, let
- [helper/](../../base_flutter/lib/common/helper/) — platform service wrappers (7 helpers)
- [dart_defines/](../../base_flutter/dart_defines/) — per-environment config JSON files

---

## Unlocks (Module 4+)

Sau khi hoàn thành Module 3, bạn sẽ:

- **Module 4 — Exception Layer:** Deep dive `AppException`, error mappers, error handlers. `Result.failure(AppException)` từ M3 là foundation.
- **Module 7 — Base UI Framework:** State management dùng `Result<T>` cho ViewModel data flow. `Log`, `Config` observer flags dùng trong provider setup.
- **Module 8 — State Management:** Riverpod providers kết nối với helpers từ M3 (`connectivityHelperProvider`, `packageHelperProvider`).

<!-- AI_VERIFY: generation-complete -->
