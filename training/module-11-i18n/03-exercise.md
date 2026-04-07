# Exercises — Thực hành Internationalization & Localization

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đọc xong [01-code-walk.md](./01-code-walk.md) và [02-concept.md](./02-concept.md).

---

## ⭐ Exercise 1: Trace l10n Data Flow

**Mục tiêu:** Trace toàn bộ flow từ JSON source → generated code → UI display cho string `l10n.login`.

### Hướng dẫn

1. Mở các file theo thứ tự: [slang.yaml](../../base_flutter/slang.yaml), [ja.i18n.json](../../base_flutter/lib/resource/l10n/ja.i18n.json), [app_string.g.dart](../../base_flutter/lib/generated/app_string.g.dart), [app_string_ja.g.dart](../../base_flutter/lib/generated/app_string_ja.g.dart), [login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart).
2. Điền vào bảng trace:

### Template

| # | Stage | File | Nội dung | Dòng |
|---|-------|------|----------|------|
| 1 | JSON source | ja.i18n.json | `"login": "???"` | ? |
| 2 | Config reads | slang.yaml | `translate_var: ???` | ? |
| 3 | Generated getter | app_string_ja.g.dart | `String get login => ???;` | ? |
| 4 | Top-level accessor | app_string.g.dart | `AppString get ??? => ...` | ? |
| 5 | Page usage | login_page.dart | `l10n.???` | ? |
| 6 | Runtime value | — | `"???"` (Japanese text) | — |

### Câu hỏi

- `l10n` là tên biến hay tên class? Nó được define ở đâu?
- Nếu đổi `translate_var: t` trong slang.yaml → `make ln` → code page cần đổi gì?
- `l10n.login` return type là gì? Compile-time hay runtime resolved?

### ✅ Checklist hoàn thành
- [ ] Điền đủ 6 stages trong bảng trace
- [ ] Trả lời 3 câu hỏi
- [ ] Hiểu tại sao slang.yaml `translate_var` quyết định tên accessor

---

## ⭐ Exercise 2: Add a New Simple String

**Mục tiêu:** Thêm string mới vào translation source → generate → sử dụng trong code. Full workflow.

### Hướng dẫn

**Step 1:** Mở [ja.i18n.json](../../base_flutter/lib/resource/l10n/ja.i18n.json). Thêm key mới (giữ alphabetical order):

```json
"profile": "プロフィール",
```

> ⚠️ Chú ý: thêm vào đúng vị trí alphabetical — sau `"passwordsAreNotMatch"`, trước `"reply"`.

**Step 2:** Chạy `make ln` trong thư mục `base_flutter/`:

```bash
cd base_flutter && make ln
```

**Step 3:** Verify generated code — mở [app_string_ja.g.dart](../../base_flutter/lib/generated/app_string_ja.g.dart):
- Tìm getter mới: `String get profile => 'プロフィール';`
- Confirm getter đúng tên, đúng value.

**Step 4:** Sử dụng trong code — mở [my_profile_page.dart](../../base_flutter/lib/ui/page/my_profile/my_profile_page.dart):
- Tìm chỗ phù hợp (ví dụ: `CommonAppBar` title)
- Thay hardcoded text (nếu có) bằng `l10n.profile`

**Step 5:** Build verify:

```bash
flutter build apk --debug 2>&1 | head -5
```

### Câu hỏi suy nghĩ
- Nếu thêm key nhưng **quên chạy `make ln`** → IDE báo lỗi gì khi dùng `l10n.profile`?
- Nếu thêm key vào JSON nhưng value để trống `"profile": ""` → generated getter ra sao? Build lỗi hay pass?
- Alphabetical order trong JSON — tại sao quan trọng cho team collaboration?

### ✅ Checklist hoàn thành
- [ ] Key thêm đúng vị trí alphabetical trong JSON
- [ ] `make ln` chạy thành công, không error
- [ ] Getter `profile` xuất hiện trong generated file
- [ ] `l10n.profile` compile thành công
- [ ] Trả lời 3 câu hỏi
- [ ] **Revert changes** sau khi hoàn thành (`git checkout -- .`)

---

## ⭐⭐ Exercise 3: Add a Parameterized String

**Mục tiêu:** Thêm string có parameter interpolation → verify generated method signature → sử dụng với named parameter.

### Hướng dẫn

**Step 1:** Thêm 2 parameterized strings vào [ja.i18n.json](../../base_flutter/lib/resource/l10n/ja.i18n.json):

```json
"welcomeUser": "ようこそ、$userName さん",
"itemCount": "$count 件のアイテムがあります",
```

**Step 2:** Chạy `make ln`.

**Step 3:** Mở generated file — verify method signatures:

```dart
// Expected:
String welcomeUser({required Object userName}) => 'ようこそ、${userName} さん';
String itemCount({required Object count}) => '${count} 件のアイテムがあります';
```

**Step 4:** Viết test snippet sử dụng cả hai:

```dart
// Trong bất kỳ page buildPage:
final welcome = l10n.welcomeUser(userName: 'Tanaka');
// → "ようこそ、Tanaka さん"

final items = l10n.itemCount(count: 5);
// → "5 件のアイテムがあります"
```

**Step 5:** Thử gọi thiếu parameter:

```dart
l10n.welcomeUser();  // → Compile error? Gì?
```

**Step 6:** Thử gọi sai type:

```dart
l10n.itemCount(count: [1, 2, 3]);  // → Compile/Runtime behavior?
```

### Câu hỏi suy nghĩ
- Parameter type là `Object` không phải `String` — tại sao slang generate `Object`?
- Nếu muốn restrict `count` phải là `int` → có cách nào không?
- So sánh: `"Error $code"` (slang) vs `"Error {code}"` (react-intl) — ưu nhược điểm mỗi syntax?

### ✅ Checklist hoàn thành
- [ ] 2 parameterized strings thêm đúng syntax (`$paramName`)
- [ ] `make ln` thành công
- [ ] Generated methods có `required Object paramName`
- [ ] Gọi với đúng params → output đúng giá trị
- [ ] Gọi thiếu params → compile error (verified)
- [ ] Trả lời 3 câu hỏi
- [ ] **Revert changes** sau khi hoàn thành

---

## ⭐⭐⭐ Exercise 4: AI Dojo — 🌍 Edge Case Finder

### 🤖 AI Dojo — i18n Edge Cases & Missing Translations

**Mục tiêu**: Dùng AI tìm edge cases trong i18n setup — missing translations, RTL issues, plural handling.

**Bước thực hiện**:

1. Copy danh sách keys từ [ja.i18n.json](../../base_flutter/lib/resource/l10n/ja.i18n.json) và nội dung [slang.yaml](../../base_flutter/slang.yaml).

2. Gửi prompt sau cho AI:

```
Đây là i18n setup của Flutter app dùng slang package, hiện tại chỉ có Japanese (ja).

Phân tích và tìm edge cases:
1. Keys nào cần plural forms mà đang thiếu? (ví dụ: "1 item" vs "5 items")
2. Keys nào có hardcoded number/date format — sẽ lỗi khi thêm locale khác?
3. Strings nào quá dài trong Japanese — có thể overflow UI trên màn hình nhỏ?
4. Nếu thêm Arabic (RTL) support — strings nào cần special handling?
5. Keys nào thiếu parameter mà logic code cần? (ví dụ: error message cần error code)

slang.yaml config:
[PASTE slang.yaml]

Translation keys (46 keys):
[PASTE ja.i18n.json]
```

3. Với mỗi edge case AI tìm được:
   - Verify bằng cách check code thực tế — key đó dùng ở đâu trong UI?
   - Edge case có thực sự gây bug hay chỉ theoretical?

4. Pick 2 edge cases thực tế nhất → viết fix (thêm/sửa key trong JSON).

**✅ Tiêu chí đánh giá**:
- [ ] AI tìm ≥ 3 edge cases có giá trị (không phải generic advice)
- [ ] Bạn verify ít nhất 2 edge cases — phân biệt issue thật vs AI overthinking
- [ ] AI nhận ra single-locale app vẫn cần plural handling cho Japanese (counter words)
- [ ] Bạn không blindly thêm tất cả suggestions — chỉ fix issues có impact thực tế

---

## 🔗 Quick Reference

| File | Đường dẫn |
|------|-----------|
| slang.yaml | [../../base_flutter/slang.yaml](../../base_flutter/slang.yaml) |
| ja.i18n.json | [../../base_flutter/lib/resource/l10n/ja.i18n.json](../../base_flutter/lib/resource/l10n/ja.i18n.json) |
| app_string.g.dart | [../../base_flutter/lib/generated/app_string.g.dart](../../base_flutter/lib/generated/app_string.g.dart) |
| app_string_ja.g.dart | [../../base_flutter/lib/generated/app_string_ja.g.dart](../../base_flutter/lib/generated/app_string_ja.g.dart) |
| my_app.dart | [../../base_flutter/lib/ui/my_app.dart](../../base_flutter/lib/ui/my_app.dart) |
| login_page.dart | [../../base_flutter/lib/ui/page/login/login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart) |
| main_page.dart | [../../base_flutter/lib/ui/page/main/main_page.dart](../../base_flutter/lib/ui/page/main/main_page.dart) |

→ Tiếp tục: [04-verify.md](./04-verify.md)

<!-- AI_VERIFY: generation-complete -->
