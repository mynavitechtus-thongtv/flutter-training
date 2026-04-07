# Exercises — Thực hành Architecture & Barrel Files

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 1](../module-01-app-entrypoint/) (hiểu boot sequence, DI setup).

---

## ⭐ Exercise 1: Trace Import Chain

**Mục tiêu:** Hiểu cách mọi file import qua barrel file — trace từ UI page đến dependency thực tế.

### Hướng dẫn

1. Mở [home_page.dart](../../base_flutter/lib/ui/page/home/home_page.dart).
2. Tìm dòng `import` — xác nhận import qua `index.dart` (relative path).
3. Từ `index.dart`, tìm export statement cho `HomeViewModel` hoặc class nào đó được dùng trong `home_page.dart`.
4. Mở file thực tế (VD: `ui/page/home/view_model/home_view_model.dart`) — đọc imports của file đó.
5. Điền bảng:

### Template

| # | File | Import statement | Import qua barrel? |
|---|------|-----------------|-------------------|
| 1 | `home_page.dart` | `import '...index.dart'` | ✅ / ❌ |
| 2 | `home_view_model.dart` | ? | ✅ / ❌ |
| 3 | `app_api_service.dart` | ? | ✅ / ❌ |
| 4 | `di.dart` | ? | ✅ / ❌ (exception?) |

**Câu hỏi suy nghĩ:**
- File nào **KHÔNG** import qua barrel file? Tại sao?
- Nếu rename `home_view_model.dart` thành `home_vm.dart`, cần update những file nào?

### ✅ Checklist hoàn thành
- [ ] Điền đủ 4 rows trong bảng
- [ ] Xác nhận ít nhất 3/4 files import qua `index.dart`
- [ ] Tìm ra exception (file nào import trực tiếp)
- [ ] Trả lời 2 câu hỏi suy nghĩ

---

## ⭐ Exercise 2: Map Project Layers

**Mục tiêu:** Phân loại files trong project theo layer — hiểu ranh giới giữa các layers.

### Hướng dẫn

Chạy lệnh sau để đếm tự động:

```bash
cd base_flutter

# Total exports
grep -c "^export" lib/index.dart

# Per layer
grep -c "^export 'common/" lib/index.dart
grep -c "^export 'data_source/" lib/index.dart
grep -c "^export 'exception/" lib/index.dart
grep -c "^export 'model/" lib/index.dart
grep -c "^export 'navigation/" lib/index.dart
grep -c "^export 'resource/" lib/index.dart
grep -c "^export 'ui/" lib/index.dart
```

### Template

Ghi nhận kết quả từ commands trên:

| Layer | Số exports | Top-3 sub-folders |
|-------|-----------|-------------------|
| `common/` | ? | helper, util, ? |
| `data_source/` | ? | api, ?, ? |
| `exception/` | ? | ?, ?, ? |
| `model/` | ? | ?, ?, ? |
| `navigation/` | ? | ?, ?, ? |
| `resource/` | ? | ?, ?, ? |
| `ui/` | ? | page, component, ? |
| Root files | ? | — |
| **Tổng** | **?** | — |

**Câu hỏi phân tích:**
- Layer nào có nhiều exports nhất, ít nhất? Giải thích tại sao dựa trên vai trò của layer đó.
- Nếu team thêm feature mới (VD: "payment"), layer nào sẽ tăng export nhiều nhất?
- Thử `grep "^export 'ui/page/" lib/index.dart | wc -l` — so sánh với `grep "^export 'ui/component/" lib/index.dart | wc -l`. Page vs Component layer nào lớn hơn? Tại sao?

### ✅ Checklist hoàn thành
- [ ] Chạy grep commands thành công, ghi nhận số exports cho 7 layers
- [ ] Xác định top-3 sub-folders cho mỗi layer (dùng `grep "^export 'common/" lib/index.dart` để xem sub-paths)
- [ ] Trả lời 3 câu hỏi phân tích

---

## ⭐⭐ Exercise 3: Add New File to Barrel

**Mục tiêu:** Trải nghiệm workflow thêm file mới vào project — từ tạo file, chạy `make ep`, đến verify barrel update.

### Scenario

Team yêu cầu thêm utility function `formatCurrency()` trong `common/util/`.

### Hướng dẫn từng bước

**Bước 1 — Tạo file mới:**

```bash
touch lib/common/util/currency_util.dart
```

**Bước 2 — Viết nội dung:**

```dart
// lib/common/util/currency_util.dart

/// Format a number as currency string.
/// Example: formatCurrency(1234.5) => '¥1,235'
String formatCurrency(double amount, {String symbol = '¥'}) {
  final rounded = amount.round();
  final formatted = rounded.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '$symbol$formatted';
}
```

**Bước 3 — Chạy `make ep`:**

```bash
cd base_flutter
make ep
```

**Bước 4 — Verify barrel update:**

```bash
grep 'currency_util' lib/index.dart
```

Expected output:
```
export 'common/util/currency_util.dart';
```

**Bước 5 — Verify import works:**

Mở bất kỳ file nào đã import `index.dart`. IDE nên nhận diện `formatCurrency` trong autocomplete.

**Bước 6 — Revert (theo đúng thứ tự):**

```bash
# (1) Xóa file vừa tạo
rm lib/common/util/currency_util.dart

# (2) Regenerate barrel file (loại bỏ export của file đã xóa)
make ep

# (3) Verify index.dart không còn export currency_util
grep 'currency_util' lib/index.dart && echo '❌ Chưa clean' || echo '✅ Clean'

# (4) Safety net — git checkout đảm bảo index.dart trở về trạng thái ban đầu
git checkout lib/index.dart
```

### ✅ Checklist hoàn thành
- [ ] File `currency_util.dart` tạo đúng trong `common/util/`
- [ ] `make ep` chạy thành công (exit code 0)
- [ ] `index.dart` chứa export statement cho `currency_util.dart`
- [ ] Export nằm đúng vị trí alphabet (giữa `common/util/app_util.dart` và `common/util/date_time_util.dart`)
- [ ] Đã revert tất cả thay đổi

> 💡 **FE Perspective**
> **Flutter:** Thêm file mới chỉ cần chạy `make ep` → barrel file tự động update. CI sẽ fail nếu quên chạy (xem `check_ci` target trong makefile).
> **React/Vue tương đương:** Thêm file mới phải **manual update** barrel `index.ts` — dễ quên, không có CI check tự động.
> **Khác biệt quan trọng:** Dart barrel auto-generated + CI enforcement → zero-maintenance. JS/TS barrel manual → source of bugs khi team members quên update.

---

## ⭐⭐⭐ Exercise 4: AI Prompt Dojo — Architecture Review

**Mục tiêu:** Dùng AI (Copilot/ChatGPT) để review kiến trúc project — đánh giá output theo tiêu chí kỹ thuật.

### Prompt để gửi AI

Copy prompt dưới đây, gửi cho AI tool (Copilot Chat, ChatGPT, etc.):

```
Analyze the Flutter project architecture based on these exports from lib/index.dart:

Layers:
- common/ (config, constant, env, helpers, hooks, types, utils)
- data_source/ (api clients, json decoders, middleware, database, firebase, preferences)
- exception/ (app exceptions, exception mappers, exception handlers)
- model/ (api models, entities, enums, converters)
- navigation/ (app router, route guards, observers)
- resource/ (colors, fonts, images, shadows, text styles, themes)
- ui/ (base classes, components, pages, popups, shared providers)

Rules:
1. All files export through single barrel file (index.dart)
2. Import only via index.dart, never direct imports
3. index.dart is auto-generated by `make ep`

Questions:
1. What architecture pattern does this follow? (Clean Architecture, MVC, MVVM, etc.)
2. Is the layer separation correct? Any files in wrong layers?
3. What are the dependency rules between layers?
4. Compare with a typical React/Next.js project structure.
5. Suggest one improvement to the folder structure.
```

### Đánh giá AI output

Chấm điểm AI response theo 5 tiêu chí:

| # | Tiêu chí | Pass / Fail | Ghi chú |
|---|---------|-------------|---------|
| 1 | Xác định đúng architecture pattern (layer-based / clean architecture variant) | ? | |
| 2 | Nhận ra barrel file pattern và lợi ích | ? | |
| 3 | Dependency direction đúng (ui → navigation → data_source → model → common) | ? | |
| 4 | So sánh FE hợp lý (không hallucinate) | ? | |
| 5 | Improvement suggestion khả thi và không vi phạm project conventions (VD: không suggest import trực tiếp) | ? | |

**Target:** ≥ 3/5 tiêu chí pass.

**Ghi chú:**
- Nếu AI suggest "import directly for better tree-shaking" → **FAIL tiêu chí 5** (vi phạm project convention)
- Nếu AI gọi đây là "MVC" → **FAIL tiêu chí 1** (đây KHÔNG phải MVC — không có Controller layer)
- Nếu AI suggest "use feature-based structure" → cần đánh giá: suggestion có acknowledge trade-offs không?

### ✅ Checklist hoàn thành
- [ ] Đã gửi prompt cho AI tool
- [ ] Chấm điểm 5 tiêu chí
- [ ] ≥ 3/5 pass
- [ ] Ghi chú cụ thể AI response sai ở đâu (nếu có)
- [ ] (Optional) Thử prompt khác, so sánh quality giữa các AI tools

---

**Tiếp theo:** [04-verify.md](./04-verify.md) — Checklist tự đánh giá toàn module.

<!-- AI_VERIFY: generation-complete -->
