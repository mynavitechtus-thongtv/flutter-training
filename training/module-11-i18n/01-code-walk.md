# Code Walk — Internationalization & Localization (slang)

> 📌 **Recap từ modules trước:**
> - **M0:** `slang.yaml` config — `base_locale: ja`, `input_directory: lib/resource/l10n`, `make ln` chạy `dart run slang` ([M0 § slang.yaml](../module-00-dart-primer/01-code-walk.md))
> - **M6:** `TranslationProvider` wrap `MaterialApp` trong `my_app.dart`, `l10n.xxx` accessor cho string resources ([M6 § my_app.dart](../module-06-resource-theme/01-code-walk.md))
> - **M9:** Pages dùng `l10n.login`, `l10n.email`, `l10n.home` — typed string access trong `buildPage` ([M9 § login_page.dart](../module-09-page-structure/01-code-walk.md))
>
> Nếu chưa nắm vững → quay lại [Module 0](../module-00-dart-primer/), [Module 6](../module-06-resource-theme/) hoặc [Module 9](../module-09-page-structure/) trước.

---

## Walk Order

```
slang.yaml (config — what to generate)
    ↓
ja.i18n.json (translation source — input strings)
    ↓
make ln → dart run slang (code generation trigger)
    ↓
app_string.g.dart (generated output — typed accessors)
    ↓
my_app.dart (integration — TranslationProvider + LocaleSettings)
    ↓
login_page.dart / main_page.dart (usage — l10n.xxx in pages)
```

Bắt đầu từ **config** (how slang works) → **source** (what strings exist) → **codegen** (how output is generated) → **integration** (how app uses it) → **page usage** (where strings appear).

---

## 1. slang.yaml — Code Generation Config

<!-- AI_VERIFY: base_flutter/slang.yaml -->
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
> - `base_locale: ja` — Japanese là locale gốc. Mọi key **phải** khai báo trong `ja.i18n.json`. Locale khác (en, vi) chỉ cần override keys cần dịch.
> - `input_directory: lib/resource/l10n` — thư mục chứa JSON source files. Naming convention: `{locale}.i18n.json` (match `input_file_pattern`).
> - `output_directory: lib/generated` — file `.g.dart` được generate vào đây. **Không edit tay** — mọi thay đổi sẽ bị overwrite lần chạy `make ln` tiếp theo.
> - `class_name: AppString` — tên class generated chứa tất cả translations. Access qua `l10n.someKey`.
> - `translate_var: l10n` — tên biến top-level globally accessible. Đây là lý do mọi page gọi `l10n.login` thay vì `AppString.instance.login`.
> - `flutter_integration: true` — enable `TranslationProvider` widget + `context.l10n` extension. Cần cho runtime locale switching.
> - `enum_name: AppLocale` — enum generated cho supported locales. Hiện tại chỉ có `AppLocale.ja`.
> - **9 lines config** → control toàn bộ i18n pipeline. Mọi convention (input format, output location, class name) defined tập trung tại đây.
> - **Hỏi:** Nếu muốn thêm locale `en` → cần tạo file gì ở đâu? slang.yaml có cần sửa không?
> - **Hỏi:** `translate_var: l10n` — nếu đổi thành `t` → code cần thay đổi gì?

> 💡 **FE Perspective**
> **Flutter:** `slang.yaml` (9 lines) config toàn bộ i18n pipeline — input JSON, output Dart code, class name, locale enum. Generate **compile-time type-safe** accessors.
> **React/Vue tương đương:** `i18n.config.js` (react-intl), `vue-i18n` config. Vue dùng `$t('key')`, Angular dùng `ngx-translate`.
> **Khác biệt quan trọng:** slang **generate Dart code** → compile-time type-safe. FE libs dùng runtime string lookup → typo chỉ phát hiện lúc chạy.

---

## 2. ja.i18n.json — Translation Source (~40+ keys)

<!-- AI_VERIFY: base_flutter/lib/resource/l10n/ja.i18n.json -->
```json
{
  "add": "追加",
  "addNewMembers": "新しいメンバーを追加",
  "allUsers": "すべてのユーザー",
  "alreadyHaveAnAccount": "すでにアカウントをお持ちですか？",
  "cancel": "キャンセル",
  "canNotConnectToHost": "ホストに接続できません",
  "conversations": "会話",
  "copy": "コピー",
  "createAnAccount": "アカウントを作成する",
  "createANewConversation": "新しい会話を作成する",
  "darkTheme": "暗いテーマ",
  "deleteAccount": "アカウントを削除する",
  "deleteAccountConfirm": "アカウントを削除してもよろしいですか？",
  "email": "メールアドレス",
  "forceLogout": "セッションの有効期限が切れました。再度ログインしてください。",
  "home": "ホームページ",
  "invalidEmail": "無効なメールアドレス",
  "invalidLoginCredentials": "無効なログイン情報",
  "invalidPassword": "無効なパスワード",
  "japanese": "日本語",
  "login": "ログイン",
  "logout": "ログアウト",
  "logoutConfirm": "ログアウトしてもよろしいですか？",
  "myPage": "マイページ",
  "noInternetException": "インターネット接続がありません",
  "ok": "OK",
  "password": "パスワード",
  "passwordConfirmation": "パスワード確認",
  "passwordsAreNotMatch": "パスワードが一致しません",
  "retry": "リトライ",
  "search": "探す",
  "settings": "設定",
  "timeoutException": "タイムアウトエラー",
  "tokenExpired": "トークンの有効期限が切れています",
  "unknownException": "不明なエラー（$errorCode）",
  "you": "（あなた）",
  "youHaveLoggedInOnAnotherDevice": "別のデバイスでログインしました"
}
```
<!-- END_VERIFY -->

> 📝 Shown 37 keys — see [full file](../../base_flutter/lib/resource/l10n/ja.i18n.json) for all ~40+ keys.

→ [Mở file gốc](../../base_flutter/lib/resource/l10n/ja.i18n.json)

> 🔎 **Quan sát**
> - **Flat key structure** — không nested. `"login": "ログイン"` thay vì `"auth": { "login": "..." }`. Convention này giữ code access đơn giản: `l10n.login` thay vì `l10n.auth.login`.
> - **camelCase keys** — match Dart property naming. `"invalidEmail"` → `l10n.invalidEmail`. JSON key = Dart getter name.
> - **Parameter interpolation:** `"unknownException": "不明なエラー（$errorCode）"` — `$errorCode` là parameter. Generated code: `String unknownException({required Object errorCode})` → **compile-time parameter check**.
> - **String categories (by convention):**
>   | Category | Examples | Count |
>   |----------|---------|-------|
>   | Auth/Login | login, email, password, invalidEmail | ~10 |
>   | Navigation | home, myPage, settings | ~4 |
>   | Actions | add, cancel, ok, retry, copy, search | ~7 |
>   | Errors | noInternetException, timeoutException, unknownException | ~6 |
>   | Confirmation dialogs | logoutConfirm, deleteAccountConfirm | ~5 |
>   | Account | createAnAccount, deleteAccount | ~4 |
>   | Other | conversations, members, darkTheme | ~10 |
> - **Hỏi:** `"ok": "OK"` — key là lowercase `ok` nhưng value viết hoa `OK`. Dart getter là `l10n.ok` → tại sao không đặt key là `OK`?
> - **Hỏi:** `$errorCode` dùng `$` prefix. Nếu muốn string chứa literal `$` → escape thế nào?

> 💡 **FE Perspective**
> **Flutter:** JSON flat keys (camelCase) → generated Dart getters. Parameter interpolation dùng `$paramName` — giống Dart string interpolation, compile-time check.
> **React/Vue tương đương:** react-intl dùng `{errorCode}`, vue-i18n dùng `{errorCode}` hoặc `@:key`, Angular dùng `{{ errorCode }}`.
> **Khác biệt quan trọng:** slang `$param` → generated `required Object param` — quên pass = compile error. FE libs dùng runtime lookup → missing param = runtime fallback.

---

## 3. make ln → Code Generation Flow

<!-- AI_VERIFY: base_flutter/makefile -->
```makefile
ln:
	dart run slang
```
<!-- END_VERIFY -->

→ [Mở makefile](../../base_flutter/makefile)

> 🔎 **Quan sát**
> - `make ln` = shorthand cho `dart run slang`. Team convention: `ln` = "localization" (viết tắt).
> - **Pipeline:**
>   ```
>   make ln
>     ↓
>   dart run slang
>     ↓ reads
>   slang.yaml (config)
>     ↓ scans
>   lib/resource/l10n/*.i18n.json (source files)
>     ↓ generates
>   lib/generated/app_string.g.dart     (main: enum, l10n accessor, settings)
>   lib/generated/app_string_ja.g.dart  (locale-specific: AppString class with getters)
>   ```
> - Output gồm **2 files**: `app_string.g.dart` (shared infrastructure) + `app_string_ja.g.dart` (locale-specific strings). Thêm locale `en` → thêm file `app_string_en.g.dart`.
> - `make lnw` = `dart run slang watch` — **watch mode**: tự regenerate khi JSON thay đổi.
> - **Workflow khi thêm string mới:**
>   1. Thêm key-value vào `ja.i18n.json`
>   2. Chạy `make ln`
>   3. Dùng `l10n.newKey` trong code → **compile check** nếu typo
> - **Hỏi:** Nếu thêm key vào JSON nhưng quên chạy `make ln` → chuyện gì xảy ra khi dùng `l10n.newKey`?
> - **Hỏi:** File `.g.dart` có nên commit vào git không? Tại sao?

---

## 4. app_string.g.dart — Generated Infrastructure (168 lines)

<!-- AI_VERIFY: base_flutter/lib/generated/app_string.g.dart -->

### 4.1. AppLocale Enum

```dart
enum AppLocale with BaseAppLocale<AppLocale, AppString> {
  ja(languageCode: 'ja');

  const AppLocale({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
  });

  @override final String languageCode;
  @override final String? scriptCode;
  @override final String? countryCode;

  // ... build() and buildSync() methods
}
```

> 🔎 **Quan sát**
> - `enum AppLocale` — **compile-time** danh sách locales. Hiện chỉ `ja`. Thêm locale → enum tự expand.
> - `with BaseAppLocale<AppLocale, AppString>` — mixin from slang package, cung cấp `build()` async và `buildSync()`.
> - `build()` / `buildSync()` — factory methods tạo `AppString` instance cho locale cụ thể.

### 4.2. l10n Accessor & TranslationProvider

```dart
/// Method A: Simple — No rebuild after locale change.
AppString get l10n => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced — All widgets trigger rebuild when locale changes.
/// Step 1: wrap App with TranslationProvider(child: MyApp())
/// Step 2: final l10n = AppString.of(context);
class TranslationProvider extends BaseTranslationProvider<AppLocale, AppString> {
  TranslationProvider({required super.child})
      : super(settings: LocaleSettings.instance);
}

/// context.l10n shorthand
extension BuildContextTranslationsExtension on BuildContext {
  AppString get l10n => TranslationProvider.of(this).translations;
}
```

→ [Mở file gốc](../../base_flutter/lib/generated/app_string.g.dart)

> 🔎 **Quan sát**
> - **Method A** (`l10n` top-level getter): đơn giản, dùng ở mọi page trong codebase. **Không rebuild** khi locale thay đổi — strings resolved lúc widget build.
> - **Method B** (`TranslationProvider` + `context.l10n`): wrap app → `InheritedWidget` propagate locale → mọi widget dùng `context.l10n` sẽ **rebuild khi locale thay đổi**. Cần nếu app hỗ trợ runtime locale switch.
> - **Codebase dùng cả hai:** `TranslationProvider` wrap ở `my_app.dart` (safety net cho future locale switch) + `l10n.xxx` (shorthand trong pages — Method A).
> - `AppString.of(context)` — static method access through `InheritedLocaleData`. Giống `Theme.of(context)` pattern.
> - `context.l10n` — extension method, syntactic sugar cho `TranslationProvider.of(this).translations`.

### 4.3. LocaleSettings & AppLocaleUtils

```dart
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, AppString> {
  static AppLocale get currentLocale => instance.currentLocale;
  static Future<AppLocale> setLocale(AppLocale locale, ...) => ...;
  static Future<AppLocale> setLocaleRaw(String rawLocale, ...) => ...;

  // Synchronous versions
  static AppLocale setLocaleSync(AppLocale locale, ...) => ...;
  static AppLocale setLocaleRawSync(String rawLocale, ...) => ...;
}

class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, AppString> {
  static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
  static List<Locale> get supportedLocales => instance.supportedLocales;
}
```

> 🔎 **Quan sát**
> - `LocaleSettings` — centralized locale management. `setLocale` (async) vs `setLocaleSync` (sync). Codebase dùng `setLocaleRawSync('ja')` trong `my_app.dart`.
> - `AppLocaleUtils.supportedLocales` — `List<Locale>` cho `MaterialApp.supportedLocales`. Tự cập nhật khi thêm locale mới.
> - **Hỏi:** `setLocale` (async) vs `setLocaleSync` — khi nào cần async version?

---

## 5. my_app.dart — Integration Point

<!-- AI_VERIFY: base_flutter/lib/ui/my_app.dart -->
```dart
class MyApp extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);

    LocaleSettings.setLocaleRawSync('ja');  // ← [1] Set default locale

    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        return TranslationProvider(       // ← [2] Wrap app for locale rebuild
          child: DevicePreview(
            // ...
            builder: (_) => MaterialApp.router(
              // ...
              supportedLocales: AppLocaleUtils.supportedLocales,  // ← [3]
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              locale: const Locale('ja'),  // ← [4] Force locale
              localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) =>
                  supportedLocales.map((e) => e.languageCode).contains(locale?.languageCode)
                      ? locale
                      : const Locale('ja'),  // ← [5] Fallback
            ),
          ),
        );
      },
    );
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/ui/my_app.dart)

> 🔎 **Quan sát**
> - **[1] `LocaleSettings.setLocaleRawSync('ja')`** — set default locale **trước** khi build widget tree. `Sync` variant vì đây là startup, không cần await.
> - **[2] `TranslationProvider`** — wraps entire app. `InheritedWidget` pattern → child widgets can access locale via `context.l10n`. **Phải ở trên `MaterialApp`** để locale context available cho toàn app.
> - **[3] `AppLocaleUtils.supportedLocales`** — auto-generated list, matching `AppLocale` enum values. Không hardcode `[Locale('ja')]`.
> - **[4] `locale: const Locale('ja')`** — force locale explicitly. Override device locale.
> - **[5] `localeResolutionCallback`** — fallback logic: nếu device locale supported → dùng, else → `ja`.
> - **`localizationsDelegates`** — Material, Widgets, Cupertino delegates. Cần cho ngôn ngữ built-in Flutter widgets (DatePicker, TimePicker, etc.).
> - **Hỏi:** `TranslationProvider` wrap `MaterialApp` nhưng `LocaleSettings.setLocaleRawSync` gọi **trước** `TranslationProvider` → thứ tự có quan trọng không?
> - **Hỏi:** Nếu muốn thêm locale switch tại runtime (ví dụ settings page) → cần thay đổi gì ở `my_app.dart`?

> 💡 **FE Perspective**
> **Flutter:** `TranslationProvider` wraps app → InheritedWidget propagate locale. `localizationsDelegates` localize built-in widgets (DatePicker, Dialog). `localeResolutionCallback` handle fallback.
> **React/Vue tương đương:** React `<IntlProvider locale="ja" messages={...}>`. Vue: `createI18n({ locale: 'ja', messages })`.
> **Khác biệt quan trọng:** Flutter cần explicit `localizationsDelegates` cho platform widgets — web browsers tự handle localization qua `Intl` API.

---

## 6. Page Usage — l10n.xxx in Action

### 6.1. login_page.dart

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/login_page.dart -->
```dart
// Title text
l10n.login,                    // → "ログイン"

// Form fields
title: l10n.email,             // → "メールアドレス"
hintText: l10n.email,          // → "メールアドレス"
title: l10n.password,          // → "パスワード"
hintText: l10n.password,       // → "パスワード"

// Button
l10n.login,                    // → "ログイン"
```
<!-- END_VERIFY -->

→ [Mở login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart)

### 6.2. main_page.dart — Tab Labels

```dart
// Bottom navigation labels
return l10n.home;     // → "ホームページ"
return l10n.myPage;   // → "マイページ"
```

→ [Mở main_page.dart](../../base_flutter/lib/ui/page/main/main_page.dart)

### 6.3. my_profile_page.dart — Action Buttons

```dart
l10n.logout,           // → "ログアウト"
l10n.deleteAccount,    // → "アカウントを削除する"
```

→ [Mở my_profile_page.dart](../../base_flutter/lib/ui/page/my_profile/my_profile_page.dart)

### 6.4. Parameterized String Usage

```dart
// In exception handler or error display
l10n.unknownException(errorCode: 'UE-01')
// → "不明なエラー（UE-01）"
```

> 🔎 **Quan sát**
> - **Consistent pattern:** Mọi user-facing string → `l10n.key`. **Không có hardcoded strings** trong UI code.
> - **Type-safe access:** `l10n.login` → Dart getter `String get login`. Typo → **compile error**.
> - **Parameterized strings:** `l10n.unknownException(errorCode: 'UE-01')` — named parameter, required bởi generated code. Quên pass → **compile error**.
> - **IDE autocomplete:** Type `l10n.` → IDE hiện toàn bộ ~40+ keys. Không cần nhớ hay tra cứu JSON.
> - **Hỏi:** Nếu dùng `l10n.unknownException(errorCode: 404)` (int thay vì String) → compile error hay runtime error?

> 💡 **FE Perspective**
> **Flutter:** `l10n.login` (simple), `l10n.unknownException(errorCode: x)` (parameterized) — typed Dart getters, full IDE autocomplete, compile-time check.
> **React/Vue tương đương:** React: `intl.formatMessage({id: 'login'})`. Vue: `$t('login')`. Cả hai dùng runtime string lookup.
> **Khác biệt quan trọng:** Flutter slang = **compile-time type-safe** + full IDE autocomplete. FE i18n = runtime lookup → typo chỉ phát hiện lúc chạy, autocomplete phụ thuộc plugin.

---

## Summary — Data Flow Diagram

```
┌────────────────────┐    ┌─────────────────────────┐
│   slang.yaml       │    │  ja.i18n.json            │
│   (config)         │    │  (~40+ translation keys)  │
└────────┬───────────┘    └────────────┬──────────────┘
         │                             │
         └──────────┬──────────────────┘
                    │ make ln (dart run slang)
                    ▼
         ┌──────────────────────────────┐
         │  app_string.g.dart           │
         │  ├── AppLocale enum          │
         │  ├── l10n top-level getter   │
         │  ├── TranslationProvider     │
         │  ├── LocaleSettings          │
         │  └── AppLocaleUtils          │
         │                              │
         │  app_string_ja.g.dart        │
         │  └── AppString class         │
         │      ├── get login → "ログイン" │
         │      ├── get email → "メール…"  │
         │      └── unknownException(…) │
         └──────────────┬───────────────┘
                        │ import
                        ▼
         ┌──────────────────────────────┐
         │  my_app.dart                 │
         │  ├── LocaleSettings.set…     │
         │  ├── TranslationProvider     │
         │  └── supportedLocales        │
         └──────────────┬───────────────┘
                        │ l10n.xxx
                        ▼
         ┌──────────────────────────────┐
         │  Pages                       │
         │  ├── l10n.login              │
         │  ├── l10n.email              │
         │  ├── l10n.home               │
         │  └── l10n.unknownException(…)│
         └──────────────────────────────┘
```

---

## Điểm cần nhớ trước khi sang Concept

1. **slang.yaml** = single source of truth cho i18n config (9 lines).
2. **JSON → Code** pipeline: `ja.i18n.json` → `make ln` → `app_string.g.dart` — typed, compile-safe.
3. **`l10n` accessor** = top-level getter → `l10n.key` ở bất kỳ đâu, không cần context.
4. **`TranslationProvider`** wraps app → enable runtime locale rebuild (Method B).
5. **Parameter interpolation** (`$errorCode`) → generated named parameters → compile-time check.
6. **No hardcoded strings** — mọi UI text qua `l10n.xxx`.

→ Tiếp tục: [02-concept.md](./02-concept.md)

<!-- AI_VERIFY: generation-complete -->
