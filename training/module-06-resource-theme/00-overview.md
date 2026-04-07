# Module 6: Resource & Theme System

## Tổng quan

Module này đi sâu vào **resource layer** — hệ thống quản lý colors, themes, typography, fonts và assets cho toàn app. Bạn sẽ đọc `AppColors` (color palette + light/dark variants), `AppThemes` (ThemeData + extension pattern), `app_text_styles.dart` (typography factory), `AppFonts` (font constants), `app_images.dart` (generated asset accessors), `res.dart` (convenience getters) — hiểu cách design tokens được define, wire vào Flutter theme system, và access từ UI code.

**Cycle:** CODE (đọc resource files) → EXPLAIN (hiểu patterns) → PRACTICE (trace + add + extend).

**Prerequisite:** Hoàn thành [Module 0 — Dart Primer](../module-00-dart-primer/) (assets in pubspec, `make ga` codegen), [Module 2 — Architecture](../module-02-architecture-barrel/) (barrel imports, resource layer trong kiến trúc), và [Module 3 — Common Layer](../module-03-common-layer/) (Config flags, Constant values, Env flavor).

---

## 🔄 Re-Anchor — Ôn lại M0-M3

| Module | Concept cần nhớ | Kết nối M6 |
|--------|-----------------|------------|
| **M0 — Dart Primer** | Assets declaration trong pubspec, `make ga` codegen | M6 giải thích **chi tiết** app_images.dart generated code + base widget classes |
| **M2 — Architecture** | Barrel imports (`index.dart`), resource layer structure | M6 đi sâu vào **nội dung** resource layer mà M2 chỉ map vị trí |
| **M3 — Common Layer** | `Config` flags, `Constant` values, `Env` flavor | M6 dùng `Env.flavor` trong text style, platform check trong theme |

→ Nếu bất kỳ concept nào chưa rõ → quay lại module tương ứng trước khi tiếp tục.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Giải thích được `AppColors` semantic naming — `white` trong dark theme là `Colors.black`?
2. Trace được `Theme.of(context).appColor` → extension getter → `_appColorMap` lookup?
3. Viết được text style mới bằng `style()` factory, xác nhận inherit `_baseTextStyle`?
4. Biết `make ga` flow: add image → generate → type-safe getter?
5. Hiểu `res.dart` getters phụ thuộc `AppColors.current` đã init?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 7 — Base ViewModel](../module-07-base-viewmodel/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

6 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | Color System & Semantic Naming | 🔴 MUST-KNOW | Immutable palettes, of(context), dual access |
| 2 | Theme Extension Pattern | 🔴 MUST-KNOW | ThemeData extension, _appColorMap, cascade init |
| 3 | Text Style Factory | 🔴 MUST-KNOW | Base merge, consistent typography |
| 4 | Asset Generation & Type Safety | 🟡 SHOULD-KNOW | make ga, $AssetsImagesGen, base widgets |
| 5 | Font Management | 🟢 AI-GENERATE | pubspec ↔ AppFonts, platform strategy |
| 6 | Convenience Getters & Global Access | 🟡 SHOULD-KNOW | res.dart DX pattern |

**Phân bố:** 🔴 ~50% · 🟡 ~33% · 🟢 ~17%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc app_colors → app_themes → app_text_styles → app_fonts → app_images → res.dart | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 6 concepts: color system, theme extension, text factory, asset gen, fonts, convenience | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 5 bài tập trace + add style + add color + AI review + theme rebuild | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + cross-check | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace Color Usage Flow | ⭐ |
| 2 | Add a New Text Style | ⭐ |
| 3 | Add a New Theme Color | ⭐⭐ |
| 4 | AI Prompt Dojo — Resource System Review | ⭐⭐⭐ |
| 5 | Theme Switch Rebuild Trace | ⭐⭐ |

---

## 🔓 Unlocks

Hoàn thành Module 6 mở khóa:

| Module | Sử dụng gì từ M6 |
|--------|-------------------|
| **M9 — Page Structure** | `color.xxx`, `style()`, `image.xxx` trực tiếp trong widget code |
| **M10 — Hooks** | Text styles kết hợp responsive sizing |
| **M11 — i18n** | i18n integration song song resource layer |

---

## 🔗 Liên kết

- [app_colors.dart](../../base_flutter/lib/resource/app_colors.dart) — color palette, light/dark variants (58 lines)
- [app_themes.dart](../../base_flutter/lib/resource/app_themes.dart) — ThemeData + extension pattern (46 lines)
- [app_text_styles.dart](../../base_flutter/lib/resource/app_text_styles.dart) — typography factory (63 lines)
- [app_fonts.dart](../../base_flutter/lib/resource/app_fonts.dart) — font family constants (9 lines)
- [app_images.dart](../../base_flutter/lib/resource/app_images.dart) — generated asset accessors (23 lines)
- [res.dart](../../base_flutter/lib/resource/res.dart) — convenience getters (5 lines)
- [base/asset_gen_image.dart](../../base_flutter/lib/resource/base/asset_gen_image.dart) — Image.asset wrapper
- [base/svg_gen_image.dart](../../base_flutter/lib/resource/base/svg_gen_image.dart) — SvgPicture wrapper
- [base_page.dart](../../base_flutter/lib/ui/base/base_page.dart) — `AppColors.of(context)` call site
- [index.dart](../../base_flutter/lib/index.dart) — barrel exports for resource layer (M2)

<!-- AI_VERIFY: generation-complete -->
