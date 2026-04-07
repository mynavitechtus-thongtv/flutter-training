# Verification — Kiểm tra kết quả Module 19

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi vẽ/giải thích được 3-tầng pipeline: Local (lefthook) → PR (Bitbucket + Codemagic CI) → Deploy (Codemagic workflows)? | CI/CD Architecture | 🔴 |
| 2 | Tôi phân biệt được fail-fast (`check_ci`) vs report-all (`ci` with `skip_error=true`)? | CI/CD Architecture | 🔴 |
| 3 | Tôi liệt kê được 8 steps của `make check_ci` và mục đích mỗi step? | PR Quality Gate | 🔴 |
| 4 | Tôi giải thích được 3 hooks (pre-commit, commit-msg, pre-push) và tại sao pre-push lint bị disable? | Pre-commit Hooks | 🔴 |
| 5 | Tôi giải thích YAML anchor/alias pattern (`&running-ci` / `*running-ci`) trong pipeline config? | PR Quality Gate | 🟡 |
| 6 | Tôi kể được ≥5 lint rules của super_lint và mô tả pattern extend `CommonLintRule`? | Custom Lint | 🟡 |
| 7 | Tôi hiểu toggle mechanism (`make tcl force=true`) và tại sao cần toggle custom lint? | Custom Lint | 🟡 |
| 8 | Tôi kể được 4 environments (develop, qa, staging, production) và flow `dart_defines/*.json` encode/decode? | Build Variants | 🟡 |
| 9 | Tôi mô tả được flow code → TestFlight/Google Play và biết Codemagic cần config gì (code signing, keystore)? | Production Readiness | 🟢 |

**Target:** 4/4 Yes cho 🔴 MUST-KNOW, tối thiểu 7/9 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace CI Pipeline ⭐

- [ ] Hoàn thành bảng 8-step `make check_ci` với mục đích mỗi step
- [ ] Trace được flow: commit → hook → push → pipeline → deploy
- [ ] So sánh được adhoc workflow (email distribution) vs distribution workflow (store deploy)
- [ ] Biết Docker image nào dùng cho Bitbucket Pipeline (`ghcr.io/cirruslabs/flutter:3.38.7`)

### Exercise 2 — Custom Lint Rule ⭐⭐

- [ ] Tạo file rule theo đúng pattern (extend `CommonLintRule`)
- [ ] Override `check()` → dùng AST visitor → `reporter.atNode()`
- [ ] Register rule trong `super_lint.dart`
- [ ] Thêm config trong `analysis_options.yaml` under `custom_lint:`
- [ ] Rule detect đúng pattern — test trên real code

### Exercise 3 — New Environment ⭐⭐

- [ ] Liệt kê ≥ 8 files/configs cần thay đổi cho environment mới
- [ ] Viết workflow YAML skeleton hợp lệ
- [ ] Giải thích process tạo env vars trên Codemagic
- [ ] `dart_defines/*.json` file mới có đủ required keys

### Exercise 4 — CAPSTONE ⭐⭐⭐

- [ ] Architecture trace cover ≥ 6 layers
- [ ] Test plan đầy đủ (unit + widget + golden)
- [ ] CI trace cover 8 steps `make check_ci`
- [ ] Deploy plan từ develop → production
- [ ] Document connects ≥ 8 modules (M0–M19)

---

## 3. Quick Quiz

<details>
<summary>Q1: <code>make check_ci</code> dùng fail-fast — tại sao không chạy hết tất cả steps rồi mới báo lỗi?</summary>

**Fail-fast** dừng ngay khi step đầu tiên fail → tiết kiệm thời gian developer. Ví dụ: nếu `format check` fail ở step 2, không cần chạy `unit test` ở step 5 vì code chưa đạt chuẩn format. Ngược lại, `make ci` dùng `skip_error=true` để chạy **tất cả** steps và report toàn bộ lỗi — dùng trong CI server nơi cần biết **mọi** vấn đề trong một lần chạy để developer fix hết trước khi push lại.
</details>

<details>
<summary>Q2: Lefthook pre-push lint bị disable — tại sao?</summary>

Custom lint (`super_lint` + `custom_lint_builder`) chạy AST analysis trên **toàn bộ codebase** → rất chậm (có thể 30-60 giây). Chạy trước mỗi `git push` gây friction lớn cho developer workflow. Thay vào đó, lint được chạy trong **CI pipeline** (Bitbucket/Codemagic) — nơi có compute resources mạnh hơn và không block developer locally. `pre-commit` hook chỉ chạy nhanh: format check + analyze trên staged files.
</details>

<details>
<summary>Q3: YAML anchor <code>&running-ci</code> và alias <code>*running-ci</code> giải quyết vấn đề gì?</summary>

Anchor/alias là DRY pattern trong YAML. `&running-ci` **define** một block config (VD: Flutter version, cache paths, common setup steps). `*running-ci` **reference** block đó ở multiple pipelines (develop, staging, production). Không cần copy-paste → khi thay đổi Flutter version, chỉ sửa **một chỗ**. Tương đương variable/mixin trong CSS — single source of truth cho pipeline config.
</details>

<details>
<summary>Q4: <code>dart_defines/*.json</code> encode base64 — tại sao không pass plain text?</summary>

Flutter `--dart-define-from-file` đọc JSON file, nhưng giá trị trong JSON được **compiled vào binary**. Base64 encoding trong pipeline context giúp: **(1)** Tránh special characters break shell command (VD: `&`, `=` trong URL). **(2)** Codemagic environment variables an toàn khi truyền qua CI — không bị interpret sai. **(3)** Decode tại build time → giá trị thật chỉ tồn tại trong binary, không nằm plain text trong git history.
</details>

<details>
<summary>Q5: Project chạy dual CI (Bitbucket Pipelines + Codemagic) — tại sao cần cả hai?</summary>

**Bitbucket Pipelines** = lightweight CI cho **PR quality gate** — chạy format, analyze, unit test, coverage. Nhanh, dùng Docker container chuẩn. **Codemagic** = specialized **mobile CI/CD** — build iOS/Android, code signing, deploy to stores. Bitbucket không có macOS runner (cần cho iOS build). Codemagic đắt hơn per-minute → chỉ dùng cho build/deploy. Kết hợp: Bitbucket filter PRs sớm (rẻ, nhanh) → Codemagic build/deploy (đắt, chậm, chỉ khi code đã pass quality gate).
</details>

---

## 4. FE Perspective Mapping

| Flutter | FE Equivalent |
|---------|---------------|
| Lefthook | Husky + lint-staged |
| super_lint | ESLint custom plugins |
| Bitbucket Pipelines | GitHub Actions / GitLab CI |
| Codemagic | Vercel / Netlify (nhưng cho mobile) |
| `dart_defines/*.json` | `.env.*` files |
| `make check_ci` | `npm run lint && npm test && npm run build` |

---

## 5. Backward Reference Check

- [ ] M18: `make te` + `make cov` trong pipeline = automated testing từ M18
- [ ] M7: BaseViewModel patterns được lint check bởi super_lint rules
- [ ] M12: API layer structure enforced bởi naming conventions trong CI

## 6. Forward Reference

Đây là **module core cuối cùng**. M0–M19 complete. → **Capstone Project** hoặc **Optional Modules** (A: Platform Channels, B: Push/Deeplink, C: Isolates).

---

## ✅ Module Complete

Hoàn thành khi:

- [ ] Self-assessment: ≥ 7/9 Yes (4/4 🔴 bắt buộc)
- [ ] Exercise 1 + 2 hoàn thành
- [ ] Quick Quiz trả lời đúng ≥ 3/5

---

## 🎓 Course Complete — Congratulations!

🎉 **Chúc mừng bạn đã hoàn thành Flutter Training Program!**

### Nhìn lại hành trình

Qua 20 modules, bạn đã đi qua full-stack Flutter development:

| Giai đoạn | Modules | Skills |
|-----------|---------|--------|
| **Foundation** | M00-M02 | Dart, project structure, barrel files |
| **Architecture** | M03-M06 | Common layer, exception handling, navigation, theming |
| **State & UI** | M07-M10 | ViewModel, Riverpod, page structure, hooks |
| **Data & API** | M11-M14 | i18n, API integration, error handling, local storage |
| **Production** | M15-M19 | Login flow, UI patterns, performance, testing, CI/CD |

### Tiếp theo

- 🔧 **Optional Modules**: Platform Channels, Push/Deeplink, Isolates
- 📝 **Capstone Project**: Áp dụng tất cả vào dự án thực tế
- 🚀 **Real Project**: Bạn đã sẵn sàng contribute vào production codebase

> 💪 *"The best way to learn is to build. The best way to grow is to ship."*

---

## ➡️ Next Steps

🎉 Hoàn thành Module 19 — bạn đã hoàn tất toàn bộ core curriculum!

→ Tiếp tục với **Optional Modules**:
- **[Module A — Platform Channels](../module-optional-A-platform-channels/)** — giao tiếp Flutter ↔ Native (iOS/Android)
- **[Module B — Push & Deep Link](../module-optional-B-push-deeplink/)** — push notifications, deep linking
- **[Module C — Isolates](../module-optional-C-isolates/)** — background processing, concurrency

→ Hoặc bắt đầu **[Capstone Project](../capstone/capstone-spec.md)** để tổng hợp toàn bộ kiến thức.

<!-- AI_VERIFY: generation-complete -->
