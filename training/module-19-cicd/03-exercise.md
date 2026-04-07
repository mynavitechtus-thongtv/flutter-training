# Module 19 – Exercises: CI/CD, Lint & Production Readiness

> **Mục tiêu**: Thực hành tracing CI pipeline, thêm custom lint rule, cấu hình environment mới, và CAPSTONE tổng hợp toàn bộ kiến thức từ M0–M19.

📌 **Recap**: M0 (pubspec.yaml, makefile) · M3 (Config, env files) · M18 (testing infrastructure)

---

## Exercise 1 ⭐ — Trace CI Pipeline

<!-- AI_VERIFY: exercise-1 -->

### Mục tiêu

Trace toàn bộ CI flow từ local commit đến deployment.

### Acceptance Criteria

- [ ] Trace `lefthook.yml`: pre-commit hook chạy script nào? Commit-msg validate gì?
- [ ] Trace `make check_ci`: điền bảng 8 steps (mỗi step: make target + kiểm tra gì)
- [ ] Trace `codemagic.yaml` CI workflow: trigger khi nào? Skip gì? Artifacts nào?
- [ ] So sánh adhoc vs distribution workflow: output khác nhau? Steps thêm?
- [ ] Giải thích flow: commit → hook → push → pipeline → deploy

<details>
<summary>🏗️ Architecture Hint</summary>

- `cat lefthook.yml` để xem hooks
- `grep -A 15 "^check_ci:" makefile` để xem 8 steps
- `grep -A 15 "^  ci:" codemagic.yaml` cho CI workflow

</details>

---

## Exercise 2 ⭐⭐ — Đọc hiểu Custom Lint Rule

<!-- AI_VERIFY: exercise-2 -->

> ⚠️ **Lưu ý:** Bài gốc yêu cầu viết custom lint rule từ đầu (dùng Dart AST visitor). Đây là kỹ năng nâng cao, không phù hợp survey tier. Bài tập đã chuyển sang **đọc hiểu rule có sẵn**. Phần implement đầy đủ nằm ở Bonus bên dưới.

### Mục tiêu

Đọc hiểu một custom lint rule có sẵn trong `super_lint/`, trace logic và giải thích cách hoạt động.

### Acceptance Criteria

- [ ] Mở `super_lint/lib/src/lints/` — liệt kê tất cả lint rules có sẵn
- [ ] Chọn 1 rule (ví dụ: `avoid_unnecessary_async_function.dart`) và đọc kỹ source code
- [ ] Trả lời các câu hỏi:
  - Rule này kiểm tra (check) điều gì? Vi phạm gì sẽ bị báo lỗi?
  - Rule extends class nào? Constructor nhận tham số gì?
  - Trong `check()`, registry callback nào được dùng? (vd: `addMethodInvocation`, `addFunctionDeclaration`, ...)
  - `problemMessage` hiển thị gì cho developer?
- [ ] Trace flow: rule được register ở đâu trong `lib/super_lint.dart`?
- [ ] Trace config: rule được enable/disable ở đâu trong `analysis_options.yaml`?
- [ ] Vẽ sơ đồ đơn giản: `analysis_options.yaml` → `super_lint.dart` (register) → `rule file` (check logic) → `reporter` (báo lỗi)

<details>
<summary>🏗️ Architecture Hint</summary>

- `ls super_lint/lib/src/lints/` để xem danh sách rules
- Rule pattern: extends `CommonLintRule<dynamic>`, constructor nhận `CustomLintConfigs`
- `RuleConfig(name: '...', configs: configs, problemMessage: (_) => '...')`
- Register: xem list trong `lib/super_lint.dart`

</details>

<details>
<summary>⭐⭐⭐ Bonus Challenge: Viết `AvoidPrintStatement` từ đầu</summary>

> Đây là bài gốc — dành cho trainee muốn thử sức với Dart AST. Hoàn thành phần chính trước.

**Mục tiêu:** Thêm `AvoidPrintStatement` rule vào `super_lint/`.

**Acceptance Criteria:**
- [ ] Tạo `lib/src/lints/avoid_print_statement.dart` — detect `print()` calls, suggest `Logger` thay thế
- [ ] Rule extends `CommonLintRule`, override `check()` dùng `context.registry.addMethodInvocation`
- [ ] Register trong `lib/super_lint.dart`
- [ ] Config trong `analysis_options.yaml`

**Gợi ý:**
- Tham khảo: `super_lint/lib/src/lints/avoid_unnecessary_async_function.dart` cho pattern
- Trong `check()`: dùng `context.registry.addMethodInvocation` để detect `print()` calls
- Check `node.methodName.name == 'print'` hoặc kiểm tra target type
- Report: `reporter.reportErrorForNode(code, node)`
- Tương tự ESLint `no-console` rule nhưng dùng Dart AST visitor

</details>

---

## Exercise 3 ⭐⭐ — Thêm Environment Mới

<!-- AI_VERIFY: exercise-3 -->

### Mục tiêu

Trace process thêm environment **`uat`** (User Acceptance Testing).

### Acceptance Criteria

- [ ] Liệt kê ≥ 8 files/configs cần thay đổi cho env `uat`
- [ ] Viết workflow YAML skeleton cho `adhoc_uat` (dựa trên `adhoc_staging`)
- [ ] Giải thích secret encoding: `base64 -i dart_defines/uat.json | pbcopy` → Codemagic env var
- [ ] Valid YAML syntax cho workflow

<details>
<summary>🏗️ Architecture Hint</summary>

- Files cần thay đổi: `dart_defines/`, `codemagic.yaml`, `makefile`, Firebase configs, iOS signing, `env_config.vars`
- Tham khảo `adhoc_staging` workflow trong `codemagic.yaml` và replace `staging` → `uat`
- Key configs: `DART_DEFINES_UAT`, `APP_APPLE_ID_UAT`, `ios_uat_distribution_profile`

</details>

---

## Exercise 4a ⭐⭐ — CAPSTONE: Trace Architecture & CI Flow

<!-- AI_VERIFY: exercise-capstone-a -->

### Mục tiêu

Từ 1 feature requirement, trace qua tất cả layers đến production deployment — tổng hợp kiến thức M0–M19.

### Scenario

> **Feature**: Thêm "Profile Page" — hiển thị user info, edit name/avatar, caching offline.

### Acceptance Criteria

**Phần A: Architecture Trace**
- [ ] Xác định ≥ 6 layers cần tạo: Navigation (M5), Page UI (M9), ViewModel (M7-8), Data Model (M11), API (M12), Storage (M14)
- [ ] Liệt kê tất cả files cần tạo/sửa cho mỗi layer

**Phần B: Test Plan**
- [ ] Liệt kê unit tests cần viết (ViewModel tests, AAA pattern)
- [ ] Liệt kê widget/golden tests cần viết

**Phần C: CI Readiness**
- [ ] Chạy `make check_ci` locally — pass hết
- [ ] Xác định key checks: `MissingGoldenTest`, `TestFolderMustMirrorLibFolder`

**Phần D: Deploy Plan**
- [ ] Trace: develop → `adhoc_develop` → `distribution_store_staging` → `distribution_store_production`

<details>
<summary>🏗️ Architecture Hint</summary>

- Files: `lib/ui/page/profile/profile_page.dart` + `view_model/profile_state.dart` + `view_model/profile_view_model.dart`
- State: `@freezed class ProfileState with _$ProfileState implements BaseState`
- ViewModel: `StateNotifierProvider.autoDispose<ProfileViewModel, CommonState<ProfileState>>`
- Page: `@RoutePage()` + register trong `app_router.dart`
- Test: `test/unit_test/ui/page/profile/view_model/profile_view_model_test.dart`

</details>

### Deliverable

Document: architecture diagram, file list, test plan, CI trace, deploy plan — connects ≥ 8 modules.

---

## Exercise 4b ⭐⭐⭐ — CAPSTONE (Bonus): Implementation — Running Code

<!-- AI_VERIFY: exercise-capstone-b -->

> **Optional** — dành cho trainee muốn thực hành end-to-end. Hoàn thành Exercise 4a trước.

### Mục tiêu

Implement thực tế feature Profile Page từ architecture trace ở Exercise 4a.

### Acceptance Criteria

- [ ] Tạo `ProfileState` (Freezed) với: `displayName`, `email`, `avatarUrl`
- [ ] Tạo `ProfileViewModel extends BaseViewModel<ProfileState>` với `loadProfile()`
- [ ] Tạo `ProfilePage extends BasePage` với `buildPage()` hiển thị profile info
- [ ] Tạo unit test: happy path + failure path cho `loadProfile()`
- [ ] `make gen` → code generation thành công
- [ ] `flutter analyze` → no issues
- [ ] Tests pass
- [ ] Code follow patterns đúng từ M07 (BaseViewModel), M08 (Provider), M09 (BasePage)

<details>
<summary>💡 Gợi ý chi tiết (mở khi stuck > 15 phút)</summary>

- Copy login pattern: State → ViewModel → Page, thay field names
- `loadProfile()`: dùng `runCatching` + mock data (hoặc real API nếu available)
- Page: `select((s) => s.displayName)` cho từng field để optimize rebuilds
- Test: mock ref, verify state after `loadProfile()`
- Route: `AutoRoute(page: ProfileRoute.page)` trong `app_router.dart`
- `dart run build_runner build` sau khi thêm `@RoutePage()` + `@freezed`

</details>

### Deliverable

Running code: ProfilePage hoạt động, tests pass, CI green.

---

## Tổng kết Exercises

| Exercise | Difficulty | Focus | Kết quả |
|----------|-----------|-------|---------|
| 1 ⭐ | Trace CI | Đọc config files, hiểu flow | Bảng 8-step + flow diagram |
| 2 ⭐⭐ | Đọc hiểu lint rule | super_lint architecture | Trace diagram + Q&A |
| 3 ⭐⭐ | New environment | Multi-file config change | File list + workflow yaml |
| 4a ⭐⭐ | **CAPSTONE: Trace** | Architecture + CI trace M0–M19 | Production readiness document |
| 4b ⭐⭐⭐ | **CAPSTONE: Implement** (bonus) | Full implementation | Running code + tests pass |

→ **Next**: [04-verify.md](./04-verify.md) — verification checklist cho toàn bộ module.

<!-- AI_VERIFY: generation-complete -->
