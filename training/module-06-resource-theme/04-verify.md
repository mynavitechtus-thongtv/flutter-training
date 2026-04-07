# Verification — Kiểm tra kết quả Module 6

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được `AppColors` dùng **semantic naming** — `white` = primary background, không phải literal color? | Color System | 🔴 |
| 2 | Tôi trace được `of(context)` → `Theme.of(context).appColor` → `_appColorMap` lookup → return `AppColors`? | Theme Extension | 🔴 |
| 3 | Tôi tạo được text style mới bằng `style()` factory và xác nhận nó inherit `_baseTextStyle` properties? | Text Style Factory | 🔴 |
| 4 | Tôi mô tả được asset generation flow: add file → `make ga` → getter trong `app_images.dart`? | Asset Generation | 🟡 |
| 5 | Tôi biết font family string trong `AppFonts` phải **exact match** pubspec `family:` name? | Font Management | 🟢 |
| 6 | Tôi hiểu `res.dart` getters (`color`, `image`) phụ thuộc `AppColors.current` đã được set? | Convenience Getters | 🟡 |

**Target:** 3/3 Yes cho 🔴 MUST-KNOW, tối thiểu 5/6 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace Color Usage Flow ⭐

Đáp án tham khảo:

| Step | File | Code | Giá trị (light) | Giá trị (dark) |
|------|------|------|-----------------|----------------|
| 1 | `app_colors.dart` | `final Color black3` | (field declaration) | (field declaration) |
| 2 | `app_colors.dart` | `defaultAppColor` → `black3:` | `Color(0xFF272336)` | — |
| 3 | `app_colors.dart` | `darkThemeColor` → `black3:` | — | `Color(0xFFd8dcc9)` |
| 4 | `app_themes.dart` | `lightTheme..addAppColor(...)` | Registered in `_appColorMap[light]` | Registered in `_appColorMap[dark]` |
| 5 | `app_colors.dart` | `of(context)` | `defaultAppColor` | `darkThemeColor` |
| 6 | `app_colors.dart` | `current = appColor` | `current.black3` = `0xFF272336` | `current.black3` = `0xFFd8dcc9` |
| 7 | `res.dart` | `color.black3` | `0xFF272336` | `0xFFd8dcc9` |

**Verification points:**
- [ ] `black3` light = dark purple, dark = light sage → contrast đảo ngược phù hợp background
- [ ] Gọi `color.black3` trước `of(context)` → `LateInitializationError` vì `current` chưa được assign
- [ ] `of(context)` vừa return **và** gán `current` → dùng return value trong widget tree, `current` cho code ngoài tree

### Exercise 2 — Add New Text Style ⭐

- [ ] Function signature: `TextStyle bodyLargeTextStyle({required Color color})`
- [ ] Trả về `style(fontWeight: FontWeight.w400, fontSize: 16, height: 24 / 16, color: color)`
- [ ] `letterSpacing` = `0.03` (inherited từ `_baseTextStyle.merge()`)
- [ ] `fontFamily` = `null` (production), `Noto_Sans_JP` (test flavor)

**Câu hỏi answers:**
- [ ] `color` required → force caller dùng theme color, prevent hard-code `Colors.black`
- [ ] `height: 24 / 16` = `1.5` → **identical** result, nhưng `24 / 16` readable hơn (match Figma spec)
- [ ] `letterSpacing: 0.5` override base → acceptable nếu design spec khác base. Trade-off: specific style break global consistency — cân nhắc kỹ.

### Exercise 3 — Add New Theme Color ⭐⭐

- [ ] `blue1` field added: `final Color blue1;`
- [ ] Constructor: `required this.blue1` → **compiler báo lỗi** ở `defaultAppColor` và `darkThemeColor` nếu thiếu
- [ ] Light value: `Color(0xFF2196F3)` — Material Blue
- [ ] Dark value: `Color(0xFF64B5F6)` — Lighter blue cho contrast trên dark background
- [ ] `color.blue1` hoạt động qua `res.dart` → `AppColors.current.blue1`

**Câu hỏi answers:**
- [ ] Compiler báo lỗi tại **mọi nơi tạo `AppColors`** thiếu `blue1` → catching missing colors at compile time
- [ ] `const` constructor → tất cả fields phải là compile-time constants → `computeBlue()` **KHÔNG** được, chỉ literal/const expressions
- [ ] 50+ colors → group vào sub-objects: `AppColors.brand.primary`, `AppColors.neutral.grey1`. Hoặc dùng `copyWith` pattern.

### Exercise 4 — AI Prompt Dojo ⭐⭐⭐

- [ ] AI output ≥ 4/6 tiêu chí pass
- [ ] AI nhận diện extension pattern trade-off (simplicity vs no lerp/copyWith)
- [ ] AI flag `static late` concern (LateInitializationError nếu access trước init)
- [ ] AI **KHÔNG** suggest full rewrite sang Material 3 ColorScheme (existing codebase too large to migrate)
- [ ] AI nhận diện `_appColorMap` static concern (shared across ThemeData instances, mutation side effects)
- [ ] Bạn identify ≥ 1 điểm AI output sai hoặc thiếu context (ví dụ: AI có thể không biết `BasePage` refresh `current`)

---

## 3. Concept Cross-Check

| # | Scenario | Đáp án đúng | Concept |
|---|----------|-------------|---------|
| 1 | `AppColors.of(context)` khi theme = dark → `color.white` = ? | `Colors.black` (semantic: background) | Color System |
| 2 | `Theme.of(context).appColor` internally → lookup gì? | `_appColorMap[AppThemes.currentAppThemeType]` | Theme Extension |
| 3 | `style(color: null, fontSize: 14)` → `letterSpacing` = ? | `0.03` (from `_baseTextStyle.merge()`) | Text Style Factory |
| 4 | Thêm `assets/images/logo.svg` → cần làm gì? | `make ga` → `app_images.dart` regenerated → `image.logo` | Asset Generation |
| 5 | `AppFonts.notoSansJP` = `'Noto_Sans_JP'` nhưng pubspec ghi `NotoSansJP` → ? | Font **silent fail** → fallback system font, no error | Font Management |
| 6 | Gọi `color.black` khi `current` chưa init → ? | `LateInitializationError` crash | Convenience Getters |

---

## 4. Architecture Cross-Check

| Component | File | Scope | Used by |
|-----------|------|-------|---------|
| `AppColors` | `app_colors.dart` | Immutable color sets, static `current` | Themes, UI, res.dart |
| `AppThemes` | `app_themes.dart` | Theme state holder, ThemeData extension | MyApp `theme:` param |
| `style()` | `app_text_styles.dart` | Top-level factory function | All Text widgets |
| `AppFonts` | `app_fonts.dart` | Static font constants | ThemeData, TextStyle |
| `Assets` | `app_images.dart` | Generated asset paths | res.dart, UI widgets |
| `color`, `image` | `res.dart` | Top-level getters | Widget code everywhere |

**Kiểm tra:**
- [ ] `AppColors` → `AppThemes` → `ThemeData` → `MaterialApp.theme`: dependency flow rõ ràng
- [ ] `BasePage.build()` → `AppColors.of(context)` → refresh `current` → `res.dart` getters luôn đúng
- [ ] Barrel `index.dart` exports tất cả 9 resource files → single import cho consumer

---

## ➡️ Next Module

Hoàn thành Module 6! Bạn đã nắm vững Resource & Theme system.

→ Tiến sang **[Module 7 — Base ViewModel](../module-07-base-viewmodel/)** để học base UI framework pattern.

<!-- AI_VERIFY: generation-complete -->
