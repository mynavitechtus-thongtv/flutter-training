# Verification — Kiểm tra kết quả Module 13

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi liệt kê được 7 interceptors của `AuthAppServerApiClient` theo đúng registration order? | Chain Architecture | 🔴 |
| 2 | Tôi giải thích được request phase chạy theo registration order (1→N), error phase chạy reverse (N→1)? | Chain Architecture | 🔴 |
| 3 | Tôi trace được `RefreshTokenInterceptor` queue pattern: `_isRefreshing` flag + `Queue` + retry qua `NoneAuthAppServerApiClient`? | Token Refresh | 🔴 |
| 4 | Tôi mô tả được `RetryOnErrorInterceptor` dùng header-based state (`retryCount`, `isRetry`) + selective retry (chỉ timeout/connection)? | Retry Backoff | 🔴 |
| 5 | Tôi biết `SuccessResponseDecoderType` có 6 loại và khi nào dùng loại nào? | Decoder Pipeline | 🟡 |
| 6 | Tôi giải thích được `ConnectivityInterceptor` dùng `handler.reject()` để short-circuit pipeline? | Connectivity Guard | 🟡 |
| 7 | Tôi describe được `PagingExecutor` snapshot/rollback pattern (`_output` vs `_oldOutput`)? | Paging Executor | 🟡 |

**Target:** 4/4 Yes cho 🔴 MUST-KNOW, tối thiểu 6/7 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace Interceptor Execution Order ⭐

- [ ] Request phase đủ **6 interceptors** có `onRequest` (CustomLog → Connectivity → RetryOnError → BasicAuth → Header → AccessToken)
- [ ] `RefreshTokenInterceptor` **không có** `onRequest` — đã ghi rõ
- [ ] Error phase (401): `RefreshTokenInterceptor` catch 401 → refresh → retry
- [ ] Trả lời: BasicAuth set `Authorization: Basic ...`, AccessToken overwrite thành `Bearer ...` → **Bearer wins** vì chạy sau
- [ ] Trả lời: Refresh API chạy qua `RefreshTokenApiClient` (dedicated client), retry qua `NoneAuthAppServerApiClient`
- [ ] Trả lời: `ConnectivityInterceptor.reject()` → error phase bắt đầu từ **ConnectivityInterceptor trở về trước** (CustomLog) — `RefreshTokenInterceptor` **không chạy** vì nó ở phía sau connectivity trong chain

### Exercise 2 — Add Custom Header Interceptor ⭐

- [ ] File location: `lib/data_source/api/middleware/request_id_interceptor.dart`
- [ ] `extends BaseInterceptor` với `InterceptorType.requestId`
- [ ] Priority: ~15 (sau `header(10)`, trước `accessToken(20)`) — hoặc giải thích hợp lý
- [ ] `onRequest` generate UUID v4, set `options.headers['X-Request-ID']`
- [ ] Gọi `handler.next(options)` hoặc `super.onRequest(options, handler)` — cả hai đều đúng
- [ ] Trả lời retry question: `_dio.fetch()` chạy full pipeline → request mới có UUID mới → **X-Request-ID thay đổi** per retry (đây là behavior mong muốn cho distributed tracing)
- [ ] **Đã revert changes**

**Cross-check [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md):**

| Rule | Expected |
|------|----------|
| File: snake_case | `request_id_interceptor.dart` ✅ |
| Class: PascalCase | `RequestIdInterceptor` ✅ |
| Enum value: camelCase | `requestId` ✅ |

### Exercise 3 — Rate Limit Retry Interceptor ⭐⭐

- [ ] Override `onError` — detect status code 429
- [ ] Parse `Retry-After` header: `err.response?.headers.value('Retry-After')`
- [ ] Default fallback: 5 seconds nếu header missing
- [ ] Max wait guard: nếu `Retry-After > 30` (hoặc configurable max) → reject, không đợi quá lâu
- [ ] Header-based retry count pattern (tương tự `RetryOnErrorInterceptor`)
- [ ] `_dio.fetch()` cho retry — chạy lại full pipeline
- [ ] Trả lời: 429 retry có known wait time (server chỉ định), timeout retry dùng exponential guess
- [ ] Trả lời: Đặt **trước** `RetryOnErrorInterceptor` trong error chain (= **sau** trong registration) — 429 nên xử lý trước retry logic
- [ ] **Đã revert changes**

### Exercise 4 — Paging Executor ⭐⭐

- [ ] `GetUsersPagingParams extends PagingParams` với `role` parameter
- [ ] `GetUsersPagingExecutor extends PagingExecutor<UserData, GetUsersPagingParams>`
- [ ] `action()` gọi `appApiService` method phù hợp
- [ ] `LoadMoreOutput` với `data`, `isLastPage` (derived từ `!has_more`), `total`
- [ ] Riverpod Provider pattern match existing:
  ```dart
  final getUsersPagingExecutorProvider = Provider<GetUsersPagingExecutor>(
    (ref) => getIt.get<GetUsersPagingExecutor>(),
  );
  ```
- [ ] Trả lời `isInitialLoad`: `true` → reset page/offset/data; `false` → increment page, append data
- [ ] Trả lời error rollback: `_output = _oldOutput` → page 4 fail, `_output` quay về page 3 state → user vẫn thấy data page 1-3
- [ ] Trả lời re-throw: `PagingExecutor` wrap non-`AppException` rồi throw lại → cho ViewModel/ExceptionHandler handle ở layer trên (separation of concerns)
- [ ] **Đã revert changes**

### Exercise 5 — AI Dojo: Security Review ⭐⭐⭐

- [ ] AI tìm ≥ 2 potential information leakage points (thường: `toString()` expose quá nhiều implementation details, log level không phân biệt debug/release)
- [ ] Bạn verify mỗi finding — xác nhận risk level thực tế trong production build (High / Medium / Low)
- [ ] AI **KHÔNG** suggest bỏ hết error messages — chỉ sanitize sensitive details (stack trace, server URL, internal IDs)
- [ ] AI đề xuất sanitization approach:
  - `toString()` methods chỉ hiện minimal info trong release mode
  - Log statements không ghi tokens, passwords, PII
  - Raw server error không pass thẳng lên UI
  - Debug vs Release error detail level được phân biệt rõ
- [ ] Bạn kết luận: code hiện tại an toàn ở mức nào? Cần fix gì ngay vs nice-to-have?
- [ ] ≥3 câu reflection viết ra

---

## 3. Kết nối với Modules tiếp theo

| Module tiếp | Pattern từ M13 sẽ dùng |
|------------|------------------------|
| **M14 — Local Storage** | `AppPreferences` (đã thấy trong `AccessTokenInterceptor`, `RefreshTokenInterceptor`) — deep dive encrypted storage |
| **M15 — Capstone Login** | Full login flow: API call → interceptor chain → save tokens → navigate. RefreshToken interceptor active sau login |
| **M16 — Popup/Dialog/Paging** | `PagingExecutor` integration vào UI — `isInitialLoad` cho pull-to-refresh, `isLastPage` cho load more indicator |

→ Quay lại: [00-overview.md](./00-overview.md) — tổng quan module.

---

## ➡️ Next Module

Hoàn thành Module 13! Bạn đã nắm vững error handling patterns, exception handling flow.

→ Tiến sang **[Module 14 — Local Storage](../module-14-local-storage/)** để học SharedPreferences, secure storage, local data persistence.

<!-- AI_VERIFY: generation-complete -->
