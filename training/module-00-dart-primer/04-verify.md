# Verification — Kiểm tra kết quả Module 0

> Đối chiếu bài làm với chuẩn [flutter_dart_instructions.md](../../base_flutter/docs/technical/flutter_dart_instructions.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng.

### Part A: Dart Language (→ [02-concept.md § Part B](./02-concept.md))

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| D1 | Tôi phân biệt được `final` vs `const` vs `late`? | Variables & Types | 🔴 |
| D2 | Tôi sử dụng được `?`, `!`, `??`, `?.` đúng ngữ cảnh? | Null Safety | 🔴 |
| D3 | Tôi viết được class với named constructor, factory, `this.` shorthand? | Classes | 🔴 |
| D4 | Tôi phân biệt được `extends` vs `implements` vs `with`? | Inheritance & Mixins | 🟡 |
| D5 | Tôi viết được `async`/`await` và handle error với `try/catch`? | Async & Errors | 🔴 |
| D6 | Tôi giải thích được generics `<T>`, bounded generics `<T extends X>`? | Generics | 🟡 |
| D7 | Tôi đọc hiểu được `sealed class`, pattern matching, records (Dart 3)? | Dart 3 Features | 🟢 |

**Target:** 4/4 Yes cho 🔴 MUST-KNOW (D1, D2, D3, D5), tối thiểu 5/7 tổng.

### Part B: Toolchain (→ [02-concept.md](./02-concept.md))

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được `>=3.3.0 <4.0.0` nghĩa gì? | SDK Constraints | 🔴 |
| 2 | Tôi phân biệt được `dependencies` vs `dev_dependencies`? | Dependency Mgmt | 🟡 |
| 3 | Tôi chỉ ra được 3 cặp annotation ↔ generator? | Dependency Mgmt | 🟡 |
| 4 | Tôi mô tả được flow: source + annotation → build_runner → `.g.dart`? | Codegen Pipeline | 🟡 |
| 5 | Tôi giải thích được `strict-casts` và `strict-raw-types` chặn gì? | Static Analysis | 🔴 |
| 6 | Tôi mô tả được flow `.i18n.json` → slang → `AppString`? | i18n | 🟢 |
| 7 | Tôi biết khi nào dùng `make sync` vs `make fb` vs `make check_ci`? | Toolchain | 🟡 |
| 8 | Tôi biết asset phải khai báo trong `pubspec.yaml` mới dùng được? | Asset Mgmt | 🟢 |

**Target:** 2/2 Yes cho 🔴 MUST-KNOW (Q1, Q5), tối thiểu 6/8 tổng.

---

## 2. Exercise Verification

### Exercise 0A — Null Safety Drill ⭐ (Dart)

- [ ] `greet(null)` trả về "Hello, Guest"
- [ ] `greet("Alice")` trả về "Hello, Alice"
- [ ] `safeParseInt(null)` trả về 0
- [ ] `safeParseInt("abc")` trả về 0
- [ ] Tìm được 3 ví dụ nullable field trong `base_flutter/lib/model/`

### Exercise 0B — Class & Constructor Patterns ⭐ (Dart)

- [ ] `copyWith` method chạy đúng: `dev.copyWith(timeout: 5000)` tạo instance mới
- [ ] Tìm được 2 factory constructor trong `base_flutter/lib/`
- [ ] Giải thích được sự khác biệt factory constructor vs named constructor

### Exercise 0C — Async & Error Handling ⭐⭐ (Dart)

- [ ] `fetchUsers([1, -1, 2])` trả về `['User_1', 'User_2']` (skip failed)
- [ ] Không throw exception khi 1 id fail
- [ ] So sánh `Future.wait` vs `Promise.all` đúng (Future.wait throw first error)

### Exercise 1 — Trace the Dependency Tree ⭐ (Toolchain)

- [ ] Bảng có đủ **5 cặp**: `freezed_annotation`↔`freezed`, `json_annotation`↔`json_serializable`, `injectable`↔`injectable_generator`, `auto_route`↔`auto_route_generator`, `slang`↔`slang_build_runner`
- [ ] Annotation packages nằm trong `dependencies`
- [ ] Generator packages nằm trong `dev_dependencies`
- [ ] Cột "Mục đích" không để trống

**Cross-check:** mở [pubspec.yaml](../../base_flutter/pubspec.yaml) và search từng package name.

### Exercise 2 — Run the Toolchain ⭐

- [ ] `make sync` exit code 0
- [ ] Liệt kê ≥ 5 file generated (`.g.dart` / `.freezed.dart` / `.gr.dart`)
- [ ] File `lib/generated/app_string.g.dart` tồn tại
- [ ] `make lint` không có **error** (warning chấp nhận được)

**Cross-check:** chạy `find lib -name "*.g.dart" | wc -l` — kết quả phải > 0.

### Exercise 3 — Add a Dependency ⭐⭐

- [ ] Thêm `url_launcher` đúng indentation (2 spaces, ngang hàng dependency khác)
- [ ] `make pg` thành công
- [ ] `pubspec.lock` diff có entry `url_launcher`
- [ ] Đã revert về trạng thái ban đầu (`git checkout pubspec.yaml pubspec.lock`)

### Exercise 4 — Understand Lint Rules ⭐⭐

- [ ] Viết function 3 positional params → `make lint` báo warning `prefer_named_parameters`
- [ ] Refactor sang `required` named params → `make lint` pass
- [ ] Đã xoá file `lib/exercise_lint_test.dart`

**Đối chiếu chuẩn:** [flutter_dart_instructions.md](../../base_flutter/docs/technical/flutter_dart_instructions.md) yêu cầu tuân thủ Effective Dart — named parameters là best practice khi function có > 2 params.

### Exercise 5 — Localization Key (🤖 AI) ⭐⭐⭐

- [ ] AI output đánh giá qua 4 tiêu chí: camelCase key, flat structure, Japanese value, unique key
- [ ] Key thêm vào `ja.i18n.json` đúng format
- [ ] `make ln` thành công
- [ ] `grep` tìm thấy key trong `app_string.g.dart`
- [ ] Đã revert lại trạng thái ban đầu

---

## 3. docs/technical Cross-Check 🔴

Các rule từ [flutter_dart_instructions.md](../../base_flutter/docs/technical/flutter_dart_instructions.md) áp dụng cho M0:

| Rule | Áp dụng ở đâu trong M0 | Kiểm tra |
|------|------------------------|----------|
| Follow Effective Dart guidelines | Toàn bộ code viết trong exercises | Đã đọc naming conventions? |
| Avoid `!` (force unwrap) | Chưa viết code production, nhưng **ghi nhớ** | — |
| Use `const` constructors | Chưa áp dụng trực tiếp — module sau | — |
| `prefer_relative_imports` | Sẽ gặp khi import trong `lib/` | Kiểm tra `analysis_options.yaml` có rule này |
| `use_super_parameters` | Sẽ gặp khi viết Widget — module sau | — |
| Avoid `print`, use logger | Nếu thêm debug code trong exercises → dùng logger | Không có `print()` trong code? |
| Arrow syntax for one-line functions | Exercise 4 refactor | Function body 1 dòng → dùng `=>` |
| `///` doc comments for public APIs | Chưa viết public API — ghi nhớ cho module sau | — |

> 💡 M0 chủ yếu **đọc + chạy toolchain**. Phần lớn rules sẽ áp dụng từ Module 1 trở đi. Ở đây cần **nhận biết** rules tồn tại.

---

## 4. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Edit file `.g.dart` / `.freezed.dart` | Mất thay đổi khi chạy `make fb` | Chỉ edit source file, chạy lại codegen |
| 2 | Quên `make fb` sau khi sửa model | Compile error do gen file outdated | Chạy `make fb` hoặc `make sync` |
| 3 | Sai indentation trong `pubspec.yaml` | `pub get` fail, YAML parse error | Dùng 2 spaces, không dùng tab |
| 4 | Dùng `^` version range thay vì exact pin | Không theo convention project | Pinned exact: `10.3.0` không phải `^10.3.0` |
| 5 | Thêm key i18n dạng `snake_case` | Codegen tạo getter sai naming convention | Dùng `camelCase` theo project convention |
| 6 | Chạy `flutter pub get` trực tiếp | Bỏ qua makefile workflow | Dùng `make pg` để nhất quán |

---

## 5. Module Completion Criteria

Hoàn thành **tất cả** mục dưới đây để pass Module 0:

**Dart Language:**
- [ ] **D1:** Self-Assessment Part A ≥ 5/7 Yes (bắt buộc tất cả 🔴 đều Yes)
- [ ] **D2:** Exercise 0A — null safety functions chạy đúng trên DartPad
- [ ] **D3:** Exercise 0B — copyWith + factory constructor nhận diện
- [ ] **D4:** Exercise 0C — async partial failure handling đúng

**Toolchain:**
- [ ] **C1:** Self-Assessment Part B ≥ 6/8 Yes (bắt buộc 2 câu 🔴 đều Yes)
- [ ] **C2:** Exercise 1 — bảng 5 cặp annotation ↔ generator đầy đủ
- [ ] **C3:** Exercise 2 — `make sync` + `make lint` thành công
- [ ] **C4:** Exercise 3 — thêm + revert dependency thành công
- [ ] **C5:** Exercise 4 — trải nghiệm lint warning → fix → pass
- [ ] **C6:** Exercise 5 — AI generate + evaluate + codegen thành công
- [ ] **C7:** Không còn file test/temp trong `lib/` (đã cleanup)
- [ ] **C8:** `git status` clean (không có uncommitted changes từ exercises)

> ✅ **Pass:** C1–C8 tất cả checked → chuyển sang [Module 01 — App Entrypoint](../module-01-app-entrypoint/).
> ❌ **Chưa pass:** Quay lại exercise/concept chưa hoàn thành, đối chiếu lại checklist.

<!-- AI_VERIFY: generation-complete -->
