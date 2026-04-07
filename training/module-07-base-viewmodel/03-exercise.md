# Exercises — Thực hành Base Page, State & ViewModel

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 4 — Exception Handling](../module-04-exception-handling/) và đọc xong [01-code-walk.md](./01-code-walk.md).

> 📌 **Phân biệt M07 vs M08:** Các exercises này focus trên **BaseViewModel lifecycle** — loading counter, error handling qua `runCatching`, dispose pattern, `doingAction` tracking. **Riverpod state management** (provider types, ref API, selector optimization) sẽ ở [M08 exercises](../module-08-riverpod-state/03-exercise.md).

---

## ⭐ Exercise 1: Trace Login Flow End-to-End

**Mục tiêu:** Trace toàn bộ data flow từ user tap "Login" → ViewModel → CommonState → BasePage → UI.

### Hướng dẫn

1. Mở [login_view_model.dart](../../base_flutter/lib/ui/page/login/view_model/login_view_model.dart).
2. Bắt đầu từ `login()` method → trace qua `runCatching` → `base_view_model.dart` → `base_page.dart`.
3. Điền bảng trace cho **success case** và **error case**.

### Template — Success Case

| Step | File | Code | State change |
|------|------|------|-------------|
| 1. User tap Login | `login_page.dart` | `vm.login()` | — |
| 2. runCatching start | `base_view_model.dart` | `showLoading()` | `isLoading: ? → ?` |
| 3. Action execute | `login_view_model.dart` | `action()` closure | — |
| 4. Save tokens | `login_view_model.dart` | `Future.wait([...])` | — |
| 5. Navigate | `login_view_model.dart` | `replaceAll([MainRoute()])` | — |
| 6. runCatching end | `base_view_model.dart` | `hideLoading()` | `isLoading: ? → ?` |
| 7. BasePage react | `base_page.dart` | `ref.listen(isLoading)` | Overlay: ? → ? |

### Template — Error Case

| Step | File | Code | State change |
|------|------|------|-------------|
| 1. User tap Login | `login_page.dart` | `vm.login()` | — |
| 2. runCatching start | `base_view_model.dart` | `showLoading()` | `isLoading: ? → ?` |
| 3. Action throws | `login_view_model.dart` | API throws exception | — |
| 4. Catch + wrap | `base_view_model.dart` | `AppUncaughtException(...)` | — |
| 5. hideLoading | `base_view_model.dart` | `hideLoading()` | `isLoading: ? → ?` |
| 6. doOnError | `login_view_model.dart` | `data.copyWith(onPageError: ...)` | `onPageError: '' → ?` |
| 7. handleErrorWhen | `base_view_model.dart` | returns `false` | exception setter: skipped |
| 8. BasePage | `base_page.dart` | `ref.listen(appException)` | Fires? Yes/No |

**Câu hỏi:**
- Tại sao `handleErrorWhen: (_) => false` ngăn dialog hiển thị?
- Nếu bỏ `doOnError`, error sẽ hiển thị ở đâu? (hint: `handleErrorWhen` default)
- `doOnSuccessOrError` chạy ở step nào trong error flow? Trước hay sau `doOnError`?

### ✅ Checklist hoàn thành
- [ ] Điền 2 bảng trace (success + error) với giá trị cụ thể
- [ ] Trả lời 3 câu hỏi
- [ ] Hiểu flow: ViewModel → CommonState → BasePage `ref.listen` → UI reaction

---

## ⭐ Exercise 2: Add Action Tracking to Login

**Mục tiêu:** Thêm `actionName` vào `login()` — track "đang login" riêng biệt với loading toàn cục.

### Hướng dẫn

**Step 1:** Mở [login_view_model.dart](../../base_flutter/lib/ui/page/login/view_model/login_view_model.dart).

**Step 2:** Modify `login()` — thêm `actionName`:

```dart
FutureOr<void> login() async {
  await runCatching(
    actionName: 'login',          // ← thêm dòng này
    action: () async { ... },
    handleErrorWhen: (_) => false,
    doOnError: (e) async { ... },
  );
}
```

**Step 3:** Trong login page widget, thêm reactive check:

```dart
// Trong buildPage():
final isLoggingIn = ref.watch(
  loginViewModelProvider.select((s) => s.isDoingAction('login')),
);

ElevatedButton(
  onPressed: isLoggingIn ? null : () => vm.login(),
  child: isLoggingIn
      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
      : const Text('Login'),
);
```

**Câu hỏi:**
- `isDoingAction('login')` khác gì `isLoading`? Khi nào cần dùng cái nào?
- Nếu page có 2 nút: "Login" và "Login with Google" — track thế nào?
- `startAction` + `stopAction` nằm trong `runCatching` — nếu quên `actionName` thì sao?

### ✅ Checklist hoàn thành
- [ ] Thêm `actionName: 'login'` vào `runCatching`
- [ ] Sử dụng `isDoingAction('login')` trong widget
- [ ] Trả lời 3 câu hỏi
- [ ] Verify: khi login → button disabled + inline spinner, page loading overlay vẫn hiển thị

---

## ⭐⭐ Exercise 3: Create a ProfileViewModel

**Mục tiêu:** Tạo `ProfileState` + `ProfileViewModel` từ đầu — practice full pattern.

> 💡 **FE Perspective**
> **Flutter:** `StateNotifier` giữ state immutable, expose methods để update — widget listen thay đổi qua `ref.watch()` và rebuild chỉ phần cần thiết.
> **React/Vue tương đương:** Custom hook `useXxxState` + `useReducer` trong React, Pinia `defineStore` + `storeToRefs` trong Vue.
> **Khác biệt quan trọng:** Flutter `StateNotifier` là class-based với explicit state type, React hooks là function-based. Flutter rebuild scoped qua `select()`, React cần `useMemo`/`React.memo` để optimize.

### Requirements

| Field | Type | Default |
|-------|------|---------|
| `name` | `String` | `''` |
| `email` | `String` | `''` |
| `avatarUrl` | `String` | `''` |
| `isEditing` | `bool` | `false` |

Methods:

| Method | Logic |
|--------|-------|
| `setName(String)` | Update name |
| `setEmail(String)` | Update email |
| `toggleEditing()` | Flip `isEditing` |
| `saveProfile()` | `runCatching` → simulate API call (2s delay) → navigate back |

### Hướng dẫn

**Step 1:** Tạo `lib/ui/page/profile/view_model/profile_state.dart`:

> ⚠️ **part directive:** Thêm `part 'profile_state.freezed.dart';` ở đầu file nếu dùng `@freezed`. Thiếu directive này → `build_runner` không generate code → compile error. Xem [M0 § Codegen](../module-00-dart-primer/02-concept.md#3-code-generation-pipeline--should-know).

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../index.dart';

part 'profile_state.freezed.dart';

// Skeleton — điền code:
@freezed
sealed class ProfileState extends BaseState with _$ProfileState {
  const factory ProfileState({
    // TODO: define fields
  }) = _ProfileState;
}
```

> 💡 `sealed class` (Dart 3): cho phép compiler kiểm tra exhaustive pattern matching — đảm bảo bạn handle TẤT CẢ cases trong `switch`/`when`. Treat như convention cho freezed union types.

**Step 2:** Tạo `lib/ui/page/profile/view_model/profile_view_model.dart`:

```dart
// Skeleton — điền code:
final profileViewModelProvider = StateNotifierProvider.autoDispose<
    ProfileViewModel, CommonState<ProfileState>>(
  // TODO: factory
);

class ProfileViewModel extends BaseViewModel<ProfileState> {
  // TODO: constructor + methods
}
```

**Step 3:** Implement `saveProfile()`:
- Dùng `runCatching` với `handleLoading: true`
- Thêm `actionName: 'save'`
- Simulate: `await Future.delayed(Duration(seconds: 2))`
- Success: navigate back (dùng `_ref.read(appNavigatorProvider).pop()`)
- Error: global dialog (default `handleErrorWhen`)

**Step 4:** Chạy `make gen` / `build_runner` để generate freezed code.

### ✅ Checklist hoàn thành
- [ ] `ProfileState extends BaseState` + `@freezed` annotation
- [ ] `ProfileViewModel extends BaseViewModel<ProfileState>`
- [ ] Provider: `StateNotifierProvider.autoDispose`
- [ ] `saveProfile()` dùng `runCatching` đúng pattern
- [ ] `setName`, `setEmail` dùng `data = data.copyWith(...)` pattern
- [ ] `toggleEditing` flip boolean đúng cách
- [ ] Code build thành công (freezed generated)

---

## ⭐⭐ Exercise 4: Multiple Actions Tracking

**Mục tiêu:** Tạo page có nhiều async actions — practice `doingAction` tracking cho từng button.

### Scenario

Một settings page có 3 actions:
1. **"Clear Cache"** — 1s delay, success → snackbar
2. **"Sync Data"** — 3s delay, có thể fail → global error dialog
3. **"Delete Account"** — 2s delay, confirm dialog trước khi execute

### Hướng dẫn

**Step 1:** Tạo `SettingsState`:

```dart
@freezed
sealed class SettingsState extends BaseState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool cacheCleared,
    @Default(false) bool dataSynced,
  }) = _SettingsState;
}
```

**Step 2:** Tạo `SettingsViewModel` với 3 methods:

```dart
Future<void> clearCache() async {
  await runCatching(
    actionName: 'clearCache',
    action: () async {
      await Future.delayed(const Duration(seconds: 1));
      data = data.copyWith(cacheCleared: true);
    },
  );
}

Future<void> syncData() async {
  await runCatching(
    actionName: 'syncData',
    action: () async {
      await Future.delayed(const Duration(seconds: 3));
      data = data.copyWith(dataSynced: true);
    },
    maxRetries: 3,  // allow retry
  );
}

Future<void> deleteAccount() async {
  await runCatching(
    actionName: 'deleteAccount',
    action: () async {
      await Future.delayed(const Duration(seconds: 2));
      await _ref.read(appNavigatorProvider).replaceAll([LoginRoute()]);
    },
    handleLoading: false,  // no global loading — dùng inline indicator
  );
}
```

**Step 3:** Trong widget, track từng action:

```dart
final isClearingCache = ref.watch(provider.select((s) => s.isDoingAction('clearCache')));
final isSyncing = ref.watch(provider.select((s) => s.isDoingAction('syncData')));
final isDeleting = ref.watch(provider.select((s) => s.isDoingAction('deleteAccount')));
```

**Câu hỏi:**
- Nếu user tap "Clear Cache" và "Sync Data" cùng lúc → `isLoading` hiển thị sao?
- `deleteAccount` dùng `handleLoading: false` — overlay spinner có hiện không? Tại sao chọn pattern này?
- `maxRetries: 3` cho syncData — tổng cộng bao nhiêu lần execute (retry + original)?

### ✅ Checklist hoàn thành
- [ ] 3 methods dùng `runCatching` với `actionName` riêng biệt
- [ ] Widget track từng action qua `isDoingAction()`
- [ ] `handleLoading: false` cho deleteAccount — inline indicator only
- [ ] Trả lời 3 câu hỏi

---

## ⭐⭐⭐ Exercise 5: AI Dojo — ⚡ Performance Analysis

### 🤖 AI Dojo — Performance Analysis cho ViewModel

**Mục tiêu**: Dùng AI phân tích performance issues trong ViewModel — unnecessary rebuilds, state management overhead.

**Bước thực hiện**:

1. Copy nội dung [base_view_model.dart](../../base_flutter/lib/ui/base/base_view_model.dart) và [login_view_model.dart](../../base_flutter/lib/ui/page/login/view_model/login_view_model.dart) vào clipboard.

2. Gửi prompt sau cho AI:

```
Phân tích performance của BaseViewModel + LoginViewModel trong Flutter
(Riverpod + StateNotifier).

Tìm:
1. Unnecessary rebuilds: state thay đổi field A nhưng widget watching field B cũng rebuild?
2. Loading counter pattern (showLoading/hideLoading) — có overhead khi nhiều actions
   concurrent không?
3. doingAction Map — mỗi update tạo Map mới ({...state.doingAction}) — với 10+ actions thì sao?
4. runCatching gọi state setter nhiều lần (loading, action tracking, error) — mỗi lần
   trigger rebuild?
5. Đề xuất 3 optimizations cụ thể với code example.

Code:
[PASTE base_view_model.dart + login_view_model.dart]
```

3. Đánh giá từng optimization AI đề xuất:
   - Có thực sự cần thiết cho app scale hiện tại không?
   - Implementation cost vs performance gain?
   - Có break existing pattern/API không?

4. Pick 1 optimization khả thi nhất → viết pseudo-code implement.

**✅ Tiêu chí đánh giá**:
- [ ] AI identify đúng: `state = state.copyWith(...)` trigger rebuild cho TẤT CẢ listeners
- [ ] AI nhận ra `select()` (ở widget level) giảm impact — không phải ViewModel responsibility
- [ ] Bạn đánh giá: ≥ 1 suggestion thực tế, ≥ 1 suggestion over-engineering cho app size hiện tại
- [ ] Bạn **không** apply optimization mà chưa measure — "premature optimization is root of all evil"

---

## Tổng kết Exercises

| # | Bài tập | Độ khó | Concept chính |
|---|---------|--------|---------------|
| 1 | Trace Login Flow | ⭐ | runCatching flow, BasePage reactive |
| 2 | Add Action Tracking | ⭐ | doingAction, actionName |
| 3 | Create ProfileViewModel | ⭐⭐ | Full pattern: State + ViewModel + Provider |
| 4 | Multiple Actions Tracking | ⭐⭐ | Parallel actions, handleLoading |
| 5 | AI Dojo — Performance Analysis | ⭐⭐⭐ | Performance, critical analysis |

**Tiếp theo:** [04-verify.md](./04-verify.md) — checklist tự đánh giá.

<!-- AI_VERIFY: generation-complete -->
