# Concepts — Dart Isolates & Concurrency

> 📌 **Module context:** Module này survey 6 concepts chính về Dart isolate model, mapping từ code đã đọc ở [01-code-walk](./01-code-walk.md). Mỗi concept kèm FE bridge cho dev có background JavaScript/React.

---

## Concept 1: Dart Isolate Model — No Shared Memory

### Isolate = Isolated Memory + Event Loop

```
┌──────────── Isolate A (Main) ───────────┐   ┌──────────── Isolate B ──────────────┐
│  ┌─────────┐  ┌──────────────────────┐  │   │  ┌─────────┐  ┌────────────────┐   │
│  │  Heap   │  │  Event Loop          │  │   │  │  Heap   │  │  Event Loop    │   │
│  │ (riêng) │  │  ┌─────┐ ┌───────┐  │  │   │  │ (riêng) │  │  ┌─────┐      │   │
│  │         │  │  │Micro│ │ Event │  │  │   │  │         │  │  │Micro│      │   │
│  │         │  │  │Queue│ │ Queue │  │  │   │  │         │  │  │Queue│      │   │
│  └─────────┘  │  └─────┘ └───────┘  │  │   │  └─────────┘  │  └─────┘      │   │
│               └──────────────────────┘  │   │               └────────────────┘   │
└─────────────────────┬───────────────────┘   └──────────┬────────────────────────┘
                      │      Message Passing             │
                      └──────── SendPort ◄──────────────┘
```

**Core principles:**
1. **No shared memory** — mỗi isolate có **riêng heap**. Không có race condition, không cần mutex/lock
2. **Message passing only** — isolates giao tiếp qua `SendPort`/`ReceivePort`. Data được **copy** (deep clone) hoặc **transfer** (move ownership)
3. **Independent event loop** — mỗi isolate có event loop riêng, chạy trên OS thread riêng

**Tại sao design này?**
- Eliminates data races, deadlocks. GC per-isolate (no global pause).
- Trade-off: copy overhead khi truyền large data giữa isolates

> 💡 **FE Perspective**
> **Flutter:** Dart isolate = isolated memory + event loop. No shared memory, communicate qua `SendPort`/`ReceivePort` (message passing).
> **React/Vue tương đương:** Web Worker — cả hai đều no shared memory, communicate qua `postMessage`. Comlink library wrap Worker cho ergonomic.
> **Khác biệt quan trọng:** JS có `SharedArrayBuffer` cho shared memory. Dart **không có equivalent** (by design, an toàn hơn).

---

## Concept 2: Main Isolate vs Background Isolates

### Main Isolate — UI Thread

| Aspect | Main Isolate | Background Isolate |
|--------|-------------|-------------------|
| **UI rendering** | ✅ Duy nhất | ❌ Không access |
| **Platform channels** | ✅ Full access | ⚠️ Hạn chế (Flutter ≥3.7 mới hỗ trợ background) |
| **Plugin access** | ✅ Tất cả plugins | ❌ Hầu hết plugins không hoạt động |
| **State (Riverpod, etc.)** | ✅ Normal | ❌ Phải tạo mới |
| **Lifecycle** | App lifetime | Tạo/hủy theo demand |

**Mental model:**
```
App Start → Main Isolate spawns
         → User scrolls list (60fps rendering) ← Main isolate busy
         → API returns 10MB JSON
         → Parse JSON on main isolate = JANK (dropped frames)
         → Parse JSON on background isolate = SMOOTH (parallel execution)
```

**Codebase context:** Toàn bộ Riverpod providers, Navigator, BuildContext — tất cả tồn tại trên **main isolate**. Background isolate phải hoạt động **independent**.

> 💡 **FE Perspective**
> **Flutter:** Main isolate = UI thread. Background isolate không access được widget tree, plugins, Riverpod state.
> **React/Vue tương đương:** Main thread (UI). Web Worker không access DOM.
> **Khác biệt quan trọng:** Flutter background isolate cũng không access hầu hết plugins (trước Flutter 3.7). Web Worker không có hạn chế plugin tương tự.

---

## Concept 3: Isolate.run() và compute() — Simplified APIs

### compute() — Flutter's One-Shot Isolate

```dart
// compute(): spawn isolate → run function → return result → kill isolate
final result = await compute(parseJson, rawJsonString);

// Function PHẢI là top-level hoặc static (không capture closure state)
List<UserData> parseJson(String raw) {
  final list = jsonDecode(raw) as List;
  return list.map((e) => UserData.fromJson(e)).toList();
}
```

### Isolate.run() — Dart 2.19+ (included in all Flutter 3.x releases) (Preferred)

```dart
// Isolate.run(): giống compute() nhưng hỗ trợ closure
final result = await Isolate.run(() {
  final list = jsonDecode(rawJsonString) as List;
  return list.map((e) => UserData.fromJson(e)).toList();
});
```

| API | Min Version | Closure Support | Use Case |
|-----|-----------|----------------|----------|
| `compute()` | Flutter any | ❌ Top-level/static only | Simple one-shot task |
| `Isolate.run()` | Dart 2.19+ (included since Flutter 3.7) | ✅ Closure (auto-copy captured vars) | Recommended default |
| `Isolate.spawn()` | Dart any | ❌ Manual ports | Long-lived worker |

**So sánh chi tiết:**

| Aspect | `compute()` | `Isolate.run()` | `Isolate.spawn()` |
|--------|:-----------:|:---------------:|:-----------------:|
| **Dart version** | Mọi version | Dart 2.19+ (included since Flutter 3.7) | Mọi version |
| **Lifecycle** | One-shot (spawn → run → kill) | One-shot (spawn → run → kill) | Persistent (spawn → communicate N lần → manual kill) |
| **Communication** | 1 input → 1 output | 1 input → 1 output | Bi-directional qua SendPort/ReceivePort |
| **Closure support** | ❌ Top-level/static only | ✅ Closure (auto-copy) | ❌ Top-level/static only |
| **Setup overhead** | ~20-50ms mỗi lần | ~20-50ms mỗi lần | ~20-50ms 1 lần, reuse nhiều lần |
| **Error handling** | Try/catch trong caller | Try/catch trong caller | Manual qua port messages |

**Khi nào dùng cái nào:**
- **`Isolate.run()`** — **default choice**, one-shot task, clean API, recommended cho Flutter 3.7+ / Dart 2.19+
- **`compute()`** — legacy compatible, cùng behavior với `Isolate.run()` nhưng không hỗ trợ closure
- **`Isolate.spawn()`** — long-lived worker cần communicate nhiều lần (ví dụ: background image processing pipeline, real-time data parsing stream)

> 💡 **FE Perspective**
> **Flutter:** `Isolate.run()` (preferred) hoặc `compute()` — one-shot isolate, clean API. `Isolate.spawn()` cho long-lived worker.
> **React/Vue tương đương:** `Comlink.wrap()` abstract Worker creation. Raw `new Worker()` + `postMessage()` cho manual management.
> **Khác biệt quan trọng:** `Isolate.run()` hỗ trợ closure (Flutter 3.7+ / Dart 2.19+). `compute()` chỉ top-level/static function.

---

## Concept 4: SendPort / ReceivePort — Low-Level Communication

### Two-Way Communication Pattern

```dart
// Main isolate — spawn worker, receive messages
Future<void> runWorker() async {
  final receivePort = ReceivePort();
  await Isolate.spawn(_workerEntry, receivePort.sendPort);

  await for (final message in receivePort) {
    if (message is SendPort) {
      message.send('start');  // bidirectional
    } else if (message == 'done') {
      receivePort.close(); break;
    }
  }
}

// Worker — PHẢI là top-level function
void _workerEntry(SendPort mainPort) {
  final workerPort = ReceivePort();
  mainPort.send(workerPort.sendPort);  // gửi port về main
  workerPort.listen((msg) {
    for (var i = 0; i < 100; i++) { mainPort.send(i); }
    mainPort.send('done');
  });
}
```

**Message passing rules:**
- Primitive types (int, String, bool, double, null): copy giá trị
- List, Map, Set: deep copy recursive
- `SendPort`: transferable — cho phép bi-directional communication
- **Không thể gửi:** closures, `BuildContext`, native resources, Socket, HttpClient

> 💡 **`Isolate.exit()`** (Dart 2.15+): Gửi kết quả về main isolate bằng **zero-copy transfer** và terminate isolate cùng lúc. `Isolate.run()` dùng pattern này internally. Khi dùng raw `Isolate.spawn()` + `SendPort`, prefer `Isolate.exit(sendPort, result)` thay vì `sendPort.send(result)` để tránh copy overhead.

> 💡 **FE Perspective**
> **Flutter:** `SendPort`/`ReceivePort` cho bidirectional communication. Data được deep copy (primitives, List, Map) hoặc transfer (`SendPort`).
> **React/Vue tương đương:** `MessageChannel` API (`port1.postMessage()`/`port2.onmessage`). Structured clone algorithm cho data serialization.
> **Khác biệt quan trọng:** Dart không thể gửi closures, `BuildContext`, native resources. JS cũng không thể gửi functions qua `postMessage`.

---

## Concept 5: Isolate Use Cases — Khi nào dùng

### Decision Matrix

```
Task > 16ms trên main isolate?
├── YES → CPU-intensive?
│   ├── YES → ✅ Dùng Isolate
│   │   ├── One-shot → Isolate.run() / compute()
│   │   └── Streaming → Isolate.spawn() + ports
│   └── NO (I/O bound) → ❌ async/await đủ tốt
└── NO → ❌ Không cần isolate (overhead > benefit)
```

| Use Case | Isolate? | Lý do |
|----------|---------|-------|
| **JSON parse 5000–10000 items** | ⚠️ | CPU-bound nhưng cần **measure trước** với profiling (DevTools Timeline) |
| **JSON parse > 10000 items** | ✅ | Strongly consider isolate — significant allocation overhead |
| **Image resize/compress** | ✅ | CPU-bound: pixel manipulation |
| **Crypto hash/encrypt** | ✅ | CPU-bound: mathematical computation |
| **SQLite bulk insert** | ⚠️ | I/O nhưng serialization overhead có thể justify |
| **HTTP request** | ❌ | I/O — Dart async handles efficiently |
| **File read/write** | ❌ | I/O — OS handles off-thread |
| **SharedPreferences.get** | ❌ | Light I/O, fast access |
| **Simple string manipulation** | ❌ | Trivial — isolate overhead > task time |

**Codebase:** `FileUtil.convertToWebPAndResize()` — plugin handles natively. Single `UserData.fromJson()` — không cần. List 5000–10000 `fromJson()` — ⚠️ measure first với profiling. List >10000 items — ✅ strongly consider `Isolate.run()`.

> 💡 **FE Perspective**
> **Flutter:** Dùng Isolate khi CPU-intensive > 16ms. I/O (network, file) dùng `async/await` đủ tốt.
> **React/Vue tương đương:** Dùng Web Worker khi CPU-bound > 16ms. `requestIdleCallback` cho scheduling nhẹ.
> **Khác biệt quan trọng:** Cùng rule: CPU-bound → Worker/Isolate. I/O-bound → async đủ. `fetch()` không cần Worker, `JSON.parse(huge)` nên dùng.

---

## Concept 6: Isolate Limitations — Gotchas & Constraints

### Không thể làm gì trong background isolate

```dart
// ❌ UI access — context không tồn tại trong background isolate
// ❌ Plugins (trước Flutter 3.7) — SharedPreferences, Firestore → PlatformException
// ❌ Non-sendable objects — Socket, HttpClient không transferable
```

**Flutter ≥ 3.7:** Có thể dùng platform channels trong background isolate nếu setup `RootIsolateToken` + `BackgroundIsolateBinaryMessenger.ensureInitialized(token)`.

### Common Gotchas

| Gotcha | Giải pháp |
|--------|-----------|
| Setup cost ≈ 20-50ms | Chỉ dùng khi task > 100ms |
| Copy overhead large data | `TransferableTypedData` cho binary |
| No shared state | Pass data qua message, không rely on globals |
| Debug khó hơn | DevTools → Isolates tab |

> 💡 **FE Perspective**
> **Flutter:** Isolate setup cost ≈20-50ms. Không thể access UI, plugins (trước 3.7), shared state. Debug qua DevTools Isolates tab.
> **React/Vue tương đương:** Web Workers cũng không access DOM. `SharedArrayBuffer` + `Atomics` cho shared state (JS only).
> **Khác biệt quan trọng:** Dart **không có** shared memory equivalent — phải dùng message passing. An toàn hơn nhưng có copy overhead.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
