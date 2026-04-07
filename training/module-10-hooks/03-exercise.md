# Exercises — Thực hành Hooks & Custom Hooks

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 7](../module-07-base-viewmodel/) (BasePage lifecycle), [Module 8](../module-08-riverpod-state/) (Riverpod state), [Module 9](../module-09-page-structure/) (page anatomy), đọc xong [01-code-walk.md](./01-code-walk.md) và [02-concept.md](./02-concept.md).

---

## ⭐ Exercise 1: Identify & Classify Hooks trong Codebase

**Mục tiêu:** Scan toàn bộ page files — liệt kê mọi hook call, phân loại built-in vs custom, xác nhận hook rules compliance.

### Hướng dẫn

1. Mở các files sau:
   - [base_page.dart](../../base_flutter/lib/ui/base/base_page.dart)
   - [splash_page.dart](../../base_flutter/lib/ui/page/splash/splash_page.dart)
   - [login_page.dart](../../base_flutter/lib/ui/page/login/login_page.dart)
   - [main_page.dart](../../base_flutter/lib/ui/page/main/main_page.dart)

2. Điền bảng inventory:

### Template

| # | File | Hook call | Hook type | Return type | Purpose | Auto-dispose? |
|---|------|-----------|-----------|-------------|---------|---------------|
| 1 | base_page.dart | `useState<OverlayEntry?>(null)` | built-in | `ValueNotifier<OverlayEntry?>` | Loading overlay state | ? |
| 2 | splash_page.dart | `useEffect(() => ..., [])` | built-in | `void` | Init on mount | ? |
| 3 | login_page.dart | ? | ? | ? | ? | ? |
| 4 | main_page.dart | ? | ? | ? | ? | ? |
| ... | | | | | | |

3. Kiểm tra hook rules compliance cho mỗi file:
   - [ ] Tất cả hooks gọi trực tiếp trong `build()` / `buildPage()` (Rule 1)?
   - [ ] Hooks gọi theo thứ tự cố định, không conditional (Rule 2)?
   - [ ] Không có hooks trong loops (Rule 3)?

### Câu hỏi suy nghĩ

- `base_page.dart` gọi `useState` ở `build()` (không phải `buildPage()`). Khi subclass override `buildPage()` và thêm hooks, thứ tự hooks có ổn không? Tại sao?
- Nếu thêm `useScrollController()` vào `splash_page.dart` **sau** `useEffect` → thứ tự hooks thay đổi so với lần build trước? (Hint: splash_page chưa từng có scroll controller trước đó)

### ✅ Checklist hoàn thành
- [ ] Inventory ≥ 5 hook calls across 4 files
- [ ] Xác nhận loại (built-in / custom) cho mỗi hook
- [ ] Verify Rule 1, 2, 3 compliance
- [ ] Trả lời 2 câu hỏi

---

## ⭐ Exercise 2: useEffect Cleanup — Stream Subscription

**Mục tiêu:** Viết `useEffect` với proper cleanup function — hiểu lifecycle cleanup flow.

### Hướng dẫn

**Scenario:** Bạn cần listen `connectivity` stream (giả lập) trong một page — khi connectivity status thay đổi, update UI. Khi page unmount, phải cancel subscription.

**Step 1:** Trong bất kỳ page file (hoặc tạo scratch file), viết:

```dart
@override
Widget buildPage(BuildContext context, WidgetRef ref) {
  final isOnline = useState(true);

  useEffect(() {
    // TODO: Subscribe to connectivity stream
    // TODO: Update isOnline.value based on stream events
    // TODO: Return cleanup function that cancels subscription

    return null;  // ← FIX THIS: return proper cleanup
  }, []);

  return CommonScaffold(
    body: Center(
      child: Text(isOnline.value ? 'Online ✅' : 'Offline ❌'),
    ),
  );
}
```

**Step 2:** Implement with proper cleanup:

```dart
useEffect(() {
  final subscription = connectivityStream.listen((status) {
    isOnline.value = status == ConnectivityStatus.online;
  });

  return () {
    subscription.cancel();  // ← cleanup khi unmount hoặc deps change
  };
}, []);
```

**Step 3:** Trace lifecycle — điền thứ tự:

| # | Event | Action |
|---|-------|--------|
| 1 | Page mount | ? |
| 2 | `useEffect` callback runs | ? |
| 3 | Stream emits `offline` | ? |
| 4 | Widget rebuild (isOnline → false) | ? |
| 5 | User navigates away (page unmount) | ? |
| 6 | Cleanup runs | ? |

**Step 4:** Thay `[]` → `[userId]` (dependency). Trace lại: khi `userId` changes → cleanup cũ chạy trước hay effect mới chạy trước?

### Câu hỏi suy nghĩ

- Nếu quên `return () { subscription.cancel(); }` → điều gì xảy ra sau khi navigate away?
- `return null` vs `return () {}` — trong trường hợp nào dùng `null` ổn? (Hint: khi không có resource cần release)
- Nếu `useEffect` callback throws exception → cleanup function có chạy khi unmount không?

### ✅ Checklist hoàn thành
- [ ] `useEffect` có proper cleanup function (return `() { sub.cancel(); }`)
- [ ] Điền đúng lifecycle sequence (6 steps)
- [ ] Trace lại với `[userId]` dependency
- [ ] Trả lời 3 câu hỏi
- [ ] **Revert changes** sau khi hoàn thành

---

## ⭐⭐ Exercise 2b — Extract `usePageInit` Custom Hook

> **Mục tiêu**: Thực hành tạo custom hook đơn giản bằng cách extract pattern lặp trong codebase

### Bối cảnh

Trong `base_flutter`, nhiều page dùng cùng pattern khởi tạo:

```dart
useEffect(() {
  Future.microtask(() => ref.read(viewModelProvider.notifier).init());
  return null;
}, []);
```

Pattern này lặp lại ở `splash_page.dart`, `main_page.dart`, và sẽ lặp ở mọi page mới. Đây là cơ hội extract thành custom hook.

### Yêu cầu

1. Tạo file `lib/ui/hook/use_page_init.dart`
2. Implement custom hook `usePageInit`:
   ```dart
   void usePageInit(VoidCallback onInit) {
     useEffect(() {
       Future.microtask(onInit);
       return null;
     }, []);
   }
   ```
3. Verify hook hoạt động bằng cách mentally trace: gọi `usePageInit(() => ref.read(provider.notifier).init())` trong 1 page

### Tiêu chí hoàn thành
- [ ] File `use_page_init.dart` tạo đúng vị trí
- [ ] Hook sử dụng `useEffect` + `Future.microtask` pattern
- [ ] Hiểu tại sao cần `Future.microtask` (tránh gọi init() trong build phase)

### 🧹 Clean up
Revert — xóa file `use_page_init.dart` nếu không merge, chạy `make ep` để update barrel.

---

## ⭐⭐ Exercise 3: Custom Hook — useDebounce

**Mục tiêu:** Viết custom hook `useDebounce<T>` — debounce value thay đổi nhanh (search input). Apply hook rules, proper cleanup.

### Hướng dẫn

**Scenario:** Login page có search/filter field — user type nhanh → không muốn trigger API call mỗi keystroke. Cần debounce 300ms.

**Step 1:** Tạo file `lib/common/hook/use_debounce.dart`:

```dart
import 'dart:async';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Debounces a value — returns the debounced value after [delay].
///
/// Usage:
/// ```dart
/// final searchText = useState('');
/// final debouncedSearch = useDebounce(searchText.value, duration: Duration(milliseconds: 300));
///
/// useEffect(() {
///   if (debouncedSearch.isNotEmpty) {
///     ref.read(provider.notifier).search(debouncedSearch);
///   }
///   return null;
/// }, [debouncedSearch]);
/// ```
T useDebounce<T>(T value, {required Duration duration}) {
  // TODO: implement
  // Hints:
  // 1. useState<T>(value) — hold debounced state
  // 2. useEffect — setup Timer on value change, cancel previous timer
  // 3. Return debounced state value
}
```

**Step 2:** Implement the hook. Key requirements:
- `useState<T>(value)` cho debounced value
- `useEffect` với `[value, duration]` dependencies
- **Cleanup:** cancel `Timer` khi value changes lại hoặc unmount
- Return `debouncedState.value`

**Step 3:** Verify implementation checklist:

| Requirement | Check |
|-------------|-------|
| Uses `useState<T>` for debounced value | ? |
| Uses `useEffect` with `[value, duration]` keys | ? |
| Creates `Timer` inside effect | ? |
| Cleanup cancels timer (`return () => timer.cancel()`) | ? |
| Returns `T` (not `ValueNotifier<T>`) | ? |
| No hook violations (no conditionals, no loops) | ? |

**Step 4:** Write usage example — integrate with a text field:

```dart
@override
Widget buildPage(BuildContext context, WidgetRef ref) {
  final searchText = useState('');
  final debouncedSearch = useDebounce(searchText.value, duration: const Duration(milliseconds: 300));

  useEffect(() {
    if (debouncedSearch.isNotEmpty) {
      ref.read(provider.notifier).search(debouncedSearch);
    }
    return null;
  }, [debouncedSearch]);

  return PrimaryTextField(
    hintText: 'Search...',
    onChanged: (text) => searchText.value = text,
  );
}
```

### Câu hỏi suy nghĩ

- Tại sao `duration` nằm trong dependency keys? Khi nào `duration` thay đổi runtime?
- Nếu user type "abc" rồi clear thành "" trong vòng 300ms → `debouncedSearch` value cuối cùng là gì?
- `useDebounce` có thể dùng cho non-String types không? (Hint: generic `T`)
- So sánh: React `useDebounce` implementation khác Flutter version thế nào?

### ✅ Checklist hoàn thành
- [ ] `useDebounce<T>` compile thành công
- [ ] Proper cleanup (Timer cancel trong return function)
- [ ] Hook rules compliant (no conditionals, consistent order)
- [ ] Usage example wired vào text field
- [ ] Trả lời 4 câu hỏi
- [ ] **Revert changes** sau khi hoàn thành (hoặc keep nếu useful)

---

## ⭐⭐⭐ Exercise 4: AI Dojo — 🔧 Refactor Challenge

### 🤖 AI Dojo — StatefulWidget → Hooks Conversion

**Mục tiêu**: Cho AI một StatefulWidget → yêu cầu convert sang hooks → so sánh hai approaches.

**Bước thực hiện**:

1. Viết (hoặc copy) một StatefulWidget đơn giản có: `TextEditingController` + `dispose()`, `ScrollController` + listener + `dispose()`, `initState` gọi API, `setState` cho local loading state.

2. Gửi prompt sau cho AI:

```
Convert StatefulWidget này sang Flutter Hooks (HookConsumerWidget).

Requirements:
- Dùng useTextEditingController, useScrollController, useState, useEffect
- Cleanup phải tương đương dispose() của StatefulWidget
- Giữ nguyên behavior: init load + scroll listener + loading state

class ProfileEditPage extends StatefulWidget { ... }
class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nameController;
  late final ScrollController _scrollController;
  bool _isLoading = false;

  @override void initState() {
    super.initState();
    _nameController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadProfile();
  }

  @override void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() { /* pagination logic */ }
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    /* API call */
    setState(() => _isLoading = false);
  }
  @override Widget build(BuildContext context) { /* ... */ }
}
```

3. So sánh hai versions:
   - Lines of code: StatefulWidget vs Hooks — giảm bao nhiêu %?
   - Cleanup: explicit `dispose()` vs automatic hook cleanup — cái nào dễ quên bug hơn?
   - Readability: team member chưa biết hooks đọc version nào dễ hơn?

**✅ Tiêu chí đánh giá**:
- [ ] AI convert thành công — hooks version compile-ready (hoặc gần compile-ready)
- [ ] AI dùng đúng hooks: `useTextEditingController()`, `useScrollController()`, `useState()`, `useEffect()`
- [ ] Bạn so sánh 3 khía cạnh (LOC, cleanup safety, readability) với nhận xét cụ thể
- [ ] Bạn kết luận: khi nào hooks tốt hơn, khi nào StatefulWidget vẫn ổn

---

## 📊 Exercise Summary

| # | Exercise | Difficulty | Concept practiced | Time est. |
|---|----------|-----------|-------------------|-----------|
| 1 | Identify & Classify Hooks | ⭐ | Built-in hooks, hook rules | 15 min |
| 2 | useEffect Cleanup | ⭐ | useEffect lifecycle, cleanup | 20 min |
| 3 | Custom useDebounce Hook | ⭐⭐ | Custom hook pattern, useState, useEffect, Timer | 30 min |
| 4 | AI Dojo — Refactor Challenge | ⭐⭐⭐ | StatefulWidget → Hooks conversion | 25 min |

---

## ⏭️ Next Steps

Kiểm tra kết quả → [04-verify.md](./04-verify.md)

<!-- AI_VERIFY: generation-complete -->
