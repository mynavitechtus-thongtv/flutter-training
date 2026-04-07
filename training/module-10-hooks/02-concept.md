# Concepts — Hooks & Custom Hooks

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

---

## 1. flutter_hooks & HookConsumerWidget 🔴 MUST-KNOW

**WHY:** Mọi page trong app dùng hooks. Hiểu sai base class → hooks không work, crash runtime.

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_page.dart -->
```dart
abstract class BasePage<ST extends BaseState, P extends ProviderListenable<CommonState<ST>>>
    extends HookConsumerWidget {
  // ...
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingOverlayEntry = useState<OverlayEntry?>(null);
    // ← hooks work because HookConsumerWidget
  }
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § HookConsumerWidget](./01-code-walk.md#1-hookconsumerwidget--tại-sao-hooks-available-trong-pages)

**EXPLAIN:**

**flutter_hooks** là port của React Hooks sang Flutter. Package `hooks_riverpod` cung cấp `HookConsumerWidget` = hooks + Riverpod.

**Widget class comparison:**

| Class | Hooks? | Riverpod ref? | Use case |
|-------|--------|---------------|----------|
| `StatelessWidget` | ❌ | ❌ | Pure UI, no state |
| `HookWidget` | ✅ | ❌ | Hooks only, no Riverpod |
| `ConsumerWidget` | ❌ | ✅ | Riverpod only, no hooks |
| **`HookConsumerWidget`** | ✅ | ✅ | **Chuẩn project — cả hai** |
| `StatefulWidget` | ❌ | ❌ | Manual state (legacy pattern) |
| `ConsumerStatefulWidget` | ❌ | ✅ | Riverpod + manual lifecycle |

**Khi nào dùng gì?**
- `HookConsumerWidget` → **default choice** cho pages (BasePage)
- `ConsumerWidget` → simple components không cần hooks
- `HookWidget` → utility widgets cần hooks nhưng không cần Riverpod
- `StatefulWidget` → gần như **không dùng** trong project này

**Hook Element lifecycle:**

```
HookConsumerWidget.build() called
  ↓
HookElement checks: first build?
  ├── Yes → create hook states (useState → new ValueNotifier, etc.)
  └── No → reuse existing hook states (same order!) → update if keys changed
  ↓
return Widget tree
  ↓
Widget unmount → HookElement.dispose() → all hook states auto-disposed
```

> 💡 **FE Perspective**
> **Flutter:** `HookConsumerWidget` kết hợp hooks + Riverpod ref — base class chuẩn cho pages cần cả local state (hooks) lẫn global state (Riverpod).
> **React/Vue tương đương:** React functional component + Redux Provider context. Vue: `<script setup>` + Pinia.
> **Khác biệt quan trọng:** Flutter **phải chọn base class** để bật hooks; React/Vue hooks luôn available trong function components by default.

**PRACTICE:** Mở [base_page.dart](../../base_flutter/lib/ui/base/base_page.dart) — xác nhận `extends HookConsumerWidget`. Thử đổi thành `ConsumerWidget` → `useState` compile error.

---

## 2. Built-in Hooks — useState, useEffect, useScrollController, useFocusNode, useRef 🔴 MUST-KNOW

**WHY:** Đây là tools cơ bản được dùng ở mọi page. Không nắm → không đọc/viết page code.

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/login_page.dart -->
```dart
final scrollController = useScrollController();
```
<!-- END_VERIFY -->
<!-- AI_VERIFY: base_flutter/lib/ui/base/base_page.dart -->
```dart
final loadingOverlayEntry = useState<OverlayEntry?>(null);
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § Built-in Hooks](./01-code-walk.md#2-built-in-hooks--real-usage-trong-codebase)

**EXPLAIN:**

**Hook catalog — 5 built-in hooks dùng trong codebase:**

| Hook | Trả về | Purpose | Auto-dispose? | Codebase usage |
|------|--------|---------|---------------|----------------|
| `useState<T>(init)` | `ValueNotifier<T>` | Local reactive state | ✅ | `base_page.dart`, `use_back_blocker.dart` |
| `useEffect(fn, keys)` | `void` | Side effects, lifecycle | ✅ (cleanup) | `splash_page.dart`, `main_page.dart` |
| `useScrollController()` | `ScrollController` | Scroll management | ✅ | `login_page.dart` |
| `useFocusNode()` | `FocusNode` | Focus management | ✅ | `use_focus_node_refocus_on_resume.dart` |
| `useRef<T>(init)` | `ObjectRef<T>` | Persistent mutable ref | — | `use_focus_node_refocus_on_resume.dart` |

**useState vs useRef — key distinction:**

```dart
// useState → reactive (triggers rebuild)
final count = useState(0);
count.value = 1;  // → widget rebuilds

// useRef → non-reactive (no rebuild)
final cache = useRef<Map<String, dynamic>>({});
cache.value = {'key': 'updated'};  // → NO rebuild
```

**Use `useState` when:** UI cần update khi value thay đổi (loading state, toggle, counter).
**Use `useRef` when:** Cần persist value across rebuilds mà **không** cần re-render (controllers, caches, flags).

**Hooks replace StatefulWidget boilerplate:**

| StatefulWidget | Hook equivalent | Lines saved |
|----------------|-----------------|-------------|
| `late final controller; initState() { controller = ...; } dispose() { controller.dispose(); }` | `final controller = useScrollController();` | ~10 → 1 |
| `bool _isLoading = false; setState(() => _isLoading = true);` | `final isLoading = useState(false); isLoading.value = true;` | ~5 → 2 |
| `WidgetsBindingObserver + didChangeAppLifecycleState + removeObserver` | `useOnAppLifecycleStateChange(callback)` | ~15 → 3 |

> 💡 **FE Perspective**
> **Flutter:** 5 built-in hooks cơ bản: `useState` (reactive state), `useEffect` (side effects), `useScrollController`, `useFocusNode`, `useRef` (persistent non-reactive ref) — tất cả auto-dispose.
> **React/Vue tương đương:** `useState` ≈ React `useState` / Vue `ref()`. `useRef` ≈ React `useRef`. `useScrollController` và `useFocusNode` không có direct equivalent trên web.
> **Khác biệt quan trọng:** Flutter hooks auto-dispose controllers khi unmount — thay thế toàn bộ `StatefulWidget` + `initState` + `dispose` boilerplate.

**PRACTICE:** Liệt kê tất cả hooks được dùng trong `login_page.dart` và `base_page.dart`. Xác nhận mỗi hook auto-dispose.

---

## 3. useEffect Lifecycle — Mount, Dispose, Dependencies 🔴 MUST-KNOW

**WHY:** `useEffect` là hook phức tạp nhất. Hiểu sai dependency keys → memory leaks, missed updates, infinite loops.

<!-- AI_VERIFY: base_flutter/lib/ui/page/splash/splash_page.dart -->
```dart
useEffect(
  () {
    Future.microtask(() {
      ref.read(provider.notifier).init();
    });
    return null;
  },
  [],
);
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § useEffect](./01-code-walk.md#22-useeffect--side-effects--lifecycle)

**EXPLAIN:**

**Full signature:**

```dart
void useEffect(
  Dispose? Function() effect,  // ← returns cleanup function (or null)
  [List<Object?>? keys],       // ← dependency array (or null/omitted)
);
```

**3 modes dựa trên `keys`:**

```
┌─────────────────┬──────────────────────────────┬───────────────┐
│ keys            │ Effect runs when?            │ Real use case │
├─────────────────┼──────────────────────────────┼───────────────┤
│ []              │ Mount only                   │ init(), fetch │
│ [dep1, dep2]    │ Mount + when deps change     │ re-fetch data │
│ null / omitted  │ Every build (⚠️ rare)        │ debug logging │
└─────────────────┴──────────────────────────────┴───────────────┘
```

**Cleanup lifecycle detail:**

```dart
useEffect(() {
  final sub = stream.listen((data) => /* ... */);

  return () {
    sub.cancel();  // ← cleanup function
  };
}, [streamId]);  // ← effect re-runs when streamId changes
```

**Timeline with dependency changes:**

```
Build 1 (mount, streamId = 'A'):
  → effect runs → sub = stream('A').listen(...)
  → cleanup = () => sub.cancel()

Build 2 (streamId still 'A'):
  → keys unchanged → SKIP (no effect, no cleanup)

Build 3 (streamId = 'B'):
  → cleanup from Build 1 runs → sub('A').cancel()
  → effect runs → sub = stream('B').listen(...)
  → cleanup = () => sub.cancel()

Unmount:
  → cleanup from Build 3 runs → sub('B').cancel()
```

**Common mistakes:**

| Mistake | Symptom | Fix |
|---------|---------|-----|
| `keys: null` (forgot `[]`) | Effect runs every build | Add `[]` for mount-only |
| Missing cleanup | Memory leak (stream still listening) | Return cancel function |
| `keys: [mutableObject]` | Effect never re-runs (same reference) | Use primitive values as keys |
| Call `setState` in effect sync | "setState during build" error | Wrap in `Future.microtask()` |

> 💡 **FE Perspective**
> **Flutter:** `useEffect(fn, keys)` — 3 modes: `[]` = mount only, `[deps]` = re-run khi deps thay đổi, `null` = every build. Cleanup function chạy trước re-run và khi unmount.
> **React/Vue tương đương:** React `useEffect(fn, [])` — identical API. Vue: `onMounted()` + `onUnmounted()`.
> **Khác biệt quan trọng:** Flutter `keys` so sánh bằng `==` operator; React dùng `Object.is`. Flutter không có ESLint plugin auto-check hook dependencies.

> 💡 **FE: `useEffect` cleanup = giống React, khác lifecycle**
> `useEffect` return function = cleanup — giống React `useEffect(() => { return () => cleanup(); }, [])`.
> **Nhưng Flutter hooks chạy trong `build()`**, không phải component lifecycle riêng biệt.
> Cleanup chạy: (1) trước khi effect re-run do dependency change, (2) khi widget unmount.
>
> **Concrete dispose example:**
> ```dart
> useEffect(() {
>   final subscription = stream.listen((data) {
>     // handle data
>   });
>   // ↓ cleanup — cancel subscription khi deps change hoặc unmount
>   return () => subscription.cancel();
> }, [streamId]);
> ```
> → Quên return cleanup = **memory leak** — subscription vẫn active sau khi widget unmount.

**PRACTICE:** Trong `main_page.dart`, effect có `return () {};` (empty cleanup). Suy nghĩ: khi nào cần real cleanup? Viết version với `StreamSubscription` cleanup.

---

### 3b. `useMemoized` — Expensive Computation Cache

> ⚠️ **Khác React**: `useMemoized` KHÔNG có dependency list — nó cache value vĩnh viễn (giống `useMemo(() => value, [])` với deps rỗng). Muốn recompute khi deps đổi → dùng `useMemoized` + `keys` parameter hoặc `useState` + `useEffect`.

> 💡 **FE: `useMemoized` ≈ React `useMemo` — nhưng KHÔNG auto-dispose**
>
> | | Flutter `useMemoized` | React `useMemo` |
> |---|---|---|
> | Syntax | `useMemoized(() => compute(), [keys])` | `useMemo(() => compute(), [deps])` |
> | Re-compute | Khi keys thay đổi | Khi deps thay đổi |
> | Auto-dispose result | ❌ **Không** | ❌ Không |
> | Cleanup needed? | ✅ Phải dùng `useEffect` cleanup nếu result cần dispose | ✅ Same |
>
> ```dart
> // Flutter — useMemoized + useEffect cleanup
> final controller = useMemoized(() => AnimationController(vsync: this), []);
> useEffect(() => controller.dispose, []); // ← BẮT BUỘC cleanup
> // Nếu quên useEffect cleanup → AnimationController leak
> ```
>
> → `useMemoized` chỉ cache computed value, **không quản lý lifecycle**. Nếu value cần dispose → phải pair với `useEffect` cleanup.

---

## 4. Custom Hook Pattern — Extract Reusable Logic 🟡 SHOULD-KNOW

**WHY:** Custom hooks giúp extract logic phức tạp ra khỏi `build()` — reusable, testable, clean.

```dart
// Pattern: useXxx function that calls built-in hooks
ReturnType useXxxYyy(Dependencies deps) {
  // 1. Built-in hooks
  final state = useState(initialValue);

  // 2. Side effects / lifecycle
  useEffect(() { /* ... */ return cleanup; }, [deps]);

  // 3. Return composed result
  return result;
}
```
→ Đã đọc trong [01-code-walk § Hook Composition](./01-code-walk.md#5-hook-composition-pattern--summary)

**EXPLAIN:**

**Naming convention:** `useXxx` prefix — **bắt buộc**. Đây là convention từ React, Flutter Hooks follow.

**When to extract custom hook:**
- Logic **reused** ở ≥ 2 pages
- `build()` method **dài** và complex → extract cho readability
- Logic involves **multiple hooks** wired together
- Need **unit testing** của hook logic riêng

**Custom hook ≠ Helper function:**

| Custom Hook | Helper Function |
|-------------|-----------------|
| Calls other hooks inside | No hook calls |
| Must be called in `build()` | Can be called anywhere |
| Has lifecycle (mount/dispose) | Stateless computation |
| `useXxx()` naming | `calculateXxx()` naming |
**Hướng dẫn tạo Custom Hook:**

1. **Naming:** Luôn bắt đầu bằng `use` prefix: `useTimer`, `useDebounce`, `useFormValidation`
2. **Return type:** Trả về giá trị hoặc Record type nếu cần expose state + actions:
   ```dart
   // Simple return:
   int useCounter() { ... }
   // Record return (state + action):
   ({int count, VoidCallback increment}) useCounter() { ... }
   ```
3. **Khi nào extract:** Logic reuse ≥ 2 nơi, hoặc `build()` quá dài (>50 lines logic), hoặc cần unit test hook logic riêng
4. **File placement:** Shared hooks → `lib/common/hook/`, page-specific → `lib/ui/page/<feature>/`
**File placement:**

```
lib/common/hook/              ← shared hooks (cross-page)
  ├── use_back_blocker.dart
  └── use_focus_node_refocus_on_resume.dart

lib/ui/page/xxx/              ← page-specific hooks (nếu cần)
  └── use_xxx_page_logic.dart
```

> 💡 **FE Perspective**
> **Flutter:** Custom hooks là top-level functions `useXxx()` gọi built-in hooks bên trong — extract reusable lifecycle logic ra khỏi `build()`.
> **React/Vue tương đương:** React custom hooks (1:1 pattern, cùng `useXxx` convention). Vue composables trong `composables/` folder.
> **Khác biệt quan trọng:** Flutter custom hooks là **top-level functions** (giống React) — không phải class methods. Must follow hook rules (same order, no conditionals).

**PRACTICE:** Identify logic trong `login_page.dart` có thể extract thành custom hook. Hint: scroll + keyboard management?

---

### Hooks vs StatefulWidget — Timer Example

So sánh code tương đương giữa hooks và `StatefulWidget` cho một countdown timer:

**StatefulWidget (traditional):**
```dart
class TimerWidget extends StatefulWidget {
  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late Timer _timer;
  int _seconds = 60;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds--);
      if (_seconds <= 0) _timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer.cancel();  // ← phải manual cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('$_seconds');
}
```

**Hooks (codebase pattern):**
```dart
Widget build(BuildContext context, WidgetRef ref) {
  final seconds = useState(60);

  useEffect(() {
    final timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (seconds.value > 0) seconds.value--;
    });
    return timer.cancel;  // ← auto cleanup on unmount
  }, []);

  return Text('${seconds.value}');
}
```

| | StatefulWidget | Hooks |
|---|---|---|
| Lines of code | ~25 | ~12 |
| Cleanup | Manual `dispose()` — quên = memory leak | Return cleanup function — explicit + co-located |
| State + logic | Tách `initState`/`dispose`/`build` | Co-located trong `build()` |
| Reusability | Phải extract mixin hoặc copy code | Extract `useCountdown()` custom hook |

---

## 5. useBackBlocker — PopScope + Async Confirm 🟡 SHOULD-KNOW

**WHY:** Pattern chặn back navigation + confirm dialog — dùng ở mọi form page có unsaved changes.

<!-- AI_VERIFY: base_flutter/lib/common/hook/use_back_blocker.dart -->
```dart
BackBlockerResult useBackBlocker(AppNavigator nav) {
  final isAllowedToPop = useState(false);

  void handleNavigation(VoidCallback? action) {
    isAllowedToPop.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (action != null) { action(); }
      else { nav.pop(); }
    });
  }

  return (isAllowed: isAllowedToPop.value, handleNavigation: handleNavigation);
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § use_back_blocker](./01-code-walk.md#3-use_back_blockerdart--custom-hook-popscope-integration)

**EXPLAIN:**

**Integration diagram:**

```
┌──────────────────────────────────────────────────┐
│ Page (HookConsumerWidget)                        │
│                                                  │
│  final backBlocker = useBackBlocker(nav);        │
│                                                  │
│  PopScope(                                       │
│    canPop: backBlocker.isAllowed,  ◄── hook state│
│    onPopInvokedWithResult: (didPop, _) {         │
│      if (!didPop) showConfirmDialog() ──┐        │
│    },                                   │        │
│    child: Scaffold(...)                 │        │
│  )                                      │        │
│                                         ▼        │
│  User confirms → backBlocker.handleNavigation()  │
│    → isAllowed = true → rebuild → pop succeeds   │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Two-phase approach (tại sao cần 2 frames):**

| Frame | Action | PopScope.canPop |
|-------|--------|-----------------|
| N | `handleNavigation()` → `isAllowedToPop.value = true` | `false` (old value) |
| N | Rebuild scheduled | — |
| N+1 | Widget tree rebuilt with `canPop: true` | `true` ✅ |
| N+1 | `addPostFrameCallback` → `nav.pop()` | Pop allowed |

→ If `nav.pop()` runs in frame N (same frame as `isAllowedToPop = true`), widget tree chưa rebuild → `PopScope` vẫn block.

**Record type (`typedef BackBlockerResult`):**

```dart
typedef BackBlockerResult = ({
  bool isAllowed,
  void Function(VoidCallback? action) handleNavigation,
});
```

Dart 3 record type — lightweight, named fields, no class needed. Pattern phổ biến cho hook returns khi cần expose **state + action**.

> 💡 **FE Perspective**
> **Flutter:** `useBackBlocker` dùng `useState` + `addPostFrameCallback` + `PopScope` — two-phase approach: set state frame N, pop frame N+1 sau rebuild.
> **React/Vue tương đương:** React Router v6 `useBlocker()` / `usePrompt()`. Vue Router: `onBeforeRouteLeave()` guard.
> **Khác biệt quan trọng:** Flutter `PopScope` là **widget** trong tree (declarative); React/Vue guards là **callbacks** (imperative) — Flutter cần 2 frames do widget rebuild cycle.

**PRACTICE:** Trace flow khi user nhấn Back 2 lần nhanh (double-tap). Điều gì xảy ra? Hint: `didPop` check.

---

## 6. useFocusNodeRefocusOnResume — Lifecycle + Controller Coordination 🟡 SHOULD-KNOW

**WHY:** Ví dụ hook compose nhiều hooks + controller pattern. Giải quyết iOS-specific UX bug.

<!-- AI_VERIFY: base_flutter/lib/common/hook/use_focus_node_refocus_on_resume.dart -->
```dart
FocusNode useFocusNodeRefocusOnResume(BuildContext context) {
  final focusNode = useFocusNode();
  final controller = useRef(RefocusOnResumeController()).value;

  useOnAppLifecycleStateChange((previous, current) {
    if (context.mounted) {
      controller.handleLifecycleStateChange(
        state: current, context: context, node: focusNode,
      );
    }
  });

  return focusNode;
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § use_focus_node_refocus_on_resume](./01-code-walk.md#4-use_focus_node_refocus_on_resumedart--lifecycle-aware-custom-hook)

**EXPLAIN:**

**Hook composition architecture:**

```
useFocusNodeRefocusOnResume(context)     ← Custom hook (26 lines)
  │
  ├── useFocusNode()                     ← Built-in: auto FocusNode
  │     └── [auto-create + auto-dispose]
  │
  ├── useRef(RefocusOnResumeController())  ← Built-in: persistent ref
  │     └── [no rebuild on change]
  │     └── RefocusOnResumeController      ← Plain Dart class (no hooks)
  │           ├── handleGoingBackground()
  │           ├── handleResumed()
  │           └── handleLifecycleStateChange()
  │
  └── useOnAppLifecycleStateChange()     ← Built-in: lifecycle observer
        └── [auto-register + auto-unregister]
```

**Separation of concerns:**
- **Hook** (`useFocusNodeRefocusOnResume`) → wiring, lifecycle, hook orchestration
- **Controller** (`RefocusOnResumeController`) → business logic (when to refocus, guard conditions)

Tại sao tách controller ra class riêng?
1. **Testable** — unit test controller logic không cần widget test environment
2. **Reusable** — controller có thể dùng ngoài hook context
3. **Single responsibility** — hook chỉ lo wiring, controller lo logic

**`context.mounted` guard:**

```dart
useOnAppLifecycleStateChange((previous, current) {
  if (context.mounted) {  // ← IMPORTANT: widget might be disposed
    controller.handleLifecycleStateChange(...);
  }
});
```

App lifecycle events có thể fire **sau khi widget đã unmount** (user navigate away trong lúc app resuming). `context.mounted` check prevents "looking up widget in disposed element" crash.

> 💡 **FE Perspective**
> **Flutter:** Hook (`useFocusNodeRefocusOnResume`) lo wiring lifecycle hooks; Controller (`RefocusOnResumeController`) chứa pure logic — tách biệt để unit test riêng.
> **React/Vue tương đương:** React: custom hook + class service. Vue: composable + utility class.
> **Khác biệt quan trọng:** Pattern hook + controller giúp test logic mà không cần widget test environment — pure Dart class testable independently.

**PRACTICE:** `RefocusOnResumeController` check `isAnotherTextInputFocused` trước khi refocus. Tại sao? Scenario: 2 text fields, user switch focus, app resume → refocus field cũ sẽ **override** user intent.

---

## 7. Hook Rules & Limitations 🟢 AI-GENERATE

**WHY:** Vi phạm hook rules → runtime crash hoặc silent bugs. Rules giống React — nhưng enforced differently.

**EXPLAIN:**

**3 Rules — không ngoại lệ:**

### Rule 1: Only call hooks inside `build()`

```dart
// ✅ CORRECT — inside build
@override
Widget build(BuildContext context, WidgetRef ref) {
  final count = useState(0);         // ← OK
  final controller = useScrollController();  // ← OK
  return Text('${count.value}');
}

// ❌ WRONG — outside build
void someMethod() {
  final count = useState(0);         // ← CRASH: no HookElement
}
```

### Rule 2: Always call hooks in the same order

```dart
// ❌ WRONG — conditional hook
@override
Widget build(BuildContext context, WidgetRef ref) {
  if (someCondition) {
    final name = useState('');       // ← hook #1 sometimes exists, sometimes not
  }
  final count = useState(0);        // ← hook #2 becomes hook #1 when condition false → MISMATCH

  // HookElement tracks hooks by INDEX, not name
  // Build 1: [useState(''), useState(0)] → indices [0, 1]
  // Build 2 (condition false): [useState(0)] → index [0] gets wrong state!
}

// ✅ CORRECT — always call, conditionally use
@override
Widget build(BuildContext context, WidgetRef ref) {
  final name = useState('');         // ← always called (hook #0)
  final count = useState(0);        // ← always called (hook #1)

  if (someCondition) {
    // use name.value here
  }
}
```

### Rule 3: Don't call hooks in loops

```dart
// ❌ WRONG — dynamic number of hooks
for (final item in items) {
  final state = useState(item.defaultValue);  // ← items.length might change
}

// ✅ CORRECT — fixed hook count, manage list state
final states = useState<List<String>>(items.map((i) => i.defaultValue).toList());
```

**Hook index tracking:**

```
HookElement maintains: List<HookState> _hooks

build() call #1:      build() call #2:
  useState → _hooks[0]   useState → _hooks[0] ← reuse
  useEffect → _hooks[1]  useEffect → _hooks[1] ← reuse
  useFocusNode → _hooks[2]  useFocusNode → _hooks[2] ← reuse

If order changes → _hooks[0] has WRONG type → cast error / wrong state
```

**Comparison with React:**

| Rule | Flutter Hooks | React Hooks |
|------|---------------|-------------|
| Only in build/render | ✅ Same | ✅ Same |
| Consistent order | ✅ Same | ✅ Same |
| No conditionals | ✅ Same | ✅ Same |
| Lint enforcement | ❌ No official lint | ✅ `eslint-plugin-react-hooks` |

→ Flutter **không có linter tự động** cho hook rules. Developer phải tự enforce. Đây là lý do **code review** quan trọng.

> 💡 **FE Perspective**
> **Flutter:** 3 hook rules bắt buộc: chỉ gọi trong `build()`, luôn cùng thứ tự, không gọi trong conditional/loop — vi phạm gây crash hoặc wrong state.
> **React/Vue tương đương:** React hook rules 100% giống. Vue composables **không** có rule này (track by variable name, không by index).
> **Khác biệt quan trọng:** Flutter **không có** ESLint-like auto-check cho hook rules — phải enforce qua code review. React có `eslint-plugin-react-hooks`.

**PRACTICE:** Review code snippet dưới đây — tìm vi phạm hook rule:

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final isEditing = ref.watch(editingProvider);

  if (isEditing) {
    final controller = useTextEditingController();
    return TextField(controller: controller);
  }

  return Text('Read only');
}
```

Answer: `useTextEditingController` trong conditional → vi phạm Rule 2. Fix: di chuyển hook lên trước `if`.

---

> 📋 Badge summary → xem [00-overview.md](./00-overview.md)

---

## ⏭️ Next Steps

Thực hành → [03-exercise.md](./03-exercise.md) — 4 bài tập từ identify hooks đến custom hook.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
