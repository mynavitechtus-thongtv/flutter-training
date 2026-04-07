# Code Walk — Dart Isolates & Concurrency

> 📌 **Recap từ modules trước:**
> - **M0:** Dart basics, Future/async/await — nền tảng concurrency model ([M0 § Dart](../module-00-dart-primer/01-code-walk.md))
> - **M3:** Config/Constants — isolate-safe constants, không share mutable state ([M3 § Config](../module-03-common-layer/01-code-walk.md))
> - **M17:** Performance optimization — khi nào cần offload work khỏi main isolate ([M17 § Perf](../module-17-performance-animation/01-code-walk.md))
>
> Nếu chưa nắm vững Future/async/await → quay lại M0 trước.

---

## Walk Order

```
lib/main.dart (single-threaded event loop — main isolate)
    ↓
lib/data_source/firebase/messaging/firebase_messaging_service.dart (background isolate concept)
    ↓
lib/common/helper/local_push_notification_helper.dart (background notification processing)
    ↓
lib/common/util/file_util.dart (I/O operations — isolate candidates)
    ↓
lib/model/api/user_data.freezed.dart (JSON serialization — compute() candidate)
    ↓
build.yaml / pubspec.yaml (build_runner — separate process, not isolate)
```

Bắt đầu từ **main isolate** (event loop) → **background handler concepts** → **isolate candidates** trong codebase hiện tại.

> ⚠️ `base_flutter` chưa implement isolates. Code walk này phân tích **CƠ HỘI** sử dụng isolates — không phải code đang chạy. Mục tiêu: nhận diện khi nào cần isolate dựa trên codebase thật.

---

## 1. Main Isolate — Event Loop trong main.dart

<!-- AI_VERIFY: base_flutter/lib/main.dart -->

> 💡 **FE Perspective**
> **Flutter:** Main isolate chạy single-threaded event loop. `async/await` = schedule, không phải multi-thread.
> **React/Vue tương đương:** JS main thread cũng single-threaded event loop. `await fetch()` không block UI vì I/O delegate cho browser engine.
> **Khác biệt quan trọng:** `JSON.parse(hugeString)` block main thread ở cả JS và Dart. Giải pháp: Web Worker (JS), Isolate (Dart).

### Structural Overview

```
main() → runZonedGuarded
├── _runMyApp()                         ← TẤT CẢ chạy trên MAIN ISOLATE
│   ├── WidgetsFlutterBinding.ensureInitialized()
│   ├── Firebase.initializeApp()
│   ├── AppInitializer.init()
│   └── runApp(ProviderScope(...))      ← UI rendering loop
└── _reportError()                      ← error zone handler
```

### Key Insight: async ≠ multi-thread

```dart
// main.dart L12-16
Future<void> main() async => runZonedGuarded(
      _runMyApp,
      (error, stackTrace) => _reportError(error: error, stackTrace: stackTrace),
    );
```

**Phân tích:**
- `Future<void> main() async` — hàm `main` là async nhưng **vẫn chạy trên main isolate**
- `runZonedGuarded` — Zone giống error boundary, **không tạo isolate mới**
- `await Firebase.initializeApp()` — non-blocking wait, nhưng vẫn **main isolate**
- Toàn bộ `_runMyApp()` là sequential async — nếu có heavy computation ở đây → **block UI**

**Đây là lý do cần isolate:** Khi có CPU-intensive work (JSON parsing lớn, image processing, crypto), `async/await` không giúp được vì vẫn chạy trên cùng thread. Phải dùng **separate isolate** để thực sự parallel execution.

> 💡 **FE Perspective**
> **Flutter:** `async/await` vẫn chạy trên main isolate — chỉ schedule khác thời điểm, **không phải** multi-thread.
> **React/Vue tương đương:** `await fetch()` không block UI vì I/O delegate cho browser engine. `JSON.parse(hugeString)` vẫn block main thread.
> **Khác biệt quan trọng:** Giải pháp giống nhau: JS dùng Web Worker, Dart dùng Isolate cho CPU-bound work.

---

## 2. Background Isolate Opportunities — Firebase Messaging

<!-- AI_VERIFY: base_flutter/lib/data_source/firebase/messaging/firebase_messaging_service.dart -->

### Firebase Background Message Handler Pattern

```dart
// firebase_messaging_service.dart — current implementation
class FirebaseMessagingService {
  final _messaging = FirebaseMessaging.instance;

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
```

**Isolate relevance:** Firebase Messaging có `onBackgroundMessage` handler — đây là real-world isolate usage. Khi app ở background, Firebase dispatch message handler trên **separate Dart isolate**:

```dart
// Pattern thường dùng (không có trong codebase hiện tại nhưng là standard practice):
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ⚠️ Chạy trên ISOLATE RIÊNG — không access được:
  // - Provider/Riverpod state
  // - Navigator
  // - BuildContext
  // - Bất kỳ singleton nào từ main isolate
  await Firebase.initializeApp();  // phải init lại!
  print('Background message: ${message.messageId}');
}

// Registration — phải ở TOP-LEVEL, không trong class
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

**Key constraints:** `@pragma('vm:entry-point')` (giữ function), top-level function only, không share state (re-init mọi thứ), không access UI.

> 💡 **FE Perspective**
> **Flutter:** Firebase background handler chạy trên isolate riêng — không access Provider, Navigator, singleton từ main.
> **React/Vue tương đương:** Service Worker chạy riêng, không access DOM. `@pragma('vm:entry-point')` ≈ `self.addEventListener` registration.
> **Khác biệt quan trọng:** Dart background isolate phải re-init mọi thứ (`Firebase.initializeApp()`). Service Worker cũng cần separate setup.

---

## 3. Notification Processing — Background Work Pattern

<!-- AI_VERIFY: base_flutter/lib/common/helper/local_push_notification_helper.dart -->

```dart
// local_push_notification_helper.dart L17-20
class LocalPushNotificationHelper {
  LocalPushNotificationHelper(this._packageHelper);
  final PackageHelper _packageHelper;
  // ...
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/common/helper/local_push_notification_helper.dart`](../../base_flutter/lib/common/helper/local_push_notification_helper.dart)

**Isolate concern:** `LocalPushNotificationHelper` dùng DI (`@LazySingleton`) — instance này **chỉ tồn tại trên main isolate**. Nếu cần xử lý notification ở background isolate → **không thể access** instance này.

**Pattern an toàn cho background isolate:** dùng top-level functions, tạo dependencies locally — không rely on DI container hay global singletons.

---

## 4. File Operations — Isolate Opportunities

<!-- AI_VERIFY: base_flutter/lib/common/util/file_util.dart -->

```dart
// file_util.dart L13-35
static Future<XFile> convertToWebPAndResize({
  required File inputFile,
  int minWidth = 800,
}) async {
  final tempDir = await getTemporaryDirectory();
  final targetPath = path.join(
    tempDir.path,
    '${path.basenameWithoutExtension(inputFile.path)}.webp',
  );
  final result = await FlutterImageCompress.compressAndGetFile(
    inputFile.absolute.path,
    targetPath,
    quality: 80,
    format: CompressFormat.webp,
    minWidth: minWidth,
  );
  if (result == null) throw Exception('Failed to compress image');
  return result;
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/common/util/file_util.dart`](../../base_flutter/lib/common/util/file_util.dart)

**Phân tích isolate candidate:**

| Operation | CPU-bound? | Isolate candidate? | Lý do |
|-----------|-----------|-------------------|-------|
| `convertToWebPAndResize` | ✅ Heavy | ⚠️ Partially | Plugin dùng native code (đã offload), nhưng Dart-side processing có thể benefit |
| `getImageFileFromUrl` | ❌ I/O | ❌ | Network I/O — async đủ tốt |
| `deleteFile` | ❌ Fast | ❌ | Trivial operation |
| `getUniqueFileName` | ❌ Fast | ❌ | String manipulation nhẹ |

**Rule of thumb:** Chỉ dùng isolate cho **CPU-intensive** work > 16ms (1 frame @ 60fps). I/O operations (network, file read) đã async — không cần isolate.

> 💡 **FE Perspective**
> **Flutter:** Chỉ dùng isolate cho CPU-intensive work > 16ms. Plugin-based I/O (ảnh, file) đã offload native.
> **React/Vue tương đương:** `fetch()` không cần Worker (browser handle I/O off-thread). `crypto.subtle.digest()` trên large data nên dùng Worker.
> **Khác biệt quan trọng:** Flutter image compress plugin dùng native code (đã offload). JS image processing trên canvas cần Worker.

---

## 5. JSON Serialization — compute() Prime Candidate

<!-- AI_VERIFY: base_flutter/lib/model/api/user_data.freezed.dart -->

### Freezed + json_serializable Pattern

```dart
// user_data.freezed.dart — generated code
factory _UserData.fromJson(Map<String, dynamic> json) =>
    _$UserDataFromJson(json);

Map<String, dynamic> toJson() {
  return _$UserDataToJson(this);
}
```

**Khi nào cần isolate cho JSON parsing:**

```dart
// ❌ Small response — KHÔNG cần isolate
final user = UserData.fromJson(json);  // <1ms, fine trên main isolate

// ✅ Large response — NÊN dùng compute()
// Ví dụ: list 1000+ items, nested objects
final users = await Isolate.run(() {
  final List<dynamic> jsonList = jsonDecode(hugeJsonString);
  return jsonList.map((e) => UserData.fromJson(e)).toList();
});
```

**Benchmark guideline:**
- < 1000 items: `fromJson` trực tiếp trên main isolate (< 16ms)
- 1000-10,000 items: Cân nhắc `compute()` nếu notice jank — ⚠️ measure trước với profiling
- \> 10,000 items hoặc deeply nested: **Luôn** dùng `Isolate.run()` / `compute()`

---

## 6. build_runner — Separate Process (Không phải Isolate)

<!-- AI_VERIFY: base_flutter/build.yaml -->

**Clarification:** `build_runner` chạy trong **separate Dart process** (không phải isolate) — riêng VM, riêng memory. Code generation (freezed, json_serializable) chạy ở build time, không affect runtime.

> 💡 **FE Perspective**
> **Flutter:** `build_runner` chạy trong separate Dart process (không phải isolate) — code gen tại build time.
> **React/Vue tương đương:** Webpack/Vite build process — hoàn toàn separate process, khác Web Worker (runtime).
> **Khác biệt quan trọng:** `build_runner` là build-time tool. Isolate là runtime concurrency. Không nhầm lẫn.

---

## Summary: Concurrency Landscape trong Codebase

```
┌─────────────── Concurrency trong base_flutter ───────────────┐
│                                                               │
│  Main Isolate (Event Loop)                                    │
│  ├── async/await (I/O: network, file, DB)     ← ĐỦ TỐT      │
│  ├── Stream (Firebase onMessage, Riverpod)    ← ĐỦ TỐT      │
│  └── Timer/Future.delayed (scheduling)        ← ĐỦ TỐT      │
│                                                               │
│  Isolate Opportunities (chưa implement, nên consider)         │
│  ├── Large JSON parsing (> 1000 items)        ← compute()    │
│  ├── Image processing (nếu Dart-side)         ← Isolate.run  │
│  └── Crypto/hashing operations                ← compute()    │
│                                                               │
│  Background Isolate (Firebase, đã có sẵn)                     │
│  └── onBackgroundMessage handler              ← tự động      │
│                                                               │
│  Separate Process (build time)                                │
│  └── build_runner code generation             ← không liên quan│
└───────────────────────────────────────────────────────────────┘
```

<!-- AI_VERIFY: generation-complete -->
