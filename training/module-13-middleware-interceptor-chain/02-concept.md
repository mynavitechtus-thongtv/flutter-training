# Concepts — Middleware & Interceptor Chain

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

### Error Handling Flow — End-to-End Overview

Trước khi đi vào từng concept, đây là **full error flow** từ API call đến UI:

```
API call (RestApiClient)
    ↓ error
Dio Interceptor Chain (onError phase: reverse order)
    ↓ ConnectivityInterceptor → noInternet
    ↓ RetryOnErrorInterceptor → retry or pass
    ↓ RefreshTokenInterceptor → refresh or pass
    ↓
DioExceptionMapper
    ↓ map DioException → RemoteException(kind: timeout/network/serverError/...)
    ↓
AppException (RemoteException extends AppException)
    ↓
ViewModel.runCatching()
    ├── handleErrorWhen: true → BasePage.handleException → Error Dialog
    └── handleErrorWhen: false → doOnError → set state.onPageError → UI inline error
```

> Mỗi concept dưới đây giải thích chi tiết từng bước trong flow trên.

---

## 1. Interceptor Chain Architecture & Execution Order 🔴 MUST-KNOW

**WHY:** Interceptor chain là **backbone** của mọi API call. Hiểu sai execution order → token không gắn, retry không chạy, log không ghi. Mọi request/response đều chạy qua chain này.

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/base_interceptor.dart -->
```dart
abstract class BaseInterceptor extends InterceptorsWrapper {
  BaseInterceptor(this.type);
  final InterceptorType type;
}

enum InterceptorType {
  retryOnError(100), // add first → onRequest chạy đầu tiên
  connectivity(99),
  basicAuth(40),
  refreshToken(30),
  accessToken(20),
  header(10),
  customLog(1);      // add last → onRequest chạy cuối cùng

  const InterceptorType(this.priority);
  final int priority;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § base_interceptor.dart](./01-code-walk.md#1-base_interceptordart--abstract-base--priority)

**EXPLAIN:**

Dio interceptor pipeline hoạt động theo 3 phases:

| Phase | Execution Order | Hook |
|-------|----------------|------|
| **Request** | Registration order (1→N) | `onRequest()` |
| **Response** | Reverse order (N→1) | `onResponse()` |
| **Error** | Reverse order (N→1) | `onError()` |

**Tại sao order quan trọng?**

```
Request Phase:           Error Phase (reverse):
1. CustomLog      →      7. RefreshToken (catch 401)
2. Connectivity   →      6. (AccessToken — no onError)
3. RetryOnError   →      5. (Header — no onError)
4. BasicAuth      →      4. (BasicAuth — no onError)
5. Header         →      3. RetryOnError (retry timeout)
6. AccessToken    →      2. (Connectivity — no onError)
7. (no onRequest) →      1. CustomLog (log error)
```

**Ví dụ thực tế:** Nếu `ConnectivityInterceptor` đặt **sau** `AccessTokenInterceptor` → app cố đọc token từ storage trước khi biết có mạng không → phí I/O. Đặt đúng: check network sớm, fail fast.

> ⛔ **QUAN TRỌNG — Priority ≠ Execution Order**
> `InterceptorType` enum có field `priority` nhưng đây chỉ là **convention nội bộ**, KHÔNG phải Dio runtime feature. 
> Dio thực thi interceptors theo **thứ tự đăng ký** (`interceptors.add()` order), không theo priority number.
> Nếu bạn thêm interceptor mới, thứ tự `add()` trong client setup quyết định execution order.

**Abstract base pattern:** `BaseInterceptor extends InterceptorsWrapper` cho phép:
- Enforce type classification (`InterceptorType` enum)
- Convention: `priority` value gợi ý thứ tự registration mong muốn (team convention, không phải Dio feature)
- IDE discoverability — tìm tất cả interceptors qua "find subclasses of BaseInterceptor"

> 💡 **FE Perspective**: Pattern giống Express middleware / [Axios interceptors](https://axios-http.com/docs/interceptors). Điểm mới: Dio có **3 hooks** (`onRequest`, `onResponse`, `onError`) với reverse order cho response/error phase — Axios chỉ có 2 hooks, không có built-in priority system.

**PRACTICE:** Mở [auth_app_server_api_client.dart](../../base_flutter/lib/data_source/api/client/auth_app_server_api_client.dart). Liệt kê 7 interceptors theo registration order. Sau đó vẽ execution order cho **error phase** (reverse). Verify với diagram trong [01-code-walk § Execution Order](./01-code-walk.md#10-request-phase--full-execution-order).

---

## 2. Token Refresh with Queue Pattern 🔴 MUST-KNOW

**WHY:** Token refresh là **critical path** — sai logic = infinite refresh loop, race condition, hoặc force logout sai. Queue pattern giải quyết concurrent 401 problem mà single-retry approach không handle được.

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/refresh_token_interceptor.dart -->
```dart
var _isRefreshing = false;
final _queue = Queue<({RequestOptions options, ErrorInterceptorHandler handler})>();

void onError(DioException err, ErrorInterceptorHandler handler) {
  if (err.response?.statusCode == HttpStatus.unauthorized) {
    _onExpiredToken(options: err.response!.requestOptions, handler: handler);
  } else {
    handler.next(err);
  }
}

Future<void> _onExpiredToken({...}) async {
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
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § RefreshTokenInterceptor](./01-code-walk.md#9-refreshtokeninterceptor--queue-based-token-refresh)

**EXPLAIN:**

**Problem:** App gửi 3 requests cùng lúc, token hết hạn → 3 x 401:

```
❌ Without Queue (naive approach):
A(401) → refresh → new token → retry A ✅
B(401) → refresh → new token → retry B ✅ (but wasted 1 refresh)
C(401) → refresh → FAIL (refresh token used by B) → force logout ❌

✅ With Queue Pattern:
A(401) → add to queue → start refresh
B(401) → add to queue → skip (isRefreshing = true)
C(401) → add to queue → skip (isRefreshing = true)
→ refresh done → retry A, B, C with new token → all ✅
```

**3 trạng thái của RefreshTokenInterceptor:**

| State | `_isRefreshing` | Queue | Behavior |
|-------|:--------------:|:-----:|----------|
| Idle | `false` | empty | 401 → start refresh |
| Refreshing | `true` | accumulating | 401 → add to queue, skip |
| Done | `false` | cleared | retry all queued, cleanup |

> 💡 **FE Perspective**: Cùng pattern Axios 401 queue (shared `isRefreshing` + pending promise queue). Điểm mới: Flutter dùng **separate Dio instance** (`noneAuthAppServerApiClient`) cho retry — Axios cũng cần separate instance nhưng nhiều dev quên → infinite refresh loop.

**Tại sao retry dùng `noneAuthAppServerApiClient`?**

```dart
final response = await noneAuthAppServerApiClient.fetch(options);
```

→ Token mới đã được gắn vào `options.headers` bằng `_putAccessToken()`. Nếu dùng `authAppServerApiClient` → `AccessTokenInterceptor` sẽ đọc lại token từ storage (có thể chưa persist xong) → race condition. NonAuth client không có `AccessTokenInterceptor` → dùng token từ headers trực tiếp.

**PRACTICE:** Trace scenario: 2 requests fail 401, refresh thành công. Điền timeline:
1. Request A → 401 → `_queue = [A]`, `_isRefreshing = ?` → start `_refreshToken()`
2. Request B → 401 → `_queue = [A, B]`, `_isRefreshing = ?` → skip
3. `_refreshToken()` success → `_onRefreshTokenSuccess()` → retry both
4. `finally` → `_isRefreshing = ?`, `_queue = ?`

---

## 3. Retry with Exponential Backoff 🔴 MUST-KNOW

**WHY:** Network không ổn định — timeout, DNS failure tạm thời. Retry tự động + backoff tránh "retry storm" (nhiều clients retry cùng lúc overwhelm server).

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/retry_on_error_interceptor.dart -->
```dart
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  if (!options.headers.containsKey(retryHeaderKey)) {
    options.headers[retryCountKey] = Constant.maxRetries;
  }
  super.onRequest(options, handler);
}

Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
  final retryCount = safeCast<int>(err.requestOptions.headers[retryCountKey]) ?? 0;
  if (retryCount > 0 && shouldRetry(err)) {
    await Future<void>.delayed(_retryHelper.getRetryInterval(retryCount));
    final response = await _dio.fetch<dynamic>(
      err.requestOptions
        ..headers[retryHeaderKey] = true
        ..headers[retryCountKey] = retryCount - 1,
    );
    return handler.resolve(response);
  }
  return super.onError(err, handler);
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § RetryOnErrorInterceptor](./01-code-walk.md#5-retryonerrorinterceptor--exponential-backoff)

**EXPLAIN:**

**Header-based state management:**

| Header Key | Purpose | Lifecycle |
|-----------|---------|-----------|
| `retryCountKey` | Remaining retries (3→2→1→0) | Set on first request, decremented per retry |
| `retryHeaderKey` (`isRetry`) | Flag: is this a retry? | Set on retry, prevents `onRequest` re-initialization |

**Backoff timeline (default: 3 retries):**

```
Request   → timeout
Retry 1   → wait firstRetryInterval  → timeout
Retry 2   → wait secondRetryInterval → timeout
Retry 3   → wait thirdRetryInterval  → timeout
→ give up → pass error downstream
```

**Selective retry — chỉ transient errors:**

```dart
bool shouldRetry(DioException error) =>
    error.type == DioExceptionType.connectionTimeout ||
    error.type == DioExceptionType.receiveTimeout ||
    error.type == DioExceptionType.connectionError ||
    error.type == DioExceptionType.sendTimeout;
```

→ KHÔNG retry: `badResponse` (400/500), `cancel`, `badCertificate` — đây là **deterministic errors**, retry không thay đổi kết quả.

**`_dio.fetch()` — full pipeline re-execution:**

Khi retry, request chạy lại **toàn bộ interceptor chain** (log, connectivity check, token inject...). Đây là design conscious — retry request cần headers mới nhất (token có thể đã refresh giữa chừng).

> 💡 **FE Perspective**
> **Flutter:** `RetryOnErrorInterceptor` — header-based state (`retryCountKey`, `retryHeaderKey`), exponential backoff, chỉ retry transient errors (timeout, connection). `_dio.fetch()` re-execute toàn bộ interceptor chain
> **React/Vue tương đương:** `axios-retry` library — `axiosRetry(axios, { retries: 3, retryDelay: exponentialDelay })`. Cùng concept exponential backoff + selective retry
> **Khác biệt quan trọng:** Dio retry là **interceptor built-in** (first-class, chạy lại full pipeline) — Axios retry là **plugin ngoài**, không đảm bảo full chain re-execution. Flutter dùng **request headers** lưu retry state — pattern sáng tạo, không cần external state.

**PRACTICE:** Trả lời: Nếu `Constant.maxRetries = 0`, interceptor behavior thay đổi thế nào? Hint: check `if (retryCount > 0 && shouldRetry(err))`.

---

## 4. Response Decoder Pipeline 🟡 SHOULD-KNOW

> Response Decoder pattern đã được giải thích chi tiết ở [M12 — Concept § Response Decoder](../module-12-data-layer/02-concept.md). Phần này focus vào error flow khi decode fails.

**Error boundary trong decoder:**
- Decoder error → `RemoteExceptionKind.decodeError` → consistent với exception system (M4)
- `RemoteException` from upstream → `rethrow` — không double-wrap

> 📌 Chi tiết implementation sẽ được cover trong module tương ứng. Section này giới thiệu context để hiểu error flow end-to-end.

---

## 5. Connectivity Guard Pattern 🟡 SHOULD-KNOW

**WHY:** Check network **trước khi gửi request** tránh timeout wait vô ích (30s timeout khi không có mạng). Fail fast → UX tốt hơn.

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/connectivity_interceptor.dart -->
```dart
class ConnectivityInterceptor extends BaseInterceptor {
  ConnectivityInterceptor(this._connectivityHelper)
      : super(InterceptorType.connectivity);

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
→ Đã đọc trong [01-code-walk § ConnectivityInterceptor](./01-code-walk.md#4-connectivityinterceptor--network-guard)

**EXPLAIN:**

**`handler.reject()` vs `handler.next()`:**

| Method | Effect |
|--------|--------|
| `handler.next(options)` | Pass request sang interceptor tiếp theo |
| `handler.reject(DioException)` | **Short-circuit** — skip remaining interceptors, jump to error phase |
| `handler.resolve(Response)` | **Short-circuit** — skip remaining interceptors, return success |

`reject()` ở đây = **circuit breaker** — không cần chạy auth, header, token inject khi biết chắc request sẽ fail do no network.

> 💡 **FE Perspective**
> **Flutter:** `ConnectivityInterceptor` — check network trước khi gửi request, `handler.reject()` short-circuit toàn bộ pipeline. Fail fast với `RemoteExceptionKind.noInternet` typed exception
> **React/Vue tương đương:** Axios request interceptor check `navigator.onLine` → `return Promise.reject(new OfflineError())`. Angular `HttpInterceptor.intercept()` return `throwError()` khi offline
> **Khác biệt quan trọng:** Flutter dùng `connectivity_plus` package (platform-native check) — Web chỉ có `navigator.onLine` (không tin cậy 100%, chỉ biết có network interface, không biết có internet thật). Flutter `handler.reject()` skip **tất cả** downstream interceptors — Axios `Promise.reject()` cũng tương tự.

**Typed exception ngay tại interceptor:**

```dart
error: RemoteException(kind: RemoteExceptionKind.noInternet)
```

→ Downstream code (ViewModel, ExceptionHandler) nhận `RemoteException` typed — không cần check "is this a network error?" nữa. M4 `ExceptionHandler` đã có case cho `noInternet` → hiện dialog "Không có kết nối mạng".

**PRACTICE:** Trả lời: Nếu có mạng WiFi nhưng server down → `ConnectivityInterceptor` pass hay reject? Khi nào error được catch? (Hint: connectivity check ≠ server reachability check)

---

## 6. Paging Executor Pattern 🟡 SHOULD-KNOW

**WHY:** Pagination logic lặp lại ở nhiều màn (notifications, users, products). `PagingExecutor` abstract hóa state management (page tracking, rollback, error handling) → subclass chỉ implement API call.

<!-- AI_VERIFY: base_flutter/lib/data_source/api/paging/base/paging_executor.dart -->
```dart
abstract class PagingExecutor<T, P extends PagingParams> {
  LoadMoreOutput<T> _output;
  LoadMoreOutput<T> _oldOutput;  // snapshot for rollback

  Future<LoadMoreOutput<T>> execute({required bool isInitialLoad, P? params}) async {
    try {
      if (isInitialLoad) {
        _output = LoadMoreOutput<T>(data: <T>[], page: initPage, offset: initOffset);
      }
      final loadMoreOutput = await action(page: page, limit: limit, params: params);
      // ... update _output, _oldOutput
      return newOutput;
    } catch (e) {
      _output = _oldOutput;  // rollback
      throw e is AppException ? e : AppUncaughtException(rootException: e);
    }
  }

  Future<LoadMoreOutput<T>> action({required int page, required int limit, required P? params});
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § PagingExecutor](./01-code-walk.md#13-pagingexecutor--pagination-state-machine)

**EXPLAIN:**

**Template Method pattern:**

```
PagingExecutor.execute()    ← orchestrates state, error handling
    ↓ calls
Subclass.action()           ← implements API call, returns LoadMoreOutput
```

**State management — Snapshot/Rollback:**

| Field | Khi success | Khi error |
|-------|------------|-----------|
| `_output` | Updated (new page, new data) | **Rollback** to `_oldOutput` |
| `_oldOutput` | Updated = `_output` | Unchanged (snapshot preserved) |

→ User đang xem page 3, load page 4 fail → `_output` rollback về page 3 state → UI không bị corrupt, user có thể retry load page 4.

**`isInitialLoad` branching:**
- `true` → pull-to-refresh / first load → reset page to `initPage`, clear data
- `false` → load more → append, increment page

> 💡 **FE Perspective**
> **Flutter:** `PagingExecutor` — Template Method pattern, abstract `action()` cho API call, snapshot/rollback (`_output`/`_oldOutput`) cho error recovery, `isInitialLoad` phân biệt refresh vs load-more
> **React/Vue tương đương:** React Query `useInfiniteQuery` — `queryFn({ pageParam })` callback, `fetchNextPage()` vs `refetch()`, `previousData` giữ khi error. Custom `usePagination` hook
> **Khác biệt quan trọng:** Flutter dùng **abstract class** (OOP Template Method) — React dùng **hook + callback** (functional). Flutter snapshot/rollback là **imperative** (`_oldOutput = _output`) — React Query giữ `previousData` **tự động**. Flutter subclass mỗi endpoint — React Query config per query key.

**PRACTICE:** Tạo `GetUsersPagingExecutor` extends `PagingExecutor<UserData, GetUsersPagingParams>`. Implement `action()` gọi `appApiService.getUsers()`.

> 📌 **Note**: PagingExecutor được giới thiệu ở đây vì error handling aspect (snapshot/rollback pattern). Coverage chi tiết (usage, pagination UI, `InfiniteList` integration) → xem [Module 16](../module-16-popup-dialog-paging/02-concept.md).

---

## 7. Request/Response Logging Strategy 🟢 AI-GENERATE

**WHY:** Debug API issues cần log chi tiết, nhưng production không được log sensitive data. `CustomLogInterceptor` balance giữa debug utility và security.

<!-- AI_VERIFY: base_flutter/lib/data_source/api/middleware/custom_log_interceptor.dart -->
```dart
class CustomLogInterceptor extends BaseInterceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kReleaseMode || !Config.enableLogInterceptor || !Config.enableLogRequestInfo) {
      handler.next(options);
      return;
    }
    // 🌐 emoji prefix logging...
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    // 🎉 emoji prefix, _limitLines(maxLines: 150)
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ⛔️ emoji prefix, status code + response body
  }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § CustomLogInterceptor](./01-code-walk.md#3-customloginterceptor--requestresponse-logging)

**EXPLAIN:**

**3-layer log gate:**

```dart
if (kReleaseMode                        // Layer 1: build mode
    || !Config.enableLogInterceptor      // Layer 2: global toggle
    || !Config.enableLogRequestInfo) {   // Layer 3: per-category toggle
  handler.next(options); return;
}
```

→ Production: **zero overhead** — không gọi `Log.d()`, không build log strings
→ Debug: enabling/disabling từng loại log (request info, success response, error response)

**Emoji convention:**

| Emoji | Phase | Use |
|-------|-------|-----|
| 🌐 | Request | Filter request logs |
| 🎉 | Response | Filter success logs |
| ⛔️ | Error | Filter error logs — dễ spot trong log stream |

**FormData awareness:**

```dart
if (options.data is FormData) {
  // Log fields + files separately, don't dump binary data
}
```

→ Upload file → log file name, content type, length — **không log raw bytes** (security + log overflow).

**Truncation safety:** `_limitLines(maxLines: 150)` — large JSON responses (10k+ lines) bị truncate → log buffer không bị overflow.

**PRACTICE:** Thử đổi emoji convention thành timestamp-based logging. Ưu điểm gì? Nhược điểm gì so với emoji approach khi filter log?

---

### 8. Extension Opportunity — Connectivity-Aware UI Patterns (Bonus)

> ⏭️ **Bonus Content** — Phần này giới thiệu patterns nâng cao. Bạn có thể skip và quay lại sau khi hoàn thành module.

**WHY:** User mất internet giữa lúc dùng app → UX tệ nếu chỉ show generic error. Codebase đã có `ConnectivityHelper` + `ConnectivityInterceptor` — section này dạy cách tận dụng ở UI level.

> ⚠️ **Code mẫu minh hoạ — KHÔNG có trong codebase.** Code trong section này chỉ để giải thích concept connectivity-aware UI. Codebase chỉ có `ConnectivityHelper` + `ConnectivityInterceptor` (ở infrastructure level), chưa implement UI-level indicator.

### Codebase đã có gì?

| Component | File | Vai trò |
|-----------|------|----------|
| `ConnectivityHelper` | `common/helper/` | Stream `onConnectivityChanged` + `isNetworkAvailable` |
| `ConnectivityInterceptor` | `data_source/api/middleware/` | Throw `RemoteException(kind: noInternet)` trước khi gọi API |
| `RemoteExceptionKind.noInternet` | `exception/` | Exception cho "no internet" |

### Pattern: UI-Level Connectivity Indicator

```dart
// Provider wrapping connectivity stream
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityHelper.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
});

// Trong Page — hiện banner khi offline
Widget buildPage(BuildContext context) {
  final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

  return Column(
    children: [
      if (!isOnline)
        MaterialBanner(
          content: const Text('Không có kết nối mạng'),
          backgroundColor: AppColors.current.error.withOpacity(0.1),
          actions: [
            TextButton(
              onPressed: () => ref.invalidate(connectivityProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      Expanded(child: _buildContent()),
    ],
  );
}
```

### Khi nào cần UI indicator vs chỉ interceptor?

| Trường hợp | Interceptor đủ? | Cần UI indicator? |
|-------------|-----------------|-------------------|
| User submit form → no internet | ✅ `runCatching` catch error | ❌ Error message đủ |
| User đang browse list → mất mạng | ❌ Không trigger nếu không gọi API | ✅ Banner cho biết offline |
| Real-time data (chat, notifications) | ❌ Connection drop silent | ✅ Banner + auto-retry khi online |
| Offline-first (cached data available) | ❌ Hiển thị stale data mà user không biết | ✅ "Offline mode" indicator |

> 💡 **FE Perspective — Connectivity**
>
> | Flutter | Web / React |
> |---------|-------------|
> | `connectivity_plus` package | `navigator.onLine` + `online`/`offline` events |
> | `StreamProvider` + `ConnectivityResult` | `useEffect` + `addEventListener('online', ...)` |
> | `ConnectivityInterceptor` (Dio) | Axios interceptor check `navigator.onLine` |
> | `MaterialBanner` | Toast / Banner component |
>
> **Khác biệt:** Web browser tự show offline indicator (Chrome dinosaur). Mobile app không có — phải tự implement.

> ℹ️ **Scope Note:** Full offline-first architecture (request queue + sync + conflict resolution) nằm ngoài scope training. Packages tham khảo: `drift` (SQLite), `connectivity_plus`, `workmanager` (background sync).

---

> 📋 Badge summary → xem [00-overview.md](./00-overview.md)

→ Tiếp theo: [03-exercise.md](./03-exercise.md) — 5 bài tập thực hành.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
