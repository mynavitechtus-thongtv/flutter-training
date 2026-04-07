# Verify — Platform Channels

> Checklist xác nhận hoàn thành Optional Module A. Đánh dấu ✅ khi done.

---

## 1. Self-Assessment Quiz (5 câu — trả lời không mở source code)

### Q1. Channel Types
**Q:** Flutter plugin cần gửi **continuous sensor data** từ native → Dart. Channel nào phù hợp nhất?

| | Đáp án |
|---|--------|
| A) | `MethodChannel` — gọi `invokeMethod` liên tục mỗi 100ms |
| B) | `EventChannel` — native side dùng `EventSink`, Dart side nhận `Stream` |
| C) | `BasicMessageChannel` — gửi raw binary frame |
| D) | `BroadcastChannel` — dùng broadcast pattern |

### Q2. Codec
**Q:** `StandardMessageCodec` hỗ trợ type nào **KHÔNG** cần custom codec?

| | Đáp án |
|---|--------|
| A) | `int`, `String`, `List<int>`, `Map<String, dynamic>` |
| B) | `int`, `String`, `DateTime`, `Uint8List` |
| C) | `int`, `String`, custom Dart class, `enum` |
| D) | Tất cả Dart types đều tự động serialize |

### Q3. Thread Safety
**Q:** `MethodChannel` handler trên iOS chạy ở thread nào?

| | Đáp án |
|---|--------|
| A) | Luôn chạy trên background thread |
| B) | Luôn chạy trên **main thread** (UI thread) |
| C) | Thread do developer chỉ định khi tạo channel |
| D) | Tạo thread mới cho mỗi method call |

### Q4. Plugin vs Raw Channel
**Q:** Khi nào nên dùng raw `MethodChannel` thay vì tìm plugin package trên pub.dev?

| | Đáp án |
|---|--------|
| A) | Luôn dùng raw channel — plugin package chậm hơn |
| B) | Khi cần tương tác với native API **đặc thù** mà không có plugin, hoặc cần kiểm soát chi tiết hơn |
| C) | Khi app chỉ chạy trên 1 platform |
| D) | Khi Flutter SDK version quá cũ |

### Q5. Pigeon
**Q:** Pigeon codegen giải quyết vấn đề chính nào so với raw MethodChannel?

| | Đáp án |
|---|--------|
| A) | Tăng performance gấp 10x |
| B) | Loại bỏ string-based method names + untyped arguments → **type-safe** interface giữa Dart và native |
| C) | Tự động generate UI native cho cả iOS và Android |
| D) | Cho phép gọi native code mà không cần viết Swift/Kotlin |

### Đáp án

| Câu | Đáp án | Giải thích ngắn |
|-----|--------|-----------------|
| Q1 | **B** | `EventChannel` thiết kế cho continuous data stream (sensor, connectivity). `MethodChannel` là request/reply — polling liên tục không hiệu quả. |
| Q2 | **A** | `StandardMessageCodec` hỗ trợ primitive types + `List` + `Map`. `DateTime` và custom class cần custom codec. |
| Q3 | **B** | Platform channel messages dispatch trên **main thread** (cả iOS và Android). Heavy work phải tự dispatch sang background. |
| Q4 | **B** | Plugin-first approach. Raw channel chỉ khi API quá đặc thù hoặc plugin không đáp ứng yêu cầu cụ thể. |
| Q5 | **B** | Pigeon generate type-safe interface (`.dart` + `.swift`/`.kt`), loại bỏ string method names và `dynamic` arguments. |

### Scoring Rubric

| Điểm | Mức độ | Hành động |
|------|--------|-----------|
| 5/5 | ✅ Xuất sắc | Hiểu sâu platform channels — chuyển tiếp |
| 4/5 | ✅ Đạt | Nắm vững core concepts — review câu sai |
| 3/5 | ⚠️ Cần ôn | Đọc lại [02-concept.md](./02-concept.md) sections tương ứng |
| ≤2/5 | ❌ Chưa đạt | Đọc lại toàn bộ concept + code walk trước khi làm exercise |

---

## 2. Code Walk Verification

```
<!-- AI_VERIFY: code-walk-checkpoint -->
[ ] Đọc AppDelegate.swift — hiểu FlutterMethodChannel("jp.flutter.app") + setMethodCallHandler
[ ] Đọc SceneDelegate.swift — hiểu FlutterEngine lifecycle và binaryMessenger
[ ] Đọc MainActivity.kt — hiểu FlutterActivity và configureFlutterEngine extension point
[ ] Đọc GeneratedPluginRegistrant.java — hiểu auto-registration 15+ plugins
[ ] Đọc app_preferences.dart — hiểu FlutterSecureStorage dùng platform channel internally
[ ] Đọc local_push_notification_helper.dart — phân biệt Android notification channel vs Flutter platform channel
```

## 3. Concept Comprehension

```
<!-- AI_VERIFY: concept-checkpoint -->
[ ] Phân biệt 3 channel types: MethodChannel (request/reply), EventChannel (stream), BasicMessageChannel (raw)
[ ] Giải thích StandardMessageCodec: Dart types → binary → native types tự động
[ ] Mô tả Flutter → Native flow: invokeMethod → codec → binaryMessenger → thread switch → handler
[ ] Giải thích EventChannel pattern cho continuous data (sensor, connectivity)
[ ] Phân biệt raw platform channel vs plugin package — khi nào dùng cái nào
[ ] Giải thích Pigeon: codegen type-safe interface thay thế string-based method call
```

## 4. Exercise Completion

```
<!-- AI_VERIFY: exercise-checkpoint -->
[ ] Ex1 ⭐: Channel trace report — identified explicit channel + mapped 3 plugin flows
[ ] Ex2 ⭐⭐: Battery MethodChannel hoạt động cả iOS + Android — cùng channel name
[ ] Ex3 ⭐⭐⭐: Pigeon generated code compile + native implementations return real data
```

## 5. FE Perspective Mapping

```
<!-- AI_VERIFY: fe-bridge-checkpoint -->
[ ] MethodChannel ↔ WebView postMessage / React Native NativeModules
[ ] EventChannel ↔ EventSource (SSE) / WebSocket server-push
[ ] FlutterEngine ↔ WebView JS runtime / RN Bridge (JSI)
[ ] Plugin package ↔ Cordova/Capacitor plugin / RN native module
[ ] Pigeon codegen ↔ React Native Codegen (TurboModules) / Protocol Buffers
[ ] StandardMessageCodec ↔ structuredClone algorithm / JSON.stringify
[ ] GeneratedPluginRegistrant ↔ Cordova plugin.xml auto-registration
```

## 6. Backward Reference Check

```
<!-- AI_VERIFY: backward-ref-checkpoint -->
[ ] M0: Dart types → codec chỉ hỗ trợ primitive types + List/Map
[ ] M1: WidgetsFlutterBinding → platform channel messages dispatch qua binding layer
[ ] M3: Config/Constants → environment values có thể truyền qua channel nếu cần
```

## 7. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Dùng string "magic" cho method name — typo `getBatteryLevel` vs `getBateryLevel` | Silent fail, native handler không match | Dùng constant hoặc Pigeon codegen |
| 2 | Heavy computation trong channel handler trên main thread | UI jank / ANR trên Android | Dispatch sang background thread trong native code |
| 3 | Quên handle `FlutterMethodNotImplemented` trên native side | Crash khi Dart gọi method chưa implement | Luôn có default case trong `setMethodCallHandler` |
| 4 | Nhầm Android **notification channel** với Flutter **platform channel** | Config sai notification settings | Hai concept hoàn toàn khác — notification channel là Android OS feature |
| 5 | Gọi plugin API trước `WidgetsFlutterBinding.ensureInitialized()` | `MissingPluginException` | Đảm bảo binding initialized trước mọi plugin call (M1) |

---

## 8. Module Completion Criteria

Hoàn thành các mục dưới đây để pass Optional Module A:

- [ ] **C1:** Self-Assessment Quiz ≥ 4/5 đáp án đúng
- [ ] **C2:** Code Walk — tất cả checkpoints đã đánh dấu
- [ ] **C3:** Concept Comprehension — tất cả checkpoints đã đánh dấu
- [ ] **C4:** Exercise 1 ⭐ hoàn thành — channel trace report
- [ ] **C5:** Exercise 2 ⭐⭐ hoàn thành — Battery MethodChannel cả iOS + Android
- [ ] **C6:** _(Stretch goal)_ Exercise 3 ⭐⭐⭐ — Pigeon codegen compile + native data
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

---

## ➡️ Next Module

Hoàn thành Module A! Bạn đã nắm vững Platform Channels.

→ Tiến sang **[Module B — Push Notifications & Deep Linking](../module-optional-B-push-deeplink/)** để học push notifications và deep link handling.

<!-- AI_VERIFY: generation-complete -->
