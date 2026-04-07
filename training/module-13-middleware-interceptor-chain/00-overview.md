# Module 13: Middleware & Interceptor Chain

## Tổng quan

Module này đi sâu vào **interceptor middleware layer** — kiến trúc interceptor chain giữa API calls và exception handling. Bạn sẽ đọc `BaseInterceptor` (abstract base + priority), `RefreshTokenInterceptor` (queue-based token refresh), `RetryOnErrorInterceptor` (exponential backoff), `ConnectivityInterceptor` (network guard), `CustomLogInterceptor` (request/response logging), response decoder pipeline, và `PagingExecutor` (pagination state machine) — hiểu cách mỗi interceptor transform, guard, hoặc retry request trước khi error đến exception layer.

**Cycle:** CODE (đọc interceptor chain files) → EXPLAIN (hiểu patterns) → PRACTICE (trace + build + extend).

**Prerequisite:** Hoàn thành [Module 4 — Exception Handling](../module-04-exception-handling/) (`AppException` hierarchy, `DioExceptionMapper`), [Module 12 — Data Layer](../module-12-data-layer/) (`RestApiClient`, `AppApiService`, Auth vs NonAuth clients).

---

## 🔄 Re-Anchor — Ôn lại M4, M12

| Module | Concept cần nhớ | Kết nối M13 |
|--------|-----------------|-------------|
| **M4 — Exception Handling** | `AppException` hierarchy, `RemoteException(kind)`, `DioExceptionMapper` | Interceptors throw `RemoteException` trực tiếp (connectivity) hoặc để mapper handle sau chain |
| **M12 — Data Layer** | `RestApiClient`, `DioBuilder`, Auth vs NonAuth clients, interceptor registration | M13 deep dive **bên trong** mỗi interceptor — M12 chỉ giới thiệu client + list interceptors |

→ Nếu bất kỳ concept nào chưa rõ → quay lại module tương ứng trước khi tiếp tục.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Liệt kê được 7 interceptors của `AuthAppServerApiClient` theo đúng registration + execution order?
2. Trace được `RefreshTokenInterceptor` queue pattern: `_isRefreshing` mutex, `Queue<>` accumulate, retry qua `NoneAuthAppServerApiClient`?
3. Giải thích `RetryOnErrorInterceptor` header-based state + selective retry (chỉ timeout/connection)?
4. Phân biệt `handler.next()` / `handler.reject()` / `handler.resolve()` và impact lên pipeline?
5. Mô tả `PagingExecutor` snapshot/rollback pattern + `isInitialLoad` branching?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 14 — Local Storage](../module-14-local-storage/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

8 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | Interceptor Chain Architecture & Execution Order | 🔴 MUST-KNOW | Foundation — mọi API call đều chạy qua chain |
| 2 | Token Refresh with Queue Pattern | 🔴 MUST-KNOW | Critical path — sai = force logout / infinite loop |
| 3 | Retry with Exponential Backoff | 🔴 MUST-KNOW | Network resilience — retry đúng, không retry storm |
| 4 | Response Decoder Pipeline | 🟡 SHOULD-KNOW | Factory pattern, error wrapping, 6 decoder types |
| 5 | Connectivity Guard Pattern | 🟡 SHOULD-KNOW | Fail fast, short-circuit pipeline |
| 6 | Paging Executor Pattern | 🟡 SHOULD-KNOW | Template method, snapshot/rollback state |
| 7 | Request/Response Logging Strategy | 🟢 AI-GENERATE | 3-layer log gate, emoji convention, truncation |
| 8 | Connectivity-Aware UI Patterns | 🟢 AI-GENERATE | UI-level offline indicator, banner pattern |

**Phân bố:** 🔴 ~38% · 🟡 ~38% · 🟢 ~25%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Walk interceptor chain: base → registration → 7 interceptors → decoders → paging | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 8 concepts từ interceptor chain patterns | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 5 bài tập trace + add header + rate limit + paging + AI review | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + exercise verification | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace Interceptor Execution Order | ⭐ |
| 2 | Add Custom Header Interceptor | ⭐ |
| 3 | Implement Rate Limit Retry Interceptor | ⭐⭐ |
| 4 | Implement Paging Executor | ⭐⭐ |
| 5 | AI Prompt Dojo — Interceptor Architecture Review | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [base_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/base_interceptor.dart) — abstract base + `InterceptorType` enum (24 lines)
- [auth_app_server_api_client.dart](../../base_flutter/lib/data_source/api/client/auth_app_server_api_client.dart) — 7-interceptor chain registration (37 lines)
- [none_auth_app_server_api_client.dart](../../base_flutter/lib/data_source/api/client/none_auth_app_server_api_client.dart) — 5-interceptor chain (29 lines)
- [custom_log_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/custom_log_interceptor.dart) — request/response/error logging (101 lines)
- [connectivity_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/connectivity_interceptor.dart) — network guard (23 lines)
- [retry_on_error_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/retry_on_error_interceptor.dart) — exponential backoff retry (76 lines)
- [basic_auth_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/basic_auth_interceptor.dart) — Basic auth header (26 lines)
- [header_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/header_interceptor.dart) — device/package headers (30 lines)
- [access_token_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/access_token_interceptor.dart) — Bearer token injection (19 lines)
- [refresh_token_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/refresh_token_interceptor.dart) — queue-based 401 refresh (140 lines)
- [base_success_response_decoder.dart](../../base_flutter/lib/data_source/api/json_decoder/base_success_response_decoder.dart) — factory decoder pipeline (54 lines)
- [base_error_response_decoder.dart](../../base_flutter/lib/data_source/api/json_decoder/base_error_response_decoder.dart) — error decoder (53 lines)
- [paging_executor.dart](../../base_flutter/lib/data_source/api/paging/base/paging_executor.dart) — pagination state machine (67 lines)
- [get_notifications_paging_executor.dart](../../base_flutter/lib/data_source/api/paging/get_notifications_paging_executor.dart) — concrete paging example (50 lines)

---

## Unlocks (Module 14+)

Sau khi hoàn thành Module 13, bạn sẽ:

- **Module 14 — Local Storage:** Deep dive `AppPreferences` — encrypted token storage mà `AccessTokenInterceptor` / `RefreshTokenInterceptor` đã đọc/ghi.
- **Module 15 — Capstone Login:** Full login flow — API call chạy qua interceptor chain → save tokens → `RefreshTokenInterceptor` active → navigate. Kết hợp M5 (navigation) + M8 (state) + M12 (API) + M13 (interceptors).
- **Module 16 — Popup/Dialog/Paging:** `PagingExecutor` + UI integration — pull-to-refresh gọi `execute(isInitialLoad: true)`, scroll load more gọi `execute(isInitialLoad: false)`.

<!-- AI_VERIFY: generation-complete -->
