# Verification — Kiểm tra kết quả Module 8

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được `ProviderScope` tạo `ProviderContainer`, vị trí root, và `overrides` cho testing? | ProviderScope & Container | 🔴 |
| 2 | Tôi chọn đúng provider type (Provider / StateProvider / StateNotifierProvider / FutureProvider) trong < 10 giây? | Types Taxonomy | 🔴 |
| 3 | Tôi hiểu tại sao base_flutter bridge getIt → Provider thay vì dùng getIt trực tiếp trong ViewModel? | DI Bridge | 🟡 |
| 4 | Tôi phân biệt `ref.read` (one-shot) / `ref.watch` (rebuild) / `ref.listen` (side-effect) và rules từng method? | ref API | 🔴 |
| 5 | Tôi giải thích được `autoDispose` lifecycle: create → alive → no listeners → dispose → fresh on re-enter? | autoDispose & family | 🟡 |
| 6 | Tôi dùng `.select()` để chỉ rebuild khi field cụ thể thay đổi — giải thích performance impact? | Selector Pattern | 🔴 |
| 7 | Tôi phân biệt shared state (app-wide, no autoDispose) vs page state (scoped, autoDispose) — communication flow? | Shared vs Page | 🟡 |

**Target:** 7/7 Yes. Tối thiểu 4/4 🔴 MUST-KNOW phải Yes.

---

## 2. Exercise Verification

### Exercise 1 — Trace Provider Lifecycle ⭐

**Expected lifecycle sequence:**

| # | Event | Provider | Trigger |
|---|-------|----------|---------|
| 1 | `didAddProvider` | `splashViewModelProvider` | Splash page mounts, first `ref.watch` |
| 2 | `didDisposeProvider` | `splashViewModelProvider` | Navigate to Login → splash page unmounts → no listeners |
| 3 | `didAddProvider` | `loginViewModelProvider` | Login page mounts, first `ref.watch` |
| 4 | `didAddProvider` | `mainViewModelProvider` | Navigate to Main → main page mounts |
| 5 | `didDisposeProvider` | `loginViewModelProvider` | Login page replaced → no listeners → autoDispose |

**Đáp án câu hỏi:**
- `splashViewModelProvider` dispose **trước** `loginViewModelProvider` add — Splash unmount diễn ra, rồi Login mount.
- Bỏ `autoDispose` → `didDisposeProvider` **không fire** khi navigate away — VM vẫn alive trong container → memory leak.
- `appNavigatorProvider` (no autoDispose) → `didDisposeProvider` chỉ fire khi **ProviderContainer dispose** = app terminate.

### Exercise 2 — Identify Provider Types ⭐

**Đáp án bảng:**

| Provider | Type | autoDispose? | Lý do |
|----------|------|-------------|-------|
| `appNavigatorProvider` | `Provider` | ❌ | DI bridge — service, read-only, app-wide |
| `appPreferencesProvider` | `Provider` | ❌ | DI bridge — getIt singleton |
| `currentUserProvider` | `StateProvider` | ❌ | Simple mutable, global, no business logic |
| `sharedViewModelProvider` | `Provider` | ❌ | Utility service, no mutable state |
| `loginViewModelProvider` | `StateNotifierProvider` | ✅ | Page VM, complex state + business logic |
| `homeViewModelProvider` | `StateNotifierProvider` | ✅ | Page VM, page-scoped |
| `exceptionHandlerProvider` | `Provider` | ❌ | Service with ref, app-wide |
| `firebaseMessagingServiceProvider` | `Provider` | ❌ | DI bridge — getIt singleton |

**Đáp án câu hỏi:**
- `currentUserProvider` dùng `StateProvider` vì chỉ cần set/get `UserData` — không có methods, no business logic → StateNotifier overkill.
- `sharedViewModelProvider` dùng `Provider` (read-only) — class có methods nhưng **không** có mutable state (no `StateNotifier`). Methods tác động lên **other providers** (`appPreferencesProvider`, `appNavigatorProvider`), không self-state.
- `FutureProvider` cho app config → đặt cùng level DI bridge, **không** autoDispose (config persist suốt app).

### Exercise 3 — SettingsViewModel ⭐⭐

**Verification checklist:**

```dart
// ✅ State đúng pattern:
@freezed
sealed class SettingsState extends BaseState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool isDarkMode,
    @Default('en') String language,
    @Default(true) bool notificationsEnabled,
  }) = _SettingsState;
}

// ✅ Provider đúng pattern:
final settingsViewModelProvider =
    StateNotifierProvider.autoDispose<SettingsViewModel, CommonState<SettingsState>>(
  (ref) => SettingsViewModel(ref),
);

// ✅ ViewModel đúng pattern:
class SettingsViewModel extends BaseViewModel<SettingsState> {
  SettingsViewModel(this._ref) : super(const CommonState(data: SettingsState()));
  final Ref _ref;

  void toggleDarkMode() {
    data = data.copyWith(isDarkMode: !data.isDarkMode);
  }

  void setLanguage(String lang) {
    data = data.copyWith(language: lang);
  }

  void toggleNotifications() {
    data = data.copyWith(notificationsEnabled: !data.notificationsEnabled);
  }

  Future<void> resetDefaults() async {
    await runCatching(
      action: () async {
        data = const SettingsState(); // reset to defaults
      },
    );
  }
}
```

**Đáp án câu hỏi:**
- `toggleDarkMode` **không** cần `runCatching` — purely synchronous, no async/API, no error possible. `runCatching` cho async operations có thể fail.
- Bỏ `.autoDispose` → Settings state persists khi navigate away → user quay lại thấy state cũ (có thể OK nếu intentional), nhưng VM **không** release memory.
- Read preferences: `_ref.read(appPreferencesProvider).saveSomething(value)` — dùng `ref.read` (not watch) vì đây là action, not subscription.

### Exercise 4 — Selector Optimization ⭐⭐

**Task 1 — Before refactor (no selectors):**
- User gõ 16 ký tự → `setEmail()` gọi 16 lần → state change 16 lần
- Widget A (email): 16 rebuilds ✅ (cần)
- Widget C (loading): 16 rebuilds ❌ (unnecessary — isLoading không đổi!)
- Tổng `build()` = 16 calls → **mọi widget rebuild**

**Task 2 — After refactor:**
```dart
// Refactored — separate watches:
final email = ref.watch(loginViewModelProvider.select((s) => s.data.email));
final error = ref.watch(loginViewModelProvider.select((s) => s.data.onPageError));
final isLoading = ref.watch(loginViewModelProvider.select((s) => s.isLoading));
```

**Task 3 — After refactor rebuild counts:**
- Widget A (email): 16 rebuilds (cần — email thực sự đổi)
- Widget C (loading): 0 rebuilds ✅ (isLoading không đổi khi gõ email)
- Performance gain: Widget C, D saved 16 unnecessary rebuilds

**Đáp án câu hỏi:**
- Không `@freezed` → `==` comparison fail (default identity, not value equality) → selector **luôn** fire dù value giống → no optimization. Freezed provides value equality.
- Return List mới mỗi lần → `==` fails (khác instance dù cùng elements) → rebuild mỗi state change. Fix: `const []` default, hoặc `DeepCollectionEquality`.
- `.select((s) => s.data)` rebuild khi **bất kỳ** field trong data đổi. `.select((s) => s.data.email)` chỉ rebuild khi email đổi → **granular hơn**.

---

## 3. Cross-Module Connections

| Từ M8 | Kết nối | Forward |
|--------|---------|---------|
| `ProviderScope` root | ← M1: App entrypoint setup | → M12: Override providers trong test |
| Provider types taxonomy | ← M7: StateNotifierProvider cho ViewModel | → M9: Consume providers trong concrete pages |
| DI bridge (getIt → Provider) | ← M2: getIt + injectable registration | → M12: Mock DI services via provider override |
| ref.listen / ref.watch | ← M7: BasePage reactive binding | → M9: Widget-level consumption patterns |
| autoDispose lifecycle | ← M7: ViewModel dispose | → M15: Advanced state coordination |
| Selector pattern | ← M7: BasePage select for exception/loading | → M9: Performance optimization in lists |

---

## 4. Completion Gate

Trước khi chuyển sang [Module 9 — Page Structure](../module-09-page-structure/):

- [ ] **Self-assessment:** 7/7 Yes (tất cả 🔴 items phải Yes)
- [ ] **Exercise 1:** Lifecycle trace table hoàn chỉnh + 3 câu hỏi
- [ ] **Exercise 2:** Provider classification table + 3 câu hỏi
- [ ] **Exercise 3:** SettingsViewModel code compiles + pass pattern check
- [ ] **Exercise 4 hoặc 5:** Hoàn thành ít nhất 1 trong 2 bài ⭐⭐/⭐⭐⭐

<!-- AI_VERIFY: generation-complete -->
