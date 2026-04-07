# Code Walk — Data Layer & API Integration

> 📌 **Recap:** M2 — DI `@LazySingleton()`, `getIt.get<T>()` | M3 — `Constant` class (URLs, timeouts) | M4 — `DioExceptionMapper` → `RemoteException` | M7 — `runCatching` trong BaseViewModel
> → Chưa nắm vững? Quay lại [Module 2](../module-02-architecture-barrel/), [Module 3](../module-03-common-layer/), [Module 4](../module-04-exception-handling/) hoặc [Module 7](../module-07-base-viewmodel/).

---

## Walk Order

```
Data layer structure overview
    ↓
DioBuilder (Dio factory)
    ↓
RestApiClient (generic REST client)
    ↓
NoneAuthAppServerApiClient (no-auth client)
    ↓
AuthAppServerApiClient (auth client with interceptors)
    ↓
AppApiService (service facade)
    ↓
AppPreferences (local storage)
    ↓
AppDatabase (DB wrapper)
```

Bắt đầu từ **infrastructure** (Dio factory) → **generic client** → **concrete clients** → **service facade** → **local storage**.

---

## 1. Data Layer Structure — Folder Organization

<!-- AI_VERIFY: base_flutter/lib/data_source/ -->
```
lib/data_source/
├── api/
│   ├── app_api_service.dart          ← facade cho tất cả API calls
│   ├── client/
│   │   ├── base/
│   │   │   ├── rest_api_client.dart  ← generic REST client (Dio wrapper)
│   │   │   ├── dio_builder.dart      ← Dio factory
│   │   │   └── graphql_api_client.dart
│   │   ├── auth_app_server_api_client.dart
│   │   ├── none_auth_app_server_api_client.dart
│   │   ├── refresh_token_api_client.dart
│   │   ├── random_user_api_client.dart
│   │   └── raw_api_client.dart
│   ├── json_decoder/                 ← response decoders
│   │   ├── base_success_response_decoder.dart
│   │   ├── base_error_response_decoder.dart
│   │   ├── success_response_decoder/
│   │   └── error_response_decoder/
│   ├── middleware/                    ← interceptors
│   │   ├── base_interceptor.dart
│   │   ├── access_token_interceptor.dart
│   │   ├── refresh_token_interceptor.dart
│   │   ├── header_interceptor.dart
│   │   ├── basic_auth_interceptor.dart
│   │   ├── connectivity_interceptor.dart
│   │   ├── custom_log_interceptor.dart
│   │   └── retry_on_error_interceptor.dart
│   └── paging/                       ← pagination executors
├── database/
│   └── app_database.dart
├── firebase/
│   ├── firestore/
│   └── messaging/
└── preference/
    └── app_preferences.dart
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/`](../../base_flutter/lib/data_source/)

- `api/` — HTTP: clients, decoders, interceptors, pagination
- `database/` — local DB wrapper
- `firebase/` — Firebase services
- `preference/` — SharedPreferences / encrypted storage

> 📖 **Thuật ngữ Data Layer — Cần biết trước khi đọc tiếp**
>
> | Thuật ngữ | Giải thích ngắn |
> |-----------|----------------|
> | **Dio** | HTTP client phổ biến cho Dart — interceptors, FormData, cancel token, timeout. Tương đương **Axios**. |
> | **Interceptor** | Middleware chạy trước/sau mỗi HTTP request. `handler.next()` = `next()` trong Express. |
> | **Decoder\<T\>** | `T Function(dynamic json)` — parse raw JSON thành typed model. Tương đương zod `.parse()`. |
> | **safeCast\<T\>()** | Cast an toàn → `null` nếu type không khớp. Defined in `lib/common/util/object_util.dart`. |
> | **DataResponse\<T\> / PagingDataResponse\<T\>** | Response wrappers — `{ data: T }` và `{ data: T[], meta: {...} }`. |

---

## 2. DioBuilder — Dio Factory

<!-- AI_VERIFY: base_flutter/lib/data_source/api/client/base/dio_builder.dart -->
```dart
class DioBuilder {
  const DioBuilder._();

  static Dio createDio({
    BaseOptions? options,
    List<Interceptor> Function(Dio)? interceptors,
  }) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: options?.connectTimeout ?? Constant.connectTimeout,
        receiveTimeout: options?.receiveTimeout ?? Constant.receiveTimeout,
        sendTimeout: options?.sendTimeout ?? Constant.sendTimeout,
        baseUrl: options?.baseUrl ?? Constant.appApiBaseUrl,
      ),
    );

    final sortedInterceptors =
        (interceptors?.call(dio) ?? <Interceptor>[]).sortedByDescending((element) {
      return element.safeCast<BaseInterceptor>()?.type.priority ?? -1;
    });

    dio.interceptors.addAll(sortedInterceptors);

    return dio;
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/client/base/dio_builder.dart`](../../base_flutter/lib/data_source/api/client/base/dio_builder.dart)

- `const DioBuilder._()` — utility class, không instantiate
- `interceptors?.call(dio)` — callback nhận Dio instance → trả danh sách interceptors
- **`sortedByDescending` theo priority** — thứ tự chạy phụ thuộc priority

**Interceptor Priority (cao → chạy trước trong request):**

```
retryOnError (100) → connectivity (99) → basicAuth (40) →
refreshToken (30) → accessToken (20) → header (10) → customLog (1)
```

---

## 3. RestApiClient — Generic REST Client

<!-- AI_VERIFY: base_flutter/lib/data_source/api/client/base/rest_api_client.dart -->
```dart
class RestApiClient {
  RestApiClient({
    required this.dio,
    this.errorResponseDecoderType = Constant.defaultErrorResponseDecoderType,
    this.successResponseDecoderType = Constant.defaultSuccessResponseDecoderType,
  });

  final SuccessResponseDecoderType successResponseDecoderType;
  final ErrorResponseDecoderType errorResponseDecoderType;
  final Dio dio;

  Future<FinalOutput?> request<FirstOutput extends Object, FinalOutput extends Object>({
    required RestMethod method,
    required String path,
    Map<String, dynamic>? queryParameters,
    Object? body,
    Decoder<FirstOutput>? decoder,
    SuccessResponseDecoderType? successResponseDecoderType,
    ErrorResponseDecoderType? errorResponseDecoderType,
    Options? options,
    FinalOutput? Function(Response<dynamic> response)? customSuccessResponseDecoder,
  }) async {
    // ...
    try {
      final response = await _requestByMethod(
        method: method, path: path,
        queryParameters: queryParameters, body: body, options: options,
      );

      if (response.data == null) return null;

      if (customSuccessResponseDecoder != null) {
        return customSuccessResponseDecoder(response);
      }

      return BaseSuccessResponseDecoder<FirstOutput, FinalOutput>.fromType(
        successResponseDecoderType ?? this.successResponseDecoderType,
      ).map(response: response.data, decoder: decoder);
    } catch (error, _) {
      throw DioExceptionMapper(
        BaseErrorResponseDecoder.fromType(
          errorResponseDecoderType ?? this.errorResponseDecoderType,
        ),
      ).map(exception: error, apiInfo: ApiInfo(method: method.name, url: path));
    }
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/client/base/rest_api_client.dart`](../../base_flutter/lib/data_source/api/client/base/rest_api_client.dart)

> `SuccessResponseDecoderType` có 6 values: `.dataJsonObject` (wrapped single object `{data:{...}}`), `.dataJsonArray` (wrapped list `{data:[...]}`), `.jsonObject` (raw object), `.jsonArray` (raw list), `.paging` (list + meta pagination), `.plain` (raw string). Default set trong `Constant`. Dùng parameter `successResponseDecoderType` để override per-request khi API format khác default.

### Generic Type System

```
request<FirstOutput, FinalOutput>()
         ↓              ↓
   Model type      Response wrapper type
   (UserData)      (DataResponse<UserData>)
```

### Request Flow

```
request() → _requestByMethod() → dio.get/post/put/... → Interceptors → Server
    ↓ success
BaseSuccessResponseDecoder.fromType().map(response, decoder) → FinalOutput
    ↓ error
DioExceptionMapper(BaseErrorResponseDecoder) → throws RemoteException (M4)
```

→ `_requestByMethod()` — clean switch: `RestMethod` enum map trực tiếp sang `dio.get/post/patch/put/delete`.

---

## 4. NoneAuthAppServerApiClient — Non-Auth Client

<!-- AI_VERIFY: base_flutter/lib/data_source/api/client/none_auth_app_server_api_client.dart -->
```dart
@LazySingleton()
class NoneAuthAppServerApiClient extends RestApiClient {
  NoneAuthAppServerApiClient()
      : super(
          dio: DioBuilder.createDio(
            options: BaseOptions(baseUrl: Constant.appApiBaseUrl),
            interceptors: (dio) => [
              CustomLogInterceptor(),
              ConnectivityInterceptor(getIt.get<ConnectivityHelper>()),
              RetryOnErrorInterceptor(dio, RetryOnErrorInterceptorHelper()),
              BasicAuthInterceptor(),
              HeaderInterceptor(
                packageHelper: getIt.get<PackageHelper>(),
                deviceHelper: getIt.get<DeviceHelper>(),
              ),
            ],
          ),
        );
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/client/none_auth_app_server_api_client.dart`](../../base_flutter/lib/data_source/api/client/none_auth_app_server_api_client.dart)

> 💡 **Phân biệt API Auth vs User Auth**: `NoneAuth` ở đây nghĩa là **không có User Authentication** (không gửi Bearer token). `BasicAuthInterceptor` gửi **API-level credentials** (API key) — giống như API key trong header `X-API-Key`. Đừng nhầm lẫn: `BasicAuth` = client credentials, `Bearer` = user credentials.

## 5. AuthAppServerApiClient — Auth Client

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
              ConnectivityInterceptor(getIt.get<ConnectivityHelper>()),
              RetryOnErrorInterceptor(dio, RetryOnErrorInterceptorHelper()),
              BasicAuthInterceptor(),
              HeaderInterceptor(
                packageHelper: getIt.get<PackageHelper>(),
                deviceHelper: getIt.get<DeviceHelper>(),
              ),
              AccessTokenInterceptor(getIt.get<AppPreferences>()),
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

**So sánh interceptor chain:**

| # | Interceptor | Non-Auth | Auth | Vai trò |
|---|------------|----------|------|---------|
| 1 | `CustomLogInterceptor` | ✅ | ✅ | Log request/response |
| 2 | `ConnectivityInterceptor` | ✅ | ✅ | Check mạng |
| 3 | `RetryOnErrorInterceptor` | ✅ | ✅ | Retry lỗi mạng |
| 4 | `BasicAuthInterceptor` | ✅ | ✅ | Basic auth header |
| 5 | `HeaderInterceptor` | ✅ | ✅ | Device/package info |
| 6 | `AccessTokenInterceptor` | ❌ | ✅ | Bearer token |
| 7 | `RefreshTokenInterceptor` | ❌ | ✅ | Auto refresh khi 401 |

→ Chi tiết từng interceptor: xem [Module 13 § code-walk](../module-13-middleware-interceptor-chain/01-code-walk.md).

---

## 6. AppApiService — Service Facade

<!-- AI_VERIFY: base_flutter/lib/data_source/api/app_api_service.dart -->
```dart
final appApiServiceProvider = Provider<AppApiService>(
  (ref) => getIt.get<AppApiService>(),
);

@LazySingleton()
class AppApiService {
  AppApiService(
    this._noneAuthAppServerApiClient,
    this._authAppServerApiClient,
    this._uploadFileServerApiClient,
  );

  final NoneAuthAppServerApiClient _noneAuthAppServerApiClient;
  final AuthAppServerApiClient _authAppServerApiClient;
  final UploadFileServerApiClient _uploadFileServerApiClient;
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/app_api_service.dart`](../../base_flutter/lib/data_source/api/app_api_service.dart)

**3 injected clients:**

| Client | Dùng cho | Token handling |
|--------|---------|---------------|
| `_noneAuthAppServerApiClient` | Login, forgot password, public data | Không có token interceptors |
| `_authAppServerApiClient` | Protected endpoints (getMe, logout, CRUD) | AccessToken + RefreshToken |
| `_uploadFileServerApiClient` | File upload (S3 pre-signed URLs) | Minimal interceptors |

### Method Pattern — Login (Non-Auth)

```dart
Future<TokenAndRefreshTokenData> login({
  required String email,
  required String password,
}) async {
  final tokenAndRefreshTokenData = await _noneAuthAppServerApiClient
      .request<TokenAndRefreshTokenData, DataResponse<TokenAndRefreshTokenData>>(
    method: RestMethod.post,
    path: 'v1/login',
    body: {'email': email.trim(), 'password': password},
    decoder: (json) =>
        TokenAndRefreshTokenData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
  );
  return tokenAndRefreshTokenData?.data ?? const TokenAndRefreshTokenData();
}
```

**Anatomy:** Client choice → Generic types → Method + path → Body → Decoder callback → Null safety fallback.

### Method Pattern — Protected (Auth)

```dart
Future<UserData> getMe() async {
  final response = await _authAppServerApiClient
      .request<UserData, DataResponse<UserData>>(
    method: RestMethod.get,
    path: 'v1/me',
    decoder: (json) => UserData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
  );
  return response?.data ?? const UserData();
}
```

→ Dùng `_authAppServerApiClient` — auto gắn Bearer token.

### Method Pattern — Pagination

```dart
Future<PagingDataResponse<NotificationData>?> getNotifications({
  required int page,
  required int limit,
  bool? isRead,
}) async {
  return _authAppServerApiClient
      .request<NotificationData, PagingDataResponse<NotificationData>>(
    method: RestMethod.get,
    path: 'v1/notifications',
    queryParameters: {
      'page': page, 'limit': limit,
      if (isRead != null) 'is_read': isRead,
    },
    successResponseDecoderType: SuccessResponseDecoderType.paging,
    decoder: (json) => NotificationData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
  );
}
```

→ `SuccessResponseDecoderType.paging` cho pagination response. Conditional entry `if (isRead != null)`.

---

## 7. Response Decoder Pipeline

<!-- AI_VERIFY: base_flutter/lib/data_source/api/json_decoder/base_success_response_decoder.dart -->
```dart
enum SuccessResponseDecoderType {
  dataJsonObject,   // { "data": { ... } }
  dataJsonArray,    // { "data": [ ... ] }
  jsonObject,       // { ... }  (no wrapper)
  jsonArray,        // [ ... ]
  paging,           // { "data": [...], "meta": { "page": ..., "total": ... } }
  plain,            // raw response (no decode)
}

abstract class BaseSuccessResponseDecoder<I extends Object, O extends Object> {
  factory BaseSuccessResponseDecoder.fromType(SuccessResponseDecoderType type) {
    return switch (type) {
      SuccessResponseDecoderType.dataJsonObject =>
        DataJsonObjectResponseDecoder<I>() as BaseSuccessResponseDecoder<I, O>,
      SuccessResponseDecoderType.paging =>
        PagingDataResponseDecoder<I>() as BaseSuccessResponseDecoder<I, O>,
      // ... other types
    };
  }

  O? map({required dynamic response, Decoder<I>? decoder}) {
    try {
      return mapToDataModel(response: response, decoder: decoder);
    } on RemoteException catch (_) {
      rethrow;
    } catch (e) {
      throw RemoteException(kind: RemoteExceptionKind.decodeError, rootException: e);
    }
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/json_decoder/base_success_response_decoder.dart`](../../base_flutter/lib/data_source/api/json_decoder/base_success_response_decoder.dart)

**Pipeline:** Raw JSON → `fromType(enum)` → concrete decoder → `decoder` callback `(json) => Model.fromJson(json)` → Typed output.

Error decoder tương tự — factory pattern, same error wrapping → `ServerError` → `DioExceptionMapper` → `RemoteException`.

---

## 8. AppPreferences & AppDatabase — Local Storage (Preview)

`AppPreferences` là lớp quản lý local storage với **3 tầng**: `SharedPreferences` (plain), `EncryptedSharedPreferences` (AES), `FlutterSecureStorage` (Keychain/Keystore).

`AppDatabase` là thin wrapper — hiện delegate sang `AppPreferences`, có thể mở rộng cho Isar/Hive.

→ [Mở file gốc: `lib/data_source/preference/app_preferences.dart`](../../base_flutter/lib/data_source/preference/app_preferences.dart)

> 📖 **Deep dive:** Phân tích chi tiết constructor, 3-tier storage, token encryption, logout cleanup, DI registration → xem **[Module 14 — Local Storage](../module-14-local-storage/01-code-walk.md)**. M14 là nguồn tài liệu chính thức cho toàn bộ local storage patterns.

⚠️ Token luôn encrypted — **KHÔNG BAO GIỜ** lưu plain text. Mobile không có browser sandbox → cần encryption thật sự.

---

## 9. Full Request Lifecycle — End to End

Trace flow khi ViewModel gọi `login()`:

```
ViewModel.login() → runCatching { appApiService.login(email, password) }
    ↓
AppApiService.login() → _noneAuthAppServerApiClient.request<...>(post, 'v1/login', body, decoder)
    ↓
RestApiClient.request() → _requestByMethod() → dio.post()
    ↓
Interceptors (request): RetryOnError → Connectivity → BasicAuth → Header → CustomLog
    ↓ HTTP → Server → Response
Interceptors (response): CustomLog → Header → BasicAuth → Connectivity → RetryOnError
    ↓
BaseSuccessResponseDecoder.map(response, decoder) → DataResponse<TokenAndRefreshTokenData>
    ↓
ViewModel: appPreferences.saveAccessToken / saveRefreshToken → navigate
```

**Error path:**
```
DioException → RestApiClient catch → DioExceptionMapper → RemoteException
    → runCatching catches → ExceptionHandler → UI error display (M4)
```

---

## Tổng kết Walk

| # | File | Pattern chính |
|---|------|--------------|
| 1 | `dio_builder.dart` | Factory, interceptor sorting by priority |
| 2 | `rest_api_client.dart` | Generic REST client, decoder pipeline, error mapping |
| 3-4 | Client classes | Concrete clients, interceptor chain composition |
| 5 | `app_api_service.dart` | Service facade, 3 injected clients |
| 6 | Decoders | Strategy pattern, factory method |
| 7 | `app_preferences.dart` | 3-tier storage, encrypted tokens (→ [M14](../module-14-local-storage/)) |
| 8 | `app_database.dart` | Thin DB wrapper (→ [M14](../module-14-local-storage/)) |

→ Tiếp tục: [02-concept.md](./02-concept.md) — giải thích 7 concepts rút ra từ code walk.

<!-- AI_VERIFY: generation-complete -->
