# Code Walk — Push Notification & Deep Linking

> 📌 **Recap từ modules trước:**
> - **M5:** `AppNavigator`, route guards — navigation target khi handle push/deep link ([M5 § Navigation](../module-05-navigation/01-code-walk.md))
> - **M12:** `AppApiService` — HTTP layer, token gửi kèm device registration ([M12 § API](../module-12-data-layer/01-code-walk.md))
> - **M13:** Interceptor chain — error handling khi register/unregister token ([M13 § Error](../module-13-middleware-interceptor-chain/01-code-walk.md))
> - **MA:** Platform channels — FCM plugin dùng MethodChannel + EventChannel internally ([MA § Channels](../module-optional-A-platform-channels/01-code-walk.md))
>
> Nếu chưa nắm vững → quay lại module tương ứng trước.

---

## Walk Order

```
firebase_messaging_service.dart → local_push_notification_helper.dart → deep_link_helper.dart → notification_data.dart
```

FCM service (source) → Local notification (display + route) → Deep link (URI nav) → Data model (glue).

---

## 1. FirebaseMessagingService — FCM Gateway

<!-- AI_VERIFY: base_flutter/lib/data_source/firebase/messaging/firebase_messaging_service.dart -->

> 💡 **FE Perspective**
> **Flutter:** `FirebaseMessagingService` expose streams: `onMessage` (foreground), `onMessageOpenedApp` (background tap), `initialMessage` (terminated).
> **React/Vue tương đương:** Service Worker `push` event handler. `getToken()` ≈ `PushManager.subscribe()`. OneSignal `getDeviceState().userId`.
> **Khác biệt quan trọng:** Flutter có 3 APIs cho 3 app states. Web chỉ phân biệt Service Worker vs page context.

### Structural Overview

```
FirebaseMessagingService (@LazySingleton)
├── deviceToken / onTokenRefresh   — FCM registration token + rotation stream
├── onMessage / onMessageOpenedApp — foreground / background tap streams
├── initialMessage                 — terminated → launch (Future, 1 lần)
├── deleteToken()                  — unregister device
└── subscribeToTopic() / unsubscribeFromTopic()
```

### Token Management

```dart
// firebase_messaging_service.dart L15-24
Future<String?> get deviceToken async {
  try {
    final deviceToken = await _messaging.getToken();
    return deviceToken;
  } catch (e) {
    Log.e('Error getting device token: $e');
    return null;
  }
}
```

**Phân tích:** `getToken()` trả về FCM registration token — **unique per device + app instance**. try/catch vì có thể fail (no network, Play Services missing). `onTokenRefresh` stream giúp sync token mới khi FCM rotate.

> ⚠️ **Gotcha:** Token refresh **không** có guaranteed timing. PHẢI listen `onTokenRefresh` và update server-side, nếu không push fail silently.

### Message Streams — 3 trạng thái app

```dart
// firebase_messaging_service.dart L27-31
Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;
Future<RemoteMessage?> get initialMessage => _messaging.getInitialMessage();
```

**3 scenarios nhận push:**

| Trạng thái app | API | Behavior |
|----------------|-----|----------|
| **Foreground** | `onMessage` | Stream fires, app quyết định hiển thị notification hay không |
| **Background** | `onMessageOpenedApp` | User tap notification → app mở → stream fires |
| **Terminated** | `initialMessage` | User tap notification → app launch → Future resolves 1 lần |

> 💡 **FE Perspective**
> **Flutter:** 3 app states cho push: `onMessage` (foreground), `onMessageOpenedApp` (background tap), `initialMessage` (terminated).
> **React/Vue tương đương:** Service Worker `push` event (foreground) vs `notificationclick` (background/terminated). OneSignal: `onReceived` vs `onOpened`.
> **Khác biệt quan trọng:** Flutter phân biệt 3 states rõ ràng với APIs riêng. Web chỉ có Service Worker vs page context.

### Background Message Handler

Khi app ở background hoặc terminated, Firebase gọi handler ở top-level (bên ngoài class):

> ⚠️ **Lưu ý**: Code background handler dưới đây là **standard pattern khuyến nghị** — hiện CHƯA CÓ trong `base_flutter`. Bạn sẽ thêm vào khi implement push notification.

```dart
// ⚠️ PHẢI là top-level function, KHÔNG phải method của class
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Xử lý message (lưu local DB, update badge, etc.)
  // ⚠️ KHÔNG dùng BuildContext, Navigator, hoặc any UI code ở đây
  debugPrint('Background message: ${message.messageId}');
}

void main() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}
```

> 🔗 **FE Perspective**: Tương tự Service Worker trong web — code chạy trong isolate riêng, không access được DOM (hay widget tree trong Flutter).

### Topic Subscription & DI

```dart
// firebase_messaging_service.dart L37-45
Future<void> subscribeToTopic(String topic) async {
  await _messaging.subscribeToTopic(topic);
}
```

**Topic messaging** cho phép gửi push tới **group of devices** mà không cần biết individual token. Server gửi 1 API call tới FCM topic thay vì N calls cho N tokens.

**DI:** `@LazySingleton()` + Riverpod `Provider` — dual registration pattern nhất quán với các service khác trong codebase.

---

## 2. LocalPushNotificationHelper — Display & Routing

<!-- AI_VERIFY: base_flutter/lib/common/helper/local_push_notification_helper.dart -->

> 💡 **FE Perspective**
> **Flutter:** `FlutterLocalNotificationsPlugin` hiển thị notification với platform-specific config. Callback injection cho navigation.
> **React/Vue tương đương:** Web `Notification` API (`new Notification(title, { body, icon })`). React Native `PushNotificationIOS.addNotificationRequest()`.
> **Khác biệt quan trọng:** Flutter cần separate config cho Android (channel) và iOS (Darwin). Web Notification API thống nhất cross-browser.

### Structural Overview

```
LocalPushNotificationHelper (@LazySingleton)
├── _packageHelper          — inject PackageHelper (app id, app name)
├── channelId / channelName — derived from app package info
├── init(onNavigate)        — setup plugin + create Android channel
│   ├── AndroidInitializationSettings(_androidDefaultIcon)
│   ├── DarwinInitializationSettings(request*: false)
│   └── createNotificationChannel(high importance)
├── onSelectNotification()  — parse payload JSON → navigate
├── notify(NotificationData)— download image → show notification
└── cancelAll()             — clear all notifications
```

### Initialization — Platform-Specific Config

```dart
// local_push_notification_helper.dart L31-59
Future<void> init(Future<void> Function(String) onNavigate) async {
  const androidInit = AndroidInitializationSettings(_androidDefaultIcon);
  const iOSInit = DarwinInitializationSettings(
    requestAlertPermission: false,  // dùng firebase_messaging request thay thế
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await FlutterLocalNotificationsPlugin().initialize(
    InitializationSettings(android: androidInit, iOS: iOSInit),
    onDidReceiveNotificationResponse: (details) =>
        onSelectNotification(details, onNavigate),
  );
  // Android 8.0+ bắt buộc notification channel
  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(AndroidNotificationChannel(
        channelId, channelName, description: channelDescription,
        importance: Importance.high,  // heads-up notification
      ));
}
```

**Key points:**
1. **`DarwinInitializationSettings(request*: false)`** — dùng `firebase_messaging` request permission thống nhất. Tránh double-prompt.
2. **`onDidReceiveNotificationResponse`** — callback khi user **tap** notification → bridge tới navigation.
3. **`createNotificationChannel`** — chỉ có effect lần đầu. Sau đó user control importance trong Settings.

### Notification Tap → Navigation

```dart
// local_push_notification_helper.dart L62-73
static void onSelectNotification(
  NotificationResponse payload, void Function(String) onNavigate,
) {
  if (payload.payload == null || payload.payload!.isEmpty) return;
  final data = safeCast<Map<String, dynamic>>(jsonDecode(payload.payload!)) ?? {};
  final conversationId = safeCast<String>(data['conversation_id']) ?? '';
  onNavigate(conversationId);
}
```

**Flow:** Tap → parse JSON payload → extract `conversation_id` → `onNavigate(id)` → `AppNavigator` push route. `onNavigate` là **callback injection** — helper không biết navigation logic.

### Show Notification

`notify(NotificationData)` flow: download image URL → `BigPictureStyleInformation` (Android expanded style) → `FlutterLocalNotificationsPlugin().show()` với `_randomNotificationId` (unique per notification, fixed ID = replace cũ). iOS dùng `DarwinNotificationDetails()` đơn giản.

---

## 3. DeepLinkHelper — URI-Based Navigation

<!-- AI_VERIFY: base_flutter/lib/common/helper/deep_link_helper.dart -->

> 💡 **FE Perspective**
> **Flutter:** `AppLinks` package abstract URI handling thành `stringLinkStream`. Guard logic check authentication trước khi navigate.
> **React/Vue tương đương:** `react-router` deep linking + `Linking.addEventListener('url')` (React Native). `window.addEventListener('popstate')`.
> **Khác biệt quan trọng:** Flutter cần `StreamSubscription` + dispose. React cần `removeEventListener` trong cleanup.

### Structural Overview

```
DeepLinkHelper (@LazySingleton)
├── _navigator          — AppNavigator (injected)
├── _appPreferences     — AppPreferences (login state check)
├── appLinks            — AppLinks() instance
├── _appLinksSubscription — StreamSubscription<String>
├── listenToDeepLinks() — subscribe stringLinkStream → handle URIs
└── dispose()           — cancel subscription
```

### Deep Link Listening & Dispose

```dart
// deep_link_helper.dart L30-41
void listenToDeepLinks() {
  _appLinksSubscription = appLinks.stringLinkStream.listen((event) {
    if (event == Constant.resetPasswordLink && !_appPreferences.isLoggedIn) {
      _navigator.replaceAll([const LoginRoute()]);
    }
  });
}

void dispose() {
  _appLinksSubscription?.cancel();
}
```

**Phân tích:**
1. **`stringLinkStream`** — Stream lắng nghe URI từ OS. Hoạt động khi app running (foreground/background).
2. **Guard logic** — Check `!isLoggedIn` trước khi navigate. Deep link guard tương tự route guard trong M5.
3. **`replaceAll`** — Clear navigation stack → push `LoginRoute`. Back button không quay về screen trước.
4. **Dispose** — `StreamSubscription` PHẢI cancel. Nếu không → memory leak.

**DI:** Injectable resolve `AppNavigator` + `AppPreferences` qua getIt (`@LazySingleton`).

---

## 4. NotificationData — Bridge Model

<!-- AI_VERIFY: base_flutter/lib/model/api/notification_data.dart -->

```dart
@freezed
sealed class NotificationData with _$NotificationData {
  const factory NotificationData({
    @Default('') String title,
    @Default('') String body,
    @Default('') String image,
  }) = _NotificationData;

  factory NotificationData.fromJson(Map<String, dynamic> json) => _$NotificationDataFromJson(json);

  factory NotificationData.from(RemoteMessage? data) {
    return NotificationData(
      title: data?.notification?.title ?? '',
      body: data?.notification?.body ?? '',
      image: safeCast<String>(data?.data['image']) ?? '',
    );
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc: `lib/model/api/notification_data.dart`](../../base_flutter/lib/model/api/notification_data.dart)

**Key points:** Freezed model (immutable). **Dual factory** — `fromJson` (API) + `from(RemoteMessage)` (FCM push). `@Default('')` → non-null fields, simplify downstream.

---

## Full Push Flow — End to End

```
Server gửi FCM message
    ↓
FCM SDK nhận (platform channel internally)
    ↓
┌─ App foreground: onMessage stream fires
│   → NotificationData.from(remoteMessage)
│   → localPushNotificationHelper.notify(notificationData)
│   → User thấy heads-up notification
│   → User tap → onSelectNotification → parse payload → onNavigate
│
├─ App background: onMessageOpenedApp stream fires
│   → Tương tự foreground nhưng app đã có state
│
└─ App terminated: initialMessage returns RemoteMessage
    → Xử lý 1 lần khi app launch
```

---

## Tổng kết

| File | Responsibility | Key Pattern |
|------|---------------|-------------|
| `FirebaseMessagingService` | FCM gateway | `@LazySingleton`, stream-based API |
| `LocalPushNotificationHelper` | Display + routing | Callback injection, platform config |
| `DeepLinkHelper` | URI → navigation | Stream subscription + guard logic |
| `NotificationData` | Data bridge | Freezed, dual factory |

→ Tiếp theo: [02-concept.md](./02-concept.md) — 6 concepts lý thuyết.

<!-- AI_VERIFY: generation-complete -->
