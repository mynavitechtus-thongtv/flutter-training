# Module 1: App Entrypoint & Bootstrap

## Tổng quan

Module này đi vào **điểm khởi đầu** của Flutter app: từ `main()` qua các bước init cho đến khi widget tree hiển thị trên screen. Bạn sẽ đọc `main.dart`, `app_initializer.dart`, `di.dart` — hiểu boot sequence, error boundary, DI setup, và Firebase initialization.

**Cycle:** CODE (đọc entry files) → EXPLAIN (hiểu boot concepts) → PRACTICE (trace + modify init).

**Prerequisite:** Hoàn thành [Module 0 — Dart Primer](../module-00-dart-primer/) (pubspec, make sync, codegen pipeline).

**⏱️ Thời lượng ước tính:** 45–60 phút.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Hiểu tại sao `WidgetsFlutterBinding.ensureInitialized()` phải gọi trước async operations?
2. Giải thích được `runZonedGuarded` và Zone error handling?
3. Biết cách `get_it` + `injectable` phối hợp (annotation → codegen → runtime)?
4. Hiểu vai trò `ProviderScope` trong Riverpod?

→ Nếu **4/4 Yes** — chuyển thẳng [Module 02 — Architecture](../module-02-architecture-barrel/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

7 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | Flutter App Entry Point | 🔴 MUST-KNOW | Sai = không hiểu app lifecycle |
| 2 | WidgetsFlutterBinding | 🔴 MUST-KNOW | Thiếu = crash trước runApp |
| 3 | runZonedGuarded | 🟡 SHOULD-KNOW | Global error handling |
| 4 | Init Sequence | 🟡 SHOULD-KNOW | Thứ tự init quan trọng |
| 5 | DI (get_it + injectable) | 🟡 SHOULD-KNOW | Nền tảng dependency management |
| 6 | ProviderScope | 🟢 AI-GENERATE | Riverpod root — deep dive ở M8 |
| 7 | Firebase Integration | 🟢 AI-GENERATE | Firebase.initializeApp() + Crashlytics — deep dive ở MB |

**Phân bố:** 🔴 ~29% · 🟡 ~43% · 🟢 ~28%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc main.dart → app_initializer.dart → di.dart | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 7 concepts từ boot sequence | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 4 bài tập trace + modify init | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + tiêu chí pass | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace the Boot Sequence | ⭐ |
| 2 | Add an Initialization Step | ⭐⭐ |
| 3 | Trace DI Registration | ⭐⭐ |
| 4 | Custom Boot Logger (🤖 AI Prompt Dojo) | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [main.dart](../../base_flutter/lib/main.dart) — app entry point
- [app_initializer.dart](../../base_flutter/lib/app_initializer.dart) — system initialization
- [di.dart](../../base_flutter/lib/di.dart) — DI container setup
- [log_instructions.md](../../base_flutter/docs/technical/log_instructions.md) — logging conventions

---

## Unlocks (Module 2+)

Sau khi hoàn thành Module 1, bạn sẽ:

- **Module 2 — Architecture:** Hiểu project structure (layers, folder convention). Kiến thức DI và init flow từ M1 là prerequisite.
- **Module 7 — Base UI Framework:** MyApp widget, theme, routing setup — build trên `ProviderScope` đã học ở M1.
- **Module 8 — State Management:** Deep dive Riverpod — `ProviderScope`, Provider types, observers.

→ Bắt đầu: [01-code-walk.md](./01-code-walk.md)

<!-- AI_VERIFY: generation-complete -->
