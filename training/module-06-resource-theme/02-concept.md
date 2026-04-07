# Concepts — Resource & Theme System

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

---

## 1. Color System & Semantic Naming 🔴 MUST-KNOW

**WHY:** Mọi UI element cần color. Sai cách tổ chức color → hard-coded values rải rác, theme switching bất khả thi, design update = manual find-replace toàn codebase.

<!-- AI_VERIFY: base_flutter/lib/resource/app_colors.dart -->
```dart
class AppColors {
  const AppColors({
    required this.white,
    required this.black,
    required this.black2,
    required this.black3,
    required this.red1,
    required this.grey1,
    required this.grey2,
    required this.green1,
  });

  static late AppColors current;

  static const defaultAppColor = AppColors(
    white: Colors.white, black: Colors.black, ...
  );

  static const darkThemeColor = AppColors(
    white: Colors.black, black: Colors.white, ...
  );

  static AppColors of(BuildContext context) {
    final appColor = Theme.of(context).appColor;
    current = appColor;
    return current;
  }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_colors.dart](./01-code-walk.md#1-app_colorsdart--color-palette--theme-variants)

**EXPLAIN:**

**Cấu trúc 3 phần:**

| Phần | Code | Vai trò |
|------|------|---------|
| Instance fields | `final Color white, black, ...` | Immutable color set — 1 instance = 1 theme |
| Static variants | `defaultAppColor`, `darkThemeColor` | Pre-built light/dark palette |
| Context accessor | `of(BuildContext context)` | Lấy colors đúng theo theme + cache vào `current` |

**Semantic naming:**

```dart
// ❌ Literal naming (fragile):
final backgroundColor = Colors.white;      // dark theme? phải đổi

// ✅ Semantic naming (codebase pattern):
AppColors.current.white;                   // "white" = primary background
// dark theme → Colors.black, nhưng code KHÔNG đổi
```

→ Color name mô tả **role**, không mô tả **value**. Khi switch theme, value thay đổi nhưng API giữ nguyên.

> 💡 **FE Perspective — CSS cascade vs Flutter explicit**
> **CSS:** Styles cascade qua DOM tree — child tự động inherit `color`, `font-family` từ parent. Override ở bất kỳ level nào.
> **Flutter:** Không có cascade. Mỗi widget phải **explicitly** lấy color qua `AppColors.of(context)` hoặc `Theme.of(context)`. `ThemeData` propagate qua `InheritedWidget`, nhưng widget phải chủ động "pull" — không tự động "flow down" như CSS.
> **Tại sao quan trọng:** FE dev quen expect styles tự cascade. Trong Flutter, quên gọi `of(context)` = widget dùng default color, không inherited.

**`of(context)` + `current` — dual access pattern:**

```
Widget tree available?
    ├─ YES → AppColors.of(context) — context-aware, always correct
    └─ NO  → AppColors.current     — cached value, dùng ngoài widget tree
                                      (ViewModel, utility, etc.)
```

→ `of(context)` là **preferred path**. `current` là **escape hatch** — chỉ dùng khi không có context.
→ `BasePage.build()` gọi `AppColors.of(context)` → refresh `current` mỗi build cycle.

> ⚠️ **Footgun Alert:** `AppColors.current` sẽ throw `LateInitializationError` nếu gọi trước khi theme được khởi tạo (ví dụ: trong `initState` trước `MaterialApp`). Đây là lỗi #1 mà new dev gặp khi dùng `AppColors`.

> 💡 **FE Perspective**
> **Flutter:** Semantic colors trong `AppColors` dùng `of(context)` để resolve design tokens từ context — mỗi build cycle refresh `current` theo theme hiện tại.
> **React/Vue tương đương:** CSS custom properties (`:root { --bg-primary: white }`), styled-components `useTheme()` hook, Tailwind `bg-white dark:bg-black`.
> **Khác biệt quan trọng:** Flutter baked semantic vào Dart object (`AppColors.current`), CSS baked vào variables, Tailwind baked vào class names. Flutter resolve tại runtime qua `BuildContext`, CSS resolve tại paint time.

**PRACTICE:** Mở `app_colors.dart` → xác nhận `white` field trong `darkThemeColor` = `Colors.black`. Trace `of(context)` call trong `base_page.dart` → hiểu khi nào `current` được refresh.

---

## 2. Theme Extension Pattern 🔴 MUST-KNOW

**WHY:** Flutter `ThemeData` có sẵn `colorScheme`, `textTheme` nhưng **không** có slot cho custom color palette. Extension pattern giải quyết — attach `AppColors` vào ThemeData mà không subclass.

<!-- AI_VERIFY: base_flutter/lib/resource/app_themes.dart -->
```dart
extension ThemeDataExtensions on ThemeData {
  static final Map<AppThemeType, AppColors> _appColorMap = {};

  void addAppColor({required AppThemeType type, required AppColors appColor}) {
    _appColorMap[type] = appColor;
  }

  AppColors get appColor {
    return _appColorMap[AppThemes.currentAppThemeType] ??
        AppColors.defaultAppColor;
  }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_themes.dart](./01-code-walk.md#2-app_themesdart--themedata--custom-extension)

**EXPLAIN:**

**Tại sao extension, không phải ThemeExtension<T>?**

| Approach | Ưu | Nhược |
|----------|-----|------|
| `ThemeExtension<T>` (Flutter 3.0+) | Official API, `copyWith`, `lerp` support | Boilerplate nhiều hơn, phải register trong `ThemeData.extensions` |
| Extension method (codebase pattern) | Đơn giản, ít boilerplate, cascade `..addAppColor()` | Dùng static map → shared state, không có auto `lerp` |

> 💡 **`lerp` là gì?** `lerp` = *linear interpolation* — hàm nội suy giữa 2 giá trị (ví dụ: `Color.lerp(red, blue, 0.5)` → màu trung gian giữa đỏ và xanh). Flutter dùng `lerp` để animate smooth khi chuyển theme. Không có `lerp` = theme switch tức thì, không có transition animation.

→ Codebase chọn **extension method** cho simplicity. Trade-off: không animate khi switch theme (acceptable cho hầu hết apps).

> 📌 **Tại sao `base_flutter` không dùng `ThemeExtension<T>`?** Project khởi tạo trước Flutter 3.0 khi API này chưa tồn tại. `ThemeExtension<T>` yêu cầu nhiều boilerplate hơn: phải define class riêng, implement `copyWith()` và `lerp()`, đăng ký trong `ThemeData.extensions`. Tuy nhiên, **project mới nên cân nhắc `ThemeExtension<T>`** vì nó là official API, hỗ trợ theme transition animation, và type-safe hơn approach hiện tại.

**Static map — shared state:**

```dart
static final Map<AppThemeType, AppColors> _appColorMap = {};
```

→ `static` trong extension = **class-level**, không per-instance. Tất cả ThemeData instance share cùng map.
→ `addAppColor` gọi lúc khởi tạo `lightTheme`/`darkTheme` → map có 2 entries.

**Theme registration flow:**

```
App startup
    ↓
lightTheme = ThemeData(...)..addAppColor(type: light, appColor: defaultAppColor)
darkTheme  = ThemeData(...)..addAppColor(type: dark,  appColor: darkThemeColor)
    ↓
_appColorMap = { light: defaultAppColor, dark: darkThemeColor }
    ↓
Theme.of(context).appColor → lookup _appColorMap[currentAppThemeType]
```

> **JS tương đương (gần nhất)**: method chaining `builder.setColor('red').setSize(12).build()` — nhưng Dart `..` không cần return `this`.

**`AppThemes` class — theme state:**

```dart
class AppThemes {
  const AppThemes._();
  static late AppThemeType currentAppThemeType = AppThemeType.light;
}
```

→ Mutable static field = global theme state. Switch theme: set `currentAppThemeType` → rebuild UI → `appColor` getter trả palette mới.

> 💡 **FE Perspective**
> **Flutter:** Extension trên `ThemeData` dùng `addAppColor()` inject custom palette vào theme — `_appColorMap` là module-scoped registry, `appColor` getter resolve theo `currentAppThemeType`.
> **React/Vue tương đương:** styled-components `<ThemeProvider>` spread custom tokens vào theme object, React `useContext(ThemeContext).appColors`.
> **Khác biệt quan trọng:** Flutter dùng extension method (OOP) có private storage (`_appColorMap`), JS dùng object spread không có encapsulation tương đương.

**PRACTICE:** Trace dòng code từ `lightTheme` → `addAppColor` → `_appColorMap` → `appColor` getter. Xác nhận `appColor` fallback về `defaultAppColor` khi map empty.

---

## 3. Text Style Factory 🔴 MUST-KNOW

**WHY:** Typography inconsistent = app trông unprofessional. Factory pattern đảm bảo mọi text kế thừa base properties (letter-spacing, font family) và color luôn dynamic theo theme.

<!-- AI_VERIFY: base_flutter/lib/resource/app_text_styles.dart -->
```dart
const _defaultLetterSpacing = 0.03;

final _baseTextStyle = TextStyle(
  letterSpacing: _defaultLetterSpacing,
  fontFamily: Env.flavor == Flavor.test ? AppFonts.notoSansJP : null,
);

TextStyle style({required Color? color, required double? fontSize, ...}) {
  return _baseTextStyle.merge(TextStyle(color: color, fontSize: fontSize, ...));
}

TextStyle exampleTextStyle({required Color color}) => style(
  fontWeight: FontWeight.w700, fontSize: 48, height: 56 / 48, color: color,
);
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_text_styles.dart](./01-code-walk.md#3-app_text_stylesdart--typography-factory)

**EXPLAIN:**

**Merge pattern:**

```
_baseTextStyle { letterSpacing: 0.03, fontFamily: ... }
        ↓  .merge()
TextStyle { color: red, fontSize: 14, fontWeight: w500 }
        ↓  result
TextStyle { letterSpacing: 0.03, fontFamily: ..., color: red, fontSize: 14, fontWeight: w500 }
```

→ `merge()` = non-null fields trong argument **override** base. Null fields → giữ base value.
→ Mọi text style trong app **tự động** có `letterSpacing: 0.03` — consistency mà không repeat.

**Convention cho named text styles:**

```dart
TextStyle xxxTextStyle({required Color color}) => style(
  fontWeight: FontWeight.w700,
  fontSize: 48,
  height: 56 / 48,  // lineHeight / fontSize
  color: color,       // ← luôn required, dynamic theo theme
);
```

| Rule | Lý do |
|------|-------|
| `color` là required parameter | Force caller dùng theme color, không hard-code |
| `height` = ratio (56/48) | Match design spec (Figma: fontSize 48, lineHeight 56) |
| Top-level function | Short call syntax: `exampleTextStyle(color: color.black)` |

**Test font override:**

```dart
fontFamily: Env.flavor == Flavor.test ? AppFonts.notoSansJP : null,
```

→ Golden tests cần pixel-perfect → force specific font. Production: `null` → fallback to ThemeData fontFamily.

> 💡 **FE Perspective**
> **Flutter:** `_baseTextStyle.merge()` compose base token (letter-spacing, font-family) với specific style — factory `style()` function đảm bảo mọi text kế thừa base properties.
> **React/Vue tương đương:** Tailwind `@apply` composing base + custom, styled-components `css` helper, CSS `font: inherit` + override = same merge pattern.
> **Khác biệt quan trọng:** Flutter dùng immutable Dart object merge (`TextStyle.merge()`), CSS dùng cascade. Flutter = compile-time type checking, CSS = runtime resolution.

**PRACTICE:** Viết một `bodyTextStyle({required Color color})` với fontSize 14, fontWeight w400, height 20/14. Xác nhận nó inherit `letterSpacing: 0.03` từ `_baseTextStyle`.

---

## 4. Asset Generation & Type Safety 🟡 SHOULD-KNOW

**WHY:** Typo trong asset path → runtime crash (image not found). Generated code = compile-time safety. Biết gen flow → thêm asset mới đúng cách.

<!-- AI_VERIFY: base_flutter/lib/resource/app_images.dart -->
```dart
class $AssetsImagesGen {
  const $AssetsImagesGen();
  String get iconBack => 'assets/images/icon_back.svg';
  String get imageAppIcon => 'assets/images/image_app_icon.png';
  List<String> get values => [iconBack, iconClose, ...];
}

class Assets {
  const Assets._();
  static const $AssetsImagesGen images = $AssetsImagesGen();
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_images.dart](./01-code-walk.md#5-app_imagesdart--generated-asset-accessors)

**EXPLAIN:**

**Generation flow:**

```
1. Add file to assets/images/
2. Declare folder in pubspec.yaml: assets: [assets/images/]
3. Run: make ga  (→ dart run tools/gen_assets.dart .)
4. app_images.dart re-generated → new getter available
5. Use: Assets.images.newImage or image.newImage (via res.dart)
```

**Asset folder organization — rationale:**

| Folder | Nội dung | Lý do tách riêng |
|--------|---------|------------------|
| `assets/images/` | Static images (PNG, SVG, JPEG) | Code-gen tạo typed getters, render qua `Image.asset()` / `SvgPicture` |
| `assets/raw/` | JSON configs, data files | Không cần code-gen images, load qua `rootBundle.loadString()` |
| `assets/fonts/` | Custom typeface files (TTF, OTF) | Khai báo riêng trong `pubspec.yaml` `fonts:` section, không qua images gen |

→ Tách folder theo **cách sử dụng**, không theo loại file. Images cần gen, fonts cần pubspec registration, raw cần manual loading.

**Naming convention:**

| File name | Getter name | Rule |
|-----------|------------|------|
| `icon_back.svg` | `iconBack` | snake_case → camelCase |
| `image_app_icon.png` | `imageAppIcon` | Prefix `image_` / `icon_` preserved |
| `image_dark_background.jpeg` | `imageDarkBackground` | Full name converted |

**Base widgets cho rendering:**

```dart
// PNG/JPG → AssetGenImage
image.imageAppIcon.toAssetGenImage.image(width: 100, height: 100)
// → Image.asset('assets/images/image_app_icon.png', width: 100, height: 100)

// SVG → SvgGenImage
image.iconBack.toSvgGenImage.svg(width: 24, colorFilter: ...)
// → SvgPicture(SvgAssetLoader(...), width: 24, colorFilter: ...)
```

→ `.toAssetGenImage` / `.toSvgGenImage` = extension trên String (từ `base/`).

> 💡 **FE Perspective**
> **Flutter:** Generated asset accessors tạo type-safe getters cho mọi asset — typo trong asset path → compile error thay vì runtime crash.
>
> ⚠️ **Clarification**: `make ga` chạy `dart run tools/gen_assets.dart .` (custom script trong project), **không phải** `flutter_gen` package. Output là simple String constants, không phải `AssetGenImage` objects.
> **React/Vue tương đương:** Webpack asset modules / Vite `import.meta.glob` — `import icon from './assets/icon.svg'` cho compile-time check.
> **Khác biệt quan trọng:** Cùng principle shift error từ runtime → compile time. Flutter dùng code generation, JS bundler dùng import resolution.

**PRACTICE:** Chạy `make ga` → kiểm tra `app_images.dart` regenerated. Thử thêm file `assets/images/test.png` → `make ga` → xác nhận `test` getter xuất hiện.

---

## 5. Font Management 🟢 AI-GENERATE

**WHY:** Font misconfiguration = silent failure (hiện fallback font, không error). Hiểu pipeline: pubspec → AppFonts → ThemeData → TextStyle.

<!-- AI_VERIFY: base_flutter/lib/resource/app_fonts.dart -->
```dart
class AppFonts {
  AppFonts._();
  static const String cupertino = 'Cupertino';
  static const String notoSansJP = 'Noto_Sans_JP';
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_fonts.dart](./01-code-walk.md#4-app_fontsdart--font-family-constants)

**EXPLAIN:**

**Font pipeline:**

```
1. Font files:    assets/fonts/Noto_Sans_JP/static/NotoSansJP-Regular.ttf
2. pubspec.yaml:  fonts: [{ family: Noto_Sans_JP, fonts: [{asset: ..., weight: 400}] }]
3. AppFonts:      static const notoSansJP = 'Noto_Sans_JP';
4a. ThemeData:    fontFamily: AppFonts.notoSansJP  (Android only)
4b. TextStyle:    fontFamily: AppFonts.notoSansJP  (test only)
5. Widget:       Text('Hello') — inherits font from ThemeData
```

**Platform-specific strategy:**

| Platform | Font | Lý do |
|----------|------|-------|
| Android | `AppFonts.notoSansJP` | Custom font cho CJK, consistent rendering |
| iOS | `null` (system font — SF Pro) | iOS system font đã tốt, users expect native feel |
| Test | `AppFonts.notoSansJP` | Deterministic rendering cho golden tests |

**Failure mode:**

```dart
static const String notoSansJP = 'Noto_Sans_JP';
// Nếu pubspec.yaml ghi: family: NotoSansJP  (thiếu underscore)
// → KHÔNG error, KHÔNG warning → fallback system font → UI sai subtly
```

→ String phải **exact match** pubspec `family:` name. Lý do dùng constant: sai 1 chỗ → sửa 1 chỗ.

**PRACTICE:** Mở `pubspec.yaml` → tìm `fonts:` section → xác nhận mỗi `family:` name match AppFonts constant.

---

## 6. Convenience Getters & Global Access 🟡 SHOULD-KNOW

**WHY:** Boilerplate accessor lặp lại hàng trăm lần: `AppColors.current.black`, `Assets.images.iconBack`. Convenience getters = DX tốt hơn, code ngắn gọn hơn.

<!-- AI_VERIFY: base_flutter/lib/resource/res.dart -->
```dart
import '../index.dart';

AppColors get color => AppColors.current;
$AssetsImagesGen get image => Assets.images;
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § res.dart](./01-code-walk.md#6-resdart--convenience-top-level-getters)

**EXPLAIN:**

**Trước vs sau res.dart:**

```dart
// Trước (verbose):
Text('Hi', style: style(color: AppColors.current.black, fontSize: 14));
AssetGenImage(Assets.images.iconBack).image(width: 24);

// Sau (concise):
Text('Hi', style: style(color: color.black, fontSize: 14));
image.iconBack.toAssetGenImage.image(width: 24);
```

→ `color` → `AppColors.current` (luôn reflect theme hiện tại).
→ `image` → `Assets.images` (static access, không cần context).

**Trade-off:**

| Pro | Con |
|-----|-----|
| Ngắn gọn, dễ đọc | Top-level getter = implicit dependency |
| Consistent across codebase | IDE "Find References" khó hơn (tìm `color.` quá generic) |
| Barrel export → 1 import | `color` phụ thuộc `current` được set đúng trước khi dùng |

→ Pattern này chấp nhận trade-off vì: tần suất dùng **rất cao** (mỗi widget) + codebase đã có convention `BasePage` refresh `current` trước mỗi build.

> 💡 **FE Perspective**
> **Flutter:** Top-level getters (`color.black`, `color.red1`) là convenience accessors tới `AppColors.current` — phụ thuộc `current` được refresh bởi `BasePage.build()`.
> **React/Vue tương đương:** Global CSS variables `var(--color-black)`, Tailwind `text-black` resolves theo theme, hoặc `window.__theme.colors` pattern trong legacy FE.
> **Khác biệt quan trọng:** Flutter dùng Dart top-level variable (mutable static), CSS dùng cascade resolution. IDE "Find References" khó hơn với Flutter pattern vì `color.` quá generic.

**PRACTICE:** Grep `color.` trong codebase → xác nhận usage pattern. Thử viết `TextStyle s = style(color: color.red1, fontSize: 16)` → verify compile OK.

---

> 📋 Badge summary → xem [00-overview.md](./00-overview.md)

**Phân bố:** 🔴 ~50% · 🟡 ~33% · 🟢 ~17%

---

## Bonus: Dark/Light Theme Toggle 🟡 SHOULD-KNOW

**WHY:** Hầu hết production apps cần hỗ trợ dark mode. Hiểu cách toggle → implement feature toggle trong Settings page.

**Dark/Light toggle qua `ThemeMode`:**

```dart
// Trong MaterialApp:
MaterialApp(
  theme: AppThemes.lightTheme,       // light palette
  darkTheme: AppThemes.darkTheme,    // dark palette
  themeMode: themeMode,              // ← ThemeMode.light / dark / system
);
```

**3 giá trị `ThemeMode`:**

| ThemeMode | Behavior |
|-----------|----------|
| `ThemeMode.light` | Luôn dùng `theme` (light) |
| `ThemeMode.dark` | Luôn dùng `darkTheme` (dark) |
| `ThemeMode.system` | Theo system setting (iOS/Android) |

**Toggle pattern trong ViewModel:**

```dart
// 1. Lưu preference
await appPreferences.setDarkMode(isDark);

// 2. Update AppThemes state
AppThemes.currentAppThemeType = isDark ? AppThemeType.dark : AppThemeType.light;

// 3. Rebuild MaterialApp với ThemeMode mới
// Dùng StateProvider hoặc ValueNotifier để trigger rebuild
```

**Kết nối với codebase hiện tại:**
- `AppThemes.currentAppThemeType` — global state quyết định palette
- `AppColors.defaultAppColor` vs `AppColors.darkThemeColor` — 2 palette sẵn có
- `Theme.of(context).appColor` — accessor tự resolve theo `currentAppThemeType`

> 💡 **Tip:** Khi toggle theme, `AppColors.of(context)` trong `BasePage.build()` tự động refresh `current` → tất cả widget dùng `color.xxx` sẽ nhận palette mới.

---

📖 [Glossary](../_meta/glossary.md)
<!-- AI_VERIFY: generation-complete -->
