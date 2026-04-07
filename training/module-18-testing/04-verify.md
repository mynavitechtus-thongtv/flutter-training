# Verification — Kiểm tra kết quả Module 18

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được 4 tầng testing pyramid (Unit → Widget → Golden → Integration) và trade-off speed vs confidence? | Testing Pyramid | 🔴 |
| 2 | Tôi mô tả được flow `testExecutable()` → `GoldenToolkit.runWithConfiguration()` → `loadFonts()` → `base.main()`? | Test Config | 🔴 |
| 3 | Tôi phân biệt được `thenReturn` (sync) vs `thenAnswer` (async) vs `thenThrow` (error) trong Mocktail? | Mocktail | 🔴 |
| 4 | Tôi biết khi nào cần `registerFallbackValue` (non-nullable `any()`) và `resetMocktailState()` trong `tearDown`? | Mocktail | 🔴 |
| 5 | Tôi apply được AAA pattern (Arrange → Act → Assert) và test cả state changes (`expect`) lẫn side effects (`verify`)? | Unit Test Pattern | 🔴 |
| 6 | Tôi tuân thủ convention: `group('method')` → `group('happy')` / `group('unhappy')` với descriptive test names? | Unit Test Convention | 🟡 |
| 7 | Tôi chạy được golden test (`flutter test --tags=golden`) và hiểu update flow (`make ug`)? | Golden Testing | 🟡 |
| 8 | Tôi hiểu `LocalFileComparatorWithThreshold` với 0.003% tolerance — tại sao cần threshold? | Golden Testing | 🟡 |
| 9 | Tôi phân biệt được integration test vs widget test (real device, no mocking, driver pattern)? | Integration Testing | 🟢 |

**Target:** 5/5 Yes cho 🔴 MUST-KNOW, tối thiểu 7/9 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Run Existing Tests ⭐

- [ ] `make ut` chạy thành công — tất cả unit tests pass
- [ ] `make wt` chạy thành công — tất cả widget tests pass
- [ ] `make cov_ut` chạy thành công — coverage report generated
- [ ] Đọc coverage report — hiểu ý nghĩa line/branch coverage %

### Exercise 2 — Write Unit Test ⭐⭐

- [ ] Test file đặt đúng mirror path: `test/unit_test/ui/page/*/..._view_model_test.dart`
- [ ] Có `group('method')` → `group('happy')` / `group('unhappy')` structure
- [ ] ≥ 1 happy path test: verify state change sau action thành công
- [ ] ≥ 1 unhappy path test: verify error handling khi action fail
- [ ] Mock setup đúng: `when(() => mock.method()).thenAnswer((_) async => ...)`
- [ ] All tests pass khi chạy lại (deterministic)

### Exercise 3 — Widget Test: Login Form ⭐⭐

- [ ] Tạo file test đúng path: `test/widget_test/ui/page/login/login_page_widget_test.dart`
- [ ] Test: fields render (đủ 2 `PrimaryTextField`)
- [ ] Test: login button disabled khi fields empty, enabled sau khi nhập
- [ ] Dùng pattern: Arrange (`pumpWidget`) → Act (`tap`/`enterText`) → Assert (`expect`)
- [ ] Ít nhất 4 test cases viết xong, chạy pass

### Exercise 4 — Golden Test Exploration ⭐⭐

- [ ] Tìm ≥ 1 golden test file trong codebase
- [ ] Chạy golden tests thành công (`flutter test --tags=golden`)
- [ ] Hiểu update flow: code change → golden fail → review → `make ug` accept
- [ ] Hiểu tại sao cần load fonts thật (Ahem font problem — default font gây sai golden)

### Exercise 5 — AI-Generated Tests ⭐⭐⭐

- [ ] AI generate ≥ 3 test cases cho một ViewModel
- [ ] Review AI output — identify ≥ 1 incorrect mock setup hoặc wrong assertion
- [ ] Sửa AI-generated tests cho pass
- [ ] Reflection: AI mạnh ở boilerplate generation, yếu ở business logic edge cases

---

## 3. Quick Quiz

<details>
<summary>Q1: Tại sao unit tests chiếm số lượng lớn nhất trong testing pyramid?</summary>

Unit tests **nhanh nhất** (milliseconds), **rẻ nhất** (không cần device/emulator), và **deterministic** (không flaky). Chúng test logic isolated — một function, một method — nên dễ viết, dễ debug khi fail. Widget tests chậm hơn (cần pump widget), integration tests chậm nhất (cần real device). Pyramid shape phản ánh: nhiều unit tests (base rộng) + ít integration tests (đỉnh hẹp) = best cost/confidence ratio.
</details>

<details>
<summary>Q2: <code>thenReturn</code> vs <code>thenAnswer</code> — khi nào dùng cái nào?</summary>

`thenReturn(value)` cho **synchronous** return — dùng khi method trả về value trực tiếp (VD: `when(() => mock.name).thenReturn('John')`). `thenAnswer((_) async => value)` cho **asynchronous** return — dùng khi method trả về `Future` (VD: `when(() => mock.login()).thenAnswer((_) async => true)`). Nếu dùng `thenReturn` cho `Future` method → trả `Future` object thay vì await result → test sai logic. `thenThrow(exception)` dùng để simulate error path.
</details>

<details>
<summary>Q3: Tại sao cần <code>registerFallbackValue</code> khi dùng <code>any()</code> với non-nullable types?</summary>

`any()` trong Mocktail cần tạo một "placeholder" value cho type matching. Với nullable types (`String?`), placeholder = `null`. Nhưng với **non-nullable** types (`LoginRequest`), Mocktail không thể tự tạo instance → cần `registerFallbackValue(LoginRequest(...))` trong `setUpAll`. Fallback value **không phải** expected value — nó chỉ dùng để satisfy type system. Actual matching vẫn dựa trên `any()` matcher.
</details>

<details>
<summary>Q4: Golden test fail sau khi thay đổi UI — làm sao biết đó là intentional change hay bug?</summary>

**Review visual diff** — so sánh golden file cũ vs screenshot mới. Nếu change **đúng ý** (VD: thay đổi button color theo design) → chạy `make ug` để update golden files → commit golden files mới. Nếu change **không mong muốn** (VD: text bị lệch) → đó là bug, fix code trước. `LocalFileComparatorWithThreshold` với 0.003% tolerance cho phép tiny pixel differences (anti-aliasing, font rendering) pass mà không cần update — chỉ significant visual changes mới fail.
</details>

<details>
<summary>Q5: <code>flutter_test_config.dart</code> load fonts thật — tại sao không dùng default font?</summary>

Flutter test environment mặc định dùng **Ahem font** — một font đặc biệt chỉ render rectangles thay vì actual glyphs. Golden tests capture visual output → Ahem font tạo golden images **không giống** real app. `loadFonts()` trong `flutter_test_config.dart` load fonts thực tế (từ `assets/fonts/`) → golden images phản ánh chính xác UI production. Đây cũng là lý do golden tests cần `GoldenToolkit.runWithConfiguration` — config bao gồm font loading + device pixel ratio.
</details>

---

## 4. Code Quality Checks

- [ ] Tests chạy deterministic — pass 100% khi chạy lại
- [ ] Không có flaky tests (tests fail ngẫu nhiên)
- [ ] Test names mô tả rõ scenario: `'when X, should Y'`

---

## 5. FE Perspective Mapping

| Flutter | FE Equivalent |
|---------|---------------|
| Unit test (`flutter_test`) | Jest / Vitest |
| Widget test | React Testing Library |
| Golden test | Storybook + Percy/Chromatic visual regression |
| Integration test | Cypress / Playwright E2E |
| `flutter_test_config.dart` | `jest.config.ts` / `vitest.config.ts` |
| `mocktail` | `jest.fn()` / `jest.mock()` |

---

## 6. Backward Reference Check

- [ ] Nhận ra `LoginViewModel` (M15) là target test trong case study
- [ ] Hiểu `ref.read(provider)` mock pattern liên quan đến M8 (Riverpod)
- [ ] BaseViewModel (M7) methods được test qua subclass instances

## 7. Forward Reference

- [ ] Biết M19 (CI/CD) sẽ chạy `make te` + `make cov` tự động trong pipeline

---

## ✅ Module Complete

Hoàn thành khi:

- [ ] Self-assessment: ≥ 7/9 Yes (5/5 🔴 bắt buộc)
- [ ] Exercise 1 + 2 + 3 + 4 hoàn thành
- [ ] Quick Quiz trả lời đúng ≥ 3/5

---

## ➡️ Next Module

Hoàn thành Module 18! Bạn đã nắm vững testing (unit, widget, integration).

→ Tiến sang **[Module 19 — CI/CD](../module-19-cicd/)** để học continuous integration, deployment pipelines, Codemagic/Fastlane.

<!-- AI_VERIFY: generation-complete -->
