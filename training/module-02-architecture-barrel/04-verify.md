# Verification — Kiểm tra kết quả Module 2

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được barrel file là gì và tại sao project dùng 1 `index.dart` duy nhất? | Barrel File Pattern | 🔴 |
| 2 | Tôi biết cách import đúng (3 nhóm, luôn qua `index.dart`) và nhận ra import sai? | Import Convention | 🔴 |
| 3 | Tôi liệt kê được 7 layers và trách nhiệm chính của mỗi layer? | Layer Architecture | 🟡 |
| 4 | Tôi phân biệt khi nào dùng `factory`, `lazySingleton`, `factoryAsync`? | DI Registration Types | 🟡 |
| 5 | Tôi mô tả được widget tree từ `ProviderScope` đến `MaterialApp.router`? | App Widget Tree | 🟡 |
| 6 | Tôi nhận biết file generated (không sửa tay) và biết command regenerate? | Code Generation | 🟢 |

**Target:** 2/2 Yes cho 🔴 MUST-KNOW, tối thiểu 5/6 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace Import Chain ⭐

- [ ] Bảng có đủ **4 rows** (home_page, home_view_model, app_api_service, di.dart)
- [ ] Ít nhất 3/4 files import qua `index.dart`
- [ ] Xác nhận `di.dart` là exception (import `di.config.dart` trực tiếp)
- [ ] Trả lời câu hỏi rename — chỉ cần `make ep` (không manual update)

**Cross-check:** Mở từng file, verify import statement khớp với bảng.

### Exercise 2 — Map Project Layers ⭐

- [ ] Đếm đúng 7 layers + root files
- [ ] Tổng exports ≈ 160
- [ ] `ui/` có nhiều exports nhất (presentation layer phức tạp)
- [ ] `navigation/` có ít exports nhất (compact routing layer)

**Cross-check:** Chạy `grep -c` commands từ exercise, so sánh kết quả.

### Exercise 3 — Add New File to Barrel ⭐⭐

- [ ] File `currency_util.dart` đặt đúng trong `common/util/`
- [ ] `make ep` chạy thành công
- [ ] Export statement xuất hiện ở vị trí alphabet chính xác
- [ ] Function `formatCurrency` accessible qua `index.dart` import
- [ ] Đã revert tất cả thay đổi

**Cross-check [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md):**

| Rule | Kiểm tra |
|------|----------|
| Public files export qua `index.dart` | `make ep` thêm export? |
| Import luôn qua `index.dart` | Test import từ file khác? |
| Chạy `make ep` khi thêm file | Đã chạy? |

**Cross-check [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md):**

| Rule | Kiểm tra |
|------|----------|
| File name: snake_case | `currency_util.dart` ✅ |
| Function name: camelCase, verb+complement | `formatCurrency` ✅ |
| Parameter name: camelCase, include units | `amount` (OK), `symbol` (OK) |

### Exercise 4 — AI Prompt Dojo ⭐⭐⭐

- [ ] AI output đánh giá qua 5 tiêu chí
- [ ] ≥ 3/5 tiêu chí pass
- [ ] Ghi chú cụ thể AI response sai ở đâu (nếu có)
- [ ] AI **KHÔNG** suggest import file trực tiếp

---

## 3. docs/technical Cross-Check 🔴

Các rule từ [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) áp dụng cho M2:

| Rule | Áp dụng ở đâu trong M2 | Kiểm tra |
|------|------------------------|----------|
| Export qua `index.dart` | Barrel file pattern (Concept 1) | Hiểu tại sao rule này tồn tại? |
| Import qua `index.dart` | Import convention (Concept 2) | Nhận biết import sai? |
| Chạy `make ep` khi thêm/xóa file | Exercise 3 | Biết command và khi nào chạy? |
| Max 100 characters per line | Mọi code | File generated tuân thủ? |
| Formatting: `make fm` | Workflow | Biết chạy format trước commit? |

Các rule từ [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md) áp dụng cho M2:

| Rule | Áp dụng ở đâu | Kiểm tra |
|------|---------------|----------|
| File names: snake_case | Layer folders, file naming | `app_api_service.dart`, `home_page.dart` |
| Class names: PascalCase | `AppApiService`, `HomePage` | Consistency trong `index.dart` exports |
| Folder names: snake_case | `data_source/`, `json_decoder/` | Không dùng camelCase cho folders |
| No abbreviations | `connectivity_helper` (not `conn_helper`) | Check exports cho abbreviations |

---

## 4. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Import file trực tiếp (`import '../models/user.dart'`) | Lint error, code review reject | Dùng `import '...index.dart'` |
| 2 | Quên chạy `make ep` sau khi thêm file | CI fail, file mới không accessible | Luôn `make ep` trước commit |
| 3 | Sửa file generated (`di.config.dart`, `index.dart`) | Mất thay đổi khi chạy codegen | Sửa source → `make fb` / `make ep` |
| 4 | Đặt file sai layer (VD: util vào `ui/`) | Vi phạm dependency direction | Review layer responsibilities |
| 5 | Dùng `lazySingleton` cho stateless class | Giữ instance không cần thiết trong memory | Dùng `factory` (annotation `@injectable`) |

---

## 5. Module Completion Gate

Hoàn thành module khi:

- [ ] Self-assessment: ≥ 5/6 Yes
- [ ] Exercise 1 + 2: hoàn thành đúng
- [ ] Exercise 3: `make ep` workflow thành công
- [ ] Exercise 4: ≥ 3/5 AI evaluation pass
- [ ] Hiểu sự khác biệt giữa file generated vs manual

**Nếu pass → tiến đến:**
- [Module 3 — Common Layer](../module-03-common-layer/) — shared utilities, constants, extensions (layer `common/`)
- [Module 5 — Navigation & Routing](../module-05-navigation/) — widget tree, navigation (layer `navigation/`)
- [Module 8 — State Management](../module-08-riverpod-state/) — Riverpod providers, `HookConsumerWidget` deep dive

<!-- AI_VERIFY: generation-complete -->
