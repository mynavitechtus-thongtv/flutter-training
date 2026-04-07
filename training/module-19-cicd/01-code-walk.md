# Module 19 – Code Walk: CI/CD, Lint & Production Readiness

> **Mục tiêu**: Đọc hiểu toàn bộ CI/CD infrastructure của dự án — từ pre-commit hooks, custom lint, PR pipeline, đến Codemagic build/deploy pipeline cho 4 environments.

📌 **Recap**: M0 (pubspec.yaml, makefile — project tooling) · M3 (Config, env files — dart_defines) · M18 (testing infrastructure — `make te`, `make check_ci`)

---

## 1. Tổng quan CI/CD Flow — Bức tranh toàn cảnh

<!-- AI_VERIFY: section-cicd-overview -->

```
Developer Workflow:
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────────────┐
│  Code + Git  │────▶│ lefthook     │────▶│ Bitbucket PR    │────▶│ Codemagic Build  │
│  (local)     │     │ (pre-commit) │     │ Pipeline (CI)   │     │ (CD → Stores)    │
└─────────────┘     └──────────────┘     └─────────────────┘     └──────────────────┘
      ▲                    │                     │                        │
      │              format + msg          lint + test              build + deploy
      │              validation            gate                    4 environments
      └──────────────────────────────────────────────────────────────────┘
                              Feedback loop
```
<!-- END_VERIFY -->

> 💡 **FE Perspective**
> **Flutter:** CI/CD flow: Lefthook (pre-commit) → Bitbucket Pipeline (PR) → Codemagic (build/deploy).
> **React/Vue tương đương:** Husky (pre-commit) → GitHub Actions / GitLab CI (PR check) → Vercel/Netlify (deploy).
> **Khác biệt quan trọng:** Mobile cần code signing + build cho cả iOS và Android. Web chỉ cần 1 build target.

---

## 2. lefthook.yml — Pre-commit Hooks

📂 `../../base_flutter/lefthook.yml`

```yaml
pre-commit:
  parallel: true
  scripts:
    "pre-commit.sh":
      runner: bash

commit-msg:
  scripts:
    "commit-msg.sh":
      runner: bash
```

| Hook | Trigger | Mục đích |
|------|---------|----------|
| `pre-commit` | Trước `git commit` | Validate branch naming convention |
| `commit-msg` | Sau nhập message | Validate commit message convention |
| `pre-push` (disabled) | Trước `git push` | `make lint` (quá chậm local) |

**Actual hook scripts** (`.lefthook/`):

```bash
# .lefthook/pre-commit/pre-commit.sh — Branch naming convention
local_branch="$(git rev-parse --abbrev-ref HEAD)"
valid_branch_regex='^(feature|bugfix|improvement|release|hotfix)\/NFT-[0-9]+_.*$'
# Ví dụ hợp lệ: feature/NFT-2_some_text
if [[ ! $local_branch =~ $valid_branch_regex ]]; then
    echo "$local_branch is bad branch name"; exit 1
fi
```

```bash
# .lefthook/commit-msg/commit-msg.sh — Commit message convention
commit_regex='^\[NFT-\d+\] .*$'
# Ví dụ hợp lệ: "[NFT-2] some text"
if ! grep -iqE "$commit_regex" "$1"; then
    echo "Bad commit message" >&2; exit 1
fi
```

> 💡 **FE Perspective**
> **Flutter:** Lefthook: YAML config, Go binary, parallel hooks. Pre-commit + commit-msg.
> **React/Vue tương đương:** Husky + lint-staged. Commitlint cho commit message validation.
> **Khác biệt quan trọng:** Lefthook không cần Node.js runtime. Husky phụ thuộc Node.js ecosystem.

---

## 3. super_lint/ — Custom Lint Package

<!-- AI_VERIFY: section-super-lint -->

📂 `../../base_flutter/super_lint/`

### 3.1 Structure & Entry Point

```
super_lint/
├── pubspec.yaml          ← Standalone (publish_to: "none"), custom_lint_builder
├── lib/
│   ├── super_lint.dart   ← Plugin entry: register 30 rules
│   └── src/
│       ├── base/         ← CommonLintRule base class
│       ├── lints/        ← 30 rule files
│       ├── utils/        ← Helpers
│       └── visitor/      ← AST visitors
```

```dart
class _SuperLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      AvoidHardCodedColors(configs),
      PreferNamedParameters(configs),
      MissingGoldenTest(configs),
      TestFolderMustMirrorLibFolder(configs),
      // ... 30 rules
    ];
  }
}
```

### 3.3 30 Lint Rules — 6 Categories

| Category | Ví dụ Rules | Mục đích |
|----------|-------------|----------|
| **Code Quality** | `AvoidDynamic`, `PreferAsyncAwait` | Type safety |
| **Naming** | `RequireMatchingFileAndClassName`, `PreferNamedParameters` | Convention |
| **UI** | `AvoidHardCodedColors`, `PreferCommonWidgets` | Consistent UI |
| **Architecture** | `IncorrectParentClass`, `PreferImportingIndexFile` | Layer discipline |
| **Testing** | `MissingGoldenTest`, `TestFolderMustMirrorLibFolder` | Coverage enforcement |
| **Analytics** | `IncorrectScreenNameParameterValue`, `IncorrectEventName` | Tracking correctness |

### 3.4 Rule Pattern

Mỗi rule: extend `CommonLintRule` → `RuleConfig(name, problemMessage)` → override `check()` → AST visitor → `reporter.atNode()`.

> 💡 **FE Perspective**
> **Flutter:** `custom_lint_builder` dùng AST visitor pattern — mỗi rule extend `CommonLintRule` với `check()` method.
> **React/Vue tương đương:** ESLint custom rules — cùng AST visitor pattern. `@typescript-eslint/utils` cho typed AST.
> **Khác biệt quan trọng:** Flutter lint là standalone Dart package. ESLint rules là JS modules trong plugin.

### 3.5 Configuration

📂 `../../base_flutter/analysis_options.yaml` — `custom_lint:` section configures rules with params + excludes.

**Makefile**: `make tcl force=true` (toggle on for CI) · `make lint` (super_lint + flutter analyze).

---

## 4. bitbucket-pipelines.yml — PR Pipeline

<!-- AI_VERIFY: section-pr-pipeline -->

📂 `../../base_flutter/bitbucket-pipelines.yml`

```yaml
image: ghcr.io/cirruslabs/flutter:3.38.7

definitions:
  steps:
    - step: &running-ci
        name: CI.
        script:
          - flutter doctor -v
          - make tcl force=true        # ← Enable custom lint
          - make sync                  # ← pub get + codegen + l10n
          - make check_ci              # ← Full CI check

pipelines:
  pull-requests:
    '**':                              # ← Mọi PR đều trigger
      - step: *running-ci
```

### Pipeline Flow — `make check_ci` breakdown

| # | Target | Kiểm tra |
|---|--------|----------|
| 1 | `check_pubs` | Pubspec validation |
| 2 | `check_page_routes` | Route registration |
| 3 | `check_assets_structure` | Asset conventions |
| 4 | `ep` | Barrel file exports |
| 5 | `rup` | Unused packages |
| 6 | `fm` | `dart format --set-exit-if-changed -l 100` |
| 7 | `te` | Unit + Widget tests |
| 8 | `lint` | super_lint + flutter analyze |

> 💡 **FE Perspective**
> **Flutter:** `make check_ci` = 8-step fail-fast gate. `bitbucket-pipelines.yml` dùng YAML anchors cho DRY.
> **React/Vue tương đương:** `npm ci && npm run lint && npm test && npm run build`. YAML anchors ≈ reusable workflows.
> **Khác biệt quan trọng:** Flutter cần `make sync` (pub get + codegen + l10n) trước khi test. Web chỉ cần `npm ci`.

---

## 5. codemagic.yaml — CI/CD Pipeline & Deployment

<!-- AI_VERIFY: section-codemagic -->

📂 `../../base_flutter/codemagic.yaml` (542 lines)

### 5.1 Definitions — Shared Configuration

```yaml
definitions:
  instance_mac_os: &instance_mac_os
    instance_type: mac_mini_m1         # ← Apple Silicon
    max_build_duration: 60             # ← 60 minutes timeout
    cache:
      cache_paths:
        - $HOME/.gradle/caches         # ← Android build cache
        - $HOME/.pub-cache             # ← Dart packages
        - $HOME/Library/Caches/CocoaPods  # ← iOS pods

  env_config: &env_config
    flutter: 3.38.7
    java: 21
    xcode: 16.0
    cocoapods: 1.16.2
    vars:
      JAVA_TOOL_OPTIONS: "-Xmx5g"     # ← JVM heap size cho Android build
    groups:
      - secrets                         # ← Codemagic encrypted env vars
      - emails
```

### 5.2 YAML Anchors — DRY

~25 anchor definitions dùng `&name` / `*name`: sync, lint, build (ipa/apk/aab × 4 envs), decode configs, code signing, build numbers.

```yaml
scripts:
  - &sync
    name: Run pub get and gen files
    script: make sync
# → Reuse: *sync trong mọi workflow
```

### 5.3 Build Number & Secrets

**Build number**: Query store API → +1 → `dart run tools/dart_tools/lib/set_build_number_pubspec.dart`.
- iOS: `app-store-connect get-latest-testflight-build-number`
- Android: `google-play get-latest-build-number` (fallback: `$BUILD_NUMBER`)

**dart_defines**: Local JSON → base64 encode → Codemagic env var → CI decode lại.

```yaml
- &decode_dart_defines
  script: |
    echo $DART_DEFINES_DEVELOP | base64 --decode > dart_defines/develop.json
```

### 5.4 Workflows — 9 Total

| Workflow | Environment | Output | Deploy Target |
|----------|-------------|--------|---------------|
| `adhoc_develop` | develop | .ipa + .apk | Email distribution |
| `adhoc_qa` | qa | .ipa + .apk | Email distribution |
| `adhoc_staging` | staging | .ipa + .apk | Email distribution |
| `adhoc_production` | production | .ipa + .apk | Email distribution |
| `distribution_store_develop` | develop | .ipa + .aab | TestFlight + Google Play Internal |
| `distribution_store_qa` | qa | .ipa + .aab | TestFlight + Google Play Internal |
| `distribution_store_staging` | staging | .ipa + .aab | TestFlight + Google Play Internal |
| `distribution_store_production` | production | .ipa + .aab | TestFlight + GP Internal + Crashlytics |
| `ci` | — | test results | PR gate (auto-trigger) |

### 5.5 Distribution Workflow Anatomy

Key sections của `distribution_store_develop`:

```yaml
<<: *instance_mac_os          # Mac Mini M1, 60min, cache
environment:
  <<: *env_config             # Flutter 3.38.7, Java 21, Xcode 16.0
  android_signing: [android_keystore]
  ios_signing:
    provisioning_profiles: [ios_develop_distribution_profile]
    certificates: [ios_p12]
scripts:
  - *setup... → *sync → *build_dev_ipa → *build_dev_aab
publishing:
  google_play: { track: internal, submit_as_draft: true }
  app_store_connect: { submit_to_testflight: true, beta_groups: ["testers"] }
```

### 5.6 CI Workflow — Auto-trigger

```yaml
ci:
  triggering: { events: [pull_request], branch_patterns: [{ pattern: "*" }] }
  when:
    condition: not event.pull_request.draft   # Skip drafts
  artifacts: [test/widget_test/**/failures/**/*.png]  # Golden failures
```

Dual CI: Bitbucket Pipeline (Linux, fast) + Codemagic CI (macOS) chạy song song.

---

## 6. Fastlane & Makefile Orchestration

<!-- AI_VERIFY: section-fastlane -->

**Fastlane** (`android/fastlane/` + `ios/fastlane/`): Code signing, build .ipa/.aab, store upload. Codemagic gọi via `make build_*`.

> Fastlane là automation tool cho mobile deployment. Trong `base_flutter`, Fastlane configs nằm ở `ios/fastlane/` và `android/fastlane/`. Chúng automate: build → sign → upload to TestFlight/Play Console. `Fastfile` chứa lanes (CI/CD steps), `Appfile` chứa app identifiers. Xem `ios/fastlane/Fastfile` để hiểu flow.

**Makefile** — orchestration layer, CI-relevant targets:

| Group | Targets | Mục đích |
|-------|---------|----------|
| Quality gate | `check_ci`, `ci` | Fail-fast vs report-all |
| Lint | `lint`, `sl`, `analyze`, `tcl` | Custom lint + flutter analyze |
| Test | `te`, `ut`, `wt`, `ug` | Unit, widget, golden |
| Format | `fm` | `dart format -l 100` |
| Code checks | `check_pubs`, `ep`, `rup` | Convention enforcement |
| Build | `sync`, `ref` | Pub get + codegen |

> Makefile = orchestration layer — local dev và CI chạy cùng logic.

---

## 7. Tổng kết

```
LOCAL                        REMOTE
git commit                   
  ├─ lefthook pre-commit     
  ├─ lefthook commit-msg     
git push ──────────────────▶ Bitbucket Pipeline (make check_ci)
                             Codemagic CI (auto, skip drafts)
PR merge ──────────────────▶ Codemagic Workflow → TestFlight + Google Play
```

| Area | Tool | Config |
|------|------|--------|
| Pre-commit | Lefthook | `lefthook.yml` |
| Custom lint | super_lint | `analysis_options.yaml` |
| PR pipeline | Bitbucket | `bitbucket-pipelines.yml` |
| CI/CD | Codemagic | `codemagic.yaml` |
| Deploy | Fastlane | `android/fastlane/`, `ios/fastlane/` |
| Orchestration | Make | `makefile` |
| Env config | dart_defines | `dart_defines/*.json` |

→ **Next**: [02-concept.md](./02-concept.md) — deep-dive 6 concepts: pipeline architecture, PR gate, hooks, lint, build variants, production readiness.

<!-- AI_VERIFY: generation-complete -->
