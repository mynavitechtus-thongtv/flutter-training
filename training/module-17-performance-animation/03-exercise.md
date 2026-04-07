# Exercises — Performance, DevTools & Animation

> 📌 **Trước khi bắt đầu:** Đọc [01-code-walk](./01-code-walk.md) và [02-concept](./02-concept.md). Mỗi exercise build trên concepts đã cover.

---

## Exercise 1 ⭐ — DevTools Profiling Walkthrough

### Mục tiêu

Sử dụng Flutter DevTools để profile shimmer animation, đọc Performance Overlay, và identify rebuild patterns.

### Acceptance Criteria

- [ ] Run app debug mode, mở Flutter DevTools
- [ ] Enable Performance Overlay, navigate đến shimmer screen, chụp screenshot
- [ ] Flutter Inspector: tìm widget tree path cho `Shimmer` → `ShimmerLoading` → `ShaderMask`
- [ ] Timeline: record 3-5s shimmer, identify frame nào > 16ms
- [ ] Memory tab: heap snapshot trước/sau load `CommonImage.network(enableCache: true)`, ghi nhận memory delta
- [ ] Deliverable: file `docs/m17-devtools-report.md` với screenshots + analysis

<details>
<summary>🏗️ Architecture Hint</summary>

- Mở DevTools: `Dart: Open DevTools` trong VS Code
- Performance Overlay: `showPerformanceOverlay: true` trong `MaterialApp`
- Memory tab: "Take Heap Snapshot" button

</details>

---

## Exercise 2 ⭐⭐ — Optimize Provider Rebuilds

### Mục tiêu

Refactor một page để dùng `Consumer` + `select()` pattern, đo rebuild count trước/sau.

### Acceptance Criteria

- [ ] Chọn target page dùng `ref.watch(provider)` broad (hoặc tạo demo page)
- [ ] Đo baseline rebuild count với `debugPrint`
- [ ] Refactor: wrap từng section trong `Consumer` + `ref.watch(provider.select(...))`
- [ ] Đo after: rebuild count giảm đáng kể
- [ ] Verify với `AppProviderObserver` log
- [ ] Deliverable: refactored code + log comparison before/after + giải thích tại sao `select()` giảm rebuild

<details>
<summary>🏗️ Architecture Hint</summary>

- Tham khảo pattern trong `login_page.dart`: `ref.watch(provider.select((value) => value.data.fieldName))`
- Thêm `debugPrint('🔄 build()')` vào `build()` để đếm rebuilds
- Mỗi `Consumer` chỉ watch field cần thiết, không watch toàn bộ state

</details>

---

## Exercise 3 ⭐⭐ — Shimmer Variant: Pulse Effect

### Mục tiêu

Tạo shimmer variant mới dùng **opacity pulse** thay vì sliding gradient.

### Acceptance Criteria

- [ ] File: `lib/ui/component/shimmer/pulse_shimmer.dart`
- [ ] `PulseShimmer`: `StatefulWidget` + `SingleTickerProviderStateMixin`
- [ ] `AnimationController` bounded [0.3, 1.0], `repeat(reverse: true)`
- [ ] `PulseShimmerLoading`: dùng `FadeTransition` hoặc `AnimatedOpacity` (không `ShaderMask`)
- [ ] `const` constructor cho cả widget mới
- [ ] Hoạt động với existing shapes: `CircleShimmer`, `RoundedRectangleShimmer`
- [ ] `dispose()` AnimationController đúng cách

<details>
<summary>🏗️ Architecture Hint</summary>

- Follow `shimmer.dart` architecture pattern
- `AnimationController(duration: Duration(milliseconds: 800), vsync: this)`
- `..repeat(reverse: true)` — oscillate thay vì loop
- `FadeTransition(opacity: animation, child: child)` — GPU-level animation
- Expose `Animation<double>` cho descendants qua `InheritedWidget` hoặc constructor param

</details>

<details>
<summary>💡 Gợi ý chi tiết (mở khi stuck > 15 phút)</summary>

- `PulseShimmer` tương tự `Shimmer` — wrap children, cung cấp animation
- `PulseShimmerLoading` tương tự `ShimmerLoading` — thay `ShaderMask` bằng `FadeTransition`
- Child widget opacity cycle 0.3 → 1.0 → 0.3 tự động
- Flutter cần `SingleTickerProviderStateMixin` + `dispose()`. CSS animation tự quản lý lifecycle.

</details>

---

## Exercise 4 ⭐⭐⭐ — AI Dojo: Performance Audit Tool

### Mục tiêu

Prompt AI tạo `PerformanceAuditWidget` wrap bất kỳ subtree nào để đo rebuild count + build time.

### Acceptance Criteria

- [ ] Prompt AI với context: Flutter performance monitoring, widget rebuild tracking
- [ ] AI output: `PerformanceAuditWidget` đếm rebuild + `Stopwatch` timing
- [ ] `kDebugMode` guard — zero production overhead
- [ ] Debug overlay hiện stats ở corner, không block interaction
- [ ] Review AI output: correctness, accuracy, safety, UX
- [ ] Viết note: AI generate đúng/sai gì, cần sửa gì

<details>
<summary>🏗️ Architecture Hint</summary>

- Input: bất kỳ child widget
- Output: debug overlay hiện rebuild count + average build time
- Constraints: chỉ active trong `kDebugMode`, dùng `Stopwatch` cho timing
- Structure: `StatefulWidget` với `label`, `child`, `showOverlay` params

</details>

---

## Exercise 5 ⭐ — Animated Card Expansion (Implicit Animation)

### Mục tiêu

Sử dụng `AnimatedContainer` để tạo card expand/collapse animation — áp dụng implicit animation concept (Concept 7).

### Acceptance Criteria

- [ ] Card expand khi tap, collapse khi tap lại (toggle)
- [ ] Animation duration = 300ms, curve = `Curves.easeInOut`
- [ ] Dùng `AnimatedContainer` (KHÔNG dùng `AnimationController`)
- [ ] Height thay đổi từ 80 → 200 khi expand
- [ ] Card hiển thị title (luôn visible) + detail text (chỉ visible khi expanded)
- [ ] Có `const` constructor cho widget

<details>
<summary>🏗️ Architecture Hint</summary>

- `bool _isExpanded = false` state (dùng `useState` hook hoặc `StatefulWidget`)
- `AnimatedContainer(height: _isExpanded ? 200 : 80, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)`
- Wrap trong `GestureDetector` hoặc `InkWell` cho tap handling
- Dùng `AnimatedCrossFade` hoặc `Visibility` cho detail text appearance
- Tham khảo [02-concept.md § Implicit Animations](./02-concept.md) cho giải thích `AnimatedContainer`

</details>

---

> ➡️ Sau khi hoàn thành, chạy verification checklist tại [04-verify.md](./04-verify.md).

<!-- AI_VERIFY: generation-complete -->
