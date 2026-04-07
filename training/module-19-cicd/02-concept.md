# Module 19 – Concepts: CI/CD, Lint & Production Readiness

> **Mục tiêu**: Nắm vững 6 concepts cốt lõi của CI/CD pipeline — từ kiến trúc tổng thể, quality gates, đến production deployment và monitoring.

📌 **Recap**: M0 (pubspec.yaml, makefile) · M3 (Config, env files) · M18 (testing infrastructure)

---

## Concept 1: CI/CD Pipeline Architecture 🟡 SHOULD-KNOW

**WHY:** Pipeline architecture thay đổi theo project, cần hiểu flow tổng quát để adapt.

<!-- AI_VERIFY: concept-1 -->

### Định nghĩa

**CI (Continuous Integration)**: Tự động verify code quality mỗi khi có thay đổi — lint, test, format check.  
**CD (Continuous Delivery/Deployment)**: Tự động build và deploy app lên distribution channels.

### Kiến trúc 3 tầng

| Tầng | Tool | Speed | Trigger |
|------|------|-------|---------|
| LOCAL | lefthook (pre-commit) | Seconds | `git commit` |
| PR GATE | Bitbucket + Codemagic CI | Minutes | PR created |
| DEPLOYMENT | Codemagic workflows | 30-60min | Manual/merge |

### Pipeline Tool Choices

| Concern | Tool | Lý do |
|---------|------|-------|
| Git hooks | Lefthook | YAML, parallel, cross-platform |
| PR CI | Bitbucket Pipelines | VCS integration, Docker-based |
| Build/Deploy | Codemagic | Flutter-native, macOS runners, code signing |

> 💡 **FE Perspective**
> **Flutter:** 3 tầng: Lefthook (local) → Bitbucket + Codemagic (PR) → Codemagic workflows (deploy).
> **React/Vue tương đương:** Husky (local) → GitHub Actions (PR) → Vercel (deploy).
> **Khác biệt quan trọng:** Mobile thêm: code signing + dual platform builds (iOS + Android). Web chỉ cần 1 build output.

---

## Concept 2: PR Pipeline — Quality Gate 🟡 SHOULD-KNOW

**WHY:** PR quality gate là standard process, cần hiểu để configure nhưng template có sẵn.

<!-- AI_VERIFY: concept-2 -->

### Nguyên tắc

PR pipeline là **gateway bắt buộc** — không pass = không merge. Đảm bảo mọi code vào `main`/`develop` đều đạt tiêu chuẩn.

### 8-step Gate (`make check_ci`)

| # | Target | Fail nếu... |
|---|--------|-------------|
| 1-3 | `check_pubs`, `check_page_routes`, `check_assets_structure` | Convention violations |
| 4-5 | `ep`, `rup` | Missing exports, unused packages |
| 6 | `fm` | Unformatted code |
| 7 | `te` | Test failure |
| 8 | `lint` | Lint violation |

### Dual CI

Bitbucket Pipeline (Linux, fast, cheap) + Codemagic CI (macOS, iOS-specific, golden tests). Codemagic skips draft PRs via `when: condition: not event.pull_request.draft`.

> 💡 **FE Perspective**
> **Flutter:** 8-step `make check_ci` fail-fast gate. Dual CI: Bitbucket (Linux, fast) + Codemagic (macOS, golden tests).
> **React/Vue tương đương:** GitHub Actions (`lint + test`) + Vercel Preview (`build`) cho mỗi PR.
> **Khác biệt quan trọng:** Flutter cần macOS runner cho iOS golden tests. Web CI chỉ cần Linux.

---

## Concept 3: Pre-commit Hooks — Local Quality Gate 🔴 MUST-KNOW

**WHY:** Pre-commit hooks chạy mỗi commit — phải hiểu để troubleshoot khi hook fail.

<!-- AI_VERIFY: concept-3 -->

### Hook Lifecycle

```
git commit -m "feat: add login"
  ├── pre-commit → pre-commit.sh (format staged files, exit 1 → cancel)
  ├── commit-msg → commit-msg.sh (validate convention, exit 1 → cancel)
  └── Commit ✅
```

### Lefthook vs Husky

| Feature | Lefthook | Husky (JS) |
|---------|----------|------------|
| Config | YAML | JS/JSON |
| Runtime | Go binary (fast) | Node.js |
| Parallel | Built-in | Manual |

> 💡 **FE Perspective**
> **Flutter:** Lefthook (Go binary, YAML, parallel) chạy pre-commit + commit-msg hooks.
> **React/Vue tương đương:** Husky + lint-staged. Commitlint + Conventional Commits.
> **Khác biệt quan trọng:** Lefthook là Go binary (nhanh, không cần Node.js). Husky cần Node.js runtime.

### Local CI Checks — Chạy trước khi push

Ngoài pre-commit hooks (tự động), developer nên chạy **manual checks** trước khi push code:

```bash
# 3 lệnh kiểm tra cơ bản trước khi push
flutter analyze                      # Static analysis — lint errors, warnings
flutter test                          # Unit + widget tests — regression check
dart format --set-exit-if-changed .   # Format check — CI sẽ fail nếu unformatted
```

**Tại sao chạy local trước khi push?**
- CI pipeline mất **5-15 phút** → feedback chậm
- 3 lệnh trên chạy **< 2 phút** locally → catch 90% issues sớm
- Tránh "fix lint" commits gây noise trong git history

> **Tip:** Thêm alias vào shell profile: `alias fpush="flutter analyze && flutter test && dart format --set-exit-if-changed . && git push"` → one-command pre-push check.

---

## Concept 4: Custom Lint Rules — Project-specific Enforcement 🟡 SHOULD-KNOW

**WHY:** Custom lint rules là project-specific config, cần biết cách thêm rule nhưng structure có sẵn.

<!-- AI_VERIFY: concept-4 -->

### Tại sao cần Custom Lint?

`flutter_lints` cover chung, nhưng project-specific conventions cần custom rules:

| Rule | Giải quyết |
|------|-----------|
| `AvoidHardCodedColors` | Buộc dùng `cl.xxx` |
| `MissingGoldenTest` | Widget mới phải có golden test |
| `TestFolderMustMirrorLibFolder` | `test/` mirror `lib/` |
| `PreferNamedParameters` | >2 params → named |

### Architecture

`analysis_options.yaml` → Dart Analyzer + `custom_lint` plugin → `super_lint` (30+ rules). Mỗi rule là AST visitor via `custom_lint_builder`.

Toggle: `make tcl force=true` — CI luôn enable, developer có thể disable locally.

> 💡 **FE Perspective**
> **Flutter:** `custom_lint` + `super_lint` (30+ rules) dùng AST visitor via `custom_lint_builder`.
> **React/Vue tương đương:** ESLint custom plugins (`eslint-plugin-*`). `@typescript-eslint/utils` cho AST visitor.
> **Khác biệt quan trọng:** Flutter lint là Dart package, cùng ngôn ngữ. ESLint plugin dùng JS/TS để lint JS/TS code.

---

## Concept 5: Build Variants — 4 Environments 🔴 MUST-KNOW

**WHY:** 4 environments ảnh hưởng daily development — phải biết switch environment khi dev/test.

<!-- AI_VERIFY: concept-5 -->

### Environment Matrix

| Env | Mục đích | Deploy |
|-----|----------|--------|
| `develop` | Dev daily | Internal testing |
| `qa` | QA testing | QA team |
| `staging` | Pre-release | Stakeholders |
| `production` | Release | App Store / Play Store |

### dart_defines & Secrets

`dart_defines/develop.json` → `{ "FLAVOR": "develop" }`. Build: `flutter build --dart-define-from-file=dart_defines/develop.json`.

**CI flow**: local JSON → `base64 -i file | pbcopy` → Codemagic env var → CI `base64 --decode`.

### Build Number

iOS: `app-store-connect get-latest-testflight-build-number` → +1. Android: `google-play get-latest-build-number` → +1.

> 💡 **FE Perspective**
> **Flutter:** 4 environments với `dart_defines/*.json`. Build: `flutter build --dart-define-from-file=dart_defines/develop.json`.
> **React/Vue tương đương:** `.env.development`, `.env.production` trong Next.js/Vite.
> **Khác biệt quan trọng:** Mobile thêm: build number management cho store submissions + code signing per environment.

---

## Concept 6: Production Readiness — Deployment & Beyond 🟡 SHOULD-KNOW

**WHY:** Codemagic pipeline là essential tool cho project — cần hiểu deployment flow, signing, và distribution channels để troubleshoot CI/CD issues.

<!-- AI_VERIFY: concept-6 -->

### Deployment Flow

Code → CI pass → PR merge → Codemagic workflow → Build .ipa/.aab → TestFlight + Google Play → Crashlytics symbols.

### Production Readiness Checklist

| Category | Item |
|----------|------|
| Code Quality | All lint rules pass (`make lint`) |
| Testing | Unit + Widget + Golden pass (`make te`) |
| Security | Secrets only via env vars (Codemagic groups) |
| Config | dart_defines correct per env |
| Signing | iOS profiles + certs, Android keystore |
| Versioning | Build number auto-increment from store APIs |
| Monitoring | Crashlytics dSYM upload (production) |
| Distribution | TestFlight beta_groups + Google Play internal track |

> 💡 **FE Perspective**
> **Flutter:** Codemagic workflow: build .ipa/.aab → TestFlight + Google Play. Crashlytics dSYM upload.
> **React/Vue tương đương:** Vercel production deploy + npm publish. Sentry source maps upload.
> **Khác biệt quan trọng:** Mobile thêm Apple/Google review process, code signing, dual platform. Web deploy instant.

---

## Tổng kết Concepts

| # | Concept | Core Idea | Key File |
|---|---------|-----------|----------|
| 1 | Pipeline Architecture | 3-tầng: local → PR → deploy | All configs |
| 2 | PR Quality Gate | 8-step fail-fast check | `bitbucket-pipelines.yml` |
| 3 | Pre-commit Hooks | Local gate trước commit | `lefthook.yml` |
| 4 | Custom Lint | 30+ project-specific rules | `super_lint/`, `analysis_options.yaml` |
| 5 | Build Variants | 4 envs × dart_defines | `codemagic.yaml`, `dart_defines/` |
| 6 | Production Readiness | Deploy + monitor + signing | `codemagic.yaml` publishing |

→ **Next**: [03-exercise.md](./03-exercise.md) — thực hành: trace CI, add lint rule, new env, CAPSTONE.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
