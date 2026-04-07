# Concepts — Internationalization & Localization

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

---

## 1. slang Setup — YAML Config & Convention 🔴 MUST-KNOW

**WHY:** slang.yaml là trung tâm điều khiển toàn bộ i18n pipeline. Hiểu sai config → generate sai output, IDE không nhận strings.

<!-- AI_VERIFY: base_flutter/slang.yaml -->
```yaml
base_locale: ja
input_directory: lib/resource/l10n
input_file_pattern: .i18n.json
output_directory: lib/generated
class_name: AppString
translate_var: l10n
flutter_integration: true
enum_name: AppLocale
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § slang.yaml](./01-code-walk.md#1-slangyaml--code-generation-config)

**EXPLAIN:**

**Config anatomy:**

| Key | Vai trò | Nếu thiếu/sai |
|-----|---------|---------------|
| `base_locale` | Locale gốc — tất cả keys phải có | Thiếu → slang error, không generate |
| `input_directory` | Thư mục chứa JSON source | Sai path → "no translation files found" |
| `input_file_pattern` | File naming pattern | Sai → slang không nhận file |
| `output_directory` | Nơi output `.g.dart` | Sai → file generate ở chỗ không mong đợi |
| `class_name` | Tên class generated | Đổi → import/reference cần cập nhật |
| `translate_var` | Tên top-level getter | `l10n` = convention, đổi → mọi `l10n.xxx` phải đổi theo |
| `output_file_name` | Tên file `.g.dart` output | Đổi → import path cần cập nhật |
| `flutter_integration` | Enable TranslationProvider | `false` → không có widget rebuild khi locale change |
| `enum_name` | Tên locale enum | Đổi → `AppLocale` reference cần cập nhật |

**Naming convention pipeline:**

```
{locale}.i18n.json  →  app_string.g.dart  →  AppString class
   ↑                        ↑                      ↑
input_file_pattern    output_file_name         class_name
```

**Multi-locale setup (nếu thêm English):**

```
lib/resource/l10n/
├── ja.i18n.json     ← base_locale (must have ALL keys)
└── en.i18n.json     ← override locale (chỉ cần keys muốn dịch)
```

→ `make ln` generate thêm `app_string_en.g.dart` + `AppLocale.en` trong enum.

> 💡 **FE Perspective**
> **Flutter:** `slang.yaml` là build-time codegen config — 9 keys control toàn bộ pipeline từ input JSON → output typed Dart class.
> **React/Vue tương đương:** React: `i18next.init({ lng, fallbackLng, resources })`. Vue: `createI18n()` config. Angular: `angular.json` → `i18n.sourceLocale`.
> **Khác biệt quan trọng:** slang = **build-time** codegen config (phải chạy trước compile). FE libs = **runtime** config (load khi app start).

**PRACTICE:** Mở `slang.yaml` → đổi `translate_var: t` → chạy `make ln` → xem output thay đổi gì trong `app_string.g.dart`. Revert lại.

---

## 2. Translation Source Format — JSON với Parameter Interpolation 🔴 MUST-KNOW

**WHY:** JSON format quyết định generated Dart API. Hiểu syntax → thêm string nhanh, đúng convention, tận dụng parameter/plural features.

<!-- AI_VERIFY: base_flutter/lib/resource/l10n/ja.i18n.json -->
```json
{
  "login": "ログイン",
  "email": "メールアドレス",
  "unknownException": "不明なエラー（$errorCode）"
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § ja.i18n.json](./01-code-walk.md#2-jai18njson--translation-source-40-keys)

**EXPLAIN:**

**3 loại string entries:**

| Type | JSON | Generated Dart | Usage |
|------|------|----------------|-------|
| Simple | `"login": "ログイン"` | `String get login => 'ログイン';` | `l10n.login` |
| Parameterized | `"err": "Error（$code）"` | `String err({required Object code})` | `l10n.err(code: 'X')` |
| Nested (optional) | `"auth": {"login": "..."}` | `_AppStringAuthJa get auth` | `l10n.auth.login` |

**Parameter rules:**

- `$paramName` → slang generates `required Object paramName` parameter
- Multiple params: `"msg": "Hello $name, you have $count items"` → `String msg({required Object name, required Object count})`
- Dart-style naming: `$errorCode` (camelCase) — **không** dùng `$error_code`

**Plural & Gender forms (slang advanced):**

slang hỗ trợ plural và context (gender) qua syntax đặc biệt trong JSON:

```json
{
  "itemCount": {
    "one": "$count アイテム",
    "other": "$count アイテム"
  },
  "greeting": {
    "context": {
      "male": "彼は $name です",
      "female": "彼女は $name です"
    }
  }
}
```

→ Generated Dart API:
```dart
// Plural
l10n.itemCount(count: 1)   // → "1 アイテム" (one)
l10n.itemCount(count: 5)   // → "5 アイテム" (other)

// Gender/Context
l10n.greeting(name: 'Tanaka', context: GenderContext.male)
l10n.greeting(name: 'Suzuki', context: GenderContext.female)
```

> ⚠️ Codebase hiện tại **không dùng** plural/gender — tất cả strings là simple hoặc parameterized. Biết syntax để dùng khi cần.

**Key naming convention trong codebase:**

```
✅ camelCase:     "invalidEmail", "deleteAccountConfirm"
❌ snake_case:    "invalid_email"  ← slang vẫn chạy nhưng phá Dart convention
❌ UPPER_CASE:    "INVALID_EMAIL"  ← generated getter sẽ là INVALID_EMAIL → phá convention
```

**JSON key = Dart getter name** — đây là contract. Thay đổi key → breaking change cho code reference.

> 💡 **FE Perspective**
> **Flutter:** Parameter dùng `$paramName` syntax — slang generate `required Object paramName` → compile-time type check, quên pass = compile error.
> **React/Vue tương đương:** react-intl: `{errorCode}`, vue-i18n: `{errorCode}` hoặc `@:key`, Angular: `{{ errorCode }}` (ICU format).
> **Khác biệt quan trọng:** slang params = **compile-time required**. FE libs = runtime interpolation — missing param = silent fallback hoặc runtime error.

**PRACTICE:** Thêm 1 parameterized string: `"welcomeUser": "ようこそ、$userName さん"` → `make ln` → verify generated getter signature.

---

## 3. Code Generation Flow — make ln Pipeline 🔴 MUST-KNOW

**WHY:** Hiểu pipeline = biết khi nào phải re-generate, debug khi output sai, integrate vào CI/CD.

<!-- AI_VERIFY: base_flutter/makefile -->
```makefile
ln:
	dart run slang
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § make ln](./01-code-walk.md#3-make-ln--code-generation-flow)

**EXPLAIN:**

**Pipeline stages:**

```
[1] Developer edits ja.i18n.json
          ↓
[2] make ln (= dart run slang)
          ↓
[3] slang reads slang.yaml → resolves config
          ↓
[4] slang scans input_directory → finds *.i18n.json files
          ↓
[5] slang parses JSON → builds translation tree
          ↓
[6] slang validates: missing keys? invalid params? duplicates?
          ↓
[7] slang generates:
    ├── app_string.g.dart     (shared: enum, l10n, TranslationProvider, LocaleSettings)
    └── app_string_ja.g.dart  (locale: AppString class with all getters)
          ↓
[8] Dart analyzer picks up new file → IDE autocomplete updated
          ↓
[9] Developer uses l10n.newKey → compile check ✓
```

**Khi nào PHẢI chạy `make ln`:**

| Thay đổi | Cần `make ln`? |
|----------|---------------|
| Thêm key mới vào JSON | ✅ Yes — getter chưa tồn tại |
| Sửa value (text) của key hiện tại | ✅ Yes — giá trị runtime |
| Đổi tên key | ✅ Yes — getter name thay đổi |
| Thêm locale file mới (en.i18n.json) | ✅ Yes — thêm enum + class |
| Sửa slang.yaml config | ✅ Yes — output structure thay đổi |
| Chỉ sửa Dart UI code (dùng l10n.xxx) | ❌ No |

**Error cases:**

| Problem | Error | Fix |
|---------|-------|-----|
| JSON syntax error | `FormatException` | Fix JSON (trailing comma, missing quote) |
| Key in en.json missing in ja.json | Warning — fallback to base | Add key to ja.json (base locale) |
| Duplicate key | slang overwrite — last wins | Remove duplicate |
| `$param` in one locale, missing in another | Generated param mismatch | Ensure same params across locales |

> 💡 **FE Perspective**
> **Flutter:** `make ln` (`dart run slang`) đọc JSON → generate `.g.dart` files. Phải chạy sau mỗi lần thêm/sửa key trong JSON.
> **React/Vue tương đương:** `npm run extract` (react-intl), `vue-i18n-extract` — tương tự nhưng FE libs cũng hỗ trợ runtime JSON loading.
> **Khác biệt quan trọng:** Flutter **bắt buộc** build step trước compile. FE libs load JSON at runtime → key mới available ngay không cần rebuild.

**PRACTICE:** Cố tình tạo JSON error (missing closing `}`) → chạy `make ln` → đọc error message → fix → chạy lại.

---

## 4. l10n Accessor Pattern — Typed, Compile-Safe 🟡 SHOULD-KNOW

**WHY:** Hiểu `l10n` accessor cho phép chọn đúng method (top-level vs context-based) tùy use case.

<!-- AI_VERIFY: base_flutter/lib/generated/app_string.g.dart -->
```dart
// Method A: Top-level getter
AppString get l10n => LocaleSettings.instance.currentTranslations;

// Method B: Context-based
class TranslationProvider extends BaseTranslationProvider<...> { ... }
extension BuildContextTranslationsExtension on BuildContext {
  AppString get l10n => TranslationProvider.of(this).translations;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_string.g.dart](./01-code-walk.md#42-l10n-accessor--translationprovider)

**EXPLAIN:**

**Method A vs Method B:**

| | Method A: `l10n.key` | Method B: `context.l10n.key` |
|---|---------------------|------------------------------|
| Import cần | `app_string.g.dart` | `app_string.g.dart` + BuildContext |
| Dùng ở đâu | Mọi nơi (UI, ViewModel, utils) | Chỉ trong widget (có context) |
| Locale change rebuild | ❌ Không tự rebuild | ✅ Rebuild qua InheritedWidget |
| Use case | Static locale (single-language app) | Dynamic locale (multi-language switch) |
| Codebase dùng | ✅ Chủ yếu | ⚠️ Ít dùng |

**Tại sao codebase dùng Method A (`l10n.key`) chủ yếu?**
- App hiện tại chỉ support 1 locale (`ja`). Không có runtime switch.
- `TranslationProvider` vẫn wrap app → sẵn sàng cho future multi-locale.
- Method A ngắn gọn hơn, không cần `context` → dùng được trong ViewModel, utils.

> 📋 **Convention**: Codebase dùng **Method A (`l10n` global accessor)** throughout. Đây là convention thống nhất — không mix methods.

**Generated AppString class:**

```dart
class AppString {
  String get login => 'ログイン';                    // ← simple getter
  String get email => 'メールアドレス';               // ← simple getter
  String unknownException({required Object errorCode}) // ← parameterized method
      => '不明なエラー（${errorCode}）';
}
```

→ Mỗi JSON key → 1 Dart getter/method. **IDE autocomplete, refactor, find-usages** đều hoạt động.

> 💡 **FE Perspective**
> **Flutter:** Method A (`l10n.key`) = top-level getter, dùng mọi nơi không cần context. Method B (`context.l10n`) = InheritedWidget, rebuild khi locale thay đổi.
> **React/Vue tương đương:** Method A ≈ `i18next.t('key')`. Method B ≈ `useIntl()` (react-intl), `useI18n()` (vue-i18n).
> **Khác biệt quan trọng:** Method A không tự rebuild khi switch locale — OK cho single-language app. Method B reactive nhưng cần `BuildContext`.

**PRACTICE:** Trong bất kỳ page, thử thay `l10n.login` bằng `context.l10n.login` → verify cùng kết quả. Quan sát: IDE autocomplete có khác không?

---

## 5. Locale Fallback Behavior 🟡 SHOULD-KNOW

**WHY:** Khi translation key thiếu, cần biết app sẽ hiển thị gì — tránh UI broken hoặc crash.

**EXPLAIN:**

**Khi translation key missing, slang xử lý theo thứ tự:**

| Scenario | Behavior |
|----------|----------|
| Key có trong base locale (`ja`) nhưng thiếu trong `en` | Fallback về base locale value (hiển thị Japanese) |
| Key hoàn toàn không tồn tại | **Compile error** — `l10n.missingKey` không compile vì getter không được generate |
| Runtime locale không supported | `localeResolutionCallback` → fallback về `base_locale` |

**So sánh với FE i18n libs:**

| | slang (Flutter) | react-intl / vue-i18n |
|---|---|---|
| Missing key (build time) | ❌ Compile error | ⚠️ Runtime: hiển thị key as-is hoặc fallback |
| Missing key (locale override) | Fallback về base locale | Fallback chain: `en-US` → `en` → default |
| Warning logs | Codegen báo warning khi key thiếu trong non-base locale | Runtime console warning |

→ **Ưu điểm slang:** Missing key = compile error → không bao giờ ship app với translation thiếu. FE libs chỉ warning runtime → có thể miss.

> 💡 **FE Perspective**
> **Flutter:** slang tự động fall back về `base_locale` khi key thiếu trong locale khác — compile-time guarantee không missing key.
> **React/Vue tương đương:** i18next `fallbackLng`, react-intl `defaultLocale`, vue-i18n `fallbackLocale`.
> **Khác biệt quan trọng:** slang fallback là **compile-time** (generated code) — web i18n libs fallback tại runtime, có thể flash untranslated text.

---

## 6. ARB vs slang — Format Comparison 🟢 AI-GENERATE

**WHY:** Flutter ecosystem có 2 approach chính cho i18n. Hiểu trade-off để chọn đúng cho project.

**EXPLAIN:**

| | ARB (Flutter standard) | slang (codebase hiện tại) |
|---|---|---|
| **Format** | `.arb` (JSON-like, ICU syntax) | `.i18n.json` (JSON) hoặc YAML |
| **Setup** | `flutter_localizations` + `intl` | `slang` package + `slang.yaml` config |
| **Type safety** | Có (generated `AppLocalizations`) | Có (`AppString` class) |
| **Plural/Gender** | ICU syntax: `{count, plural, one{...} other{...}}` | slang syntax: nested object `{"one": ..., "other": ...}` |
| **Build speed** | Chậm hơn (phần của `flutter gen-l10n`) | Nhanh hơn (`dart run slang` chỉ gen i18n) |
| **IDE support** | VS Code plugin `arb-editor` | Type-safe getter → IDE autocomplete |
| **Tooling** | `flutter gen-l10n` (built-in) | `dart run slang` hoặc `make ln` |
| **Community** | Official Flutter approach | Community package, widely used |

**Khi nào chọn gì?**
- **ARB:** Project theo chuẩn Flutter official, team đã quen ICU syntax, cần maximum compatibility
- **slang:** Ưu tiên build speed, thích YAML config, muốn type-safe params mạnh hơn

→ Codebase `base_flutter` chọn slang vì: build nhanh, config đơn giản (`slang.yaml`), type-safe getters.

---

## 7. TranslationProvider & Locale Management 🟡 SHOULD-KNOW

**WHY:** Hiểu widget tree integration = biết cách enable multi-language, debug locale issues, handle edge cases (hot restart, deep link).

<!-- AI_VERIFY: base_flutter/lib/ui/my_app.dart -->
```dart
LocaleSettings.setLocaleRawSync('ja');
return TranslationProvider(
  child: MaterialApp.router(
    supportedLocales: AppLocaleUtils.supportedLocales,
    localizationsDelegates: [...],
    locale: const Locale('ja'),
    localeResolutionCallback: (...) => ...,
  ),
);
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § my_app.dart](./01-code-walk.md#5-my_appdart--integration-point)

**EXPLAIN:**

**Widget tree order (quan trọng):**

```
MyApp
  └── Consumer
      └── TranslationProvider        ← [1] Must be ABOVE MaterialApp
          └── DevicePreview
              └── MaterialApp.router  ← [2] Uses supportedLocales, delegates
                  └── Pages           ← [3] Access l10n.xxx
```

**3 layers i18n integration:**

| Layer | Component | Purpose |
|-------|-----------|---------|
| slang layer | `LocaleSettings.setLocaleRawSync('ja')` | Set active locale cho `l10n` getter |
| Widget layer | `TranslationProvider` | InheritedWidget → `context.l10n` reactive |
| Flutter layer | `supportedLocales` + `localizationsDelegates` | Material/Cupertino built-in widget localization |

**Tại sao cần `localizationsDelegates`?**

`LocaleSettings` + `TranslationProvider` chỉ handle **app strings** (custom text). Flutter built-in widgets (DatePicker, AlertDialog "OK"/"Cancel") cần **platform delegates:**

| Delegate | Localize what |
|----------|--------------|
| `GlobalMaterialLocalizations` | Material widget text (DatePicker, Dialog buttons) |
| `GlobalWidgetsLocalizations` | Text direction (LTR/RTL) |
| `GlobalCupertinoLocalizations` | Cupertino widget text (iOS-style picker, action sheet) |

**Runtime locale switch flow (future feature):**

```
User picks "English" in Settings
  → LocaleSettings.setLocale(AppLocale.en)
    → TranslationProvider notifies descendants
      → All widgets using context.l10n rebuild
        → UI updates to English
```

> 💡 **FE Perspective**
> **Flutter:** `TranslationProvider` (InheritedWidget) + `localizationsDelegates` (Material/Cupertino) + `localeResolutionCallback` — 3 layers i18n integration trong widget tree.
> **React/Vue tương đương:** `<IntlProvider>` (react-intl), `<I18nProvider>` (vue-i18n) — React context / Vue provide-inject.
> **Khác biệt quan trọng:** Flutter cần explicit `localizationsDelegates` cho platform widgets (DatePicker). Web browsers tự localize qua `Intl` API — không cần delegates.

**PRACTICE:** Comment out `TranslationProvider` → rebuild → quan sát `context.l10n` có còn hoạt động không? (`l10n.xxx` top-level vẫn OK — explain tại sao).

---

## 8. Adding New Strings — Workflow & Best Practices 🟢 AI-GENERATE

**WHY:** Real-world task: PM yêu cầu thêm text mới → cần nắm workflow để execute nhanh, đúng convention.

**EXPLAIN:**

**Standard workflow — 4 steps:**

```
[Step 1] → Add key to ja.i18n.json
              "newFeature": "新機能"

[Step 2] → Run make ln
              (generates updated app_string.g.dart)

[Step 3] → Use in code
              l10n.newFeature

[Step 4] → Verify
              Build pass + UI displays correctly
```

**Best practices:**

| Rule | Ví dụ | Lý do |
|------|-------|-------|
| camelCase keys | `"deleteConfirm"` ✅ | Match Dart getter convention |
| Descriptive names | `"loginButtonTitle"` > `"btn1"` | Self-documenting |
| Group by feature | Auth strings together | Dễ maintain |
| Param dùng camelCase | `$userName` ✅ `$user_name` ❌ | Dart convention |
| Avoid embedded HTML/markup | Tách content và style | Security + maintainability |
| Alphabetical order | `"add"` trước `"cancel"` | Git diff clean, avoid conflicts |

**Common mistakes:**

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Quên `make ln` | `l10n.newKey` → compile error | Run `make ln` |
| JSON trailing comma | `FormatException` during codegen | Remove trailing comma |
| Duplicate key | Silent overwrite — wrong value | Search duplicate, remove |
| Hardcode string thay vì `l10n` | String không localize được | Replace with `l10n.key` |
| Key in non-base locale only | Key not generated | Add to base locale first (`ja`) |

> 💡 **FE Perspective**
> **Flutter:** Workflow 4 bước: thêm key vào JSON → `make ln` → dùng `l10n.newKey` → verify build pass. Key mới **chỉ available sau codegen**.
> **React/Vue tương đương:** Workflow tương tự: edit JSON → (optional extract) → dùng `t('key')`. FE có thể dùng runtime loader.
> **Khác biệt quan trọng:** Flutter **bắt buộc** build step (`make ln`) — key mới = compile error nếu chưa generate. FE libs có thể load JSON runtime → available ngay.

**PRACTICE:** Thêm key `"profile": "プロフィール"` → `make ln` → dùng `l10n.profile` trong `my_profile_page.dart` → verify.

---

> 📋 Badge summary → xem [00-overview.md](./00-overview.md)

→ Tiếp tục: [03-exercise.md](./03-exercise.md)

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
