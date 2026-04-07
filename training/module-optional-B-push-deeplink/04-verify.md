# Verify — Push Notification & Deep Linking

> Checklist xác nhận hoàn thành Optional Module B. Đánh dấu ✅ khi done.

---

## 1. Self-Assessment Quiz (5 câu — trả lời không mở source code)

### Q1. FCM Message Types
**Q:** App đang ở **foreground** trên Android. FCM gửi **notification message** (có `notification` field). Điều gì xảy ra?

| | Đáp án |
|---|--------|
| A) | Hệ thống tự hiển thị notification trên system tray |
| B) | `onMessage` stream nhận message nhưng **không** tự hiển thị notification — phải dùng `flutter_local_notifications` |
| C) | Message bị drop hoàn toàn, chỉ nhận khi background |
| D) | FCM SDK tự show in-app banner |

### Q2. FCM Token Lifecycle
**Q:** Khi nào FCM device token bị **thay đổi**?

| | Đáp án |
|---|--------|
| A) | Mỗi lần app mở |
| B) | Khi user uninstall rồi reinstall app, restore trên device mới, hoặc user xóa app data |
| C) | Chỉ khi developer gọi `deleteToken()` thủ công |
| D) | Token không bao giờ thay đổi sau khi tạo lần đầu |

### Q3. Deep Link Types
**Q:** Universal Links (iOS) khác Custom URI Scheme ở điểm nào **quan trọng nhất**?

| | Đáp án |
|---|--------|
| A) | Universal Links nhanh hơn 10x |
| B) | Universal Links yêu cầu **domain verification** (apple-app-site-association file) → chỉ app owner mới claim được |
| C) | Custom URI Scheme hỗ trợ nhiều platform hơn |
| D) | Universal Links không cần config trong Xcode |

### Q4. Background Message Handling
**Q:** `FirebaseMessaging.onBackgroundMessage(handler)` có ràng buộc gì?

| | Đáp án |
|---|--------|
| A) | Handler có thể dùng mọi plugin và singleton bình thường |
| B) | Handler phải là **top-level function**, chạy trên **separate isolate** — không access được app state/DI |
| C) | Handler chỉ chạy trên iOS, Android không hỗ trợ |
| D) | Handler chạy trên main isolate nhưng ở priority thấp |

### Q5. Notification Routing
**Q:** User tap notification khi app đang **terminated**. Flow đúng để navigate đến đúng screen là gì?

| | Đáp án |
|---|--------|
| A) | `onMessageOpenedApp` stream fire ngay → navigate |
| B) | `getInitialMessage()` lấy pending message khi app khởi động → parse payload → navigate sau khi app initialized |
| C) | Không thể xử lý — user phải mở app thủ công |
| D) | FCM SDK tự navigate dựa trên payload `click_action` |

### Đáp án

| Câu | Đáp án | Giải thích ngắn |
|-----|--------|-----------------|
| Q1 | **B** | Foreground: FCM SDK **không** tự hiển thị notification. `onMessage` nhận data → developer phải dùng `flutter_local_notifications` để show. |
| Q2 | **B** | Token thay đổi khi reinstall, restore device, hoặc clear app data. Cần listen `onTokenRefresh` và gửi token mới lên server. |
| Q3 | **B** | Universal Links yêu cầu AASA file trên domain → verified ownership. Custom URI scheme (`myapp://`) bất kỳ app nào cũng có thể register. |
| Q4 | **B** | Background handler chạy trên separate isolate → top-level function, không access app state, DI, hoặc một số plugins. |
| Q5 | **B** | Terminated state: `getInitialMessage()` trả về message đã trigger open. Phải gọi sau app init, parse payload, rồi navigate. |

### Scoring Rubric

| Điểm | Mức độ | Hành động |
|------|--------|-----------|
| 5/5 | ✅ Xuất sắc | Hiểu sâu push notification & deep linking — chuyển tiếp |
| 4/5 | ✅ Đạt | Nắm vững core concepts — review câu sai |
| 3/5 | ⚠️ Cần ôn | Đọc lại [02-concept.md](./02-concept.md) sections tương ứng |
| ≤2/5 | ❌ Chưa đạt | Đọc lại toàn bộ concept + code walk trước khi làm exercise |

---

## 2. Code Walk Verification

```
<!-- AI_VERIFY: code-walk-checkpoint -->
[ ] Đọc FirebaseMessagingService — hiểu deviceToken, onTokenRefresh, 3 message streams
[ ] Đọc LocalPushNotificationHelper — hiểu init() flow, platform-specific config, onSelectNotification
[ ] Đọc DeepLinkHelper — hiểu stringLinkStream, guard logic, dispose pattern
[ ] Đọc NotificationData — hiểu dual factory (fromJson + from RemoteMessage)
[ ] Trace full flow: FCM → NotificationData → local notif → tap → navigate
```

## 3. Concept Comprehension

```
<!-- AI_VERIFY: concept-checkpoint -->
[ ] Giải thích FCM token lifecycle: getToken → onTokenRefresh → deleteToken
[ ] Phân biệt data message vs notification message — behavior khác nhau theo app state
[ ] Mô tả tại sao cần flutter_local_notifications khi foreground (FCM SDK không tự hiển thị)
[ ] Giải thích Android notification channel: tạo 1 lần, user control importance
[ ] Mô tả notification routing flow: payload JSON → parse → extract ID → navigate
[ ] Phân biệt 3 loại deep link: custom URI scheme, Universal Links, App Links
[ ] Giải thích platform config: AndroidManifest intent-filter, Info.plist entitlements
```

## 4. Exercise Completion

```
<!-- AI_VERIFY: exercise-checkpoint -->
[ ] Ex1 ⭐: Flow report với ≥ 5 steps (file:line), data transformations, 3 câu hỏi
[ ] Ex2 ⭐⭐: TopicSubscriptionPage — 4 topics, SwitchListTile, persist state, error handling
[ ] Ex3 ⭐⭐⭐: DeepLinkRouter — ≥ 4 URI patterns, auth guard, push notification integration
```

## 5. FE Perspective Mapping

```
<!-- AI_VERIFY: fe-bridge-checkpoint -->
[ ] FirebaseMessagingService ↔ Web Push API (PushManager.subscribe)
[ ] FCM token ↔ PushSubscription.endpoint
[ ] onMessage/onMessageOpenedApp ↔ Service Worker push/notificationclick events
[ ] flutter_local_notifications ↔ Web Notification API / showNotification()
[ ] Android notification channel ↔ Chrome per-site notification settings
[ ] AppLinks.stringLinkStream ↔ react-router URL listening / popstate event
[ ] Universal Links ↔ PWA manifest scope + start_url
[ ] Topic messaging ↔ OneSignal segments
```

## 6. Backward Reference Check

```
<!-- AI_VERIFY: backward-ref-checkpoint -->
[ ] M5: AppNavigator — push/replaceAll dùng trong notification routing + deep link handling
[ ] M12: AppApiService — device token registration gửi qua HTTP layer
[ ] M13: Interceptor chain — error handling khi API calls fail (token registration)
[ ] MA: Platform channels — FCM plugin dùng MethodChannel/EventChannel internally
```

## 7. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Không handle `getInitialMessage()` cho terminated state | User tap notification khi app killed → navigate bị mất | Luôn check `getInitialMessage()` trong app init flow |
| 2 | Dùng `notification message` thay vì `data message` cho custom routing | iOS/Android xử lý khác nhau, payload bị strip khi background | Dùng **data-only message** + `flutter_local_notifications` để kiểm soát hoàn toàn |
| 3 | Background message handler access DI/singleton | Crash hoặc null — handler chạy trên **separate isolate** | Handler phải là top-level function, tự init dependencies nếu cần |
| 4 | Quên tạo Android notification channel trước khi show local notification | Notification không hiển thị trên Android 8+ (API 26+) | Tạo channel trong `LocalPushNotificationHelper.init()` với importance phù hợp |
| 5 | Deep link intent-filter thiếu `autoVerify="true"` (Android App Links) | Link mở browser thay vì app, hoặc show disambiguation dialog | Thêm `android:autoVerify="true"` + host `.well-known/assetlinks.json` |

---

## 8. Module Completion Criteria

Hoàn thành các mục dưới đây để pass Optional Module B:

- [ ] **C1:** Self-Assessment Quiz ≥ 4/5 đáp án đúng
- [ ] **C2:** Code Walk — tất cả checkpoints đã đánh dấu
- [ ] **C3:** Concept Comprehension — tất cả checkpoints đã đánh dấu
- [ ] **C4:** Exercise 1 ⭐ hoàn thành — flow report với ≥ 5 steps
- [ ] **C5:** Exercise 2 ⭐⭐ hoàn thành — TopicSubscriptionPage
- [ ] **C6:** _(Stretch goal)_ Exercise 3 ⭐⭐⭐ — DeepLinkRouter với auth guard
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

Hoàn thành Module B! Bạn đã nắm vững Push & Deep Link.

→ Tiến sang **[Module C — Isolates & Background Processing](../module-optional-C-isolates/)** để học concurrency patterns trong Dart.

<!-- AI_VERIFY: generation-complete -->
