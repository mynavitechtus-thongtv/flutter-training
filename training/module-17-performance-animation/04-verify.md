# Verification — Kiểm tra kết quả Module 17

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được 3 trees (Widget → Element → RenderObject) và vai trò từng layer trong rendering pipeline? | Rendering Pipeline | 🔴 |
| 2 | Tôi phân biệt được const widget reuse vs normal widget rebuild — tại sao `const` skip entire subtree? | Rendering Pipeline | 🔴 |
| 3 | Tôi mô tả được AnimationController + Ticker lifecycle — unbounded vs bounded, auto-pause khi offscreen, dispose pattern? | AnimationController | 🟡 |
| 4 | Tôi biết 4 tab chính của Flutter DevTools (Inspector, Performance Overlay, Timeline, Memory) và use case từng tab? | DevTools | 🟡 |
| 5 | Tôi giải thích được 3-tier image caching (memory → disk → network) và `memCacheWidth` optimization? | Image Caching | 🔴 |
| 6 | Tôi hiểu Consumer + `select()` giảm rebuild scope — mỗi Consumer là independent rebuild boundary? | Provider Performance | 🔴 |
| 7 | Tôi phân biệt được paint-level animation (ShaderMask — chỉ repaint) vs widget-level animation (setState — rebuild tree)? | ShaderMask & GPU | 🟡 |
| 8 | Tôi biết dùng AppProviderObserver để detect unnecessary provider rebuild? | Provider Performance | 🟡 |
| 9 | Tôi phân biệt được implicit animation (AnimatedContainer, AnimatedOpacity) vs explicit animation (AnimationController)? | Implicit Animations | 🟡 |

**Target:** 6/6 Yes cho 🔴 MUST-KNOW, tối thiểu 7/9 tổng.

---

## 2. Exercise Verification

### Exercise 1 — DevTools Profiling Report ⭐

- [ ] Mở app bằng `flutter run --profile` và launch DevTools
- [ ] Capture ≥ 3 screenshots (Inspector, Performance Overlay, Timeline)
- [ ] Phân tích ≥ 1 performance bottleneck (UI thread > 16ms hoặc unnecessary rebuild)
- [ ] Report saved tại `docs/m17-devtools-report.md`

### Exercise 2 — Provider Rebuild Optimization ⭐⭐

- [ ] Trước refactor: đếm rebuild count bằng `AppProviderObserver` log
- [ ] Áp dụng `select()` và/hoặc `Consumer` wrapper
- [ ] Sau refactor: rebuild count giảm rõ rệt (ghi số cụ thể)
- [ ] Code diff cho thấy chỉ thêm `select()` / `Consumer`, không thay đổi logic

### Exercise 3 — PulseShimmer Variant ⭐⭐

- [ ] `PulseShimmer` dùng `AnimationController` bounded [0.3, 1.0] với `repeat(reverse: true)`
- [ ] Animation mượt — không bị jank khi scroll
- [ ] `dispose()` gọi `_controller.dispose()` — không memory leak
- [ ] Reuse `Shimmer` ancestor pattern hoặc tự tạo controller mới

### Exercise 4 — PerformanceAuditWidget ⭐⭐⭐

- [ ] Widget hiển thị rebuild count + average build time
- [ ] Dùng `debugPrint` hoặc overlay hiển thị real-time
- [ ] Wrap bất kỳ widget nào để đo — reusable pattern
- [ ] Không ảnh hưởng production build (gated bởi `kDebugMode` hoặc `Config` flag)

---

## 3. Quick Quiz

<details>
<summary>Q1: Khi gọi <code>setState()</code>, cả 3 trees đều rebuild từ đầu — đúng hay sai?</summary>

**Sai.** Chỉ **Widget tree** rebuild (tạo object mới). **Element tree** chạy diff algorithm (`canUpdate`) để quyết định reuse hay recreate — tương tự React reconciler. **RenderObject tree** chỉ repaint nếu layout thực sự thay đổi (`markNeedsPaint` / `markNeedsLayout`). Đây là lý do Flutter vẫn nhanh dù rebuild Widget tree thường xuyên.
</details>

<details>
<summary>Q2: Tại sao <code>shimmer.dart</code> dùng <code>AnimationController.unbounded</code> thay vì bounded mặc định?</summary>

Shimmer cần gradient chạy "ngoài" widget bounds (min: -0.5, max: 1.5) để hiệu ứng tự nhiên — gradient bắt đầu từ ngoài bên trái và kết thúc ngoài bên phải. Bounded controller mặc định clamp giá trị trong [0.0, 1.0], sẽ làm gradient bị cắt đột ngột tại edges. Thêm nữa, `SingleTickerProviderStateMixin` tự động pause ticker khi widget offscreen → tiết kiệm CPU/battery.
</details>

<details>
<summary>Q3: <code>ref.watch(provider)</code> vs <code>ref.watch(provider.select((s) => s.data.onPageError))</code> — khác biệt gì về performance?</summary>

`ref.watch(provider)` rebuild widget khi **bất kỳ field nào** trong state thay đổi (kể cả không liên quan). `ref.watch(provider.select(...))` chỉ rebuild khi giá trị **selected** thay đổi. Ví dụ: `isLoading` thay đổi nhưng `onPageError` giữ nguyên → widget dùng `select((s) => s.data.onPageError)` sẽ **KHÔNG** rebuild. Kết hợp với `Consumer` widget để mỗi phần UI có rebuild scope riêng — đây là optimization pattern quan trọng nhất cho Riverpod.
</details>

<details>
<summary>Q4: Performance Overlay hiện thanh đỏ vượt 16ms ở UI thread — nguyên nhân phổ biến nhất là gì?</summary>

Nguyên nhân phổ biến: **(1)** Quá nhiều widget rebuild trong `build()` — thiếu `const`, thiếu `select()`, rebuild scope quá rộng. **(2)** Expensive computation trong `build()` — nên move sang `initState` hoặc cache. **(3)** Deep widget tree rebuild — dùng `Consumer` tạo rebuild boundary. Dùng DevTools **Timeline** tab để identify chính xác frame nào bị jank và call stack gây ra.
</details>

<details>
<summary>Q5: <code>CachedNetworkImage</code> dùng <code>memCacheWidth</code> để làm gì? Không set thì sao?</summary>

`memCacheWidth` resize ảnh **trong memory cache** theo kích thước hiển thị thực tế (width × devicePixelRatio). Ví dụ: ảnh gốc 2000×2000px, widget hiển thị 200×200 logical, device 3x → cache 600×600. Tiết kiệm ~90% memory. Nếu không set, ảnh gốc full resolution giữ trong memory → image cache bloat → potential OOM crash trên device có RAM thấp.
</details>

---

## 4. FE Perspective Mapping

| Flutter | FE Equivalent |
|---------|---------------|
| AnimationController | GSAP Timeline / requestAnimationFrame |
| ShaderMask | CSS mask-image + GPU compositing |
| const widget | (no direct React equivalent — React always re-creates) |
| CachedNetworkImage | Service Worker Cache API |
| Consumer + select() | React.memo + useSelector |
| DevTools | Chrome DevTools + React Profiler |
| Performance Overlay | Lighthouse real-time |
| Flutter 3 trees | React Virtual DOM → Real DOM (but 3 layers vs 2) |
| Implicit Animations | CSS `transition: all 300ms ease` |

---

## 5. Backward Reference Check

- [ ] M7: BasePage lifecycle — dispose pattern cho AnimationController tương tự
- [ ] M8: Provider rebuild — select() và Consumer đã giới thiệu, M17 deep-dive performance
- [ ] M9: Shimmer component — M17 phân tích animation architecture bên trong

## 6. Forward Reference

- [ ] M18 preview: hiểu rằng performance metrics có thể đo automated trong tests

---

## ✅ Module Complete

Hoàn thành khi:

- [ ] Self-assessment: ≥ 7/9 Yes (6/6 🔴 bắt buộc)
- [ ] Exercise 1 + 2 hoàn thành
- [ ] Quick Quiz trả lời đúng ≥ 3/5

```
Ngày hoàn thành: _______________
Reviewer: _______________
Notes: _______________
```

---

## ➡️ Next Module

Hoàn thành Module 17! Bạn đã nắm vững performance optimization, animation.

→ Tiến sang **[Module 18 — Testing](../module-18-testing/)** để học unit testing, widget testing, integration testing.

<!-- AI_VERIFY: generation-complete -->
