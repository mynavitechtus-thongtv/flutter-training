# Exercises — Thực hành Middleware & Interceptor Chain

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 4](../module-04-exception-handling/) (AppException hierarchy), [Module 12](../module-12-data-layer/) (RestApiClient, AppApiService) và đọc xong [01-code-walk.md](./01-code-walk.md).

---

## ⭐ Exercise 1: Trace Interceptor Execution Order

**Mục tiêu:** Trace request/error phase cho 1 API call qua toàn bộ interceptor chain.

### Hướng dẫn

1. Mở [auth_app_server_api_client.dart](../../base_flutter/lib/data_source/api/client/auth_app_server_api_client.dart).
2. Giả sử gọi `GET /v1/me` (cần auth).
3. Trace **request phase** — từng interceptor `onRequest()` chạy gì.
4. Giả sử server trả **401 Unauthorized** — trace **error phase**.

### Template

**Phần A — Request Phase (happy path):**

| Order | Interceptor | Action trong `onRequest` | Headers sau step |
|:-----:|------------|------------------------|-----------------|
| 1 | `CustomLogInterceptor` | ? | (unchanged) |
| 2 | `ConnectivityInterceptor` | ? | (unchanged) |
| 3 | `RetryOnErrorInterceptor` | ? | `retryCount: ?` |
| 4 | `BasicAuthInterceptor` | ? | `Authorization: Basic ?` |
| 5 | `HeaderInterceptor` | ? | `User-Agent: ?` |
| 6 | `AccessTokenInterceptor` | ? | `Authorization: Bearer ?` |
| 7 | `RefreshTokenInterceptor` | (no onRequest) | — |

**Phần B — Error Phase (server trả 401):**

| Order | Interceptor | Action trong `onError` | Result |
|:-----:|------------|----------------------|--------|
| 7 | `RefreshTokenInterceptor` | ? (401 detected?) | ? |
| 6 | `AccessTokenInterceptor` | ? | ? |
| ... | ... | ... | ... |
| 1 | `CustomLogInterceptor` | ? | ? |

**Câu hỏi:**
- Step 4 (BasicAuth) set `Authorization: Basic ...`, step 6 (AccessToken) set `Authorization: Bearer ...` — ai “thắng”? Tại sao?
- Khi `RefreshTokenInterceptor` catch 401, nó gọi `_refreshToken()` → API call này chạy qua client nào? Tại sao không dùng `AuthAppServerApiClient`?
- Nếu `ConnectivityInterceptor` reject → `RefreshTokenInterceptor.onError()` có chạy không? Tại sao?

### ✅ Checklist hoàn thành
- [ ] Điền đủ request phase (6 interceptors có `onRequest`)
- [ ] Điền error phase (xác định interceptors nào có `onError`)
- [ ] Trả lời 3 câu hỏi

---

## ⭐ Exercise 2: Add Custom Header Interceptor

**Mục tiêu:** Tạo interceptor gắn custom header `X-Request-ID` (UUID) vào mọi request.

### Yêu cầu

Tạo `RequestIdInterceptor` trong `lib/data_source/api/middleware/`:

- Extends `BaseInterceptor` với `InterceptorType` phù hợp
- Override `onRequest` — generate UUID v4 → gắn vào `options.headers['X-Request-ID']`
- Thêm `InterceptorType.requestId` vào enum với priority hợp lý
- Register vào `AuthAppServerApiClient`

**Câu hỏi:**
- `X-Request-ID` dùng cho gì? (distributed tracing, log correlation)
- Nếu request bị retry bởi `RetryOnErrorInterceptor` → `X-Request-ID` có thay đổi không? Nên thay đổi không?
- Priority bạn chọn là bao nhiêu? Giải thích tại sao

<details>
<summary>💡 Gợi ý (mở khi stuck > 15 phút)</summary>

- Tham khảo `ConnectivityInterceptor` cho pattern extends `BaseInterceptor`
- `handler.next(options)` hoặc `super.onRequest(options, handler)` — chọn 1
- Priority nên thấp hơn `AccessTokenInterceptor` (chạy trước auth headers)
- Package `uuid` hoặc `Uuid().v4()` cho UUID generation

</details>

### ✅ Checklist hoàn thành
- [ ] File tạo đúng location, extends `BaseInterceptor`
- [ ] `onRequest` gắn UUID v4 vào header
- [ ] `InterceptorType` enum updated với priority hợp lý
- [ ] Register vào client
- [ ] Trả lời 3 câu hỏi
- [ ] **Đã revert changes**

---

## ⭐⭐ Exercise 3: Implement Rate Limit Retry Interceptor

**Mục tiêu:** Tạo interceptor xử lý HTTP 429 (Too Many Requests) — đọc `Retry-After` header, wait, retry.

### Yêu cầu

Tạo `RateLimitInterceptor` trong `lib/data_source/api/middleware/`:

**Signature:**
```dart
class RateLimitInterceptor extends BaseInterceptor {
  RateLimitInterceptor(Dio dio);
  // Override onError — detect 429, parse Retry-After, wait, retry
}
```

**Behavior:**
- Detect HTTP 429 trong `onError`
- Parse `Retry-After` header (seconds) — default 5s nếu missing
- Track retry count qua headers (giống `RetryOnErrorInterceptor` pattern)
- Max 2 retries, max wait cap (e.g., 30s)
- Retry qua `_dio.fetch()` → re-execute full pipeline

**Câu hỏi:**
- 429 retry khác gì retry timeout? (wait time known vs exponential guess)
- Interceptor này nên đặt trước hay sau `RetryOnErrorInterceptor` trong chain? Tại sao?
- Nếu `Retry-After` trả giá trị rất lớn (3600 = 1 giờ) → bạn handle thế nào?

<details>
<summary>💡 Gợi ý (mở khi stuck > 15 phút)</summary>

- Tham khảo `RetryOnErrorInterceptor` cho header-based state tracking pattern
- Key steps trong `onError`:
  1. Check `statusCode == 429`
  2. `int.tryParse(err.response?.headers.value('Retry-After') ?? '') ?? 5`
  3. Check retry count < max
  4. `Future.delayed(Duration(seconds: wait))` → `_dio.fetch(options)` → `handler.resolve()`
- Nhớ cap `Retry-After` at reasonable max (30s) để tránh block quá lâu

</details>

### ✅ Checklist hoàn thành
- [ ] Override `onError` — detect 429
- [ ] Parse `Retry-After` header với default fallback
- [ ] Header-based retry count (không dùng instance state)
- [ ] `Future.delayed()` đúng duration
- [ ] Max retry guard + max wait time guard
- [ ] Trả lời 3 câu hỏi
- [ ] **Đã revert changes**

---

## ⭐⭐ Exercise 4: Implement Paging Executor

**Mục tiêu:** Tạo `GetUsersPagingExecutor` — pagination cho user list endpoint.

### API Spec

- Endpoint: `GET /v1/users?page={page}&limit={limit}&role={role}`
- Auth: Required
- Response: `{ "data": [...], "pagination": { "page": 1, "limit": 10, "total": 100, "has_more": true } }`

### Yêu cầu

1. Tạo `GetUsersPagingParams extends PagingParams` với field `role`
2. Tạo `GetUsersPagingExecutor extends PagingExecutor<UserData, GetUsersPagingParams>`
3. Override `action()` — gọi API, return `LoadMoreOutput`
4. Tạo Riverpod Provider (tham khảo `getNotificationsPagingExecutorProvider`)

**Câu hỏi:**
- `isInitialLoad: true` khác `isInitialLoad: false` thế nào trong `PagingExecutor.execute()`?
- Nếu load page 4 fail → `_output` sẽ bằng gì? User thấy gì trên UI?
- Tại sao `PagingExecutor` catch lỗi rồi throw lại? Sao không swallow?

<details>
<summary>💡 Gợi ý (mở khi stuck > 15 phút)</summary>

- `GetUsersPagingParams` chỉ cần 1 field: `final String? role`
- `action()` signature: `Future<LoadMoreOutput<UserData>> action({required int page, required int limit, required GetUsersPagingParams? params})`
- `LoadMoreOutput`: `data` (list), `isLastPage` (derived từ `has_more`), `total`
- Provider pattern: `final getUsersPagingExecutorProvider = Provider<GetUsersPagingExecutor>((ref) => getIt.get<GetUsersPagingExecutor>())`
- `@Injectable()` annotation cho DI

</details>

### ✅ Checklist hoàn thành
- [ ] `GetUsersPagingParams extends PagingParams`
- [ ] `GetUsersPagingExecutor` extends đúng generic types
- [ ] `action()` return `LoadMoreOutput` với `isLastPage` từ `has_more`
- [ ] Provider registered
- [ ] Trả lời 3 câu hỏi
- [ ] **Đã revert changes**

---

## ⭐⭐⭐ Exercise 5: AI Dojo — 🛡️ Security Review

### 🤖 AI Dojo — Information Leakage trong Error Handling

**Mục tiêu**: Dùng AI tìm information leakage risks trong error messages và exception handling code.

**Bước thực hiện**:

1. Copy nội dung các file exception: [exception_handler.dart](../../base_flutter/lib/exception/exception_handler/exception_handler.dart), [remote_exception.dart](../../base_flutter/lib/exception/remote_exception.dart), và [dio_exception_mapper.dart](../../base_flutter/lib/exception/exception_mapper/dio_exception_mapper.dart).

2. Gửi prompt sau cho AI:

```
Bạn là security engineer review Flutter app. Phân tích error handling code
tìm information leakage:

1. Error messages hiển thị cho user có chứa thông tin nhạy cảm không?
   (stack trace, server URL, SQL error, internal IDs)
2. toString() methods có expose implementation details không?
3. Log statements có ghi sensitive data không? (tokens, passwords, PII)
4. Exception propagation: raw server error có bị pass thẳng lên UI không?
5. Debug vs Release: có error info nào chỉ nên hiện ở debug mode?

Chỉ report issues CÓ RISK thực sự, không report code style.

Code:
[PASTE exception_handler.dart + remote_exception.dart + dio_exception_mapper.dart]
```

3. Với mỗi risk AI tìm được:
   - Check code thực tế: risk có thật không?
   - Severity: High (user thấy sensitive info) / Medium (log chứa info) / Low (theoretical)
   - `toString()` methods — chỉ dùng trong debug hay có thể leak ra production UI?

4. Hỏi follow-up: "Viết sanitization function để clean error messages trước khi hiển thị cho user."

**✅ Tiêu chí đánh giá**:
- [ ] AI tìm ≥ 2 potential leakage points (thường: toString có quá nhiều info, log level không phân biệt debug/release)
- [ ] Bạn verify mỗi finding — xác nhận risk level thực tế trong production build
- [ ] AI **KHÔNG** suggest bỏ hết error messages (user cần biết "có lỗi xảy ra" — chỉ cần sanitize details)
- [ ] Bạn kết luận: code hiện tại an toàn ở mức nào? Cần fix gì ngay vs nice-to-have?

---

## Tổng kết Exercises

| # | Bài tập | Độ khó | Concept liên quan |
|---|---------|--------|-------------------|
| 1 | Trace Interceptor Execution Order | ⭐ | Chain Architecture (#1) |
| 2 | Add Custom Header Interceptor | ⭐ | Chain Architecture (#1), Logging (#7) |
| 3 | Implement Rate Limit Retry | ⭐⭐ | Retry with Backoff (#3) |
| 4 | Implement Paging Executor | ⭐⭐ | Paging Executor (#6) |
| 5 | AI Dojo — Security Review | ⭐⭐⭐ | Information leakage, security |

→ Tiếp theo: [04-verify.md](./04-verify.md) — tự kiểm tra kết quả.

<!-- AI_VERIFY: generation-complete -->
