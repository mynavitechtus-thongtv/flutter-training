# Code Walk — Middleware & Interceptor Chain

> 📌 **Recap:** M4 — `AppException` hierarchy, `DioExceptionMapper` → typed `RemoteException` → UI dispatch | M12 — `RestApiClient`, Auth vs NonAuth clients, `DioBuilder.createDio()`
> → Chưa nắm vững? Quay lại [Module 4](../module-04-exception-handling/) hoặc [Module 12](../module-12-data-layer/).

---

## Walk Order

```
base_interceptor.dart (abstract base + priority enum)
    ↓
AuthAppServerApiClient (interceptor registration order)
    ↓
--- Request Phase (onRequest) ---
CustomLogInterceptor → ConnectivityInterceptor → RetryOnErrorInterceptor
→ BasicAuthInterceptor → HeaderInterceptor → AccessTokenInterceptor
    ↓
--- Response Phase (onResponse) ---
CustomLogInterceptor.onResponse
    ↓
--- Error Phase (onError) ---
RefreshTokenInterceptor → RetryOnErrorInterceptor → CustomLogInterceptor.onError
    ↓
--- Supporting Patterns ---
BaseSuccessResponseDecoder → BaseErrorResponseDecoder → PagingExecutor
```

Bắt đầu từ **base abstraction** → **chain registration** → walk từng interceptor theo **execution order** → supporting patterns.

---

## 1. base_interceptor.dart — Abstract Base & Priority

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/base_interceptor.dart -->
```dart
import 'package:dio/dio.dart';

abstract class BaseInterceptor extends InterceptorsWrapper {
  BaseInterceptor(this.type);

  final InterceptorType type;
}

enum InterceptorType {
  retryOnError(100), // add first
  connectivity(99),  // add second
  basicAuth(40),
  refreshToken(30),
  accessToken(20),
  header(10),
  customLog(1);      // add last

  const InterceptorType(this.priority);

  /// higher, add first
  /// lower, add last
  final int priority;
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/middleware/base_interceptor.dart`](../../base_flutter/lib/data_source/api/middleware/base_interceptor.dart)

- Mọi interceptor kế thừa `BaseInterceptor` → `InterceptorsWrapper` (Dio). 3 hooks: `onRequest`, `onResponse`, `onError`
- `InterceptorType` enum với **priority** — higher = add first vào pipeline, chạy trước trong request phase

---

## 2. AuthAppServerApiClient — Chain Registration

> 📖 **Cross-ref:** Class definition và DI registration đã covered ở [M12 § AuthAppServerApiClient](../module-12-data-layer/01-code-walk.md#5-authappserverapiclient--auth-client). Phần này focus vào **interceptor chain registration order** — trọng tâm của M13.

<!-- AI_VERIFY: base_flutter/lib/data_source/api/client/auth_app_server_api_client.dart -->
```dart
@LazySingleton()
class AuthAppServerApiClient extends RestApiClient {
  AuthAppServerApiClient()
      : super(
          dio: DioBuilder.createDio(
            options: BaseOptions(baseUrl: Constant.appApiBaseUrl),
            interceptors: (dio) => [
              CustomLogInterceptor(),
              ConnectivityInterceptor(
                getIt.get<ConnectivityHelper>(),
              ),
              RetryOnErrorInterceptor(
                dio,
                RetryOnErrorInterceptorHelper(),
              ),
              BasicAuthInterceptor(),
              HeaderInterceptor(
                packageHelper: getIt.get<PackageHelper>(),
                deviceHelper: getIt.get<DeviceHelper>(),
              ),
              AccessTokenInterceptor(
                getIt.get<AppPreferences>(),
              ),
              RefreshTokenInterceptor(
                getIt.get<AppPreferences>(),
                getIt.get<RefreshTokenApiClient>(),
                getIt.get<NoneAuthAppServerApiClient>(),
              ),
            ],
          ),
        );
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/client/auth_app_server_api_client.dart`](../../base_flutter/lib/data_source/api/client/auth_app_server_api_client.dart)

**Auth vs NonAuth vs Upload:**

| Interceptor | AuthClient | NonAuthClient | UploadClient |
|-------------|:----------:|:-------------:|:------------:|
| CustomLogInterceptor | ✅ | ✅ | ✅ |
| ConnectivityInterceptor | ✅ | ✅ | ✅ |
| RetryOnErrorInterceptor | ✅ | ✅ | ✅ |
| BasicAuthInterceptor | ✅ | ✅ | ❌ |
| HeaderInterceptor | ✅ | ✅ | ❌ |
| AccessTokenInterceptor | ✅ | ❌ | ❌ |
| RefreshTokenInterceptor | ✅ | ❌ | ❌ |

→ NonAuth thiếu token interceptors (endpoint không cần auth). Upload chỉ giữ 3 interceptors cơ bản.

---

## 3. CustomLogInterceptor — Request/Response Logging

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/custom_log_interceptor.dart -->
```dart
class CustomLogInterceptor extends BaseInterceptor {
  CustomLogInterceptor() : super(InterceptorType.customLog);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kReleaseMode || !Config.enableLogInterceptor || !Config.enableLogRequestInfo) {
      handler.next(options);
      return;
    }
    // Build log: method, uri, headers, body (FormData aware)
    // _limitLines(maxLines: 150) — truncation
    Log.d(log.join('\n'));
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    // 🎉 log status + body, _limitLines
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ⛔️ log error code + response
    handler.next(err);
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/middleware/custom_log_interceptor.dart`](../../base_flutter/lib/data_source/api/middleware/custom_log_interceptor.dart)

- **Release mode guard:** `kReleaseMode` → skip log hoàn toàn → zero perf impact production
- **Config toggles:** `enableLogRequestInfo`, `enableLogSuccessResponse`, `enableLogErrorResponse` — granular control
- **Truncation:** `_limitLines(maxLines: 150)` — tránh log quá dài
- Luôn gọi `handler.next()` — pass-through, không block pipeline

---

## 4. ConnectivityInterceptor — Network Guard

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/connectivity_interceptor.dart -->
```dart
class ConnectivityInterceptor extends BaseInterceptor {
  ConnectivityInterceptor(this._connectivityHelper)
      : super(InterceptorType.connectivity);

  final ConnectivityHelper _connectivityHelper;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!await _connectivityHelper.isNetworkAvailable) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: RemoteException(kind: RemoteExceptionKind.noInternet),
        ),
      );
    }

    return super.onRequest(options, handler);
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/middleware/connectivity_interceptor.dart`](../../base_flutter/lib/data_source/api/middleware/connectivity_interceptor.dart)

- **`handler.reject()`** short-circuit toàn bộ pipeline → `RemoteExceptionKind.noInternet`
- Flutter dùng `connectivity_plus` (platform-native) — đáng tin cậy hơn `navigator.onLine` trên web

---

## 5. RetryOnErrorInterceptor — Exponential Backoff

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/retry_on_error_interceptor.dart -->
```dart
class RetryOnErrorInterceptor extends BaseInterceptor {
  RetryOnErrorInterceptor(this._dio, this._retryHelper)
      : super(InterceptorType.retryOnError);

  final Dio _dio;
  final RetryOnErrorInterceptorHelper _retryHelper;

  static const retryHeaderKey = 'isRetry';
  static const retryCountKey = 'retryCount';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.headers.containsKey(retryHeaderKey)) {
      options.headers[retryCountKey] = Constant.maxRetries;
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = safeCast<int>(err.requestOptions.headers[retryCountKey]) ?? 0;
    if (retryCount > 0 && shouldRetry(err)) {
      await Future<void>.delayed(_retryHelper.getRetryInterval(retryCount));
      try {
        final response = await _dio.fetch<dynamic>(
          err.requestOptions
            ..headers[retryHeaderKey] = true
            ..headers[retryCountKey] = retryCount - 1,
        );
        return handler.resolve(response);
      } on Object catch (_) {
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool shouldRetry(DioException error) =>
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.sendTimeout;
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/middleware/retry_on_error_interceptor.dart`](../../base_flutter/lib/data_source/api/middleware/retry_on_error_interceptor.dart)

- **Header-based state:** retry count travels **with the request** — stateless interceptor
- **Selective retry:** `shouldRetry()` chỉ retry **timeout + connection errors** — KHÔNG retry business errors (400, 500)
- **`_dio.fetch()`** re-execute qua **full Dio pipeline** (tất cả interceptors chạy lại)
- Exponential backoff qua `getRetryInterval()` — intervals từ `Constant`

---

## 6. BasicAuthInterceptor — Client Credentials

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/basic_auth_interceptor.dart -->
```dart
class BasicAuthInterceptor extends BaseInterceptor {
  BasicAuthInterceptor({
    this.username = Env.appBasicAuthName,
    this.password = Env.appBasicAuthPassword,
  }) : super(InterceptorType.basicAuth);

  final String username;
  final String password;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[Constant.basicAuthorization] =
        _basicAuthenticationHeader();
    return super.onRequest(options, handler);
  }

  String _basicAuthenticationHeader() {
    return 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/middleware/basic_auth_interceptor.dart`](../../base_flutter/lib/data_source/api/middleware/basic_auth_interceptor.dart)

→ Client-level auth, credentials từ `Env` (envied, compile-time). Set `Constant.basicAuthorization` header.

---

## 7. HeaderInterceptor — Device & Package Info

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/header_interceptor.dart -->
```dart
class HeaderInterceptor extends BaseInterceptor {
  HeaderInterceptor({
    required this.packageHelper,
    required this.deviceHelper,
    this.headers = const {},
  }) : super(InterceptorType.header);

  final PackageHelper packageHelper;
  final DeviceHelper deviceHelper;
  final Map<String, dynamic> headers;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final userAgentValue = userAgentClientHintsHeader();
    options.headers[Constant.userAgentKey] = userAgentValue;
    if (headers.isNotEmpty) {
      options.headers.addAll(headers);
    }
    handler.next(options);
  }

  String userAgentClientHintsHeader() {
    return '${deviceHelper.operatingSystem}_${packageHelper.versionName}';
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/middleware/header_interceptor.dart`](../../base_flutter/lib/data_source/api/middleware/header_interceptor.dart)

→ User-Agent = `{OS}_{appVersion}`. Helpers inject qua DI → testable.

---

## 8. AccessTokenInterceptor — Bearer Token Injection

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/access_token_interceptor.dart -->
```dart
class AccessTokenInterceptor extends BaseInterceptor {
  AccessTokenInterceptor(this._appPreferences) : super(InterceptorType.accessToken);

  final AppPreferences _appPreferences;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _appPreferences.accessToken;
    if (token.isNotEmpty) {
      options.headers[Constant.basicAuthorization] = '${Constant.bearer} $token';
    }
    handler.next(options);
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/middleware/access_token_interceptor.dart`](../../base_flutter/lib/data_source/api/middleware/access_token_interceptor.dart)

⚠️ **Order matters:** `BasicAuthInterceptor` set `Constant.basicAuthorization`, rồi `AccessTokenInterceptor` **overwrite** cùng key với `Bearer $token` → Bearer wins. Chỉ có trong **Auth client**.

> 💡 **Header Key Collision**: Cả BasicAuth và Bearer token đều dùng chung header key `Authorization`. Bearer token luôn overwrite Basic Auth vì interceptor chạy sau. Pattern này hoạt động vì backend chỉ cần 1 auth method per request. Nếu backend cần cả 2 simultaneously → cần custom header key riêng.

---

## 9. RefreshTokenInterceptor — Queue-Based Token Refresh

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/refresh_token_interceptor.dart -->
```dart
class RefreshTokenInterceptor extends BaseInterceptor {
  RefreshTokenInterceptor(
    this.appPreferences,
    this.refreshTokenApiClient,
    this.noneAuthAppServerApiClient,
  ) : super(InterceptorType.refreshToken);

  final AppPreferences appPreferences;
  final RefreshTokenApiClient refreshTokenApiClient;
  final NoneAuthAppServerApiClient noneAuthAppServerApiClient;

  var _isRefreshing = false;
  final _queue = Queue<({RequestOptions options, ErrorInterceptorHandler handler})>();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == HttpStatus.unauthorized) {
      final options = err.response!.requestOptions;
      _onExpiredToken(options: options, handler: handler);
    } else {
      handler.next(err);
    }
  }

  Future<void> _onExpiredToken({
    required RequestOptions options,
    required ErrorInterceptorHandler handler,
  }) async {
    _queue.addLast((options: options, handler: handler));
    if (!_isRefreshing) {
      _isRefreshing = true;
      try {
        final newToken = await _refreshToken();
        await _onRefreshTokenSuccess(newToken);
      } catch (e) {
        _onRefreshTokenError(e);
      } finally {
        _isRefreshing = false;
        _queue.clear();
      }
    }
  }

  // _refreshToken(): call API, save new tokens to AppPreferences
  // _onRefreshTokenSuccess(): replay all queued requests with new token
  // _onRefreshTokenError(): forward error to all queued handlers
  // _requestWithNewToken(): attach new token, fetch via noneAuthClient
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/middleware/refresh_token_interceptor.dart`](../../base_flutter/lib/data_source/api/middleware/refresh_token_interceptor.dart)

**Interceptor phức tạp nhất — Queue Pattern:**

```
Request A (401) → add to queue → _isRefreshing = false → START refresh
Request B (401) → add to queue → _isRefreshing = true → SKIP (chờ)
Request C (401) → add to queue → _isRefreshing = true → SKIP (chờ)
    ↓ refresh complete
→ retry A, B, C đồng thời với new token → clear queue
```

**Key design decisions:**
- `_isRefreshing` flag (mutex-like) — chỉ 1 refresh tại 1 thời điểm, chống stampede
- Retry dùng **NoneAuth client** — tránh `AccessTokenInterceptor` overwrite token cũ (race condition)
- Refresh fail → tất cả queued requests nhận error → downstream xử lý (force logout)
- `_queue.clear()` trong `finally` — cleanup dù success hay error

---

## 10. Request Phase — Full Execution Order

```
┌─────────────────────────────────────────────────┐
│               REQUEST PHASE (onRequest)          │
├─────────────────────────────────────────────────┤
│ 1. CustomLogInterceptor    → log request info    │
│ 2. ConnectivityInterceptor → check network       │
│    ↳ NO network → handler.reject() → ERROR PHASE │
│ 3. RetryOnErrorInterceptor → set retryCount      │
│ 4. BasicAuthInterceptor    → set Basic auth      │
│ 5. HeaderInterceptor       → set User-Agent      │
│ 6. AccessTokenInterceptor  → set Bearer token    │
│ 7. (no onRequest for RefreshTokenInterceptor)    │
├─────────────────────────────────────────────────┤
│               → HTTP Request to Server →         │
├─────────────────────────────────────────────────┤
│              RESPONSE PHASE (onResponse)         │
│ 7→1. Reverse order — only CustomLog has logic    │
├─────────────────────────────────────────────────┤
│               ERROR PHASE (onError)              │
│ 7. RefreshTokenInterceptor → catch 401, refresh  │
│ 3. RetryOnErrorInterceptor → retry on timeout    │
│ 1. CustomLogInterceptor    → log error           │
└─────────────────────────────────────────────────┘
```

→ Request phase: registration order (1→7). Response/Error phase: **reverse** (7→1).

---

## 11–12. Response Decoders — Success & Error

Chi tiết decoder pipeline xem [M12 § Response Decoder](../module-12-data-layer/01-code-walk.md#7-response-decoder-pipeline).

<!-- AI_VERIFY: base_flutter/lib/data_source/api/json_decoder/base_success_response_decoder.dart -->
```dart
// SuccessResponseDecoderType: dataJsonObject, dataJsonArray, jsonObject, jsonArray, paging, plain
// BaseSuccessResponseDecoder.fromType(type) → factory → concrete decoder
// map() wraps decode errors as RemoteExceptionKind.decodeError, rethrows RemoteException
```
<!-- END_VERIFY -->

<!-- AI_VERIFY: base_flutter/lib/data_source/api/json_decoder/base_error_response_decoder.dart -->
```dart
// ErrorResponseDecoderType: jsonObject, jsonArray, line
// BaseErrorResponseDecoder.fromType(type) → factory → ServerError
// Symmetric pattern with success decoder
```
<!-- END_VERIFY -->

---

## 13. PagingExecutor — Pagination State Machine

Chi tiết PagingExecutor xem [M12 § code-walk](../module-12-data-layer/01-code-walk.md).

<!-- AI_VERIFY: base_flutter/lib/data_source/api/paging/base/paging_executor.dart -->
```dart
// PagingExecutor<T, P>: Template Method pattern
// execute(isInitialLoad) → action(page, limit, params) [abstract]
// Snapshot/rollback: _oldOutput backup → error → _output = _oldOutput
// Subclass chỉ cần implement action() — map API response → LoadMoreOutput
```
<!-- END_VERIFY -->

<!-- AI_VERIFY: base_flutter/lib/data_source/api/paging/get_notifications_paging_executor.dart -->
```dart
// GetNotificationsPagingExecutor extends PagingExecutor<NotificationData, ...>
// Chỉ override action(): call appApiService.getNotifications() → LoadMoreOutput
```
<!-- END_VERIFY -->

---

## Tổng kết Walk Order

| # | File | Vai trò | Phase |
|---|------|---------|-------|
| 1 | `base_interceptor.dart` | Abstract base + priority enum | Foundation |
| 2 | `auth_app_server_api_client.dart` | Chain registration | Setup |
| 3 | `custom_log_interceptor.dart` | Log request/response/error | Req + Res + Err |
| 4 | `connectivity_interceptor.dart` | Network check, short-circuit | Request |
| 5 | `retry_on_error_interceptor.dart` | Retry timeout/connection | Req + Error |
| 6 | `basic_auth_interceptor.dart` | Client credentials | Request |
| 7 | `header_interceptor.dart` | Device/package info | Request |
| 8 | `access_token_interceptor.dart` | Bearer token | Request |
| 9 | `refresh_token_interceptor.dart` | 401 → refresh + queue retry | Error |
| 10-11 | Decoders | Success/Error response parsing | Post-response |
| 12 | `paging_executor.dart` | Pagination state machine | Application |

→ Tiếp theo: [02-concept.md](./02-concept.md) — 7 concepts rút ra từ code walk.

<!-- AI_VERIFY: generation-complete -->
