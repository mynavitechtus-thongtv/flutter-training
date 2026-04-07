# Exercises — Thực hành Riverpod & State Management

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 7 — Base ViewModel](../module-07-base-viewmodel/) và đọc xong [01-code-walk.md](./01-code-walk.md).

> 📌 **Khác M07:** Exercises ở đây focus vào **Riverpod providers, ref lifecycle, và provider scope** — không lặp lại BaseViewModel lifecycle (đã học ở M07). Nếu chưa rõ `runCatching`, `showLoading`/`hideLoading` → quay lại [M07 exercises](../module-07-base-viewmodel/03-exercise.md).

---

## ⭐ Exercise 1: Trace Provider Lifecycle

**Mục tiêu:** Bật observer logs, trace lifecycle events khi navigate qua Login → Main → back.

### Hướng dẫn

**Step 1:** Mở [Config flags](../../base_flutter/lib/common/config.dart) — bật:
```dart
static const logOnDidAddProvider = true;
static const logOnDidDisposeProvider = true;
static const logOnDidUpdateProvider = false;  // quá nhiều noise
```

**Step 2:** Run app, navigate: Splash → Login → Main → Pop back (nếu có).

**Step 3:** Quan sát console logs, điền bảng:

| Event | Provider | Khi nào fires |
|-------|----------|---------------|
| `didAddProvider` | `splashViewModelProvider` | ? |
| `didAddProvider` | `loginViewModelProvider` | ? |
| `didDisposeProvider` | `splashViewModelProvider` | ? |
| `didAddProvider` | `mainViewModelProvider` | ? |
| `didDisposeProvider` | `loginViewModelProvider` | ? |

**Câu hỏi:**
- `splashViewModelProvider` dispose **trước** hay **sau** `loginViewModelProvider` add?
- Nếu `autoDispose` bị bỏ khỏi `loginViewModelProvider` — `didDisposeProvider` có fire khi navigate away không?
- `appNavigatorProvider` (không autoDispose) — bao giờ `didDisposeProvider` fire?

### ✅ Checklist hoàn thành
- [ ] Điền bảng lifecycle events với thứ tự chính xác
- [ ] Trả lời 3 câu hỏi
- [ ] Hiểu: autoDispose ↔ didDisposeProvider ↔ no listeners

---

## ⭐ Exercise 2: Identify Provider Types

**Mục tiêu:** Classify mọi provider trong base_flutter — type, lifecycle, reason.

### Hướng dẫn

Duyệt codebase và điền bảng đầy đủ:

| Provider | Type | autoDispose? | Lý do chọn type |
|----------|------|-------------|-----------------|
| `appNavigatorProvider` | `Provider` | ❌ | ? |
| `appPreferencesProvider` | `Provider` | ❌ | ? |
| `currentUserProvider` | ? | ? | ? |
| `sharedViewModelProvider` | ? | ? | ? |
| `loginViewModelProvider` | ? | ? | ? |
| `homeViewModelProvider` | ? | ? | ? |
| `exceptionHandlerProvider` | ? | ? | ? |
| `firebaseMessagingServiceProvider` | ? | ? | ? |

**Câu hỏi:**
- Tại sao `currentUserProvider` dùng `StateProvider` thay vì `StateNotifierProvider`?
- Tại sao `sharedViewModelProvider` dùng `Provider` (read-only) dù class có methods?
- Nếu thêm `FutureProvider` cho app config — đặt ở đâu, autoDispose hay không?

### ✅ Checklist hoàn thành
- [ ] Điền đầy đủ bảng (tối thiểu 8 providers)
- [ ] Trả lời 3 câu hỏi
- [ ] Giải thích được decision tree: khi nào Provider / StateProvider / StateNotifierProvider

---

## ⭐⭐ Exercise 3: Riverpod Provider Coordination — Settings Feature

> 📝 Exercise này build trên pattern đã học ở M07 Ex3–Ex4. Focus vào Riverpod-specific patterns thay vì repeat ViewModel setup.

> ⚠️ **Khác biệt với M07 Ex3–Ex4**: Bài này KHÔNG lặp lại M07 — focus là **ref lifecycle và cross-provider coordination**, không phải ViewModel setup.

**Mục tiêu:** Xây dựng SettingsViewModel tập trung vào **cross-provider coordination**, `ref` lifecycle, và `.autoDispose` behavior — các pattern chỉ xuất hiện khi dùng Riverpod.

### Requirements

**Scenario:** SettingsViewModel cần **read và write** qua `appPreferencesProvider` (đã có sẵn trong base_flutter). Thay vì tạo state riêng cho mỗi field, hãy **coordinate giữa providers**.

**Tasks:**

| Task | Focus Riverpod pattern |
|------|------------------------|
| 1. Inject `appPreferencesProvider` vào SettingsViewModel | `ref.read()` trong constructor |
| 2. `toggleDarkMode()` — read current value, flip, save | `ref.read(appPreferencesProvider).saveDarkMode(...)` |
| 3. Watch `currentUserProvider` để disable settings khi logged out | `ref.watch()` vs `ref.read()` — khi nào dùng cái nào? |
| 4. Thử bỏ `.autoDispose` → observe: Settings state persist khi navigate away và quay lại | `.autoDispose` behavior |

### Hướng dẫn

**Step 1:** Tạo provider declaration — focus vào `ref` usage:

```dart
final settingsViewModelProvider = StateNotifierProvider.autoDispose<
    SettingsViewModel, CommonState<SettingsState>>(
  (ref) {
    // TODO: Dùng ref.read hay ref.watch cho appPreferencesProvider? Tại sao?
    final prefs = ref._____(appPreferencesProvider);
    return SettingsViewModel(ref, prefs);
  },
);
```

**Step 2:** Implement cross-provider read trong ViewModel:

```dart
class SettingsViewModel extends BaseViewModel<SettingsState> {
  final AppPreferences _prefs;

  // TODO: toggleDarkMode dùng _prefs để persist
  // TODO: Khi nào cần runCatching ở đây? (hint: _prefs.saveDarkMode có async không?)
}
```

**Step 3:** Experiment với `.autoDispose` behavior:
- [ ] Run app với `.autoDispose` → navigate away từ Settings → quay lại → state reset?
- [ ] Bỏ `.autoDispose` → repeat → state preserved?
- [ ] Quan sát console logs (từ Exercise 1) — `didDisposeProvider` fire khi nào?

**Câu hỏi:**
- `ref.read` vs `ref.watch` trong provider factory — khi nào dùng cái nào? Nếu dùng sai thì sao?
- Nếu Settings là app-wide (persist khi navigate) — bỏ `.autoDispose`, consequences gì ngoài state preserved?
- Nếu 2 providers cùng watch lẫn nhau (`A.watch(B)` + `B.watch(A)`) — chuyện gì xảy ra?

### ✅ Checklist hoàn thành
- [ ] Provider declaration với `ref.read(appPreferencesProvider)` injection
- [ ] `toggleDarkMode()` coordinate giữa ViewModel state và AppPreferences
- [ ] Experiment `.autoDispose` on/off — ghi nhận behavior khác biệt
- [ ] Trả lời 3 câu hỏi (đặc biệt `ref.read` vs `ref.watch`)
- [ ] Hiểu tại sao circular provider dependency là lỗi

---

## ⭐⭐ Exercise 4: Selector Optimization

**Mục tiêu:** Phân tích và tối ưu widget rebuilds bằng `.select()`.

### Scenario

Giả sử `login_page.dart` có layout:

```dart
Widget buildPage(BuildContext context, WidgetRef ref) {
  // Current — không selector:
  final state = ref.watch(loginViewModelProvider);

  return Column(children: [
    Text(state.data.email),           // A: email display
    Text(state.data.onPageError),     // B: error message
    if (state.isLoading)              // C: loading indicator
      CircularProgressIndicator(),
    ElevatedButton(                   // D: login button
      onPressed: state.isLoading ? null : () => ref.read(loginViewModelProvider.notifier).login(),
      child: Text('Login'),
    ),
  ]);
}
```

### Tasks

**Task 1:** Đếm rebuilds khi user gõ email "test@example.com" (16 ký tự):
- Widget A rebuild bao nhiêu lần? 
- Widget C rebuild bao nhiêu lần?
- Tổng `build()` calls = ?

**Task 2:** Refactor dùng selectors — tách thành separate widgets hoặc separate `ref.watch`:

```dart
// Rewrite — mỗi widget chỉ watch field cần thiết:
// TODO: refactor
```

**Task 3:** Đếm lại rebuilds sau refactor:
- Widget A rebuild? 
- Widget C rebuild?
- Performance gain = ?

**Câu hỏi:**
- Tại sao không thể dùng `ref.watch` với selector trực tiếp trên `state.data.email` nếu `LoginState` không dùng `@freezed`?
- `.select()` so sánh bằng `==` — nếu return object mới mỗi lần (e.g., `List`) thì sao?
- `ref.watch(provider.select((s) => s.data))` vs `ref.watch(provider.select((s) => s.data.email))` — cái nào granular hơn?

### ✅ Checklist hoàn thành
- [ ] Đếm rebuild counts trước refactor
- [ ] Refactor code dùng `.select()` 
- [ ] Đếm lại proves improvement
- [ ] Trả lời 3 câu hỏi

---

## ⭐⭐⭐ Exercise 5: AI Dojo — 🏗️ Architecture Challenge

### 🤖 AI Dojo — Provider Architecture Design

**Mục tiêu**: Mô tả feature mới cho AI → AI thiết kế provider architecture → so sánh với approach của bạn.

**Bước thực hiện**:

1. **Trước khi hỏi AI** — tự thiết kế trên giấy/notes (5 phút):

> Feature: "Shopping Cart" — user thêm items, xem tổng giá, checkout. Cart persist qua session (không mất khi đổi tab). Checkout cần confirm dialog + API call.

   Ghi lại: bạn dùng bao nhiêu providers? Loại gì? autoDispose hay không?

2. Gửi prompt sau cho AI:

```
Thiết kế Riverpod provider architecture cho Shopping Cart feature trong Flutter:
- User thêm/xóa items từ nhiều pages khác nhau
- Cart state persist khi navigate giữa các tabs (không reset)
- Tổng giá tính realtime khi items thay đổi
- Checkout flow: confirm dialog → API call → clear cart → navigate to success page
- Project dùng StateNotifierProvider + BaseViewModel pattern

Cho tôi:
1. Danh sách providers cần tạo (tên, type, autoDispose hay không, lý do)
2. Data flow diagram: user add item → providers nào update → UI nào rebuild
3. Vấn đề cần cẩn thận (state sync, dispose timing, error handling)
```

3. So sánh design của AI với design của bạn:
   - AI dùng mấy providers? Bạn dùng mấy?
   - AI có đề xuất `autoDispose: false` cho cart (vì persist qua navigation)?
   - AI handle checkout error flow thế nào?

4. Merge ý tưởng: lấy điểm tốt từ cả hai design → viết final architecture.

**✅ Tiêu chí đánh giá**:
- [ ] Bạn thiết kế architecture TRƯỚC khi hỏi AI (không copy AI)
- [ ] AI design và design của bạn có ≥ 1 khác biệt đáng suy nghĩ
- [ ] AI giải thích được autoDispose decision cho cart provider
- [ ] Bạn viết final design kết hợp insights từ cả hai — giải thích lý do chọn

<!-- AI_VERIFY: generation-complete -->
