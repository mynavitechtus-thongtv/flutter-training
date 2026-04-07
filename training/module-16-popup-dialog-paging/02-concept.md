# Concepts — Popup, Dialog & Paging Patterns

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

> 📌 **Recap:**
> - **M7:** `BasePopup` abstract class — `popupId` + `buildPopup()` template ([M7](../module-07-base-viewmodel/02-concept.md))
> - **M9:** `CommonScaffold`, `CommonText`, `CommonImage` — shared UI components ([M9](../module-09-page-structure/02-concept.md))
> - **M12:** `RestApiClient`, Dio interceptor chain, pagination response format ([M12](../module-12-data-layer/02-concept.md))
> - **M13:** `PagingExecutor` base, `LoadMoreOutput` state, error boundary ([M13](../module-13-middleware-interceptor-chain/02-concept.md))

---

## 1. BasePopup Pattern & popupId Deduplication — 🟡 SHOULD-KNOW

**WHY:** Hiểu pattern để mở rộng custom dialogs, nhưng base class đã handle dedup — AI gen được.

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_popup.dart -->
```dart
abstract class BasePopup extends StatelessWidget {
  const BasePopup({required this.popupId, super.key});

  final String popupId;
  Widget buildPopup(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return buildPopup(context);
  }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § 1. BasePopup — Abstract Foundation](./01-code-walk.md#1-basepopup--abstract-foundation)

**EXPLAIN:**

`popupId` là **deduplication key** — ngăn user double-tap tạo 2 dialog giống nhau xếp chồng. Mỗi subclass define ID strategy riêng:

| Popup | popupId format | Dedup behavior |
|-------|---------------|----------------|
| `ErrorDialog.error` | `'ErrorDialog.error_$message'` | Cùng message → cùng ID → skip |
| `ConfirmDialog` | `'ConfirmDialog_$message'` | Cùng action → cùng ID |
| `CommonSnackBar` | `'CommonSnackBar.success_$message'` | Type + message dedup |
| `MaintenanceModeDialog` | `'MaintenanceModeDialog'` (static) | Chỉ 1 instance globally |

Tại sao ID chứa message? Vì 2 error khác message ("Timeout" vs "Server error") **nên** hiển thị song song — chúng là events khác nhau.

`buildPopup()` là abstract template method — mỗi subclass tự implement UI, `build()` chỉ delegate xuống.

> 💡 **FE Perspective**
> **Flutter:** `popupId` string-based — cho phép multiple different popups nhưng prevent same popup twice.
> **React/Vue tương đương:** `<Modal isOpen={flag}>` prevent duplicate bằng single boolean state. Hoặc modal manager library track open modals by key.
> **Khác biệt quan trọng:** Flutter dialog là **route** trên Navigator stack, cần ID mechanism. React modal là component trong tree, toggle bằng state.

---

## 2. Dialog Patterns (Error, Confirm, Maintenance) — 🔴 MUST-KNOW

**WHY:** Mọi feature đều cần show dialog — phải hiểu factory pattern, `pop(result)`, và khi nào dùng dialog nào.

<!-- AI_VERIFY: base_flutter/lib/ui/popup/error_dialog/error_dialog.dart -->
```dart
class ErrorDialog extends BasePopup {
  const ErrorDialog._({
    required super.popupId,
    required this.message,
    this.onRetryPressed,
  });

  factory ErrorDialog.error({required String message}) => ErrorDialog._(
    popupId: 'ErrorDialog.error_$message',
    message: message,
  );

  factory ErrorDialog.errorWithRetry({
    required String message,
    required VoidCallback onRetryPressed,
  }) => ErrorDialog._(
    popupId: 'ErrorDialog.errorWithRetry_$message',
    message: message,
    onRetryPressed: onRetryPressed,
  );
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § 2. ErrorDialog — Error + Retry Pattern](./01-code-walk.md#2-errordialog--error--retry-pattern)

**EXPLAIN:**

**Private constructor + named factory** — pattern dùng chung ở cả `ErrorDialog` và `ConfirmDialog`:

1. **Controlled creation** — không thể tạo dialog ở state không hợp lệ (e.g., retry dialog without callback)
2. **Self-documenting API** — `ErrorDialog.errorWithRetry()` rõ ràng hơn `ErrorDialog(hasRetry: true, onRetry: ...)`
3. **Domain vocabulary** — `ConfirmDialog.deleteAccount()` vs `ConfirmDialog.logOut()` → code self-explaining

**3 Dialog archetypes** từ code-walk:

| Aspect | ErrorDialog | ConfirmDialog | MaintenanceModeDialog |
|--------|------------|---------------|----------------------|
| **Purpose** | Inform error | Get user decision | Block entire app |
| **Return** | `void` (dismiss) | `bool` via `pop(true/false)` | None (không dismiss) |
| **Widget** | `AlertDialog.adaptive` | `AlertDialog.adaptive` | `CommonScaffold` (full screen) |
| **popupId** | Dynamic (includes message) | Dynamic | Static (1 instance) |

→ Đã đọc trong [01-code-walk § 3. ConfirmDialog — Confirm/Cancel Pattern](./01-code-walk.md#3-confirmdialog--confirmcancel-pattern) và [01-code-walk § 5. MaintenanceModeDialog — Full-Screen Takeover](./01-code-walk.md#5-maintenancemodedialog--full-screen-takeover)

`ConfirmDialog` trả kết quả qua `Navigator.pop(true/false)` — caller dùng `final confirmed = await showDialog<bool>(...)`. `MaintenanceModeDialog` dùng `CommonScaffold` thay vì `AlertDialog` vì cần full-screen blocking.

> 💡 **FE Perspective**
> **Flutter:** Factory pattern giữ 1 class nhưng API giống multiple components. `pop(result)` trả data ngược caller.
> **React/Vue tương đương:** Separate components (`<DeleteConfirmModal>`, `<LogoutConfirmModal>`) hoặc Promise-based `confirm()`. Material-UI `<Dialog>` + `onClose` callback.
> **Khác biệt quan trọng:** Flutter `showDialog` trả `Future<T?>` — dialog result là awaitable. React dùng callback hoặc state update.

---

## 3. SnackBar Pattern — 🟡 SHOULD-KNOW

**WHY:** Common notification pattern, AI gen được nhưng cần hiểu SnackBar vs Dialog khác biệt.

<!-- AI_VERIFY: base_flutter/lib/ui/popup/common_snack_bar/common_snack_bar.dart -->
```dart
CommonSnackBar.success(message: "Saved!")    // green — color.green1
CommonSnackBar.info(message: "Updated")      // grey — color.grey1
CommonSnackBar.error(message: "Failed")      // red  — color.red1
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § 4. CommonSnackBar — Color-Coded Notifications](./01-code-walk.md#4-commonsnackbar--color-coded-notifications)

**EXPLAIN:**

3 factories, 1 class, chỉ khác `backgroundColor` — consistent styling enforced tại code level, zero configuration cho caller.

**SnackBar vs Dialog — khi nào dùng gì?**

| Criteria | SnackBar | Dialog |
|----------|----------|--------|
| User action required? | No (auto-dismiss) | Yes (must tap) |
| Blocking? | No (overlay, app interactive) | Yes (modal) |
| Position | Bottom of screen | Center of screen |
| Mechanism | `ScaffoldMessenger` | `Navigator` (route) |
| Duration | Time-limited | Until user dismisses |

Key: SnackBar dùng `ScaffoldMessenger` (overlay system), dismiss bằng `ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar()` — **không phải** `Navigator.pop()` vì SnackBar không nằm trên route stack.

> 💡 **FE Perspective**
> **Flutter:** `ScaffoldMessenger.showSnackBar()` — overlay system tách biệt Navigator.
> **React/Vue tương đương:** Toast libraries (`react-toastify`, `notistack`): `toast.success()`, `toast.error()`. Semantic factory → visual variant.
> **Khác biệt quan trọng:** Flutter SnackBar gắn với `Scaffold`, React toast thường global. Flutter cần `ScaffoldMessenger` context.

---

## 4. AlertDialog.adaptive — 🟢 AI-GENERATE

**WHY:** One-liner API, chỉ cần biết API tồn tại — Flutter xử lý cross-platform tự động.

<!-- AI_VERIFY: base_flutter/lib/ui/popup/error_dialog/error_dialog.dart -->
```dart
AlertDialog.adaptive(
  title: Text(title),
  content: Text(message),
  actions: [
    TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
  ],
)
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § 2. ErrorDialog — Error + Retry Pattern](./01-code-walk.md#2-errordialog--error--retry-pattern)

**EXPLAIN:**

Flutter detect platform → render `AlertDialog` (Material trên Android) hoặc `CupertinoAlertDialog` (Cupertino trên iOS). Không cần `if (Platform.isIOS)`.

**Caveats:**
- Cupertino constraints có thể override custom styling (font size, padding)
- `.adaptive` không tự swap button order theo platform convention
- `MaintenanceModeDialog` không dùng `.adaptive` vì cần full-screen layout với `CommonScaffold`

> 💡 **FE Perspective**
> **Flutter:** `AlertDialog.adaptive` — 1 API, 2 platform looks.
> **React/Vue tương đương:** Không có built-in equivalent. Thường dùng CSS media queries hoặc platform-detect library. React Native có `Alert.alert()` tương tự.
> **Khác biệt quan trọng:** Flutter render **native-looking** widgets per platform. Web frameworks thường 1 look across platforms.

---

## 5. PagingExecutor Template Method — 🔴 MUST-KNOW

**WHY:** Phải hiểu Template Method để implement paging mới — AI không giúp debug state rollback.

<!-- AI_VERIFY: base_flutter/lib/data_source/api/paging/base/paging_executor.dart -->
```dart
abstract class PagingExecutor<T, P extends PagingParams> {
  PagingExecutor({
    this.initPage = Constant.initialPage,
    this.initOffset = 0,
    this.limit = Constant.itemsPerPage,
  });

  LoadMoreOutput<T> _output;      // current state
  LoadMoreOutput<T> _oldOutput;   // snapshot for rollback

  Future<LoadMoreOutput<T>> action({
    required int page,
    required int limit,
    required P? params,
  });

  Future<LoadMoreOutput<T>> execute({
    required bool isInitialLoad,
    P? params,
  }) async { ... }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § 6. PagingExecutor — Template Method for Pagination](./01-code-walk.md#6-pagingexecutor--template-method-for-pagination)

**EXPLAIN:**

Subclass chỉ cần **1 method**: `action()`. Toàn bộ orchestration (page tracking, reset, error handling) nằm trong `execute()` base class.

**`execute()` flow — Snapshot/Rollback pattern:**

```
execute(isInitialLoad: false)
  ├── _oldOutput = _output              ← snapshot trước khi fetch
  ├── action(page, limit, params)       ← subclass API call
  │
  ├── ✅ Success:
  │   _output = newOutput               ← update state
  │   _oldOutput = _output              ← update snapshot
  │
  └── ❌ Error:
      _output = _oldOutput              ← rollback về snapshot
      throw AppException
```

Load page 3 fail → state quay lại page 2 clean. User thấy data cũ, có thể retry.

**Template Method vs Strategy:**

| Template Method (base project chọn) | Strategy |
|--------------------------------------|----------|
| Subclass extends, override `action()` | Inject function vào executor |
| Base controls flow | Caller controls flow |
| Phù hợp khi flow **cố định** | Phù hợp khi flow **thay đổi** |

Paging flow luôn giống nhau: reset → fetch → update state → handle error. Chỉ có **fetch** thay đổi per API → Template Method phù hợp.

→ Đã đọc trong [01-code-walk § 8. Concrete Executor — GetNotificationsPagingExecutor](./01-code-walk.md#8-concrete-executor--getnotificationspagingexecutor)

> 💡 **FE Perspective**
> **Flutter:** `PagingExecutor.execute()` orchestrate, `action()` abstract — classic Template Method.
> **React/Vue tương đương:** `react-query` `useInfiniteQuery` cung cấp cùng flow: error khi fetch page mới không mất data pages cũ. Custom hook `usePagination` với `fetchFn` parameter = Strategy variant.
> **Khác biệt quan trọng:** Flutter dùng class inheritance (Template Method). React dùng hooks + callback (Strategy). Cùng kết quả, khác mechanism.

<details>
<summary>📖 Further Reading: Paging Alternatives Comparison</summary>

**Paging Alternatives — Khi nào dùng approach nào?**

Ngoài `PagingExecutor` (custom implementation), có các approach khác:

| Approach | Ưu điểm | Nhược điểm | Khi nào dùng |
|----------|---------|------------|-------------|
| **PagingExecutor** (project) | Full control, rollback, typed state | Tự maintain | Enterprise app cần custom behavior |
| **`infinite_scroll_pagination`** package | API đơn giản, built-in widgets (`PagedListView`) | Ít customizable, thêm dependency | Prototype nhanh, paging đơn giản |
| **Manual `ScrollController`** | Không dependency, flexible | Boilerplate nhiều, tự handle edge cases | App nhỏ, learning purpose |

Manual approach dùng `ScrollController.addListener()` + check `position.pixels >= position.maxScrollExtent - threshold` → trigger load more. Package `infinite_scroll_pagination` wrap logic này + thêm error/empty state widgets.

</details>

---

## 6. LoadMoreOutput State Management — 🟡 SHOULD-KNOW

**WHY:** Freezed model, cấu trúc quen thuộc. Cần hiểu state flow nhưng model shape là AI-gen friendly.

<!-- AI_VERIFY: base_flutter/lib/model/base/load_more_output.dart -->
```dart
@freezed
sealed class LoadMoreOutput<T> with _$LoadMoreOutput<T> {
  const factory LoadMoreOutput({
    required List<T> data,
    Object? otherData,
    @Default(Constant.initialPage) int page,
    @Default(false) bool isRefreshSuccess,
    @Default(0) int offset,
    @Default(false) bool isLastPage,
    @Default(0) int total,
    @Default(false) bool isLoading,
    AppException? exception,
  }) = _LoadMoreOutput;

  int get nextPage => page + 1;
  int get previousPage => page - 1;
  bool get hasError => exception != null;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § 7. LoadMoreOutput — Paging State Model](./01-code-walk.md#7-loadmoreoutput--paging-state-model)

**EXPLAIN:**

Single Freezed model chứa **toàn bộ paging lifecycle state**. UI consume trực tiếp qua fields và computed getters.

**State transitions:**

```
Initial → execute(true) → Page 1 (data: 10 items, page=2)
  → execute(false) → Page 2 (data: 10 items, page=3)
  → execute(false) → Last page (data: 5 items, isLastPage=true) → UI stops loading
```

| `isInitialLoad` | Behavior | Use case |
|-----------------|----------|----------|
| `true` | Reset → fetch page 1 | Pull-to-refresh, filter change |
| `false` | Keep state → fetch next page | Scroll to bottom |

**Field responsibilities:**

| Field | Role |
|-------|------|
| `data` | Items cho current page |
| `page` / `offset` | Page tracking (page-based hoặc offset-based APIs) |
| `isLastPage` | UI biết dừng trigger load more |
| `isLoading` | Show loading indicator |
| `exception` | Error state cho retry UI |
| `isRefreshSuccess` | Phân biệt refresh vs load-more |

Computed getters `nextPage`, `previousPage`, `hasError` — logic đặt trong model, UI không cần tính.

> 💡 **FE Perspective**
> **Flutter:** Freezed immutable model — `copyWith` tạo state mới, reference equality check cho rebuild.
> **React/Vue tương đương:** `useInfiniteQuery` state object: `{ data, hasNextPage, isFetching, error }`. Redux slice với similar fields.
> **Khác biệt quan trọng:** Flutter model là typed class với computed getters. React thường plain object hoặc dùng selector functions.

---

## Summary — Badge Table

| # | Concept | Badge | Lý do |
|---|---------|-------|-------|
| 1 | BasePopup & popupId Deduplication | 🟡 SHOULD-KNOW | Base class handle dedup, AI gen custom dialogs được |
| 2 | Dialog Patterns (Error, Confirm, Maintenance) | 🔴 MUST-KNOW | Mọi feature cần show dialog, factory + pop(result) |
| 3 | SnackBar Pattern | 🟡 SHOULD-KNOW | Common pattern, AI gen được, cần hiểu SnackBar vs Dialog |
| 4 | AlertDialog.adaptive | 🟢 AI-GENERATE | One-liner API, Flutter auto cross-platform |
| 5 | PagingExecutor Template Method | 🔴 MUST-KNOW | Phải hiểu để implement paging + debug rollback |
| 6 | LoadMoreOutput State Management | 🟡 SHOULD-KNOW | Freezed model quen thuộc, cần hiểu state flow |

---

> **Tiếp theo:** [03-exercise.md](./03-exercise.md) — bài tập áp dụng popup & paging patterns.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
