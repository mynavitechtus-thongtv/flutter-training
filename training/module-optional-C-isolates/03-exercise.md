# Exercises — Dart Isolates & Concurrency

> 📌 **Trước khi bắt đầu:** Đọc [01-code-walk](./01-code-walk.md) và [02-concept](./02-concept.md). Mỗi exercise build trên concepts đã cover.

---

## Exercise 1 ⭐ — Identify Isolate Candidates trong Codebase

### Mục tiêu
Audit codebase hiện tại, xác định operations nào có thể benefit từ isolate, và giải thích lý do.

### Steps

1. **Scan file operations:** Mở `../../base_flutter/lib/common/util/file_util.dart`. Với mỗi method (`convertToWebPAndResize`, `getImageFileFromUrl`, `deleteFile`, `getUniqueFileName`), đánh giá:
   - CPU-bound hay I/O-bound?
   - Estimated execution time (< 16ms hay > 16ms)?
   - Isolate candidate? Tại sao?

2. **Scan JSON parsing:** Tìm tất cả `fromJson` / `toJson` usage trong `../../base_flutter/lib/model/api/`. Identify trường hợp nào parse **list** lớn (> 100 items). Gợi ý: check API response handlers trong `../../base_flutter/lib/data_source/api/`.

3. **Scan background handlers:** Mở `../../base_flutter/lib/data_source/firebase/messaging/firebase_messaging_service.dart`. Đánh giá: có cần `onBackgroundMessage` handler không? Nếu thêm, những constraints nào phải tuân theo?

4. **Document findings:** Tạo bảng với columns: File | Method | Type (CPU/IO) | Duration Estimate | Isolate? | Reason

### Deliverable

File `docs/mC-isolate-candidates.md`: bảng audit ít nhất 8 operations, phân loại rõ ràng.

```
<!-- AI_VERIFY: exercise-1-candidates -->
✅ Đánh giá ít nhất 4 file utility methods (CPU vs I/O classification)
✅ Identified JSON parsing hotspots trong model layer
✅ Analyzed Firebase background handler constraints
✅ Documented reasoning cho mỗi candidate (dùng / không dùng isolate)
```

---

## Exercise 2 ⭐⭐ — Implement compute() cho JSON Parsing

### Mục tiêu
Tạo helper function dùng `compute()` / `Isolate.run()` để parse large JSON response off main isolate.

### Steps

1. **Tạo isolate helper** — file `lib/common/helper/isolate_helper.dart`:
   ```dart
   import 'dart:convert';
   import 'dart:isolate';

   class IsolateHelper {
     /// Parse JSON string thành List<Map> trên background isolate.
     /// Chỉ dùng khi data lớn (> 1000 items).
     static Future<List<T>> parseJsonList<T>({
       required String rawJson,
       required T Function(Map<String, dynamic>) fromJson,
     }) async {
       final decoded = await Isolate.run(() {
         return (jsonDecode(rawJson) as List)
             .cast<Map<String, dynamic>>();
       });
       // fromJson có thể dùng codegen → chạy trên main isolate
       return decoded.map(fromJson).toList();
     }
   }
   ```

2. **Benchmark:** Tạo test đo thời gian parse 5000 items trên main isolate vs `Isolate.run()`:
   ```dart
   // test/common/helper/isolate_helper_test.dart
   test('benchmark JSON parsing', () async {
     final json = jsonEncode(
       List.generate(5000, (i) => {'id': i, 'name': 'User $i', 'email': 'u$i@test.com'}),
     );
     final sw1 = Stopwatch()..start();
     // Main isolate parse...
     sw1.stop();

     final sw2 = Stopwatch()..start();
     // Isolate.run() parse...
     sw2.stop();

     print('Main: ${sw1.elapsedMilliseconds}ms, Isolate: ${sw2.elapsedMilliseconds}ms');
   });
   ```

3. **Integrate:** Thử tích hợp `IsolateHelper.parseJsonList` vào một API call handler có response lớn. Verify app behavior không đổi.

> 📝 Với 5000 items đơn giản (3 fields), main isolate có thể nhanh hơn do isolate spawn overhead (~20-50ms). Thử tăng lên 50,000+ items hoặc complex nested JSON để thấy rõ lợi ích. Mục tiêu chính là **jank-free UI**, không nhất thiết faster wall-clock time.

### Deliverable

`isolate_helper.dart` + benchmark test + screenshot kết quả benchmark.

```
<!-- AI_VERIFY: exercise-2-compute -->
✅ IsolateHelper class với parseJsonList method
✅ Sử dụng Isolate.run() (hoặc compute()) đúng cách
✅ Function parameter là top-level compatible (không capture mutable state)
✅ Benchmark test so sánh main isolate vs background isolate
```

---

## Exercise 3 ⭐⭐⭐ — Long-Lived Worker với SendPort/ReceivePort

### Mục tiêu
Implement worker isolate pattern cho streaming progress — ví dụ batch processing nhiều files.

### Steps

1. **Tạo worker** — `lib/common/helper/batch_worker.dart` với:
   - `BatchWorker` class: fields `_isolate`, `_receivePort`, `_workerSendPort`
   - `Stream<BatchProgress> start()` — spawn isolate, yield progress via `async*`
   - `void submitWork(List<String> items)` — gửi work qua `_workerSendPort`
   - `void dispose()` — `_isolate?.kill()` + `_receivePort?.close()`
   - `BatchProgress` data class: `completed`, `total`, `isComplete` getter
   - `@pragma('vm:entry-point') void _workerEntry(SendPort mainPort)` — top-level, setup bidirectional ports, process items, send progress

2. **UI integration:** Page với `StreamBuilder` + `BatchWorker.start()` hiển thị progress bar.

3. **Error handling:** `Isolate.addErrorListener` — restart worker hoặc notify user khi crash.

### Deliverable

`batch_worker.dart` + test page demo progress + error handling.

```
<!-- AI_VERIFY: exercise-3-sendport -->
✅ Isolate.spawn() với bi-directional communication (2 SendPorts)
✅ @pragma('vm:entry-point') trên entry function
✅ Stream-based progress reporting từ worker → main isolate
✅ Proper cleanup: Isolate.kill() + ReceivePort.close()
✅ Error listener setup
```

<!-- AI_VERIFY: generation-complete -->
