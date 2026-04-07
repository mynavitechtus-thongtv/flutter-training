# Module 0: Dart Reading Primer + Toolchain Setup

## Tổng quan

Module này có **hai phần**: (1) **Dart Language Fundamentals** — nắm vững Dart syntax, null safety, async, OOP cho FE developers chuyển từ JS/TS sang Dart, và (2) **Toolchain Setup** — đọc hiểu cấu hình project Flutter (`pubspec.yaml`, `makefile`, `analysis_options.yaml`, `build.yaml`, `slang.yaml`).

**Cycle:** LANGUAGE (đọc Dart fundamentals) → CODE (đọc config) → EXPLAIN (hiểu concept) → PRACTICE (chạy toolchain).

**Prerequisite:** Flutter SDK ≥ 3.3.0 đã cài đặt, clone `base_flutter` thành công. Kinh nghiệm JavaScript/TypeScript (React, Vue, hoặc Angular).

**⏱️ Thời lượng ước tính:** 90–120 phút (pre-work trước buổi sync-up). Nếu đã biết Dart → bỏ qua Dart Language section, chỉ học Toolchain section (~30 phút).

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

### Dart Language
1. Hiểu null safety (`?`, `!`, `??`, `late`) và type system (`dynamic` vs `Object`)?
2. Hiểu functions: named parameters (`required`), arrow syntax, closures, `typedef`?
3. Viết được class với named constructor, factory constructor, `this.` shorthand?
4. Phân biệt `extends` vs `implements` vs `with` (mixin)?
5. Hiểu `Future`, `async/await`, `Stream` basics?
6. Đọc được pattern matching, sealed classes, records (Dart 3)?

### Toolchain
7. Hiểu semantic versioning và SDK constraint `>=3.3.0 <4.0.0`?
8. Phân biệt `dependencies` vs `dev_dependencies` và pattern annotation ↔ generator?
9. Đã chạy `build_runner` và hiểu flow codegen `.g.dart` / `.freezed.dart`?
10. Biết `strict-casts`, `strict-raw-types` trong `analysis_options.yaml` chặn gì?

→ Nếu **10/10 Yes** — chuyển thẳng [Module 01 — App Entrypoint](../module-01-app-entrypoint/).
→ Nếu chỉ pass Dart (1-6) → đọc phần Toolchain: [01-code-walk.md](./01-code-walk.md).
→ Nếu chỉ pass Toolchain (7-10) → đọc phần Dart: [02-concept.md § Part B](./02-concept.md).
→ Nếu có bất kỳ **No** — hoàn thành toàn bộ module này.

---

## 🏷️ Badge Summary

7 toolchain concepts + 17 Dart language concepts, phân loại theo mức độ cần nắm:

**Dart Language (trong 02-concept.md § Dart Language Quick Reference):**

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | Variables, Types & Null Safety | 🔴 MUST-KNOW | Foundation cho mọi code |
| 2 | Functions & Closures | 🔴 MUST-KNOW | Callback patterns khắp nơi |
| 3 | Classes & Constructors | 🔴 MUST-KNOW | OOP foundation |
| 4 | Inheritance, Mixins & Generics | 🟡 SHOULD-KNOW | Base class patterns |
| 5 | Async/Await & Streams | 🔴 MUST-KNOW | API calls, state |
| 6 | Pattern Matching & Records | 🟢 AI-GENERATE | Dart 3 features — AI hỗ trợ pattern matching boilerplate |

**Toolchain (01-code-walk.md → 02-concept.md):**

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | Dart SDK & Version Constraints | 🔴 MUST-KNOW | Sai = không build được |
| 2 | Dependency Management | 🟡 SHOULD-KNOW | Hiểu dependency tree |
| 3 | Code Generation Pipeline | 🟡 SHOULD-KNOW | Nền tảng codegen |
| 4 | Static Analysis & Type Safety | 🔴 MUST-KNOW | Chất lượng code |
| 5 | Localization (i18n) Strategy | 🟢 AI-GENERATE | AI hỗ trợ được |
| 6 | Toolchain Workflow | 🟡 SHOULD-KNOW | makefile commands |
| 7 | Asset Management | 🟢 AI-GENERATE | AI hỗ trợ được |

**Phân bố (tổng 13 concept groups):** 🔴 46% · 🟡 31% · 🟢 23%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc 5 file config cốt lõi của `base_flutter` | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 7 toolchain + 17 Dart language concepts | EXPLAIN — tooling, codegen & Dart fundamentals |
| [03-exercise.md](./03-exercise.md) | 5 bài tập thực hành trên codebase | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + tiêu chí pass | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 0A | Null Safety Drill (Dart) | ⭐ |
| 0B | Class & Constructor Patterns (Dart) | ⭐ |
| 0C | Async & Error Handling (Dart) | ⭐⭐ |
| 1 | Trace the Dependency Tree | ⭐ |
| 2 | Run the Toolchain | ⭐ |
| 3 | Add a New Dependency | ⭐⭐ |
| 4 | Understand Lint Rules | ⭐⭐ |
| 5 | Add a Localization Key (🤖 AI Prompt Dojo) | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [pubspec.yaml](../../base_flutter/pubspec.yaml) — khai báo project chính
- [makefile](../../base_flutter/makefile) — workflow commands
- [analysis_options.yaml](../../base_flutter/analysis_options.yaml) — lint rules
- [flutter_dart_instructions.md](../../base_flutter/docs/technical/flutter_dart_instructions.md) — coding standards

---

## Unlocks (Module 1+)

Sau khi hoàn thành Module 0, bạn sẽ:

- **Module 1 — App Entrypoint:** Đọc `main.dart`, `app_initializer.dart`, hiểu app bootstrap flow. Kiến thức về dependency injection (`injectable`) và codegen từ M0 là prerequisite.
- **Module 2+:** Mọi module sau đều giả định bạn biết chạy `make sync`, `make fb`, `make lint`.

→ Bắt đầu: [01-code-walk.md](./01-code-walk.md)

<!-- AI_VERIFY: generation-complete -->
