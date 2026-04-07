# Concepts — Common Layer Deep Dive

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

---

## 1. Configuration Pattern 🔴 MUST-KNOW

**WHY:** Mọi feature flag, debug toggle đều phụ thuộc `Config`. Hiểu sai → log không hoạt động, feature bật sai môi trường.

<!-- AI_VERIFY: base_flutter/lib/common/config.dart -->
```dart
class Config {
  const Config._();
  static const enableGeneralLog = kDebugMode;
  static const isPrettyJson = kDebugMode;
  static const generalLogMode = [LogMode.all];
  static const printStackTrace = kDebugMode;
  static const enableDevicePreview = false;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § config.dart](./01-code-walk.md#configdart--debug-flags--feature-toggles)

**EXPLAIN:**

`Config` class áp dụng pattern **compile-time configuration**:

| Đặc điểm | Giải thích |
|-----------|------------|
| `const Config._()` | Private constructor → không instantiate → class = pure namespace |
| `static const` fields | Compile-time constants → compiler **inline** values, zero runtime cost |
| `kDebugMode` toggle | Flutter SDK constant → `true` (debug) / `false` (release) |
| Tree-shaking | Code trong `if (kDebugMode)` bị **xóa hoàn toàn** ở release build |

**Tại sao pattern này tốt hơn alternatives:**

```dart
// ❌ Approach 1: Global variable (mutable → side effects)
bool enableLog = true; // ai cũng đổi được

// ❌ Approach 2: Map-based config (no type safety)
final config = {'enableLog': true}; // no autocomplete
config['enbaleLog']; // typo → null, no compile error

// ✅ Approach 3: Static const class (project pattern)
class Config {
  static const enableGeneralLog = kDebugMode; // type-safe, immutable, tree-shakeable
}
```

**Config → downstream effect chain:**

```
Config.enableGeneralLog = kDebugMode
  └── Log._enableLog = Config.enableGeneralLog
       └── Log.d() / Log.e() check _enableLog
            └── Mọi nơi gọi Log.d("...") → hoạt động hay bị skip
```

**PRACTICE:** Mở [config.dart](../../base_flutter/lib/common/config.dart). Thay `enableDevicePreview = false` thành `kDebugMode`. Tìm nơi `enableDevicePreview` được dùng (hint: `my_app.dart`). Hiểu impact → revert lại.

---

## 2. Constants & Magic Number Avoidance 🔴 MUST-KNOW

**WHY:** Magic numbers/strings scatter khắp codebase = bug khi đổi, khó tìm, không consistent.

<!-- AI_VERIFY: base_flutter/lib/common/constant.dart -->
```dart
class Constant {
  const Constant._();
  static const initialPage = 1;
  static const itemsPerPage = 20;
  static const connectTimeout = Duration(seconds: 30);
  static const maxRetries = 3;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § constant.dart](./01-code-walk.md#constantdart--app-wide-constants)

**EXPLAIN:**

**Magic number** = giá trị literal xuất hiện trực tiếp trong code mà không rõ ý nghĩa:

```dart
// ❌ Magic numbers — đọc code không hiểu "20" là gì
final items = await api.getItems(page: 1, limit: 20);
await Future.delayed(Duration(seconds: 30));

// ✅ Named constants — rõ ràng
final items = await api.getItems(
  page: Constant.initialPage,
  limit: Constant.itemsPerPage,
);
await Future.delayed(Constant.connectTimeout);
```

**Quy tắc tổ chức Constant class:**

| Nhóm | Ví dụ | Tại sao nhóm riêng |
|------|-------|-------------------|
| Design | `designDeviceWidth = 375.0` | Responsive layout calculations |
| Paging | `initialPage = 1`, `itemsPerPage = 20` | API pagination params |
| Format | `fddMMyyyy = 'dd/MM/yyyy'` | Date formatting patterns |
| Duration | `snackBarDuration = Duration(seconds: 3)` | Animation/timeout durations |
| API | `connectTimeout`, `maxRetries` | Network configuration |
| Error codes | `invalidRefreshToken = 1300` | Server error code mapping |

**Duration type-safety (so với raw int):**

```dart
// ❌ Unsafe — 30 là seconds? milliseconds?
static const timeout = 30;

// ✅ Type-safe — rõ ràng đơn vị
static const connectTimeout = Duration(seconds: 30);
```

**PRACTICE:** Search `Constant.` trong codebase. Đếm bao nhiêu files reference `Constant`. Con số này cho thấy tầm quan trọng của việc tập trung constants.

---

## 3. Environment Management 🔴 MUST-KNOW

**WHY:** Multi-flavor builds là standard cho production app. Hiểu `Env` + `dart-define` để config đúng per-environment.

<!-- AI_VERIFY: base_flutter/lib/common/env.dart -->
```dart
enum Flavor { develop, qa, staging, production, test }

class Env {
  const Env._();
  static late Flavor flavor =
      Flavor.values.byName(const String.fromEnvironment(_flavorKey, defaultValue: 'test'));
  static const String appDomain =
      String.fromEnvironment(_appDomain, defaultValue: 'https://api.vn');

  static void init() {
    Log.d(flavor, name: _flavorKey);
    Log.d(appDomain, name: _appDomain);
  }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § env.dart](./01-code-walk.md#envdart--flavor--environment-variables)

**EXPLAIN:**

**Luồng inject environment variables:**

```
1. Developer tạo file:  dart_defines/develop.json
   {"FLAVOR": "develop", "APP_DOMAIN": "https://dev-api.vn"}

2. Build command:       flutter run --dart-define-from-file=dart_defines/develop.json

3. Compiler inline:     String.fromEnvironment('FLAVOR') → 'develop'
                        String.fromEnvironment('APP_DOMAIN') → 'https://dev-api.vn'

4. Runtime access:      Env.flavor → Flavor.develop
                        Env.appDomain → 'https://dev-api.vn'
```

**`const` vs `late` trong Env:** (xem giải thích `late` keyword tại [M0 § Variables & Types](../module-00-dart-primer/02-concept.md#1a-variables--var-final-const-late))

| Field | Keyword | Tại sao |
|-------|---------|---------|
| `appDomain` | `const` | `String.fromEnvironment()` = const constructor → compile-time |
| `flavor` | `late` | `Flavor.values.byName(...)` = runtime method call → không phải const |

**Enum Flavor — type-safe environment:**

```dart
// ❌ String-based (unsafe)
static const flavor = String.fromEnvironment('FLAVOR');
if (flavor == 'devlop') { ... } // typo → silent bug

// ✅ Enum-based (type-safe)
static late Flavor flavor = Flavor.values.byName(...);
if (flavor == Flavor.develop) { ... } // compile-time check
```

> 💡 **FE Perspective**
> **Flutter:** `--dart-define` inject values lúc compile → inline vào binary, không cần `.env` file lúc deploy, bảo mật hơn.
> **React/Vue tương đương:** `.env` files + `process.env` inject lúc build time, values embed vào JS bundle.
> **Khác biệt quan trọng:** Dart values inline vào binary (không readable). JS/TS `.env` values vẫn readable trong client bundle → cần cẩn thận với sensitive data.

**PRACTICE:** Mở [dart_defines/develop.json](../../base_flutter/dart_defines/develop.json) và [dart_defines/production.json](../../base_flutter/dart_defines/production.json). So sánh: key nào khác nhau? `Env.init()` log bao nhiêu values?

---

## 4. Logging System 🟡 SHOULD-KNOW

**WHY:** Debug logging là công cụ số 1 khi phát triển. Hiểu log system để dùng đúng level, filter đúng output.

<!-- AI_VERIFY: base_flutter/lib/common/util/log.dart -->
```dart
class Log {
  static void d(Object? message, {
    LogColor color = LogColor.yellow,
    LogMode mode = LogMode.normal, ...
  }) {
    if (!kDebugMode || ... ) return;
    _log('$message', color: color, name: name ?? '');
  }

  static void e(Object? errorMessage, {
    LogColor color = LogColor.red,
    Object? errorObject, StackTrace? stackTrace, ...
  }) { ... }
}

mixin LogMixin on Object {
  void logD(String message, ...) {
    Log.d(message, name: runtimeType.toString(), ...);
  }
}
```
<!-- END_VERIFY -->

> 💡 **FE Note**: `mixin on SomeClass` = "this mixin can ONLY be applied to classes extending SomeClass". Giống constraint trên HOC: `withAuth(Component)` chỉ accept components có certain props.
→ Đã đọc trong [01-code-walk § log.dart](./01-code-walk.md#logdart--logging-system)

**EXPLAIN:**

**2 cách sử dụng:**

| Cách | Khi nào | Ví dụ |
|------|---------|-------|
| `Log.d(message)` | Static call, top-level code, functions | `Log.d('App started')` |
| `with LogMixin` → `logD(message)` | Trong class cần auto-prefix class name | `logD('Loading...')` → `[HomeVM] Loading...` |

**Log guard hierarchy:**

```
Log.d() called
  ├── kDebugMode == false? → SKIP (release build)
  ├── _generalLogMode.isEmpty? → SKIP (log disabled)
  ├── mode not in _generalLogMode? → SKIP (filtered out)
  └── _log() → dev.log() → DevTools console ✅
```

**`dev.log()` vs `print()`:**

| Feature | `print()` | `dev.log()` |
|---------|-----------|------------|
| DevTools filter | ❌ all mixed | ✅ filter by `name` |
| Color support | ❌ | ✅ ANSI codes |
| Stack trace | Manual | Built-in `stackTrace` param |
| Production | Còn trong release | `kDebugMode` guard removes |

**LogColor ANSI codes:**

```
Log.d('Info', color: LogColor.yellow)   → vàng (default)
Log.e('Error', color: LogColor.red)     → đỏ (default errors)
Log.d('Success', color: LogColor.green) → xanh lá
```

**PRACTICE:** Trong [log.dart](../../base_flutter/lib/common/util/log.dart), trace chuỗi: `Config.enableGeneralLog` → `Log._enableLog` → `Log.d()` guard condition. Nếu `Config.enableGeneralLog = false`, có log nào hiện không?

---

## 5. Result Type & Sealed Classes 🟡 SHOULD-KNOW

### 5a. Basic `Result<T>` — Sealed Class + `when()`/`map()`

**WHY:** `Result<T>` là pattern xuyên suốt app — mọi API call, async operation đều return `Result`. Foundation cho error handling ở [M4](../module-04-exception-handling/).

<!-- AI_VERIFY: base_flutter/lib/common/type/result.dart -->
```dart
@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T data) = _Success;
  const factory Result.failure(AppException exception) = _Error;

  static Future<Result<T>> fromAsyncAction<T>(
      Future<T> Function() action) async {
    try {
      return Result.success(await action.call());
    } on AppException catch (e) {
      Log.e(e);
      return Result.failure(e);
    }
  }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § result.dart](./01-code-walk.md#resultdart--sealed-union-type-cho-error-handling)

> 📦 **@freezed Preview — Code Generation tạo gì?**
>
> Khi bạn viết `@freezed class Result<T>` rồi chạy `make fb` (build_runner), file `result.freezed.dart` được tạo với:
>
> | Generated | Mô tả |
> |-----------|--------|
> | `_$Result<T>` mixin | `copyWith`, `==`, `hashCode` — immutable value equality |
> | `_Success<T>` class | Concrete class từ `const factory Result.success(T data)` |
> | `_Error<T>` class | Concrete class từ `const factory Result.failure(AppException exception)` |
> | `.when()` | Pattern matching — **bắt buộc** handle tất cả cases |
> | `.map()` | Giống `when()` nhưng trả về wrapped typed value |
> | `.maybeWhen()` | Partial matching với `orElse` fallback |
>
> Bạn không cần hiểu generated code chi tiết ngay — chỉ cần biết pattern này là **code-gen**: viết 3 dòng, nhận ~200 dòng generated code.

**EXPLAIN:**

> 💡 **FE Perspective — Immutable Data Class & copyWith**
> 
> | Flutter | React / Vue |
> |---------|-------------|
> | `@freezed class` + code-gen | TypeScript `interface` + Immer.js `produce()` |
> | `copyWith(name: 'new')` (generated method) | `{ ...obj, name: 'new' }` spread operator / Immer `draft.name = 'new'` |
> | Deep equality by value (generated `==`) | Manual deep compare / lodash `isEqual` / `JSON.stringify` |
> | Compile-time immutability enforced | Convention-based: `Object.freeze()`, `readonly` in TS |
> | `toJson()` / `fromJson()` generated | `class-transformer` / manual serialization / Zod `.parse()` |

**Union type = either A or B, never both:**

```
Result<User>
  ├── Result.success(User) ← happy path
  └── Result.failure(AppException) ← error path
```

**Pattern matching (exhaustive check):**

> ℹ️ **Note:** `.when()` và `.map()` là methods được **freezed tự động generate** (trong file `result.freezed.dart`). Bạn không viết chúng — chạy `make fb` và chúng xuất hiện. Tương tự TypeScript discriminated union với exhaustive switch.

```dart
final result = await repository.getUser(id);

// Approach 1: when() — compiler forces handle BOTH cases
result.when(
  success: (user) => showUser(user),
  failure: (exception) => showError(exception),
);

// Approach 2: map() — return transformed value
final widget = result.map(
  success: (data) => UserCard(data.data),
  failure: (error) => ErrorWidget(error.exception.message),
);
```

**Ví dụ chạy được — cả success và failure path:**

```dart
// Success path:
final successResult = Result<String>.success('Hello Flutter');
successResult.when(
  success: (data) => print('Got: $data'),     // → Got: Hello Flutter
  failure: (error) => print('Error: $error'),
);

// Failure path:
final failureResult = Result<String>.failure(
  AppUncaughtException(), // hoặc bất kỳ AppException subtype
);
failureResult.when(
  success: (data) => print('Got: $data'),
  failure: (error) => print('Error: ${error.message}'), // → Error: UE-00
);

// map() — transform thành giá trị khác:
final message = successResult.when(
  success: (data) => 'User said: $data',
  failure: (error) => 'Failed: ${error.message}',
);
print(message); // → User said: Hello Flutter
```

**So sánh `.when()` vs `.map()`:**

| Method | Behavior | Return |
|--------|----------|--------|
| `.when(success:, error:)` | Destructure — truy cập trực tiếp giá trị bên trong | Giá trị bất kỳ (T) |
| `.map(success:, error:)` | Transform — wrap lại thành Result mới | `Result<NewType>` |

> 💡 Code trên chạy được trong context có `Result`, `AppUncaughtException` import. Trên DartPad cần define placeholder types.

> 🏁 **Checkpoint — Result<T> Basics**
> - [ ] Bạn hiểu `Success<T>` vs `Failure` sealed variants?
> - [ ] Bạn biết khi nào dùng `when()` vs `map()`?
> 👉 Nếu OK, tiếp tục Advanced patterns.

<details>
<summary>🔍 Advanced: <code>fromAsyncAction</code> helper & DartPad practice (click to expand)</summary>

### 5b. Advanced Patterns — `fromAsyncAction()` + Practical Scenarios

**`fromAsyncAction` — factory helper:**

```dart
// Thay vì viết try/catch ở mọi nơi:
Result<User> result;
try {
  final user = await api.getUser(id);
  result = Result.success(user);
} on AppException catch (e) {
  Log.e(e);
  result = Result.failure(e);
}

// Dùng factory helper — DRY:
final result = await Result.fromAsyncAction(() => api.getUser(id));
```

**Tại sao `Result` tốt hơn throwing exceptions:**

| Approach | Vấn đề |
|----------|--------|
| Throw + try/catch | Caller có thể **quên** catch → app crash |
| Return `null` | Không biết **lý do fail** → mất error info |
| Return `Result<T>` | Compiler **force** handle cả 2 cases → safe ✅ |

> 💡 **FE Perspective — Union Type / Sealed Class**
> 
> | Flutter | React / Vue |
> |---------|-------------|
> | `@freezed` sealed union: `Result.success` / `Result.failure` | TS discriminated union: `{ ok: true, data: T } \| { ok: false, error: E }` |
> | `when(success:, failure:)` — compiler-enforced exhaustive | `if (result.ok)` — type narrowing; exhaustive possible via `switch` + `never` default nhưng phải opt-in |
> | Adding new variant → compile errors at all call sites | Adding new union member → `switch` + `never` default sẽ báo lỗi, nhưng `if/else` chain thì không |
> | `map()` / `when()` / `maybeWhen()` generated helpers | Manual `switch` / `if-else` on discriminant field |
> | Pattern: `Result<T>`, `AsyncValue<T>` (Riverpod) | Pattern: `{ status, data, error }` in react-query / SWR |

> 💡 **FE Perspective**
> **Flutter:** `Result<T>` gom success data + failure error vào **1 object** — `when(success:, failure:)` compiler-enforced, không cần track `data` + `error` state riêng.
> **React/Vue tương đương:** `try/catch` + `useState(null)` cho data và error riêng, hoặc react-query `{ data, error, isLoading }`.
> **Khác biệt quan trọng:** `Result<T>` guarantee chỉ 1 trạng thái tại 1 thời điểm (success XOR failure). React useState có thể vô tình set cả data + error cùng lúc → inconsistent state.

> 💡 **Note:** react-query / TanStack Query solve this problem — so sánh trên chỉ áp dụng cho raw `useState` approach.

#### 🎮 Thử ngay trên DartPad

Copy đoạn code sau vào [DartPad](https://dartpad.dev) để chạy thử:

```dart
// Self-contained Result<T> example — paste vào DartPad
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);
}

// Simulate API call
Result<String> fetchUserName(bool shouldFail) {
  if (shouldFail) return const Failure('Network error');
  return const Success('Nguyen Van A');
}

void main() {
  final result = fetchUserName(false);

  // Pattern matching — Dart 3 syntax
  switch (result) {
    case Success(:final data):
      print('✅ Hello, $data!');
    case Failure(:final error):
      print('❌ Error: $error');
  }

  // Thử đổi false → true để thấy error case
  final errorResult = fetchUserName(true);
  switch (errorResult) {
    case Success(:final data):
      print('✅ Hello, $data!');
    case Failure(:final error):
      print('❌ Error: $error');
  }
}
```

> 💡 **Tip:** Thay `shouldFail` từ `false` → `true` để thấy cả 2 branches. Đây là foundation cho error handling ở M04.

**PRACTICE:** Mở [result.dart](../../base_flutter/lib/common/type/result.dart). Viết pseudo-code: nếu thêm case `Result.loading()` → cần sửa những gì? (Hint: `when()`, `map()` calls sẽ fail compile)

</details>

---

## 6. Extensions & Utility Patterns 🟡 SHOULD-KNOW

**WHY:** Extension methods là cách thêm functionality vào existing types **không cần subclass**. Project dùng extensively cho collections, BuildContext, nullable types.

<!-- AI_VERIFY: base_flutter/lib/common/util/extension.dart -->
```dart
extension NullableListExtensions<T> on List<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § extension.dart](./01-code-walk.md#extensiondart--extension-methods)

**EXPLAIN:**

**Extension method syntax:**

```dart
extension ExtensionName on TargetType {
  ReturnType get propertyName => ...;     // getter
  ReturnType methodName(params) => ...;   // method
}
```

**Nullable vs non-nullable extensions:**

```dart
// Extension on nullable type — handle null
extension NullableListExtensions<T> on List<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

// Extension on non-nullable type — this is never null
extension ListExtensions<T> on List<T> {
  List<T> plus(T element) => appendElement(element).toList(growable: false);
}
```

```dart
// Usage
List<String>? names;
names.isNullOrEmpty; // ✅ true — safe on null

List<String> items = ['a', 'b'];
items.plus('c'); // ✅ ['a', 'b', 'c'] — new list, immutable style
```

**`object_util.dart` — `safeCast` & `let`:**

<!-- AI_VERIFY: base_flutter/lib/common/util/object_util.dart -->
```dart
extension ObjectExt<T> on T? {
  R? safeCast<R>() {
    final that = this;
    if (that is R) return that;
    Log.e('Error: safeCast: $this is not $R');
    return null;
  }

  R? let<R>(R Function(T)? cb) {
    final that = this;
    if (that == null) return null;
    return cb?.call(that);
  }
}
```
<!-- END_VERIFY -->

**`let` pattern — transform if non-null:**

```dart
// Thay vì:
final user = getUser();
Widget? widget;
if (user != null) {
  widget = UserCard(user);
}

// Dùng let — concise:
final widget = getUser()?.let((u) => UserCard(u));
```

**Ví dụ cụ thể từ codebase `base_flutter`:**

```dart
// 1. NullableStringExtensions — check string null/empty an toàn
extension NullableStringExtensions on String? {
  bool get isNotNullAndNotEmpty => this != null && this!.isNotEmpty;
}
// Usage: if (userName.isNotNullAndNotEmpty) { ... }

// 2. BuildContextExtensions — shortcut cho Theme/FocusScope
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  FocusScopeNode get focusScope => FocusScope.of(this);
}
// Usage: final colors = context.theme.colorScheme;
//        context.focusScope.unfocus(); // dismiss keyboard

// 3. ListExtensions — immutable-style collection operations
extension ListExtensions<T> on List<T> {
  List<T> plus(T element) => appendElement(element).toList(growable: false);
  List<T> minus(T element) => exceptElement(element).toList(growable: false);
}
// Usage: final updated = selectedItems.plus(newItem);
//        final removed = selectedItems.minus(oldItem);
```

→ Xem đầy đủ: [extension.dart](../../base_flutter/lib/common/util/extension.dart), [object_util.dart](../../base_flutter/lib/common/util/object_util.dart)

**PRACTICE:** Viết extension method `truncate(int maxLength)` trên `String` — trả về string cắt ngắn với `...` nếu dài hơn `maxLength`. Test: `'Hello World'.truncate(5)` → `'Hello...'`.

---

## 7. Helper Architecture 🟢 AI-GENERATE

**WHY:** Hiểu pattern helper để biết đặt code mới ở đâu. Mỗi helper = 1 platform concern, registered qua DI.

<!-- AI_VERIFY: base_flutter/lib/common/helper/connectivity_helper.dart -->
```dart
@LazySingleton()
class ConnectivityHelper {
  Future<bool> get isNetworkAvailable async { ... }
  Stream<bool> get onConnectivityChanged { ... }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § helper/](./01-code-walk.md#helper--single-responsibility-helper-classes)

**Mini code walk — ConnectivityHelper (đầy đủ):**

```dart
// 1. Riverpod provider — bridge DI → UI
final connectivityHelperProvider = Provider<ConnectivityHelper>(
  (ref) => getIt.get<ConnectivityHelper>(),
);

// 2. Class — wrap connectivity_plus package
@LazySingleton()
class ConnectivityHelper {
  // Check hiện tại có mạng không
  Future<bool> get isNetworkAvailable async {
    final result = await Connectivity().checkConnectivity();
    return _isNetworkAvailable(result);
  }

  // Stream reactive — UI tự update khi mạng thay đổi
  Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged.map(_isNetworkAvailable);
  }

  // Private helper — logic tập trung 1 chỗ
  bool _isNetworkAvailable(List<ConnectivityResult> result) {
    if (result.length == 1 && result.first == ConnectivityResult.none) {
      return false;
    }
    return true;
  }
}
```

→ Pattern: `@LazySingleton` (DI) + Provider (Riverpod bridge) + single concern (chỉ connectivity). Mọi helper khác follow pattern tương tự.

**EXPLAIN:**

**Helper pattern trong project:**

```
Mỗi helper:
  1. @LazySingleton() → DI registration (1 instance, lazy)
  2. final xxxProvider = Provider<XxxHelper>(...) → Riverpod bridge
  3. Single-responsibility: 1 helper = 1 concern
  4. init() method (nếu cần) → gọi từ AppInitializer
```

| Helper | Concern | Package bên dưới |
|--------|---------|-----------------|
| `ConnectivityHelper` | Network status | `connectivity_plus` |
| `CrashlyticsHelper` | Crash reporting | `firebase_crashlytics` |
| `DeepLinkHelper` | Deep link handling | `uni_links` |
| `DeviceHelper` | Device info | `device_info_plus` |
| `PackageHelper` | App version info | `package_info_plus` |
| `PermissionHelper` | Runtime permissions | `permission_handler` |
| `AnalyticsHelper` | Event tracking | `firebase_analytics` |

**Tại sao wrap package vào helper:**
1. **Abstraction** — UI code không phụ thuộc trực tiếp vào `connectivity_plus` → dễ swap package.
2. **Testability** — mock `ConnectivityHelper` trong tests, không cần mock package.
3. **Centralized config** — logic check connectivity ở 1 chỗ.

> 💡 **FE Perspective**
> **Flutter:** Helper classes dùng `@LazySingleton` DI + Riverpod provider — mỗi helper = 1 platform concern (connectivity, crashlytics, deep link...), lazy init, injectable.
> **React/Vue tương đương:** Service layer classes registered trong Context/Provider, hoặc singleton modules import trực tiếp.
> **Khác biệt quan trọng:** Flutter helpers được DI container quản lý lifecycle + Riverpod bridge đến UI. FE services thường manual instantiate hoặc module singleton — khó mock trong tests.

**PRACTICE:** Liệt kê tất cả helpers trong `lib/common/helper/`. Cho mỗi helper, xác nhận: (1) có `@LazySingleton`? (2) có provider? (3) có `init()` method?

### Disposable Pattern

Nhiều helpers và services cần **cleanup khi không còn dùng** — đóng streams, cancel subscriptions, release resources. Trong Flutter, pattern này thường được implement qua `dispose()` method.

→ Pattern này được áp dụng trong BaseViewModel [M07](../module-07-base-viewmodel/00-overview.md) — nơi `dispose()` tự động close streams và cancel async operations khi ViewModel bị remove khỏi widget tree.

---

> 📋 Badge summary → xem [00-overview.md](./00-overview.md)

**Next:** Thực hành các concepts → [03-exercise.md](./03-exercise.md)

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
