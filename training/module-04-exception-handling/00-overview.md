# Module 4: Exception Handling & Error Flow

## Tổng quan

Module này đi sâu vào **exception layer** — hệ thống xử lý lỗi toàn app. Bạn sẽ đọc `AppException` hierarchy, `ExceptionHandler` dispatch, `ExceptionMapper` transformation — hiểu cách raw errors (Dio, Firebase, ...) được convert thành typed exceptions, mang theo action instruction, và hiển thị UI phù hợp cho user.

**Cycle:** CODE (đọc exception layer files) → EXPLAIN (hiểu patterns) → PRACTICE (trace + build + extend).

**Prerequisite:** Hoàn thành [Module 0 — Dart Primer](../module-00-dart-primer/) (OOP: abstract class, implements, sealed class), [Module 1 — App Entrypoint](../module-01-app-entrypoint/) (`runZonedGuarded` error boundary), [Module 2 — Architecture](../module-02-architecture-barrel/) (layer structure, barrel pattern), và [Module 3 — Common Layer](../module-03-common-layer/) (`Result<T>` type, `Log.e()`, `Config`).

> 🎯 **Dart OOP cần biết trước:** Module này sử dụng `abstract class`, `implements`, `extends`, `sealed class`, generic constraints (`<T extends AppException>`), và factory constructors. Nếu chưa quen → đọc [Dart Language Fundamentals](../module-00-dart-primer/02-concept.md#dart-language-quick-reference) Group 3 (OOP: Classes, Inheritance & Mixins) và Group 4 (Async & Error Handling) trước khi bắt đầu.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Mô tả được `AppException` contract: `message` + `action` abstract getters, tại sao `implements Exception`?
2. Liệt kê 4 exception subtypes và giải thích mỗi loại handle domain lỗi nào?
3. Trace được flow: `DioException` → `DioExceptionMapper.map()` → `RemoteException(kind)` → `action` → `ExceptionHandler.switch`?
4. Giải thích `AppExceptionAction` enum — 7 actions map đến UI behaviors cụ thể nào?
5. Phân biệt 2 layers error catching: `runZonedGuarded` (global) vs `Result.fromAsyncAction` (per-action)?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 5 — Navigation & Routing](../module-05-navigation/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

7 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | Exception Hierarchy & Abstract Base | 🔴 MUST-KNOW | Contract cho mọi error handling trong app |
| 2 | Typed Exception Subtypes | 🔴 MUST-KNOW | Enum-driven, exhaustive switch enforcement |
| 3 | Action-Driven Error Handling | 🔴 MUST-KNOW | Exception tự khai báo UI behavior |
| 4 | Exception Mapping Pattern | 🟡 SHOULD-KNOW | Raw → typed transformation, testable |
| 5 | Error Boundary Integration | 🟡 SHOULD-KNOW | Global vs per-action error catching layers |
| 6 | Result Type Integration | 🟡 SHOULD-KNOW | Transport mechanism cho exceptions qua layers |
| 7 | Localized Error Messages | 🟢 AI-GENERATE | l10n integration, error code convention |

**Phân bố:** 🔴 ~43% · 🟡 ~43% · 🟢 ~14%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc app_exception → remote_exception → validation → firebase auth → uncaught → handler → mapper | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 7 concepts từ exception layer patterns | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 5 bài tập trace + add kind + create subtype + map error + AI review | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + hierarchy cross-check | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace Exception Flow End-to-End | ⭐ |
| 2 | Add a New ValidationExceptionKind | ⭐ |
| 3 | Create a New Exception Subtype | ⭐⭐ |
| 4 | Map Raw Error to Typed Exception | ⭐⭐ |
| 5 | AI Prompt Dojo — Test Generation | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [app_exception.dart](../../base_flutter/lib/exception/app_exception.dart) — abstract base class + `AppExceptionAction` enum
- [remote_exception.dart](../../base_flutter/lib/exception/remote_exception.dart) — API/network errors (12 kinds, ~130 lines)
- [validation_exception.dart](../../base_flutter/lib/exception/validation_exception.dart) — form validation errors (3 kinds)
- [app_firebase_auth_exception.dart](../../base_flutter/lib/exception/app_firebase_auth_exception.dart) — Firebase auth errors (6 kinds)
- [app_uncaught_exception.dart](../../base_flutter/lib/exception/app_uncaught_exception.dart) — catch-all fallback
- [exception_handler.dart](../../base_flutter/lib/exception/exception_handler/exception_handler.dart) — centralized UI dispatch (~90 lines)
- [app_exception_mapper.dart](../../base_flutter/lib/exception/exception_mapper/app_exception_mapper.dart) — mapper interface (8 lines)
- [dio_exception_mapper.dart](../../base_flutter/lib/exception/exception_mapper/dio_exception_mapper.dart) — Dio → RemoteException mapper (~100 lines)
- [result.dart](../../base_flutter/lib/common/type/result.dart) — `Result.failure(AppException)` transport (M3)
- [main.dart](../../base_flutter/lib/main.dart) — `runZonedGuarded` error boundary (M1)

---

## Unlocks (Module 7+)

Sau khi hoàn thành Module 4, bạn sẽ:

- **Module 7 — Base UI Framework:** ViewModel base class gọi `exceptionHandlerProvider.handleException()`. `isForcedErrorToHandle` quyết định ViewModel skip hay handle.
- **Module 9 — Page Structure:** `ErrorDialog`, `CommonSnackBar`, `MaintenanceModeDialog` — UI widgets được `ExceptionHandler` sử dụng.
- **Module 12 — Data Layer:** Full end-to-end: Dio interceptor → `DioExceptionMapper` → repository `Result.fromAsyncAction` → ViewModel → UI. Exception layer là trung tâm.

<!-- AI_VERIFY: generation-complete -->
