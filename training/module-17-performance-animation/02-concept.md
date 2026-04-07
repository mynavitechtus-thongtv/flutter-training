# Concepts — Performance, DevTools & Animation

> 📌 **Module context:** Module này survey 8 concepts chính về performance & animation trong Flutter, mapping từ code đã đọc ở [01-code-walk](./01-code-walk.md). Mỗi concept kèm FE bridge cho dev có background React/CSS.

---

## Concept 1: Flutter Rendering Pipeline — 3 Trees 🔴 MUST-KNOW

**WHY:** 3 Trees là fundamental — debug performance issues bắt buộc hiểu Widget/Element/RenderObject lifecycle.

### Widget Tree → Element Tree → RenderObject Tree

```
Widget Tree          Element Tree          RenderObject Tree
(Blueprint)          (Lifecycle)           (Layout & Paint)
─────────────        ─────────────         ─────────────
 Shimmer              ShimmerElement        RenderShimmer
   └── ShimmerLoading    └── ShimmerLoadingEl  └── RenderShaderMask
         └── CircleShimmer     └── CircleEl         └── RenderContainer
```

**Widget** = immutable config object. Rebuilt mỗi frame nếu parent gọi `setState()`.
**Element** = persistent instance quản lý lifecycle. Giữ reference tới Widget và RenderObject. Framework dùng `canUpdate(oldWidget, newWidget)` để quyết định reuse hay recreate Element.
**RenderObject** = thực hiện layout (`performLayout`) và paint (`paint`). Đây là nơi pixel thực sự được vẽ.

**Key insight:** Khi bạn gọi `setState()`, chỉ **Widget tree** rebuild. Element tree chạy diff algorithm (tương tự React reconciler), RenderObject tree chỉ repaint nếu layout thay đổi.

> 💡 **FE Perspective**
> **Flutter:** 3 trees: Widget (blueprint) → Element (lifecycle/diff) → RenderObject (layout/paint). `setState()` chỉ rebuild Widget tree.
> **React/Vue tương đương:** React có Virtual DOM → Real DOM (2 layers). Element ≈ Fiber node, RenderObject ≈ DOM node.
> **Khác biệt quan trọng:** RenderObject **trực tiếp paint pixel** — không có browser layout engine trung gian.

### const Widget = Skip Rebuild

```dart
const SizedBox(height: 24)  // Widget instance được canonicalize
```

`const` cho phép Dart compiler tạo **compile-time constant**. Framework detect `identical(oldWidget, newWidget) == true` → **skip entire subtree rebuild**. Không có equivalent trong React (JSX luôn tạo object mới).

---

## Concept 2: AnimationController & Ticker System 🟡 SHOULD-KNOW

**WHY:** Hooks (`useAnimationController`) wrap phần lớn, nhưng cần hiểu Ticker để debug animation jank.

### Ticker → vsync → frame callback

```
Display refresh (60Hz/120Hz)
    ↓
SchedulerBinding.scheduleFrameCallback
    ↓
Ticker.tick() — every frame
    ↓
AnimationController.value updated
    ↓
Listeners notified → setState/repaint
```

**SingleTickerProviderStateMixin** cung cấp `Ticker` gắn vào widget lifecycle:
- Widget visible → ticker active → animation chạy
- Widget offscreen → ticker paused → save CPU/battery
- Widget disposed → ticker cancelled → no leak

Trong codebase, `shimmer.dart` dùng `AnimationController.unbounded` vì value cần vượt ngoài [0, 1]:
```dart
_shimmerController = AnimationController.unbounded(vsync: this)
  ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
```

**unbounded** vs **bounded:** Default controller clamp [lowerBound, upperBound]. Shimmer cần gradient chạy "ngoài" widget bounds để hiệu ứng tự nhiên.

> 💡 **FE Perspective**
> **Flutter:** `AnimationController` + `Ticker` gắn với widget lifecycle — tự pause khi invisible.
> **React/Vue tương đương:** `requestAnimationFrame` ≈ Ticker. GSAP Timeline ≈ AnimationController.
> **Khác biệt quan trọng:** Flutter Ticker tự động pause khi widget invisible. Browser `rAF` vẫn chạy nếu tab active.

---

## Concept 3: ShaderMask & GPU Compositing 🟢 AI-GENERATE

**WHY:** ShaderMask là advanced API, AI gen được — chỉ cần biết API tồn tại để search khi cần.

### Paint Level vs Widget Level

```
Widget-level animation:        Paint-level animation:
setState() → rebuild subtree   Listener → markNeedsPaint
→ new Widget objects           → RenderObject.paint() lại
→ Element diff                 → chỉ GPU compositing
→ RenderObject update          → KHÔNG rebuild widget tree
⚠️ Expensive                   ✅ Cheap (60fps guaranteed)
```

> 📌 `setState()` trigger rebuild cho **chính StatefulWidget đó** và toàn bộ subtree bên dưới nó — **không phải** toàn bộ widget tree. Tuy nhiên, nếu StatefulWidget ở vị trí cao trong tree, subtree rebuild có thể rất lớn → vẫn là performance concern.

`ShimmerLoading` dùng **paint-level approach:**
1. `_onShimmerChange()` → `setState({})` empty body
2. BUT child widget đã build xong → `ShaderMask` chỉ cập nhật shader parameter
3. GPU composite new gradient over existing child → **no widget rebuild**

**ShaderMask mechanism:**
- `shaderCallback` nhận `bounds` (child size) → tạo shader từ gradient
- `blendMode: BlendMode.srcATop` → gradient chỉ affect opaque pixels của child
- Kết quả: child shape giữ nguyên, color "shimmer" chạy qua

> 💡 **FE Perspective**
> **Flutter:** `ShaderMask` hoạt động ở RenderObject level — GPU compositing, không rebuild widget tree.
> **React/Vue tương đương:** CSS `mask-image: linear-gradient(...)` + animation. View Transitions API dùng compositor-level animation.
> **Khác biệt quan trọng:** Flutter animate shader parameter trực tiếp. Browser dùng CSS compositor — cùng hiệu quả nhưng khác API.

---

## Concept 4: Flutter DevTools 🟡 SHOULD-KNOW

**WHY:** DevTools là debugging tool hàng ngày, cần biết cách dùng nhưng UI tự explanatory.

### 4 Tab chính cho Performance

| Tab | Function | Khi nào dùng |
|-----|----------|-------------|
| **Flutter Inspector** | Widget tree browser, layout explorer | Debug layout issues, check widget properties |
| **Performance Overlay** | Real-time FPS, GPU/UI thread | Phát hiện jank (frame > 16ms) |
| **Timeline** | Frame-by-frame analysis | Deep dive vào specific jank frame |
| **Memory** | Heap snapshot, allocation tracking | Detect memory leaks, image cache bloat |

### Performance Overlay — đọc nhanh

```
UI thread:  ████████░░░░░░░░  8ms ✅ (< 16ms budget)
GPU thread: ████████████░░░░  12ms ✅ (< 16ms budget)
```

Nếu bar vượt đường 16ms → **jank** (dropped frame). Thường gặp:
- UI thread spike: quá nhiều widget rebuild, expensive `build()` method
- GPU thread spike: complex shader, overdraw, large image decode

**Enable trong code:**
```dart
MaterialApp(
  showPerformanceOverlay: true,  // hoặc toggle trong DevTools
)
```

### Profiling Workflow — Step-by-step

```
1. flutter run --profile          ← Build profile mode (gần production, có DevTools)
2. Mở DevTools URL từ terminal     ← "Open DevTools" link in console
3. Performance tab → Record         ← Bắt đầu ghi frames
4. Thực hiện action gây jank        ← Scroll list, navigate, animation
5. Stop recording → Timeline view   ← Xem từng frame
6. Tìm frame > 16ms (đỏ)           ← Đây là jank frame
7. Drill down: Build → Layout → Paint  ← Xác định bottleneck phase
```

**Lưu ý:** `--profile` mode **bắt buộc** cho profiling chính xác. Debug mode có overhead lớn (assert checks, debug flags) → kết quả không đáng tin. Release mode không có DevTools → không profile được.

**Quick checks trước khi dùng DevTools:**
```bash
flutter analyze          # Lint warnings có thể ảnh hưởng performance
flutter test             # Đảm bảo code hoạt động đúng trước khi profile
dart format --set-exit-if-changed .  # Code format consistency
```

> 💡 **FE Perspective**
> **Flutter:** DevTools có 4 tab chính: Inspector, Performance Overlay, Timeline, Memory.
> **React/Vue tương đương:** Chrome DevTools Performance tab ≈ Timeline. React Profiler ≈ Inspector + Timeline. Memory tab giống Chrome Memory panel.
> **Khác biệt quan trọng:** Flutter Performance Overlay real-time (UI + GPU thread). Lighthouse là one-shot audit, không real-time.

---

## Concept 5: Image Caching & Network Optimization 🟡 SHOULD-KNOW

**WHY:** Caching strategy varies per project, cần hiểu concept nhưng implementation là config-based.

### 3-Tier Caching Strategy

```
Request image URL
    ↓
[1] Memory cache (HashMap) — instant, ~100 images
    ↓ miss
[2] Disk cache (file system) — fast, configurable size
    ↓ miss
[3] Network request — slow, bandwidth cost
    ↓
Save to disk → save to memory → display
```

`CachedNetworkImage` trong `common_image.dart` implement cả 3 tier. Key optimizations trong codebase:

**Memory-aware sizing:**
```dart
final memCacheWidth = _style.memCacheWidth ??
    (_style.width != null ? maxWidth.times(devicePixelRatio).toInt() : null);
```

Ảnh hiển thị 200x200 logical pixel, device 3x → cache 600x600 pixel. KHÔNG cache full 2000x2000 original → tiết kiệm ~90% memory.

**Fade-in transition:**
```dart
fadeInDuration: const Duration(milliseconds: 500),
fadeInCurve: Curves.easeIn,
```

Không chỉ aesthetic — fade-in mask **image decode latency**. Người dùng thấy transition mượt thay vì image flash.

> 💡 **FE Perspective**
> **Flutter:** `CachedNetworkImage` với 3-tier cache: memory → disk → network. `memCacheWidth` giảm memory 75%+.
> **React/Vue tương đương:** Browser `<img>` tự cache qua HTTP headers. Service Worker Cache API cho full control. `loading="lazy"` cho lazy loading.
> **Khác biệt quan trọng:** Browser cache không controllable size/eviction. Flutter phải explicit dùng `CachedNetworkImage` package.

---

## Concept 6: Provider Performance — Selective Rebuild 🔴 MUST-KNOW

**WHY:** Selective rebuild ảnh hưởng trực tiếp performance hàng ngày — `select()` vs `watch()` phải hiểu rõ.

### Rebuild Scope Comparison

```
❌ Broad rebuild:
ref.watch(loginProvider)  // ANY field change → rebuild

✅ Selective rebuild:
ref.watch(loginProvider.select((s) => s.data.onPageError))  // chỉ error change
```

### Consumer Widget = Rebuild Boundary

```dart
Column(
  children: [
    Consumer(builder: (_, ref, __) {
      final error = ref.watch(provider.select((v) => v.data.onPageError));
      return ErrorWidget(error);  // chỉ rebuild khi error thay đổi
    }),
    Consumer(builder: (_, ref, __) {
      final enabled = ref.watch(provider.select((v) => v.data.isLoginButtonEnabled));
      return LoginButton(enabled);  // chỉ rebuild khi enabled thay đổi
    }),
  ],
)
```

Mỗi `Consumer` là một **independent rebuild scope**. `Column` parent KHÔNG rebuild. Đây là pattern quan trọng nhất cho Riverpod performance.

### AppProviderObserver — khi nào provider rebuild?

`AppProviderObserver.didUpdateProvider` log **mọi** state change. Nếu thấy provider X update 50 lần/giây → code smell:
- State update quá granular → batch updates
- Thiếu `select()` → widget rebuild không cần thiết
- Timer/stream emitting quá nhanh → throttle/debounce

> 💡 **FE Perspective**
> **Flutter:** `Consumer` + `select()` tạo rebuild boundary — chỉ rebuild khi selected slice thay đổi.
> **React/Vue tương đương:** `select()` = `useSelector` (Redux), `useMemo` (React). `Consumer` = `React.memo` wrapper. `ProviderObserver` = Redux DevTools.
> **Khác biệt quan trọng:** React re-render toàn component function, Riverpod chỉ re-run `builder` callback.

---

## Concept 7: Implicit Animations — Zero-Boilerplate Motion 🟡 SHOULD-KNOW

> Concepts #2–#3 cover **explicit animation** (AnimationController, Ticker, ShaderMask) — cần setup controller, dispose, vsync. Phần này cover **implicit animation** — Flutter tự quản lý animation state, dev chỉ thay đổi property.

> 💡 **FE Perspective**
> **Flutter:** Implicit animation = thay đổi property, framework tự animate. Không cần `AnimationController`.
> **React/Vue tương đương:** CSS `transition: all 300ms ease`. Thay đổi property → framework tự animate.
> **Khác biệt quan trọng:** Flutter implicit animation là widget-level, không cần `@keyframes` hay `requestAnimationFrame`.

### Animation Curves — Tham khảo nhanh

Mọi implicit animation đều nhận tham số `curve` quyết định **tốc độ thay đổi** theo thời gian:

| Curve | Mô tả | Khi nào dùng |
|-------|--------|-------------|
| `Curves.linear` | Tốc độ đều từ đầu đến cuối (đường thẳng) | Progress bar, countdown |
| `Curves.easeIn` | Bắt đầu chậm, tăng tốc dần (vào nhanh) | Element rời khỏi màn hình |
| `Curves.easeOut` | Bắt đầu nhanh, chậm dần (dừng mượt) | Element xuất hiện, dropdown mở |
| `Curves.easeInOut` | Chậm → nhanh → chậm (S-curve, tự nhiên nhất) | **Default cho hầu hết UI animation** |
| `Curves.bounceOut` | Nảy vài lần khi kết thúc (như bóng rơi) | Notification badge, playful UI |
| `Curves.elasticOut` | Vượt qua đích rồi đàn hồi lại | Spring-like effect, emphasis |
| `Curves.fastOutSlowIn` | Material Design recommended curve | Material motion, page transitions |

> **Rule of thumb:** `Curves.easeInOut` cho 80% cases. `Curves.fastOutSlowIn` cho Material Design compliance. `Curves.bounceOut` / `elasticOut` chỉ dùng khi cần attention-grabbing effect.

### 7a. AnimatedContainer — animate mọi visual property

**WHAT:** `Container` tự animate khi bất kỳ property nào thay đổi (size, color, padding, margin, decoration). Chỉ cần set `duration`.

**WHEN:** Button hover/press state, card expand/collapse, responsive layout change.

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  width: isExpanded ? 200 : 100,
  height: isExpanded ? 200 : 100,
  decoration: BoxDecoration(
    color: isExpanded ? Colors.blue : Colors.grey,
    borderRadius: BorderRadius.circular(isExpanded ? 16 : 8),
  ),
  child: const Icon(Icons.star),
)
```

Khi `isExpanded` thay đổi (qua `setState` hoặc state management) → **tất cả** property animate đồng thời. Không cần `AnimationController`, không cần `dispose`.

> 💡 **FE Perspective**
> **Flutter:** `AnimatedContainer` animate mọi visual property khi thay đổi (size, color, padding, decoration).
> **React/Vue tương đương:** `transition: width 300ms, height 300ms, background-color 300ms` — nhưng gộp vào 1 widget.
> **Khác biệt quan trọng:** Flutter gộp tất cả animated properties trong 1 `AnimatedContainer`. CSS cần list từng property.

<details>
<summary>📚 Đọc thêm: Các loại Implicit Animation khác</summary>

> Nội dung dưới đây là "nice to know" — không bắt buộc cho module này. `AnimatedContainer` và `Hero` ở trên đủ để nắm pattern chung.

### 7b. AnimatedOpacity — fade in/out

**WHAT:** Thay đổi `opacity` → widget tự fade. Giữ widget trong tree (khác `Visibility` — remove khỏi layout).

**WHEN:** Show/hide error message, loading indicator, empty state placeholder.

```dart
AnimatedOpacity(
  duration: const Duration(milliseconds: 200),
  opacity: isVisible ? 1.0 : 0.0,
  child: const Text('Error occurred'),
)
```

**Performance note:** `AnimatedOpacity` wrap child trong `RenderOpacity` — GPU compositing, không rebuild child. Nhưng child vẫn **nằm trong tree** (vẫn nhận events nếu `opacity: 0`). Dùng kết hợp `IgnorePointer` nếu cần disable interaction.

> 💡 **FE Perspective**
> **Flutter:** `AnimatedOpacity` fade widget bằng GPU compositing, child vẫn trong tree.
> **React/Vue tương đương:** `transition: opacity 200ms` — gần như 1:1.
> **Khác biệt quan trọng:** CSS `visibility: hidden` ≈ `Visibility(visible: false)`. CSS `opacity: 0` ≈ `AnimatedOpacity(opacity: 0)` — child vẫn nhận events.

### 7c. AnimatedSwitcher — cross-fade giữa 2 widget

**WHAT:** Khi `child` thay đổi (khác `key`) → fade-out widget cũ, fade-in widget mới. Default dùng `FadeTransition`.

**WHEN:** Tab content swap, step wizard, loading → data transition.

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: isLoading
      ? const CircularProgressIndicator(key: ValueKey('loading'))
      : Text(data, key: const ValueKey('content')),
)
```

**Key là bắt buộc** — `AnimatedSwitcher` dựa vào `key` + `runtimeType` để detect child thay đổi. Thiếu key → không animate.

> 💡 **FE Perspective**
> **Flutter:** `AnimatedSwitcher` cross-fade giữa 2 widget khi `key` thay đổi. Built-in, không cần package.
> **React/Vue tương đương:** Vue `<transition>` component. React `react-transition-group` `<SwitchTransition>`.
> **Khác biệt quan trọng:** Flutter dựa vào `key` + `runtimeType` để detect change. Thiếu key → không animate.

### 7d. AnimatedDefaultTextStyle — animate text style

**WHAT:** Thay đổi `TextStyle` (size, color, weight) → widget tự animate transition.

**WHEN:** Active/inactive tab label, selected/unselected chip, emphasis toggle.

```dart
AnimatedDefaultTextStyle(
  duration: const Duration(milliseconds: 250),
  style: isSelected
      ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)
      : const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey),
  child: const Text('Tab Label'),
)
```

> 💡 **FE Perspective**
> **Flutter:** `AnimatedDefaultTextStyle` animate text style (size, color, weight) khi thay đổi.
> **React/Vue tương đương:** `transition: font-size 250ms, font-weight 250ms, color 250ms` trên text element.
> **Khác biệt quan trọng:** Flutter gộp vào 1 widget. CSS cần khai báo từng property trong `transition`.

</details>

### 7e. Hero — shared element transition giữa routes

**WHAT:** Widget "bay" từ route này sang route khác bằng cách match `tag`. Flutter tạo overlay animation tự động.

**WHEN:** Image thumbnail → detail view, avatar → profile page, card → full-screen.

```dart
// Screen A — list item
Hero(
  tag: 'product-image-${product.id}',
  child: Image.network(product.imageUrl, width: 80, height: 80),
)

// Screen B — detail (navigate via Navigator.push)
Hero(
  tag: 'product-image-${product.id}',  // same tag = animate between
  child: Image.network(product.imageUrl, width: double.infinity, height: 300),
)
```

Flutter tự tính toán position, size, clip → animate trên **Overlay** layer (phía trên cả 2 route). Không cần `AnimationController`, không cần coordinate calculation.

> 💡 **FE Perspective**
> **Flutter:** `Hero` widget match bằng `tag` — auto animate position, size, clip giữa 2 routes.
> **React/Vue tương đương:** View Transitions API (`document.startViewTransition`) — browser capture old/new state rồi animate.
> **Khác biệt quan trọng:** Flutter dùng widget tree match (tag string). Browser dùng DOM snapshot. Flutter không cần coordinate calculation.

### Decision Table — Implicit vs Explicit

| Cần | Dùng | Ví dụ |
|-----|------|-------|
| Thay đổi property đơn giản | Implicit (`AnimatedContainer`) | Button color change |
| Cross-fade giữa 2 widget | `AnimatedSwitcher` | Tab content swap |
| Animation phức tạp, custom curve | Explicit (`AnimationController`) | Staggered list animation |
| Shared element giữa 2 route | `Hero` | Image detail transition |
| Fade in/out một widget | `AnimatedOpacity` | Show/hide error message |
| Animate text style | `AnimatedDefaultTextStyle` | Active tab label |

**Rule of thumb:** Bắt đầu với implicit animation. Chỉ chuyển sang explicit khi cần: chaining, staggering, custom `AnimatedWidget`, hoặc control playback (pause/reverse/repeat).

---

## 8. List Performance — ListView.builder & Optimization 🟡 SHOULD-KNOW

**WHY:** List/scroll performance là #1 issue trong production Flutter apps. `Column + SingleChildScrollView` cho list dài sẽ gây jank nghiêm trọng.

> 💡 **FE Perspective — Virtualized List**
> 
> | Flutter | React / Vue |
> |---------|-------------|
> | `ListView.builder` — chỉ build visible items | `react-window` / `react-virtualized` — virtual scrolling |
> | `itemExtent` — fixed height hint cho layout engine | `itemSize` prop trong react-window |
> | `cacheExtent` — pre-build items ngoài viewport | `overscanCount` trong react-window |
> | `RepaintBoundary` — isolate repaint region | Không có tương đương (browser handles) |

**Key patterns:**
- **ALWAYS** dùng `ListView.builder` cho dynamic lists (lazy construction)
- Đặt `itemExtent` khi items có fixed height → O(1) scroll offset calculation
- `RepaintBoundary` wrap complex list items → tránh repaint cascade
- `const` constructors cho list item widgets → skip rebuild

> 💡 **FE Perspective**
> React dev quen `react-window`: Flutter `ListView.builder` là equivalent built-in — không cần thêm package. Khác biệt: Flutter repaint granularity ở widget level (không phải DOM element) → `RepaintBoundary` giúp control repaint scope.

---

## Quick Reference — Khi nào dùng gì?

| Vấn đề | Công cụ | Concept |
|--------|---------|---------|
| Widget rebuild quá nhiều | `const` constructor, `Consumer`, `select()` | #1, #6 |
| Animation giật | `SingleTickerProviderStateMixin`, `ShaderMask` | #2, #3 |
| Animate property đơn giản | `AnimatedContainer`, `AnimatedOpacity` | #7 |
| Cross-fade widget swap | `AnimatedSwitcher` | #7 |
| Shared element giữa routes | `Hero` | #7 |
| Frame drop | DevTools Performance Overlay, Timeline | #4 |
| Memory leak | DevTools Memory tab, `ProviderObserver` | #4, #6 |
| Image load chậm | `CachedNetworkImage`, `memCacheWidth` | #5 |

> ➡️ **Forward ref:** M18 covers testing fundamentals (unit, widget, golden, integration tests) — không chuyên về performance testing. Performance profiling dùng DevTools Timeline là tool chính để đo, nằm ngoài scope training.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
