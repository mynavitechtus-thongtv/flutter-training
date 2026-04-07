# Concepts — Push Notification & Deep Linking

> 📌 **Recap:** M5: AppNavigator, route guards | M12: AppApiService | M13: interceptor chain | MA: Platform channels
>
> Module này cover 6 concepts xoay quanh push notification flow và deep linking trong Flutter.

---

## Concept 1 — Firebase Cloud Messaging Architecture

> 💡 **FE Perspective**
> **Flutter:** FCM: registration token (unique per device), data vs notification message, background handler chạy trong isolate riêng.
> **React/Vue tương đương:** Web Push API (`PushManager` + VAPID keys). FCM token ≈ `PushSubscription.endpoint`. Topic ≈ OneSignal segments.
> **Khác biệt quan trọng:** FCM background handler chạy trong isolate riêng (không access UI/state). Service Worker cũng isolated nhưng khác API.

### FCM High-Level Flow

```
Your Server → FCM Server → APNs (iOS) / FCM Transport (Android) → Device
```

**Thành phần chính:**

1. **FCM Registration Token** — Unique identifier cho 1 device + 1 app instance. Token có thể thay đổi khi:
   - App restore trên device mới
   - User clear app data
   - App uninstall/reinstall
   - FCM rotation policy (không có fixed schedule)

2. **Data Message vs Notification Message:**
   - **Notification message** — FCM SDK tự hiển thị khi app background/terminated. Foreground thì app nhận stream.
   - **Data message** — App LUÔN nhận, cả foreground/background. App tự quyết định hiển thị.
   - **Cả hai** — Notification + data payload. Behavior phụ thuộc app state.

### FCM Setup Steps

> 🔧 FCM setup steps (từ zero đến nhận notification) → xem [Exercise file](./03-exercise.md#fcm-setup-reference)

3. **Background Handler** — top-level function, chạy trong **isolate riêng** (không access được app state, UI, singleton từ main isolate). `@pragma('vm:entry-point')` bắt buộc.

4. **Topic Messaging** — Subscribe device tới named topic. Server gửi 1 request → FCM fan-out tới tất cả subscribers. Max 2000 topics/device.

---

## Concept 2 — Local Notification Display

> 💡 **FE Perspective**
> **Flutter:** `flutter_local_notifications` hiển thị notification khi app foreground (FCM SDK không tự show). Android Notification Channel (API 26+).
> **React/Vue tương đương:** Web `Notification` API + `ServiceWorkerRegistration.showNotification()`. Chrome notification settings per-site.
> **Khác biệt quan trọng:** Android có "notification channel" (OS-level grouping) — không có direct Web equivalent. iOS dùng permission system khác.

### Tại sao cần Local Notification?

FCM **notification message** khi app ở foreground → SDK **KHÔNG** tự hiển thị. App nhận `RemoteMessage` qua `onMessage` stream nhưng user không thấy gì. `flutter_local_notifications` plugin giải quyết: app tạo local notification để hiển thị.

### Android Notification Channel (API 26+)

**Rules:** Channel tạo **1 lần**, user control importance trong Settings. App KHÔNG thể change sau khi tạo. Mỗi notification PHẢI gắn vào 1 channel (Android 8.0+). Codebase dùng `applicationId` làm `channelId` — 1 channel cho toàn app.

### iOS: không có "channel". Permission request 1 lần, user control alert style/sounds/badges trong Settings. iOS 12+ hỗ trợ provisional authorization (quiet notification không cần permission trước).

---

## Concept 3 — Notification Routing

> 💡 **FE Perspective**
> **Flutter:** Notification tap → parse payload JSON → extract data → `AppNavigator.push(route)`. Callback injection pattern.
> **React/Vue tương đương:** Service Worker `notificationclick` event → `clients.openWindow(url)`. OneSignal `setNotificationOpenedHandler`.
> **Khác biệt quan trọng:** `initialMessage` (app terminated) chỉ return 1 lần. Web PWA `notificationclick` cũng single-fire.

### Payload → Navigation Flow

```
User tap notification
    ↓
OS callback → onDidReceiveNotificationResponse
    ↓
onSelectNotification(NotificationResponse, onNavigate)
    ↓
Parse payload JSON → extract conversation_id
    ↓
onNavigate(conversationId) → AppNavigator push route
```

**Design decisions:**

1. **JSON payload** — `flutter_local_notifications` chỉ support `String` payload. Codebase encode Map → JSON string khi show, decode khi tap.
2. **Callback injection** — `onNavigate` inject từ caller. Helper không depend on routing layer → testable, flexible.
3. **Guard conditions** — Check payload != null trước khi parse. Defensive vì notification có thể không có payload.

> ⚠️ **Gotcha:** `initialMessage` (app terminated) chỉ return **1 lần**. Gọi lần 2 → `null`. Phải consume ngay trong startup.

---

## Concept 4 — Deep Linking với AppLinks

> 💡 **FE Perspective**
> **Flutter:** 3 loại deep link: Custom URI Scheme (`myapp://`), Universal Links (iOS), App Links (Android). `app_links` package abstract thành stream.
> **React/Vue tương đương:** `react-router` URL-based routing. Universal Links ≈ PWA manifest `start_url`. `stringLinkStream` ≈ `window.addEventListener('popstate')`.
> **Khác biệt quan trọng:** Mobile cần server-side verification (`apple-app-site-association`/`assetlinks.json`). Web URL routing không cần.

### 3 loại Deep Link

| Loại | Format | Ví dụ | Platform |
|------|--------|-------|----------|
| **Custom URI Scheme** | `myapp://path` | `myapp://chat/123` | iOS + Android |
| **Universal Links** | `https://domain.com/path` | `https://app.com/reset-password` | iOS |
| **App Links** | `https://domain.com/path` | `https://app.com/reset-password` | Android |

**Custom URI Scheme** — Đơn giản nhưng không verify ownership. Dùng cho internal navigation.

**Universal Links (iOS) / App Links (Android)** — HTTPS URL + server-side verification (`apple-app-site-association` / `assetlinks.json`). Chỉ verified owner mới handle được.

### AppLinks Package

Codebase dùng `app_links` package — abstract iOS (`NSUserActivity`) + Android (`Intent.ACTION_VIEW`) thành `stringLinkStream` thống nhất.

**Guard Logic:** Deep link handler PHẢI có authentication check, route validation, và state check (tránh duplicate push).

---

## Concept 5 — Push + Deep Link Integration Flow

> 💡 **FE Perspective**
> **Flutter:** Full flow: FCM → `FirebaseMessagingService` → `LocalPushNotificationHelper.notify()` → user tap → `AppNavigator.push()`.
> **React/Vue tương đương:** Web Push → Service Worker nhận push → `showNotification(data)` → user click → `clients.openWindow(url)`.
> **Khác biệt quan trọng:** Flutter có 3 app states (foreground/background/terminated) với APIs khác nhau. Web chỉ có Service Worker vs page.

### End-to-End Architecture

```
                         ┌──────────────┐
                         │  Your Server │
                         └──────┬───────┘
                                │ HTTP POST /send
                         ┌──────▼───────┐
                         │  FCM Server  │
                         └──────┬───────┘
                                │
                    ┌───────────┼───────────┐
                    │ APNs      │           │ FCM Transport
               ┌────▼────┐              ┌───▼────┐
               │   iOS   │              │Android │
               └────┬────┘              └───┬────┘
                    │                       │
         ┌──────────▼───────────────────────▼──────────┐
         │         FirebaseMessagingService             │
         │  onMessage / onMessageOpenedApp / initial   │
         └──────────┬──────────────────────────────────┘
                    │
         ┌──────────▼──────────────────────────────────┐
         │     NotificationData.from(remoteMessage)    │
         └──────────┬──────────────────────────────────┘
                    │
         ┌──────────▼──────────────────────────────────┐
         │  LocalPushNotificationHelper.notify(data)   │
         │  → show local notification with payload     │
         └──────────┬──────────────────────────────────┘
                    │ user tap
         ┌──────────▼──────────────────────────────────┐
         │  onSelectNotification → parse payload       │
         │  → onNavigate(conversationId)               │
         └──────────┬──────────────────────────────────┘
                    │
         ┌──────────▼──────────────────────────────────┐
         │  AppNavigator.push(destination)             │
         └─────────────────────────────────────────────┘
```

Push notification cũng có thể chứa deep link URL trong data payload. Hai approach:
1. **Direct navigation** — Parse `conversation_id` → push `ChatRoute(id)`. Codebase hiện dùng approach này.
2. **Via deep link system** — Parse `deep_link` URL → feed vào `DeepLinkHelper`. Reuse routing logic.

---

## Concept 6 — Platform-Specific Configuration

> 💡 **FE Perspective**
> **Flutter:** Platform config: `AndroidManifest.xml` (intent filter, FCM channel), `Info.plist` (background modes, entitlements).
> **React/Vue tương đương:** PWA `manifest.json` + Service Worker registration. Browser handle permissions trực tiếp.
> **Khác biệt quan trọng:** Mobile cần entitlements + signing. Android 13+ cần runtime permission `POST_NOTIFICATIONS`. Web không cần.

### Android Configuration

```xml
<!-- AndroidManifest.xml: FCM default channel + deep link intent filter -->
<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="@string/default_notification_channel_id" />
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" android:host="app.example.com" />
</intent-filter>
```

`autoVerify="true"` → Android verify domain qua `assetlinks.json`. `google-services.json` trong `android/app/`.

### iOS Configuration

- **Info.plist:** `UIBackgroundModes` → `remote-notification`. `FirebaseAppDelegateProxyEnabled` → `NO` nếu cần custom swizzling.
- **Entitlements:** `aps-environment` (dev/production), `com.apple.developer.associated-domains` → `applinks:domain.com`
- **GoogleService-Info.plist** — Firebase config, add vào Xcode project.

### Permissions

| Platform | Permission | When |
|----------|-----------|------|
| Android 13+ | `POST_NOTIFICATIONS` | Runtime permission |
| Android < 13 | Không cần | Auto-granted |
| iOS | Push notification | `requestPermission()` — 1 lần |

> ⚠️ **Best practice:** KHÔNG request permission ngay khi app launch. Giải thích value trước (onboarding screen) → conversion rate cao hơn.

---

## Concept Map

```
FCM Architecture ──→ Message Types ──→ App State Handling
       │                                      │
       ▼                                      ▼
Token Management              Local Notification Display
       │                                      │
       ▼                                      ▼
Topic Subscription              Notification Routing
                                              │
                                              ▼
                               Deep Link Integration
                                              │
                                              ▼
                              Platform-Specific Config
```

→ Tiếp theo: [03-exercise.md](./03-exercise.md) — 3 bài tập thực hành.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
