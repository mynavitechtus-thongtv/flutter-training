# Code Walk — Đọc hiểu Project Config trước khi viết code

## pubspec.yaml — Trung tâm khai báo project

<!-- AI_VERIFY: base_flutter/pubspec.yaml#L1-L7 -->
```yaml
name: nalsflutter
description: A new Flutter project.
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/pubspec.yaml)

> 🔎 **Quan sát**
> - `publish_to: "none"` — project này là app, không phải library publish lên pub.dev
> - `version: 1.0.0+1` — format `major.minor.patch+buildNumber`, build number dùng cho store upload
> - **Hỏi:** SDK constraint `>=3.3.0 <4.0.0` nghĩa là gì? Tại sao giới hạn `<4.0.0`?

> 💡 **FE Perspective**
> **Flutter:** `pubspec.yaml` khai báo tên, version, SDK constraint cho project.
> **React/Vue tương đương:** `package.json` trong Node.js — `name`, `version`, `engines.node`.
> **Khác biệt quan trọng:** `pubspec.yaml` dùng YAML format và quản lý cả assets/fonts, `package.json` dùng JSON và không quản lý assets.

### dependencies vs dev_dependencies

<!-- AI_VERIFY: base_flutter/pubspec.yaml#L9-L59 [EXCERPT — 8 of ~50 dependencies shown] -->
```yaml
dependencies:
  auto_route: 10.3.0          # navigation
  dio: 5.8.0+1                # HTTP client
  hooks_riverpod: 2.6.1       # state management
  freezed_annotation: 3.1.0   # immutable models
  json_annotation: 4.9.0      # JSON serialization
  injectable: 2.5.1           # dependency injection
  flutter:
    sdk: flutter
  slang: 4.12.1               # i18n / localization
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/pubspec.yaml)

> 🔎 **Quan sát**
> - Version pinning chính xác (`10.3.0`), không dùng `^` — lock version tránh breaking change
> - `flutter: sdk: flutter` — dependency đặc biệt, trỏ vào Flutter SDK thay vì pub.dev
> - **Hỏi:** Tại sao `dio` version `5.8.0+1` có dấu `+1`? Khác gì so với `5.8.1`?

> 💡 **FE Perspective**
> **Flutter:** `dependencies` (runtime) và `dev_dependencies` (build/test only), version pinning chính xác (`10.3.0`).
> **React/Vue tương đương:** `dependencies` và `devDependencies` trong `package.json`.
> **Khác biệt quan trọng:** Dart lock chính xác version (không dùng `^`/`~` range), giống `npm install --save-exact`.

<!-- AI_VERIFY: base_flutter/pubspec.yaml#L60-L82 -->
```yaml
dev_dependencies:
  auto_route_generator: 10.2.6   # gen route code
  build_runner: 2.7.0            # codegen engine
  freezed: 3.2.3                 # gen immutable classes
  json_serializable: 6.11.1      # gen fromJson/toJson
  injectable_generator: 2.8.1    # gen DI config
  mocktail: 1.0.4                # test mocking
  flutter_test:
    sdk: flutter
  super_lint:
    path: super_lint              # local package
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/pubspec.yaml)

> 🔎 **Quan sát**
> - Nhiều package kết thúc bằng `_generator` — đây là code generators chạy lúc build, không ship vào app
> - `super_lint: path: super_lint` — reference đến local package trong repo, không phải từ pub.dev
> - **Hỏi:** `build_runner` là gì? Tại sao cần riêng một engine cho codegen?

### Flutter assets & fonts

<!-- AI_VERIFY: base_flutter/pubspec.yaml#L83-L111 -->
```yaml
flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/images/
  fonts:
    - family: Cupertino
      fonts:
        - asset: assets/fonts/Cupertino/CupertinoIcons.ttf
    - family: Noto_Sans_JP
      fonts:
        - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-Thin.ttf
          weight: 100
        - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-ExtraLight.ttf
          weight: 200
        - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-Light.ttf
          weight: 300
        - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-Regular.ttf
          weight: 400
        - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-Medium.ttf
          weight: 500
        - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-Bold.ttf
          weight: 700
        - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-ExtraBold.ttf
          weight: 800
        - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-Black.ttf
          weight: 900
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/pubspec.yaml)

> 🔎 **Quan sát**
> - `generate: true` — bật Flutter codegen (auto-gen localization classes)
> - `Cupertino` font family — cung cấp iOS-style icons (CupertinoIcons) cho platform-native UI
> - 9 font weights (100-900) cho `Noto_Sans_JP` — đầy đủ từ Thin đến Black, linh hoạt cho typography
> - Font khai báo với `weight` cụ thể — Flutter map `FontWeight.w400` → file `.ttf` tương ứng
> - **Hỏi:** Nếu quên khai báo `assets/images/` ở đây, điều gì xảy ra khi load ảnh trong code?

---

## makefile — Automation shortcuts

<!-- AI_VERIFY: base_flutter/makefile#L3-L6 -->
```makefile
pg:
	flutter pub get
	cd super_lint && flutter pub get
	cd super_lint/example && flutter pub get
```
<!-- END_VERIFY -->

<!-- AI_VERIFY: base_flutter/makefile#L20-L28 -->
```makefile
fb:
	dart run build_runner build --delete-conflicting-outputs

cc:
	dart run build_runner clean

ccfb:
	make cc
	make fb
```
<!-- END_VERIFY -->

<!-- AI_VERIFY: base_flutter/makefile#L35-L39 -->
```makefile
sync:
	make pg
	make ln
	make cc
	make fb
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/makefile)

> 🔎 **Quan sát**
> - `make pg` = **p**ub **g**et — cài dependencies (tương đương `npm install`)
> - `make fb` = **f**reezed + **b**uild — chạy code generation cho models, routes, DI
> - `make sync` = combo: cài deps → gen localization → clean → build codegen. **Đây là lệnh chạy đầu tiên** khi clone project
> - **Hỏi:** Tại sao `sync` phải chạy `cc` (clean) trước `fb` (build)?

> 💡 **FE Perspective**
> **Flutter:** `make sync` = pub get + localization gen + codegen — workflow đầy đủ khi clone project.
> **React/Vue tương đương:** `npm install && npm run build`.
> **Khác biệt quan trọng:** Flutter project cần bước codegen (tạo file `.g.dart`, `.freezed.dart`) mà JS/TS không có.

### Format, test & lint

<!-- AI_VERIFY: base_flutter/makefile#L144-L150 -->
```makefile
fm:
	@if [ "$(skip_error)" = "true" ]; then \
		find . -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" ! -name "*.gr.dart" ! -name "*.config.dart" ! -name "*.mocks.dart" ! -path '*/generated/*' ! -path '*/.dart_tool/*' | tr '\n' ' ' | xargs dart format -l 100; \
	else \
		find . -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" ! -name "*.gr.dart" ! -name "*.config.dart" ! -name "*.mocks.dart" ! -path '*/generated/*' ! -path '*/.dart_tool/*' | tr '\n' ' ' | xargs dart format --set-exit-if-changed -l 100; \
	fi
	make sort_arb
```
<!-- END_VERIFY -->

<!-- AI_VERIFY: base_flutter/makefile#L160-L176 -->
```makefile
ut:
	@if [ "$(skip_error)" = "true" ]; then \
		flutter test test/unit_test || true; \
	else \
		flutter test test/unit_test; \
	fi

wt:
	@if [ "$(skip_error)" = "true" ]; then \
		flutter test test/widget_test || true; \
	else \
		flutter test test/widget_test; \
	fi

lint:
	make sl skip_error=$(skip_error)
	make analyze skip_error=$(skip_error)
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/makefile)

> 🔎 **Quan sát**
> - `fm` exclude tất cả file generated (`*.g.dart`, `*.freezed.dart`) — **không bao giờ format generated code**
> - Line length limit: `-l 100` (100 ký tự/dòng)
> - Test tách 2 folder: `unit_test` và `widget_test` — chạy riêng cho CI nhanh hơn
> - **Hỏi:** `--set-exit-if-changed` có nghĩa gì? Tại sao CI cần flag này?

> 💡 **FE Perspective**
> **Flutter:** `make fm` (format), `make lint` (analyse), `make ut` (unit test) — formatter built-in trong Dart SDK.
> **React/Vue tương đương:** `prettier --check`, `eslint .`, `jest --testPathPattern=unit`.
> **Khác biệt quan trọng:** Dart có formatter built-in (không cần cài Prettier), và exclude file generated tự động.

---

## analysis_options.yaml — Quy tắc chất lượng code

<!-- AI_VERIFY: base_flutter/analysis_options.yaml#L1-L26 [EXCERPT — simplified, some exclude patterns omitted] -->
```yaml
analyzer:
  plugins:
    - custom_lint
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.config.dart"
    - "lib/generated/**/*.dart"
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    unused_import: warning
    invalid_annotation_target: ignore
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/analysis_options.yaml)

> 🔎 **Quan sát**
> - `exclude` pattern giống `fm` — generated files được exclude khỏi analysis
> - `strict-casts: true` — **cấm implicit cast**, mọi type conversion phải explicit
> - `strict-raw-types: true` — **cấm raw generic types** (phải viết `List<String>`, không được viết `List`)
> - **Hỏi:** Tại sao `unused_import` là `warning` chứ không phải `error`?

> 💡 **FE Perspective**
> **Flutter:** `analysis_options.yaml` cấu hình static analysis + lint rules built-in trong Dart SDK.
> **React/Vue tương đương:** `.eslintrc` + `tsconfig.json` strict mode.
> **Khác biệt quan trọng:** Dart built-in static analysis — không cần cài ESLint riêng. `strict-casts` ≈ TypeScript `strict: true`.

### Custom lint rules

<!-- AI_VERIFY: base_flutter/analysis_options.yaml#L28-L55 -->
```yaml
custom_lint:
  rules:
    - prefer_named_parameters:
      threshold: 2
    - avoid_unnecessary_async_function:
    - prefer_async_await:
    - avoid_hard_coded_colors:
    - avoid_hard_coded_strings:
      includes:
        - "lib/ui/component/**/*.dart"
        - "lib/ui/page/**/*_page.dart"
    - incorrect_parent_class:
    - prefer_common_widgets:
    - avoid_dynamic:
    - avoid_using_datetime_now:
    - missing_run_catching:
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/analysis_options.yaml)

> 🔎 **Quan sát**
> - `prefer_named_parameters: threshold: 2` — function có ≥2 params phải dùng named parameters

> 💡 **Named parameters:** `threshold: 2` = hàm có ≥2 params phải dùng named params (giống destructured props trong React: `function Button({ label, onClick })`). Chi tiết ở [02-concept.md § Part B](./02-concept.md).

> - `avoid_hard_coded_strings` chỉ apply cho UI (`lib/ui/`) — buộc dùng localization
> - `avoid_dynamic` — cấm kiểu `dynamic`, buộc declare type cụ thể
> - **Hỏi:** `missing_run_catching` có vẻ là custom rule — đoán xem nó enforce điều gì?

### Linter rules (built-in)

<!-- AI_VERIFY: base_flutter/analysis_options.yaml#L148-L233 [EXCERPT — 9 of 80+ rules shown] -->
```yaml
linter:
  rules:
    - always_declare_return_types
    - annotate_overrides
    - avoid_print
    - prefer_const_constructors
    - prefer_final_locals
    - prefer_single_quotes
    - unawaited_futures
    - prefer_relative_imports
    - use_super_parameters
```
<!-- END_VERIFY -->

> ⚠️ **Note:** File gốc có 80+ linter rules (L148-L233). Trên đây chỉ là 9 rules tiêu biểu. Xem full list trong file gốc.

→ [Mở file gốc](../../base_flutter/analysis_options.yaml)

> 🔎 **Quan sát**
> - `prefer_const_constructors` — Dart dùng `const` rất nhiều để optimize rebuild widget
> - `prefer_final_locals` — biến local phải `final` nếu không reassign (tương tự `const` trong JS)
> - `avoid_print` — production code không được `print()`, phải dùng logger
> - **Hỏi:** `unawaited_futures` bắt lỗi gì? Hint: liên quan đến async/await.

---

## build.yaml — Cấu hình code generation

<!-- AI_VERIFY: base_flutter/build.yaml#L1-L20 -->
```yaml
targets:
  $default:
    sources:
      - lib/**
      - graphql/**
      - pubspec.*
      - $package$
    builders:
      slang_build_runner:
        options:
          base_locale: ja
          input_directory: lib/resource/l10n
          input_file_pattern: .i18n.json
          output_directory: lib/generated
          output_file_name: app_string.g.dart
          class_name: AppString
          translate_var: l10n
          flutter_integration: true
          enum_name: AppLocale
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/build.yaml)

> 🔎 **Quan sát**
> - `sources` chỉ định folder nào `build_runner` scan — không quét `test/` hay `tools/`
> - `slang_build_runner` gen localization: đọc `.i18n.json` → output `app_string.g.dart`
> - `base_locale: ja` — locale mặc định là tiếng Nhật (project cho client Nhật)
> - **Hỏi:** Tại sao output file có suffix `.g.dart`? Convention này có ý nghĩa gì?

> 💡 **FE Perspective**
> **Flutter:** `build.yaml` cấu hình sources cho `build_runner` scan và options cho từng generator plugin.
> **React/Vue tương đương:** `webpack.config.js` cho plugin configuration.
> **Khác biệt quan trọng:** Dart gen file mới (`.g.dart`) cạnh source file, không transform code lúc bundle như webpack.

---

## slang.yaml — Localization config

<!-- AI_VERIFY: base_flutter/slang.yaml#L1-L9 -->
```yaml
base_locale: ja
input_directory: lib/resource/l10n
input_file_pattern: .i18n.json
output_directory: lib/generated
output_file_name: app_string.g.dart
class_name: AppString
translate_var: l10n
flutter_integration: true
enum_name: AppLocale
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/slang.yaml)

> 🔎 **Quan sát**
> - Config giống hệt `slang_build_runner` trong `build.yaml` — file này là standalone config cho CLI `dart run slang`
> - `translate_var: l10n` — trong code sẽ dùng `l10n.someKey` để truy cập string
> - **Hỏi:** Tại sao cần cả `slang.yaml` lẫn config trong `build.yaml`? (Hint: 2 cách chạy khác nhau — CLI vs build_runner)

> 💭 Suy nghĩ trước khi đọc concept — đáp án ở [02-concept.md](./02-concept.md)

> 💡 **FE Perspective**
> **Flutter:** `slang.yaml` cấu hình gen type-safe class từ JSON — `l10n.someKey` có autocomplete, sai key = compile error.
> **React/Vue tương đương:** `i18next` config hoặc `vue-i18n` setup, import JSON trực tiếp.
> **Khác biệt quan trọng:** Dart gen type-safe class (compile error nếu sai key), FE dùng string key (runtime error nếu sai).

---

## Code Walk Summary

| File | Vai trò | FE Equivalent |
|------|---------|---------------|
| `pubspec.yaml` | Khai báo dependencies, assets, metadata | `package.json` |
| `makefile` | Automation: build, test, lint, format | `package.json scripts` |
| `analysis_options.yaml` | Static analysis + lint rules | `.eslintrc` + `tsconfig strict` |
| `build.yaml` | Code generation config | `webpack.config.js` (plugin) |
| `slang.yaml` | Localization codegen config | `i18next.config.js` |

**Workflow khi clone project lần đầu:**

```
make sync    # = pub get + localization gen + codegen
make fm      # = format check
make lint    # = static analysis
make ut      # = unit tests
```

<!-- AI_VERIFY: generation-complete -->
