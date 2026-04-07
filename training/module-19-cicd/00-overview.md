# Module 19 – CI/CD, Lint & Production Readiness

## Tổng quan

Module này survey toàn bộ CI/CD infrastructure của dự án Flutter — từ pre-commit hooks, custom lint enforcement, PR quality gates, đến Codemagic build/deploy pipeline cho 4 environments. Đây là **module core cuối cùng** và bao gồm CAPSTONE exercise tổng hợp kiến thức M0–M19.

**Depth**: Advanced Survey — đọc hiểu pipeline configs, trace build/deploy flow, không setup CI từ đầu.

---

## Bạn sẽ học

1. **CI/CD Pipeline Architecture** — 3 tầng: local hooks → PR gate → deployment
2. **PR Quality Gate** — 8-step `make check_ci` trong Bitbucket Pipelines + Codemagic CI
3. **Pre-commit Hooks** — Lefthook: format check, commit message validation
4. **Custom Lint Rules** — super_lint package: 30+ project-specific rules via `custom_lint_builder`
5. **Build Variants** — 4 environments (develop/qa/staging/production), dart_defines, build number management
6. **Production Readiness** — Code signing, store deployment, Crashlytics, caching strategy

**Phân bố:** 🔴 ~33% · 🟡 ~67% · 🟢 0%

---

## Kiến thức cần có

| Module | Nội dung | Vai trò trong M19 |
|--------|----------|-------------------|
| **M0** | pubspec.yaml, makefile | Makefile orchestrates mọi CI commands |
| **M3** | Config, env files | dart_defines, environment switching |
| **M18** | Testing infrastructure | Tests chạy trong CI pipeline (`make te`) |

---

## Cấu trúc files

| File | Nội dung | Thời gian |
|------|----------|-----------|
| [01-code-walk.md](./01-code-walk.md) | Walk-through: lefthook, super_lint, pipelines, codemagic | 35 min |
| [02-concept.md](./02-concept.md) | 6 concepts: pipeline, PR gate, hooks, lint, variants, production | 25 min |
| [03-exercise.md](./03-exercise.md) | 4 exercises: ⭐ trace CI → ⭐⭐ lint rule → ⭐⭐ new env → ⭐⭐⭐ CAPSTONE | 120 min |
| [04-verify.md](./04-verify.md) | Verification checklist | 10 min |

---

## 💡 FE Perspective

| Flutter | FE Equivalent |
|---------|---------------|
| Lefthook (pre-commit hooks) | Husky + lint-staged |
| super_lint (custom_lint_builder) | ESLint custom plugins |
| `analysis_options.yaml` | `.eslintrc.js` + `prettier.config.js` |
| Bitbucket Pipelines | GitHub Actions / GitLab CI |
| Codemagic (build + deploy) | Vercel / Netlify (deploy) |
| `dart_defines/*.json` | `.env.*` files (Next.js / Vite) |
| Fastlane (store deploy) | N/A (web has no app store) |
| `make check_ci` | `npm run lint && npm test && npm run build` |

---

## Key Files

```
lefthook.yml                 ← Git hooks (pre-commit, commit-msg)
bitbucket-pipelines.yml      ← PR pipeline (make check_ci)
codemagic.yaml               ← CI/CD (542L, 9 workflows)
makefile                     ← Orchestration (check_ci, lint, te...)
analysis_options.yaml        ← Analyzer + custom_lint config
dart_defines/*.json          ← Compile-time config per env
super_lint/                  ← 30+ custom lint rules
android/fastlane/ + ios/fastlane/  ← Store deployment
```

---

## Forward Reference

→ **Capstone Project**: Áp dụng full CI/CD process cho capstone implementation.
→ **Optional Modules**: Platform Channels (A), Push/Deeplink (B), Isolates (C).

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Mô tả `lefthook.yml` pre-commit hook flow — commands nào chạy trước khi commit?
2. Giải thích `bitbucket-pipelines.yml` PR pipeline — `make check_ci` chạy những gì?
3. Phân biệt 4 environment files trong `dart_defines/` — develop vs staging vs QA vs production?
4. Configure được `codemagic.yaml` workflow mới cho branch deployment?
5. Giải thích `super_lint/` custom rules — tại sao cần project-specific lint ngoài `analysis_options.yaml`?

→ Nếu **5/5 Yes** — chuyển thẳng [Optional Modules](../module-optional-A-platform-channels/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

## Unlocks (Post-M19)

Sau khi hoàn thành Module 19, bạn sẽ:

- **Capstone Project:** CI/CD pipeline sẵn sàng — PR checks, pre-commit hooks, và deployment workflows đã hiểu.
- **Optional Modules:** Platform Channels (A), Push/Deeplink (B), Isolates (C) — independent modules, chọn theo nhu cầu dự án.

<!-- AI_VERIFY: generation-complete -->
