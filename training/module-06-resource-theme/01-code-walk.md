# Code Walk — Resource & Theme System

> 📌 **Recap từ modules trước:**
> - **M0:** Khai báo assets trong `pubspec.yaml`, chạy `make ga` để generate asset accessors ([M0 § assets](../module-00-dart-primer/01-code-walk.md))
> - **M2:** Barrel imports qua `index.dart`, resource layer nằm trong kiến trúc tổng thể, tất cả resource files export qua barrel ([M2 § barrel](../module-02-architecture-barrel/01-code-walk.md))
> - **M3:** `Config` flags (debug/production), `Constant` values (durations, sizes), `Env` flavor config — ảnh hưởng font selection và theme behavior ([M3 § config](../module-03-common-layer/01-code-walk.md))
>
> Nếu chưa nắm vững → quay lại [Module 0](../module-00-dart-primer/), [Module 2](../module-02-architecture-barrel/) hoặc [Module 3](../module-03-common-layer/) trước.

---

## Walk Order

```
app_colors.dart (color palette + light/dark variants)
    ↓
app_themes.dart (ThemeData + extension bridge)
    ↓
app_text_styles.dart (typography factory)
    ↓
app_fonts.dart (font family constants)
    ↓
app_images.dart (generated asset accessors)
    ↓
res.dart (convenience top-level getters)
```

Bắt đầu từ **colors** (design tokens) → **themes** (ThemeData wiring) → **text styles** (typography) → **fonts** (font families) → **images** (generated assets) → **res.dart** (global shorthand).

---

## 1. app_colors.dart — Color Palette & Theme Variants

<!-- AI_VERIFY: base_flutter/lib/resource/app_colors.dart -->
```dart
// ignore_for_file: avoid_hard_coded_colors
import 'package:flutter/material.dart';

import '../index.dart';

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

  final Color white;
  final Color black;
  final Color black2;
  final Color black3;
  final Color red1;
  final Color grey1;
  final Color grey2;
  final Color green1;

  static const defaultAppColor = AppColors(
    white: Colors.white,
    black: Colors.black,
    black2: Colors.black54,
    black3: Color(0xFF272336),
    red1: Colors.red,
    grey1: Colors.grey,
    grey2: Color(0xFFF2F2F2),
    green1: Colors.green,
  );

  static const darkThemeColor = AppColors(
    white: Colors.black,
    black: Colors.white,
    black2: Colors.white54,
    black3: Color(0xFFd8dcc9),
    red1: Colors.red,
    grey1: Colors.grey,
    grey2: Color(0xFFF2F2F2),
    green1: Colors.green,
  );

  static AppColors of(BuildContext context) {
    final appColor = Theme.of(context).appColor;
    current = appColor;
    return current;
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/resource/app_colors.dart`](../../base_flutter/lib/resource/app_colors.dart)

### Phân tích

**Immutable color set:**

| Thành phần | Mục đích |
|-----------|---------|
| `const AppColors({required ...})` | Constructor bắt buộc tất cả fields → không bao giờ thiếu color |
| `final Color white`, `black`, ... | Instance fields, immutable sau khi tạo |
| `static late AppColors current` | Singleton cache — giá trị mới nhất từ `of(context)` |

> ⚠️ **Cảnh báo `late`:** Nếu truy cập `AppColors.current` **trước khi** `of(context)` được gọi lần đầu (ví dụ: trong test hoặc early lifecycle code), Dart throw `LateInitializationError`. Luôn đảm bảo theme được initialize trong `MaterialApp.builder` trước khi dùng `AppColors.current`.

**Hai predefined variants:**

| Variant | `white` | `black` | `black3` | Còn lại |
|---------|---------|---------|----------|---------|
| `defaultAppColor` (light) | `Colors.white` | `Colors.black` | `0xFF272336` (dark purple) | Standard |
| `darkThemeColor` (dark) | `Colors.black` | `Colors.white` | `0xFFd8dcc9` (light sage) | **Đảo ngược** semantic |

→ Chú ý: `white` trong dark theme **là** `Colors.black`. Đây là **semantic naming** — `white` = "background color chính", không phải literal white.

**`of(BuildContext context)` — context-aware accessor:**

```dart
static AppColors of(BuildContext context) {
  final appColor = Theme.of(context).appColor;  // ← extension getter (xem app_themes.dart)
  current = appColor;                            // ← cache to static field
  return current;
}
```

→ Pattern giống `Theme.of(context)`, `MediaQuery.of(context)` — lấy resource từ widget tree.
→ Side effect: gán `current` — cho phép access **ngoài** widget tree qua `AppColors.current`.

**Nơi gọi `of(context)`:**

```dart
// base_page.dart — BasePage.build()
AppColors.of(context);  // ← gọi 1 lần trong mỗi page build
```

→ Mỗi page build → refresh `current` → tất cả code dùng `color.xxx` (qua `res.dart`) luôn đúng theme.

> 💡 **FE Perspective**
> **Flutter:** `AppColors` dùng `of(context)` để resolve design tokens từ `BuildContext` tại runtime — mỗi page build refresh `current` theo theme hiện tại.
> **React/Vue tương đương:** CSS custom properties (`:root { --color-white: #fff }`), `getComputedStyle()` resolve giá trị, Tailwind `theme.colors` config với `dark:` variant.
> **Khác biệt quan trọng:** Flutter resolve tại runtime qua Dart object (`AppColors.current`), CSS resolve tại paint time qua variables. Flutter cần explicit `of(context)` call, CSS custom properties tự resolve.

---

## 2. app_themes.dart — ThemeData + Custom Extension

<!-- AI_VERIFY: base_flutter/lib/resource/app_themes.dart -->
```dart
// ignore_for_file: avoid_hard_coded_colors
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../index.dart';

/// define custom themes here
final lightTheme = ThemeData(
  brightness: Brightness.light,
  splashColor: Colors.transparent,
  fontFamily: defaultTargetPlatform == TargetPlatform.android
      ? AppFonts.notoSansJP
      : null,
)..addAppColor(
    type: AppThemeType.light,
    appColor: AppColors.defaultAppColor,
  );

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  splashColor: Colors.transparent,
  fontFamily: defaultTargetPlatform == TargetPlatform.android
      ? AppFonts.notoSansJP
      : null,
)..addAppColor(
    type: AppThemeType.dark,
    appColor: AppColors.darkThemeColor,
  );

enum AppThemeType { light, dark }

extension ThemeDataExtensions on ThemeData {
  static final Map<AppThemeType, AppColors> _appColorMap = {};

  void addAppColor({
    required AppThemeType type,
    required AppColors appColor,
  }) {
    _appColorMap[type] = appColor;
  }

  AppColors get appColor {
    return _appColorMap[AppThemes.currentAppThemeType] ??
        AppColors.defaultAppColor;
  }
}

class AppThemes {
  const AppThemes._();
  static late AppThemeType currentAppThemeType = AppThemeType.light;
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/resource/app_themes.dart`](../../base_flutter/lib/resource/app_themes.dart)

### Phân tích

**Theme creation flow:**

```
ThemeData(brightness, splashColor, fontFamily)
    ↓ cascade (..)
addAppColor(type: light, appColor: defaultAppColor)
    ↓ registers in
_appColorMap[AppThemeType.light] = AppColors.defaultAppColor
```

**`ThemeDataExtensions` — extension on ThemeData:**

| Member | Loại | Mục đích |
|--------|------|---------|
| `_appColorMap` | `static final Map` | Shared storage — **tất cả** ThemeData instances dùng chung |
| `addAppColor()` | Method | Đăng ký color palette cho theme type |
| `appColor` | Getter | Lấy `AppColors` theo `currentAppThemeType` |

→ **Tại sao extension thay vì subclass ThemeData?** ThemeData là class của Flutter SDK, rất phức tạp. Extension cho phép attach custom data mà **không** thay đổi ThemeData hierarchy.

**Platform-specific font:**

```dart
fontFamily: defaultTargetPlatform == TargetPlatform.android
    ? AppFonts.notoSansJP
    : null,
```

→ Android: dùng `Noto_Sans_JP` (khai báo trong pubspec). iOS: `null` → dùng system font (San Francisco). Lý do: iOS system font đã tốt rồi, Android cần custom font cho CJK rendering.

**`AppThemes` — theme state holder:**

```dart
class AppThemes {
  const AppThemes._();                                  // private constructor
  static late AppThemeType currentAppThemeType = AppThemeType.light;
}
```

→ `late` + initial value → mutable singleton. Khi switch theme: `AppThemes.currentAppThemeType = AppThemeType.dark` → `appColor` getter trả về dark colors.

**Cascade operator `.."` pattern:**

```dart
final lightTheme = ThemeData(...)
  ..addAppColor(type: ..., appColor: ...);
```

→ `..` cascade gọi `addAppColor` trên ThemeData instance vừa tạo, rồi trả về chính ThemeData đó. Nếu dùng `.` → trả về `void`.

> 💡 **FE Perspective**
> **Flutter:** Extension trên `ThemeData` inject custom `AppColors` vào theme object có sẵn qua `addAppColor()` — `_appColorMap` là module-scoped storage, `appColor` getter resolve theo `currentAppThemeType`.
> **React/Vue tương đương:** styled-components `<ThemeProvider theme={{...defaultTheme, appColors}}>`, hoặc spread custom tokens vào theme object.
> **Khác biệt quan trọng:** Flutter dùng extension method pattern (OOP, compile-time), JS dùng object spread (runtime merge). `_appColorMap` là module-scoped variable (closure) — private nhưng shared.

> 💡 **Trade-off:** `_appColorMap` là shared global mutable state. React dev quen `ThemeProvider` scoped sẽ thấy lạ. Project chấp nhận vì chỉ switch light↔dark toàn app — không cần scope theme theo sub-tree.

### ThemeData Override Cascade — Thứ tự ưu tiên

Khi Flutter resolve style cho một widget, cascade từ thấp đến cao:

```
1. Base ThemeData(brightness, fontFamily, splashColor)      ← global defaults
       ↓ overridden by
2. ThemeData.copyWith(colorScheme: ..., textTheme: ...)     ← component-level overrides
       ↓ overridden by
3. Component themes (ElevatedButtonTheme, AppBarTheme, ...) ← per-widget-type defaults
       ↓ overridden by
4. Widget-level style (ElevatedButton(style: ...))          ← specific widget instance
```

| Level | Scope | Ví dụ trong codebase |
|-------|-------|---------------------|
| Base ThemeData | Toàn app | `ThemeData(brightness: Brightness.light, fontFamily: ...)` |
| copyWith | Toàn app (override base) | Hiện chưa dùng — extension thay copyWith |
| Component theme | Tất cả widget cùng type | Có thể thêm `elevatedButtonTheme:` trong ThemeData |
| Widget instance | Chỉ widget đó | `style(color: color.red1, fontSize: 14)` trên Text cụ thể |

→ Codebase dùng **extension pattern** (`addAppColor`) thay vì `copyWith` → simple nhưng bypass cascade level 2. Widget-level styles (qua `app_text_styles.dart`) là override cuối cùng.

---

## 3. app_text_styles.dart — Typography Factory

<!-- AI_VERIFY: base_flutter/lib/resource/app_text_styles.dart -->
```dart
// ignore_for_file: avoid_using_text_style_constructor_directly
import 'package:flutter/material.dart';

import '../index.dart';

const _defaultLetterSpacing = 0.03;

final _baseTextStyle = TextStyle(
  letterSpacing: _defaultLetterSpacing,
  fontFamily: Env.flavor == Flavor.test ? AppFonts.notoSansJP : null,
);

TextStyle style({
  required Color? color,
  required double? fontSize,
  Color? backgroundColor,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  String? fontFamily,
  List<String>? fontFamilyFallback,
  TextOverflow? overflow,
  List<Shadow>? shadows,
  Locale? locale,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
}) {
  return _baseTextStyle.merge(
    TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      // ... other fields
    ),
  );
}

TextStyle exampleTextStyle({required Color color}) => style(
      fontWeight: FontWeight.w700,
      fontSize: 48,
      height: 56 / 48,
      color: color,
    );
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/resource/app_text_styles.dart`](../../base_flutter/lib/resource/app_text_styles.dart)

### Phân tích

**Base style + merge pattern:**

```
_baseTextStyle (letterSpacing, fontFamily)
    ↓ .merge()
TextStyle(color, fontSize, fontWeight, ...)
    ↓ result
Final TextStyle = base properties + custom overrides
```

→ `merge()` giữ lại tất cả properties từ base, chỉ override những gì passed in. Đảm bảo **mọi text** trong app đều inherit `letterSpacing: 0.03`.

**Top-level function `style()`:**

| Design choice | Lý do |
|--------------|-------|
| Top-level function (không phải method trong class) | Gọi gọn: `style(color: c, fontSize: 14)` thay vì `AppTextStyles.style(...)` |
| `required Color? color` | Bắt buộc truyền nhưng cho phép `null` — explicit "tôi biết không có color" |
| `required double? fontSize` | Tương tự — luôn phải quyết định fontSize |

**Ví dụ factory function:**

```dart
TextStyle exampleTextStyle({required Color color}) => style(
  fontWeight: FontWeight.w700,   // bold
  fontSize: 48,                  // large heading
  height: 56 / 48,              // line-height = 56px
  color: color,                  // color truyền từ ngoài
);
```

→ Mỗi text style trong app là một function gọi `style()`. Convention: `xxxTextStyle({required Color color})` — color luôn dynamic theo theme.

**`height: 56 / 48` — line-height ratio:**

→ Flutter `TextStyle.height` là multiplier trên fontSize. `56 / 48 ≈ 1.167` → line-height = fontSize × 1.167.
→ Design spec thường cho pixel values (fontSize: 48px, lineHeight: 56px) → formula: `lineHeight / fontSize`.

**Test environment font:**

```dart
fontFamily: Env.flavor == Flavor.test ? AppFonts.notoSansJP : null,
```

→ Golden tests cần deterministic rendering → force font cụ thể. Production: `null` → inherit từ ThemeData.

> 💡 **FE Perspective**
> **Flutter:** `_baseTextStyle.merge()` compose base properties (letter-spacing, font-family) với custom overrides — `style()` function là factory tạo `TextStyle` consistent.
> **React/Vue tương đương:** Tailwind `@apply` composing base + custom classes, styled-components `css` helper composing base styles, CSS `font: inherit` + override.
> **Khác biệt quan trọng:** Flutter dùng Dart object merge (immutable `TextStyle.merge()`), CSS dùng cascade/specificity. Flutter factory function = single source of truth cho typography.

---

## 4. app_fonts.dart — Font Family Constants

<!-- AI_VERIFY: base_flutter/lib/resource/app_fonts.dart -->
```dart
class AppFonts {
  AppFonts._();

  /// Font family: Cupertino
  static const String cupertino = 'Cupertino';

  /// Font family: Noto_Sans_JP
  static const String notoSansJP = 'Noto_Sans_JP';
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/resource/app_fonts.dart`](../../base_flutter/lib/resource/app_fonts.dart)

### Phân tích

→ 9 dòng, đơn giản nhưng quan trọng: **single source of truth** cho font family names.

**Mapping với pubspec.yaml:**

```yaml
# pubspec.yaml
fonts:
  - family: Cupertino
    fonts:
      - asset: assets/fonts/Cupertino/CupertinoIcons.ttf
  - family: Noto_Sans_JP
    fonts:
      - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-Regular.ttf
        weight: 400
      # ... 100, 200, 300, 500, 600
```

| Constant | pubspec `family` | Dùng ở đâu |
|----------|-----------------|------------|
| `AppFonts.cupertino` | `Cupertino` | Icon font (CupertinoIcons) |
| `AppFonts.notoSansJP` | `Noto_Sans_JP` | Main text font (Android, tests) |

→ **Private constructor** `AppFonts._()` — prevent instantiation, chỉ dùng static constants.
→ String value **phải** match exact `family:` name trong pubspec — sai 1 ký tự → font silent fail (hiện fallback).

---

## 5. app_images.dart — Generated Asset Accessors

<!-- AI_VERIFY: base_flutter/lib/resource/app_images.dart -->
```dart
class $AssetsImagesGen {
  const $AssetsImagesGen();

  String get iconBack => 'assets/images/icon_back.svg';
  String get iconClose => 'assets/images/icon_close.svg';
  String get imageAppIcon => 'assets/images/image_app_icon.png';
  String get imageBackground => 'assets/images/image_background.png';
  String get imageDarkBackground => 'assets/images/image_dark_background.jpeg';

  /// List of all assets
  List<String> get values =>
      [iconBack, iconClose, imageAppIcon, imageBackground, imageDarkBackground];
}

class Assets {
  const Assets._();
  static const $AssetsImagesGen images = $AssetsImagesGen();
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/resource/app_images.dart`](../../base_flutter/lib/resource/app_images.dart)

### Phân tích

**Generated by `make ga`:**

```
assets/images/ folder scan
    ↓
dart run tools/gen_assets.dart .
    ↓
app_images.dart (auto-gen: type-safe getters)
```

→ Mỗi file trong `assets/images/` → 1 getter trả `String` path.
→ `$AssetsImagesGen` — prefix `$` = convention cho generated class (không sửa tay).

**`Assets` — entry point:**

```dart
Assets.images.iconBack    // → 'assets/images/icon_back.svg'
Assets.images.imageAppIcon // → 'assets/images/image_app_icon.png'
```

→ Type-safe: typo → compile error. So với `'assets/images/icn_back.svg'` → runtime error.

**`values` getter:**

```dart
List<String> get values => [iconBack, iconClose, ...];
```

→ Hữu ích cho preloading, cache warming. Iterate tất cả assets: `Assets.images.values.forEach(precacheImage)`.

**Base widget classes (`base/`):**

Project cung cấp `AssetGenImage` và `SvgGenImage` cho rendering:

```dart
// asset_gen_image.dart
'assets/images/image_app_icon.png'.toAssetGenImage.image(width: 100)
// → Image.asset('assets/images/image_app_icon.png', width: 100)

// svg_gen_image.dart
'assets/images/icon_back.svg'.toSvgGenImage.svg(width: 24)
// → SvgPicture(SvgAssetLoader(...), width: 24)
```

→ Extension methods `.toAssetGenImage` / `.toSvgGenImage` convert String path → widget wrapper.

---

## 6. res.dart — Convenience Top-Level Getters

<!-- AI_VERIFY: base_flutter/lib/resource/res.dart -->
```dart
import '../index.dart';

AppColors get color => AppColors.current;

$AssetsImagesGen get image => Assets.images;
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/resource/res.dart`](../../base_flutter/lib/resource/res.dart)

### Phân tích

→ 5 dòng, nhưng impact lớn — nơi nào cũng import `res.dart` (qua barrel `index.dart`):

```dart
// Không có res.dart:
Text('Hello', style: style(color: AppColors.current.black, fontSize: 14));
AssetGenImage(Assets.images.iconBack).image(width: 24);

// Với res.dart:
Text('Hello', style: style(color: color.black, fontSize: 14));
image.iconBack.toAssetGenImage.image(width: 24);
```

→ `color` → `AppColors.current` (giá trị từ lần gọi `of(context)` gần nhất).
→ `image` → `Assets.images` (generated image accessor).

**Barrel export trong `index.dart`:**

```dart
export 'resource/app_colors.dart';
export 'resource/app_fonts.dart';
export 'resource/app_images.dart';
export 'resource/app_shadows.dart';
export 'resource/app_text_styles.dart';
export 'resource/app_themes.dart';
export 'resource/base/asset_gen_image.dart';
export 'resource/base/svg_gen_image.dart';
export 'resource/res.dart';
```

→ Toàn bộ resource layer available qua `import '../index.dart';` — **một import** cho tất cả.

---

## 7. Resource Layer Overview — File Map

```
lib/resource/
├── app_colors.dart          ← color palette (58 lines)
├── app_fonts.dart            ← font constants (9 lines)
├── app_images.dart           ← GENERATED: asset getters (23 lines)
├── app_shadows.dart          ← shadow defs (empty — extend later)
├── app_text_styles.dart      ← typography factory (63 lines)
├── app_themes.dart           ← ThemeData + extension (46 lines)
├── res.dart                  ← convenience getters (5 lines)
└── base/
    ├── asset_gen_image.dart  ← Image.asset wrapper (60+ lines)
    └── svg_gen_image.dart    ← SvgPicture wrapper (60+ lines)
```

**Data flow tổng hợp:**

```
pubspec.yaml (font declarations, asset folders)
    ↓ make ga
app_images.dart (generated asset paths)

AppFonts (constants) ─────────┐
                               ↓
AppColors (color palette) ──→ app_themes.dart (ThemeData + extension)
                               ↓
_baseTextStyle ──────────────→ app_text_styles.dart (style factory)
                               ↓
BasePage.build() → AppColors.of(context) → refresh `current`
                               ↓
res.dart: `color`, `image` ──→ Used everywhere in UI code
```

---

## Tổng kết Code Walk

| File | Pattern chính | Kết nối |
|------|--------------|---------|
| `app_colors.dart` | Immutable color set + `of(context)` | → themes, res.dart |
| `app_themes.dart` | Extension on ThemeData + cascade init | → MyApp `theme:` param |
| `app_text_styles.dart` | Base style + merge factory | → tất cả Text widgets |
| `app_fonts.dart` | Font family constants | → themes, text styles |
| `app_images.dart` | Generated type-safe asset paths | → res.dart, UI widgets |
| `app_shadows.dart` | Shadow definitions (empty — extend later) | → barrel export, extend when needed |
| `res.dart` | Top-level getters shorthand | → consumed everywhere |

→ **Forward:** Module 9 sẽ dùng `color.xxx`, `style()` trực tiếp trong widget code. Module 10 sẽ kết hợp text styles với responsive sizing. Module 11 sẽ thêm i18n layer song song với resource layer.

<!-- AI_VERIFY: generation-complete -->
