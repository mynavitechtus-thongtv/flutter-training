# Optional Module B — Push Notification & Deep Linking

> **Depth:** Advanced Survey — optional module, lighter scaffolding

---

## Mục tiêu

Sau module này, bạn sẽ:
- Hiểu Firebase Cloud Messaging architecture: token, topics, message types, 3 app states
- Trace full push flow: FCM → local notification → tap → navigate
- Nắm deep linking với AppLinks: URI scheme, Universal Links, App Links
- Kết nối push notification + deep link thành unified navigation flow

---

## Prerequisites

| Module | Cần nắm |
|--------|---------|
| **M5** | `AppNavigator`, route guards — navigation target cho push/deep link |
| **M12** | `AppApiService` — HTTP layer gửi device token lên server |
| **M13** | Interceptor chain — error handling khi register token |
| **MA** | Platform channels — FCM plugin dùng MethodChannel/EventChannel internally |

---

## Nội dung

| File | Nội dung | Thời lượng |
|------|----------|-----------|
| [01-code-walk.md](./01-code-walk.md) | FirebaseMessagingService, LocalPushNotificationHelper, DeepLinkHelper, NotificationData | ~30 min |
| [02-concept.md](./02-concept.md) | 6 concepts: FCM architecture, local notif, routing, deep link, integration flow, platform config | ~25 min |
| [03-exercise.md](./03-exercise.md) | 3 exercises: trace push flow → topic subscribe UI → deep link router | ~3-5 hrs |
| [04-verify.md](./04-verify.md) | Checklist xác nhận hoàn thành | ~10 min |

**Phân bố:** 🔴 ~33% · 🟡 ~50% · 🟢 ~17%

---

## Anchor Files

```
lib/data_source/firebase/messaging/firebase_messaging_service.dart   — FCM gateway (token, streams, topics)
lib/common/helper/local_push_notification_helper.dart                — Display + notification tap routing
lib/common/helper/deep_link_helper.dart                              — URI-based navigation (AppLinks)
lib/model/api/notification_data.dart                                 — Freezed model (RemoteMessage ↔ local notif)
```

---

## 💡 FE Perspective Summary

| Flutter | Frontend Equivalent |
|---------|-------------------|
| `FirebaseMessagingService` | Web Push API (`PushManager.subscribe`) |
| FCM token | `PushSubscription.endpoint` |
| `onMessage` / `onMessageOpenedApp` | Service Worker `push` / `notificationclick` events |
| `flutter_local_notifications` | Web `Notification` API / `showNotification()` |
| `AppLinks.stringLinkStream` | `react-router` URL listening / `popstate` event |
| Topic messaging | OneSignal segments |
| Universal Links / App Links | PWA manifest `scope` + `start_url` |

---

## Forward Reference

→ **Module Optional C: Isolates** — background handler trong FCM chạy trong isolate riêng, connect concepts từ module này.

<!-- AI_VERIFY: generation-complete -->
