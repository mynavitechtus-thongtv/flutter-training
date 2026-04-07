# Exercises — Platform Channels

> 📌 **Trước khi bắt đầu:** Đọc [01-code-walk](./01-code-walk.md) và [02-concept](./02-concept.md). Mỗi exercise build trên concepts đã cover.

---

## Exercise 1 ⭐ — Explore Existing Platform Channels

### Mục tiêu
Trace platform channel usage trong codebase — hiểu plugin nào dùng channel nào, và identify explicit channel đã có.

### Steps

1. **Tìm explicit channel:** Mở `../../base_flutter/ios/Runner/AppDelegate.swift`, locate `FlutterMethodChannel(name: "jp.flutter.app")`. Ghi nhận method name và handler logic.

2. **Trace plugin channels:** Mở `../../base_flutter/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`. List tất cả plugins registered. Pick 3 plugins (gợi ý: `FlutterSecureStoragePlugin`, `FlutterLocalNotificationsPlugin`, `SharedPreferencesPlugin`).

3. **Dart side mapping:** Với mỗi plugin đã pick, tìm file Dart sử dụng nó:
   - `flutter_secure_storage` → `../../base_flutter/lib/data_source/preference/app_preferences.dart`
   - `flutter_local_notifications` → `../../base_flutter/lib/common/helper/local_push_notification_helper.dart`
   - `shared_preferences` → trace qua `app_preferences.dart`

4. **Vẽ diagram:** Cho mỗi plugin, vẽ flow: Dart API call → (internal MethodChannel) → Native implementation

### Deliverable

File `docs/mA-channel-trace.md`: bảng mapping 3 plugins (Dart API → channel name → native API), kèm diagram flow cho `clearBadgeCount` explicit channel.

```
<!-- AI_VERIFY: exercise-1-explore -->
✅ Identified explicit FlutterMethodChannel trong AppDelegate.swift
✅ Listed 3+ plugins từ GeneratedPluginRegistrant
✅ Traced Dart → Channel → Native flow cho mỗi plugin
```

---

## Exercise 2 ⭐⭐ — Implement MethodChannel (Battery Level)

### Mục tiêu
Viết custom MethodChannel hoàn chỉnh — cả Flutter, iOS, Android side — để lấy battery level. Classic "hello world" của platform channels.

### Steps

1. **Flutter side** — tạo file `lib/common/helper/battery_helper.dart`:
   ```dart
   import 'package:flutter/services.dart';

   class BatteryHelper {
     static const _channel = MethodChannel('jp.flutter.app/battery');

     static Future<int> getBatteryLevel() async {
       try {
         final level = await _channel.invokeMethod<int>('getBatteryLevel');
         return level ?? -1;
       } on PlatformException catch (e) {
         throw Exception('Failed to get battery: ${e.message}');
       }
     }
   }
   ```

2. **Android side** — override `configureFlutterEngine` trong `MainActivity.kt`, thêm `MethodChannel("jp.flutter.app/battery")`. Handler: `BatteryManager.getIntProperty(BATTERY_PROPERTY_CAPACITY)` → `result.success(level)`.

3. **iOS side** — thêm `FlutterMethodChannel` tương tự `clearBadgeCount` trong `AppDelegate.swift`. Handler: `UIDevice.current.batteryLevel * 100` → `result(level)`. Nhớ set `isBatteryMonitoringEnabled = true`.

4. **Test:** Gọi `BatteryHelper.getBatteryLevel()` từ debug button, verify trên cả iOS simulator và Android emulator.

### Deliverable

3 files modified/created + screenshot kết quả battery level hiển thị.

```
<!-- AI_VERIFY: exercise-2-method-channel -->
✅ Flutter MethodChannel với invokeMethod + PlatformException handling
✅ Android handler với BatteryManager API
✅ iOS handler với UIDevice.batteryLevel
✅ Cùng channel name "jp.flutter.app/battery" cả 3 sides
```

---

## Exercise 3 ⭐⭐⭐ — Pigeon Type-safe Channel

### Mục tiêu
Dùng Pigeon package để generate type-safe platform channel — thay thế string-based invocation.

### Steps

1. **Thêm dependency:**
   ```yaml
   # pubspec.yaml → dev_dependencies
   pigeon: ^22.4.1  # ← Check pub.dev/packages/pigeon for latest version
   ```

2. **Tạo Pigeon definition** — `pigeons/device_info_api.dart`:
   ```dart
   import 'package:pigeon/pigeon.dart';

   class DeviceInfoResult {
     String? model;
     String? osVersion;
     int? batteryLevel;
   }

   @ConfigurePigeon(PigeonOptions(
     dartOut: 'lib/generated/device_info_api.g.dart',
     kotlinOut: 'android/app/src/main/kotlin/jp/flutter/app/DeviceInfoApi.kt',
     swiftOut: 'ios/Runner/DeviceInfoApi.swift',
   ))
   @HostApi()
   abstract class DeviceInfoApi {
     DeviceInfoResult getDeviceInfo();
   }
   ```

3. **Generate code:**
   ```bash
   dart run pigeon --input pigeons/device_info_api.dart
   ```

4. **Implement native handlers:**
   - Kotlin: implement generated `DeviceInfoApi` interface
   - Swift: implement generated `DeviceInfoApiProtocol`
   - Both: populate `DeviceInfoResult` từ native API (Build.MODEL, UIDevice.name, etc.)

5. **Flutter side:** Gọi `DeviceInfoApi().getDeviceInfo()` — fully typed, no strings.

### So sánh với Exercise 2

| Aspect | Ex2 (Raw) | Ex3 (Pigeon) |
|--------|-----------|-------------|
| Method call | `channel.invokeMethod('getBatteryLevel')` | `api.getDeviceInfo()` |
| Type safety | Runtime (string match) | Compile-time (generated interface) |
| Custom DTO | Manual Map serialization | Auto-generated codec |
| Boilerplate | Low (1 method) | Higher setup, lower per-method |

### Deliverable

Generated files + native implementations + Flutter usage demo.

```
<!-- AI_VERIFY: exercise-3-pigeon -->
✅ Pigeon definition với @HostApi + custom DTO
✅ Generated Dart/Kotlin/Swift files compile thành công
✅ Native implementations return real device info
✅ Flutter side gọi typed API — no string method names
```

<!-- AI_VERIFY: generation-complete -->
