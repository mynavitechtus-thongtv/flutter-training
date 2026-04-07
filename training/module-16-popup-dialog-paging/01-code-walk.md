# Code Walk — Popup, Dialog & Paging Patterns

> 📌 **Recap:** M7: `BasePage`, `BasePopup` base class | M9: `CommonScaffold`, `CommonText` | M12: `RestApiClient` paging | M13: `PagingExecutor`, `LoadMoreOutput`

---

## Walk Overview

Survey **2 hệ thống** — Popup/Dialog và Paging — cả hai dùng **Template Method pattern**.

```
BasePopup (abstract)                  PagingExecutor (abstract)
  ├── ErrorDialog                       └── GetNotificationsPagingExecutor
  ├── ConfirmDialog
  ├── CommonSnackBar
  └── MaintenanceModeDialog
```

---

## Part A — Popup & Dialog System

### 1. BasePopup — Abstract Foundation

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_popup.dart -->
```
📁 lib/ui/base/base_popup.dart (~15 lines)
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/base/base_popup.dart`](../../base_flutter/lib/ui/base/base_popup.dart)

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

**Structural analysis:**

| Element | Purpose |
|---------|---------|
| `extends StatelessWidget` | Popup là widget, có thể dùng với `showDialog()` hoặc `ScaffoldMessenger` |
| `popupId` (String) | **Deduplication key** — ngăn hiển thị trùng popup cùng lúc |
| `buildPopup()` abstract | Template method — mỗi subclass tự implement UI |
| `build()` delegates | Template Method — `build()` gọi `buildPopup()`, subclass override bước cụ thể |

> 💡 **FE Perspective**
> **Flutter:** `popupId` string-based deduplication — ngăn mở trùng popup khi user double-click.
> **React/Vue tương đương:** React dùng state flag (`isModalOpen`) hoặc modal manager library track open modals by key.
> **Khác biệt quan trọng:** Flutter dialog nằm trên Navigator stack cần ID mechanism. React modal là component trong tree, toggle bằng boolean state.

---

### 2. ErrorDialog — Error + Retry Pattern

<!-- AI_VERIFY: base_flutter/lib/ui/popup/error_dialog/error_dialog.dart -->
```
📁 lib/ui/popup/error_dialog/error_dialog.dart (~75 lines)
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/popup/error_dialog/error_dialog.dart`](../../base_flutter/lib/ui/popup/error_dialog/error_dialog.dart)

Private constructor + 2 named factories: `error()` (OK only), `errorWithRetry()` (Cancel + Retry). `popupId` includes message — `'ErrorDialog.error_$message'`.

**Key observations:**
- Private constructor → force dùng factory, ngăn combination sai
- `AlertDialog.adaptive` → auto Material/Cupertino per platform
- Retry flow: `Navigator.pop()` trước, rồi `onRetryPressed?.call()`
- `_hasRetry` getter (`onRetryPressed != null`) quyết định button layout

---

### 3. ConfirmDialog — Confirm/Cancel Pattern

<!-- AI_VERIFY: base_flutter/lib/ui/popup/confirm_dialog/confirm_dialog.dart -->
```
📁 lib/ui/popup/confirm_dialog/confirm_dialog.dart (~68 lines)
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/popup/confirm_dialog/confirm_dialog.dart`](../../base_flutter/lib/ui/popup/confirm_dialog/confirm_dialog.dart)

Domain-specific factories: `deleteAccount()`, `logOut()`. Trả kết quả qua `Navigator.pop(true/false)`.

| Aspect | ErrorDialog | ConfirmDialog |
|--------|-------------|---------------|
| Return value | void (dismiss) | `bool` via `pop(true/false)` |
| Factories | Generic | Domain-specific |
| Button text | Fixed | Customizable |

Caller: `final confirmed = await showDialog<bool>(context: ctx, builder: (_) => ConfirmDialog.logOut(...));`

> 💡 **FE Perspective**
> **Flutter:** `ConfirmDialog` trả `bool` qua `Navigator.pop(true/false)` — caller `await showDialog<bool>()`.
> **React/Vue tương đương:** `window.confirm()` hoặc Material-UI `<Dialog>` Promise-based pattern.
> **Khác biệt quan trọng:** Flutter `showDialog` trả `Future<T?>` — dialog result là awaitable. React dùng callback hoặc Promise wrapper.

---

### 4. CommonSnackBar — Color-Coded Notifications

<!-- AI_VERIFY: base_flutter/lib/ui/popup/common_snack_bar/common_snack_bar.dart -->
```
📁 lib/ui/popup/common_snack_bar/common_snack_bar.dart (~107 lines)
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/popup/common_snack_bar/common_snack_bar.dart`](../../base_flutter/lib/ui/popup/common_snack_bar/common_snack_bar.dart)

3 factories cùng shape khác màu: `success()` (green), `info()` (grey), `error()` (red).

| Factory | Color | Use case |
|---------|-------|----------|
| `.success()` | `color.green1` | Action completed |
| `.info()` | `color.grey1` | Informational |
| `.error()` | `color.red1` | Error notification |

`buildPopup` trả `SnackBar` widget với `Row(message + closeButton)`. Dismiss dùng `ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar()` — **không phải** `Navigator.pop()` vì SnackBar không nằm trên route stack.

> 💡 **FE Perspective**
> **Flutter:** `ScaffoldMessenger.showSnackBar()` với 3 factory methods cho semantic variants (success/info/error).
> **React/Vue tương đương:** `react-toastify`: `toast.success()`, `toast.error()`. Hoặc `notistack` cho Material-UI.
> **Khác biệt quan trọng:** Flutter SnackBar gắn với `Scaffold` context, không dùng `Navigator.pop()`. React toast thường global.

---

### 5. MaintenanceModeDialog — Full-Screen Takeover

<!-- AI_VERIFY: base_flutter/lib/ui/popup/maintenance_mode_dialog/maintenance_mode_dialog.dart -->
```
📁 lib/ui/popup/maintenance_mode_dialog/maintenance_mode_dialog.dart (~55 lines)
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/ui/popup/maintenance_mode_dialog/maintenance_mode_dialog.dart`](../../base_flutter/lib/ui/popup/maintenance_mode_dialog/maintenance_mode_dialog.dart)

Khác biệt: dùng `CommonScaffold` (full screen, không dismiss), static `popupId` = `'MaintenanceModeDialog'` (chỉ 1 instance globally). Body: app icon + title + message centered.

| Aspect | Dialogs / SnackBar | MaintenanceModeDialog |
|--------|-------------------|----------------------|
| Layout | `AlertDialog` / `SnackBar` | `CommonScaffold` (full screen) |
| Dismissable | Yes | **No** |
| popupId | Dynamic (includes message) | **Static** |

---

## Part B — Paging System

### 6. PagingExecutor — Template Method for Pagination

<!-- AI_VERIFY: base_flutter/lib/data_source/api/paging/base/paging_executor.dart -->
```
📁 lib/data_source/api/paging/base/paging_executor.dart (~67 lines)
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/paging/base/paging_executor.dart`](../../base_flutter/lib/data_source/api/paging/base/paging_executor.dart)

**Class skeleton:**

```dart
abstract class PagingExecutor<T, P extends PagingParams> {
  PagingExecutor({
    this.initPage = Constant.initialPage,
    this.initOffset = 0,
    this.limit = Constant.itemsPerPage,
  });

  LoadMoreOutput<T> _output;      // current state
  LoadMoreOutput<T> _oldOutput;   // snapshot for rollback

  // Abstract — subclass implements API call
  Future<LoadMoreOutput<T>> action({
    required int page,
    required int limit,
    required P? params,
  });

  // Template method — orchestrates paging logic
  Future<LoadMoreOutput<T>> execute({
    required bool isInitialLoad,
    P? params,
  }) async { ... }
}
```

**Generics breakdown:**

| Type param | Purpose | Example |
|------------|---------|---------|
| `T` | Data item type | `NotificationData` |
| `P extends PagingParams` | Custom parameters per API | `GetNotificationsPagingParams` |

**`execute()` flow — the Template Method:**

```
execute(isInitialLoad: true/false)
  │
  ├─ if isInitialLoad → reset _output to initial state
  │
  ├─ call action(page, limit, params)     ← subclass implements
  │
  ├─ success:
  │   ├─ calculate new page number
  │   ├─ calculate new offset
  │   ├─ update _output and _oldOutput
  │   └─ return newOutput
  │
  └─ error:
      ├─ rollback: _output = _oldOutput   ← snapshot/rollback
      └─ throw AppException
```

**Snapshot/Rollback:** Success → `_output = _oldOutput = newOutput`. Error → `_output = _oldOutput` (rollback). Load page 3 fail → state quay lại page 2 clean.

> 💡 **FE Perspective**
> **Flutter:** `PagingExecutor` dùng snapshot/rollback pattern — error khi fetch page mới giữ nguyên data pages cũ.
> **React/Vue tương đương:** `react-query` `useInfiniteQuery` — cùng behavior: error không mất cached pages.
> **Khác biệt quan trọng:** Flutter dùng class inheritance (Template Method). React dùng hook composition (callback injection).

---

### 7. LoadMoreOutput — Paging State Model

<!-- AI_VERIFY: base_flutter/lib/model/base/load_more_output.dart -->
```
📁 lib/model/base/load_more_output.dart
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/model/base/load_more_output.dart`](../../base_flutter/lib/model/base/load_more_output.dart)

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

**Field responsibilities:**

| Field | Role | Updated by |
|-------|------|-----------|
| `data` | Items for current page | `action()` return |
| `page` | Current page number | `execute()` auto-increment |
| `offset` | Item offset (for offset-based APIs) | `execute()` auto-calculate |
| `isLastPage` | No more data to load | `action()` return |
| `isLoading` | Currently fetching | `execute()` |
| `exception` | Error state | `execute()` on catch |
| `isRefreshSuccess` | Was this a refresh? | `execute()` on initial load |
| `total` | Total items count | `action()` return |

---

### 8. Concrete Executor — GetNotificationsPagingExecutor

<!-- AI_VERIFY: base_flutter/lib/data_source/api/paging/get_notifications_paging_executor.dart -->
```
📁 lib/data_source/api/paging/get_notifications_paging_executor.dart (~50 lines)
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/api/paging/get_notifications_paging_executor.dart`](../../base_flutter/lib/data_source/api/paging/get_notifications_paging_executor.dart)

Concrete example: `GetNotificationsPagingExecutor extends PagingExecutor<NotificationData, GetNotificationsPagingParams>`. Inject `AppApiService`, override `action()` — call API → map response → return `LoadMoreOutput`. Provider: `getNotificationsPagingExecutorProvider`.

Subclass chỉ implement `action()` — page tracking, snapshot/rollback, error handling đều nằm trong base `execute()`.

---

## File Map — Quick Reference

| File | Lines | Role | Pattern |
|------|-------|------|---------|
| `lib/ui/base/base_popup.dart` | ~15 | Abstract popup base | Template Method |
| `lib/ui/popup/error_dialog/error_dialog.dart` | ~75 | Error + Retry dialog | Factory + Adaptive |
| `lib/ui/popup/confirm_dialog/confirm_dialog.dart` | ~68 | Confirm/Cancel dialog | Factory + pop(result) |
| `lib/ui/popup/common_snack_bar/common_snack_bar.dart` | ~107 | Color-coded notifications | Factory + ScaffoldMessenger |
| `lib/ui/popup/maintenance_mode_dialog/maintenance_mode_dialog.dart` | ~55 | Full-screen blocking | CommonScaffold takeover |
| `lib/data_source/api/paging/base/paging_executor.dart` | ~67 | Abstract paging executor | Template Method + Snapshot |
| `lib/model/base/load_more_output.dart` | ~27 | Paging state model | Freezed immutable |
| `lib/data_source/api/paging/get_notifications_paging_executor.dart` | ~50 | Concrete paging | API → LoadMoreOutput |

---

> **Tiếp theo:** [02-concept.md](./02-concept.md) phân tích 6 design concepts đằng sau popup và paging systems.

<!-- AI_VERIFY: generation-complete -->
