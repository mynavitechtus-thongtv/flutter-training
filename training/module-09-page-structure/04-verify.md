# Verification — Kiểm tra kết quả Module 9

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi liệt kê được 4 pieces bắt buộc khi tạo page mới (`@RoutePage`, `extends BasePage<S,P>`, `provider` getter, `screenViewEvent`)? | Page Anatomy | 🔴 |
| 2 | Tôi giải thích được tại sao dùng `Future.microtask` trong `useEffect` thay vì gọi `init()` trực tiếp? | useEffect + microtask | 🔴 |
| 3 | Tôi phân biệt được khi nào dùng `Consumer` widget vs `ref.watch` trực tiếp trong `buildPage`? | Consumer Selective Rebuild | 🔴 |
| 4 | Tôi mô tả được `CommonScaffold` widget tree: Scaffold → IgnorePointer → SafeArea → Shimmer? → body? | CommonScaffold & Layout | 🟡 |
| 5 | Tôi trace được data flow: `PrimaryTextField.onChanged` → `ref.read(notifier).setField()` → State → Consumer rebuild? | Form Input Pattern | 🟡 |
| 6 | Tôi giải thích được `AutoTabsScaffold` + `BottomNavigationBar` integration — tab routes, tabsRouter, popUntilRoot? | Tab Navigation | 🟡 |
| 7 | Tôi hiểu analytics extension pattern — tại sao đặt trong page file thay vì ViewModel? | Analytics Extension | 🟢 |

**Target:** 3/3 Yes cho 🔴 MUST-KNOW, tối thiểu 6/7 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace Splash Lifecycle ⭐

Đáp án tham khảo:

| # | Event | Thứ tự |
|---|-------|--------|
| A | `BasePage.build()` called | 1 |
| B | `AppColors.of(context)` — theme init | 2 |
| C | `ref.listen(provider → appException)` registered | 3 |
| D | `ref.listen(provider → isLoading)` registered | 4 |
| E | `FocusDetector` widget created | 5 |
| F | `buildPage(context, ref)` called | 6 |
| G | `useEffect` callback registered | 7 |
| H | Widget tree committed to render | 8 |
| I | `useEffect` callback executes | 9 |
| J | `Future.microtask` → `init()` executes | 10 |

**Câu hỏi answers:**
- [ ] Cleanup: `return null` → không có cleanup function → khi SplashPage unmount, `useEffect` cleanup **không chạy** (null = nothing to run). Nếu `return () { cancel(); }` → cleanup **sẽ chạy** khi unmount.
- [ ] `ref.listen` vs `ref.watch`: `listen` **không trigger rebuild** — chỉ execute callback khi value thay đổi. `watch` trigger rebuild toàn widget. `BasePage` dùng `listen` vì exception/loading cần **side effect** (show overlay, handle error) — không cần rebuild widget tree.
- [ ] Bỏ `Future.microtask`: `init()` có thể gọi `state = newState` → `notifyListeners()` → attempt rebuild **trong build phase** → `setState() called during build` assertion error.

### Exercise 2 — Add Form Field ⭐

- [ ] `PrimaryTextField` thêm đúng vị trí — sau `SizedBox(height: 50)`, trước email field
- [ ] `onChanged: (name) => ref.read(provider.notifier).setFullName(name)` — dùng `ref.read` (not `ref.watch`)
- [ ] `keyboardType: TextInputType.name` — iOS hiện name keyboard (auto-capitalize words), Android tương tự `text`
- [ ] Validation logic → đặt trong **ViewModel/State** (computed property), không trong `PrimaryTextField`
- [ ] Field mới **không cần Consumer riêng** nếu không có UI reactive phụ thuộc giá trị field (chỉ cần `onChanged` → ViewModel)

### Exercise 3 — Build Settings Page ⭐⭐

**Structure check:**
- [ ] `settings_state.dart` — `@freezed` + `extends BaseState`
- [ ] `settings_view_model.dart` — `extends BaseViewModel<SettingsState>` + `autoDispose` `StateNotifierProvider`
- [ ] `settings_page.dart` — 4 pieces: `@RoutePage()`, `extends BasePage<...>`, `provider`, `screenViewEvent`
- [ ] `build_runner` generate thành công

**Page implementation check:**
- [ ] `useEffect` + `Future.microtask(() => init())` present
- [ ] `CommonScaffold` + `CommonAppBar(text: 'Settings', leadingIcon: LeadingIcon.back)` (hoặc tương tự)
- [ ] `Consumer` wrap SwitchListTile — `ref.watch(provider.select((v) => v.data.isDarkMode))`
- [ ] `style()`, `color.xxx` dùng đúng convention M6
- [ ] Logout/action qua `ref.read(appNavigatorProvider).showDialog(...)`

**Câu hỏi answers:**
- [ ] `SwitchListTile` value = `ref.watch(...)` → cần trong `Consumer` vì chỉ switch cần rebuild khi toggle, không phải toàn page.
- [ ] Mỗi switch watch field khác → **mỗi cái wrap `Consumer` riêng** cho tối ưu. 1 Consumer to → khi isDarkMode thay đổi → notification switch cũng rebuild (unnecessary).
- [ ] `autoDispose` `StateNotifierProvider` → mỗi lần navigate tạo **instance mới**. `autoDispose` → dispose khi page pop.

### Exercise 4 — Consumer Refactor ⭐⭐

**ref.watch / ref.read inventory:**

| # | Call | Location | Type | Watches field |
|---|------|----------|------|---------------|
| 1 | `ref.read(provider.notifier).setEmail(email)` | PrimaryTextField onChanged | read | — |
| 2 | `ref.read(provider.notifier).setPassword(password)` | PrimaryTextField onChanged | read | — |
| 3 | `ref.read(analyticsHelperProvider)._logEyeIconClickEvent(...)` | onEyeIconPressed | read | — |
| 4 | `ref.watch(provider.select(v => v.data.onPageError))` | Consumer 1 | watch | `onPageError` |
| 5 | `ref.watch(provider.select(v => v.data.isLoginButtonEnabled))` | Consumer 2 | watch | `isLoginButtonEnabled` |
| 6 | `ref.read(analyticsHelperProvider)._logLoginButtonClickEvent()` | ElevatedButton onPressed | read | — |
| 7 | `ref.read(provider.notifier).login()` | ElevatedButton onPressed | read | — |

**Rebuild diagram khi `LoginState.email` changes:**

```
LoginState.email changes →
  ├── Consumer 1 (onPageError): rebuild? → Phụ thuộc: nếu onPageError thay đổi → Yes, nếu không → No
  ├── Consumer 2 (isLoginButtonEnabled): rebuild? → Phụ thuộc: nếu isLoginButtonEnabled thay đổi → Yes
  ├── PrimaryTextField email: rebuild? → No (uncontrolled — internal state)
  ├── PrimaryTextField password: rebuild? → No
  └── CommonText "Login" title: rebuild? → No (không watch gì)
```

**Key insight:** `select` chỉ so sánh **derived value** — nếu `email` thay đổi nhưng `isLoginButtonEnabled` vẫn `false` (password vẫn empty) → Consumer 2 **KHÔNG rebuild**.

### Exercise 5 — AI Prompt Dojo ⭐⭐⭐

- [ ] AI output ≥ 4/6 tiêu chí pass
- [ ] AI nhận diện BasePage auto-handles exception/loading/analytics → page chỉ cần `buildPage`
- [ ] AI hiểu Consumer + `select` → micro-rebuild pattern
- [ ] AI so sánh React đúng (Consumer ≈ memo, select ≈ useSelector)
- [ ] AI **KHÔNG** suggest refactor BasePage thành composition (valid pattern trong codebase context)
- [ ] Bạn identify ≥ 1 điểm AI thiếu (ví dụ: FocusDetector auto-screenview, LoadingStateProvider hierarchy)

---

## 3. Concept Cross-Check

| # | Scenario | Đáp án đúng | Concept |
|---|----------|-------------|---------|
| 1 | Tạo page mới quên `@RoutePage()` → ? | `build_runner` không generate route class → compile error khi dùng trong router | Page Anatomy |
| 2 | `useEffect(() { init(); }, [])` (không `Future.microtask`) → ? | Có thể crash nếu `init()` triggers state change synchronously | useEffect + microtask |
| 3 | Wrap toàn bộ `buildPage` trong 1 `Consumer` → ? | Functional equivalent → KHÔNG tối ưu: rebuild toàn page, mất lợi ích selective rebuild | Consumer |
| 4 | `CommonScaffold(shimmerEnabled: true)` + data loaded → ? | Shimmer wraps body luôn, Shimmer widget internally controls animation based on `LoadingStateProvider` | CommonScaffold |
| 5 | `PrimaryTextField.onChanged` dùng `ref.watch` thay vì `ref.read` → ? | Mỗi state change → callback tái tạo → không crash nhưng unnecessary rebuild overhead | Form Input |
| 6 | Thêm tab mới vào `BottomTab` enum nhưng quên thêm route → ? | Enum compile OK nhưng runtime: tab count ≠ route count → index out of bounds crash | Tab Navigation |

---

## 4. Architecture Cross-Check

| Component | File | Vai trò | Dùng bởi |
|-----------|------|---------|----------|
| `BasePage<ST, P>` | `base_page.dart` | Abstract base: exception + loading + analytics | Mọi page (`SplashPage`, `LoginPage`, ...) |
| `CommonScaffold` | `common_scaffold.dart` | Layout wrapper: SafeArea + shimmer + keyboard | Mọi page trong `buildPage` |
| `CommonText` | `common_text/` | Styled text with `style()` convention | Mọi nơi cần hiển thị text |
| `PrimaryTextField` | `primary_text_field/` | Form input: focus + obscure + onChanged | Login page, form pages |
| `CommonImage` | `common_image/` | Image display: `.asset()`, `.network()` | Login background, notification cards |
| `CommonAppBar` | `common_app_bar/` | App bar with standard styling | Home page, settings pages |
| `AutoTabsScaffold` | auto_route package | Tab host: routes + bottomNavigationBuilder | `MainPage` |
| `Consumer` | hooks_riverpod package | Selective rebuild boundary | Login page (error, button) |

**Dependency flow:**

```
@RoutePage ──→ auto_route code gen ──→ Route class (.gr.dart)
    ↓
BasePage ──→ provider getter ──→ ViewModel ──→ State
    ↓
buildPage ──→ CommonScaffold ──→ body (Consumers + Components)
    ↓
Components (CommonText, PrimaryTextField, ...) ──→ style() / color. / l10n. (M6)
```

---

## 5. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Quên `@RoutePage()` annotation | `build_runner` không generate route → compile error | Luôn thêm annotation trước run `build_runner` |
| 2 | Override `build()` thay vì `buildPage()` | Mất exception handling, loading overlay, analytics | Chỉ override `buildPage()` — **NEVER** override `build()` |
| 3 | Gọi `init()` trực tiếp (không `Future.microtask`) | State change trong build phase → assertion error | Luôn wrap trong `Future.microtask(() => init())` |
| 4 | Dùng `ref.watch` trong event handler | Unnecessary rebuild, potential side effects | Event handler → `ref.read`, reactive UI → `ref.watch` |
| 5 | Không wrap reactive UI trong `Consumer` | Toàn page rebuild khi bất kỳ field thay đổi | Identify reactive sections → wrap từng cái trong `Consumer` |
| 6 | `CommonScaffold` quên `shimmerEnabled` cho data page | Không có skeleton loading → flash of empty content | Data-driven pages nên set `shimmerEnabled: true` |
| 7 | Thêm tab nhưng quên update cả 3 nơi (enum + route + page) | Runtime crash: tab/route count mismatch | Checklist: enum value → route children → tab page file |

> 📌 Xem thêm: [M05 Verify — Route mistakes](../module-05-navigation/04-verify.md) | [M08 Verify — ref.watch mistakes](../module-08-riverpod-state/04-verify.md)
> Mistakes #1, #7 liên quan route (M05). Mistakes #4, #5 liên quan ref.watch/Consumer (M08).

---

## ✅ Module Complete

Hoàn thành khi:
- [ ] 7/7 Self-Assessment = Yes (ít nhất 6/7)
- [ ] Exercise 1 + 2 done (⭐)
- [ ] Exercise 3 hoặc 4 done (⭐⭐)
- [ ] Hiểu page structure pattern → có thể tạo page mới từ scratch **không cần copy-paste**
- [ ] Common Mistakes: nhận diện được tất cả 7 mistakes

**→ Next module:** [Module 10 — Hooks](../module-10-hooks/) — Flutter Hooks, useEffect, useTextEditingController, custom hooks.

<!-- AI_VERIFY: generation-complete -->
