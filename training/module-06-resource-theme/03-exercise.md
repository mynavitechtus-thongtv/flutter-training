# Exercises — Thực hành Resource & Theme System

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 3](../module-03-common-layer/) (Config, Constant, Env) và đọc xong [01-code-walk.md](./01-code-walk.md).

---

## ⭐ Exercise 1: Trace Color Usage Flow

**Mục tiêu:** Trace toàn bộ flow từ color definition → theme registration → context accessor → UI usage.

### Hướng dẫn

1. Mở [app_colors.dart](../../base_flutter/lib/resource/app_colors.dart).
2. Chọn color `black3` — trace qua toàn bộ pipeline.
3. Điền bảng trace:

### Template

| Step | File | Code | Giá trị (light) | Giá trị (dark) |
|------|------|------|-----------------|----------------|
| 1. Define | `app_colors.dart` | `final Color black3` | ? | ? |
| 2. Light variant | `app_colors.dart` | `defaultAppColor` → `black3:` | ? | — |
| 3. Dark variant | `app_colors.dart` | `darkThemeColor` → `black3:` | — | ? |
| 4. Register | `app_themes.dart` | `lightTheme..addAppColor(...)` | `_appColorMap[light]` | `_appColorMap[dark]` |
| 5. Access | `app_colors.dart` | `of(context)` → `Theme.of(context).appColor` | ? | ? |
| 6. Cache | `app_colors.dart` | `current = appColor` | ? | ? |
| 7. Shortcut | `res.dart` | `color.black3` | ? | ? |

**Câu hỏi:**
- `black3` light = `0xFF272336` (dark purple), dark = `0xFFd8dcc9` (light sage). Tại sao đảo ngược contrast?
- Nếu gọi `color.black3` **trước** `AppColors.of(context)` lần đầu → chuyện gì xảy ra? (hint: `late`)
- `of(context)` trả về `AppColors` instance — tại sao cần cả return value **và** side-effect gán `current`?

### ✅ Checklist hoàn thành
- [ ] Điền bảng 7 steps với giá trị cụ thể
- [ ] Trả lời 3 câu hỏi
- [ ] Hiểu dual access pattern: `of(context)` vs `current`

---

## ⭐ Exercise 2: Add a New Text Style

**Mục tiêu:** Thêm `bodyLargeTextStyle` vào `app_text_styles.dart` — trải nghiệm text style factory pattern.

### Hướng dẫn

**Step 1:** Mở [app_text_styles.dart](../../base_flutter/lib/resource/app_text_styles.dart).

**Step 2:** Thêm text style mới theo design spec:

| Property | Value |
|----------|-------|
| fontSize | 16 |
| fontWeight | w400 (regular) |
| height | 24 / 16 = 1.5 |
| color | dynamic (required param) |

**Step 3:** Viết function:

```dart
TextStyle bodyLargeTextStyle({required Color color}) => style(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 24 / 16,
      color: color,
    );
```

**Step 4:** Sử dụng trong widget code:

```dart
Text(
  'Hello World',
  style: bodyLargeTextStyle(color: color.black),
)
```

**Step 5:** Verify:
- `letterSpacing` inherited từ `_baseTextStyle`? → check bằng debugger hoặc print `bodyLargeTextStyle(color: Colors.black).letterSpacing`.
- Thay `color.black` bằng `color.white` → text vẫn visible trên dark background?

### Câu hỏi suy nghĩ
- Tại sao `color` là **required** parameter thay vì optional với default?
- `height: 24 / 16` vs `height: 1.5` — có khác biệt gì? Nên dùng cách nào? Tại sao?
- Nếu design spec thêm `letterSpacing: 0.5` cho body text → override `_baseTextStyle` hay không? Trade-off?

### ✅ Checklist hoàn thành
- [ ] Function compile thành công
- [ ] `letterSpacing` = 0.03 (inherited)
- [ ] `fontFamily` = null (production) hoặc `Noto_Sans_JP` (test)
- [ ] Trả lời 3 câu hỏi
- [ ] **Revert changes** nếu không merge

---

## ⭐⭐ Exercise 3: Add a New Theme Color

**Mục tiêu:** Thêm `blue1` vào `AppColors` — trải nghiệm full pipeline: field → variants → usage.

### Hướng dẫn

**Step 1:** Thêm field vào `AppColors` constructor:

```dart
class AppColors {
  const AppColors({
    required this.white,
    required this.black,
    // ... existing fields
    required this.green1,
    required this.blue1,       // ← THÊM
  });

  // ... existing fields
  final Color green1;
  final Color blue1;           // ← THÊM
```

**Step 2:** Thêm vào cả hai variants:

```dart
static const defaultAppColor = AppColors(
  // ... existing
  green1: Colors.green,
  blue1: Color(0xFF2196F3),    // ← Material Blue
);

static const darkThemeColor = AppColors(
  // ... existing
  green1: Colors.green,
  blue1: Color(0xFF64B5F6),    // ← Lighter blue for dark theme
);
```

**Step 3:** Sử dụng:

```dart
Container(
  color: color.blue1,           // ← qua res.dart getter
  child: Text('Blue box'),
)
```

**Step 4:** Verify:
- Compile thành công (constructor requires tất cả fields → thiếu `blue1` ở bất kỳ variant nào = compile error).
- Đổi `AppThemes.currentAppThemeType = AppThemeType.dark` → `color.blue1` = `0xFF64B5F6`.
- Dùng `AppColors.of(context)` → `current.blue1` đúng theme.

### Câu hỏi suy nghĩ
- Constructor yêu cầu `required` cho tất cả fields → khi thêm field mới, compiler báo lỗi ở đâu? Lợi ích?
- `const` constructor + `const` instances (`defaultAppColor`, `darkThemeColor`) → có thể khai báo `blue1: computeBlue()` không? Tại sao?
- Nếu app có 50+ colors → constructor trở nên rất dài. Suggest pattern thay thế? (hint: `copyWith`, grouped sub-objects)

### ✅ Checklist hoàn thành
- [ ] `blue1` field có trong constructor `required`
- [ ] Cả `defaultAppColor` và `darkThemeColor` có `blue1`
- [ ] Code compile thành công
- [ ] `color.blue1` accessible qua `res.dart`
- [ ] Trả lời 3 câu hỏi
- [ ] **Revert changes** sau khi hoàn thành

---

## ⭐⭐⭐ Exercise 4: AI Dojo — 🎨 Design System Audit

### 🤖 AI Dojo — Accessibility Audit cho Theme System

**Mục tiêu**: Dùng AI kiểm tra accessibility của theme/color system — contrast ratios, font sizes, touch targets.

**Bước thực hiện**:

1. Copy light/dark color values từ [app_colors.dart](../../base_flutter/lib/resource/app_colors.dart) (phần `defaultAppColor` và `darkThemeColor`).

2. Gửi prompt sau cho AI:

```
Đây là color palette của Flutter app với light và dark theme variants.

Hãy audit accessibility:
- WCAG 2.1 AA contrast ratio (≥ 4.5:1 cho text, ≥ 3:1 cho large text)
  — check các cặp text color + background phổ biến
- Font sizes trong text styles có đủ lớn cho mobile không? (minimum 12sp)
- Có color nào quá giống nhau giữa light/dark gây confusing không?
- Suggest cải thiện cho 2 vấn đề accessibility nghiêm trọng nhất

Light theme colors:
[PASTE defaultAppColor values]

Dark theme colors:
[PASTE darkThemeColor values]

Text styles base fontSize: 14, range: 11-24
```

3. Kiểm tra AI output:
   - AI có tính đúng contrast ratio không? (verify 1-2 cặp bằng WebAIM Contrast Checker)
   - Suggestions có khả thi áp dụng vào codebase hiện tại không?

4. Hỏi follow-up: "Viết Dart code cụ thể để fix 1 color pair có contrast ratio thấp nhất."

**✅ Tiêu chí đánh giá**:
- [ ] AI phân tích ≥ 3 color pairs với contrast ratio cụ thể
- [ ] Bạn verify ít nhất 1 contrast ratio AI tính — đúng hay sai?
- [ ] AI nhận ra dark theme cần lighter text colors (không dùng cùng text color cho cả 2 themes)
- [ ] Bạn đánh giá: suggestion nào áp dụng được, suggestion nào quá lý tưởng cho production

---

## Exercise 5 — ⭐⭐ Theme Switch Rebuild Trace

<!-- AI_VERIFY: exercise-5-theme-rebuild -->

### Bối cảnh
Khi user switch theme (light ↔ dark), Flutter rebuild widgets. Câu hỏi: TOÀN BỘ widget tree rebuild hay chỉ widgets phụ thuộc theme?

> ⏭️ **Optional Exercise** — DevTools Rebuild Trace chưa được dạy ở module này. Exercise này **không bắt buộc** cho module completion. Hãy quay lại làm sau khi hoàn thành [Module 17 — Performance & Animation](../module-17-performance-animation/00-overview.md).

### Task
1. Mở DevTools → Performance Overlay
2. Switch theme từ Settings
3. Quan sát: bao nhiêu widgets rebuild? (hint: dùng `debugPrintRebuildDirtyWidgets = true` trong debug mode)
4. Trả lời: tại sao `const` widgets KHÔNG rebuild khi theme thay đổi?
5. Tìm 1 widget trong project dùng `Theme.of(context)` trực tiếp → nó có rebuild không?

### Acceptance Criteria
- [ ] Chụp screenshot DevTools showing rebuild count
- [ ] Giải thích được `const` widget immunity
- [ ] Xác định ít nhất 2 widgets rebuild vs 2 widgets KHÔNG rebuild khi switch theme

---

## Tổng kết Exercises

| # | Exercise | Concept covered | Độ khó |
|---|---------|----------------|--------|
| 1 | Trace Color Usage Flow | Color System, Theme Extension, Convenience Getters | ⭐ |
| 2 | Add New Text Style | Text Style Factory | ⭐ |
| 3 | Add New Theme Color | Color System, Theme Extension (full pipeline) | ⭐⭐ |
| 4 | AI Dojo — Design System Audit | Tất cả concepts — accessibility & critical thinking | ⭐⭐⭐ |
| 5 | Theme Switch Rebuild Trace | Theme Extension, const widget immunity, DevTools | ⭐⭐ |

→ Exercise 1-2 = trace & add theo pattern có sẵn. Exercise 3 = modify cross-file. Exercise 4 = evaluate AI output. Exercise 5 = DevTools observation & rebuild analysis.

<!-- AI_VERIFY: generation-complete -->
