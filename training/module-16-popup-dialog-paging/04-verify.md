# Verify — Popup, Dialog & Paging Patterns

> Trả lời **không mở source code** trước, sau đó verify bằng source.

---

## Section A — Popup System (5 câu)

### A1. BasePopup purpose
**Q:** `BasePopup` có 2 thành phần chính. Kể tên và giải thích.

**Expected:** (1) `popupId` — String dedup key. (2) `buildPopup()` — abstract template method. `build()` delegates to `buildPopup()`.

### A2. ErrorDialog factories
**Q:** `ErrorDialog` có mấy factory constructors? Khác nhau thế nào?

**Expected:** 2 factories. `error()` — OK only. `errorWithRetry()` — Cancel + Retry, gọi `onRetryPressed` sau pop.

### A3. ConfirmDialog return value
**Q:** `ConfirmDialog` trả về kết quả bằng cách nào?

**Expected:** `Navigator.of(context).pop(bool)`. Cancel → `pop(false)`, OK → `pop(true)`. Caller nhận qua `await showDialog<bool>()`.

### A4. SnackBar dismiss
**Q:** `CommonSnackBar` dùng API nào để dismiss? Tại sao không dùng `Navigator.pop()`?

**Expected:** `ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar()`. SnackBar không nằm trên Navigator route stack — managed bởi ScaffoldMessenger.

### A5. MaintenanceModeDialog
**Q:** `MaintenanceModeDialog` khác các popup khác ở 3 điểm. Kể tên.

**Expected:** (1) Full-screen `CommonScaffold`. (2) Không có dismiss button. (3) Static `popupId` = `'MaintenanceModeDialog'`.

## Section B — Paging System (4 câu)

### B1. Template Method
**Q:** Subclass cần override bao nhiêu methods?

**Expected:** Chỉ 1: `action()`. `execute()` là template method xử lý page tracking, state reset, snapshot/rollback.

### B2. Snapshot/Rollback
**Q:** User xem page 2 (50 items), load page 3 fail. State sau error?

**Expected:** Rollback về page 2 (50 items). `_oldOutput` giữ snapshot, error → `_output = _oldOutput`.

### B3. isInitialLoad
**Q:** `execute(isInitialLoad: true)` và `false` khác nhau thế nào?

**Expected:** `true` → reset state, fetch page 1 (pull-to-refresh, filter change). `false` → giữ state, fetch next page (scroll to bottom).

### B4. LoadMoreOutput fields
**Q:** 3 fields UI cần để quyết định hiển loading indicator?

**Expected:** `isLastPage` (ẩn indicator), `isLoading` (hiện spinner), `hasError` (hiện retry).

## Section C — Design Patterns (3 câu)

### C1. Factory constructor pattern
**Q:** Tại sao `ErrorDialog` dùng private constructor + named factories?

**Expected:** Controlled creation (ngăn state không hợp lệ), self-documenting API (`.error()` vs `.errorWithRetry()` rõ intent).

### C2. AlertDialog.adaptive
**Q:** `.adaptive` giải quyết vấn đề gì? Popup nào KHÔNG dùng nó?

**Expected:** Auto render Material/Cupertino per platform. `MaintenanceModeDialog` không dùng vì full-screen `CommonScaffold`, không phải modal dialog.

### C3. Cross-module mapping
**Q:** Map component → module: `BasePopup`, `CommonText`, `CommonScaffold`, `PagingExecutor`, `LoadMoreOutput`, `AppApiService`

**Expected:** `BasePopup` → M7, `CommonText` → M9, `CommonScaffold` → M9, `PagingExecutor` → M13, `LoadMoreOutput` → M12+M13, `AppApiService` → M12

---

> **Đạt:** ≥ 9/12 câu trả lời chính xác (không mở source).

---

## ➡️ Next Module

Hoàn thành Module 16! Bạn đã nắm vững popup/dialog, pagination patterns.

→ Tiến sang **[Module 17 — Performance & Animation](../module-17-performance-animation/)** để học performance optimization, animation patterns.

<!-- AI_VERIFY: generation-complete -->
