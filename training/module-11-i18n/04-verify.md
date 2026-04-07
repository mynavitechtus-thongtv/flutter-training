# Verification — Kiểm tra kết quả Module 11

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi mô tả được 9 config keys trong `slang.yaml` và vai trò từng key? | slang Setup | 🔴 |
| 2 | Tôi phân biệt được simple string vs parameterized string trong JSON, và `$param` syntax? | Translation Source | 🔴 |
| 3 | Tôi liệt kê được pipeline: JSON → `make ln` → `.g.dart` → `l10n.key`? | Code Generation | 🔴 |
| 4 | Tôi phân biệt Method A (`l10n.key`) vs Method B (`context.l10n.key`) — khi nào dùng cái nào? | l10n Accessor | 🟡 |
| 5 | Tôi giải thích được vai trò `TranslationProvider` + `localizationsDelegates` trong `my_app.dart`? | TranslationProvider | 🟡 |
| 6 | Tôi thực hiện được workflow thêm string mới: JSON → `make ln` → use → verify? | Adding Strings | 🟢 |

**Target:** 3/3 Yes cho 🔴 MUST-KNOW, tối thiểu 5/6 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace l10n Data Flow ⭐

Đáp án tham khảo:

| # | Stage | File | Nội dung |
|---|-------|------|----------|
| 1 | JSON source | ja.i18n.json | `"login": "ログイン"` |
| 2 | Config reads | slang.yaml | `translate_var: l10n` |
| 3 | Generated getter | app_string_ja.g.dart | `String get login => 'ログイン';` |
| 4 | Top-level accessor | app_string.g.dart | `AppString get l10n => LocaleSettings.instance.currentTranslations;` |
| 5 | Page usage | login_page.dart | `l10n.login` |
| 6 | Runtime value | — | `"ログイン"` |

**Câu hỏi answers:**
- [ ] `l10n` là **tên biến** (top-level getter), không phải class. Được define trong `app_string.g.dart` — generated bởi slang dựa trên `translate_var` config.
- [ ] Đổi `translate_var: t` → `make ln` → generated getter đổi thành `AppString get t => ...`. Mọi `l10n.xxx` trong pages → đổi thành `t.xxx`.
- [ ] `l10n.login` return type = `String`. Compile-time resolved: getter tồn tại hay không → compile check. Value (`"ログイン"`) = runtime resolved.

### Exercise 2 — Add Simple String ⭐

- [ ] Key `"profile"` thêm đúng vị trí alphabetical (sau `"passwordsAreNotMatch"`, trước `"reply"`)
- [ ] `make ln` chạy thành công — output hiện `Generated 1 file(s)` hoặc tương tự
- [ ] `String get profile => 'プロフィール';` xuất hiện trong `app_string_ja.g.dart`
- [ ] `l10n.profile` compile thành công trong Dart code

**Câu hỏi answers:**
- [ ] Quên `make ln` → `l10n.profile` → **compile error**: `The getter 'profile' isn't defined for the type 'AppString'`
- [ ] Value trống `""` → generated getter: `String get profile => '';` → build **pass**, nhưng UI hiển thị empty string
- [ ] Alphabetical order → git diff gọn gàng (chỉ 1 line added), giảm merge conflict khi nhiều dev thêm strings cùng lúc

### Exercise 3 — Parameterized String ⭐⭐

- [ ] `$userName` và `$count` syntax đúng trong JSON
- [ ] Generated signatures: `String welcomeUser({required Object userName})` và `String itemCount({required Object count})`
- [ ] Gọi đúng: `l10n.welcomeUser(userName: 'Tanaka')` → `"ようこそ、Tanaka さん"`
- [ ] Gọi thiếu param: `l10n.welcomeUser()` → **compile error**: `The named parameter 'userName' is required`
- [ ] Gọi sai type: `l10n.itemCount(count: [1,2,3])` → **compile pass** (Object accepts any type) → runtime: `"[1, 2, 3] 件のアイテムがあります"` (calls `.toString()`)

**Câu hỏi answers:**
- [ ] `Object` type → slang không biết developer muốn String/int/double. `Object.toString()` được gọi lúc runtime → flexible nhưng less type-safe cho individual params.
- [ ] Restrict `count` thành `int` → slang không hỗ trợ trực tiếp. Workaround: wrapper method trong app code, hoặc custom slang modifier (advanced).
- [ ] `$param` (slang) — Dart-native syntax, compile check tên param. `{param}` (react-intl) — lib-specific syntax, runtime check. slang wins on dev experience, react-intl wins on familiarity cho FE devs.

### Exercise 4 — AI Prompt Dojo ⭐⭐⭐

- [ ] AI output ≥ 4/6 tiêu chí pass
- [ ] AI nhận diện slang = code-gen → type-safe (vs runtime lookup)
- [ ] AI phân biệt Method A / Method B chính xác
- [ ] AI recommend multi-locale steps: tạo `en.i18n.json` → `make ln` → `AppLocale.en` auto-added
- [ ] AI so sánh slang vs intl/ARB: slang = simpler config, ARB = Flutter official, better pluralization support
- [ ] AI **KHÔNG** claim `$param` là security risk (Dart string interpolation ≠ HTML injection)
- [ ] Bạn identify ≥ 2 gaps trong AI response

---

## 3. Concept Cross-Check

| # | Scenario | Đáp án đúng | Concept |
|---|----------|-------------|---------|
| 1 | Xóa `slang.yaml` → chạy `make ln` → ? | Error: slang config not found. Không generate gì. | slang Setup |
| 2 | Thêm key `"NEW"` (uppercase) vào JSON → ? | Generated getter: `String get NEW => '...';` — phá Dart camelCase convention. Build pass nhưng lint warning. | Translation Source |
| 3 | Thêm `en.i18n.json` với fewer keys than `ja` → ? | `make ln` thành công. Missing keys fallback to `ja` (base locale). `AppLocale.en` added to enum. | Code Generation |
| 4 | Dùng `l10n.login` trong ViewModel (không có context) → ? | **Hoạt động** — Method A (top-level getter) không cần context. | l10n Accessor |
| 5 | Comment out `TranslationProvider` trong `my_app.dart` → ? | `l10n.xxx` (Method A) vẫn hoạt động. `context.l10n` → runtime error (no InheritedWidget ancestor). | TranslationProvider |
| 6 | Thêm key, quên `make ln`, deploy → ? | Compile error tại `l10n.newKey` → **build fail** → deploy blocked. Safety net của code-gen approach. | Adding Strings |

---

## 4. Architecture Cross-Check

| Component | File | Vai trò | Dùng bởi |
|-----------|------|---------|----------|
| slang.yaml | `base_flutter/slang.yaml` | i18n codegen config | `dart run slang` (build tool) |
| ja.i18n.json | `lib/resource/l10n/ja.i18n.json` | Translation source (46 keys) | slang codegen |
| app_string.g.dart | `lib/generated/app_string.g.dart` | Generated: enum, accessor, provider, settings | my_app.dart, all pages |
| app_string_ja.g.dart | `lib/generated/app_string_ja.g.dart` | Generated: AppString class with getters | app_string.g.dart (imported as part) |
| my_app.dart | `lib/ui/my_app.dart` | Integration: TranslationProvider + LocaleSettings | App entrypoint |
| Pages | `lib/ui/page/**/*.dart` | Consumer: `l10n.xxx` string access | UI layer |

**Data flow:** `ja.i18n.json` → (codegen) → `app_string*.g.dart` → (import) → `my_app.dart` + pages → (runtime) → UI text.

---

## 5. Forward Reference

Sau khi hoàn thành Module 11, bạn đã sẵn sàng cho:

- **Optional Module B — Push & Deep Links:** Localized deep link paths, locale-aware route resolution → dùng `AppLocaleUtils.supportedLocales` cho locale detection từ deep link URL.
- **Module 14 — Local Storage:** Persist user's locale preference qua `AppPreferences` (SharedPreferences) → restore locale khi app restart.
- **Multi-locale expansion:** Thêm `en.i18n.json`, `vi.i18n.json` → runtime locale switch qua `LocaleSettings.setLocale()`.

→ Quay lại [00-overview.md](./00-overview.md) để review tổng thể module.

---

## ➡️ Next Module

Hoàn thành Module 11! Bạn đã nắm vững internationalization (i18n), `slang` package.

→ Tiến sang **[Module 12 — Data Layer](../module-12-data-layer/)** để học API integration, repository pattern, Dio HTTP client.

<!-- AI_VERIFY: generation-complete -->
