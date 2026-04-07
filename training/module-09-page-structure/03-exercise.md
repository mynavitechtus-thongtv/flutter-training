# Exercises — Thực hành Page Structure & Widgets

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 7](../module-07-base-viewmodel/) (BasePage lifecycle) và [Module 8](../module-08-riverpod-state/) (Riverpod state), đọc xong [01-code-walk.md](./01-code-walk.md).

---

## Quick Checklist: Tạo Page Mới

Khi tạo page mới trong project, follow 5 bước sau:

| # | Step | File/Action | Chi tiết |
|---|------|-------------|----------|
| 1 | Tạo page file | `lib/ui/page/<feature>/<feature>_page.dart` | `extends BasePage`, `@RoutePage()`, override `provider`, `screenViewEvent`, `buildPage` |
| 2 | Tạo ViewModel + State | `<feature>_view_model.dart` + `<feature>_state.dart` | State `extends BaseState` + `@freezed`, VM `extends BaseViewModel`, provider `StateNotifierProvider.autoDispose` |
| 3 | Register route | `app_router.dart` → thêm vào `routes` getter | `AutoRoute(page: XxxRoute.page)` hoặc dùng `buildCustomRoute` |
| 4 | Chạy code-gen | `dart run build_runner build --delete-conflicting-outputs` | Generate `.gr.dart` (route) + `.freezed.dart` (state) |
| 5 | Thêm navigation trigger | Từ page khác: `ref.read(appNavigatorProvider).push(XxxRoute())` | Hoặc dùng `replace`, `popAndPush` tùy UX flow |

> 💡 Quên bước nào → compile error hoặc route không tìm thấy. Chạy code-gen **sau** khi thêm `@RoutePage()` và `@freezed`.

---

## ⭐ Exercise 1: Trace Splash Page Lifecycle

**Mục tiêu:** Trace thứ tự execution từ khi `SplashPage` được mount đến khi navigate sang Login/Main.

### Hướng dẫn

1. Mở [splash_page.dart](../../base_flutter/lib/ui/page/splash/splash_page.dart) và [base_page.dart](../../base_flutter/lib/ui/base/base_page.dart).
2. Đánh số thứ tự execution cho các event sau.

### Template

Điền số thứ tự (1-10):

| # | Event | File | Thứ tự |
|---|-------|------|--------|
| A | `BasePage.build()` called | base_page.dart | ? |
| B | `AppColors.of(context)` — theme init | base_page.dart | ? |
| C | `ref.listen(provider → appException)` registered | base_page.dart | ? |
| D | `ref.listen(provider → isLoading)` registered | base_page.dart | ? |
| E | `FocusDetector` widget created | base_page.dart | ? |
| F | `buildPage(context, ref)` called | splash_page.dart | ? |
| G | `useEffect` callback registered | splash_page.dart | ? |
| H | Widget tree committed to render | Framework | ? |
| I | `useEffect` callback executes | splash_page.dart | ? |
| J | `Future.microtask` → `init()` executes | splash_page.dart | ? |

**Câu hỏi:**
- Nếu `init()` gọi `ref.read(appNavigatorProvider).replaceAll([LoginRoute()])` → SplashPage bị unmount → `useEffect` cleanup có chạy không?
- `ref.listen` (C, D) khác `ref.watch` thế nào? Tại sao `BasePage` dùng `listen` cho exception/loading thay vì `watch`?
- Nếu bỏ `Future.microtask` (gọi `init()` trực tiếp trong `useEffect`) → chuyện gì xảy ra?

### ✅ Checklist hoàn thành
- [ ] Điền đúng thứ tự 10 events
- [ ] Trả lời 3 câu hỏi
- [ ] Hiểu tại sao `BasePage.build()` runs trước `buildPage()`

---

## ⭐ Exercise 2: Add a Form Field to Login Page

**Mục tiêu:** Thêm "Full Name" text field vào login form — thực hành form input wiring pattern.

### Hướng dẫn

**Step 1:** Mở [login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart).

**Step 2:** Thêm `PrimaryTextField` cho "Full Name" **trước** email field:

```dart
// Thêm sau SizedBox(height: 50) và trước PrimaryTextField email
PrimaryTextField(
  title: l10n.fullName,         // ← thêm key vào l10n nếu chưa có, hoặc dùng 'Full Name'
  hintText: 'Enter your name',
  onChanged: (name) => ref.read(provider.notifier).setFullName(name),
  keyboardType: TextInputType.name,
  suffixIcon: const Icon(Icons.person),
),
const SizedBox(height: 24),
```

**Step 3:** Check xem build có pass không (ViewModel method `setFullName` chưa tồn tại → compile error expected).

**Step 4:** Tạo stub method trong ViewModel (nếu muốn compile pass):

```dart
// Trong login_view_model.dart — chỉ stub, không cần logic thực
void setFullName(String name) {
  // TODO: implement
}
```

**Step 5:** Verify UI — field hiển thị đúng vị trí, keyboard type đúng, icon hiển thị.

### Câu hỏi suy nghĩ
- `keyboardType: TextInputType.name` vs `TextInputType.text` — khác biệt trên iOS vs Android?
- Nếu cần validate "Full Name" phải ≥ 2 characters → validation logic đặt ở đâu? (PrimaryTextField / ViewModel / State?)
- Field mới có cần `Consumer` wrap riêng không? Tại sao?

### ✅ Checklist hoàn thành
- [ ] `PrimaryTextField` thêm đúng vị trí trong Column children
- [ ] `onChanged` wire đến `ref.read(provider.notifier).setFullName(...)`
- [ ] Build pass (với stub method)
- [ ] UI render đúng (icon + title + hint)
- [ ] Trả lời 3 câu hỏi
- [ ] **Revert changes** sau khi hoàn thành

---

## ⭐⭐ Exercise 3: Build a Settings Page

**Mục tiêu:** Tạo `SettingsPage` hoàn chỉnh theo BasePage pattern — full page anatomy, init lifecycle, shared components.

### Hướng dẫn

**Step 1:** Tạo file structure:

```
lib/ui/page/settings/
├── settings_page.dart
├── settings_view_model.dart
└── settings_state.dart
```

**Step 2:** Implement `SettingsState`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../index.dart';

part 'settings_state.freezed.dart';

@freezed
sealed class SettingsState extends BaseState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool isDarkMode,
    @Default(false) bool isNotificationEnabled,
    @Default('en') String language,
  }) = _SettingsState;
}
```

**Step 3:** Implement `SettingsViewModel`:

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../index.dart';

final settingsViewModelProvider = StateNotifierProvider.autoDispose<
    SettingsViewModel, CommonState<SettingsState>>(
  (ref) => SettingsViewModel(ref),
);

class SettingsViewModel extends BaseViewModel<SettingsState> {
  SettingsViewModel(this._ref) : super(const CommonState(data: SettingsState()));
  final Ref _ref;

  void init() {
    // TODO: load settings from preferences
  }

  void toggleDarkMode() {
    data = data.copyWith(isDarkMode: !state.data.isDarkMode);
  }

  void toggleNotification() {
    data = data.copyWith(isNotificationEnabled: !state.data.isNotificationEnabled);
  }
}
```

**Step 4:** Implement `SettingsPage` — apply mọi pattern từ code walk:

```dart
@RoutePage()
class SettingsPage extends BasePage<SettingsState,
    AutoDisposeStateNotifierProvider<SettingsViewModel, CommonState<SettingsState>>> {
  const SettingsPage({super.key});

  @override
  ScreenViewEvent get screenViewEvent => ScreenViewEvent(screenName: ScreenName.settingsPage);

  @override
  AutoDisposeStateNotifierProvider<SettingsViewModel, CommonState<SettingsState>> get provider =>
      settingsViewModelProvider;

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    // TODO: implement
    // 1. useEffect + Future.microtask → init()
    // 2. CommonScaffold with CommonAppBar
    // 3. SwitchListTile for dark mode (use Consumer for selective rebuild)
    // 4. SwitchListTile for notification
    // 5. ListTile for language selection
    // 6. ListTile for logout (use ref.read(appNavigatorProvider).showDialog)
  }
}
```

**Step 5:** Register route trong `app_router.dart` (M5 pattern) + chạy `build_runner`.

**Step 6:** Navigate từ `my_profile_page.dart` → `SettingsPage`.

### Yêu cầu kỹ thuật
- [ ] Page anatomy đủ 4 pieces (@RoutePage, BasePage generics, provider, screenViewEvent)
- [ ] `useEffect` + `Future.microtask` cho init
- [ ] Dùng `CommonScaffold` + `CommonAppBar`
- [ ] Ít nhất 1 `Consumer` widget cho selective rebuild
- [ ] Dùng `style()`, `color.xxx`, `l10n.xxx` theo M6 convention
- [ ] Logout action qua `ref.read(appNavigatorProvider).showDialog(...)`

### Câu hỏi suy nghĩ
- `SwitchListTile` value phải watch state → đặt `ref.watch` ở đâu? Trong `Consumer` hay ngoài?
- Nếu tất cả switches watch khác nhau field → mỗi cái wrap `Consumer` riêng hay 1 `Consumer` to?
- ViewModel dùng `StateNotifierProvider.autoDispose` — lifecycle là gì? Khi nào instance mới được tạo? (Xem [M08 § autoDispose](../module-08-riverpod-state/02-concept.md#5-autodispose--family-modifiers--should-know))

### ✅ Checklist hoàn thành
- [ ] 3 files tạo đúng structure
- [ ] `build_runner` thành công
- [ ] Page hiển thị với settings options
- [ ] Consumer wrap đúng vị trí
- [ ] Navigate từ Profile → Settings hoạt động
- [ ] Back button pop đúng
- [ ] Trả lời 3 câu hỏi

---

## ⭐⭐ Exercise 4: Consumer Refactor — Optimize Login Page

**Mục tiêu:** Phân tích login_page.dart, xác định phần nào nên/không nên wrap Consumer, thực hành tối ưu rebuild scope.

### Hướng dẫn

**Step 1:** Mở [login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart).

**Step 2:** Liệt kê tất cả `ref.watch` và `ref.read` calls trong page:

| # | Call | Location | Type | Watches field |
|---|------|----------|------|---------------|
| 1 | ? | ? | watch/read | ? |
| 2 | ? | ? | watch/read | ? |
| ... | | | | |

**Step 3:** Với mỗi `ref.watch`, đánh giá:

| # | Cần Consumer? | Lý do |
|---|--------------|-------|
| 1 | Yes / No | ? |
| 2 | Yes / No | ? |

**Step 4:** Identify refactor opportunity — nếu bạn thêm avatar display (watch `userData`) vào login page → đặt Consumer ở đâu?

**Step 5:** Vẽ rebuild diagram — khi `LoginState.email` thay đổi:

```
LoginState.email changes →
  ├── Consumer 1 (onPageError): rebuild? Y/N
  ├── Consumer 2 (isLoginButtonEnabled): rebuild? Y/N
  ├── PrimaryTextField email: rebuild? Y/N
  ├── PrimaryTextField password: rebuild? Y/N
  └── CommonText "Login" title: rebuild? Y/N
```

### Câu hỏi nâng cao
- Nếu move **toàn bộ** `buildPage` content vào 1 `Consumer` → performance thay đổi thế nào? (improvement hay regression?)
- `ref.watch(provider.select(...))` trong `buildPage` (không trong Consumer) → rebuild scope là gì?
- Khi nào **không nên** dùng `Consumer`? (overhead vs benefit)

### ✅ Checklist hoàn thành
- [ ] Liệt kê đầy đủ watch/read calls
- [ ] Đánh giá Consumer necessity cho mỗi watch
- [ ] Vẽ rebuild diagram
- [ ] Trả lời 3 câu hỏi nâng cao
- [ ] Hiểu Consumer boundary trade-off

---

## ⭐⭐⭐ Exercise 5: AI Dojo — 📝 Documentation Generation

### 🤖 AI Dojo — Widget Documentation cho Page Structure

**Mục tiêu**: Dùng AI sinh documentation cho page code — đánh giá tính chính xác và completeness.

**Bước thực hiện**:

1. Copy nội dung [login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart) vào clipboard.

2. Gửi prompt sau cho AI:

```
Generate documentation cho Flutter widget này theo format:
- Widget overview: mục đích, context sử dụng
- Props/dependencies: list tất cả providers, hooks, external dependencies
- State management: state nào được watch, side effects nào được listen
- Lifecycle: thứ tự init → build → dispose
- Consumer breakdown: mỗi Consumer wrap cái gì, tại sao tách riêng
- Usage example: cách navigate đến page này và pass arguments (nếu có)

Code:
[PASTE login_page.dart]
```

3. Đánh giá documentation AI tạo:
   - **Correctness**: AI mô tả đúng flow (init → useEffect → Future.microtask) không?
   - **Completeness**: AI có list đủ tất cả hooks và ref.watch/ref.read calls?
   - **Accuracy**: AI hiểu đúng BasePage lifecycle (build → buildPage → listeners setup)?

4. Sửa 2-3 chỗ AI viết sai/thiếu → tạo documentation chính xác.

**✅ Tiêu chí đánh giá**:
- [ ] AI tạo documentation cover ≥ 4/6 sections yêu cầu
- [ ] Bạn tìm ≥ 1 chỗ AI mô tả **sai** (thường sai lifecycle order hoặc miss BasePage inheritance)
- [ ] Bạn tìm ≥ 1 chỗ AI **thiếu** (thường miss screenViewEvent hoặc FocusDetector auto-tracking)
- [ ] Final documentation sau khi bạn sửa — chính xác và hữu ích cho developer mới

---

**Next:** [04-verify.md](./04-verify.md) — Kiểm tra kết quả.

<!-- AI_VERIFY: generation-complete -->
