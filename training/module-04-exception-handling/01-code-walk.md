# Code Walk — Exception Handling & Error Flow

> 📌 **Recap từ modules trước:**
> - **M1:** `runZonedGuarded` — global error boundary wrap toàn app, mọi uncaught exception bị bắt ([M1 § main.dart](../module-01-app-entrypoint/01-code-walk.md#main--entry-point-với-error-boundary))
> - **M3:** `Result<T>` union type — `Result.failure(AppException)` bắt typed exceptions, `Log.e()` log errors, `Config` toggle log ([M3 § result.dart](../module-03-common-layer/01-code-walk.md))
> - **M2:** Layer architecture — `exception/` là dedicated layer, `common/` là foundation, barrel `index.dart` re-export tất cả ([M2 § layers](../module-02-architecture-barrel/01-code-walk.md))
>
> Nếu chưa nắm vững → quay lại [Module 1](../module-01-app-entrypoint/), [Module 2](../module-02-architecture-barrel/) hoặc [Module 3](../module-03-common-layer/) trước.

---

## app_exception.dart — Abstract Base Class (Contract)

<!-- AI_VERIFY: base_flutter/lib/exception/app_exception.dart -->
```dart
abstract class AppException implements Exception {
  AppException({
    this.onRetry,
    this.rootException,
  });

  final Object? rootException;
  Future<void> Function()? onRetry;

  String get message;

  AppExceptionAction get action;

  bool get recordError => false;

  bool get isForcedErrorToHandle => false;

  @override
  String toString() {
    return 'rootException: $rootException, message: $message, action: $action';
  }
}

enum AppExceptionAction {
  showSnackBar,
  showDialog,
  showDialogWithRetry,
  showForceLogoutDialog,
  showNonCancelableDialog,
  showMaintenanceDialog,
  doNothing,
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/exception/app_exception.dart)

> 🔎 **Quan sát**
> - `abstract class` + `implements Exception` — **contract** cho tất cả exception types trong app. Mọi exception đều phải cung cấp `message` + `action`.
> - `rootException: Object?` — lưu lại exception gốc (Dart `Exception`, `Error`, hoặc bất kỳ `Object`). Pattern **exception chaining** — không mất context debug.
> - `onRetry: Future<void> Function()?` — callback retry **gắn vào exception** → `ExceptionHandler` có thể hiển thị "Retry" button mà không cần biết logic retry.
> - `String get message` — **abstract getter** → mỗi subtype **bắt buộc** override. Trả về localized string (l10n).

> 💡 `l10n` là global accessor cho localized strings (chi tiết ở [M11](../module-11-i18n/)). Hiện tại đọc như 'localized message getter'.

> - `AppExceptionAction get action` — **abstract getter** → mỗi subtype quyết định **cách xử lý UI** (snackbar? dialog? force logout?).
> - `recordError => false` — default không record lên Crashlytics. Subtype override `true` nếu cần.
> - `isForcedErrorToHandle => false` — flag cho errors cần xử lý ngay (token expired, maintenance). Default = false.
> - `AppExceptionAction` enum — **7 actions** rõ ràng, exhaustive → compiler enforce handle hết trong `switch`.
> - **Hỏi:** Tại sao `implements Exception` mà không `extends Exception`?

> 💡 **FE Perspective**
> **Flutter:** `AppException` abstract class với abstract getters `message` + `action` — subtypes **bắt buộc** implement, `AppExceptionAction` enum với 7 values cho exhaustive switch.
> **React/Vue tương đương:** `class AppError extends Error { action: 'toast' | 'dialog' | 'redirect' }` — base error class với string union type cho action.
> **Khác biệt quan trọng:** Dart abstract getters + enum → compile-time guarantee subtype phải implement. JS chỉ convention-based, không enforce — dễ quên implement `message` hoặc typo `action` string.

🏁 **Checkpoint:** Đã đọc xong `app_exception.dart` — base contract. Tóm tắt 1 câu trước khi tiếp tục.

---

## remote_exception.dart — API & Network Errors

<!-- AI_VERIFY: base_flutter/lib/exception/remote_exception.dart -->
```dart
class RemoteException extends AppException {
  RemoteException({
    required this.kind,
    this.dioStatusCode,
    this.serverError,
    this.apiInfo,
    super.rootException,
    super.onRetry,
  }) : super();

  final RemoteExceptionKind kind;
  final int? dioStatusCode;
  final ServerError? serverError;
  final ApiInfo? apiInfo;

  String get _apiInfo => Env.flavor == Flavor.production || Env.flavor == Flavor.test
      ? ''
      : '\nTime: ${DateTimeUtil.now.toStringWithFormat(Constant.fddMMyyyyHHmm)}\nPath: $apiInfo';

  @override
  String get message =>
      switch (kind) {
        RemoteExceptionKind.badCertificate => l10n.unknownException(errorCode: 'UE-01'),
        RemoteExceptionKind.noInternet => l10n.noInternetException,
        RemoteExceptionKind.network => l10n.canNotConnectToHost,
        RemoteExceptionKind.userNotFound ||
        RemoteExceptionKind.otherServerDefined =>
          generalServerMessage ?? l10n.unknownException(errorCode: 'UE-02'),
        RemoteExceptionKind.serverUndefined => l10n.unknownException(errorCode: 'UE-03'),
        RemoteExceptionKind.timeout => l10n.timeoutException,
        RemoteExceptionKind.cancellation => l10n.unknownException(errorCode: 'UE-04'),
        RemoteExceptionKind.unknown => l10n.unknownException(errorCode: 'UE-05'),
        RemoteExceptionKind.refreshTokenFailed => l10n.tokenExpired,
        RemoteExceptionKind.decodeError => l10n.unknownException(errorCode: 'UE-06'),
        RemoteExceptionKind.serverMaintenance => l10n.maintenanceTitle,
      } +
      _apiInfo;

  @override
  AppExceptionAction get action {
    return switch (kind) {
      RemoteExceptionKind.serverMaintenance => AppExceptionAction.showMaintenanceDialog,
      RemoteExceptionKind.refreshTokenFailed ||
      RemoteExceptionKind.userNotFound =>
        AppExceptionAction.showForceLogoutDialog,
      RemoteExceptionKind.otherServerDefined ||
      RemoteExceptionKind.serverUndefined ||
      RemoteExceptionKind.badCertificate ||
      RemoteExceptionKind.decodeError ||
      RemoteExceptionKind.cancellation ||
      RemoteExceptionKind.unknown =>
        AppExceptionAction.showDialog,
      RemoteExceptionKind.noInternet ||
      RemoteExceptionKind.network ||
      RemoteExceptionKind.timeout =>
        AppExceptionAction.showDialogWithRetry,
    };
  }

  @override
  bool get isForcedErrorToHandle =>
      kind == RemoteExceptionKind.refreshTokenFailed ||
      kind == RemoteExceptionKind.serverMaintenance;
  // ... helper getters: generalServerStatusCode, generalServerMessage, generalServerErrorId
}

enum RemoteExceptionKind {
  noInternet,      // no connectivity
  timeout,         // connect/receive/send timeout
  network,         // host not found, SocketException

  otherServerDefined,   // 4xx with structured error body
  refreshTokenFailed,   // token expired → force logout
  serverMaintenance,    // 503 → maintenance dialog
  userNotFound,         // specific server error

  serverUndefined,      // 5xx without body
  badCertificate,       // SSL certificate issue
  decodeError,          // JSON parsing failure
  cancellation,         // request cancelled
  unknown,              // catch-all fallback
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/exception/remote_exception.dart)

> 🔎 **Quan sát**
> - **12 `RemoteExceptionKind`** — mỗi kind là một loại network/API error cụ thể. Không dùng generic "network error" → phân biệt rõ để xử lý UI khác nhau.
> - `switch (kind)` trong cả `message` và `action` — Dart 3 **switch expression** exhaustive: thêm enum value mới → compiler báo lỗi ở **tất cả** switch → không quên handle.
> - `message` getter trả về **localized string** (`l10n.noInternetException`) + debug info (`_apiInfo`). Production/test ẩn API path → bảo mật.
> - `action` getter mapping: network errors → `showDialogWithRetry` (user có thể retry), server 4xx → `showDialog`, token/maintenance → forced actions.
> - `isForcedErrorToHandle` — chỉ `refreshTokenFailed` + `serverMaintenance` → ViewModel phải handle, không skip được.
> - `or pattern` (`||`) trong switch: `RemoteExceptionKind.refreshTokenFailed || RemoteExceptionKind.userNotFound => showForceLogoutDialog` — Dart 3 pattern matching, gọn hơn multiple cases.
> - **Hỏi:** Tại sao `_apiInfo` check `Env.flavor == Flavor.production` → trả empty string?

> 💡 **FE Perspective**
> **Flutter:** `RemoteException` dùng `RemoteExceptionKind` enum (12 kinds) + Dart 3 switch expression exhaustive — mỗi kind tự khai báo `message` (l10n) và `action` (UI behavior).
> **React/Vue tương đương:** Axios interceptor phân loại error bằng `if/else` chain: `error.code === 'ECONNABORTED'` → timeout, `status === 503` → maintenance, `status === 401` → unauthorized.
> **Khác biệt quan trọng:** Dart enum + switch expression → compiler-checked exhaustive (thêm kind mới → compile error ở mọi switch). FE if/else chain → dễ miss case, không có exhaustive check.

---

## validation_exception.dart — Form Validation Errors

<!-- AI_VERIFY: base_flutter/lib/exception/validation_exception.dart -->
```dart
class ValidationException extends AppException {
  ValidationException({
    required this.kind,
    super.rootException,
    super.onRetry,
  }) : super();

  final ValidationExceptionKind kind;

  @override
  String toString() {
    return 'ValidationException(kind: $kind, ${super.toString()})';
  }

  @override
  AppExceptionAction get action => AppExceptionAction.doNothing;

  @override
  String get message => switch (kind) {
        ValidationExceptionKind.invalidEmail => l10n.invalidEmail,
        ValidationExceptionKind.invalidPassword => l10n.invalidPassword,
        ValidationExceptionKind.passwordsDoNotMatch => l10n.passwordsAreNotMatch,
      };
}

enum ValidationExceptionKind {
  invalidEmail,
  invalidPassword,
  passwordsDoNotMatch,
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/exception/validation_exception.dart)

> 🔎 **Quan sát**
> - `action => AppExceptionAction.doNothing` — validation errors **không hiện dialog**. UI layer tự handle (show inline error message dưới text field).
> - 3 `ValidationExceptionKind` — mỗi loại validation có localized message riêng.
> - Pattern giống `RemoteException`: `kind` enum + `switch` expression cho `message`. Nhưng **action cố định** `doNothing` → validation errors là silent exceptions, caller tự quyết hiển thị.
> - **Hỏi:** Caller nào catch `ValidationException` và hiển thị error message trên UI? (→ Preview: ViewModel ở [M7](../module-07-base-viewmodel/))

---

## app_firebase_auth_exception.dart — Firebase Auth Errors

<!-- AI_VERIFY: base_flutter/lib/exception/app_firebase_auth_exception.dart -->
```dart
class AppFirebaseAuthException extends AppException {
  AppFirebaseAuthException({
    required this.kind,
    super.rootException,
    super.onRetry,
  }) : super();

  final AppFirebaseAuthExceptionKind kind;

  @override
  String toString() {
    return 'AppFirebaseAuthExceptionKind(kind: $kind, ${super.toString()})';
  }

  @override
  String get message => switch (kind) {
        AppFirebaseAuthExceptionKind.invalidEmail => l10n.invalidEmail,
        AppFirebaseAuthExceptionKind.userDoesNotExist => l10n.userDoesNotExist,
        AppFirebaseAuthExceptionKind.invalidLoginCredentials => l10n.invalidLoginCredentials,
        AppFirebaseAuthExceptionKind.usernameAlreadyInUse => l10n.usernameAlreadyInUse,
        AppFirebaseAuthExceptionKind.requiresRecentLogin => l10n.requiresRecentLogin,
        AppFirebaseAuthExceptionKind.unknown => l10n.unknownException(errorCode: 'FBA-001'),
      };

  @override
  AppExceptionAction get action => AppExceptionAction.doNothing;
}

enum AppFirebaseAuthExceptionKind {
  invalidEmail,
  invalidLoginCredentials,
  userDoesNotExist,
  usernameAlreadyInUse,
  requiresRecentLogin,
  unknown,
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/exception/app_firebase_auth_exception.dart)

> 🔎 **Quan sát**
> - Cùng pattern với `ValidationException`: `kind` enum + `action = doNothing` + localized `message`.
> - **6 kinds** phủ các Firebase Auth errors phổ biến. `unknown` là catch-all với error code `FBA-001`.
> - `action => doNothing` — giống validation: caller (ViewModel) tự quyết cách hiển thị. Firebase auth errors thường show inline trên login screen.
> - **Error code pattern:** `FBA-001` (Firebase Auth), `UE-0x` (Remote Unknown Error) → team dễ trace lỗi từ user report.
> - **Hỏi:** Đâu là nơi convert `FirebaseAuthException` (từ Firebase SDK) → `AppFirebaseAuthException`? (→ Preview: mapper pattern bên dưới, hoặc repository layer ở [M12](../module-12-data-layer/))

🏁 **Checkpoint:** Đã đọc xong các exception subtypes (Remote, Validation, Firebase). Tóm tắt 1 câu trước khi tiếp tục.

---

## app_uncaught_exception.dart — Catch-All Fallback

<!-- AI_VERIFY: base_flutter/lib/exception/app_uncaught_exception.dart -->
```dart
class AppUncaughtException extends AppException {
  AppUncaughtException({
    super.rootException,
    super.onRetry,
  }) : super();

  @override
  String toString() {
    return 'AppUncaughtException(${super.toString()})';
  }

  @override
  String get message => l10n.unknownException(errorCode: 'UE-00');

  @override
  AppExceptionAction get action => AppExceptionAction.doNothing;
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/exception/app_uncaught_exception.dart)

> 🔎 **Quan sát**
> - **Đơn giản nhất** — không có `kind` enum, message cố định `UE-00`.
> - Dùng khi bắt được exception mà **không thuộc** bất kỳ subtype nào → safety net.
> - `rootException` vẫn lưu exception gốc → debug qua Crashlytics hoặc log.
> - `action = doNothing` — uncaught exceptions → log, không tự ý show UI. `runZonedGuarded` (M1) và `Result.fromAsyncAction` (M3) là nơi bắt chúng.

---

## exception_handler.dart — Centralized UI Dispatch

> 🔮 **Preview:** Code này dùng `appNavigatorProvider` (M05) và `sharedViewModelProvider` (M07). Hiện tại đọc như 'service inject qua DI' — sẽ hiểu rõ sau.

<!-- AI_VERIFY: base_flutter/lib/exception/exception_handler/exception_handler.dart -->
```dart
final exceptionHandlerProvider = Provider<ExceptionHandler>(
  (ref) => ExceptionHandler(ref),
);

class ExceptionHandler {
  const ExceptionHandler(this._ref);

  final Ref _ref;

  Future<void> handleException(AppException appException) async {
    if (appException.recordError) {
      await _ref.read(crashlyticsHelperProvider).recordError(
            exception: appException,
            stack: StackTrace.current,
            reason: appException.message,
          );
    }

    Log.e('handleException: $appException');

    switch (appException.action) {
      case AppExceptionAction.showSnackBar:
        _ref.read(appNavigatorProvider)
            .showSnackBar(CommonSnackBar.error(message: appException.message));
        break;
      case AppExceptionAction.showDialog:
        await _ref.read(appNavigatorProvider).showDialog(
              ErrorDialog.error(message: appException.message),
            );
        break;
      case AppExceptionAction.showDialogWithRetry:
        if (appException.onRetry != null) {
          await _ref.read(appNavigatorProvider).showDialog(
            ErrorDialog.errorWithRetry(
              message: appException.message,
              onRetryPressed: () async {
                await appException.onRetry?.call();
              },
            ),
          );
        } else {
          await _ref.read(appNavigatorProvider).showDialog(
            ErrorDialog.error(message: appException.message),
          );
        }
        break;
      case AppExceptionAction.showForceLogoutDialog:
        await _ref.read(appNavigatorProvider).showDialog(
              ErrorDialog.error(message: appException.message),
            );
        try {
          await _ref.read(sharedViewModelProvider).forceLogout();
        } catch (e) {
          Log.e('force logout error: $e');
          await _ref.read(appNavigatorProvider).replaceAll([const LoginRoute()]);
        }
        break;
      case AppExceptionAction.showNonCancelableDialog:
        await _ref.read(appNavigatorProvider).showDialog(
              ErrorDialog.error(message: appException.message),
              barrierDismissible: false,
              canPop: false,
            );
        break;
      case AppExceptionAction.showMaintenanceDialog:
        await _ref.read(appNavigatorProvider).showDialog(
              MaintenanceModeDialog(message: appException.message),
              barrierDismissible: false,
              canPop: false,
            );
        break;
      case AppExceptionAction.doNothing:
        break;
    }
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/exception/exception_handler/exception_handler.dart)

> 🔎 **Quan sát**
> - **Single method** `handleException(AppException)` — nhận **bất kỳ** AppException subtype → dispatch dựa trên `appException.action`.
> - `exceptionHandlerProvider` — Riverpod `Provider` → inject via DI, accessible từ bất kỳ ViewModel nào.
> - `switch (appException.action)` — **7 cases** khớp 7 `AppExceptionAction` values → **exhaustive**. Thêm action mới → compiler force thêm case.
> - **Crashlytics recording:** `if (recordError)` → gửi lên Firebase Crashlytics cho monitoring. Default `false` → chỉ record khi subtype opt-in.
> - **Retry pattern:** `showDialogWithRetry` check `onRetry != null` → inject retry callback từ exception. Nếu không có retry → fallback dialog thường.
> - **Force logout flow:** show error dialog → `forceLogout()` → nếu fail → hard navigate to Login. **Double-safety** — không để user stuck.
> - **Maintenance:** `barrierDismissible: false, canPop: false` → user **không thể dismiss** → forced acknowledgment.
> - `doNothing: break` — validation/firebase/uncaught exceptions → handler skip, caller tự xử lý.
> - **Hỏi:** Ai gọi `handleException`? (→ Preview: ViewModel base class ở [M7](../module-07-base-viewmodel/))

> 💡 **FE Perspective**
> **Flutter:** `ExceptionHandler` centralized — nhận `AppException`, đọc `action` enum, dispatch UI (snackbar/dialog/force logout/maintenance). Một method xử lý **tất cả** error types.
> **React/Vue tương đương:** Global error handler function `handleError(error)` → `if (action === 'toast') showToast()` — hoặc Axios interceptor + Error Boundary.
> **Khác biệt quan trọng:** Flutter centralize 100% error → UI dispatch trong 1 class. FE thường scatter (mỗi component tự catch, interceptor xử lý 1 phần) → inconsistent error UX.

🏁 **Checkpoint:** Đã đọc xong `exception_handler.dart` — centralized dispatch. Tóm tắt 1 câu trước khi tiếp tục.

---

## app_exception_mapper.dart — Mapper Interface

<!-- AI_VERIFY: base_flutter/lib/exception/exception_mapper/app_exception_mapper.dart -->
```dart
abstract class AppExceptionMapper<T extends AppException> {
  T map({
    required Object? exception,
    required ApiInfo apiInfo,
  });
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/exception/exception_mapper/app_exception_mapper.dart)

> 🔎 **Quan sát**
> - **Generic abstract class** — `T extends AppException` → mapper output phải là `AppException` subtype.
> - `map()` nhận raw `Object? exception` (bất kỳ error) + `ApiInfo` (request context) → trả về typed `T`.
> - Pattern: **Transform untyped → typed** — raw exceptions từ libraries (Dio, Firebase, ...) → app-specific `AppException`.
> - Chỉ **8 lines** nhưng define contract cho **mọi exception mapper** trong project.

---

## dio_exception_mapper.dart — Dio → RemoteException Transformation

<!-- AI_VERIFY: base_flutter/lib/exception/exception_mapper/dio_exception_mapper.dart -->
```dart
class DioExceptionMapper extends AppExceptionMapper<RemoteException> {
  DioExceptionMapper(this._errorResponseDecoder);

  final BaseErrorResponseDecoder<dynamic> _errorResponseDecoder;

  @override
  RemoteException map({
    required Object? exception,
    required ApiInfo apiInfo,
  }) {
    if (exception is RemoteException) {
      return exception;
    }

    if (exception is DioException) {
      switch (exception.type) {
        case DioExceptionType.cancel:
          return RemoteException(kind: RemoteExceptionKind.cancellation);
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return RemoteException(
            kind: RemoteExceptionKind.timeout,
            rootException: exception,
          );
        case DioExceptionType.badResponse:
          final dioStatusCode = exception.response?.statusCode ?? -1;

          if (dioStatusCode == HttpStatus.serviceUnavailable) {
            return RemoteException(
              kind: RemoteExceptionKind.serverMaintenance,
              dioStatusCode: dioStatusCode,
              rootException: exception,
            );
          }

          if (exception.response?.data != null) {
            final serverError = _errorResponseDecoder.map(
                errorResponse: exception.response!.data!, apiInfo: apiInfo);

            return switch (serverError.generalServerErrorId) {
              Constant.userNotFoundErrorId => RemoteException(
                  kind: RemoteExceptionKind.userNotFound,
                  dioStatusCode: dioStatusCode,
                  serverError: serverError,
                ),
              _ => RemoteException(
                  kind: RemoteExceptionKind.otherServerDefined,
                  dioStatusCode: dioStatusCode,
                  serverError: serverError,
                ),
            };
          }

          return RemoteException(
            kind: RemoteExceptionKind.serverUndefined,
            dioStatusCode: dioStatusCode,
            rootException: exception,
          );
        case DioExceptionType.badCertificate:
          return RemoteException(
            kind: RemoteExceptionKind.badCertificate,
            rootException: exception,
          );
        case DioExceptionType.connectionError:
          return RemoteException(kind: RemoteExceptionKind.network, rootException: exception);
        case DioExceptionType.unknown:
          if (exception.error is SocketException) {
            return RemoteException(kind: RemoteExceptionKind.network, rootException: exception);
          }
          if (exception.error is RemoteException) {
            return exception.error as RemoteException;
          }
      }
    }

    return RemoteException(kind: RemoteExceptionKind.unknown, rootException: exception);
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/exception/exception_mapper/dio_exception_mapper.dart)

> 🔎 **Quan sát**
> - **Idempotent check:** `if (exception is RemoteException) return exception` — nếu đã mapped rồi, trả lại luôn. Tránh double-mapping.
> - `DioExceptionType` switch — map 7 Dio exception types → `RemoteExceptionKind`:
>   - `cancel` → `cancellation`
>   - `connectionTimeout` / `receiveTimeout` / `sendTimeout` → `timeout`
>   - `badResponse` → phức tạp nhất: check HTTP status + parse server error body
>   - `badCertificate` → `badCertificate`
>   - `connectionError` → `network`
>   - `unknown` → check inner error (SocketException? RemoteException?)
> - **badResponse deep mapping:** `503 → serverMaintenance`, có response data → parse `ServerError` → check `generalServerErrorId` → `userNotFound` hoặc `otherServerDefined`, không có data → `serverUndefined`.
> - `_errorResponseDecoder.map()` — decode raw JSON response → `ServerError` object. Injected via constructor → testable, swappable.
> - **Fallback:** cuối cùng luôn trả `RemoteExceptionKind.unknown` → **không bao giờ throw exception** từ mapper → safe.
> - **Hỏi:** GraphQL module (commented out) sẽ cần mapper riêng hay extend `DioExceptionMapper`?

> 💡 **FE Perspective**
> **Flutter:** `DioExceptionMapper` tách riêng thành class — nhận raw `DioException`, switch trên `DioExceptionType`, trả typed `RemoteException`. Idempotent check + fallback `unknown`.
> **React/Vue tương đương:** Axios interceptor inline: `interceptors.response.use(null, error => { if (status === 503) ... })` — mapping logic trộn chung trong interceptor callback.
> **Khác biệt quan trọng:** Dart mapper là class riêng (testable, injectable, single responsibility). FE mapping logic thường inline trong interceptor → khó test, khó reuse, mix concerns.

---

## graphql_exception_mapper.dart — (Placeholder)

📌 `graphql_exception_mapper.dart` hiện tại chỉ chứa placeholder comments — xác nhận rằng pattern này extensible theo Open/Closed Principle. Khi project thêm GraphQL support, mapper mới sẽ follow cùng pattern như `dio_exception_mapper.dart`.

→ [Mở file gốc](../../base_flutter/lib/exception/exception_mapper/graphql_exception_mapper.dart)

---

## Code Walk Summary

### Exception Hierarchy

```
AppException (abstract — contract)
├── RemoteException       → 12 kinds, API/network errors
│   ├── message: localized + debug API info
│   ├── action: dialog/retry/force logout/maintenance
│   └── isForcedErrorToHandle: token + maintenance
├── ValidationException   → 3 kinds, form validation
│   ├── message: localized per kind
│   └── action: always doNothing
├── AppFirebaseAuthException → 6 kinds, Firebase auth
│   ├── message: localized per kind
│   └── action: always doNothing
└── AppUncaughtException  → catch-all fallback
    ├── message: generic UE-00
    └── action: always doNothing
```

### Error Flow (End-to-End)

```
Raw Error (DioException, FirebaseAuthException, ...)
    │
    ▼
ExceptionMapper.map()  → typed AppException subtype
    │
    ▼
Result.failure(AppException)  → propagate through layers (M3)
    │
    ▼
ViewModel catches → ref.read(exceptionHandlerProvider).handleException(e)
    │
    ▼
ExceptionHandler.handleException()
    │
    ├── recordError? → Crashlytics
    ├── Log.e()
    └── switch (action) → UI: snackbar / dialog / retry / force logout / maintenance / nothing
```

### Key Patterns Observed

| Pattern | File | Ý nghĩa |
|---------|------|----------|
| Abstract contract | `app_exception.dart` | `message` + `action` bắt buộc mọi subtype |
| Enum-driven dispatch | `AppExceptionAction` → `ExceptionHandler` | Action enum quyết định UI behavior |
| Switch expression exhaustive | `remote_exception.dart` | Thêm enum → compiler enforce handle |
| Mapper pattern | `AppExceptionMapper<T>` → `DioExceptionMapper` | Raw → typed transformation, testable |
| Exception chaining | `rootException: Object?` | Không mất debug context |
| Retry callback | `onRetry: Future<void> Function()?` | Logic retry gắn vào exception |
| Idempotent mapping | `if (exception is RemoteException) return` | Safe double-mapping prevention |
| Error code convention | `UE-0x`, `FBA-001` | Traceable error codes cho user reports |

→ Tiếp theo: [02-concept.md](./02-concept.md) — giải thích 7 concepts rút ra từ code walk.

<!-- AI_VERIFY: generation-complete -->
