# Exercises — Popup, Dialog & Paging Patterns

> 📌 **Recap:**
> - **M7:** `BasePopup` abstract class, `popupId` dedup ([M7](../module-07-base-viewmodel/03-exercise.md))
> - **M9:** `CommonScaffold`, `CommonText` components ([M9](../module-09-page-structure/03-exercise.md))
> - **M12:** `RestApiClient`, API pagination ([M12](../module-12-data-layer/03-exercise.md))
> - **M13:** `PagingExecutor`, `LoadMoreOutput` ([M13](../module-13-middleware-interceptor-chain/03-exercise.md))

---

## Exercise 1 — ⭐ Trace Popup Flow

### Mục tiêu

Hiểu popup system bằng cách trace class hierarchy, data flow, và dismiss mechanisms.

### Acceptance Criteria

- [ ] Hoàn thành class hierarchy map: `ErrorDialog`, `ConfirmDialog`, `CommonSnackBar`, `MaintenanceModeDialog` — mỗi class ghi rõ: extends gì, `popupId` format, factories, return type
- [ ] Hoàn thành dismiss mechanism table: mỗi popup type dismiss bằng cách nào, API gì
- [ ] Trả lời: `ErrorDialog.error(message: "Timeout")` gọi 2 lần → `popupId` giống nhau không? Hệ thống handle thế nào?

<details>
<summary>🏗️ Architecture Hint</summary>

- Tìm `BasePopup` definition → xem `popupId` abstract property
- Trace từng subclass: `ErrorDialog`, `ConfirmDialog`, `CommonSnackBar`, `MaintenanceModeDialog`
- Tìm dismiss logic: `Navigator.pop()`, auto-dismiss duration, barrier behavior

</details>

---

## Exercise 2 — ⭐⭐ Custom Dialog: WarningDialog

### Mục tiêu

Tạo `WarningDialog` follow base project conventions.

### Acceptance Criteria

- [ ] File: `lib/ui/popup/warning_dialog/warning_dialog.dart`
- [ ] Extends `BasePopup`, private constructor + 2 factories: `unsavedChanges` (Discard + Keep Editing), `lowStorage` (OK only)
- [ ] `AlertDialog.adaptive` + `CommonText` cho mọi text content
- [ ] `popupId` unique per factory + message (format: `'WarningDialog.<factory>_$message'`)
- [ ] Compile thành công

<details>
<summary>🏗️ Architecture Hint</summary>

- Tham khảo `ErrorDialog` cho dual-button + factory pattern
- `Navigator.pop()` trước callback để tránh multiple pops
- Conditional buttons: dùng `if (showDiscardButton)` trong actions list

</details>

<details>
<summary>💡 Gợi ý chi tiết (mở khi stuck > 15 phút)</summary>

- Private constructor: `const WarningDialog._({required super.popupId, ...})`
- Factory `.unsavedChanges`: cần `VoidCallback onDiscard` param, popupId chứa factory name
- Factory `.lowStorage`: chỉ OK button, popupId chứa message để dedup
- `buildPopup()` return `AlertDialog.adaptive(title: ..., content: ..., actions: [...])`

</details>

---

## Exercise 3 — ⭐⭐ Paging Implementation: Search Results

### Mục tiêu

Implement `SearchPagingExecutor` cho search API endpoint.

### Acceptance Criteria

- [ ] `SearchPagingParams extends PagingParams` với field `String query`
- [ ] `SearchPagingExecutor extends PagingExecutor<SearchResult, SearchPagingParams>`
- [ ] Override `action()` — call API, extract data/hasMore/total, return `LoadMoreOutput`
- [ ] Provider registered
- [ ] Trả lời trace scenario: (1) `execute(isInitialLoad: true)` → page=1; (2) `execute(false)` → page=2; (3) Error on page 3 → rollback behavior?

<details>
<summary>🏗️ Architecture Hint</summary>

- API: `GET /search?q={query}&page={page}&limit={limit}` → `{ "data": [...], "pagination": { "hasMore": true, "total": 42 } }`
- Tham khảo existing `PagingExecutor` implementations trong codebase
- `@Injectable()` annotation cho DI registration
- Provider pattern: `final searchPagingExecutorProvider = Provider<SearchPagingExecutor>(...)`

</details>

---

## Exercise 4 — ⭐⭐⭐ AI Dojo: Redesign Popup System

### Mục tiêu

Dùng AI tool explore alternative popup architecture với centralized PopupManager.

### Acceptance Criteria

- [ ] Prompt AI: đề xuất PopupManager hỗ trợ queuing, priority levels, dedup. Kèm Dart interface code.
- [ ] Identify ≥ 3 pros và ≥ 3 cons so với current `BasePopup` approach
- [ ] Viết 1 paragraph synthesis: khi nào dùng current pattern, khi nào centralized manager?

---

## Exercise 5 — ⭐⭐⭐ Wire SearchPagingExecutor vào Page với Infinite Scroll

### Mục tiêu

Kết hợp `SearchPagingExecutor` (Exercise 3) với `BasePage` pattern để tạo page hoàn chỉnh với pull-to-refresh + infinite scroll.

### Acceptance Criteria

- [ ] `SearchResultsPage` extends `BasePage` đúng generic types
- [ ] `SearchResultsState` + `SearchResultsViewModel` theo pattern M07-M08
- [ ] Pull-to-refresh gọi `execute(isInitialLoad: true)` — reset list
- [ ] Scroll gần cuối → auto `loadMore()` — append items
- [ ] `handleLoading: false` cho load-more (không flicker full-page spinner)
- [ ] Empty state hiển thị khi items rỗng
- [ ] Error state với retry button hoạt động
- [ ] `ListView.builder` (KHÔNG dùng `Column` + `SingleChildScrollView`)

<details>
<summary>🏗️ Architecture Hint</summary>

- Files: `lib/ui/page/search_results/` — page + `view_model/` (state + VM)
- State fields: `List<SearchItem> items`, `bool hasMore`, `String query`
- ViewModel: `search(String query)` (initial load) + `loadMore()` (append)
- Page: `useScrollController()` + scroll listener cho infinite scroll
- `RefreshIndicator` wrap `ListView.builder`
- `itemCount: items.length + (hasMore ? 1 : 0)` — extra item cho loading indicator

</details>

<details>
<summary>💡 Gợi ý chi tiết (mở khi stuck > 15 phút)</summary>

- Scroll detection: `scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200`
- `useEffect()` để add/remove scroll listener
- `loadMore`: guard `if (!state.data.hasMore) return;`
- `runCatching(handleLoading: false)` cho load-more để không show full-page loading
- `ListView.builder` itemBuilder: `if (index == items.length)` → show `CircularProgressIndicator`

</details>

---

> **Tiếp theo:** [04-verify.md](./04-verify.md) — Kiểm tra kiến thức popup & paging patterns.

<!-- AI_VERIFY: generation-complete -->
