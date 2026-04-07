# Verification — Kiểm tra kết quả Module 12

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được tại sao `AppApiService` wrap 3 clients thay vì ViewModel gọi client trực tiếp? | Service Facade | 🔴 |
| 2 | Tôi mô tả được `request<FirstOutput, FinalOutput>()` — generic types, decoder callback, method dispatch? | REST Client Architecture | 🔴 |
| 3 | Tôi phân biệt được interceptor chain giữa Auth vs NoneAuth client — biết khi nào dùng cái nào? | Auth vs Non-Auth | 🔴 |
| 4 | Tôi chọn đúng `SuccessResponseDecoderType` cho response format cụ thể (`dataJsonObject`, `paging`, etc.)? | Decoder Pipeline | 🟡 |
| 5 | Tôi trace được error flow: `DioException` → `DioExceptionMapper` → `RemoteException(kind: ?)` → M4 handler? | Error Mapping | 🟡 |
| 6 | Tôi chọn đúng storage tier (plain/encrypted/secure) cho data type cụ thể? | Local Storage | 🟡 |
| 7 | Tôi mô tả được folder structure data layer — biết đặt file mới ở đâu? | Data Layer Structure | 🟢 |

**Target:** 3/3 Yes cho 🔴 MUST-KNOW, tối thiểu 6/7 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace API Call ⭐

Đáp án tham khảo cho `getMe()`:

| # | Step | File | Code / Action |
|---|------|------|---------------|
| 1 | ViewModel gọi | `*_view_model.dart` | `ref.read(appApiServiceProvider).getMe()` |
| 2 | AppApiService delegate | `app_api_service.dart` | `_authAppServerApiClient.request<UserData, DataResponse<UserData>>(...)` |
| 3 | RestApiClient dispatch | `rest_api_client.dart` | `_requestByMethod(method: RestMethod.get, path: 'v1/me')` |
| 4 | Dio executes | (internal) | `dio.get('v1/me')` |
| 5 | Interceptor — request | `access_token_interceptor.dart` | `options.headers['Authorization'] = 'Bearer <encrypted_token>'` |
| 6 | Server response | (network) | `200 OK + { "data": { "id": 1, "name": "John" } }` |
| 7 | Decoder | `base_success_response_decoder.dart` | `fromType(dataJsonObject) → DataJsonObjectResponseDecoder.mapToDataModel(json, decoder)` |
| 8 | Return | `app_api_service.dart` | `response?.data ?? const UserData()` |

**Verification points:**
- [ ] Step 2: `FirstOutput = UserData`, `FinalOutput = DataResponse<UserData>`
- [ ] Step 5: Token lấy từ `_appPreferences.accessToken` — **encrypted** (`EncryptedSharedPreferences`)
- [ ] Step 7: Default `SuccessResponseDecoderType.dataJsonObject` (không có override)
- [ ] 401 scenario: `RefreshTokenInterceptor.onError()` bắt 401 → refresh token → retry request → nếu refresh fail → `DioExceptionMapper` → `RemoteException`

### Exercise 2 — Add Endpoint ⭐

```dart
Future<PagingDataResponse<UserData>?> getUsers({
  required int page,
  required int limit,
}) async {
  return _authAppServerApiClient.request<UserData, PagingDataResponse<UserData>>(
    method: RestMethod.get,
    path: 'v1/users',
    queryParameters: {
      'page': page,
      'limit': limit,
    },
    successResponseDecoderType: SuccessResponseDecoderType.paging,
    decoder: (json) => UserData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
  );
}
```

**Verification:**
- [ ] Client: `_authAppServerApiClient` (cần auth)
- [ ] Generic: `<UserData, PagingDataResponse<UserData>>`
- [ ] Decoder type: `SuccessResponseDecoderType.paging`
- [ ] `queryParameters` map đúng
- [ ] `decoder` callback đúng pattern `fromJson`

### Exercise 3 — Secure Storage ⭐⭐

- [ ] Key: `static const keyDeviceId = 'deviceId'`
- [ ] Storage tier: `EncryptedSharedPreferences` (device fingerprint = sensitive)
- [ ] **KHÔNG** xóa khi logout: `clearCurrentUserData()` KHÔNG include `keyDeviceId`
- [ ] Lý do: `deviceId` là per-device, không phải per-user session
- [ ] Language preference (`vi`/`en`) → `SharedPreferences` (plain, non-sensitive)
- [ ] Biometric token → `FlutterSecureStorage` (highest security, OS-level protection)

### Exercise 4 — Custom Decoder ⭐⭐

- [ ] `dataJsonObject` fails vì response dùng `"result"` key, không phải `"data"`
- [ ] `customSuccessResponseDecoder` được check **trước** standard decoder pipeline (xem `rest_api_client.dart` line order)
- [ ] Nhiều `"result"` endpoints → tạo `ResultJsonObjectResponseDecoder extends BaseSuccessResponseDecoder` + thêm entry trong `SuccessResponseDecoderType` enum
- [ ] `json['result']` null → `as Map<String, dynamic>` throws `TypeError` → catch block → `RemoteException(kind: decodeError)`

### Exercise 5 — AI Dojo ⭐⭐⭐

- [ ] AI output ≥ 4/6 tiêu chí pass
- [ ] AI nhận diện facade pattern justified
- [ ] AI nhận diện potential God class risk cho `AppApiService`
- [ ] AI nhận xét token security (encrypted storage)
- [ ] AI **KHÔNG** suggest rewrite toàn bộ data layer
- [ ] Bạn identify ≥ 1 điểm AI sai/thiếu context

---

## 3. Concept Cross-Check

| # | Scenario | Đáp án đúng | Concept |
|---|----------|-------------|---------|
| 1 | `login()` dùng client nào? | `_noneAuthAppServerApiClient` — chưa có token | Facade / Auth vs NoneAuth |
| 2 | Response `{ "data": [{ ... }] }` — decoder type? | `dataJsonArray` | Decoder Pipeline |
| 3 | `DioExceptionType.connectionTimeout` → `RemoteExceptionKind.?` | `timeout` | Error Mapping |
| 4 | `saveAccessToken(token)` dùng storage nào? | `_encryptedSharedPreferences` | Local Storage |
| 5 | `isLoggedIn` dùng storage nào? | `_sharedPreference` (plain) | Local Storage |
| 6 | Interceptor priority 100 chạy khi nào trong request? | **Đầu tiên** (highest priority → first in request chain) | Auth vs Non-Auth |

---

## 4. Architecture Cross-Check

| Component | File | DI | Riverpod Provider | Used by |
|-----------|------|----|-------------------|---------|
| `AppApiService` | `app_api_service.dart` | `@LazySingleton` | `appApiServiceProvider` | ViewModels |
| `RestApiClient` | `rest_api_client.dart` | — (base class) | — | Auth/NoneAuth clients |
| `AuthAppServerApiClient` | `auth_app_server_api_client.dart` | `@LazySingleton` | — | `AppApiService` |
| `NoneAuthAppServerApiClient` | `none_auth_app_server_api_client.dart` | `@LazySingleton` | — | `AppApiService` |
| `AppPreferences` | `app_preferences.dart` | `@LazySingleton` | `appPreferencesProvider` | Interceptors, ViewModel |
| `AppDatabase` | `app_database.dart` | `@LazySingleton` | `appDatabaseProvider` | ViewModel |

**Kiểm tra:**
- [ ] ViewModel → `AppApiService` → Clients → `RestApiClient` → Dio: dependency flow một chiều
- [ ] `AccessTokenInterceptor` → `AppPreferences`: interceptor đọc token từ storage (cross-cutting concern)
- [ ] `RefreshTokenInterceptor` → `AppPreferences` + `RefreshTokenApiClient`: refresh flow kết nối storage + API

---

## 5. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Gọi `_noneAuthAppServerApiClient` cho protected endpoint | 401 Unauthorized — thiếu Bearer token | Check endpoint cần auth → dùng `_authAppServerApiClient` |
| 2 | Quên specify `successResponseDecoderType` cho pagination | Default `dataJsonObject` → decode fail hoặc miss meta | Luôn kiểm tra response format → chọn decoder type đúng |
| 3 | Lưu token bằng `SharedPreferences` (plain) | Token leak — bất kỳ app nào root access đều đọc được | Luôn dùng `EncryptedSharedPreferences` cho tokens |
| 4 | `decoder` callback return wrong type | Runtime cast error → `RemoteException(kind: decodeError)` | Đảm bảo `decoder` return type match `FirstOutput` generic |
| 5 | Không handle `response?.data ?? fallback` | Null crash khi server trả empty body | Luôn null-check + provide default value |
| 6 | `clearCurrentUserData()` xóa thiếu keys | Token/data leak sau logout | Review tất cả user-specific keys đều có trong clear method |

---

## ✅ Module Complete

Hoàn thành khi:

- [ ] Self-assessment: ≥ 6/7 Yes
- [ ] Exercise 1-2 (⭐): Hoàn tất — trace flow + add endpoint
- [ ] Exercise 3-4 (⭐⭐): Hoàn tất — secure storage + decoder
- [ ] Exercise 5 (⭐⭐⭐): AI review + critical evaluation
- [ ] Cross-check: Trả lời đúng 6/6 scenarios
- [ ] Hiểu dependency flow: ViewModel → Facade → Client → Dio → Interceptors

→ Module tiếp theo: [Module 13 — Error Handling & Interceptors](../module-13-middleware-interceptor-chain/) — deep dive interceptor middleware, retry logic, refresh token flow.

<!-- AI_VERIFY: generation-complete -->
