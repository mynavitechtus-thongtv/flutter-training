# Verification — Kiểm tra kết quả Module 4

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được `AppException` contract: `message` + `action` abstract getters, `implements Exception` vs `extends`? | Exception Hierarchy | 🔴 |
| 2 | Tôi liệt kê được 4 subtypes và mỗi subtype dùng enum `kind` + switch exhaustive? | Typed Subtypes | 🔴 |
| 3 | Tôi trace được flow: `AppExceptionAction` → `ExceptionHandler.switch` → UI (snackbar/dialog/force logout)? | Action-Driven Handling | 🔴 |
| 4 | Tôi mô tả `DioExceptionMapper.map()` flow: `DioException` → `RemoteException` với idempotent check + fallback? | Exception Mapping | 🟡 |
| 5 | Tôi phân biệt 2 layers: `runZonedGuarded` (global) vs `Result.fromAsyncAction` (per-action) error catching? | Error Boundary | 🟡 |
| 6 | Tôi giải thích `Result.failure(AppException)` chỉ catch `on AppException`, let bugs bubble up? | Result Integration | 🟡 |
| 7 | Tôi hiểu `l10n` integration trong exception messages và error code convention (`UE-0x`, `FBA-xxx`)? | Localized Messages | 🟢 |

**Target:** 3/3 Yes cho 🔴 MUST-KNOW, tối thiểu 6/7 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace Exception Flow ⭐

- [ ] Bảng trace có đủ **5 steps** (Dio → Mapper → kind → action → UI)
- [ ] `SocketException` → `DioException(type: connectionError)` → `RemoteExceptionKind.network`
- [ ] Hoặc `DioException(type: unknown, error: SocketException)` → cũng `RemoteExceptionKind.network` (mapper check `exception.error is SocketException`)
- [ ] `RemoteExceptionKind.network` → `action = showDialogWithRetry`
- [ ] `ExceptionHandler` → `showDialogWithRetry` case → dialog với retry button (nếu `onRetry != null`) hoặc dialog thường

**Cross-check:** Mở [dio_exception_mapper.dart](../../base_flutter/lib/exception/exception_mapper/dio_exception_mapper.dart), verify `connectionError` case (line ~81) và `unknown` + `SocketException` check (line ~87).

**Bonus verification:** `HTTP 503` → `DioExceptionType.badResponse` → `HttpStatus.serviceUnavailable` check → `RemoteExceptionKind.serverMaintenance` → `action = showMaintenanceDialog` → non-cancelable `MaintenanceModeDialog`.

### Exercise 2 — Add ValidationExceptionKind ⭐

- [ ] Thêm `phoneNumberInvalid` vào enum → analyzer báo lỗi tại `switch (kind)` trong `message` getter
- [ ] Error message dạng: `"The type 'ValidationExceptionKind' is not exhaustively matched by the switch cases"`
- [ ] Fix bằng thêm case → analyzer pass
- [ ] Trả lời: `if/else` **không** có exhaustive check → compiler **không** báo lỗi khi thêm enum
- [ ] Trả lời: thêm `ValidationExceptionKind` → sửa **1 file** (validation_exception.dart) vì `action` fixed
- [ ] Trả lời: thêm `RemoteExceptionKind` → sửa **2+ places** (`message` switch + `action` switch + có thể `isForcedErrorToHandle`)
- [ ] **Đã revert changes**

### Exercise 3 — Create Exception Subtype ⭐⭐

- [ ] File location: `lib/exception/app_permission_exception.dart`
- [ ] Class `extends AppException` (không `implements`)
- [ ] Constructor: `required this.kind`, `super.rootException`, `super.onRetry`
- [ ] `toString()` bao gồm kind + `super.toString()`
- [ ] `action` override — `showDialog` hợp lý (user cần biết permission bị denied)
- [ ] `message` switch exhaustive trên 4 kinds

**Cross-check [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md):**

| Rule | Kiểm tra |
|------|----------|
| File name: snake_case | `app_permission_exception.dart` ✅ |
| Class name: PascalCase | `AppPermissionException` ✅ |
| Enum name: PascalCase | `AppPermissionExceptionKind` ✅ |
| Enum values: camelCase | `cameraPermissionDenied` ✅ |

**Rationale checks:**
- [ ] `action = showDialog` → hợp lý vì user cần thấy thông báo mở Settings
- [ ] Không cần sửa `ExceptionHandler` → `showDialog` case đã tồn tại → OCP respected
- [ ] Export via barrel file `index.dart` (hoặc exception barrel) → accessible toàn app
- [ ] `onRetry` có thể gắn callback mở app Settings → retry permission request

### Exercise 4 — Map Firebase Auth Error ⭐⭐

- [ ] Map đủ 5 error codes:

| Firebase `code` | `AppFirebaseAuthExceptionKind` |
|----------------|-------------------------------|
| `'invalid-email'` | `invalidEmail` |
| `'user-not-found'` | `userDoesNotExist` |
| `'wrong-password'` | `invalidLoginCredentials` |
| `'email-already-in-use'` | `usernameAlreadyInUse` |
| `'requires-recent-login'` | `requiresRecentLogin` |

- [ ] Fallback `_ =>` cho unknown Firebase error codes → `AppFirebaseAuthExceptionKind.unknown`
- [ ] Final fallback cho non-`FirebaseAuthException` input → `unknown`
- [ ] `rootException` passed through → original error preserved

**So sánh với `DioExceptionMapper`:**

| Tiêu chí | `DioExceptionMapper` | Firebase Auth mapper |
|----------|---------------------|---------------------|
| Input type | `DioException` (typed) | `FirebaseAuthException` (typed) |
| Discrimination | `DioExceptionType` enum | `code` String |
| Complexity | Deep nesting (badResponse) | Flat mapping |
| Idempotent check | `is RemoteException` | Không cần (khác type) |
| Implements interface | `AppExceptionMapper<RemoteException>` | Có thể standalone |

### Exercise 5 — AI Prompt Dojo ⭐⭐⭐

- [ ] AI output cover ≥ 4/6 tiêu chí
- [ ] AI nhận diện exhaustive switch (7 cases for 7 enum values)
- [ ] AI đánh giá forceLogout fallback (try/catch → navigate Login)
- [ ] AI **KHÔNG** suggest dùng generic `catch (e)` thay typed exceptions
- [ ] AI hiểu `AppExceptionAction` pattern (exception carries handling instruction)
- [ ] AI nhận xét testability — mock `Ref`, mock `appNavigatorProvider`

---

## 3. Concept Cross-Check 🔴

| # | Scenario | Đáp án đúng | Concept |
|---|----------|-------------|---------|
| 1 | `RemoteException(kind: timeout).action` = ? | `AppExceptionAction.showDialogWithRetry` | Action-Driven |
| 2 | Thêm `RemoteExceptionKind.rateLimited` → compile error ở đâu? | `message` switch + `action` switch trong `RemoteException` | Exhaustive Switch |
| 3 | `ValidationException.action` = gì, tại sao? | `doNothing` — caller (ViewModel) tự handle inline | Typed Subtypes |
| 4 | `DioExceptionMapper.map(exception: RemoteException(...))` → ? | Return input as-is (idempotent check) | Mapper Pattern |
| 5 | `Result.fromAsyncAction` catch `FormatException` (non-AppException) không? | ❌ Không — `on AppException catch` only → bubbles to `runZonedGuarded` | Error Boundary |
| 6 | `ExceptionHandler` nhận `AppUncaughtException` → switch case nào? | `doNothing` → `break` → chỉ `Log.e()` | Handler Dispatch |

---

## 4. Hierarchy Cross-Check

Xác nhận hiểu hierarchy qua bảng:

| Class | Extends | Kind enum | Kind count | Action | recordError |
|-------|---------|-----------|-----------|--------|-------------|
| `AppException` | — (abstract) | — | — | abstract | `false` |
| `RemoteException` | `AppException` | `RemoteExceptionKind` | 12 | varies per kind | `false` (default) |
| `ValidationException` | `AppException` | `ValidationExceptionKind` | 3 | `doNothing` | `false` |
| `AppFirebaseAuthException` | `AppException` | `AppFirebaseAuthExceptionKind` | 6 | `doNothing` | `false` |
| `AppUncaughtException` | `AppException` | — (no enum) | 0 | `doNothing` | `false` |

**Kiểm tra:**
- [ ] Tất cả 4 subtypes `extends AppException`
- [ ] Chỉ `RemoteException` có varying `action` per kind
- [ ] Tất cả subtypes implement `message` + `action` (abstract getters)
- [ ] `rootException` available ở tất cả subtypes (từ base class constructor)

---

## 5. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Catch tất cả `catch (e)` thay vì `on AppException catch (e)` | Swallow programming bugs (`NullPointerException`, `RangeError`) | Dùng `on AppException catch` → let bugs bubble |
| 2 | Quên `_ =>` fallback trong mapper | Mapper throw exception → crash thay vì graceful error | Luôn có catch-all fallback trả `unknown` kind |
| 3 | Hardcode error message string thay vì `l10n` | Không support multi-language, không đổi text được | Dùng `l10n.keyName` cho mọi user-facing message |
| 4 | Thêm enum value nhưng quên fix switch | Compile error nếu dùng switch expression, **runtime miss** nếu dùng `if/else` | Luôn dùng switch expression → exhaustive check |
| 5 | Tạo exception subtype nhưng không export | Other layers không import được | Thêm vào barrel file `index.dart` |
| 6 | `ExceptionHandler` xử lý business logic (check user state) | Violate separation of concerns | Handler chỉ dispatch UI, business logic ở ViewModel |
| 7 | Quên preserve `rootException` khi mapping | Mất debug context, Crashlytics không có original stack | Luôn pass `rootException: exception` trong mapper |

---

## 6. Module Completion Gate

Hoàn thành module khi:

- [ ] Self-assessment: ≥ 6/7 Yes (tất cả 🔴 MUST-KNOW phải Yes)
- [ ] Exercise 1: trace đúng 5 bước SocketException → UI
- [ ] Exercise 2: trải nghiệm exhaustive switch enforcement, trả lời câu hỏi
- [ ] Exercise 3: tạo exception subtype đúng pattern, analyzer pass
- [ ] Exercise 4: map 5 Firebase error codes đúng kind
- [ ] Exercise 5: ≥ 4/6 AI evaluation pass
- [ ] Hierarchy cross-check: điền bảng đúng tất cả 4 subtypes
- [ ] Hiểu phân biệt `implements Exception` vs `extends Exception`

---

> ☕ **Nghỉ ngơi trước khi tiếp tục.** M04 và M05 là 2 modules nặng nhất trong curriculum. Đề xuất: commit bài tập → nghỉ 15-30 phút → sau đó bắt đầu M05 với đầu óc tỉnh táo.

**Nếu pass → tiến đến:**
- [Module 5 — Navigation & Routing](../module-05-navigation/) — bắt đầu UI layer
- **Unlocks:** [Module 7 — Base UI Framework](../module-07-base-viewmodel/) (exception handling trong ViewModels), [Module 9 — Page Structure](../module-09-page-structure/) (ErrorDialog UI), [Module 12 — Data Layer](../module-12-data-layer/) (full API error flow end-to-end)

<!-- AI_VERIFY: generation-complete -->
