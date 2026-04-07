# Concepts — Platform Channels

> 📌 **Module context:** Module này survey 6 concepts chính về platform channel architecture trong Flutter, mapping từ code đã đọc ở [01-code-walk](./01-code-walk.md). Mỗi concept kèm FE bridge cho dev có background React/JavaScript.

---

## Concept 1: Platform Channel Architecture — 3 Channel Types 🔴 MUST-KNOW

**WHY:** 3 channel types là foundation — chọn sai channel type = architecture mismatch.

### MethodChannel, EventChannel, BasicMessageChannel

```
┌─────────────────────────────────────────────────┐
│                  Flutter (Dart)                  │
│  MethodChannel  │ EventChannel │ BasicMessage    │
│  (request/reply)│ (stream)     │ (raw message)   │
└───────┬─────────┴──────┬───────┴───────┬─────────┘
        │     Binary Messenger (async)    │
┌───────┴─────────┬──────┴───────┬───────┴─────────┐
│  iOS (Swift/ObjC) │ Android (Kotlin/Java) │ ...  │
└─────────────────┴──────────────┴─────────────────┘
```

| Channel | Pattern | Use Case | Codebase Example |
|---------|---------|----------|-----------------|
| **MethodChannel** | Request → Response (1:1) | Gọi native function, nhận kết quả | `"jp.flutter.app"` → `clearBadgeCount` |
| **EventChannel** | Subscribe → Stream (1:N) | Sensor data, location updates, battery | Plugin `connectivity_plus` dùng internally |
| **BasicMessageChannel** | Raw message, custom codec | Lightweight communication, no method concept | Ít dùng trực tiếp — advanced use case |

**MethodChannel** phổ biến nhất — 90%+ use cases. EventChannel cho **continuous data streams** (native push data liên tục). BasicMessageChannel cho custom protocol.

> 💡 **FE Perspective**
> **Flutter:** 3 channel types: MethodChannel (request/response), EventChannel (stream), BasicMessageChannel (raw).
> **React/Vue tương đương:** MethodChannel ≈ `fetch()`. EventChannel ≈ `EventSource`/WebSocket. BasicMessageChannel ≈ `postMessage()` raw.
> **Khác biệt quan trọng:** Flutter channels là async binary messaging. React Native bridge dùng JSON (legacy) hoặc JSI direct (new arch).

---

## Concept 2: Message Codecs — Serialization Layer 🟡 SHOULD-KNOW

**WHY:** Codecs mostly transparent, nhưng cần hiểu khi debug serialization errors.

### StandardMessageCodec vs JSONMessageCodec

```
Dart Object → Codec.encode → ByteData → Platform transfer → Codec.decode → Native Object
```

| Codec | Supported Types | Use Case |
|-------|----------------|----------|
| **StandardMessageCodec** | null, bool, int, double, String, List, Map, Uint8List | Default cho MethodChannel — binary efficient |
| **JSONMessageCodec** | JSON-compatible types | Interop với JSON APIs, dễ debug |
| **StringCodec** | String only | Simple text messages |
| **BinaryCodec** | ByteData raw | Custom binary protocol |

**StandardMessageCodec** (default) serialize Dart objects sang binary format tối ưu. Không cần `jsonEncode/decode` — framework handle tự động.

```dart
// Flutter side — codec tự động handle Map → native dictionary
final result = await channel.invokeMethod('getBatteryLevel');
// result là int — codec tự decode từ native NSNumber/Integer
```

**Gotcha:** Custom Dart class KHÔNG thể truyền trực tiếp. Phải convert sang Map/List trước. Đây là lý do **Pigeon** ra đời (Concept 6).

> 💡 **FE Perspective**
> **Flutter:** `StandardMessageCodec` (default) serialize Dart objects sang binary format tối ưu. Custom class phải convert sang Map/List.
> **React/Vue tương đương:** `structuredClone()` algorithm (serialize JS objects qua `postMessage`). `JSON.stringify/parse` cho JSON codec.
> **Khác biệt quan trọng:** React Native serialize qua JSON bridge (legacy) hoặc JSI direct access (new arch). Flutter dùng binary codec hiệu quả hơn JSON.

---

## Concept 3: Flutter → Native Communication Flow 🔴 MUST-KNOW

**WHY:** Flutter → Native là hướng phổ biến nhất — phải tự implement được method call flow.

### MethodChannel Invocation Lifecycle

```
Flutter: channel.invokeMethod('clear') → encode → BinaryMessenger.send (async)
    ━━━━━━━━ Platform Thread Switch ━━━━━━━━
Native:  receive → decode → MethodCallHandler → execute → result(value)
    ━━━━━━━━ Thread Switch Back ━━━━━━━━━━━
Flutter: Future<T> completes
```

**Key points:**
- Communication là **asynchronous** — luôn trả `Future` ở Flutter side
- Thread switch xảy ra tự động — Flutter UI thread → platform main thread
- Native throws → Flutter nhận `PlatformException`. `result(FlutterMethodNotImplemented)` ở Swift → `PlatformException` ở Dart.

### Ví dụ cụ thể: Battery Level

**Dart side:**
```dart
// Tạo channel với unique name
const platform = MethodChannel('com.example.app/battery');

Future<int> getBatteryLevel() async {
  try {
    final int level = await platform.invokeMethod('getBatteryLevel');
    return level;
  } on PlatformException catch (e) {
    throw Exception('Failed to get battery level: ${e.message}');
  }
}
```

**iOS side (Swift — AppDelegate.swift):**
```swift
let channel = FlutterMethodChannel(name: "com.example.app/battery",
                                   binaryMessenger: controller.binaryMessenger)
channel.setMethodCallHandler { (call, result) in
  if call.method == "getBatteryLevel" {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
    result(Int(device.batteryLevel * 100))  // 0-100
    // ⚠️ Trên iOS, `batteryLevel` trả về `-1` khi không xác định được (simulator, device error). Cần check: `if (batteryLevel < 0) return 'Unknown';`
  } else {
    result(FlutterMethodNotImplemented)
  }
}
```

---
> 📱 **Android Side** (Kotlin/Java) — code dưới đây chạy trên native Android, KHÔNG phải Dart

**Android side (Kotlin — MainActivity.kt):**
```kotlin
val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
                            "com.example.app/battery")
channel.setMethodCallHandler { call, result ->
  if (call.method == "getBatteryLevel") {
    val batteryManager = getSystemService(BATTERY_SERVICE) as BatteryManager
    val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    result.success(level)
  } else {
    result.notImplemented()
  }
}
```

> **Channel name** (`com.example.app/battery`) phải **giống nhau** ở cả 3 sides. Convention: reverse domain + feature name.

> 💡 **FE Perspective**
> **Flutter:** `channel.invokeMethod()` là async — thread switch tự động giữa Flutter UI thread và platform main thread.
> **React/Vue tương đương:** `window.postMessage()` + `addEventListener('message')`. React Native bridge cũng async (batched JSON).
> **Khác biệt quan trọng:** React Native JSI mới cho synchronous calls. Flutter vẫn luôn async qua binary messenger.

---

## Concept 4: Native → Flutter Callback Patterns 🟡 SHOULD-KNOW

**WHY:** Native → Flutter ít phổ biến hơn, pattern tương tự nhưng reversed — cần biết khi nào dùng.

### EventChannel — Continuous Stream

```dart
// Flutter side — subscribe to native stream
const eventChannel = EventChannel('com.example/sensor');
eventChannel.receiveBroadcastStream().listen(
  (data) => print('Sensor: $data'),
  onError: (err) => print('Error: $err'),
);
```

```swift
// iOS side — implement FlutterStreamHandler
class SensorStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        eventSink(sensorValue)  // push data to Flutter
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? { return nil }
}
```

**EventChannel khác MethodChannel:** MethodChannel = one-shot. EventChannel = open stream, native push liên tục. Native cũng có thể **gọi Flutter** qua cùng MethodChannel (bidirectional):
```swift
channel.invokeMethod("onPushReceived", arguments: ["title": pushTitle])  // iOS → Flutter
```

> 💡 **FE Perspective**
> **Flutter:** EventChannel cho continuous stream (sensor, location). Native cũng có thể gọi Flutter qua cùng MethodChannel (bidirectional).
> **React/Vue tương đương:** EventChannel ≈ `EventSource` (SSE). Native → Flutter ≈ WebSocket `onmessage` hoặc Cordova `fireDocumentEvent()`.
> **Khác biệt quan trọng:** EventChannel tự handle subscription lifecycle (onListen/onCancel). WebSocket cần manual management.

---

## Concept 5: Plugin Packages vs Raw Platform Channels 🟡 SHOULD-KNOW

**WHY:** Plugin vs raw channel là architecture decision — cần hiểu trade-offs để chọn đúng.

### Architecture Layers

```
Your Flutter App Code
    ↓ uses
Plugin Package (pub.dev)
  ├── lib/ — Dart API (what you import)
  ├── android/ — Kotlin/Java native code
  ├── ios/ — Swift/ObjC native code
  └── (internally uses MethodChannel/EventChannel)
    ↓ registered by
GeneratedPluginRegistrant (auto-generated)
    ↓ communicates via
Platform Channel (BinaryMessenger)
```

| Aspect | Raw Platform Channel | Plugin Package |
|--------|---------------------|----------------|
| Code location | Your `android/`, `ios/` directories | Package's `android/`, `ios/` directories |
| Maintenance | You maintain | Community/Google maintains |
| Type safety | String-based method names | Dart API with types |
| Registration | Manual in AppDelegate/Activity | Auto via `GeneratedPluginRegistrant` |
| Use when | Custom native feature | Standard native feature đã có package |

**Trong codebase:** 15+ plugins giải quyết 95% native needs. Chỉ `clearBadgeCount` channel là custom — vì không có plugin nào cover API này cụ thể.

Rule of thumb: **Tìm plugin trước → viết raw channel chỉ khi không có plugin phù hợp.**

> 💡 **FE Perspective**
> **Flutter:** Plugin package wrap native code và expose Dart API. `GeneratedPluginRegistrant` tự động register.
> **React/Vue tương đương:** npm package wrap native code (Capacitor plugin, Cordova plugin). React Native TurboModule.
> **Khác biệt quan trọng:** Flutter plugin auto-register. Cordova/Capacitor cần manual config. Rule: tìm plugin trước → viết raw channel chỉ khi không có.

---

## Concept 6: Pigeon — Type-safe Code Generation 🟢 AI-GENERATE

**WHY:** Pigeon gen code tự động — chỉ cần biết cách configure, code gen xử lý phần còn lại.

### Problem: String-based API fragile

```dart
// Dễ lỗi runtime — typo method name, wrong argument type
final result = await channel.invokeMethod('getBateryLevel');  // typo → PlatformException
```

### Solution: Pigeon generates type-safe interfaces

```
@HostApi()                          // Flutter calls native
abstract class BatteryApi {
  int getBatteryLevel();
}

@FlutterApi()                       // Native calls Flutter
abstract class NotificationApi {
  void onPushReceived(PushPayload payload);
}
```

**Pigeon generates** Dart class với typed methods, Kotlin/Swift handler interfaces, và codec cho custom DTO classes — tất cả compile-time checked.

```
pigeon input (.dart) → dart run pigeon
├── lib/generated/battery_api.g.dart     — Dart caller
├── android/.../BatteryApi.kt            — Kotlin handler
└── ios/.../BatteryApi.swift             — Swift handler
```

**Khi nào dùng Pigeon:** Nhiều methods + complex arguments, team lớn cần type safety. **Khi nào KHÔNG cần:** 1-2 simple methods (raw MethodChannel đủ) hoặc plugin đã có.

> 💡 **FE Perspective**
> **Flutter:** Pigeon generate type-safe Dart + Kotlin/Swift interfaces từ spec file. Compile-time checked.
> **React/Vue tương đương:** React Native Codegen (TurboModules) generate type-safe native interface từ spec. Protocol Buffers/gRPC codegen.
> **Khác biệt quan trọng:** Cordova không có equivalent — vẫn string-based `exec()`. Pigeon chỉ cần khi nhiều methods + complex arguments.

---

## Concept Map — How They Connect

```
Concept 1: Architecture      → 3 channel types (which to use?)
Concept 2: Codecs            → How data serialized (StandardMessageCodec default)
Concept 3: Flutter → Native  → Invocation lifecycle (async, thread switch)
Concept 4: Native → Flutter  → Callback patterns (EventChannel, bidirectional)
Concept 5: Plugin vs Raw     → When to write custom channel
Concept 6: Pigeon            → Type-safe alternative to string-based API
```

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
