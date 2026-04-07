# Code Walk — Platform Channels

> 📌 **Recap từ modules trước:**
> - **M0:** Dart basics, type system — codec serialization dựa trên Dart types ([M0 § Dart](../module-00-dart-primer/01-code-walk.md))
> - **M1:** `WidgetsFlutterBinding` — bootstrap layer nơi platform channel messages được dispatch ([M1 § Entrypoint](../module-01-app-entrypoint/01-code-walk.md))
> - **M3:** Config/Constants — environment-specific values có thể truyền qua channel ([M3 § Config](../module-03-common-layer/01-code-walk.md))
>
> Nếu chưa nắm vững → quay lại module tương ứng trước.

---

## Walk Order

```
ios/Runner/AppDelegate.swift (FlutterMethodChannel — iOS native side)
    ↓
ios/Runner/SceneDelegate.swift (FlutterEngine lifecycle)
    ↓
android/app/src/main/kotlin/jp/flutter/app/MainActivity.kt (Android entry)
    ↓
android/...GeneratedPluginRegistrant.java (how plugins register channels)
    ↓
lib/data_source/preference/app_preferences.dart (FlutterSecureStorage — plugin ≈ channel wrapper)
    ↓
lib/common/helper/local_push_notification_helper.dart (notification channel — plugin pattern)
```

Bắt đầu từ **iOS native side** (real MethodChannel) → **Android side** (FlutterEngine + plugin registration) → **Flutter side** (plugins sử dụng platform channels internally).

---

## 1. iOS MethodChannel — AppDelegate.swift

<!-- AI_VERIFY: base_flutter/ios/Runner/AppDelegate.swift -->

> 💡 **FE Perspective**
> **Flutter:** `FlutterMethodChannel` gắn với `FlutterEngine` — binary protocol qua platform thread.
> **React/Vue tương đương:** JavaScript bridge trong WebView (`window.webkit.messageHandlers`). React Native `NativeModules.MyModule.method()`.
> **Khác biệt quan trọng:** Flutter dùng binary codec (nhanh). React Native legacy dùng JSON serialization (chậm hơn).

> 💡 **Cho FE Developer**: Bạn KHÔNG cần master Swift/Kotlin — focus vào **MethodChannel pattern** (cách Flutter giao tiếp với native), không phải syntax chi tiết của ngôn ngữ native.

### Structural Overview

```
AppDelegate (FlutterAppDelegate)
├── flutterEngine — shared FlutterEngine instance
├── application(didFinishLaunchingWithOptions)
│   ├── flutterEngine.run()
│   ├── FirebaseApp.configure()
│   └── GeneratedPluginRegistrant.register(with: engine)
└── didInitializeImplicitFlutterEngine — MethodChannel setup
    └── FlutterMethodChannel(name: "jp.flutter.app")
        └── setMethodCallHandler → "clearBadgeCount"
```

### Real MethodChannel trong codebase

```swift
// AppDelegate.swift L26-38
let notificationChannel = FlutterMethodChannel(
  name: "jp.flutter.app",
  binaryMessenger: engine.applicationRegistrar.messenger()
)
notificationChannel.setMethodCallHandler({
  (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
  if call.method == "clearBadgeCount" {
    clearBadgeCount()
    result(nil)
  } else {
    result(FlutterMethodNotImplemented)
  }
})
```

**Phân tích flow:**

1. **Channel name:** `"jp.flutter.app"` — unique identifier. Flutter side và native side PHẢI dùng **cùng string**. Convention: reverse domain notation.
2. **binaryMessenger:** Transport layer. `FlutterEngine` cung cấp messenger — binary protocol qua platform thread.
3. **setMethodCallHandler:** Native **lắng nghe** call từ Flutter. Pattern: `switch` trên `call.method` string.
4. **FlutterResult:** Callback trả kết quả về Flutter. `result(nil)` = success void. `FlutterMethodNotImplemented` = method không tồn tại.

**clearBadgeCount implementation (iOS specific):**
```swift
// AppDelegate.swift L44-52
func clearBadgeCount() {
  DispatchQueue.main.async {
    UIApplication.shared.applicationIconBadgeNumber = 0
  }
}
```

API này **chỉ tồn tại trên iOS** — `applicationIconBadgeNumber` là UIKit API. Đây chính là lý do cần platform channel: Flutter không có API trực tiếp để clear iOS badge.

---

## 2. FlutterEngine Lifecycle — SceneDelegate.swift

<!-- AI_VERIFY: base_flutter/ios/Runner/SceneDelegate.swift -->

```swift
// SceneDelegate.swift L16-25
guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
  fatalError("AppDelegate not found")
}
let flutterEngine = appDelegate.flutterEngine

self.window = UIWindow(windowScene: windowScene)
let flutterViewController = FlutterViewController(
  engine: flutterEngine,
  nibName: nil,
  bundle: nil
)
```
<!-- END_VERIFY -->

→ [Mở file gốc: `ios/Runner/SceneDelegate.swift`](../../base_flutter/ios/Runner/SceneDelegate.swift)

**Key insight:** `FlutterEngine` được tạo ở `AppDelegate`, share sang `SceneDelegate`. Engine là **host** cho tất cả platform channels — mọi message đi qua engine's binary messenger.

> 💡 **FE Perspective**
> **Flutter:** `FlutterEngine` là host cho tất cả platform channels — chạy isolated Dart VM.
> **React/Vue tương đương:** WebView instance chứa JavaScript runtime. React Native `Bridge` (hoặc `JSI` trong new architecture).
> **Khác biệt quan trọng:** Flutter engine render trực tiếp pixel. WebView/React Native render qua platform UI components.

---

## 3. Android Entry — MainActivity.kt

<!-- AI_VERIFY: base_flutter/android/app/src/main/kotlin/jp/flutter/app/MainActivity.kt -->

```kotlin
// MainActivity.kt
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `android/app/src/main/kotlin/jp/flutter/app/MainActivity.kt`](../../base_flutter/android/app/src/main/kotlin/jp/flutter/app/MainActivity.kt)

Hiện tại **không có custom MethodChannel** trên Android side. Nếu muốn thêm, override `configureFlutterEngine`:

```kotlin
// Pattern: thêm MethodChannel vào Android
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "jp.flutter.app")
        .setMethodCallHandler { call, result ->
            when (call.method) {
                "clearBadgeCount" -> {
                    // Android badge API (ShortcutBadger hoặc NotificationManager)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
}
```

> **So sánh iOS vs Android:** Cùng channel name `"jp.flutter.app"`, cùng method `"clearBadgeCount"` — Flutter side gọi **một lần**, platform tự route đến native handler tương ứng.

---

## 4. Plugin Registration — GeneratedPluginRegistrant

<!-- AI_VERIFY: base_flutter/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java -->

```java
// GeneratedPluginRegistrant.java (auto-generated)
public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    flutterEngine.getPlugins().add(new FlutterFirebaseMessagingPlugin());
    flutterEngine.getPlugins().add(new FlutterLocalNotificationsPlugin());
    flutterEngine.getPlugins().add(new FlutterSecureStoragePlugin());
    flutterEngine.getPlugins().add(new SharedPreferencesPlugin());
    flutterEngine.getPlugins().add(new SqflitePlugin());
    // ... 15+ plugins
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`](../../base_flutter/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java)

**Mỗi plugin = MethodChannel wrapper.** Khi bạn dùng `flutter_secure_storage` trong Dart, bên dưới nó gọi `MethodChannel('plugins.it_nomads.com/flutter_secure_storage')` → native handler trên Android (KeyStore) hoặc iOS (Keychain).

File này **auto-generated** bởi Flutter toolchain (`flutter pub get`). Không edit trực tiếp.

---

## 5. Plugin Consumer Pattern — AppPreferences

<!-- AI_VERIFY: base_flutter/lib/data_source/preference/app_preferences.dart -->

```dart
// app_preferences.dart L16-21
_secureStorage = const FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,   // Android: EncryptedSharedPreferences
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,  // iOS: Keychain
  ),
);
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/data_source/preference/app_preferences.dart`](../../base_flutter/lib/data_source/preference/app_preferences.dart)

**Đây là cách platform channel hoạt động "ngầm":** Flutter code gọi `_secureStorage.write(key: 'token', value: jwt)` → plugin internally: `MethodChannel.invokeMethod('write', {...})` → Android: `EncryptedSharedPreferences` → iOS: `SecItemAdd` (Keychain API).

> 💡 **FE Perspective**
> **Flutter:** Plugin pattern: `FlutterSecureStorage` internally dùng `MethodChannel` → Android `EncryptedSharedPreferences` / iOS `Keychain`.
> **React/Vue tương đương:** Cordova/Capacitor plugin (`cordova-plugin-secure-storage`). React Native: `react-native-keychain`.
> **Khác biệt quan trọng:** Flutter plugin auto-register qua `GeneratedPluginRegistrant`. Cordova cần `config.xml` manual.

---

## 6. Notification Platform Specifics — local_push_notification_helper.dart

<!-- AI_VERIFY: base_flutter/lib/common/helper/local_push_notification_helper.dart -->

```dart
// local_push_notification_helper.dart L83-116
final androidPlatformChannelSpecifics = AndroidNotificationDetails(
  'channel_id', 'channel_name',
  importance: Importance.max,
  priority: Priority.high,
);
const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
final platformChannelSpecifics = NotificationDetails(
  android: androidPlatformChannelSpecifics,
  iOS: iOSPlatformChannelSpecifics,
);
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/common/helper/local_push_notification_helper.dart`](../../base_flutter/lib/common/helper/local_push_notification_helper.dart)

**"Platform channel" ở đây có 2 nghĩa:**
1. **Android Notification Channel** — OS-level concept (Android 8.0+) để group notifications
2. **Flutter Platform Channel** — transport mechanism bên dưới `flutter_local_notifications` plugin

Plugin dùng `MethodChannel` internally để gọi `NotificationManager.notify()` (Android) và `UNUserNotificationCenter.add()` (iOS). Tên "channel" trong `AndroidNotificationDetails` khác với `MethodChannel` — dễ nhầm lẫn.

---

## Summary — Platform Channel Patterns trong Codebase

| Layer | File | Channel Type | Purpose |
|-------|------|-------------|---------|
| iOS Native | `AppDelegate.swift` | `FlutterMethodChannel` explicit | clearBadgeCount |
| Android Native | `MainActivity.kt` | (none — extensible) | — |
| Plugin Registration | `GeneratedPluginRegistrant` | Auto-generated | 15+ plugin channels |
| Flutter Plugin | `app_preferences.dart` | Implicit via `FlutterSecureStorage` | Keychain/KeyStore |
| Flutter Plugin | `local_push_notification_helper.dart` | Implicit via `flutter_local_notifications` | OS notification API |

### Key Takeaway

Codebase này có **1 explicit MethodChannel** (iOS clearBadgeCount) và **15+ implicit channels** qua plugins. Dev ít khi viết raw platform channel — dùng plugin package thay thế. Nhưng hiểu channel mechanism giúp debug khi plugin fail hoặc cần custom native integration.

> 💡 **FE Perspective Summary:**
> | Flutter | Frontend |
> |---------|----------|
> | `MethodChannel` | WebView `postMessage` / React Native `NativeModules` |
> | `FlutterEngine` | WebView JS runtime / RN Bridge (JSI) |
> | Plugin package | Cordova/Capacitor plugin / RN native module |
> | `GeneratedPluginRegistrant` | Cordova `plugin.xml` auto-registration |

<!-- AI_VERIFY: generation-complete -->
