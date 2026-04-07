# Code Walk — Hooks & Custom Hooks

> 📌 **Recap từ modules trước:**
> - **M7:** `BasePage` extends `HookConsumerWidget` — kết hợp Flutter Hooks + Riverpod `WidgetRef`, `buildPage(context, ref)` lifecycle, loading overlay dùng `useState<OverlayEntry?>` ([M7 § base-ui](../module-07-base-viewmodel/01-code-walk.md))
> - **M8:** `ref.watch/read` API, `StateNotifierProvider`, `select` cho reactive UI ([M8 § state-management](../module-08-riverpod-state/01-code-walk.md))
> - **M9:** `useEffect(() { ... }, [])` init pattern ở splash/main, `useScrollController()` ở login/home, `useState<OverlayEntry?>()` ở base_page ([M9 § page-structure](../module-09-page-structure/01-code-walk.md))
>
> Nếu chưa nắm vững → quay lại [Module 7](../module-07-base-viewmodel/), [Module 8](../module-08-riverpod-state/) hoặc [Module 9](../module-09-page-structure/) trước.

---

## Walk Order

```
HookConsumerWidget (BasePage — why hooks are available)
    ↓
Built-in hooks across pages (useState, useEffect, useScrollController)
    ↓
use_back_blocker.dart (custom hook — PopScope integration)
    ↓
use_focus_node_refocus_on_resume.dart (custom hook — lifecycle coordination)
```

Bắt đầu từ **tại sao hooks work** (HookConsumerWidget inheritance) → **built-in hooks đã gặp** (recap real usage) → **custom hook pattern** (extract reusable logic) → **lifecycle-aware hook** (controller coordination).

---

## 1. HookConsumerWidget — Tại sao Hooks Available trong Pages

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_page.dart -->
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../index.dart';

abstract class BasePage<ST extends BaseState, P extends ProviderListenable<CommonState<ST>>>
    extends HookConsumerWidget {
  const BasePage({super.key});

  P get provider;
  ScreenViewEvent get screenViewEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppColors.of(context);

    final loadingOverlayEntry = useState<OverlayEntry?>(null);
    // ...
  }
}
```
<!-- END_VERIFY -->
→ Source: [base_page.dart](../../base_flutter/lib/ui/base/base_page.dart) (line 8–19)

### Breakdown

**Inheritance chain xác định hook availability:**

```
StatelessWidget
  └── ConsumerWidget          ← Riverpod: adds WidgetRef ref
  └── HookWidget              ← flutter_hooks: adds hook calls
      └── HookConsumerWidget  ← BOTH: ref + hooks in build()
          └── BasePage        ← Our base class
              └── SplashPage, LoginPage, MainPage, ...
```

**`HookConsumerWidget`** = `HookWidget` + `ConsumerWidget`. Signature:

```dart
abstract class HookConsumerWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref);
  // Internally uses HookElement → manages hook state across rebuilds
}
```

→ Mọi page kế thừa `BasePage` **tự động** được gọi hooks (`useState`, `useEffect`, `useScrollController`, ...) trong `build()` / `buildPage()`.

**Tại sao không dùng `HookWidget` thôi?**
- `HookWidget` → `build(BuildContext context)` — chỉ có hooks, **không có `ref`**
- `ConsumerWidget` → `build(BuildContext context, WidgetRef ref)` — chỉ có Riverpod, **không có hooks**
- `HookConsumerWidget` → cả hai → **chuẩn cho project dùng hooks_riverpod**

> 💡 **FE Perspective**
> **Flutter:** `HookConsumerWidget` = base class cung cấp cả hooks (`useState`, `useEffect`) lẫn Riverpod `ref` trong `build()` — chuẩn cho mọi page.
> **React/Vue tương đương:** React functional component tự có hooks + Redux context. Vue: `<script setup>` + Pinia store.
> **Khác biệt quan trọng:** Flutter cần **declare** base class (`HookConsumerWidget`) để bật hooks; React/Vue hooks available by default trong function components.

---

## 2. Built-in Hooks — Real Usage trong Codebase

### 2.1 `useState` — Reactive Local State

<!-- AI_VERIFY: base_flutter/lib/ui/base/base_page.dart -->
```dart
// base_page.dart — loading overlay state (M7)
final loadingOverlayEntry = useState<OverlayEntry?>(null);

// Khi isLoading changes:
ref.listen(provider.select((value) => value.isLoading), (previous, next) {
  if (next == true && loadingOverlayEntry.value == null) {
    _showLoadingOverlay(context: context, loadingOverlayEntry: loadingOverlayEntry);
  } else if (previous == true && next == false && loadingOverlayEntry.value != null) {
    _hideLoadingOverlay(loadingOverlayEntry);
  }
});
```
<!-- END_VERIFY -->
→ Source: [base_page.dart](../../base_flutter/lib/ui/base/base_page.dart) (line 19–32)

**`useState<T>(initialValue)`** trả về `ValueNotifier<T>`:
- **Read:** `loadingOverlayEntry.value`
- **Write:** `loadingOverlayEntry.value = newEntry` → widget rebuild
- **Auto-dispose:** khi widget unmount, `ValueNotifier` tự dispose

```
useState<OverlayEntry?>(null)
  ├── .value        ← current value (getter)
  ├── .value = x    ← set new value → triggers rebuild
  └── auto-dispose  ← cleanup khi widget unmount
```

> 💡 **FE Perspective**
> **Flutter:** `useState<T>(initialValue)` tạo reactive local state, trả về `ValueNotifier<T>` — read/write qua `.value`, auto-dispose khi unmount.
> **React/Vue tương đương:** React `useState()` gần 1:1. Vue `ref()`.
> **Khác biệt quan trọng:** Flutter `useState` trả `ValueNotifier` (access qua `.value`); React trả `[value, setValue]` tuple; Vue `ref()` cũng dùng `.value`.

### 2.2 `useEffect` — Side Effects & Lifecycle

<!-- AI_VERIFY: base_flutter/lib/ui/page/splash/splash_page.dart -->
```dart
// splash_page.dart — init on mount (M9)
useEffect(
  () {
    Future.microtask(() {
      ref.read(provider.notifier).init();
    });
    return null;  // ← no cleanup
  },
  [],  // ← empty deps = run once on mount
);
```
<!-- END_VERIFY -->
→ Source: [splash_page.dart](../../base_flutter/lib/ui/page/splash/splash_page.dart) (line 22–31)

<!-- AI_VERIFY: base_flutter/lib/ui/page/main/main_page.dart -->
```dart
// main_page.dart — init with cleanup (M9)
useEffect(
  () {
    Future.microtask(() {
      ref.read(provider.notifier).init();
    });
    return () {};  // ← empty cleanup (dispose callback)
  },
  [],
);
```
<!-- END_VERIFY -->
→ Source: [main_page.dart](../../base_flutter/lib/ui/page/main/main_page.dart) (line 50–59)

**`useEffect` lifecycle model:**

```
useEffect(effectFn, keys)

keys = []    → effectFn runs ONCE on mount
               cleanup runs ONCE on unmount (if non-null)

keys = [a]   → effectFn runs on mount + when `a` changes
               cleanup runs before EACH re-run + on unmount

keys = null  → effectFn runs on EVERY build (rare — avoid)
```

| `keys` | Mount | Rebuild (deps same) | Rebuild (deps changed) | Unmount |
|--------|-------|---------------------|------------------------|---------|
| `[]` | ✅ run | — | — | ✅ cleanup |
| `[a]` | ✅ run | — | ✅ cleanup → ✅ run | ✅ cleanup |
| `null` | ✅ run | ✅ cleanup → ✅ run | ✅ cleanup → ✅ run | ✅ cleanup |

**`return null` vs `return () {}`:**
- `return null` → **no cleanup** — splash page doesn't need cleanup
- `return () {}` → **empty cleanup** — main_page explicitly states "I acknowledge cleanup exists"
- `return () { subscription.cancel(); }` → **real cleanup** — cancel subscriptions

### 2.3 `useScrollController` — Auto-managed Controller

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/login_page.dart -->
```dart
// login_page.dart (M9)
@override
Widget buildPage(BuildContext context, WidgetRef ref) {
  final scrollController = useScrollController();

  return CommonScaffold(
    body: Stack(
      children: [
        CommonScrollbarWithIosStatusBarTapDetector(
          routeName: LoginRoute.name,
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            // ...
          ),
        ),
      ],
    ),
  );
}
```
<!-- END_VERIFY -->
→ Source: [login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart) (line 47–65)

**Without hooks (traditional approach):**
```dart
class LoginPage extends ConsumerStatefulWidget {
  @override
  State createState() => _LoginPageState();
}
class _LoginPageState extends ConsumerState<LoginPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();  // ← MUST remember to dispose
    super.dispose();
  }
}
```

**With hooks:**
```dart
final scrollController = useScrollController();  // ← 1 line, auto-dispose
```

→ `useScrollController()` wraps `ScrollController`: create on mount, dispose on unmount. Không cần `StatefulWidget`, không quên `dispose()`.

---

## 3. use_back_blocker.dart — Custom Hook: PopScope Integration

<!-- AI_VERIFY: base_flutter/lib/common/hook/use_back_blocker.dart -->
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../index.dart';

/// Result of [useBackBlocker] hook.
typedef BackBlockerResult = ({
  bool isAllowed,
  void Function(VoidCallback? action) handleNavigation,
});

BackBlockerResult useBackBlocker(AppNavigator nav) {
  final isAllowedToPop = useState(false);

  void handleNavigation(VoidCallback? action) {
    isAllowedToPop.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (action != null) {
        action();
      } else {
        nav.pop();
      }
    });
  }

  return (isAllowed: isAllowedToPop.value, handleNavigation: handleNavigation);
}
```
<!-- END_VERIFY -->
→ Source: [use_back_blocker.dart](../../base_flutter/lib/common/hook/use_back_blocker.dart) (83 lines, including docs)

### Breakdown

**Custom hook anatomy — 4 phần:**

| # | Phần | Code | Giải thích |
|---|------|------|-----------|
| 1 | Return type | `typedef BackBlockerResult = ({bool, Function})` | Record type cho structured return |
| 2 | Function signature | `BackBlockerResult useBackBlocker(AppNavigator nav)` | `useXxx` naming convention — bắt buộc |
| 3 | Internal hooks | `useState(false)` | Gọi built-in hooks bên trong custom hook |
| 4 | Return | `(isAllowed: ..., handleNavigation: ...)` | Expose state + actions |

**Flow khi user nhấn Back:**

```
User presses Back
    ↓
PopScope.onPopInvokedWithResult(didPop: false, ...)
    ↓
Show confirm dialog → user chọn "Yes"
    ↓
backBlocker.handleNavigation(null)
    ↓
isAllowedToPop.value = true → widget rebuild
    ↓
PopScope.canPop = true (từ backBlocker.isAllowed)
    ↓
addPostFrameCallback → nav.pop() → page pops
```

**Tại sao `addPostFrameCallback`?**

```dart
void handleNavigation(VoidCallback? action) {
  isAllowedToPop.value = true;                    // ← triggers rebuild
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // ← runs AFTER rebuild completes (next frame)
    // ← PopScope.canPop is now `true`
    if (action != null) {
      action();
    } else {
      nav.pop();                                   // ← pop succeeds because canPop=true
    }
  });
}
```

1. `isAllowedToPop.value = true` → `PopScope.canPop` becomes `true` nhưng **chưa applied** (rebuild pending)
2. `addPostFrameCallback` → schedule action **sau rebuild** → Flutter renders frame với `canPop: true`
3. Frame kế tiếp → `nav.pop()` → `PopScope` allows pop → page navigates away

Nếu gọi `nav.pop()` ngay (không `addPostFrameCallback`) → `PopScope` vẫn `canPop: false` → pop bị block → **navigation fail**.

**Usage example từ doc:**

```dart
class MyPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(appNavigatorProvider);
    final backBlocker = useBackBlocker(nav);

    return PopScope(
      canPop: backBlocker.isAllowed,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await showConfirmDialog(
          context: context,
          message: 'Leave without saving?',
        );
        if (confirmed) {
          backBlocker.handleNavigation(null);
        }
      },
      child: Scaffold(...),
    );
  }
}
```

> 💡 **FE Perspective**
> **Flutter:** `useBackBlocker` custom hook kết hợp `useState` + `PopScope` widget để chặn back navigation pending user confirmation.
> **React/Vue tương đương:** React Router v6 `useBlocker()` / `usePrompt()`. Vue Router: `onBeforeRouteLeave()` guard.
> **Khác biệt quan trọng:** Flutter dùng `PopScope` widget (declarative trong widget tree); React/Vue dùng router guard (imperative callback registration).

---

## 4. use_focus_node_refocus_on_resume.dart — Lifecycle-Aware Custom Hook

<!-- AI_VERIFY: base_flutter/lib/common/hook/use_focus_node_refocus_on_resume.dart -->
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../index.dart';

FocusNode useFocusNodeRefocusOnResume(BuildContext context) {
  final focusNode = useFocusNode();
  final controller = useRef(RefocusOnResumeController()).value;

  useOnAppLifecycleStateChange((previous, current) {
    if (context.mounted) {
      controller.handleLifecycleStateChange(
        state: current,
        context: context,
        node: focusNode,
      );
    }
  });

  return focusNode;
}
```
<!-- END_VERIFY -->
→ Source: [use_focus_node_refocus_on_resume.dart](../../base_flutter/lib/common/hook/use_focus_node_refocus_on_resume.dart) (26 lines)

### Breakdown

**Hook composition — 3 built-in hooks orchestrated:**

```
useFocusNodeRefocusOnResume(context)
  ├── useFocusNode()                           ← [1] auto-managed FocusNode
  ├── useRef(RefocusOnResumeController())      ← [2] persistent reference (không trigger rebuild)
  └── useOnAppLifecycleStateChange(callback)   ← [3] app lifecycle listener
```

| Hook | Vai trò | Auto-dispose? |
|------|---------|---------------|
| `useFocusNode()` | Tạo + dispose FocusNode | ✅ Yes |
| `useRef(controller)` | Giữ controller reference persistent across rebuilds | — (no dispose needed) |
| `useOnAppLifecycleStateChange` | Listen `AppLifecycleState` changes | ✅ Yes (removes observer) |

**`useRef` vs `useState`:**

```
useRef(value)     → ObjectRef<T>
  .value          ← persistent reference
  .value = x      ← does NOT trigger rebuild
                  ← use for mutable data that shouldn't cause re-render

useState(value)   → ValueNotifier<T>
  .value          ← current state
  .value = x      ← TRIGGERS rebuild
                  ← use for UI-reactive state
```

→ `useRef(RefocusOnResumeController())` — controller **không cần gây rebuild** khi internal state thay đổi. Chỉ cần persist reference.

**RefocusOnResumeController logic (tham khảo):**

<!-- AI_VERIFY: base_flutter/lib/common/controller/refocus_on_resume_controller.dart -->
```dart
void handleLifecycleStateChange({
  required AppLifecycleState state,
  required BuildContext context,
  required FocusNode node,
}) {
  switch (state) {
    case AppLifecycleState.inactive:
    case AppLifecycleState.paused:
      handleGoingBackground(node);        // ← save focus state
      break;
    case AppLifecycleState.resumed:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          handleResumed(                   // ← restore focus after delay
            context: context,
            node: node,
          );
        }
      });
      break;
    default:
      break;
  }
}
```
<!-- END_VERIFY -->
→ Source: [refocus_on_resume_controller.dart](../../base_flutter/lib/common/controller/refocus_on_resume_controller.dart) (line 61–81)

**Real-world scenario:** iOS swipe-between-apps → app goes to background → keyboard dismissed → app resumes → focus **lost** → user phải tap lại vào text field. Hook này tự refocus.

**Timeline:**

```
App Active (keyboard visible, text field focused)
    ↓ user swipes to app switcher
AppLifecycleState.inactive → paused
    ↓ controller saves: _lastPrimaryFocusBeforePause = node
App in Background (keyboard dismissed by OS)
    ↓ user returns to app
AppLifecycleState.resumed
    ↓ addPostFrameCallback → 50ms delay → node.requestFocus()
App Active (keyboard restored automatically)
```

> 💡 **FE Perspective**
> **Flutter:** `useFocusNodeRefocusOnResume` compose 3 hooks (`useFocusNode` + `useRef` + `useOnAppLifecycleStateChange`) để auto-refocus text field khi app resume từ background.
> **React/Vue tương đương:** React Native: `AppState.addEventListener('change', handler)` + custom hook `useAppStateFocusRestore(inputRef)`. Vue: không có direct equivalent.
> **Khác biệt quan trọng:** Mobile apps mất focus khi vào background — cần explicit refocus. Web apps không có vấn đề này (browser giữ focus khi switch tab).

---

## 5. Hook Composition Pattern — Summary

Từ 2 custom hooks trên, pattern chung:

```dart
// Custom hook template
ReturnType useXxxYyy(/* dependencies */) {
  // 1. Call built-in hooks (useState, useEffect, useFocusNode, useRef, ...)
  final state = useState(initialValue);
  final controller = useRef(MyController()).value;

  // 2. Wire hooks together (useEffect for side effects, lifecycle, etc.)
  useEffect(() {
    // setup
    return () { /* cleanup */ };
  }, [/* deps */]);

  // 3. Return composed result
  return (state: state.value, action: doSomething);
}
```

**Codebase hook inventory:**

| Hook file | Type | Built-in hooks used | Purpose |
|-----------|------|---------------------|---------|
| `use_back_blocker.dart` | Custom | `useState` | Block/allow back navigation |
| `use_focus_node_refocus_on_resume.dart` | Custom | `useFocusNode`, `useRef`, `useOnAppLifecycleStateChange` | Auto-refocus on app resume |
| Pages (`splash_page.dart`, etc.) | Inline | `useEffect`, `useScrollController`, `useState` | Init, scroll, local state |

**Hook directory structure:**

```
lib/common/hook/
  ├── use_back_blocker.dart                    ← custom hook (83 lines)
  └── use_focus_node_refocus_on_resume.dart    ← custom hook (26 lines)
```

→ Custom hooks live in `lib/common/hook/` — shared across pages. Inline hook calls live directly trong `buildPage()`.

---

## ⏭️ Next Steps

Concepts rút ra từ code walk → [02-concept.md](./02-concept.md)

Tóm tắt concepts sẽ cover:
1. flutter_hooks & HookConsumerWidget
2. Built-in hooks (useState, useEffect, useScrollController, useFocusNode, useRef)
3. useEffect lifecycle (mount/dispose, keys, cleanup)
4. Custom hook pattern (extract `useXxx()`)
5. useBackBlocker (PopScope integration)
6. useFocusNodeRefocusOnResume (lifecycle + controller)
7. Hook rules & limitations

Forward ref: [Module 15 — Capstone Login](../module-15-capstone-login/) sẽ combine hooks + state + navigation trong real login flow với `useBackBlocker`.

<!-- AI_VERIFY: generation-complete -->
