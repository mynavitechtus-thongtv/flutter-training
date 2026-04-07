# Exercises — Thực hành Data Layer & API Integration

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 4](../module-04-exception-handling/) (DioExceptionMapper), [Module 7](../module-07-base-viewmodel/) (runCatching) và đọc xong [01-code-walk.md](./01-code-walk.md).

---

## ⭐ Exercise 1: Trace Full API Call Lifecycle

**Mục tiêu:** Trace toàn bộ flow từ ViewModel → AppApiService → RestApiClient → Server → Response decode → ViewModel nhận data.

### Hướng dẫn

1. Mở [app_api_service.dart](../../base_flutter/lib/data_source/api/app_api_service.dart).
2. Chọn method `getMe()`.
3. Trace từng bước, điền bảng bên dưới.

### Template

Điền bảng trace cho `getMe()`:

| # | Step | File | Code / Action |
|---|------|------|---------------|
| 1 | ViewModel gọi | `*_view_model.dart` | `ref.read(appApiServiceProvider).getMe()` |
| 2 | AppApiService delegate | `app_api_service.dart` | `_authAppServerApiClient.request<?, ?>(...)` |
| 3 | RestApiClient dispatch | `rest_api_client.dart` | `_requestByMethod(method: ?, path: ?)` |
| 4 | Dio executes | (internal) | `dio.get('v1/me', ...)` |
| 5 | Interceptor — request | `access_token_interceptor.dart` | `options.headers['Authorization'] = ?` |
| 6 | Server response | (network) | `200 OK + { "data": { "id": 1, ... } }` |
| 7 | Decoder | `base_success_response_decoder.dart` | `fromType(?) → mapToDataModel(?, decoder)` |
| 8 | Return | `app_api_service.dart` | `response?.data ?? const UserData()` |

**Câu hỏi:**
- Step 2: Generic types `<FirstOutput, FinalOutput>` là gì cụ thể cho `getMe()`?
- Step 5: Token lấy từ đâu? (`_appPreferences.accessToken` — encrypted hay plain?)
- Step 7: `SuccessResponseDecoderType` nào được dùng? Default hay override?
- Nếu server trả 401, flow khác thế nào từ step 6?

### ✅ Checklist hoàn thành
- [ ] Điền đủ 8 steps với giá trị cụ thể (không để `?`)
- [ ] Trả lời 4 câu hỏi
- [ ] Vẽ được diagram request/response flow (optional)

---

## ⭐ Exercise 2: Add New API Endpoint

**Mục tiêu:** Thêm method `getUsers()` vào `AppApiService` — trải nghiệm full pattern: chọn client, specify types, write decoder.

> 💡 **FE Perspective**
> **Flutter:** `RestApiClient` wrap Dio instance, `AppApiService` expose typed methods — pattern Service Facade giấu chi tiết HTTP.
> **React/Vue tương đương:** Wrap Axios instance + interceptors, API module export các functions.
> **Khác biệt quan trọng:** Flutter dùng generic decoder callback tại request level để type-safe response; FE thường parse response ở caller hoặc dùng zod schema.

### Hướng dẫn

**API spec:**
- **Endpoint:** `GET /v1/users?page={page}&limit={limit}`
- **Auth:** Required (cần Bearer token)
- **Response format:**
```json
{
  "data": [
    { "id": 1, "name": "John", "email": "john@example.com" },
    { "id": 2, "name": "Jane", "email": "jane@example.com" }
  ],
  "meta": { "page": 1, "limit": 10, "total": 50 }
}
```

**Step 1:** Xác định:
- Client nào? (`_noneAuthAppServerApiClient` hay `_authAppServerApiClient`?)
- Generic types? (`FirstOutput` = ?, `FinalOutput` = ?)
- `successResponseDecoderType`? (xem response format — có `data` + `meta` → ?)

**Step 2:** Viết method signature:

```dart
Future<PagingDataResponse<UserData>?> getUsers({
  required int page,
  required int limit,
}) async {
  // TODO: implement
}
```

**Step 3:** Implement body — tham khảo `getNotifications()` pattern:

```dart
return _???AppServerApiClient.request<UserData, PagingDataResponse<UserData>>(
  method: RestMethod.???,
  path: '???',
  queryParameters: {
    'page': page,
    'limit': limit,
  },
  successResponseDecoderType: SuccessResponseDecoderType.???,
  decoder: (json) => UserData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
);
```

**Step 4:** Review — so sánh implementation của bạn với `getNotifications()`. Có gì giống/khác?

### ✅ Checklist hoàn thành
- [ ] Chọn đúng client (`_authAppServerApiClient`)
- [ ] Generic types chính xác (`<UserData, PagingDataResponse<UserData>>`)
- [ ] `successResponseDecoderType: SuccessResponseDecoderType.paging`
- [ ] `decoder` callback đúng pattern
- [ ] `queryParameters` map đúng `page` + `limit`

---

## ⭐⭐ Exercise 3: Implement Secure Storage for New Data

**Mục tiêu:** Thêm encrypted storage cho `deviceId` vào `AppPreferences` — hiểu khi nào dùng encrypted vs plain storage.

### Hướng dẫn

**Requirement:** Lưu `deviceId` (string, unique per device). Cần persistent qua app restart. Cần secure vì device fingerprinting.

**Step 1:** Thêm key constant vào `AppPreferences`:

```dart
static const keyDeviceId = 'deviceId';
```

**Step 2:** Implement getter/setter — chọn storage tier:

```dart
// Option A: EncryptedSharedPreferences (như accessToken)
Future<void> saveDeviceId(String deviceId) async {
  await _encryptedSharedPreferences.setString(keyDeviceId, deviceId);
}

Future<String> get deviceId {
  return _encryptedSharedPreferences.getString(keyDeviceId);
}
```

```dart
// Option B: FlutterSecureStorage
Future<void> saveDeviceId(String deviceId) async {
  await _secureStorage.write(key: keyDeviceId, value: deviceId);
}

Future<String?> get deviceId async {
  return await _secureStorage.read(key: keyDeviceId);
}
```

**Step 3:** Quyết định — Option A hay B? Trả lời:
- `deviceId` có cần xóa khi logout? (`clearCurrentUserData` có include không?)
- `deviceId` persistence level: per-user hay per-device?
- Performance: `EncryptedSharedPreferences` vs `FlutterSecureStorage` — cái nào nhanh hơn?

**Step 4:** Nếu chọn **KHÔNG xóa** khi logout (per-device, not per-user), đảm bảo `clearCurrentUserData()` **KHÔNG** remove `keyDeviceId`.

### Câu hỏi thêm
- Nếu bạn cần lưu user's preferred language (`vi`, `en`, `ja`) — storage tier nào? Encrypted hay plain?
- Biometric auth token — storage tier nào? Tại sao?

### ✅ Checklist hoàn thành
- [ ] Thêm key constant
- [ ] Implement getter/setter với đúng storage tier
- [ ] Justify lựa chọn (tại sao encrypted, tại sao không xóa khi logout)
- [ ] Trả lời 2 câu hỏi thêm
- [ ] `clearCurrentUserData()` logic đúng (include hoặc exclude `keyDeviceId`)

---

## ⭐⭐ Exercise 4: Custom Response Decoder

**Mục tiêu:** Hiểu decoder pipeline bằng cách trace qua một response format mới và xác định decoder cần dùng.

### Hướng dẫn

**Scenario:** Backend team thay đổi API response format cho một endpoint mới:

```json
// GET /v2/dashboard
{
  "status": "success",
  "result": {
    "stats": { "total_users": 100, "active_users": 42 },
    "recent_activities": [
      { "id": 1, "action": "login", "timestamp": "2024-01-01T00:00:00Z" }
    ]
  }
}
```

→ Không dùng `"data"` key → `dataJsonObject` decoder KHÔNG hoạt động.

**Step 1:** Phân tích — decoder type nào phù hợp?

| Decoder Type | Match? | Lý do |
|-------------|--------|-------|
| `dataJsonObject` | ❌ | Expect `"data"` key, response dùng `"result"` |
| `jsonObject` | ✅/❌ | Parse toàn bộ JSON thành 1 object — nhưng cần custom model |
| `plain` | ❌ | Raw response, không decode |
| Custom | ? | Cần tự viết? |

**Step 2:** Approach — dùng `customSuccessResponseDecoder`:

```dart
Future<DashboardData> getDashboard() async {
  final response = await _authAppServerApiClient.request<DashboardData, DashboardData>(
    method: RestMethod.get,
    path: 'v2/dashboard',
    customSuccessResponseDecoder: (response) {
      final json = response.data as Map<String, dynamic>;
      final result = json['result'] as Map<String, dynamic>;
      return DashboardData.fromJson(result);
    },
  );
  return response ?? const DashboardData();
}
```

**Step 3:** Trả lời:
- Tại sao `customSuccessResponseDecoder` được ưu tiên hơn `decoder` callback?
  (Hint: xem thứ tự check trong `RestApiClient.request()`)
- Nếu có nhiều endpoints dùng `"result"` thay `"data"`, bạn sẽ tạo gì?
  (Hint: tham khảo `DataJsonObjectResponseDecoder` → tạo `ResultJsonObjectResponseDecoder`)
- Error handling: nếu `json['result']` là `null`, code trên throw gì?

### ✅ Checklist hoàn thành
- [ ] Phân tích đúng tại sao `dataJsonObject` không hoạt động
- [ ] Implement dùng `customSuccessResponseDecoder`
- [ ] Trả lời 3 câu hỏi
- [ ] Biết khi nào cần custom decoder vs existing decoder types

---

## ⭐⭐⭐ Exercise 5: AI Dojo — 🧩 API Integration Generation

### 🤖 AI Dojo — Generate Repository + Model từ API Spec

**Mục tiêu**: Mô tả API endpoint cho AI → AI sinh code data layer (model + API method + decoder) → review generated code.

**Bước thực hiện**:

1. Mô tả API endpoint cho AI kèm 1 file tham khảo pattern. Gửi prompt sau:

```
Tôi cần integrate API endpoint mới vào Flutter project. Đây là pattern hiện tại
từ AppApiService:

[PASTE 1 method từ app_api_service.dart — ví dụ getMe() hoặc getNotifications()]

Hãy generate code cho endpoint mới:
- GET /v1/products?category={category}&page={page}&limit={limit}
- Auth: Required (dùng _authAppServerApiClient)
- Response: { "data": [{ "id": 1, "name": "...", "price": 99.99, "category": "..." }],
  "meta": { "page": 1, "total": 50 } }

Generate:
1. ProductData model class (dùng json_serializable pattern từ project)
2. AppApiService method getProducts()
3. Decoder callback phù hợp
4. Optional: PagingExecutor nếu pattern match getNotifications
```

2. Review code AI sinh ra — check against codebase conventions:
   - Model dùng `@JsonSerializable()` đúng pattern?
   - Generic types `<FirstOutput, FinalOutput>` chính xác?
   - `successResponseDecoderType` đúng cho paging response?

3. So sánh: AI có tạo code consistent với existing codebase không? Adjust chỗ nào?

**✅ Tiêu chí đánh giá**:
- [ ] AI sinh model class compile-ready (hoặc gần ready sau minor fixes)
- [ ] AI chọn đúng decoder type cho paging response
- [ ] Bạn tìm ≥ 1 chỗ AI code **inconsistent** với codebase convention (naming, import path, etc.)
- [ ] Bạn adjust code AI sinh → match 100% với project pattern trước khi dùng

---

## Tổng kết Exercises

| # | Bài tập | Độ khó | Concept chính |
|---|---------|--------|--------------|
| 1 | Trace API Call Lifecycle | ⭐ | Full request flow understanding |
| 2 | Add New Endpoint | ⭐ | AppApiService method pattern |
| 3 | Secure Storage | ⭐⭐ | Storage tier selection, encryption |
| 4 | Custom Decoder | ⭐⭐ | Decoder pipeline, customSuccessResponseDecoder |
| 5 | AI Dojo — API Integration | ⭐⭐⭐ | Code generation, pattern matching |

→ Tiếp tục: [04-verify.md](./04-verify.md) — self-assessment và đáp án tham khảo.

<!-- AI_VERIFY: generation-complete -->
