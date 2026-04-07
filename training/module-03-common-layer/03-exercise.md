# Exercises — Thực hành Common Layer

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 2](../module-02-architecture-barrel/) (barrel pattern, layer structure, DI basics).

---

## ⭐ Exercise 1: Trace Config Usage Chain

**Mục tiêu:** Hiểu cách `Config` class connect với các component khác — trace từ khai báo đến điểm sử dụng.

### Hướng dẫn

1. Mở [config.dart](../../base_flutter/lib/common/config.dart).
2. Chọn 3 config fields: `enableGeneralLog`, `enableLogInterceptor`, `enableNavigatorObserverLog`.
3. Với mỗi field, tìm **tất cả nơi sử dụng** trong codebase.
4. Điền bảng trace:

### Template

| Config field | File sử dụng | Cách sử dụng | Effect khi = false |
|-------------|-------------|-------------|-------------------|
| `enableGeneralLog` | `log.dart` → `Log._enableLog` | Guard trong `Log.d()` / `Log.e()` | ? |
| `enableLogInterceptor` | ? | ? | ? |
| `enableNavigatorObserverLog` | ? | ? | ? |

**Gợi ý command:**
```bash
cd base_flutter
grep -rn 'Config\.enableGeneralLog' lib/
grep -rn 'Config\.enableLogInterceptor' lib/
grep -rn 'Config\.enableNavigatorObserverLog' lib/
```

**Câu hỏi suy nghĩ:**
- Tất cả config fields dùng `kDebugMode` trừ `enableDevicePreview`. Tại sao `enableDevicePreview = false` hardcode?
- Nếu muốn enable logging cho **chỉ API calls** (không general log), cần thay đổi gì trong `Config`?

### ✅ Checklist hoàn thành
- [ ] Trace đủ 3 config fields
- [ ] Tìm được file + dòng code sử dụng cho mỗi field
- [ ] Mô tả được effect khi field = false
- [ ] Trả lời 2 câu hỏi suy nghĩ

---

## ⭐ Exercise 2: Env Flavor Investigation

**Mục tiêu:** Hiểu `dart-define` workflow — từ JSON file đến `Env.flavor` value.

### Hướng dẫn

1. Mở tất cả files trong [dart_defines/](../../base_flutter/dart_defines/):
   - `develop.json`
   - `qa.json`
   - `staging.json`
   - `production.json`

2. Điền bảng so sánh:

### Template

| Key | develop | qa | staging | production |
|-----|---------|-----|---------|------------|
| `FLAVOR` | ? | ? | ? | ? |
| `APP_DOMAIN` | ? | ? | ? | ? |
| `APP_BASIC_AUTH_NAME` | ? | ? | ? | ? |

3. Trace flow: `develop.json` → `flutter run --dart-define-from-file=...` → `Env.flavor` → `Env.init()` (log output).

4. Trả lời:

**Câu hỏi suy nghĩ:**
- Khi chạy `flutter test` **không có** `--dart-define`, `Env.flavor` = gì? Tại sao?
- `Env.appDomain` dùng `const` nhưng `Env.flavor` dùng `late`. Giải thích technical reason.
- Nếu team thêm flavor mới `demo`, cần sửa những file nào?

### ✅ Checklist hoàn thành
- [ ] Điền bảng so sánh 4 environments
- [ ] Trace được flow từ JSON → `Env.flavor`
- [ ] Trả lời đúng default flavor khi test
- [ ] Giải thích `const` vs `late` trong Env

---

## ⭐⭐ Exercise 3: Build a Result Pattern Consumer

**Mục tiêu:** Viết code sử dụng `Result<T>` — hiểu pattern matching và error handling flow.

### Scenario

Bạn đang viết một function trong ViewModel (sẽ học chi tiết ở [M7](../module-07-base-viewmodel/)) cần fetch user data và xử lý cả success/failure.

### Hướng dẫn

1. Đọc [result.dart](../../base_flutter/lib/common/type/result.dart) kỹ lại.
2. Viết **pseudo-code** (hoặc actual Dart code) cho các scenario sau:

> 💡 Scenario A dùng `Result<String>` để bạn có thể chạy trực tiếp trên DartPad. Scenario B, C nâng cấp lên `UserData` / `Post` — đây là **placeholder types giả định cho bài tập**, không tồn tại trong `base_flutter`.
>
> Dùng định nghĩa sau trên DartPad hoặc trong code bài tập:
> ```dart
> class UserData {
>   final int id;
>   final String name;
>   const UserData({required this.id, required this.name});
> }
>
> class Post {
>   final int id;
>   final String title;
>   final int userId;
>   const Post({required this.id, required this.title, required this.userId});
> }
> ```

**Scenario A — Basic pattern matching (`Result<String>`):**

```dart
// Cho:
Future<Result<String>> fetchUserName(int id);

// Viết code:
// 1. Gọi fetchUserName(1)
// 2. Dùng when() để:
//    - success → log user name, return name
//    - failure → log error, return null
```

**Scenario B — Chain multiple Results (nâng cấp lên typed models):**

```dart
// Cho:
Future<Result<UserData>> fetchUser(int id);
Future<Result<List<Post>>> fetchUserPosts(int userId);

// Viết code:
// 1. Fetch user
// 2. Nếu success → fetch posts (dùng user.id)
// 3. Nếu failure ở bất kỳ step → return failure
// Hint: nested when() hoặc mapAsync
```

**Scenario C — Dùng fromAsyncAction (so sánh với A):**

```dart
// Viết lại Scenario A dùng Result.fromAsyncAction
// So sánh: cần bao nhiêu dòng code? Error handling tự động?
```

### ✅ Checklist hoàn thành
- [ ] Scenario A: code compile-ready, handle cả 2 cases
- [ ] Scenario B: chain 2 async operations, propagate failure
- [ ] Scenario C: dùng `fromAsyncAction`, so sánh với A
- [ ] Giải thích: tại sao `Result` catch `on AppException` chứ không phải `catch (e)`?

---

## ⭐⭐ Exercise 4: Write an Extension Method

**Mục tiêu:** Tạo extension method mới — áp dụng pattern từ `extension.dart` và `object_util.dart`.

### Hướng dẫn

1. Tạo file `lib/common/util/string_util.dart` (hoặc viết trên giấy/editor).
2. Viết các extension methods sau:

**Yêu cầu:**

```dart
// Extension on String (non-nullable)
extension StringExtensions on String {
  /// Truncate string với "..." nếu dài hơn maxLength
  /// 'Hello World'.truncate(5) → 'Hello...'
  /// 'Hi'.truncate(5) → 'Hi'
  String truncate(int maxLength);

  /// Capitalize first letter
  /// 'hello world'.capitalizeFirst → 'Hello world'  
  String get capitalizeFirst;
}

// Extension on String? (nullable)
extension NullableStringExtensions2 on String? {
  /// Return this or default value
  /// null.orDefault('N/A') → 'N/A'
  /// 'hello'.orDefault('N/A') → 'hello'
  String orDefault(String defaultValue);
}
```

3. Viết test (mental test hoặc actual):

```dart
// Test cases
assert('Hello World'.truncate(5) == 'Hello...');
assert('Hi'.truncate(10) == 'Hi');
assert(''.truncate(5) == '');
assert('hello'.capitalizeFirst == 'Hello');
assert(''.capitalizeFirst == '');
assert(null.orDefault('N/A') == 'N/A');
assert('hello'.orDefault('N/A') == 'hello');
```

4. **Revert** — xóa file nếu đã tạo trong `base_flutter`:

```bash
rm lib/common/util/string_util.dart
make ep  # regenerate index.dart
```

### ✅ Checklist hoàn thành
- [ ] `truncate()` handle edge cases (empty string, maxLength > length)
- [ ] `capitalizeFirst` handle empty string
- [ ] `orDefault()` works on nullable String
- [ ] Pattern matching: so sánh extension style với project `extension.dart`
- [ ] Đã revert nếu tạo file trong base_flutter

---

## ⭐⭐⭐ Exercise 5: AI Prompt Dojo — Common Layer Review

**Mục tiêu:** Dùng AI để review common layer patterns — đánh giá output theo tiêu chí kỹ thuật.

### Prompt để gửi AI

Copy prompt dưới đây, gửi cho AI tool (Copilot Chat, ChatGPT, etc.):

```
Analyze this Flutter project's common layer structure:

lib/common/
├── config.dart        (debug flags using kDebugMode, static const)
├── constant.dart      (app-wide constants: URLs, timeouts, formats, error codes)
├── env.dart           (Flavor enum + String.fromEnvironment for dart-define)
├── controller/        (refocus_on_resume_controller)
├── helper/            (analytics, connectivity, crashlytics, deep_link, device, push_notification, package, permission)
├── hook/              (use_back_blocker, use_focus_node_refocus_on_resume)
├── type/              (big_decimal, result with freezed, typedef)
└── util/              (app_util, date_time_util, extension, file_util, log, object_util, view_util)

Key patterns:
1. Config: compile-time const, kDebugMode toggling, tree-shaking
2. Result<T>: @freezed union type (success/failure) with fromAsyncAction helper
3. Log: dev.log() wrapper with ANSI colors, LogMixin for auto class-name prefix
4. Helpers: @LazySingleton via injectable, Riverpod provider bridge
5. Extensions: nullable-safe, immutable collection operations, Kotlin-style let

Questions:
1. Is this common layer well-structured? Any redundancy?
2. Should Config use a different pattern (e.g., separate config per module)?
3. Is Result<T> approach better than pure exception handling for this project?
4. Compare this helper pattern with React's custom hooks / Vue's composables.
5. Suggest one improvement for the extension organization.
```

### Đánh giá AI output

Chấm điểm AI response theo 6 tiêu chí:

| # | Tiêu chí | Pass nếu | Fail nếu |
|---|---------|----------|----------|
| 1 | Nhận diện Config pattern | Nói đúng "compile-time const" + "tree-shaking" | Nhầm với runtime config |
| 2 | Hiểu Result type | Giải thích "union type" / "sealed class" pattern | Nói `Result` = exception wrapper |
| 3 | Log vs print | Phân biệt `dev.log()` vs `print()` | Suggest dùng `print()` |
| 4 | Helper DI pattern | Hiểu `@LazySingleton` + provider bridge | Suggest global instance |
| 5 | Extension scope | Biết extension scoped theo import | Suggest prototype modification |
| 6 | dart-define flow | Giải thích compile-time injection | Nhầm với runtime `.env` |

### Template ghi kết quả

```
AI Tool: ___________
Score: ___/6

| # | Tiêu chí | ✅/❌ | Ghi chú |
|---|---------|------|---------|
| 1 | Config pattern | | |
| 2 | Result type | | |
| 3 | Log vs print | | |
| 4 | Helper DI | | |
| 5 | Extension scope | | |
| 6 | dart-define | | |
```

### ✅ Checklist hoàn thành
- [ ] Gửi prompt cho AI
- [ ] Đánh giá theo 6 tiêu chí
- [ ] ≥ 4/6 pass
- [ ] Ghi chú AI response sai ở đâu (nếu có)
- [ ] AI **KHÔNG** suggest dùng `print()` thay `dev.log()`

---

## Exercise Summary

| # | Bài tập | Độ khó | Concept chính |
|---|---------|--------|--------------|
| 1 | Trace Config Usage | ⭐ | Configuration Pattern |
| 2 | Env Flavor Investigation | ⭐ | Environment Management |
| 3 | Build Result Pattern | ⭐⭐ | Result Type + Sealed Classes |
| 4 | Write Extension Method | ⭐⭐ | Extensions & Utilities |
| 5 | AI Prompt Dojo | ⭐⭐⭐ | All concepts |

**Next:** Kiểm tra kết quả → [04-verify.md](./04-verify.md)

<!-- AI_VERIFY: generation-complete -->
