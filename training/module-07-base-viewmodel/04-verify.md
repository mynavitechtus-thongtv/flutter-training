# Verification — Kiểm tra kết quả Module 7

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được tại sao `BaseState` là abstract marker class — không có method, chỉ constraint generic? | BaseState Contract | 🟢 |
| 2 | Tôi mô tả được 5 fields của `CommonState` và vai trò từng field (data, appException, isLoading, isFirstLoading, doingAction)? | CommonState Envelope | 🔴 |
| 3 | Tôi trace được `mounted` guard pattern — tại sao mọi setter check `mounted` trước khi update state? | BaseViewModel Lifecycle | 🔴 |
| 4 | Tôi giải thích được `_loadingCount` reference counting — 2 API song song → loading chỉ hide khi tất cả xong? | BaseViewModel Lifecycle | 🔴 |
| 5 | Tôi trace được `runCatching` flow: try → action → catch → wrap exception → handleErrorWhen → retry chain? | runCatching Pattern | 🔴 |
| 6 | Tôi phân biệt được `handleErrorWhen: (_) => false` (inline error) vs default (global dialog)? | runCatching Pattern | 🔴 |
| 7 | Tôi hiểu tại sao `BasePage` dùng `ref.listen` (side-effect) thay vì `ref.watch` (rebuild) cho exception + loading? | BasePage Reactive | 🔴 |
| 8 | Tôi viết được `StateNotifierProvider.autoDispose` declaration cho một ViewModel mới? | Provider Wiring | 🟡 |
| 9 | Tôi biết `AppProviderObserver` log 4 lifecycle events và gated bởi `Config` flags? | AppProviderObserver | 🟢 |

**Target:** 6/6 Yes cho 🔴 MUST-KNOW, tối thiểu 7/9 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace Login Flow ⭐

**Success case đáp án:**

| Step | State change |
|------|-------------|
| 2 | `isLoading: false → true`, `_loadingCount: 0 → 1` |
| 6 | `isLoading: true → false`, `_loadingCount: 1 → 0` |
| 7 | `ref.listen` fires → `_hideLoadingOverlay()` → overlay removed |

**Error case đáp án:**

| Step | State change |
|------|-------------|
| 2 | `isLoading: false → true` |
| 5 | `isLoading: true → false` |
| 6 | `data.onPageError: '' → error message` |
| 7 | `handleErrorWhen` returns `false` → **SKIP** `exception = appException` |
| 8 | `ref.listen(appException)` → **KHÔNG fire** (appException unchanged) → no dialog |

**Verification points:**
- [ ] `handleErrorWhen: (_) => false` → condition `!= false` fails → skip exception setter → `BasePage.ref.listen` không trigger
- [ ] Bỏ `doOnError` → `handleErrorWhen` default = null → condition becomes `null != false` = `true` → **exception setter fires** → dialog hiển thị
- [ ] `doOnSuccessOrError` chạy **trước** `doOnError` trong error flow: hideLoading → doOnSuccessOrError → doOnError

### Exercise 2 — Action Tracking ⭐

**Verification points:**
- [ ] `isDoingAction('login')` = per-action, `isLoading` = global. Dùng `isDoingAction` cho button-specific disable, `isLoading` cho page-wide overlay
- [ ] 2 nút: `actionName: 'emailLogin'` + `actionName: 'googleLogin'` → `isDoingAction('emailLogin')` + `isDoingAction('googleLogin')` independent
- [ ] Quên `actionName` → `startAction` / `stopAction` không gọi → `doingAction` map unchanged → `isDoingAction(...)` luôn `false`

### Exercise 3 — ProfileViewModel ⭐⭐

**Verification checklist:**

```dart
// ✅ State đúng pattern:
@freezed
sealed class ProfileState extends BaseState with _$ProfileState {
  const factory ProfileState({
    @Default('') String name,
    @Default('') String email,
    @Default('') String avatarUrl,
    @Default(false) bool isEditing,
  }) = _ProfileState;
}

// ✅ Provider đúng pattern:
final profileViewModelProvider =
    StateNotifierProvider.autoDispose<ProfileViewModel, CommonState<ProfileState>>(
  (ref) => ProfileViewModel(ref),
);

// ✅ ViewModel đúng pattern:
class ProfileViewModel extends BaseViewModel<ProfileState> {
  ProfileViewModel(this._ref) : super(const CommonState(data: ProfileState()));
  final Ref _ref;

  void setName(String name) { data = data.copyWith(name: name); }
  void setEmail(String email) { data = data.copyWith(email: email); }
  void toggleEditing() { data = data.copyWith(isEditing: !data.isEditing); }

  Future<void> saveProfile() async {
    await runCatching(
      actionName: 'save',
      action: () async {
        await Future.delayed(const Duration(seconds: 2));
        await _ref.read(appNavigatorProvider).pop();
      },
    );
  }
}
```

**Common mistakes:**
- [ ] Quên `extends BaseState` → compile error ở ViewModel generic
- [ ] Quên `.autoDispose` → memory leak khi navigate away
- [ ] Quên `const` trong `CommonState(data: ProfileState())` → không phải compile error, nhưng missed optimization
- [ ] `toggleEditing` dùng `data = data.copyWith(isEditing: true)` thay vì `!data.isEditing` → chỉ set true, không toggle

### Exercise 4 — Multiple Actions ⭐⭐

**Verification points:**
- [ ] `clearCache` + `syncData` cùng lúc: `_loadingCount` = 2 → `isLoading = true`. First completes → count = 1 → still loading. Second completes → count = 0 → `isLoading = false`
- [ ] `handleLoading: false` cho `deleteAccount` → `showLoading()` / `hideLoading()` **không gọi** → overlay spinner **không hiện**. Nhưng `startAction('deleteAccount')` **vẫn gọi** (vì `actionName != null` nằm trong `handleLoading` block) — **Wait, check code logic:** `if (handleLoading) { showLoading(); if (actionName != null) startAction(actionName); }` → `handleLoading: false` → cả `showLoading` **và** `startAction` đều skip! → `isDoingAction('deleteAccount')` luôn false → cần tự startAction/stopAction **trong** action closure
- [ ] `maxRetries: 3` cho syncData → original + 3 retries = **tối đa 4 lần execute**

### Exercise 5 — AI Prompt Dojo ⭐⭐⭐

| # | Key insight | Verified? |
|---|------------|-----------|
| 1 | `doOnError` throw → exception trong catch block → `finally` chạy, nhưng original exception context lost | |
| 2 | `shouldDoBeforeRetrying` = true, `shouldRetryAutomatically` = false → `doOnRetry` chạy nhưng recursive `runCatching` không | |
| 3 | Concurrent same `actionName` → race condition trên `doingAction` map — spread operator không atomic | |
| 4 | `null` = truly unlimited, `999` = hard cap — semantic difference | |
| 5 | `doOnCompleted` fires per-invocation, not once for entire chain → may fire multiple times | |

---

## 3. Cross-Module Connections

| Từ M7 | Kết nối | Forward |
|--------|---------|---------|
| `BaseState` + `CommonState` | → M4: `AppException` trong `CommonState.appException` | → M9: Concrete pages define state |
| `BaseViewModel.runCatching` | → M4: `AppUncaughtException`, `isForcedErrorToHandle` | → M8: Riverpod provider lifecycle |
| `BasePage.ref.listen` | → M5: `ExceptionHandler` + `AppNavigator` | → M9: Widget binding patterns |
| `AppProviderObserver` | → M3: `Config` flags, `Log` utility | → M18: Testing assertions |
| `StateNotifierProvider.autoDispose` | → M2: DI + Riverpod wiring | → M8: Deep-dive provider types |

---

## 4. Completion Gate

Trước khi chuyển sang [Module 8 — State Management](../module-08-riverpod-state/):

- [ ] **Self-assessment:** ≥ 7/9 Yes (tất cả 🔴 items phải Yes)
- [ ] **Exercise 1:** Trace tables hoàn chỉnh + 3 câu hỏi trả lời
- [ ] **Exercise 2:** `actionName` thêm đúng + `isDoingAction` trong widget
- [ ] **Exercise 3:** ProfileState + ProfileViewModel build thành công
- [ ] **Exercise 4 hoặc 5:** Hoàn thành ít nhất 1 trong 2 bài ⭐⭐/⭐⭐⭐

→ Đạt → tiến sang [Module 8](../module-08-riverpod-state/).
→ Chưa đạt → review [02-concept.md](./02-concept.md) concepts tương ứng.

<!-- AI_VERIFY: generation-complete -->
