# Exercises — Dart Language + Toolchain

> ⚠️ Bài tập Dart thực hiện trên [DartPad](https://dartpad.dev). Bài tập Toolchain thực hiện **trên codebase `base_flutter`**.

---

## Part A: Dart Language Exercises

### ⭐ Exercise 0A: Null Safety Drill

<!-- AI_VERIFY: exercise-0a -->

Thành thạo null safety operators. Mở [DartPad](https://dartpad.dev) và hoàn thành:

```dart
// 1. Khai báo nullable String, gán null
String? name = null;

// 2. Dùng ?? để cung cấp default value
String displayName = name ?? 'Anonymous';

// 3. Dùng ?. để gọi method an toàn
int? length = name?.length;

// 4. Viết function trả về nullable, caller dùng ! (force unwrap)
String? findUser(int id) => id == 1 ? 'Alice' : null;
String user = findUser(1)!;

// 5. Late initialization
late final String config;
config = 'production';
print(config);
```

**Bài tập:**
1. Viết function `String greet(String? name)` → return "Hello, {name}" hoặc "Hello, Guest" nếu null
2. Viết function `int safeParseInt(String? input)` → return parsed int hoặc 0 nếu null/invalid
3. Mở `base_flutter/lib/model/` — tìm 3 ví dụ sử dụng `?` và `required` trong class fields

### ✅ Checklist
- [ ] Viết được 2 functions trên DartPad không có lỗi
- [ ] Tìm được 3 nullable field ví dụ trong base_flutter

---

### ⭐ Exercise 0B: Class & Constructor Patterns

<!-- AI_VERIFY: exercise-0b -->

Đọc hiểu class patterns phổ biến trong `base_flutter`.

```dart
class ApiConfig {
  final String baseUrl;
  final int timeout;
  final bool enableLogging;

  const ApiConfig({
    required this.baseUrl,
    this.timeout = 30000,
    this.enableLogging = false,
  });

  factory ApiConfig.develop() => const ApiConfig(
    baseUrl: 'https://dev-api.example.com',
    enableLogging: true,
  );

  factory ApiConfig.production() => const ApiConfig(
    baseUrl: 'https://api.example.com',
    timeout: 10000,
  );
}

void main() {
  final dev = ApiConfig.develop();
  final prod = ApiConfig.production();
  print('Dev: ${dev.baseUrl}, logging: ${dev.enableLogging}');
  print('Prod: ${prod.baseUrl}, timeout: ${prod.timeout}');
}
```

**Bài tập:**
1. Thêm method `ApiConfig copyWith({String? baseUrl, int? timeout})` vào class trên
2. Mở `base_flutter/lib/` — tìm 2 class dùng factory constructor

### ✅ Checklist
- [ ] `copyWith` method chạy được trên DartPad
- [ ] Tìm được 2 factory constructor ví dụ trong base_flutter

---

### ⭐⭐ Exercise 0C: Async & Error Handling

<!-- AI_VERIFY: exercise-0c -->

Hiểu async patterns sẽ gặp trong mọi API call.

```dart
Future<String> fetchUserName(int id) async {
  await Future.delayed(Duration(seconds: 1));
  if (id <= 0) throw Exception('Invalid ID');
  return 'User_$id';
}

Future<void> main() async {
  // Happy path
  final name = await fetchUserName(1);
  print(name);

  // Error handling
  try {
    await fetchUserName(-1);
  } on Exception catch (e) {
    print('Error: $e');
  }

  // Future API style
  fetchUserName(2)
    .then((name) => print('Got: $name'))
    .catchError((e) => print('Failed: $e'));
}
```

**Bài tập:**
1. Viết function `Future<List<String>> fetchUsers(List<int> ids)` — gọi `fetchUserName` cho mỗi id, return list kết quả
2. Handle partial failure: nếu 1 id fail, vẫn return kết quả thành công (loop try/catch)
3. So sánh: `Future.wait` vs `Promise.all` — khác biệt gì khi 1 phần tử fail?

### ✅ Checklist
- [ ] `fetchUsers` chạy được
- [ ] Handle partial failure đúng (không throw nếu 1 id fail)

---

## Part B: Toolchain Exercises

## ⭐ Exercise 1: Trace the Dependency Tree

<!-- AI_VERIFY: exercise-1 -->

Hiểu pattern annotation ↔ generator — nền tảng của toàn bộ codegen pipeline.

Mở [pubspec.yaml](../../base_flutter/pubspec.yaml). Tìm annotation packages trong `dependencies` và generator tương ứng trong `dev_dependencies`. Điền bảng:

| # | Annotation Package | Section | Generator Package | Section | Mục đích |
|---|-------------------|---------|-------------------|---------|----------|
| 1 | `freezed_annotation` | ? | `freezed` | ? | ? |
| 2 | `json_annotation` | ? | `json_serializable` | ? | ? |
| 3 | `injectable` | ? | `injectable_generator` | ? | ? |
| 4 | `auto_route` | ? | `auto_route_generator` | ? | ? |
| 5 | `slang` | ? | `slang_build_runner` | ? | ? |

### ✅ Checklist
- [ ] Điền đầy đủ 5 dòng trong bảng
- [ ] Tất cả annotation packages nằm trong `dependencies`
- [ ] Tất cả generator packages nằm trong `dev_dependencies`
- [ ] Giải thích ngắn cột "Mục đích" cho mỗi cặp

---

## ⭐ Exercise 2: Run the Toolchain

<!-- AI_VERIFY: exercise-2 -->

Chạy thành công toolchain và nhận diện các file được generate.

```bash
cd base_flutter
make sync   # chạy 4 bước: pub get → slang gen → clean codegen → build codegen
```

Sau khi chạy xong, tìm file generated:
```bash
find lib -name "*.g.dart" -o -name "*.freezed.dart" -o -name "*.gr.dart" -o -name "*.config.dart" | head -20
```

Chạy lint: `make lint`

Ghi lại: bao nhiêu `.g.dart`? bao nhiêu `.freezed.dart`? `lib/generated/app_string.g.dart` tồn tại? `make lint` có error?

### ✅ Checklist
- [ ] `make sync` chạy thành công
- [ ] Liệt kê được ít nhất 5 file generated
- [ ] Xác nhận `app_string.g.dart` tồn tại
- [ ] `make lint` chạy thành công

---

## ⭐⭐ Exercise 3: Add a New Dependency

<!-- AI_VERIFY: exercise-3 -->

Thêm dependency vào project — flow tương đương `npm install <package>`.

1. Mở `pubspec.yaml`, thêm `url_launcher: ^6.3.1` vào phần `dependencies` thủ công (kiểm tra version mới nhất tại [pub.dev](https://pub.dev/packages/url_launcher))
2. Chạy `make pg` → `git diff pubspec.lock | head -30` để xem transitive deps
3. **Revert:** `git checkout pubspec.yaml pubspec.lock && make pg`

### ✅ Checklist
- [ ] Thêm `url_launcher` đúng syntax vào `dependencies`
- [ ] `make pg` thành công
- [ ] Quan sát diff của `pubspec.lock`
- [ ] Revert lại trạng thái ban đầu

---

## ⭐⭐ Exercise 4: Understand Lint Rules

<!-- AI_VERIFY: exercise-4 -->

Trải nghiệm custom lint rule — hiểu tại sao code bị reject khi push.

1. Đọc `analysis_options.yaml` → tìm rule `prefer_named_parameters` (threshold: 2)
2. Tạo file `lib/exercise_lint_test.dart`:
   ```dart
   // Exercise 4 — Test lint rule, xoá sau khi hoàn thành
   void sendNotification(String title, String body, String recipient) {
     // 3 positional params → vi phạm prefer_named_parameters
   }
   ```
3. `make lint` → observe warning
4. Refactor sang named parameters → `make lint` → confirm pass
5. `rm lib/exercise_lint_test.dart`

### ✅ Checklist
- [ ] Viết function vi phạm rule (3 positional params)
- [ ] `make lint` báo warning
- [ ] Refactor sang named parameters
- [ ] `make lint` pass
- [ ] Xoá file test

---

## ⭐⭐⭐ Exercise 5: Add a Localization Key (🤖 AI Prompt Dojo)

<!-- AI_VERIFY: exercise-5 -->

Dùng AI generate localization key, sau đó **đánh giá critically** output.

1. Đọc [ja.i18n.json](../../base_flutter/lib/resource/l10n/ja.i18n.json) — format: flat JSON, key camelCase, value tiếng Nhật. Config: [slang.yaml](../../base_flutter/slang.yaml).
2. Prompt AI:
   > *"Tôi có file `ja.i18n.json` dùng slang package trong Flutter. Format: flat JSON, key camelCase, value tiếng Nhật. Hãy thêm 2 key mới cho tính năng 'forgot password': một cho tiêu đề màn hình, một cho nút gửi email reset."*
3. **Đánh giá AI output:**

   | Tiêu chí | ✅ Đúng | ❌ Sai |
   |----------|--------|--------|
   | Key format camelCase? | `forgotPasswordTitle` | `forgot_password_title` |
   | Flat structure? | Top-level key | Nested `{ "forgotPassword": { ... } }` |
   | Value tiếng Nhật? | `パスワードをお忘れですか？` | `Forgot Password?` |
   | Không trùng key? | Key mới unique | Trùng key hiện có |
   | Key naming mô tả đúng ngữ cảnh? | `forgotPasswordTitle` (rõ màn hình + vai trò) | `title1` hoặc `forgot` (quá chung chung) |

4. Thêm key đã validate vào `ja.i18n.json` → `make ln` → `grep "forgotPassword" lib/generated/app_string.g.dart`
5. **Cleanup:** `git checkout lib/resource/l10n/ja.i18n.json && make ln`

### ✅ Checklist
- [ ] Dùng AI generate localization keys
- [ ] Đánh giá output AI theo 5 tiêu chí
- [ ] Thêm key vào `ja.i18n.json` đúng format
- [ ] `make ln` thành công
- [ ] Verify key trong `app_string.g.dart`
- [ ] Revert lại trạng thái ban đầu

---

## Tổng kết

| Exercise | Difficulty | Skill |
|----------|-----------|-------|
| 0A-0C | ⭐-⭐⭐ | Dart language fundamentals |
| 1 | ⭐ | Đọc hiểu pubspec.yaml |
| 2 | ⭐ | Chạy make commands |
| 3 | ⭐⭐ | Thêm package |
| 4 | ⭐⭐ | Lint rules |
| 5 | ⭐⭐⭐ | AI + evaluate + codegen |

> **Tip:** Sau mỗi exercise, `git status` để kiểm tra và `git checkout .` nếu muốn reset.

<!-- AI_VERIFY: generation-complete -->
