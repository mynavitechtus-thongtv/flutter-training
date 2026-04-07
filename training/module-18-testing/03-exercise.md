# Module 18 – Exercises: Testing

> **Mục tiêu**: Thực hành testing từ cơ bản đến nâng cao — chạy tests, viết unit test, tạo golden test, và AI-assisted testing.

📌 **Recap**: M7 (BaseViewModel) · M8 (Riverpod providers) · M15 (LoginViewModel)

---

## Exercise 1 ⭐ — Chạy Tests & Đọc Output

<!-- AI_VERIFY: exercise-1 -->

### Mục tiêu

Làm quen với test runner, hiểu output, phân biệt unit / widget / golden test.

### Acceptance Criteria

- [ ] Chạy `make ut` (unit tests), `make wt` (widget tests) không lỗi
- [ ] Chạy test cụ thể: `flutter test test/unit_test/ui/page/login/view_model/login_view_model_test.dart`
- [ ] Coverage HTML report mở được (`make cov_ut` → `coverage/html/index.html`)
- [ ] Phân biệt được test nào pass/fail trong output
- [ ] Trả lời: Tại sao `make te` không chạy integration tests? Golden tests nằm ở đâu? Coverage filter những file nào?

<details>
<summary>🏗️ Architecture Hint</summary>

- Các make targets: `make ut`, `make wt`, `make te`, `make cov_ut`, `make ug`
- Coverage: `grep -A 5 "cov_ut:" makefile` để xem filter
- Golden test location: tìm trong `widget_test/` directory

</details>

---

## Exercise 2 ⭐⭐ — Viết Unit Test cho ViewModel

<!-- AI_VERIFY: exercise-2 -->

### Mục tiêu

Viết unit test mới theo pattern happy/unhappy cho một ViewModel method.

### Acceptance Criteria

- [ ] Chọn 1 ViewModel để test (recommend: mở rộng `login_view_model_test.dart` hoặc viết test cho ViewModel khác)
- [ ] Ít nhất 1 happy + 1 unhappy test case
- [ ] Dùng đúng pattern: `when/thenAnswer`, `verify/verifyNever`, `expect`
- [ ] Test name mô tả rõ scenario: `'when X happens, Y should occur'`
- [ ] Mỗi test chỉ test MỘT behavior
- [ ] Không mock unit-under-test, chỉ mock dependencies
- [ ] Chạy pass: `flutter test <path>`

<details>
<summary>🏗️ Architecture Hint</summary>

- Reference: `test/unit_test/ui/page/login/view_model/login_view_model_test.dart`
- Pattern: `setUp` → `group('method')` → `group('happy'/'unhappy')` → `test()`
- AAA: Arrange (setup mocks) → Act (call method) → Assert (expect/verify)
- Dùng `const` cho dummy data, không hardcode trong `expect`

</details>

<details>
<summary>💡 Gợi ý chi tiết (mở khi stuck > 15 phút)</summary>

- Happy test idea: `when email is empty, login should not call API` → `verifyNever(() => appApiService.login(...))`
- Unhappy test idea: mock API throws → verify state has error
- Sử dụng `mocktail` package cho mocking

</details>

---

## Exercise 3 ⭐⭐ — Widget Test: Login Form Interaction 🔴 MUST-KNOW

<!-- AI_VERIFY: exercise-3-widget -->

### Mục tiêu

Viết **widget test** cho Login Page — kiểm tra UI behavior.

### Acceptance Criteria

- [ ] Tạo file `test/widget_test/ui/page/login/login_page_widget_test.dart`
- [ ] Test: fields render (đủ 2 `PrimaryTextField`)
- [ ] Test: email input accepted + displayed
- [ ] Test: login button disabled khi fields empty
- [ ] Test: login button enabled sau khi nhập cả email + password
- [ ] Test: error message hiển thị khi login fails
- [ ] Test: eye icon toggle password visibility
- [ ] Ít nhất 4/6 test cases viết xong, chạy pass
- [ ] Mỗi test dùng pattern: Arrange (`pumpWidget`) → Act (`tap`/`enterText`) → Assert (`expect`)

<details>
<summary>🏗️ Architecture Hint</summary>

- References: `login_page.dart`, `test/widget_test/ui/component/primary_text_field/primary_text_field_test.dart`, `test/common/test_util.dart`
- Dùng `ProviderScope` + `TestConfig.baseOverrides()` cho widget test setup
- Có thể tạo helper `_LoginFormTestWidget` để test form mà không cần full page routing
- `find.byType(PrimaryTextField)`, `tester.enterText()`, `tester.tap()`, `tester.pumpAndSettle()`

</details>

<details>
<summary>💡 Gợi ý chi tiết (mở khi stuck > 15 phút)</summary>

- Button disabled: `expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull)`
- Button enabled: `expect(...onPressed, isNotNull)` sau `enterText` cả 2 fields
- Eye toggle: tìm icon button, `tap()`, kiểm tra `obscureText` thay đổi
- Error: mock API error, `pumpAndSettle()`, `expect(find.text(errorMessage), findsOneWidget)`

</details>

---

## Exercise 4 ⭐⭐ — Golden Test

<!-- AI_VERIFY: exercise-4 -->

### Mục tiêu

Hiểu golden test workflow — generate, compare, update.

### Acceptance Criteria

- [ ] Tìm được ít nhất 2 file có golden assertions (`matchesGoldenFile` / `screenMatchesGolden`)
- [ ] Chạy `flutter test --tags=golden` thành công
- [ ] Hiểu flow: change code → golden fail → `make ug` → golden pass
- [ ] Trả lời: Tại sao golden test trên macOS và Linux có thể cho kết quả khác nhau? Khi nào `make ug` vs khi nào golden fail là bug thật?

<details>
<summary>🏗️ Architecture Hint</summary>

- Tìm golden files: `grep -r "matchesGoldenFile\|screenMatchesGolden\|multiScreenGolden" test/ --include="*.dart" -l`
- Infrastructure: `test/flutter_test_config.dart`, `test/common/test_config.dart`
- Thử break: thay đổi nhỏ widget → chạy golden test → observe fail → `make ug` → **revert**

</details>

---

## Exercise 5 ⭐⭐⭐ — AI Dojo: Test Generation & Analysis

<!-- AI_VERIFY: exercise-5 -->

### Mục tiêu

Sử dụng AI tools để accelerate test writing và phân tích coverage gaps.

### Acceptance Criteria

- [ ] Prompt AI với ViewModel code + test pattern từ codebase → generate test skeleton
- [ ] Chạy `make cov_ut`, tìm ViewModel có coverage < 80%
- [ ] Prompt AI phân tích missing test cases → viết 2-3 bổ sung
- [ ] AI-generated tests chạy pass
- [ ] Review: sửa ít nhất 1 test case AI generate sai
- [ ] Viết note: AI generate đúng/sai pattern gì? Test behavior hay implementation detail?

<details>
<summary>🏗️ Architecture Hint</summary>

- Prompt template: paste ViewModel code + test pattern → ask AI generate tests following same pattern
- Review checklist: tests test behavior (không phải implementation detail), mocking đúng, happy + unhappy, assertions meaningful
- Coverage: `make cov_ut` → `coverage/html/index.html`

</details>

---

## Tổng kết Exercises

| # | Độ khó | Skill |
|---|--------|-------|
| 1 | ⭐ | Chạy tests, đọc output |
| 2 | ⭐⭐ | Viết unit test |
| 3 | ⭐⭐ 🔴 | Widget test — login form |
| 4 | ⭐⭐ | Golden test workflow |
| 5 | ⭐⭐⭐ | AI-assisted testing |

→ **Forward ref**: M19 (CI/CD) sẽ tích hợp `make te` + `make cov` vào CI pipeline.

→ **Tiếp theo**: [04-verify.md](./04-verify.md) — Verification checklist.

<!-- AI_VERIFY: generation-complete -->
