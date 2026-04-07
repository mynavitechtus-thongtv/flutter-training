# Module 17 — Performance, DevTools & Animation

> **Depth:** Advanced Survey — structural overview + key pattern highlights

---

## Mục tiêu

Sau module này, bạn sẽ:
- Hiểu Flutter rendering pipeline (3 trees) và cách tối ưu widget rebuild
- Nắm shimmer animation architecture: `AnimationController` → `GradientTransform` → `ShaderMask`
- Sử dụng Flutter DevTools (Inspector, Performance Overlay, Timeline, Memory)
- Áp dụng image caching strategy với `CachedNetworkImage`
- Tối ưu Provider performance với `Consumer` + `select()` pattern

---

## Prerequisites

| Module | Cần nắm |
|--------|---------|
| **M7** | BasePage lifecycle, `const` constructors, dispose pattern |
| **M8** | Provider rebuild patterns, `select()`, `Consumer` widget |
| **M9** | Component library — shimmer, CommonImage, reusable widgets |

---

## ⏭️ Bạn có thể skip module này nếu:

- [ ] Giải thích được Flutter rendering pipeline: Widget tree → Element tree → RenderObject tree
- [ ] Biết khi nào `const` constructor giúp tránh rebuild và tại sao
- [ ] Mở `shimmer_loading.dart` và giải thích được flow: `AnimationController` → `LinearGradient` → `ShaderMask`
- [ ] Đã sử dụng Flutter DevTools (Performance Overlay, Timeline) để profile 1 page thực tế
- [ ] Giải thích được `Consumer` + `select()` pattern để tối ưu Provider rebuild

→ Nếu trả lời được **TẤT CẢ** → skip sang [Module 18 — Testing](../module-18-testing/00-overview.md)
→ Nếu thiếu 1-2 câu → đọc nhanh [02-concept.md](./02-concept.md) rồi skip
→ Nếu không trả lời được → học module này từ đầu

---

## Nội dung

| File | Nội dung | Thời lượng |
|------|----------|-----------|
| [01-code-walk.md](./01-code-walk.md) | Shimmer animation pipeline, CachedNetworkImage, Consumer rebuild | ~45 min |
| [02-concept.md](./02-concept.md) | 8 concepts: 3 trees, Ticker, ShaderMask, DevTools, Image cache, Provider perf, Implicit animations, List perf | ~30 min |
| [03-exercise.md](./03-exercise.md) | 4 exercises: DevTools profiling → rebuild optimize → shimmer variant → AI Dojo | ~2-3 hrs |
| [04-verify.md](./04-verify.md) | Checklist xác nhận hoàn thành | ~10 min |

**Phân bố:** 🔴 ~25% · 🟡 ~63% · 🟢 ~12%

---

## Anchor Files

```
lib/ui/component/shimmer/          — Animation system (4 files, ~243L)
lib/ui/component/common_image/     — Image caching (1 file, ~819L)
lib/ui/base/app_provider_observer.dart — State monitoring (~63L)
lib/ui/page/login/login_page.dart  — Consumer + select() thực chiến
lib/common/util/view_util.dart     — RenderBox utilities (~29L)
```

---

## 💡 FE Perspective Summary

| Flutter | Frontend Equivalent |
|---------|-------------------|
| 3 Trees (Widget/Element/RenderObject) | Virtual DOM → Real DOM (2 layers) |
| `AnimationController` + Ticker | `requestAnimationFrame` / GSAP |
| `ShaderMask` | CSS `mask-image` + GPU compositing |
| `CachedNetworkImage` | Service Worker Cache API |
| DevTools | Chrome DevTools + React Profiler |
| `Consumer` + `select()` | `React.memo` + `useSelector` |

---

## Forward Reference

→ **M18: Testing** sẽ cover cách viết automated performance tests — đo rebuild count, frame timing trong CI pipeline.

<!-- AI_VERIFY: generation-complete -->
