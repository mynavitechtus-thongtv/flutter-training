# Optional Module C — Dart Isolates & Concurrency

> **Depth:** Advanced Survey — optional module, lighter scaffolding

---

## Mục tiêu

Sau module này, bạn sẽ:
- Hiểu Dart isolate model: no shared memory, message passing
- Phân biệt khi nào dùng async/await (I/O) vs isolate (CPU-intensive)
- Sử dụng `Isolate.run()` / `compute()` cho one-shot tasks
- Nắm `SendPort`/`ReceivePort` pattern cho long-lived worker isolates

---

## Prerequisites

| Module | Cần nắm |
|--------|---------|
| **M0** | Dart basics, Future/async/await — nền tảng concurrency |
| **M3** | Config/Constants — isolate-safe constants, immutable data |
| **M17** | Performance optimization — identify jank, frame budget 16ms |

---

## Nội dung

| File | Nội dung | Thời lượng |
|------|----------|-----------|
| [01-code-walk.md](./01-code-walk.md) | Main isolate, background handler, isolate candidates | ~25 min |
| [02-concept.md](./02-concept.md) | 6 concepts: isolate model, APIs, ports, use cases, limitations | ~20 min |
| [03-exercise.md](./03-exercise.md) | 3 exercises: audit candidates → compute() JSON → SendPort worker | ~2-3 hrs |
| [04-verify.md](./04-verify.md) | Checklist xác nhận hoàn thành | ~10 min |

**Phân bố:** 🔴 ~33% · 🟡 ~67% · 🟢 0%

---

## Anchor Files

```
lib/main.dart — main isolate, event loop entry
lib/data_source/firebase/messaging/firebase_messaging_service.dart — background isolate concept
lib/common/helper/local_push_notification_helper.dart — background processing
lib/common/util/file_util.dart — I/O vs CPU-bound operations
lib/model/api/user_data.freezed.dart — JSON serialization (compute() candidate)
```

---

## 💡 FE Perspective Summary

| Flutter / Dart | Frontend Equivalent |
|----------------|-------------------|
| Dart Isolate | Web Worker |
| `SendPort` / `ReceivePort` | `MessageChannel` / `postMessage` |
| `compute()` / `Isolate.run()` | Comlink `wrap()` (ergonomic Worker) |
| No shared memory | `SharedArrayBuffer` restriction (JS default) |
| `@pragma('vm:entry-point')` | Service Worker `self.addEventListener` |
| Background Isolate | Service Worker / Web Worker context |

## Forward Reference

→ Hỗ trợ hiểu **Module Optional A** (platform channel restrictions) và **Module Optional B** (Firebase background isolate).

<!-- AI_VERIFY: generation-complete -->
