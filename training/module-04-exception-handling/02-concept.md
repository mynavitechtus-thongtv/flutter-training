# Concepts — Exception Handling & Error Flow

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

---

## 1. Exception Hierarchy & Abstract Base Class 🔴 MUST-KNOW

**WHY:** `AppException` là **contract** cho mọi error trong app. Hiểu sai hierarchy → catch sai type, miss error handling, UI không phản hồi đúng.

<!-- AI_VERIFY: base_flutter/lib/exception/app_exception.dart -->
```dart
abstract class AppException implements Exception {
  AppException({this.onRetry, this.rootException});
  final Object? rootException;
  Future<void> Function()? onRetry;

  String get message;            // abstract — subtype bắt buộc override
  AppExceptionAction get action; // abstract — subtype quyết định UI behavior
  bool get recordError => false;
  bool get isForcedErrorToHandle => false;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_exception.dart](./01-code-walk.md#app_exceptiondart--abstract-base-class-contract)

**EXPLAIN:**

`AppException` áp dụng pattern **Abstract Contract**:

| Thành phần | Vai trò | Bắt buộc override? |
|-----------|---------|-------------------|
| `message` | Localized error string cho UI | ✅ Yes (abstract getter) |
| `action` | Enum quyết định ExceptionHandler behavior | ✅ Yes (abstract getter) |
| `rootException` | Lưu exception gốc (exception chaining) | ❌ Optional (constructor param) |
| `onRetry` | Callback retry gắn vào exception | ❌ Optional (nullable) |
| `recordError` | Gửi Crashlytics hay không | ❌ Default `false` |
| `isForcedErrorToHandle` | ViewModel phải handle, không skip | ❌ Default `false` |

**Tại sao `implements Exception` mà không `extends Exception`?**

```dart
// Dart Exception class = interface marker, không có logic
// implements = khai báo "tôi là Exception" nhưng tự define mọi thứ
abstract class AppException implements Exception { ... }

// extends = kế thừa implementation (Exception không có gì hữu ích)
// → implements cho flexibility, AppException tự define contract riêng
```

**Hierarchy + Actions — mỗi subtype phục vụ một domain:**

```
AppException (abstract contract: message + action)
│
├── RemoteException (kind: RemoteExceptionKind) — 12 kinds
│   ├── noInternet, timeout, network  → showDialogWithRetry
│   ├── serverMaintenance             → showMaintenanceDialog
│   ├── refreshTokenFailed, userNotFound → showForceLogoutDialog
│   ├── serverUndefined, otherServerDefined, badCertificate, decodeError, cancellation, unknown → showDialog
│
├── ValidationException (kind: ValidationExceptionKind) — 3 kinds
│   └── invalidEmail, invalidPassword, passwordsDoNotMatch → doNothing
│
├── AppFirebaseAuthException (kind: AppFirebaseAuthExceptionKind) — 6 kinds
│   └── invalidEmail, userDoesNotExist, invalidLoginCredentials,
│       usernameAlreadyInUse, requiresRecentLogin, unknown → doNothing
│
└── AppUncaughtException (no kind enum)
    └── action = doNothing (catch-all fallback)
```

**Benefit:** `Result.failure(AppException)` và `ExceptionHandler.handleException(AppException)` nhận **bất kỳ subtype** → polymorphism. Mọi nơi code against interface, không against concrete class.

> 💡 **FE Perspective — Exception Hierarchy**
> 
> | Flutter | React / Vue |
> |---------|-------------|
> | `abstract class AppException` (contract) | Base `class AppError extends Error` |
> | Subtypes: `RemoteException`, `ValidationException` | Custom classes: `NetworkError`, `ValidationError` |
> | `kind` enum per subtype — exhaustive switch | `error.code` string literal — no exhaustive check in JS |
> | `implements Exception` (interface contract) | `extends Error` (prototype chain) |
> | Hierarchy enforced by Dart type system | TS `abstract class` CAN enforce hierarchy, nhưng Dart enforces across **entire exception hierarchy** including exhaustive switch — TS thiếu exhaustive pattern matching trên exception types |

**PRACTICE:** Mở [app_exception.dart](../../base_flutter/lib/exception/app_exception.dart). Chạy `grep -rn 'extends AppException' lib/` → xác nhận 4 subtypes. Tìm nơi `AppException` được dùng làm type parameter (hint: `Result<T>`, `ExceptionHandler`).

---

> 💡 **l10n Preview**: Error messages hiển thị cho user cần localized. `l10n` là global accessor cho localized strings (chi tiết ở M11). Tạm thời: `l10n.errorGeneral` — chỉ cần biết nó tồn tại.

## 2. Typed Exception Subtypes (Enum-Driven) 🔴 MUST-KNOW

**WHY:** Mỗi exception subtype dùng `kind` enum → phân loại error **chi tiết**. Không có typed subtypes → `catch (e)` generic, logic `if/else` string matching, impossible to maintain.

<!-- AI_VERIFY: base_flutter/lib/exception/remote_exception.dart -->
```dart
class RemoteException extends AppException {
  RemoteException({required this.kind, ...});
  final RemoteExceptionKind kind;

  @override
  String get message => switch (kind) {
    RemoteExceptionKind.noInternet => l10n.noInternetException,
    RemoteExceptionKind.timeout => l10n.timeoutException,
    // ... exhaustive switch trên 12 kinds
  };

  @override
  AppExceptionAction get action => switch (kind) {
    RemoteExceptionKind.serverMaintenance => AppExceptionAction.showMaintenanceDialog,
    RemoteExceptionKind.noInternet || ... => AppExceptionAction.showDialogWithRetry,
    // ... exhaustive
  };
}

enum RemoteExceptionKind {
  noInternet, timeout, network, otherServerDefined, refreshTokenFailed,
  serverMaintenance, userNotFound, serverUndefined, badCertificate,
  decodeError, cancellation, unknown,
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § remote_exception.dart](./01-code-walk.md#remote_exceptiondart--api--network-errors)

**EXPLAIN:**

**Dart 3 Switch Expression — exhaustive guarantee:**

```dart
// Thêm enum value mới vào RemoteExceptionKind:
enum RemoteExceptionKind {
  // ... existing 12 kinds
  rateLimited, // ← MỚI
}

// → Compiler error tại TẤT CẢ switch expressions:
// "The type 'RemoteExceptionKind' is not exhaustively matched"
// → Buộc phải handle ở cả message + action → không quên
```

**So sánh subtype patterns:**

| Subtype | Kind count | Action | Use case |
|---------|-----------|--------|----------|
| `RemoteException` | 12 | Varies per kind | API/network errors |
| `ValidationException` | 3 | Always `doNothing` | Form validation |
| `AppFirebaseAuthException` | 6 | Always `doNothing` | Firebase auth |
| `AppUncaughtException` | 0 (no enum) | Always `doNothing` | Catch-all |

**Tại sao `doNothing` cho validation + firebase?**

Các errors này xảy ra ở **business logic layer** (ViewModel) → caller biết context tốt hơn `ExceptionHandler`. Ví dụ: validation error hiện inline dưới text field, không cần dialog.

> 💡 **FE Perspective**
> **Flutter:** Mỗi exception subtype dùng `kind` enum — compile-time checked, IDE autocomplete, exhaustive switch expression guarantee handle tất cả cases.
> **React/Vue tương đương:** String-based error types: `throw { type: 'NETWORK_ERROR', message: '...' }` — hoặc TS string literal union `'timeout' | 'network'`.
> **Khác biệt quan trọng:** Dart enum exhaustive switch → thêm kind mới compile error ở mọi switch. JS string-based → typo `'NETWERK_ERROR'` không có compile error, TS union type tốt hơn nhưng vẫn không enforce exhaustive.

**PRACTICE:** Mở [validation_exception.dart](../../base_flutter/lib/exception/validation_exception.dart). Thử thêm `ValidationExceptionKind.phoneNumberInvalid` vào enum (chỉ thêm enum value). Dart analyzer báo lỗi ở đâu? Đó là exhaustive check hoạt động.

---

## 3. Action-Driven Error Handling 🔴 MUST-KNOW

**WHY:** Exception tự khai báo **cách xử lý mình** qua `AppExceptionAction` → `ExceptionHandler` chỉ dispatch. Không có pattern này → mỗi catch block tự quyết UI → inconsistent.

<!-- AI_VERIFY: base_flutter/lib/exception/exception_handler/exception_handler.dart -->
```dart
switch (appException.action) {
  case AppExceptionAction.showSnackBar:
    _ref.read(appNavigatorProvider).showSnackBar(...);
    break;
  case AppExceptionAction.showDialog:
    await _ref.read(appNavigatorProvider).showDialog(ErrorDialog.error(...));
    break;
  case AppExceptionAction.showDialogWithRetry:
    // check onRetry != null → show retry button
    break;
  case AppExceptionAction.showForceLogoutDialog:
    // show dialog → forceLogout() → fallback navigate Login
    break;
  case AppExceptionAction.showMaintenanceDialog:
    // non-cancelable dialog
    break;
  case AppExceptionAction.doNothing:
    break;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § exception_handler.dart](./01-code-walk.md#exception_handlerdart--centralized-ui-dispatch)

**EXPLAIN:**

**Pattern: Exception carries its own handling instruction.**

```
Exception Creation:
  RemoteException(kind: noInternet)
    → action = showDialogWithRetry (tự khai báo)

Exception Handling:
  ExceptionHandler.handleException(exception)
    → switch (exception.action)
      → showDialogWithRetry: show dialog + retry button
```

**7 actions — mapping to UI behavior:**

| Action | UI Behavior | Cancelable? | Ví dụ |
|--------|------------|------------|-------|
| `showSnackBar` | Snackbar tạm thời | Auto-dismiss | Minor errors |
| `showDialog` | Alert dialog | ✅ Dismissible | Server 4xx errors |
| `showDialogWithRetry` | Dialog + Retry button | ✅ Dismissible | No internet, timeout |
| `showForceLogoutDialog` | Dialog → force logout | ✅ Dismissible | Token expired |
| `showNonCancelableDialog` | Dialog không dismiss được | ❌ Cannot dismiss | Critical errors |
| `showMaintenanceDialog` | Maintenance screen | ❌ Cannot dismiss | Server 503 |
| `doNothing` | Skip — caller tự xử lý | N/A | Validation, firebase auth |

> 💡 **FE Perspective — Error Code → UI Behavior Mapping**
> 
> | Flutter | React / Vue |
> |---------|-------------|
> | `AppExceptionAction` enum on exception | Error code → handler mapping object `{ NETWORK: 'toast', AUTH: 'redirect' }` |
> | Exception carries its own `action` getter | Handler reads `error.code` to decide UI behavior |
> | `showDialog`, `showSnackBar`, `doNothing` | `toast.error()`, `modal.open()`, `console.warn()` |
> | Exhaustive switch — compiler checks all action cases | `switch(code)` — missing case = silent bug |
> | Adding new action → compile errors at handler | Adding new code → no automatic check at handler |

**Benefit chính:** **Decoupling** giữa exception definition và UI rendering:
- `RemoteException` (data layer) quyết định action
- `ExceptionHandler` (presentation helper) render UI
- Không layer nào biết chi tiết internal của layer kia

> 💡 **FE Perspective — Global Error Handler**
> 
> | Flutter | React / Vue |
> |---------|-------------|
> | `ExceptionHandler` class (DI singleton) | Global error handler service / toast service |
> | Reads `exception.action` → dispatch UI | Axios interceptor reads `error.response.status` → call `toast()` |
> | Centralized switch in one class | Scattered across interceptor + error boundary + components |
> | Uses `AppNavigator` for dialogs/snackbars | Uses `react-toastify` / `ElMessage` / custom toast hook |
> | `doNothing` → caller handles inline | `catch` in component → `setFieldError()` for inline display |

**PRACTICE:** Trace flow: `RemoteException(kind: timeout)` → `action` getter trả gì? → `ExceptionHandler` switch case nào? → UI hiện gì cho user?

---

## 4. Exception Mapping Pattern 🟡 SHOULD-KNOW

**WHY:** Raw exceptions từ third-party libraries (Dio, Firebase) → phải convert sang app-specific types. Mapper pattern giữ conversion logic tập trung, testable, reusable.

<!-- AI_VERIFY: base_flutter/lib/exception/exception_mapper/app_exception_mapper.dart -->
```dart
abstract class AppExceptionMapper<T extends AppException> {
  T map({required Object? exception, required ApiInfo apiInfo});
}
```
<!-- END_VERIFY -->

<!-- AI_VERIFY: base_flutter/lib/exception/exception_mapper/dio_exception_mapper.dart -->
```dart
class DioExceptionMapper extends AppExceptionMapper<RemoteException> {
  @override
  RemoteException map({required Object? exception, required ApiInfo apiInfo}) {
    if (exception is RemoteException) return exception; // idempotent
    if (exception is DioException) {
      switch (exception.type) {
        case DioExceptionType.cancel: return RemoteException(kind: RemoteExceptionKind.cancellation);
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return RemoteException(kind: RemoteExceptionKind.timeout, rootException: exception);
        case DioExceptionType.badResponse:
          // deep mapping: HTTP status + server error body → specific kind
        // ...
      }
    }
    return RemoteException(kind: RemoteExceptionKind.unknown, rootException: exception);
  }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § dio_exception_mapper.dart](./01-code-walk.md#dio_exception_mapperdart--dio--remoteexception-transformation)

**EXPLAIN:**

**Mapper flow:**

```
DioException (Dio library type)
    │
    ▼
DioExceptionMapper.map()
    ├── DioExceptionType.cancel → RemoteExceptionKind.cancellation
    ├── DioExceptionType.*Timeout → RemoteExceptionKind.timeout
    ├── DioExceptionType.badResponse
    │   ├── 503 → serverMaintenance
    │   ├── has data + userNotFoundErrorId → userNotFound
    │   ├── has data + other → otherServerDefined
    │   └── no data → serverUndefined
    ├── DioExceptionType.badCertificate → badCertificate
    ├── DioExceptionType.connectionError → network
    └── DioExceptionType.unknown → check SocketException → network
    │
    ▼
RemoteException (app-specific type)
```

**Key design decisions:**

| Decision | Lý do |
|----------|-------|
| Idempotent check (`is RemoteException`) | Tránh double-mapping khi exception đã converted |
| Generic base `AppExceptionMapper<T>` | Open for extension: GraphQL mapper, gRPC mapper, ... |
| Constructor injection `_errorResponseDecoder` | Testable: mock decoder trong unit test |
| Fallback `RemoteExceptionKind.unknown` | **Không bao giờ throw** từ mapper → safe conversion |

> 💡 **FE Perspective**
> **Flutter:** Exception mapper là **class riêng** (`DioExceptionMapper`) — nhận raw exception + API info, trả typed `AppException`. Idempotent, injectable, testable.
> **React/Vue tương đương:** Axios interceptor inline xử lý error transformation trong callback — `interceptors.response.use(null, error => { ... })`.
> **Khác biệt quan trọng:** Dart tách mapper thành class riêng → single responsibility, unit testable (mock decoder), reusable. FE inline trong interceptor → tangled logic, khó test riêng phần mapping.

**PRACTICE:** Đọc [dio_exception_mapper.dart](../../base_flutter/lib/exception/exception_mapper/dio_exception_mapper.dart). Trace case `DioExceptionType.badResponse` với HTTP 503 → output `RemoteException` có gì? Trace với HTTP 404 + server error body → output?

---

## 5. Error Boundary Integration 🟡 SHOULD-KNOW

**WHY:** `runZonedGuarded` (M1) bắt uncaught exceptions → `Log.e()` + Crashlytics. Exception layer cung cấp `AppUncaughtException` + `recordError` flag → integration point.

```dart
// M1: main.dart
Future<void> main() async => runZonedGuarded(
  _runMyApp,
  (error, stackTrace) => _reportError(error: error, stackTrace: stackTrace),
);

// Exception layer provides:
class AppUncaughtException extends AppException {
  @override String get message => l10n.unknownException(errorCode: 'UE-00');
  @override AppExceptionAction get action => AppExceptionAction.doNothing;
}
```
→ Ref: [M1 § runZonedGuarded](../module-01-app-entrypoint/01-code-walk.md#main--entry-point-với-error-boundary)

**EXPLAIN:**

**Hai layers of error catching:**

```
Layer 1: runZonedGuarded (M1)
  → Catches ALL uncaught exceptions in the app zone
  → Reports to Crashlytics
  → Last resort — if error reaches here, no UI handling happened

Layer 2: Result.fromAsyncAction (M3) + ExceptionHandler (M4)
  → Catches AppException specifically
  → Provides typed error handling with UI feedback
  → First line of defense in business logic
```

| Layer | Scope | Exception type | UI feedback |
|-------|-------|---------------|------------|
| `runZonedGuarded` | Global | Any `Object` | None (crash report only) |
| `Result.fromAsyncAction` | Per-action | `AppException` | Via `ExceptionHandler` dispatch |
| `try/catch` in mapper | Per-conversion | `DioException`, etc. | Transformed → `AppException` |

> 💡 **FE Perspective — Global Error Boundary**
> 
> | Flutter | React / Vue |
> |---------|-------------|
> | `runZonedGuarded` (catches all uncaught) | `window.onerror` / `window.onunhandledrejection` |
> | `AppUncaughtException` (fallback wrapper) | Generic `Error` object reaching global handler |
> | Reports to Crashlytics | Reports to Sentry / LogRocket / Datadog |
> | `Result.fromAsyncAction` (per-action typed catch) | React `ErrorBoundary` (`componentDidCatch`) per subtree |
> | Two layers: global zone + typed Result | Two layers: `window.onerror` (global) + ErrorBoundary (component) |

**`recordError` integration:**
```dart
// ExceptionHandler checks recordError flag
if (appException.recordError) {
  await _ref.read(crashlyticsHelperProvider).recordError(...);
}
// → Subtype override recordError = true cho critical errors
// → Default false → không spam Crashlytics với validation errors
```

**PRACTICE:** Trace: một `DioException` timeout xảy ra. Nó đi qua bao nhiêu layers trước khi user thấy dialog? (Hint: Dio interceptor → mapper → repository → Result → ViewModel → ExceptionHandler → UI)

---

## 6. Result Type Integration 🟡 SHOULD-KNOW

**WHY:** `Result.failure(AppException)` (M3) là **transport mechanism** cho exceptions qua layers. Exception layer define types, Result layer wrap & propagate.

> 📌 **Recap từ [Module 3 § Concept 5](../module-03-common-layer/02-concept.md)**: `Result<T>` là sealed class với 2 variants `Success(data)` và `Failure(exception)`. `@freezed` code gen tạo `copyWith`, equality, pattern matching. Xem M3 để biết chi tiết.

<!-- AI_VERIFY: base_flutter/lib/common/type/result.dart -->
```dart
@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T data) = _Success;
  const factory Result.failure(AppException exception) = _Error;

  static Future<Result<T>> fromAsyncAction<T>(Future<T> Function() action) async {
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
→ Ref: [M3 § result.dart](../module-03-common-layer/01-code-walk.md)

**EXPLAIN:**

**Kết nối M3 ↔ M4:**

```dart
// Repository layer (sẽ học ở M12):
Future<Result<UserData>> getUser(int id) => Result.fromAsyncAction(() async {
  final response = await _apiService.getUser(id);
  // Nếu API throw DioException → DioExceptionMapper convert → RemoteException
  // RemoteException extends AppException → caught by "on AppException catch (e)"
  // → Result.failure(RemoteException(...))
  return response.toUserData();
});

// ViewModel layer (sẽ học ở M7):
final result = await _repository.getUser(1);
result.when(
  success: (user) => state = user,
  failure: (exception) => ref.read(exceptionHandlerProvider).handleException(exception),
);
```

**Key insight:** `on AppException catch (e)` — Result **chỉ catch AppException** subtypes. Non-AppException errors (programming bugs, AssertionError) **bubble up** → `runZonedGuarded` catch → Crashlytics. Đây là **intentional design** — không swallow unexpected errors.

**PRACTICE:** Viết pseudo-code: function `login(email, password)` có thể throw `ValidationException` (invalid email) hoặc `RemoteException` (network error). Dùng `Result.fromAsyncAction` → cả hai đều bị catch? Tại sao?

---

## 7. Localized Error Messages 🟢 AI-GENERATE

**WHY:** Mọi exception carrying user-facing `message` dùng `l10n` (localization). Hardcode string → không support multi-language, không thay đổi được.

```dart
// RemoteException
RemoteExceptionKind.noInternet => l10n.noInternetException,
RemoteExceptionKind.timeout => l10n.timeoutException,

// ValidationException
ValidationExceptionKind.invalidEmail => l10n.invalidEmail,

// AppFirebaseAuthException
AppFirebaseAuthExceptionKind.unknown => l10n.unknownException(errorCode: 'FBA-001'),
```

**EXPLAIN:**

**`l10n` accessor pattern:**
- `l10n` là global accessor cho localization strings (generated từ ARB files)
- Mỗi exception kind → specific l10n key → translated string
- Error codes (`UE-01`, `FBA-001`) embed trong message → traceable mà không expose internal details

**Error code convention:**

| Prefix | Source | Ví dụ |
|--------|--------|-------|
| `UE-0x` | Remote Unknown Error | `UE-00` (uncaught), `UE-01` (bad cert), ... `UE-06` (decode) |
| `FBA-xxx` | Firebase Auth | `FBA-001` (unknown firebase auth) |

**Debug info ẩn ở production:**
```dart
// RemoteException._apiInfo
String get _apiInfo => Env.flavor == Flavor.production || Env.flavor == Flavor.test
    ? ''  // Production: ẩn API path → bảo mật
    : '\nTime: ...\nPath: $apiInfo';  // Dev/QA: hiện debug info
```

**PRACTICE:** Tìm ARB file chứa key `noInternetException`. Trace: key đó → generated Dart class → `l10n.noInternetException` → hiện trên UI dialog.

---

## Concept Summary

| # | Concept | Badge | Key Takeaway |
|---|---------|-------|-------------|
| 1 | Exception Hierarchy | 🔴 MUST-KNOW | `AppException` = contract (`message` + `action`), 4 subtypes |
| 2 | Typed Subtypes | 🔴 MUST-KNOW | Enum-driven, switch exhaustive, compiler-enforced |
| 3 | Action-Driven Handling | 🔴 MUST-KNOW | Exception tự khai báo UI behavior → handler dispatch |
| 4 | Exception Mapping | 🟡 SHOULD-KNOW | Raw → typed transformation, idempotent, fallback safe |
| 5 | Error Boundary Integration | 🟡 SHOULD-KNOW | Two layers: `runZonedGuarded` (global) + `Result.fromAsyncAction` (per-action) |
| 6 | Result Type Integration | 🟡 SHOULD-KNOW | `Result.failure(AppException)` — only catch typed exceptions, let bugs bubble |
| 7 | Localized Messages | 🟢 AI-GENERATE | l10n keys, error codes, production security |

**Phân bố:** 🔴 ~43% · 🟡 ~43% · 🟢 ~14%

→ Tiếp theo: [03-exercise.md](./03-exercise.md) — thực hành trace, build, extend exception layer.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
