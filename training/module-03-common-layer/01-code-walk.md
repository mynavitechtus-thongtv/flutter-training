# Code Walk — Common Layer Deep Dive

> 📌 **Recap từ modules trước:**
> - **M0:** `pubspec.yaml` (deps, codegen pairs), `make sync` / `make ep` / `make fb` (automation), lint rules (`analysis_options.yaml`)
> - **M1:** `main()` → `AppInitializer.init()` → `configureInjection()` → `runApp(...)` (boot sequence), `Config` được dùng trong `main.dart`, DI init
> - **M2:** barrel file pattern (`index.dart` — 1 file export tất cả), import convention (3 nhóm), layer architecture (7 layers, `common/` = foundation layer)
>
> Nếu chưa nắm vững → quay lại [Module 0](../module-00-dart-primer/), [Module 1](../module-01-app-entrypoint/) hoặc [Module 2](../module-02-architecture-barrel/) trước.

---

## config.dart — Debug Flags & Feature Toggles

<!-- AI_VERIFY: base_flutter/lib/common/config.dart -->
```dart
import 'package:flutter/foundation.dart';

import '../../index.dart';

class Config {
  const Config._();

  static const enableGeneralLog = kDebugMode;
  static const isPrettyJson = kDebugMode;
  static const generalLogMode = [LogMode.all];
  static const printStackTrace = kDebugMode;

  /// provider observer
  static const logOnDidAddProvider = false;
  static const logOnDidDisposeProvider = kDebugMode;
  static const logOnDidUpdateProvider = false;
  static const logOnProviderDidFail = kDebugMode;

  /// navigator observer
  static const enableNavigatorObserverLog = kDebugMode;

  /// log interceptor
  static const enableLogInterceptor = kDebugMode;
  static const enableLogRequestInfo = kDebugMode;
  static const enableLogSuccessResponse = kDebugMode;
  static const enableLogErrorResponse = kDebugMode;

  /// device preview
  static const enableDevicePreview = false;
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/common/config.dart)

> 🔎 **Quan sát**
> - `const Config._()` — private constructor → **không thể instantiate**. Class này chỉ chứa `static const` fields → hoạt động như namespace cho config values.
> - `kDebugMode` — Flutter SDK constant: `true` khi chạy debug, `false` ở release/profile. → Compiler **tree-shake** code debug khi build release.
> - `static const` — compile-time constant → Dart compiler inline giá trị, không tạo runtime overhead.
> - `generalLogMode = [LogMode.all]` — list literal, **const** list → không tạo object mới mỗi lần access.
> - Nhóm config theo concern: general log → provider observer → navigator → interceptor → device preview.
> - `enableDevicePreview = false` — hardcode `false` (không dùng `kDebugMode`) → feature off cả debug lẫn release.
> - **Hỏi:** Tại sao dùng `kDebugMode` thay vì `assert()` hoặc `#if DEBUG` (C/C++ style)?

> 💡 **FE Perspective**
> **Flutter:** `Config` class dùng `static const` + `kDebugMode` (compile-time constant) — code debug bị **xóa hoàn toàn** ở release build, không chỉ skip execution.
> **React/Vue tương đương:** `config.ts` + `process.env.NODE_ENV === 'development'` — bundler (Webpack/Vite) **thay thế lúc build** thành string literal, sau đó minifier tree-shake dead branch.
> **Khác biệt quan trọng:** Dart `kDebugMode` là compile-time constant → compiler inline + tree-shake **guarantee** bởi language spec. JS `NODE_ENV` cũng bị thay lúc build nhưng do **bundler** (không phải language) — hầu hết bundler hiện đại (Webpack production, Vite) xử lý tốt, nhưng không phải language-level guarantee.

---

## constant.dart — App-Wide Constants

<!-- AI_VERIFY: base_flutter/lib/common/constant.dart -->
```dart
class Constant {
  const Constant._();
  static const imageHost = 'https://i.pinimg.com';

  // Design
  static const designDeviceWidth = 375.0;
  static const designDeviceHeight = 812.0;
  static const appMinTextScaleFactor = 0.9;
  static const appMaxTextScaleFactor = 1.3;

  // Paging
  static const initialPage = 1;
  static const itemsPerPage = 20;
  static const invisibleItemsThreshold = 3;

  // Format
  static const fddMMyyyy = 'dd/MM/yyyy';
  static const fHHmm = 'HH:mm';

  // Duration
  static const listGridTransitionDuration = Duration(milliseconds: 500);
  static const snackBarDuration = Duration(seconds: 3);

  // API config
  static const connectTimeout = Duration(seconds: 30);
  static const maxRetries = 3;
  static const firstRetryInterval = Duration(seconds: 1);

  // error codes, headers, paths...
  static const basicAuthorization = 'Authorization';
  static const jwtAuthorization = 'JWT-Authorization';
  static const bearer = 'Bearer';
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/common/constant.dart) (full ~128 lines)

> 🔎 **Quan sát**
> - Cùng pattern `const ClassName._()` → class = **namespace**, không có state.
> - Nhóm constants theo domain: Design → Paging → Format → Duration → URL → API → Error → Header.
> - `Duration(milliseconds: 500)` — Dart const constructor → compile-time Duration object, không allocate lúc runtime.
> - `static String get appApiBaseUrl => '${Env.appDomain}/api/'` — dùng **getter** (không phải `const`) vì phụ thuộc `Env.appDomain` (runtime value).
> - Magic numbers **tập trung 1 chỗ** — thay vì scatter `20` / `30` khắp codebase → đổi 1 chỗ, effect toàn project.
> - **Hỏi:** Tại sao `connectTimeout` là `Duration` object thay vì `int milliseconds = 30000`?

> 💡 **FE Perspective**
> **Flutter:** `Constant` class dùng `static const` với typed values — ví dụ `Duration(seconds: 30)` type-safe, không nhầm đơn vị seconds/milliseconds.
> **React/Vue tương đương:** `constants.ts` dùng `export const API_TIMEOUT = 30000` — raw number, phải comment đơn vị (ms).
> **Khác biệt quan trọng:** Dart có `Duration`, `Color` type-safe objects. JS dùng primitive types (number, string) → dễ nhầm đơn vị, phải convention-based.

---

## env.dart — Flavor & Environment Variables

<!-- AI_VERIFY: base_flutter/lib/common/env.dart -->
```dart
import '../index.dart';

enum Flavor { develop, qa, staging, production, test }

class Env {
  const Env._();

  static const _flavorKey = 'FLAVOR';
  static const _appBasicAuthNameKey = 'APP_BASIC_AUTH_NAME';
  static const _appBasicAuthPasswordKey = 'APP_BASIC_AUTH_PASSWORD';
  static const _appDomain = 'APP_DOMAIN';

  static late Flavor flavor =
      Flavor.values.byName(const String.fromEnvironment(_flavorKey, defaultValue: 'test'));
  static const String appBasicAuthName = String.fromEnvironment(_appBasicAuthNameKey);
  static const String appBasicAuthPassword = String.fromEnvironment(_appBasicAuthPasswordKey);
  static const String appDomain =
      String.fromEnvironment(_appDomain, defaultValue: 'https://api.vn');

  static void init() {
    Log.d(flavor, name: _flavorKey);
    Log.d(appBasicAuthName, name: _appBasicAuthNameKey);
    Log.d(appBasicAuthPassword, name: _appBasicAuthPasswordKey);
    Log.d(appDomain, name: _appDomain);
  }
}
```
<!-- END_VERIFY -->

> ⛔ **SECURITY ANTI-PATTERN — KHÔNG copy pattern này vào production!**
> Dòng `Log.d(appBasicAuthPassword, ...)` log password ra console — đây là lỗ hổng bảo mật nghiêm trọng.
> Trong dự án thật, bạn PHẢI:
> 1. **Xoá** dòng log password, hoặc
> 2. **Mask**: `Log.d('${'*' * appBasicAuthPassword.length}', name: _appBasicAuthPasswordKey)`
>
> Đây là limitation của training codebase, KHÔNG phải best practice.

→ [Mở file gốc](../../base_flutter/lib/common/env.dart)

> 🔎 **Quan sát**
> - `enum Flavor` — 5 flavors: develop, qa, staging, production, test. Enum đảm bảo **type-safe** — không thể truyền string sai.
> - `String.fromEnvironment(key)` — Dart const constructor, đọc values từ `--dart-define` lúc **compile time**.
> - `static late Flavor flavor` — dùng `late` vì `Flavor.values.byName(...)` không phải `const` expression (method call). `late` cho phép lazy initialization.
> - Private keys (`_flavorKey`, `_appDomain`) — naming convention: key constants bắt đầu `_` → không expose ra ngoài class.
> - `init()` — log tất cả env values khi app start (đã thấy gọi trong [M1 § AppInitializer](../module-01-app-entrypoint/01-code-walk.md)).
> - `defaultValue: 'test'` — khi chạy `flutter test` không có `--dart-define` → mặc định flavor = test.
> - **Hỏi:** Tại sao `appDomain` dùng `const` nhưng `flavor` dùng `late`?

> 💡 **FE Perspective**
> **Flutter:** `Env` class + `--dart-define-from-file` inject values ở **compile time** → values inline vào binary, không cần config file lúc runtime, enum `Flavor` đảm bảo type-safe.
> **React/Vue tương đương:** `.env` files + `process.env.REACT_APP_*` — inject ở build time qua webpack/vite, string-based (không type-safe).
> **Khác biệt quan trọng:** Dart values inline vào binary → bảo mật hơn (không expose `.env` file). JS values embed vào bundle nhưng vẫn readable trong client-side code.

### dart_defines/ — Env config files

```
dart_defines/
├── develop.json     ← FLAVOR=develop, APP_DOMAIN=https://dev-api.vn
├── qa.json          ← FLAVOR=qa
├── staging.json     ← FLAVOR=staging
└── production.json  ← FLAVOR=production
```

Khi build: `flutter run --dart-define-from-file=dart_defines/develop.json` → inject tất cả key-value pairs.

---

## log.dart — Logging System

<!-- AI_VERIFY: base_flutter/lib/common/util/log.dart -->
```dart
enum LogColor {
  black('\x1B[30m'),
  white('\x1B[37m'),
  red('\x1B[31m'),
  green('\x1B[32m'),
  yellow('\x1B[33m'),
  blue('\x1B[34m'),
  cyan('\x1B[36m');

  const LogColor(this.code);
  final String code;
}

enum LogMode { all, api, logEvent, normal }

class Log {
  const Log._();

  static const _enableLog = Config.enableGeneralLog;
  static const _generalLogMode = Config.generalLogMode;
  static const _printStackTrace = Config.printStackTrace;

  static void d(
    Object? message, {
    LogColor color = LogColor.yellow,
    LogMode mode = LogMode.normal,
    String? name,
    DateTime? time,
  }) {
    if (!kDebugMode ||
        _generalLogMode.isEmpty ||
        (!_generalLogMode.contains(LogMode.all) &&
            !_generalLogMode.contains(mode))) return;
    _log('$message', color: color, name: name ?? '', time: time);
  }

  static void _log(
    String message, {
    LogColor color = LogColor.yellow,
    int level = 0,
    String name = '',
    DateTime? time,
    int? sequenceNumber,
    Zone? zone,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_enableLog) {
      dev.log(
        '${color.code}$message\x1B[0m',
        name: name,
        time: time,
        sequenceNumber: sequenceNumber,
        level: level,
        zone: zone,
        error: error,
        stackTrace: _printStackTrace ? stackTrace : null,
      );
    }
  }
}
```
<!-- END_VERIFY -->

> 📝 `Log.e()` — same pattern as `Log.d()`, thêm `stackTrace` parameter. Chỉ có 2 public methods: `Log.d()` (debug) và `Log.e()` (error).

→ [Mở file gốc](../../base_flutter/lib/common/util/log.dart)

> 🔎 **Quan sát**
> - `LogColor` enum với **enhanced enum** (Dart 2.17+) — mỗi value mang ANSI escape code. Ví dụ: `\x1B[31m` = red, `\x1B[0m` = reset.
> - `LogMode` — filter log theo category: `all` (mọi thứ), `api` (network), `logEvent` (analytics), `normal` (general).
> - `Log.d()` guard: `if (!kDebugMode || ...)` → **không log gì ở release build**. Double protection: `_enableLog` (từ `Config`) + `kDebugMode`.
> - `Log.e()` — thêm `errorObject` + `stackTrace` params cho error logs.
> - `_log()` private method — wraps `dev.log()` (Dart SDK) → hiển thị trong DevTools console, **không phải** `print()`.
> - `prettyJson()` — format JSON cho debug output (controlled bởi `Config.isPrettyJson`).
> - **Hỏi:** Tại sao dùng `dev.log()` thay vì `print()`? (Hint: DevTools filtering, `name` parameter)

---

> 📍 **Dưới đây là `LogMixin`** (cùng file `log.dart`, phần cuối file ~line 100+) — instance-level logging wrapper dùng `runtimeType` auto-prefix class name.

### LogMixin — Instance-level logging

<!-- AI_VERIFY: base_flutter/lib/common/util/log.dart -->
```dart
mixin LogMixin on Object {
  void logD(String message, {
    LogColor color = LogColor.yellow, DateTime? time,
  }) {
    Log.d(message, name: runtimeType.toString(), time: time, color: color);
  }

  void logE(Object? errorMessage, {
    LogColor color = LogColor.red, Object? errorObject,
    StackTrace? stackTrace, DateTime? time,
  }) {
    Log.e(errorMessage, name: runtimeType.toString(),
      errorObject: errorObject, stackTrace: stackTrace,
      time: time, color: color);
  }

  static String prettyResponse(dynamic data) {
    if (data is Map) {
      return JsonEncoder.withIndent('    ').convert(
        safeCast<Map<String, dynamic>>(data));
    }
    return data.toString();
  }
}
```
<!-- END_VERIFY -->

> 🔎 **Quan sát**
> - `mixin LogMixin on Object` — mixin có thể apply vào **mọi class** (vì mọi class extends `Object`).
> - `runtimeType.toString()` — auto-fill `name` parameter → log output tự hiển thị class name. Ví dụ: `[HomeViewModel] Loading data...`
> - `logD()` / `logE()` — wrapper methods delegate xuống `Log.d()` / `Log.e()` → không duplicate logic.
> - Usage: `class HomeViewModel with LogMixin { ... logD('fetching'); }` → output: `[HomeViewModel] fetching`
> - `prettyResponse()` — static helper, format Map response cho debug (dùng `safeCast` từ `object_util.dart`).

> 💡 **FE Perspective**
> **Flutter:** `LogMixin` dùng `runtimeType` tự động lấy class name — chỉ cần `with LogMixin`, zero-config, output: `[HomeViewModel] Loading...`.
> **React/Vue tương đương:** `const logger = createLogger('HomeViewModel')` — phải manual pass tên class/component khi tạo logger instance.
> **Khác biệt quan trọng:** Dart mixin tự động inject class name qua `runtimeType`. JS phải manual truyền string → dễ lỗi khi rename class mà quên update logger name.

---

## result.dart — Sealed Union Type cho Error Handling

<!-- AI_VERIFY: base_flutter/lib/common/type/result.dart -->
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../index.dart';

part 'result.freezed.dart';

@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T data) = _Success;
  const factory Result.failure(AppException exception) = _Error;

  static Result<T> fromSyncAction<T>(T Function() action) {
    try {
      return Result.success(action.call());
    } on AppException catch (e) {
      Log.e(e);
      return Result.failure(e);
    }
  }

  static Future<Result<T>> fromAsyncAction<T>(
      Future<T> Function() action) async {
    try {
      final output = await action.call();
      return Result.success(output);
    } on AppException catch (e) {
      Log.e(e);
      return Result.failure(e);
    }
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/common/type/result.dart)

> 🔎 **Quan sát**
> - `@freezed` annotation → code generation tạo `result.freezed.dart` (sealed class, `copyWith`, `==`, `hashCode`, pattern matching).
> - `Result<T>` generic — success mang data type `T`, failure mang `AppException` (sẽ học kỹ ở [M4 — Exception Layer](../module-04-exception-handling/)).
> - 2 factory constructors (xem [M0 § Classes & Constructors](../module-00-dart-primer/02-concept.md#3a-classes--constructors)): `Result.success(data)` và `Result.failure(exception)` → **union type** (either success OR failure, never both).
> - `fromSyncAction<T>()` — wrap synchronous code: try → success, catch AppException → failure. Auto-log error.
> - `fromAsyncAction<T>()` — wrap asynchronous code: same pattern, nhưng `async/await`.
> - `on AppException catch (e)` — chỉ catch `AppException`, **không catch tất cả exceptions** → forces caller handle unexpected errors riêng.
> - `part 'result.freezed.dart'` — `part` directive liên kết gen file với source (xem [M0 § Codegen Pipeline](../module-00-dart-primer/02-concept.md#3-code-generation-pipeline--should-know)), chạy `make fb` để regenerate.
> - **Hỏi:** Caller sử dụng `Result` thế nào? (Hint: `result.when(success: ..., failure: ...)`)

> 💡 **FE Perspective**
> **Flutter:** `Result<T>` sealed union (`@freezed`) với `when(success:, failure:)` — compiler enforce handle cả 2 cases (exhaustive check), không thể quên handle error.
> **React/Vue tương đương:** TypeScript discriminated union `{ type: 'success'; data: T } | { type: 'failure'; error: E }` — type narrowing qua `if (r.type === 'success')`.
> **Khác biệt quan trọng:** Dart `when()`/`map()` compiler-enforced exhaustive — thêm case mới → compile error tại mọi call site. TS discriminated union **có thể** exhaustive check qua `switch` + `default: const _: never = x`, nhưng phải opt-in thủ công (không tự động như Dart).

---

## extension.dart — Extension Methods

<!-- AI_VERIFY: base_flutter/lib/common/util/extension.dart -->
```dart
extension NullableListExtensions<T> on List<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

extension NullableStringExtensions on String? {
  bool get isNotNullAndNotEmpty => this != null && this!.isNotEmpty;
}

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  FocusScopeNode get focusScope => FocusScope.of(this);
}

extension ListExtensions<T> on List<T> {
  List<T> appendOrExceptElement(T item) {
    return contains(item)
        ? exceptElement(item).toList(growable: false)
        : appendElement(item).toList(growable: false);
  }

  List<T> plus(T element) {
    return appendElement(element).toList(growable: false);
  }

  List<T> minus(T element) {
    return exceptElement(element).toList(growable: false);
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/common/util/extension.dart) (full ~100+ lines)

> 🔎 **Quan sát**
> - **Nullable extensions** (`on List<T>?`, `on String?`) — extend nullable type → gọi trên `null` mà không crash: `myList.isNullOrEmpty`.
> - **BuildContext extensions** — shortcut cho `Theme.of(context)` → `context.theme`. Giảm boilerplate trong widgets.
> - **Collection extensions** (`plus`, `minus`, `appendOrExceptElement`) — immutable-style operations: return **new list**, không mutate original.
> - `toList(growable: false)` — tạo fixed-length list → micro-optimization (ít memory hơn growable list).
> - Naming: `plus(T)` / `minus(T)` — operator-like names, dễ đọc: `items.plus(newItem)`.
> - File còn có `SetExtensions`, `MapExtensions`, `NumExtensions` — cùng pattern cho các collection types.
> - **Hỏi:** Tại sao `BuildContextExtensions` không đặt trong `resource/` hay `ui/` mà ở `common/util/`?

> 💡 **FE Perspective**
> **Flutter:** Extension methods thêm functionality vào existing types (List, String, BuildContext) — scoped (chỉ visible khi import), type-safe, IDE autocomplete đầy đủ.
> **React/Vue tương đương:** Prototype extension (`Array.prototype.plus`) hoặc utility functions (`const plus = (arr, item) => [...arr, item]`).
> **Khác biệt quan trọng:** Dart extension scoped + type-safe, không ảnh hưởng global. JS prototype modification ảnh hưởng **toàn cục**, không recommend — utility functions an toàn hơn nhưng syntax kém tiện.

---

## object_util.dart — Safe Casting & Kotlin-style `let`

<!-- AI_VERIFY: base_flutter/lib/common/util/object_util.dart -->
```dart
import '../../index.dart';

T? safeCast<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  Log.e('Error: safeCast: $value is not $T');
  return null;
}

extension ObjectExt<T> on T? {
  R? safeCast<R>() {
    final that = this;
    if (that is R) {
      return that;
    }
    Log.e('Error: safeCast: $this is not $R');
    return null;
  }

  R? let<R>(R Function(T)? cb) {
    final that = this;
    if (that == null) {
      return null;
    }
    return cb?.call(that);
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/common/util/object_util.dart)

> 🔎 **Quan sát**
> - **Top-level `safeCast<T>()`** — function nhận `dynamic` value, check type → return `T?`. Log error nếu cast fail (thay vì crash).
> - **Extension `safeCast<R>()`** — chain-able version: `myObject.safeCast<String>()`. Tách `final that = this` để **promote type** (Dart null safety flow analysis).
> - **`let<R>()`** — inspired by **Kotlin `let`**: chỉ execute callback khi value != null. Return type = `R?`.
> - Pattern: `user?.let((u) => Text(u.name))` → nếu `user` null → return null, nếu non-null → return `Text(u.name)`.
> - `dynamic` usage — chỉ ở API boundary (parse JSON). Bên trong app flow → luôn typed.
> - **Hỏi:** Khi nào dùng top-level `safeCast()` vs extension `.safeCast<R>()`?

> 💡 **FE Perspective**
> **Flutter:** `let` extension transform nullable value nếu non-null (Kotlin-style), `safeCast<R>()` cast type an toàn trả về `null` nếu sai type + log error.
> **React/Vue tương đương:** `let` ≈ optional chaining `user?.name` + transform. `safeCast` ≈ `as` type assertion trong TypeScript nhưng **safe** (TS `as` sẽ throw nếu sai type runtime).
> **Khác biệt quan trọng:** Dart `safeCast` trả `null` + log error thay vì throw — an toàn hơn TS `as` assertion. `let` extension cho phép chain transform phức tạp hơn optional chaining.

---

## helper/ — Single-Responsibility Helper Classes

> Mỗi helper class wrap **1 platform concern** (network, crash reporting, permissions…) — registered qua DI (`@LazySingleton`), exposed qua Riverpod provider, và có `init()` method nếu cần setup lúc boot.

```
lib/common/helper/
├── analytics/
│   ├── analytic_event.dart
│   ├── analytic_parameter.dart
│   ├── analytics_helper.dart
│   └── screen_name.dart
├── connectivity_helper.dart
├── crashlytics_helper.dart
├── deep_link_helper.dart
├── device_helper.dart
├── local_push_notification_helper.dart
├── package_helper.dart
└── permission_helper.dart
```

### Ví dụ: connectivity_helper.dart

<!-- AI_VERIFY: base_flutter/lib/common/helper/connectivity_helper.dart -->
```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../index.dart';

final connectivityHelperProvider = Provider<ConnectivityHelper>(
  (ref) => getIt.get<ConnectivityHelper>(),
);

@LazySingleton()
class ConnectivityHelper {
  Future<bool> get isNetworkAvailable async {
    final result = await Connectivity().checkConnectivity();
    return _isNetworkAvailable(result);
  }

  Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged.map((event) {
      return _isNetworkAvailable(event);
    });
  }

  bool _isNetworkAvailable(List<ConnectivityResult> result) {
    if (result.length == 1 && result.first == ConnectivityResult.none) {
      return false;
    }
    return true;
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/common/helper/connectivity_helper.dart)

> 🔎 **Quan sát**
> - `@LazySingleton()` — DI annotation (injectable): tạo **1 instance duy nhất**, lazy init khi lần đầu get (đã học [M1 § DI](../module-01-app-entrypoint/01-code-walk.md)).
> - `connectivityHelperProvider` — Riverpod provider wrapping DI → UI widgets dùng `ref.watch(connectivityHelperProvider)` (sẽ học [M8 — State Management](../module-08-riverpod-state/)).
> - **Single responsibility** — chỉ xử lý connectivity check, không mix với UI/logic khác.
> - `Stream<bool> get onConnectivityChanged` — reactive stream → UI tự update khi network thay đổi.
> - Pattern lặp lại cho **mọi helper**: `@LazySingleton` + provider + focused interface.

### Ví dụ: package_helper.dart

<!-- AI_VERIFY: base_flutter/lib/common/helper/package_helper.dart -->
```dart
final packageHelperProvider = Provider<PackageHelper>(
  (ref) => getIt.get<PackageHelper>(),
);

@LazySingleton()
class PackageHelper {
  PackageInfo? _packageInfo;

  String get appName => _packageInfo?.appName ?? '';
  String get applicationId => _packageInfo?.packageName ?? '';
  String get versionCode => _packageInfo?.buildNumber ?? '';
  String get versionName => _packageInfo?.version ?? '';

  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    Log.d(_packageInfo!.packageName, name: 'APPLICATION_ID');
  }
}
```
<!-- END_VERIFY -->

> 🔎 **Quan sát**
> - Cùng pattern: `@LazySingleton` + Riverpod provider + DI bridge.
> - `init()` gọi từ `AppInitializer` (M1 boot sequence) → data sẵn sàng khi app load.
> - Getters return `String` (default `''`) → null-safe, UI không cần null check.

> 📌 **Note**: Helper files (`date_time_helper.dart`, `permission_helper.dart`, etc.) chứa utility functions được sử dụng xuyên suốt project. Chi tiết về cách các helpers connect với providers sẽ được cover ở [Module 08 — Riverpod State](../module-08-riverpod-state/00-overview.md).

---

## Code Walk Summary

| File | Vai trò | Pattern chính | Liên kết Module |
|------|---------|--------------|-----------------|
| `config.dart` | Debug flags, feature toggles | `static const` + `kDebugMode` | M1 (used in boot), M8 (provider observer flags) |
| `constant.dart` | App-wide constants | `static const` namespace class | M7 (paging), M12 (API config) |
| `env.dart` | Flavor + environment variables | `String.fromEnvironment` + dart-define | M1 (AppInitializer.init), M19 (CI/CD) |
| `log.dart` | Debug logging system | `Log` static + `LogMixin` | Mọi module (logging everywhere) |
| `result.dart` | Success/Failure union type | `@freezed` sealed class + generics | M4 (AppException), M7 (ViewModel Result handling) |
| `extension.dart` | Collection/Context extensions | Extension methods on nullable types | M9 (UI components), M5 (widgets) |
| `object_util.dart` | Safe cast + Kotlin `let` | Top-level function + extension | M12 (API response parsing) |
| `helper/` | Platform service wrappers | `@LazySingleton` + Riverpod provider | M8 (state management), M1 (boot init) |

**Next:** Concepts giải thích chi tiết → [02-concept.md](./02-concept.md)

<!-- AI_VERIFY: generation-complete -->
