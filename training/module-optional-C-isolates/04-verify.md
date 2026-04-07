# Verify — Dart Isolates & Concurrency

> Checklist xác nhận hoàn thành Optional Module C. Đánh dấu ✅ khi done.

---

## 1. Self-Assessment Quiz (5 câu — trả lời không mở source code)

### Q1. Isolate Model
**Q:** Dart Isolate khác **thread** (Java/C++) ở điểm nào quan trọng nhất?

| | Đáp án |
|---|--------|
| A) | Isolate chậm hơn thread 10x |
| B) | Isolate **không shared memory** — mỗi isolate có heap riêng, giao tiếp qua **message passing** (copy data) |
| C) | Isolate chỉ chạy trên iOS, Android dùng thread |
| D) | Isolate tự động share state giữa các isolate |

### Q2. compute() vs Isolate.spawn()
**Q:** Khi nào nên dùng `Isolate.spawn()` thay vì `Isolate.run()` (hoặc `compute()`)?

| | Đáp án |
|---|--------|
| A) | Luôn dùng `Isolate.spawn()` — nó nhanh hơn |
| B) | Khi cần **long-lived isolate** với bidirectional communication qua `SendPort`/`ReceivePort` (ví dụ: progress updates, multiple tasks) |
| C) | Khi function cần access UI widgets |
| D) | `Isolate.spawn()` deprecated — không nên dùng |

### Q3. SendPort / ReceivePort
**Q:** Để gửi data **từ spawned isolate về main isolate**, cần setup gì?

| | Đáp án |
|---|--------|
| A) | Gọi `setState()` trực tiếp từ spawned isolate |
| B) | Main tạo `ReceivePort`, gửi `sendPort` sang spawned isolate qua spawn parameter → spawned isolate dùng `sendPort.send(data)` |
| C) | Dùng global variable — cả 2 isolate đều access được |
| D) | Return value từ function là đủ — không cần port |

### Q4. When to Use Isolates
**Q:** Trường hợp nào **KHÔNG** cần dùng Isolate?

| | Đáp án |
|---|--------|
| A) | Parse JSON 500KB từ API response |
| B) | **HTTP request** bằng `dio.get()` — đã async, I/O-bound, không block UI |
| C) | Image processing / resize ảnh lớn |
| D) | Encrypt/decrypt file 50MB |

### Q5. Flutter Isolate Limitations
**Q:** Background isolate (spawned) **KHÔNG** thể làm gì?

| | Đáp án |
|---|--------|
| A) | Parse JSON string |
| B) | Perform mathematical calculations |
| C) | **Access UI** (Widget tree) và **một số platform plugins** require main isolate (trước Flutter 3.7 `RootIsolateToken`) |
| D) | Send messages qua SendPort |

### Đáp án

| Câu | Đáp án | Giải thích ngắn |
|-----|--------|-----------------|
| Q1 | **B** | Isolate = isolated memory. Thread share heap → cần lock/mutex. Isolate giao tiếp bằng message passing (data copy). |
| Q2 | **B** | `Isolate.run()`/`compute()` cho one-shot task. `Isolate.spawn()` cho long-lived worker cần bidirectional communication. |
| Q3 | **B** | Main tạo `ReceivePort` → lấy `.sendPort` → truyền cho spawned isolate. Spawned dùng `sendPort.send()` gửi data ngược về. |
| Q4 | **B** | HTTP request là I/O-bound → Dart async event loop xử lý tốt không block UI. Isolate dùng cho **CPU-bound** > 16ms. |
| Q5 | **C** | Background isolate không access Widget tree, và trước Flutter 3.7 không gọi được platform plugins. `RootIsolateToken` giải quyết phần plugin. |

### Scoring Rubric

| Điểm | Mức độ | Hành động |
|------|--------|-----------|
| 5/5 | ✅ Xuất sắc | Hiểu sâu Dart isolates & concurrency — chuyển tiếp |
| 4/5 | ✅ Đạt | Nắm vững core concepts — review câu sai |
| 3/5 | ⚠️ Cần ôn | Đọc lại [02-concept.md](./02-concept.md) sections tương ứng |
| ≤2/5 | ❌ Chưa đạt | Đọc lại toàn bộ concept + code walk trước khi làm exercise |

---

## 2. Code Walk Verification

```
<!-- AI_VERIFY: code-walk-checkpoint -->
[ ] Đọc main.dart — hiểu main isolate chạy single-threaded event loop, async ≠ multi-thread
[ ] Đọc firebase_messaging_service.dart — hiểu onBackgroundMessage chạy trên separate isolate
[ ] Đọc local_push_notification_helper.dart — hiểu DI/singleton KHÔNG isolate-safe
[ ] Đọc file_util.dart — phân loại CPU-bound vs I/O-bound operations
[ ] Đọc user_data.freezed.dart — hiểu khi nào fromJson cần offload sang isolate
[ ] Phân biệt isolate (runtime) vs build_runner process (build time)
```

## 3. Concept Comprehension

```
<!-- AI_VERIFY: concept-checkpoint -->
[ ] Giải thích isolate model: no shared memory, message passing, independent heap + event loop
[ ] Phân biệt main isolate (UI access, plugins) vs background isolate (restricted)
[ ] So sánh compute() vs Isolate.run() vs Isolate.spawn() — khi nào dùng cái nào
[ ] Mô tả SendPort/ReceivePort: bidirectional communication, data copy rules
[ ] Apply decision matrix: CPU-bound > 16ms → isolate, I/O → async/await
[ ] List ít nhất 3 isolate limitations: no UI, plugin restrictions, setup overhead
```

## 4. Exercise Completion

```
<!-- AI_VERIFY: exercise-checkpoint -->
[ ] Ex1 ⭐: Audit report — 8+ operations classified (CPU/IO, isolate yes/no, reasoning)
[ ] Ex2 ⭐⭐: IsolateHelper.parseJsonList hoạt động + benchmark test chạy pass
[ ] Ex3 ⭐⭐⭐: BatchWorker với SendPort/ReceivePort + progress stream + cleanup
```

## 5. FE Perspective Mapping

```
<!-- AI_VERIFY: fe-bridge-checkpoint -->
[ ] Dart Isolate ↔ Web Worker (no shared memory, message passing)
[ ] SendPort/ReceivePort ↔ MessageChannel / postMessage API
[ ] compute() / Isolate.run() ↔ Comlink wrap() (abstracted Worker)
[ ] No shared memory (Dart) ↔ SharedArrayBuffer restriction (JS — opt-in, COOP/COEP)
[ ] @pragma('vm:entry-point') ↔ Service Worker self.addEventListener registration
[ ] Background isolate ↔ Service Worker / Web Worker (no DOM access)
[ ] RootIsolateToken (Flutter 3.7+) ↔ BroadcastChannel API (cross-worker communication)
```

## 6. Backward Reference Check

```
<!-- AI_VERIFY: backward-ref-checkpoint -->
[ ] M0: Future/async/await chạy trên main isolate — NOT multi-threaded
[ ] M3: Constants (const values) isolate-safe — primitive types copy miễn phí
[ ] M17: Performance — jank > 16ms/frame là signal cần isolate offload
```

## 7. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Dùng isolate cho **I/O-bound** operations (HTTP, file read) | Overhead spawn isolate không cần thiết — async/await đã đủ | Chỉ dùng isolate cho **CPU-bound** > 16ms. I/O dùng `async`/`await` |
| 2 | Gửi object không serializable qua `SendPort` (closure, Socket, UI widget) | Runtime error: `Invalid argument` | Chỉ gửi primitive types, `List`, `Map`, `TransferableTypedData`, hoặc `SendPort` |
| 3 | Access singleton/DI trong background isolate | Null hoặc sai instance — mỗi isolate có **heap riêng** | Truyền data cần thiết qua message, hoặc re-init trong isolate |
| 4 | Quên `@pragma('vm:entry-point')` cho background entry function | Function bị tree-shaken trong release build → crash | Luôn annotate top-level function dùng làm isolate entry point |
| 5 | Không `kill()` isolate sau khi dùng xong | Memory leak — isolate tiếp tục chạy và giữ heap | Gọi `isolate.kill()` hoặc dùng `Isolate.run()` (đã tự cleanup) |

---

## 8. Module Completion Criteria

Hoàn thành các mục dưới đây để pass Optional Module C:

- [ ] **C1:** Self-Assessment Quiz ≥ 4/5 đáp án đúng
- [ ] **C2:** Code Walk — tất cả checkpoints đã đánh dấu
- [ ] **C3:** Concept Comprehension — tất cả checkpoints đã đánh dấu
- [ ] **C4:** Exercise 1 ⭐ hoàn thành — audit report với 8+ operations classified
- [ ] **C5:** Exercise 2 ⭐⭐ hoàn thành — IsolateHelper.parseJsonList + benchmark
- [ ] **C6:** _(Stretch goal)_ Exercise 3 ⭐⭐⭐ — BatchWorker với progress stream + cleanup
- [ ] **C7:** FE Perspective Mapping — tất cả mappings đã đánh dấu
- [ ] **C8:** Không còn file test/temp trong `lib/` (đã cleanup)

> ✅ **Pass:** C1–C5 + C7–C8 tất cả checked. C6 (⭐⭐⭐) = stretch goal (optional).
> ❌ **Chưa pass:** Quay lại exercise/concept chưa hoàn thành, đối chiếu lại checklist.

---

## Completion Sign-off

```
Ngày hoàn thành: _______________
Reviewer: _______________
Notes: _______________
```

<!-- AI_VERIFY: generation-complete -->
