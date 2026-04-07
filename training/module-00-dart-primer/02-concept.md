# Concepts — Dart Primer

> Tất cả concepts rút ra từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.
> Chi tiết thêm → [Dart Language Tour](https://dart.dev/language) · 📖 [Glossary](../_meta/glossary.md)

> 📋 **Sử dụng file này như cheat sheet** — không cần đọc tuần tự hết. Đọc phần nào liên quan đến exercise bạn đang làm, quay lại tra cứu khi cần.

---

# Part A — Toolchain & Project Configuration

## 1. Dart SDK & Version Constraints 🔴 MUST-KNOW

<!-- AI_VERIFY: base_flutter/pubspec.yaml#L6-L7 -->
```yaml
environment:
  sdk: ">=3.3.0 <4.0.0"
```
<!-- END_VERIFY -->

Dart dùng [semantic versioning](https://semver.org/). Constraint `>=3.3.0 <4.0.0`:
- **Minimum** SDK 3.3.0 — dùng features từ Dart 3.3 (records, patterns matching stable).
- **Upper bound** `<4.0.0` — chặn major version mới có thể breaking.

> 💡 **FE Perspective**
> **Flutter:** SDK constraint trong `pubspec.yaml` — Dart SDK = all-in-one (compiler + runtime + formatter + analyzer).
> **React/Vue:** `"engines": { "node": ">=18.0.0 <21.0.0" }` trong `package.json`.
> **Khác biệt:** Dart SDK all-in-one, không cần cài riêng như Node + TypeScript + Prettier + ESLint.

**PRACTICE:** `dart --version && flutter --version` → so sánh với constraint trong pubspec.yaml.

---

## 2. Dependency Management 🟡 SHOULD-KNOW

<!-- AI_VERIFY: base_flutter/pubspec.yaml#L9-L60 -->
```yaml
dependencies:
  auto_route: 10.3.0          # navigation — pinned exact
  dio: 5.8.0+1                # HTTP client
  flutter:
    sdk: flutter               # SDK dependency
  slang: 4.12.1               # i18n

dev_dependencies:
  build_runner: 2.7.0          # codegen engine
  freezed: 3.2.3               # gen immutable classes
  super_lint:
    path: super_lint            # local package
```
<!-- END_VERIFY -->

| Loại | Ý nghĩa | Ship vào app? |
|------|----------|---------------|
| `dependencies` | Runtime packages | ✅ Có |
| `dev_dependencies` | Build tools, test, lint | ❌ Không |
| `sdk: flutter` | Trỏ vào Flutter SDK | ✅ Có |
| `path: super_lint` | Local package trong repo | ❌ Dev only |

Ba điểm khác biệt lớn so với npm:
1. **Exact pinning** (`10.3.0`) thay vì range (`^10.3.0`) — tránh surprise breaking changes.
2. **Version `5.8.0+1`** — `+1` là build metadata (pub.dev revision), không ảnh hưởng semver.
3. **`_generator` pattern** — annotation (`freezed_annotation`) ở `dependencies`, generator (`freezed`) ở `dev_dependencies`.

> 💡 **FE Perspective**
> **Flutter:** Exact version pinning + `pubspec.lock` lock toàn bộ transitive deps.
> **React/Vue:** `npm install --save-exact`, `package-lock.json`.
> **Khác biệt:** Project này dùng exact pinning (`10.3.0` thay vì `^10.3.0`). Dart mặc định dùng `^` (tương tự `~` trong npm), nhưng team convention là exact pin để kiểm soát chặt dependency versions.

**PRACTICE:** Mở pubspec.yaml, tìm 3 cặp annotation + generator (`freezed_annotation` ↔ `freezed`, `json_annotation` ↔ `json_serializable`, `injectable` ↔ `injectable_generator`).

---

## 3. Code Generation Pipeline 🟡 SHOULD-KNOW

~40% file `.dart` trong project là generated. Không hiểu codegen = không hiểu nửa codebase.

<!-- AI_VERIFY: base_flutter/makefile#L20-L22 -->
```makefile
fb:
	dart run build_runner build --delete-conflicting-outputs
```
<!-- END_VERIFY -->
<!-- AI_VERIFY: base_flutter/build.yaml#L1-L7 -->
```yaml
targets:
  $default:
    sources:
      - lib/**
      - graphql/**
```
<!-- END_VERIFY -->

```
Source (.dart) + Annotation → build_runner → Generated (.g.dart / .freezed.dart)
```

- `build_runner` quét `sources` trong `build.yaml`, tìm file có annotation (`@freezed`, `@JsonSerializable`, `@injectable`).
- Mỗi generator tạo file với suffix convention: `.g.dart` (general), `.freezed.dart` (freezed), `.gr.dart` (auto_route).
- File generated liên kết với source qua `part` / `part of` — cùng library scope (truy cập `_private` members).
- `--delete-conflicting-outputs` xoá file gen cũ nếu conflict — **luôn dùng flag này**.

> 💡 **FE Perspective**
> **Flutter:** `build_runner` quét annotation → generate file cạnh source file, commit vào git.
> **React/Vue:** Gần nhất là GraphQL codegen — không có equivalent trực tiếp.
> **Khác biệt:** File generated nằm cạnh source file (không trong `dist/`) và commit vào git.

### PITFALLS
- ❌ **Không edit file `.g.dart`** — sẽ bị overwrite lần `make fb` tiếp theo.
- ❌ Quên chạy `make fb` sau khi thay đổi model → compile error vì file gen outdated.

---

## 4. Static Analysis & Type Safety 🔴 MUST-KNOW

<!-- AI_VERIFY: base_flutter/analysis_options.yaml#L21-L23 -->
```yaml
  language:
    strict-casts: true
    strict-raw-types: true
```
<!-- END_VERIFY -->
<!-- AI_VERIFY: base_flutter/analysis_options.yaml#L148-L155 -->
```yaml
linter:
  rules:
    - always_declare_return_types
    - prefer_const_constructors
    - prefer_final_locals
    - unawaited_futures
```
<!-- END_VERIFY -->

| Setting | Tác dụng | Ví dụ bị chặn |
|---------|----------|---------------|
| `strict-casts` | Cấm implicit cast | `Object x = "hi"; String s = x;` ❌ |
| `strict-raw-types` | Cấm raw generics | `List items = [];` ❌ → phải `List<String>` |
| `prefer_final_locals` | Var không reassign phải `final` | `var x = 1;` ❌ → `final x = 1;` |
| `unawaited_futures` | Future không `await` phải wrap `unawaited()` | `fetchData();` ❌ |

> 💡 **FE Perspective**
> **Flutter:** `strict-casts` + `strict-raw-types` enforce type safety tại compile time, không có escape hatch.
> **React/Vue:** TypeScript `strict: true` + `noImplicitAny`. ESLint plugin rules.
> **Khác biệt:** Dart có `dynamic` (≈ TS `any`) nhưng project lint rule `avoid_dynamic` chặn usage — type safety được enforce qua tooling convention, không chỉ language.

**PRACTICE:** Thử viết code vi phạm và chạy `flutter analyze`:
```dart
List items = [1, 2, 3];        // strict-raw-types violation
var name = 'hello';             // prefer_final_locals violation
```

---

## 5. Localization (i18n) Strategy 🟢 AI-GENERATE

Boilerplate i18n config — AI generate được, dev chỉ cần hiểu flow.

<!-- AI_VERIFY: base_flutter/slang.yaml#L1-L9 -->
```yaml
base_locale: ja
input_directory: lib/resource/l10n
input_file_pattern: .i18n.json
output_file_name: app_string.g.dart
class_name: AppString
translate_var: l10n
```
<!-- END_VERIFY -->

```
.i18n.json (key-value) → slang codegen → AppString class → l10n.someKey (autocomplete)
```

- Input: file JSON trong `lib/resource/l10n/` — Output: `lib/generated/app_string.g.dart`.
- Dùng trong code: `l10n.loginTitle` — **compile error nếu key không tồn tại**.

> 💡 **FE Perspective**
> **Flutter:** Slang gen type-safe class `AppString` — `l10n.loginTitle` với compile-time safety.
> **React/Vue:** `i18next` / `vue-i18n` với `t('login.title')` (string key, runtime error nếu sai).
> **Khác biệt:** Dart sai key = compile error, FE sai key = runtime error.

---

## 6. Toolchain Workflow 🟡 SHOULD-KNOW

<!-- AI_VERIFY: base_flutter/makefile#L35-L39 -->
```makefile
sync:           # Clone lần đầu / pull code mới
	make pg       # pub get (install deps)
	make ln       # gen localization
	make cc       # clean codegen
	make fb       # build codegen
```
<!-- END_VERIFY -->
<!-- AI_VERIFY: base_flutter/makefile#L57-L63 -->
```makefile
check_ci:       # Chạy trước khi push
	make check_pubs
	make check_page_routes
	make ep
	make fm
	make te
	make lint
```
<!-- END_VERIFY -->

| Khi nào | Chạy gì | Mục đích |
|---------|---------|----------|
| Clone / pull mới | `make sync` | Install deps + gen tất cả |
| Sửa model / route | `make fb` | Re-gen chỉ codegen |
| Trước khi push | `make check_ci` | Full check: format + test + lint |
| Lỗi lạ, muốn reset | `make ref` | Clean toàn bộ + rebuild from scratch |

| Target | Command thực tế | Khi nào dùng |
|--------|-----------------|--------------|
| `pg` | `flutter pub get` | Sau khi thêm dependency mới |
| `ln` | `dart run slang` | Sau khi sửa file i18n |
| `fb` | `build_runner build --delete-conflicting-outputs` | Sau khi sửa model/route |
| `cc` | `build_runner clean` | Xoá generated files |
| `ccfb` | `cc` → `fb` | Generated files bị conflict |
| `cl` | `flutter clean` + xoá lock files | Reset hoàn toàn |
| `sync` | `pg` → `ln` → `cc` → `fb` | Clone mới / pull mới |
| `ref` | `cl` → `sync` → `pu` → `pod` | Lỗi lạ, muốn reset từ đầu |
| `ep` | Auto-generate `index.dart` barrel | Sau khi tạo file mới |
| `fm` | `dart format` | Trước khi commit |
| `lint` | `dart analyze` + custom lint | Check code quality |
| `check_ci` | `fm` + `te` + `lint` + more | Trước khi push |

> 💡 **FE Perspective**
> **Flutter:** `make sync` + `make check_ci` là hai workflow chính.
> **React/Vue:** `npm ci && npm run build` cho sync, `npm run lint && npm test` cho CI.
> **Khác biệt:** Dart workflow có thêm bước codegen (`cc` + `fb`) mà FE không có.

---

## 7. Asset Management 🟢 AI-GENERATE

<!-- AI_VERIFY: base_flutter/pubspec.yaml#L83-L93 -->
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
  fonts:
    - family: Noto_Sans_JP
      fonts:
        - asset: assets/fonts/Noto_Sans_JP/static/NotoSansJP-Regular.ttf
          weight: 400
```
<!-- END_VERIFY -->

- **Assets:** Flutter include **tất cả file** trong folder — không cần list từng file.
- **Fonts:** Mỗi weight map đến file `.ttf`. `weight: 400` = `FontWeight.w400` = Regular.
- File asset **phải khai báo** trong `pubspec.yaml`. Quên khai báo → runtime error `Unable to load asset`.

> 💡 **FE Perspective**
> **Flutter:** Assets phải khai báo trong `pubspec.yaml` — quên = runtime error.
> **React/Vue:** Import trực tiếp hoặc webpack/Vite resolve tự động.
> **Khác biệt:** Flutter yêu cầu manifest tường minh — không khai báo = không tồn tại.

---

# Part B — Dart Language

> 📖 **Reading Pathway**: Part B dài ~600 dòng. Bạn KHÔNG cần đọc hết trong 1 buổi:
> - **Buổi 1**: Đọc group 1-3 (Variables → Functions → OOP basics). Đây là nền tảng.
> - **Buổi 2**: Đọc group 4-5 (Collections, Async, Advanced). Đọc khi cần tra cứu.
> - **Mọi lúc**: Dùng như **cheat sheet** — quay lại khi gặp syntax lạ trong modules sau.

### Group 1 — Types, Variables & Null Safety 🔴 MUST-KNOW

Mọi dòng code Dart bắt đầu từ khai báo biến và kiểu dữ liệu. Dart có **sound null safety** — compiler buộc xử lý `null` ngay lúc viết code.

#### 1a. Variables — `var`, `final`, `const`, `late`

```dart
void main() {
  var count = 0;          // inferred int — SAU ĐÓ KHÔNG ĐỔI KIỂU
  count = 10;             // ✅ OK
  // count = 'hello';     // ❌ COMPILE ERROR

  final now = DateTime.now(); // gán MỘT LẦN, runtime value OK
  // now = DateTime(2025);    // ❌ COMPILE ERROR

  const pi = 3.14159;        // COMPILE TIME — deeply immutable
  // const time = DateTime.now(); // ❌ ERROR

  late String authToken;      // khai báo trước, gán sau
  // print(authToken);        // ❌ RUNTIME ERROR nếu chưa gán
  authToken = 'Bearer abc123';
  print(authToken);           // ✅ OK

  String name = 'Dart';      // explicit type
}
```

> 💡 **FE Perspective**
> - `var` ≈ `let` nhưng **lock kiểu** sau lần gán đầu. JS `let x = 1; x = 'hi'` OK, Dart báo lỗi.
> - `final` ≈ JS `const` (gán 1 lần, runtime OK).
> - Dart `const` **không có tương đương JS** — compile-time, deeply immutable.
> - `late` ≈ khai báo rồi gán sau trong `useEffect`/`onMounted`, nhưng Dart kiểm tra runtime.

#### 1b. Null Safety — Sound Null Safety

```dart
void main() {
  String greeting = 'Hello';
  // greeting = null;  // ❌ COMPILE ERROR

  String? nickname;                    // cho phép null
  String display = nickname ?? 'Anonymous';       // null coalescing
  nickname ??= 'DefaultNick';                     // gán nếu đang null
  int? length = nickname?.length;                  // null-safe access
  print(nickname!.toUpperCase());                  // ! force unwrap (NGUY HIỂM)

  // Type promotion — compiler tự hiểu sau null check
  String? userName = getUserName();
  if (userName == null) return;
  print(userName.toUpperCase());       // ✅ auto-promoted sang String
}
String? getUserName() => 'Alice';
```

> 💡 **FE Perspective**
> - `String?` ≈ TS `string | null`. Dart **sound** = compiler ĐẢM BẢO 100% non-null ở chỗ không có `?`.
> - `??`, `?.` giống JS/TS. `!` ≈ TS `!` non-null assertion — **tránh dùng**.
> - **Type promotion** tự động: sau `if (x == null) return;`, compiler biết `x` non-null.

⚠️ **Gotcha:** Dart **không có `undefined`** — chỉ `null`. `!` crash runtime nếu null. Type promotion chỉ hoạt động với local variables — fields cần gán vào biến local trước.

#### 1c. String Interpolation & Type System

```dart
void main() {
  final name = 'World';
  print('Hello $name!');                 // $ cho biến đơn
  print('Next year: ${25 + 1}');         // ${} cho expression

  final html = '''
    <div><p>Hello $name</p></div>
  ''';                                   // multi-line string

  final regex = r'^\d{3}-\d{4}$';       // raw string — giữ nguyên backslash

  dynamic x = 42;    // ⚠️ = any — TẮT type checking (TRÁNH DÙNG)
  Object y = 42;     // top type AN TOÀN — phải check trước khi dùng
  if (y is int) print(y.isEven);  // ✅ auto-promoted
}
```

> 💡 **FE Perspective**
> - `'$var'` ≈ `` `${var}` `` — Dart dùng single quotes, không cần backtick.
> - `dynamic` ≈ `any`, `Object` ≈ `unknown`, `Never` ≈ `never`.

> 🏁 **Checkpoint – Types, Variables & Null Safety**
>
> Trước khi tiếp tục, hãy tự kiểm tra:
> - [ ] Bạn có thể giải thích sự khác nhau giữa `var`, `final`, `const` và `late` bằng lời của mình không?
> - [ ] Bạn có thể phân biệt `String` (non-null) và `String?` (nullable) không?
> - [ ] Bạn hiểu type promotion hoạt động thế nào sau `if (x == null) return;` không?
> - [ ] Thử viết một ví dụ nhỏ trong DartPad: khai báo biến nullable, dùng `??`, `?.` và `!`
>
> 👉 Nếu chưa chắc, hãy đọc lại phần trên trước khi tiếp tục.

---

### Group 2 — Collections & Functions 🔴 MUST-KNOW

#### 2a. Collections — List, Map, Set

```dart
void main() {
  final fruits = <String>['apple', 'banana', 'cherry'];
  fruits.add('date');                    // final = reference final, not content

  final scores = <String, int>{'alice': 95, 'bob': 87};
  int? aliceScore = scores['alice'];     // ⚠️ Trả về int? — key có thể không tồn tại

  final tags = <String>{'dart', 'flutter', 'dart'}; // duplicate bị loại

  // 🔥 Collection-if — thay conditional spread trong JSX
  final isAdmin = true;
  final menu = <String>['Home', 'Profile', if (isAdmin) 'Admin Panel'];

  // 🔥 Collection-for — thay .map() trong JSX
  final doubled = <int>[for (final n in [1, 2, 3]) n * 2];

  final moreItems = [...menu, 'Settings']; // spread giống JS
}
```

> 💡 **FE Perspective**
> - `List<T>` ≈ `T[]`. `Map<K,V>` ≈ `Record<K,V>`. `Set<T>` ≈ `Set<T>`.
> - `map['key']` luôn trả `T?` — Dart không có `undefined`, trả `null` nếu missing.
> - Collection-if/for **rất** hay dùng trong Flutter widget tree — thay `{isAdmin && <AdminPanel />}`.
> - `final list = [1,2,3]` — `final` chỉ lock reference! `list.add(4)` vẫn OK.

⚠️ **Gotcha:** `Map['key']` trả `T?` — luôn xử lý null. `final` không làm collection immutable (khác `Object.freeze()`).

#### 2b. Functions — Named Params, Arrow, Typedef

```dart
// Named parameters — pattern chủ đạo trong Flutter
void createUser({
  required String email,          // bắt buộc
  String role = 'member',         // default value
  int? age,                       // optional nullable
}) {
  print('Creating $email with role $role');
}

int add(int a, int b) => a + b;  // arrow = single expression

// First-class functions
int applyTwice(int value, int Function(int) fn) => fn(fn(value));

typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

void main() {
  createUser(email: 'alice@dev.com', role: 'admin', age: 30);
  print(applyTwice(2, (n) => n * 3)); // 18
}
```

> 💡 **FE Perspective**
> - Named params `{required String email}` ≈ TS destructured `{ email }: { email: string }`. **Bắt buộc `required`** cho non-null không có default.
> - Arrow `=> expr` giống JS — chỉ single expression.
> - `typedef` ≈ TS `type Fn = (x: number) => void`.
> - Flutter widgets dùng named params **ở khắp nơi**: `Text('Hello', style: TextStyle(fontSize: 16))`.

> 🏁 **Checkpoint – Collections & Functions**
>
> Trước khi tiếp tục, hãy tự kiểm tra:
> - [ ] Bạn có thể phân biệt `List`, `Map`, `Set` và khi nào dùng từng loại không?
> - [ ] Bạn hiểu tại sao `Map['key']` luôn trả về `T?` thay vì `T` không?
> - [ ] Bạn có thể viết collection-if và collection-for (thay thế conditional render trong JSX) không?
> - [ ] Thử viết một function với named parameters (`required`, default value, optional nullable) trong DartPad
>
> 👉 Nếu chưa chắc, hãy đọc lại phần trên trước khi tiếp tục.

---

### Group 3 — OOP: Classes, Inheritance & Mixins 🟡 SHOULD-KNOW

Flutter là OOP-heavy — mọi Widget, State là class. `extends`, `implements`, `with` xuất hiện ở mọi file.

#### 3a. Classes & Constructors

```dart
class ApiConfig {
  const ApiConfig({required this.baseUrl, this.timeout = const Duration(seconds: 30)});
  final String baseUrl;
  final Duration timeout;

  ApiConfig.dev() : this(baseUrl: 'https://dev.api.com');    // named constructor
  ApiConfig.prod() : this(baseUrl: 'https://api.com');

  factory ApiConfig.fromEnv(String env) => switch (env) {    // factory constructor
    'dev' => ApiConfig.dev(),
    'prod' => ApiConfig.prod(),
    _ => throw ArgumentError('Unknown env: $env'),
  };
}

class Counter {
  int _count = 0;             // private = _ prefix (library-level)
  int get count => _count;    // getter
  void increment() => _count++;
}
```

> 💡 **FE Perspective**
> - `this.baseUrl` ≈ TS `constructor(public baseUrl: string)` — auto-assign.
> - Named constructor `ApiConfig.dev()` ≈ TS static factory. Dart cho phép nhiều named constructors.
> - `const` constructor tạo compile-time object — Flutter dùng `const` widgets để tối ưu rebuild.
> - Private dùng `_` prefix — private ở **library level** (file), không phải class level.

#### 3b. Inheritance & Implements

```dart
abstract class AppException implements Exception {
  String get message;       // abstract getter — subclass PHẢI implement
}

class NetworkException extends AppException {       // extends = kế thừa
  NetworkException({required this.statusCode});
  final int statusCode;
  @override
  String get message => 'Network error: HTTP $statusCode';
}

class MockException implements AppException {       // implements = implement LẠI TẤT CẢ
  @override
  String get message => 'Mock error for testing';
  @override
  String toString() => 'MockException: $message';     // PHẢI override cả toString!
}
```

> 💡 **FE Perspective**
> - `extends` giống TS — kế thừa code, chỉ 1 superclass.
> - `implements` **khác TS**: Dart bắt override **TẤT CẢ** members (kể cả đã có implementation). TS chỉ bắt implement interface methods.
> - Dart không có `interface` keyword — mọi `class` có thể dùng làm interface qua `implements`.

#### 3c. Mixins

```dart
mixin LogMixin {
  void logInfo(String msg) => print('[INFO] $msg');
}

// 📌 DartPad examples dùng `print()` cho đơn giản. Trong project thực tế, dùng `Log.d()` (xem [Module 3](../module-03-common-layer/00-overview.md)) thay vì `print` để comply với `avoid_print` lint rule.

mixin CacheMixin {
  final Map<String, dynamic> _cache = {};
  void cacheData(String key, dynamic value) => _cache[key] = value;
  dynamic getCached(String key) => _cache[key];
}

// on — restrict mixin to specific superclass
mixin PaginationMixin on BaseViewModel {
  int _currentPage = 1;
  Future<void> loadNextPage() async { _currentPage++; await loadData(page: _currentPage); }
}

abstract class BaseViewModel { Future<void> loadData({int page = 1}); }

// Compose multiple mixins
class HomeViewModel extends BaseViewModel with LogMixin, CacheMixin, PaginationMixin {
  @override
  Future<void> loadData({int page = 1}) async {
    logInfo('Loading page $page');
    cacheData('page', page);
  }
}
```

> 💡 **FE Perspective**
> - Mixin **không có native equivalent** trong JS/TS. Gần nhất là HOC trong React.
> - `with A, B, C` "nối" nhiều behaviors — giải quyết single inheritance.
> - 2 mixins cùng method → **mixin cuối wins**. Mixins **không có constructor**.
>
> **TS tương đương:** TypeScript mixin pattern dùng intersection types + class expression: `type Constructor = new (...args: any[]) => {}; function Timestamped<T extends Constructor>(Base: T) { ... }`. Dart `mixin` ngắn gọn hơn và type-safe hơn.

#### 3d. Generics

```dart
class ApiResponse<T> {
  const ApiResponse({required this.data, required this.statusCode});
  final T data;
  final int statusCode;
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

sealed class Result<T> { const Result(); }
class Success<T> extends Result<T> { const Success(this.data); final T data; }
class Failure<T> extends Result<T> { const Failure(this.message); final String message; }

void main() {
  final response = ApiResponse<String>(data: 'Hello', statusCode: 200);
  // Dart generics are REIFIED — tồn tại ở runtime
  print(response is ApiResponse<String>);   // true ✅
  print(response is ApiResponse<int>);      // false ✅
}
```

> 💡 **FE Perspective**
> - Syntax giống TS: `class Box<T>`, `T extends SomeBase`.
> - **Khác biệt quan trọng:** Dart generics **reified** = runtime check. TS generics **erased** lúc compile.
> - `sealed class Result<T>` ≈ TS discriminated union — Dart compiler enforce exhaustive matching tự động.

> 🏁 **Checkpoint – OOP: Classes, Inheritance & Mixins**
>
> Trước khi tiếp tục, hãy tự kiểm tra:
> - [ ] Bạn có thể phân biệt `extends`, `implements` và `with` (mixin) không?
> - [ ] Bạn hiểu tại sao `implements` trong Dart bắt override TẤT CẢ members (khác TypeScript) không?
> - [ ] Bạn có thể giải thích mixin là gì và khi nào nên dùng thay vì inheritance không?
> - [ ] Thử viết một class đơn giản với `const` constructor và một mixin trong DartPad
>
> 👉 Nếu chưa chắc, hãy đọc lại phần trên trước khi tiếp tục.

---

### Group 4 — Async, Streams & Error Handling 🔴 MUST-KNOW

Mọi API call, database query, file I/O đều async. `Stream` power behind real-time updates, WebSocket, state management.

#### 4a. Future & Async/Await

```dart
Future<String> fetchUserName(int id) async {
  await Future.delayed(Duration(seconds: 1));
  if (id <= 0) throw ArgumentError('Invalid user ID: $id');
  return 'User_$id';
}

// Parallel execution — Future.wait = Promise.all
Future<void> loadDashboard() async {
  final results = await Future.wait([
    fetchUserName(1), fetchUserName(2), fetchUserName(3),
  ]);
  print('Loaded: $results');
}
```

#### 4b. Streams — Real-time Data

```dart
Stream<int> countdown(int from) async* {
  for (var i = from; i >= 0; i--) {
    await Future.delayed(Duration(seconds: 1));
    yield i;             // emit từng giá trị
  }
}

void main() async {
  await for (final value in countdown(3)) {
    print(value);  // 3, 2, 1, 0
  }

  final evenDoubled = Stream.fromIterable([1, 2, 3, 4, 5])
      .where((n) => n.isEven).map((n) => n * 2);
  await evenDoubled.forEach(print);    // 4, 8
}
```

> 💡 **FE Perspective**
> - `Future<T>` = `Promise<T>`. Cả `Future.wait` và `Promise.all` đều throw error đầu tiên gặp phải. Khác biệt là **timing**: `Future.wait` (default) chờ TẤT CẢ futures hoàn thành rồi mới throw, còn `Promise.all` reject ngay lập tức. Dùng `eagerError: true` để `Future.wait` cũng reject ngay — giống behavior của `Promise.all`. `Future.any()` = `Promise.race()`.
> - `Stream<T>` ≈ RxJS `Observable<T>` — **built-in**, không cần library. `.where()` = `.filter()`.
> - `async*` + `yield` tạo stream — giống JS generator nhưng cho async values.
> - Dart cảnh báo nếu quên `await` Future. JS cho phép floating promises silent.

#### 4c. Error Handling — Typed Catch

```dart
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
}

void main() async {
  try {
    final data = await fetchData('error-endpoint');
  } on ApiException catch (e) {
    print('API Error ${e.statusCode}: ${e.message}');  // typed catch
  } on FormatException catch (e) {
    print('Format error: $e');
  } catch (e, stackTrace) {
    print('Unknown: $e\nStack: $stackTrace');          // catch-all
  } finally {
    print('Done');
  }
}
```

> 💡 **FE Perspective**
> - `on Type catch (e)` = typed catch built-in. JS phải `catch(e) { if (e instanceof ...) }`.
> - `rethrow` giữ nguyên stack trace (khác `throw e` tạo stack mới).
> - `catch (e, stackTrace)` — tham số 2 là stack trace, JS phải dùng `e.stack`.

⚠️ **Gotcha:** Dart **không có unhandled promise rejection silent fail**. `on Type catch (e)` — viết `on` trước type, `catch` sau (không phải `catch (ApiException e)` như Java).

> 🏁 **Checkpoint – Async, Streams & Error Handling**
>
> Trước khi tiếp tục, hãy tự kiểm tra:
> - [ ] Bạn có thể phân biệt `Future` (single value) và `Stream` (multiple values) không?
> - [ ] Bạn hiểu `Future.wait()` tương đương `Promise.all()` và cách chạy async song song không?
> - [ ] Bạn có thể giải thích typed catch (`on Type catch (e)`) khác gì JS `catch(e)` không?
> - [ ] Thử viết một hàm `async` trả về `Future<String>` và một `Stream` đơn giản với `async*`/`yield` trong DartPad
>
> 👉 Nếu chưa chắc, hãy đọc lại phần trên trước khi tiếp tục.

---

### Group 5 — Dart 3: Enums, Patterns, Records, Extensions 🟢 AI-GENERATE

Dart 3 thêm features modern tương tự TypeScript nâng cao. Bạn sẽ gặp tất cả trong base_flutter.

#### 5a. Enhanced Enums

```dart
enum HttpMethod {
  get('GET'), post('POST'), put('PUT'), delete('DELETE');

  const HttpMethod(this.value);
  final String value;
  bool get isModifying => this == post || this == put || this == delete;
}

enum AppEnvironment {
  dev(apiUrl: 'https://dev.api.com', enableLogging: true),
  staging(apiUrl: 'https://staging.api.com', enableLogging: true),
  prod(apiUrl: 'https://api.com', enableLogging: false);

  const AppEnvironment({required this.apiUrl, required this.enableLogging});
  final String apiUrl;
  final bool enableLogging;
}
```

> 💡 **FE Perspective**
> - TS enums chỉ là numeric/string constants. Dart enhanced enums có fields, methods, constructors — giống mini-classes.
> - Enum values trong `switch` → compiler báo nếu thiếu case (exhaustive).

#### 5b. Extension Methods

```dart
extension StringValidation on String {
  bool get isEmail => RegExp(r'^[\w-\.]+@[\w-]+\.[\w-]{2,}$').hasMatch(this);
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}...';
}

extension NullableStringExt on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String orDefault(String fallback) => isNullOrEmpty ? fallback : this!;
}

void main() {
  print('alice@dev.com'.isEmail);           // true
  print('Hello World Dart'.truncate(10));   // Hello Worl...
  String? name;
  print(name.orDefault('Anonymous'));       // Anonymous
}
```

> 💡 **FE Perspective**
> - Thay vì `String.prototype.isEmail = ...` (mutate global), Dart extensions **scoped theo import** — an toàn.
> - Pattern phổ biến: `extension BuildContextExt on BuildContext { ... }`.

#### 5c. Pattern Matching & Sealed Classes

```dart
sealed class AuthState {}
class Unauthenticated extends AuthState {}
class Loading extends AuthState {}
class Authenticated extends AuthState {
  Authenticated(this.userName, this.token);
  final String userName;
  final String token;
}
class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}

// Switch expression — exhaustive, returns value
String describeState(AuthState state) => switch (state) {
  Unauthenticated() => 'Please log in',
  Loading() => 'Loading...',
  Authenticated(:final userName) => 'Welcome $userName',
  AuthError(:final message) => 'Error: $message',
};

String classifyAge(int age) => switch (age) {
  < 0 => 'Invalid',
  >= 0 && <= 12 => 'Child',
  >= 13 && <= 17 => 'Teen',
  >= 18 && <= 64 => 'Adult',
  _ => 'Senior',
};
```

> 💡 **FE Perspective**
> - `sealed class` ≈ TS discriminated union — Dart compiler **tự động enforce** exhaustive matching.
> - Switch **expression** (trả value) — TS chỉ có switch **statement**.
> - `if (x case SomeType(:final field))` thay thế `if (x is SomeType) { final field = x.field; }`.

#### 5d. Records

```dart
(int, String) getUserIdAndName() => (42, 'Alice');
({String email, int age}) getUserProfile() => (email: 'alice@dev.com', age: 25);

void main() {
  final (id, name) = getUserIdAndName();           // destructure positional
  final (:email, :age) = getUserProfile();         // destructure named
  print((1, 'a') == (1, 'a'));                     // true — structural equality
}
```

> 💡 **FE Perspective**
> - Positional `(int, String)` ≈ TS `[number, string]`. Named `({String a})` ≈ TS `{ a: string }`.
> - Records tự động **structural equality** — `(1, 'a') == (1, 'a')` là `true`. JS `[1,'a'] === [1,'a']` là `false`.
> - Records **immutable**. Use case: return multiple values mà không cần tạo class.

#### 5e. Cascade Notation (`..`)

```dart
class HttpRequest {
  String url = '';
  String method = 'GET';
  final Map<String, String> headers = {};
  String? body;
  void send() => print('$method $url');
}

void main() {
  final req = HttpRequest()
    ..url = 'https://api.com/users'
    ..method = 'POST'
    ..headers['Content-Type'] = 'application/json'
    ..body = '{"name": "Alice"}'
    ..send();

  // ?.. = null-aware cascade
  HttpRequest? maybeReq;
  maybeReq?..url = 'https://api.com'..send();
}
```

> 💡 **FE Perspective**
> - JS chaining cần mỗi method `return this`. Dart `..` **tự động trả object gốc**.
> - `..` trả object gốc, `.` trả return value. Pattern xuất hiện nhiều khi setup controllers, builders.

⚠️ **Gotcha:** `..` và `.` nhìn gần giống — 2 dots = cascade = trả object gốc.

---

## Cheat Sheet — Dart vs JavaScript/TypeScript

| # | Concept | Dart | JS / TS |
|---|---------|------|---------|
| 1 | Variable (reassign) | `var x = 1` | `let x = 1` |
| 2 | Constant (runtime) | `final x = fn()` | `const x = fn()` |
| 3 | Constant (compile) | `const x = 1` | `const x = 1` (no distinction) |
| 4 | Nullable type | `String?` | `string \| null` |
| 5 | Null coalescing | `a ?? b` | `a ?? b` |
| 6 | String interp | `'Hi $name'` | `` `Hi ${name}` `` |
| 7 | List / Array | `List<int>` | `number[]` |
| 8 | Map / Object | `Map<String, int>` | `Record<string, number>` |
| 9 | Named params | `fn({required int x})` | `fn({ x }: { x: number })` |
| 10 | Arrow function | `=> expr` | `=> expr` |
| 11 | Constructor | `MyClass(this.x)` | `constructor(public x: T)` |
| 12 | Interface | `abstract class` / `implements` | `interface` + `implements` |
| 13 | Mixin | `mixin M {}` + `with M` | No native equivalent |
| 14 | Generic | `class Box<T>` (reified) | `class Box<T>` (erased) |
| 15 | Enum + methods | `enum E { a; get x => ... }` | Not supported |
| 16 | Future | `Future<T>` + `async/await` | `Promise<T>` + `async/await` |
| 17 | Stream | `Stream<T>` + `async*`/`yield` | `Observable<T>` (RxJS) |
| 18 | Typed catch | `on Type catch (e)` | `catch(e) { if (e instanceof...) }` |
| 19 | Extension | `extension on Type {}` | `Type.prototype.method = ...` |
| 20 | Pattern match | `switch expr { case => }` | Not available (TC39 proposal) |
| 21 | Record / Tuple | `(int, String)` | `[number, string]` (TS) |
| 22 | Cascade | `..method()` | `return this` chaining |
| 23 | Top type (safe) | `Object` | `unknown` |
| 24 | Top type (unsafe) | `dynamic` | `any` |
| 25 | Bottom type | `Never` | `never` |

---

**Tiếp theo:** [Module 01 — App Entrypoint](../module-01-app-entrypoint/) sẽ đọc `main.dart` và `app_initializer.dart`.

<!-- AI_VERIFY: generation-complete -->
