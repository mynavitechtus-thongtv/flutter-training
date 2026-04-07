# Exercises — Push Notification & Deep Linking

> 📌 **Recap:** M5: AppNavigator, route guards | M8: Riverpod (AsyncNotifier) | M12: AppApiService | M13: interceptor chain | MA: Platform channels

---

## FCM Setup Reference

> 📦 Các bước setup FCM từ zero đến nhận notification (được chuyển từ [Concept file](./02-concept.md)):

```
1. Firebase Console → Create project (hoặc dùng project có sẵn)
2. flutterfire configure             ← CLI tự tạo firebase_options.dart + config files
3. flutter pub add firebase_core firebase_messaging
4. await Firebase.initializeApp()     ← Trong main() trước runApp()
5. FirebaseMessaging.instance.requestPermission()  ← iOS bắt buộc, Android 13+
6. final token = await FirebaseMessaging.instance.getToken()  ← Gửi token lên server
7. Setup handlers:
   ├── FirebaseMessaging.onMessage.listen()           ← Foreground
   ├── FirebaseMessaging.onMessageOpenedApp.listen()   ← Background tap
   └── FirebaseMessaging.instance.getInitialMessage()  ← Terminated tap
8. @pragma('vm:entry-point')
   Future<void> _backgroundHandler(RemoteMessage msg)  ← Background processing
   → FirebaseMessaging.onBackgroundMessage(_backgroundHandler)
```

> ⚠️ **iOS thêm:** Enable Push Notifications capability trong Xcode + upload APNs key lên Firebase Console.

---

## Exercise 1 ⭐ — Trace Push Notification Flow

**Mục tiêu:** Trace toàn bộ flow từ FCM message đến user thấy notification và navigate khi tap.

### Task

1. Mở `../../base_flutter/lib/data_source/firebase/messaging/firebase_messaging_service.dart`

2. Trace flow cho scenario **Foreground push** từ FCM message arrives → `onMessage` fires → `NotificationData.from()` → `notify()` → user tap → `onSelectNotification` → `onNavigate(conversationId)`

3. Viết **flow report** gồm:
   - File + line number cho mỗi bước
   - Data type chuyển đổi: `RemoteMessage` → `NotificationData` → `String payload` → `Map` → `String conversationId`
   - Identify background handler function (hint: top-level function)

4. Trả lời:
   - Khi app terminated, notification tap trigger API nào trong `FirebaseMessagingService`?
   - `_randomNotificationId` dùng để làm gì? Nếu dùng fixed ID thì sao?
   - Tại sao `DarwinInitializationSettings` set tất cả `request*Permission: false`?

### Deliverable

```
<!-- AI_VERIFY: ex1-flow-report -->
File: _____
Foreground flow: step 1 → step 2 → ... (file:line mỗi bước)
Data transformations: RemoteMessage → ??? → ??? → navigate
Background handler location: _____
Q1 answer: _____
Q2 answer: _____
Q3 answer: _____
```

### Acceptance Criteria

```
<!-- AI_VERIFY: ex1-criteria -->
- [ ] Trace đầy đủ ≥ 5 steps với file:line references
- [ ] Identify data type tại mỗi step chuyển đổi
- [ ] 3 câu hỏi trả lời chính xác
- [ ] Tìm được background handler registration
```

---

## Exercise 2 ⭐⭐ — Topic Subscribe/Unsubscribe UI

**Mục tiêu:** Tạo UI cho phép user subscribe/unsubscribe notification topics.

### Task

1. Tạo `TopicSubscriptionPage` trong feature folder phù hợp:
   ```
   lib/ui/page/topic_subscription/
   ├── topic_subscription_page.dart
   └── topic_subscription_view_model.dart
   ```

2. **ViewModel** (Riverpod) — quản lý list topics với name/isSubscribed. Gọi `subscribeToTopic`/`unsubscribeFromTopic`.

3. **UI:** `ListView` + `SwitchListTile` cho 4 predefined topics (`news`, `promotions`, `updates`, `alerts`). Toggle → subscribe/unsubscribe. Loading indicator, SnackBar on error.

4. **Persist:** Lưu `Set<String>` subscribed topics vào `SharedPreferences` (key: `subscribed_topics`). Load khi init, save sau mỗi toggle.

### Hints

- Inject `FirebaseMessagingService` qua `firebaseMessagingServiceProvider`
- Dùng `AsyncNotifier` cho topic state. Reference M8 (Riverpod) + M5 (navigation).

### Deliverable

```
<!-- AI_VERIFY: ex2-topic-subscription -->
Files created:
- [ ] topic_subscription_page.dart
- [ ] topic_subscription_view_model.dart
- [ ] Updated AppPreferences (nếu cần thêm getter/setter)
```

### Acceptance Criteria

```
<!-- AI_VERIFY: ex2-criteria -->
- [ ] 4 topics hiện thị với SwitchListTile
- [ ] Toggle gọi đúng subscribe/unsubscribe API
- [ ] State persist qua app restart (SharedPreferences)
- [ ] Loading indicator khi toggle
- [ ] Error handling với SnackBar
- [ ] ViewModel tách biệt khỏi UI logic
```

---

## Exercise 3 ⭐⭐⭐ — Deep Link Route Handler

**Mục tiêu:** Mở rộng `DeepLinkHelper` để handle nhiều deep link routes, không chỉ reset password.

### Task

1. **Define URI schema:** `https://app.example.com/chat/{id}` → ChatDetailRoute, `/profile/{id}` → ProfileRoute, `/reset-password?token=xxx` → LoginRoute, `myapp://notification/{id}` → NotificationDetailRoute

2. **Tạo `DeepLinkRouter`** — tách routing logic ra khỏi `DeepLinkHelper`:
   ```dart
   class DeepLinkRouter {
     final AppNavigator _navigator;
     final AppPreferences _appPreferences;
     /// Parse URI string → navigate. Return true nếu handled.
     bool handleDeepLink(String uri) { ... }
   }
   ```

3. **Route matching:** Parse `Uri`, match path segments, extract path/query parameters. Auth guard cho protected routes. Unknown route → log + return false.

4. **Update `DeepLinkHelper`** để dùng `DeepLinkRouter` trong `listenToDeepLinks()`.

5. **Push notification integration** — Nếu notification payload chứa `deep_link` key → feed URI vào `DeepLinkRouter`.

### Hints

Dùng `Uri.parse()` + `pathSegments` + `queryParameters`. Separate `_requiresAuth(String path)` method. Reference M5 `AppNavigator` API.

### Deliverable

```
<!-- AI_VERIFY: ex3-deep-link-router -->
Files:
- [ ] deep_link_router.dart (new)
- [ ] deep_link_helper.dart (updated)
- [ ] local_push_notification_helper.dart (updated onSelectNotification)
```

### Acceptance Criteria

```
<!-- AI_VERIFY: ex3-criteria -->
- [ ] DeepLinkRouter handle ≥ 4 URI patterns
- [ ] Path parameter extraction chính xác
- [ ] Query parameter extraction cho reset-password
- [ ] Auth guard cho protected routes
- [ ] Unknown route → log + return false
- [ ] Push notification deep link integration
- [ ] Existing reset-password flow vẫn hoạt động
```

---

## Tổng kết Exercises

| Ex | Difficulty | Skill practiced |
|----|-----------|-----------------|
| 1 ⭐ | Trace | Đọc code flow, data transformation, understand 3 app states |
| 2 ⭐⭐ | Build | Riverpod ViewModel, FCM topic API, SharedPreferences persist |
| 3 ⭐⭐⭐ | Architect | URI parsing, route matching, guard logic, module integration |

→ Tiếp theo: [04-verify.md](./04-verify.md) — checklist xác nhận hoàn thành.

<!-- AI_VERIFY: generation-complete -->
