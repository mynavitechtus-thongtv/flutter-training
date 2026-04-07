# Verification — Kiểm tra kết quả Module 10

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được tại sao `BasePage` extends `HookConsumerWidget` thay vì `ConsumerWidget`? | flutter_hooks & HookConsumerWidget | 🔴 |
| 2 | Tôi liệt kê được 5 built-in hooks dùng trong codebase (`useState`, `useEffect`, `useScrollController`, `useFocusNode`, `useRef`) và purpose? | Built-in Hooks | 🔴 |
| 3 | Tôi phân biệt được 3 modes `useEffect` (`[]`, `[deps]`, `null`) và khi nào cleanup chạy? | useEffect Lifecycle | 🔴 |
| 4 | Tôi giải thích được custom hook pattern — `useXxx()` naming, khi nào extract, file placement? | Custom Hook Pattern | 🟡 |
| 5 | Tôi trace được `useBackBlocker` flow: user Back → block → confirm → `handleNavigation` → `addPostFrameCallback` → pop? | useBackBlocker | 🟡 |
| 6 | Tôi hiểu `useFocusNodeRefocusOnResume` compose 3 hooks và tại sao dùng `useRef` thay `useState` cho controller? | useFocusNodeRefocusOnResume | 🟡 |
| 7 | Tôi liệt kê được 3 hook rules (only in build, consistent order, no conditionals) và consequences khi vi phạm? | Hook Rules | 🟢 |

**Target:** 3/3 Yes cho 🔴 MUST-KNOW, tối thiểu 6/7 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Identify & Classify Hooks ⭐

Đáp án tham khảo (minimum expected):

| # | File | Hook call | Hook type | Return type |
|---|------|-----------|-----------|-------------|
| 1 | base_page.dart | `useState<OverlayEntry?>(null)` | built-in | `ValueNotifier<OverlayEntry?>` |
| 2 | splash_page.dart | `useEffect(() => ..., [])` | built-in | `void` |
| 3 | login_page.dart | `useScrollController()` | built-in | `ScrollController` |
| 4 | main_page.dart | `useEffect(() => ..., [])` | built-in | `void` |

**Câu hỏi answers:**
- [ ] `base_page.dart` gọi `useState` ở `build()`, subclass thêm hooks ở `buildPage()` → thứ tự **ổn** vì `build()` luôn gọi `useState` trước, rồi mới gọi `buildPage()` → hooks order consistent.
- [ ] Thêm `useScrollController()` vào `splash_page.dart` → lần build **đầu tiên** sau thay đổi code, hook mới được thêm → **hot restart** cần thiết (hot reload có thể gây mismatch). Trong production: không có issue vì code compiled lại.

### Exercise 2 — useEffect Cleanup ⭐

**Lifecycle sequence:**

| # | Event | Action |
|---|-------|--------|
| 1 | Page mount | Widget first build |
| 2 | `useEffect` callback runs | `subscription = stream.listen(...)` |
| 3 | Stream emits `offline` | `isOnline.value = false` |
| 4 | Widget rebuild | Text shows "Offline ❌" |
| 5 | User navigates away | Widget unmounting |
| 6 | Cleanup runs | `subscription.cancel()` |

**Câu hỏi answers:**
- [ ] Quên cleanup → subscription vẫn active → stream events fire → `isOnline.value = ...` trên disposed widget → potential crash hoặc memory leak.
- [ ] `return null` ổn khi: `useEffect` chỉ trigger `Future.microtask` (fire-and-forget), không tạo subscription/timer/listener cần cancel.
- [ ] Nếu effect throws → cleanup từ **effect call trước** vẫn chạy khi unmount. Cleanup của effect **hiện tại** không tồn tại (exception trước return statement).

### Exercise 3 — Custom useDebounce ⭐⭐

**Reference implementation:**

```dart
T useDebounce<T>(T value, {required Duration duration}) {
  final debouncedState = useState<T>(value);

  useEffect(() {
    final timer = Timer(duration, () {
      debouncedState.value = value;
    });

    return () => timer.cancel();
  }, [value, duration]);

  return debouncedState.value;
}
```

**Verification checklist:**
- [ ] `useState<T>(value)` — initial debounced value = input value
- [ ] `useEffect` with `[value, duration]` → re-runs when input changes
- [ ] `Timer(duration, callback)` — delayed update
- [ ] `return () => timer.cancel()` — cancel previous timer on new value
- [ ] Returns `T` (unwrapped value), not `ValueNotifier<T>`
- [ ] No hook rule violations

**Câu hỏi answers:**
- [ ] `duration` in deps: cho phép thay đổi debounce time runtime (e.g., user settings). Thường duration cố định → nhưng vẫn best practice đưa vào deps.
- [ ] Type "abc" → clear to "" trong 300ms: timer cho "abc" cancelled, timer mới cho "" bắt đầu → `debouncedSearch = ""` sau 300ms.
- [ ] Generic `T` → works cho mọi type (int, enum, custom object). `useEffect` so sánh keys bằng `==`.
- [ ] React `useDebounce` gần identical — khác: React dùng `setTimeout`/`clearTimeout`, Flutter dùng `Timer`/`timer.cancel()`.

### Exercise 4 — AI Prompt Dojo ⭐⭐⭐

- [ ] AI output ≥ 4/6 criteria pass
- [ ] AI nhận diện hooks pattern standard (HookConsumerWidget + custom hooks = valid)
- [ ] AI hiểu `addPostFrameCallback` — cần vì rebuild phải complete trước pop (không phải race condition)
- [ ] AI phân biệt `useRef` vs `useState` cho controller (no-rebuild vs rebuild)
- [ ] AI **KHÔNG** suggest migrate away from hooks (valid architecture choice)
- [ ] Bạn identify ≥ 1 AI gap (e.g., `context.mounted` guard, `addPostFrameCallback` timing detail)

---

## 3. Concept Cross-Check

| # | Scenario | Đáp án đúng | Concept |
|---|----------|-------------|---------|
| 1 | Page extends `ConsumerWidget` thay vì `HookConsumerWidget` → gọi `useState()` → ? | Compile error: `useState` not available — no HookElement | HookConsumerWidget |
| 2 | `useEffect(() { init(); }, null)` (null thay vì `[]`) → ? | Effect runs **every build** — `init()` called repeatedly → bugs/perf | useEffect Lifecycle |
| 3 | Custom hook `useXxx()` gọi bên trong `onPressed` callback → ? | Runtime crash: no active HookElement — hooks only work in `build()` | Hook Rules |
| 4 | `useState` trong `if (isEditing)` block → toggle `isEditing` → ? | Hook index mismatch → wrong state returned → silent bug or cast error | Hook Rules |
| 5 | `useBackBlocker` gọi `nav.pop()` trực tiếp (không `addPostFrameCallback`) → ? | `PopScope.canPop` chưa update → pop blocked → navigation fails | useBackBlocker |
| 6 | `useRef` thay bằng `useState` cho controller trong `useFocusNodeRefocusOnResume` → ? | Controller internal state change triggers rebuild → unnecessary renders | useRef vs useState |

---

## 4. Architecture Cross-Check

| Component | File | Vai trò | Dùng bởi |
|-----------|------|---------|----------|
| `HookConsumerWidget` | `hooks_riverpod` package | Base class cho hooks + Riverpod | `BasePage`, `CommonScrollbar`, etc. |
| `BasePage` | `base_page.dart` | Abstract base — exception, loading, analytics | All pages |
| `useState` | `flutter_hooks` package | Local reactive state | `base_page.dart`, `use_back_blocker.dart` |
| `useEffect` | `flutter_hooks` package | Side effects, lifecycle | `splash_page.dart`, `main_page.dart` |
| `useScrollController` | `flutter_hooks` package | Auto-managed ScrollController | `login_page.dart` |
| `useFocusNode` | `flutter_hooks` package | Auto-managed FocusNode | `use_focus_node_refocus_on_resume.dart` |
| `useRef` | `flutter_hooks` package | Persistent non-reactive reference | `use_focus_node_refocus_on_resume.dart` |
| `useBackBlocker` | `use_back_blocker.dart` | Custom hook — back navigation guard | Form pages |
| `useFocusNodeRefocusOnResume` | `use_focus_node_refocus_on_resume.dart` | Custom hook — auto-refocus on resume | Text input pages |
| `RefocusOnResumeController` | `refocus_on_resume_controller.dart` | Business logic for refocus | `useFocusNodeRefocusOnResume` |

---

## 5. Kết nối Forward

Module tiếp theo: hooks concepts sẽ được apply trong:
- **[Module 11 — Internationalization (i18n)](../module-11-i18n/):** multi-language support với `slang` package, locale switching, và string resource management.

<!-- AI_VERIFY: generation-complete -->
