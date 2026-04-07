# Code Walk — Performance, DevTools & Animation

> 📌 **Recap từ modules trước:**
> - **M7:** `BasePage` lifecycle, `const` constructors khắp codebase — widget rebuild tối ưu tại base layer ([M7 § BasePage](../module-07-base-viewmodel/01-code-walk.md))
> - **M9:** Component library — `Shimmer`, `CommonImage`, reusable UI primitives ([M9 § Components](../module-09-page-structure/01-code-walk.md))
> - **M8:** Provider rebuild patterns — `select()`, `Consumer` widget, `AppProviderObserver` ([M8 § State](../module-08-riverpod-state/01-code-walk.md))
>
> Nếu chưa nắm vững → quay lại module tương ứng trước.

---

## Walk Order

```
shimmer.dart (AnimationController + gradient pipeline)
    ↓
shimmer_loading.dart (descendant subscription + ShaderMask)
    ↓
circle_shimmer.dart / rounded_rectangle_shimmer.dart (shape primitives)
    ↓
common_image.dart (CachedNetworkImage, memory optimization)
    ↓
app_provider_observer.dart (state change monitoring)
    ↓
login_page.dart (Consumer selective rebuild — thực chiến)
```

Bắt đầu từ **animation pipeline** (how shimmer moves) → **image caching** (network perf) → **state rebuild optimization** (provider perf).

---

## 1. Shimmer Animation Architecture — shimmer.dart

<!-- AI_VERIFY: base_flutter/lib/ui/component/shimmer/shimmer.dart -->

> 💡 **FE Perspective**
> **Flutter:** Shimmer dùng `AnimationController.unbounded` + custom `GradientTransform` để animate gradient position.
> **React/Vue tương đương:** CSS `@keyframes shimmer { background-position: -200% → 200% }` + `linear-gradient`. GSAP Timeline tương tự.
> **Khác biệt quan trọng:** Flutter dùng custom `GradientTransform` thay vì `background-position`. Animation ở render level, không phải DOM.

### Structural Overview

```
Shimmer (StatefulWidget)
├── _ShimmerState (SingleTickerProviderStateMixin)
│   ├── AnimationController.unbounded — repeating 1s cycle
│   ├── LinearGradient + _SlidingGradientTransform
│   ├── Exposes: gradient, size, shimmerChanges (Listenable)
│   └── getDescendantOffset() — coordinate mapping
└── _SlidingGradientTransform (GradientTransform)
    └── Matrix4.translationValues — slide gradient across width
```

→ [Mở file gốc](../../base_flutter/lib/ui/component/shimmer/shimmer.dart)

### Key Pattern Highlights

**AnimationController.unbounded + repeat:**
```dart
// shimmer.dart L59-61
_shimmerController = AnimationController.unbounded(vsync: this)
  ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
```

Tại sao `.unbounded`? Controller thông thường clamp value trong [0, 1]. Shimmer cần slide **ngoài bounds** (`-0.5` → `1.5`) để gradient chạy hết chiều rộng widget. `vsync: this` — `SingleTickerProviderStateMixin` đảm bảo animation chỉ tick khi widget visible (tiết kiệm battery).

**Custom GradientTransform:**
```dart
// shimmer.dart L83-92
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
```

Mỗi frame, `slidePercent` = controller value → gradient dịch chuyển `bounds.width * percent` pixel theo trục X. Đây là cách Flutter "animate gradient position" — khác biệt cơ bản với CSS `background-position` animation.

**Ancestor pattern — expose state to descendants:**
```dart
// shimmer.dart L13-15
static _ShimmerState? of(BuildContext context) {
  return context.findAncestorStateOfType<_ShimmerState>();
}
```

Pattern cổ điển `InheritedWidget`-style lookup. Descendants gọi `Shimmer.of(context)` để truy cập `gradient`, `size`, `shimmerChanges`. Tương tự React Context nhưng qua widget tree traversal.

---

## 2. ShimmerLoading — Descendant Widget

<!-- AI_VERIFY: base_flutter/lib/ui/component/shimmer/shimmer_loading.dart -->

### Animation Subscription Pattern

```dart
// shimmer_loading.dart L27-37
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (_shimmerChanges != null) {
    _shimmerChanges!.removeListener(_onShimmerChange);
  }
  _shimmerChanges = Shimmer.of(context)?.shimmerChanges;
  if (_shimmerChanges != null) {
    _shimmerChanges!.addListener(_onShimmerChange);
  }
}
```

→ [Mở file gốc](../../base_flutter/lib/ui/component/shimmer/shimmer_loading.dart)

`didChangeDependencies` — KHÔNG phải `initState`. Tại sao? Vì `Shimmer.of(context)` phụ thuộc ancestor trong tree. Nếu ancestor thay đổi (ví dụ hot reload), `didChangeDependencies` được gọi lại → re-subscribe. `initState` chỉ chạy 1 lần.

> 💡 **FE Perspective**
> **Flutter:** `didChangeDependencies` re-subscribe khi ancestor thay đổi — khác `initState` chỉ chạy 1 lần.
> **React/Vue tương đương:** `useEffect` với dependency array — re-run khi dependency thay đổi.
> **Khác biệt quan trọng:** Flutter tách rõ: `initState` = mount-only, `didChangeDependencies` = dependency-changed. React gộp vào `useEffect`.

### ShaderMask Rendering

```dart
// shimmer_loading.dart L68-80
return ShaderMask(
  blendMode: BlendMode.srcATop,
  shaderCallback: (bounds) {
    return gradient.createShader(
      Rect.fromLTWH(
        -offsetWithinShimmer.dx,
        -offsetWithinShimmer.dy,
        shimmerSize.width,
        shimmerSize.height,
      ),
    );
  },
  child: widget.loadingWidget != null ? widget.loadingWidget! : widget.child,
);
```

**Performance insight:** `ShaderMask` hoạt động ở **RenderObject level** — GPU compositing, không phải widget rebuild. Mỗi frame chỉ cập nhật shader parameter (offset, gradient), widget tree **không** rebuild. Đây là lý do shimmer mượt 60fps.

`_onShimmerChange` chỉ gọi `setState` khi `isLoading == true`:
```dart
void _onShimmerChange() {
  if (widget.isLoading) {
    setState(() {});  // trigger repaint, NOT rebuild subtree
  }
}
```

---

## 3. Shape Primitives — circle_shimmer.dart & rounded_rectangle_shimmer.dart

<!-- AI_VERIFY: base_flutter/lib/ui/component/shimmer/circle_shimmer.dart -->
<!-- AI_VERIFY: base_flutter/lib/ui/component/shimmer/rounded_rectangle_shimmer.dart -->

Cả hai đều là **StatelessWidget + const constructor**:

```dart
const CircleShimmer({this.diameter, super.key});
const RoundedRectangleShimmer({this.width, this.height, this.radius, super.key});
```

→ [Mở file gốc](../../base_flutter/lib/ui/component/shimmer/circle_shimmer.dart)
→ [Mở file gốc](../../base_flutter/lib/ui/component/shimmer/rounded_rectangle_shimmer.dart)

**Performance pattern:** `const` constructor cho phép Flutter **reuse instance** khi rebuild parent — `const CircleShimmer()` ở hai nơi khác nhau trả về **cùng một instance**. Framework skip `canUpdate` check → zero rebuild cost.

Hai widget này là **children** của `ShimmerLoading` — chúng chỉ cung cấp shape (Container + BoxDecoration), phần animation do `ShaderMask` từ parent handle.

> 💡 **FE Perspective**
> **Flutter:** `const` constructor cho phép reuse instance — framework skip rebuild toàn bộ subtree.
> **React/Vue tương đương:** CSS skeleton loading: `<div class="skeleton-circle">` + parent animation overlay. Shape là HTML structure.
> **Khác biệt quan trọng:** Flutter `const` canonicalize instance tại compile-time. React/JSX luôn tạo object mới — không có equivalent.

---

## 4. CommonImage — Network Performance

<!-- AI_VERIFY: base_flutter/lib/ui/component/common_image/common_image.dart -->

### CachedNetworkImage Integration

```dart
// common_image.dart — network factory
CommonImage.network({
  required String? url,
  // ...
  bool enableCache = false,  // opt-in caching
})
```

→ [Mở file gốc](../../base_flutter/lib/ui/component/common_image/common_image.dart)

Khi `enableCache = true`, component switch sang `CachedNetworkImage`:

```dart
// common_image.dart L340-385
if (_style.useCachedNetworkImage) {
  final maxWidth = min(screenWidth, _style.width ?? screenWidth);
  final memCacheWidth = _style.memCacheWidth ??
      (_style.width != null ? maxWidth.times(devicePixelRatio).toInt() : null);

  image = CachedNetworkImage(
    imageUrl: imageUrl,
    memCacheWidth: memCacheWidth,
    memCacheHeight: memCacheHeight,
    fadeInDuration: const Duration(milliseconds: 500),
    fadeOutDuration: _style.fadeOutDuration,
    // ...
  );
}
```

**Memory optimization pattern:** `memCacheWidth` / `memCacheHeight` tính theo `devicePixelRatio` — ảnh 1000x1000 trên device 2x chỉ cache 500x500 logical pixel → giảm 75% memory. Đây là optimization thường bị bỏ qua.

**Dual caching:** `CachedNetworkImage` sử dụng:
1. **Memory cache** — quick access, limited size
2. **Disk cache** — persistent, `maxWidthDiskCache` / `maxHeightDiskCache` limit

> 💡 **FE Perspective**
> **Flutter:** `CachedNetworkImage` với `memCacheWidth` tính theo `devicePixelRatio` — giảm 75%+ memory.
> **React/Vue tương đương:** Browser `<img>` cache qua HTTP headers (`Cache-Control`, `ETag`). Service Worker Cache API cho full control.
> **Khác biệt quan trọng:** Flutter phải explicit dùng `CachedNetworkImage` package vì không có built-in browser cache layer.

---

## 5. AppProviderObserver — State Performance Monitoring

<!-- AI_VERIFY: base_flutter/lib/ui/base/app_provider_observer.dart -->

```dart
class AppProviderObserver extends ProviderObserver {
  AppProviderObserver({
    this.logOnDidAddProvider = Config.logOnDidAddProvider,
    this.logOnDidUpdateProvider = Config.logOnDidUpdateProvider,
    // ...
  });

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (logOnDidUpdateProvider) {
      Log.d('didUpdateProvider: $provider, previousValue: $previousValue, newValue: $newValue');
    }
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/ui/base/app_provider_observer.dart)

**Performance debugging tool:** Observer tracks **mọi** provider change. Trong dev mode, enable `logOnDidUpdateProvider` để phát hiện:
- Provider rebuild quá nhiều (unnecessary state changes)
- Provider dispose sớm (memory leak source)
- Provider add bất thường (circular dependency)

Config flags (`Config.logOnDidAddProvider`) cho phép toggle per-environment — chỉ log ở dev/staging, tắt ở production.

> 💡 **FE Perspective**
> **Flutter:** `ProviderObserver.didUpdateProvider` log mọi state change — code-level observable.
> **React/Vue tương đương:** React DevTools Profiler track re-renders. Redux DevTools track state changes.
> **Khác biệt quan trọng:** `ProviderObserver` là code-level, không cần external tool. React cần DevTools extension.

---

## 6. Consumer Selective Rebuild — login_page.dart

<!-- AI_VERIFY: base_flutter/lib/ui/page/login/login_page.dart -->

```dart
// login_page.dart L96-112
Consumer(
  builder: (context, ref, child) {
    final onPageError = ref.watch(
      provider.select((value) => value.data.onPageError),
    );
    return Visibility(
      visible: onPageError.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: CommonText(onPageError, style: style(fontSize: 14, color: color.red1)),
      ),
    );
  },
),
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/ui/page/login/login_page.dart)

**Pattern: Consumer + select() = surgical rebuild**

Toàn bộ `LoginPage` watch provider, nhưng `Consumer` widget **cô lập** vùng rebuild:
- `ref.watch(provider.select(...))` — chỉ rebuild khi `onPageError` thay đổi, KHÔNG phải toàn state
- `Consumer` tạo **rebuild boundary** — siblings KHÔNG bị ảnh hưởng

Tương tự cho login button:
```dart
// login_page.dart L114-120
Consumer(
  builder: (context, ref, child) {
    final isLoginButtonEnabled = ref.watch(
      provider.select((value) => value.data.isLoginButtonEnabled),
    );
    return ElevatedButton(/* ... */);
  },
),
```

Hai `Consumer` rebuild **độc lập** — error message thay đổi không trigger button rebuild, và ngược lại.

> 💡 **FE Perspective**
> **Flutter:** `Consumer` + `select()` tạo surgical rebuild boundary — siblings không bị ảnh hưởng.
> **React/Vue tương đương:** `React.memo` + `useSelector` (Redux Toolkit) — chỉ re-render khi selected slice thay đổi.
> **Khác biệt quan trọng:** `Consumer` chỉ re-run `builder` callback. React re-render toàn component function.

---

## 7. Implicit Animations — Không có trong base_flutter 🟡 SHOULD-KNOW

base_flutter **không sử dụng** implicit animation widgets (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`, `Hero`). Toàn bộ animation trong codebase dùng explicit approach (`AnimationController` + `ShaderMask` cho shimmer).

Tuy nhiên, trong production app:
- **~80% animation** có thể giải quyết bằng implicit widgets — chỉ thay đổi property + set `duration`
- Implicit animation là **entry point** tốt nhất cho developer mới — zero boilerplate, no dispose, no mixin
- `Hero` transition gần như **bắt buộc** cho navigation UX chuyên nghiệp (image gallery, product detail)

> 📖 Xem chi tiết tại [02-concept.md § Concept 7](./02-concept.md#concept-7-implicit-animations--zero-boilerplate-motion--should-know) — bao gồm code snippets, decision table, và FE Bridge mapping.

---

## Summary — Performance Patterns Map

| Pattern | File | Mechanism | FE Equivalent |
|---------|------|-----------|---------------|
| Shimmer animation | `shimmer.dart` | `AnimationController` + `GradientTransform` | CSS `@keyframes` + `linear-gradient` |
| GPU compositing | `shimmer_loading.dart` | `ShaderMask` at RenderObject level | CSS `mask-image` + GPU compositing |
| const reuse | `circle_shimmer.dart` | `const` constructor → instance canonicalization | N/A (React re-creates objects) |
| Image caching | `common_image.dart` | `CachedNetworkImage` + memory-aware sizing | Browser cache + `loading="lazy"` |
| State monitoring | `app_provider_observer.dart` | `ProviderObserver` lifecycle hooks | Redux DevTools / React Profiler |
| Selective rebuild | `login_page.dart` | `Consumer` + `select()` | `React.memo` + `useSelector` |

> ➡️ **Forward ref:** M18 sẽ cover profiling patterns trong test — dùng DevTools để đo performance metrics tự động.

<!-- AI_VERIFY: generation-complete -->
