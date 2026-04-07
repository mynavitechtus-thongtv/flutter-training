# Exercises — Thực hành Exception Handling & Error Flow

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành [Module 3](../module-03-common-layer/) (Result type, Log.e, Config) và đọc xong [01-code-walk.md](./01-code-walk.md).

---

## ⭐ Exercise 1: Trace Exception Flow End-to-End

**Mục tiêu:** Trace một error từ raw exception → typed exception → Result → UI hiển thị, hiểu mỗi layer làm gì.

### Hướng dẫn

**Scenario:** User mở app khi không có internet. API call fail với `SocketException`.

1. Bắt đầu từ [dio_exception_mapper.dart](../../base_flutter/lib/exception/exception_mapper/dio_exception_mapper.dart).
2. `SocketException` → Dio wrap thành `DioException(type: connectionError)` hoặc `DioException(type: unknown, error: SocketException)`.
3. Trace qua mapper → `RemoteException` với `kind` = gì?
4. `RemoteException.action` getter → `AppExceptionAction` nào?
5. `ExceptionHandler.handleException()` → switch case nào → UI hiện gì?

### Template

Điền bảng trace:

| Step | Layer | Input | Output |
|------|-------|-------|--------|
| 1 | Dio library | `SocketException` | `DioException(type: ?)` |
| 2 | `DioExceptionMapper.map()` | `DioException` | `RemoteException(kind: ?)` |
| 3 | `RemoteException.message` | `kind` | `l10n.???` |
| 4 | `RemoteException.action` | `kind` | `AppExceptionAction.???` |
| 5 | `ExceptionHandler` | `AppExceptionAction` | UI: ??? |

**Bonus:** Trace lại với scenario `DioException(type: badResponse, statusCode: 503)` → server maintenance flow.

### ✅ Checklist hoàn thành
- [ ] Điền bảng 5 steps cho SocketException scenario
- [ ] Xác định đúng `RemoteExceptionKind` cho `connectionError`
- [ ] Xác định UI output (dialog type, có retry button không?)
- [ ] Bonus: trace 503 → maintenance dialog flow

---

## ⭐ Exercise 2: Add a New ValidationExceptionKind

**Mục tiêu:** Thêm validation kind mới — trải nghiệm exhaustive switch enforcement.

### Hướng dẫn

1. Mở [validation_exception.dart](../../base_flutter/lib/exception/validation_exception.dart).
2. Thêm `phoneNumberInvalid` vào `ValidationExceptionKind` enum:

```dart
enum ValidationExceptionKind {
  invalidEmail,
  invalidPassword,
  passwordsDoNotMatch,
  phoneNumberInvalid, // ← THÊM
}
```

3. **KHÔNG sửa gì khác** — save file.
4. Chạy Dart analyzer:

```bash
cd base_flutter
dart analyze lib/exception/validation_exception.dart
```

5. Quan sát error message — Dart analyzer báo lỗi ở `switch (kind)` trong `message` getter.
6. Fix: thêm case cho `phoneNumberInvalid`:

```dart
ValidationExceptionKind.phoneNumberInvalid => 'Invalid phone number', // tạm hardcode
```

7. Analyzer pass → **revert tất cả changes** (đây là exercise, không commit).

### Câu hỏi suy nghĩ
- Nếu dùng `if/else` thay vì `switch` expression → compiler có báo lỗi khi thêm enum value không?
- Bao nhiêu files cần sửa khi thêm `ValidationExceptionKind` mới? (hint: chỉ 1 file vì `action` là fixed `doNothing`)
- So sánh: thêm `RemoteExceptionKind` mới → bao nhiêu files cần sửa? Tại sao nhiều hơn?

### ✅ Checklist hoàn thành
- [ ] Thêm enum value thành công
- [ ] Dart analyzer báo exhaustive error
- [ ] Fix switch case → analyzer pass
- [ ] Trả lời 3 câu hỏi suy nghĩ
- [ ] **Revert changes**

---

## ⭐⭐ Exercise 3: Create a New Exception Subtype

**Mục tiêu:** Tạo `AppPermissionException` — exception cho permission denied scenarios. Áp dụng pattern observed.

### Hướng dẫn

1. Tạo file `lib/exception/app_permission_exception.dart`.
2. Implement theo pattern từ `ValidationException`:

### Template

```dart
import '../index.dart';

class AppPermissionException extends AppException {
  AppPermissionException({
    required this.kind,
    super.rootException,
    super.onRetry,
  }) : super();

  final AppPermissionExceptionKind kind;

  // TODO: override toString()
  // TODO: override action → AppExceptionAction.showDialog (user cần biết)
  // TODO: override message → switch (kind) với hardcoded strings,
  //       ví dụ: 'Camera permission denied', 'Location permission denied'...
}

enum AppPermissionExceptionKind {
  cameraPermissionDenied,
  locationPermissionDenied,
  notificationPermissionDenied,
  storagePermissionDenied,
}
```

> ⚠️ Dùng **hardcoded strings** cho `message` — localization keys (`l10n.cameraPermissionDenied`…) chưa tồn tại trong project. Chúng sẽ được thêm qua M11 (i18n) workflow.

> 💡 Hardcoded strings are acceptable here vì lint rule `avoid_hard_coded_strings` chỉ áp dụng cho files trong `lib/ui/`. File exception nằm trong `lib/exception/` — không bị lint rule này check. Trong production, bạn sẽ thêm l10n keys (Module 11) trước.

3. Implement 3 TODOs.
4. Verify: `dart analyze lib/exception/app_permission_exception.dart` → no errors.

### Câu hỏi suy nghĩ
- Bạn chọn `action = showDialog` hay `doNothing`? Justify.
- Có cần thêm case mới vào `ExceptionHandler.handleException()` không? Tại sao không?
- `AppPermissionException` cần export ở đâu để cả app dùng được? (hint: barrel file `index.dart`)
- Nếu permission denied cần **retry** (ask permission again), pattern nào support? (hint: `onRetry` callback)

### ✅ Checklist hoàn thành
- [ ] File tạo đúng location, đúng naming convention
- [ ] `extends AppException` — đúng hierarchy
- [ ] `kind` enum + `switch` exhaustive cho `message`
- [ ] `action` override có rationale rõ ràng
- [ ] `toString()` bao gồm kind + super
- [ ] Dart analyzer pass (trừ l10n nếu chưa add keys)
- [ ] **Clean up** — nếu không merge, xóa file test

---

## ⭐⭐ Exercise 4: Map Raw Error to Typed Exception

**Mục tiêu:** Viết mapper function chuyển `FirebaseAuthException` (raw) → `AppFirebaseAuthException` (typed). Hiểu mapper pattern thực tế.

### Scenario

Firebase Auth SDK throw `FirebaseAuthException` với `code` string. Bạn cần map sang `AppFirebaseAuthExceptionKind`.

### Hướng dẫn

1. Đọc [app_firebase_auth_exception.dart](../../base_flutter/lib/exception/app_firebase_auth_exception.dart).
2. Reference Firebase Auth error codes: `invalid-email`, `user-not-found`, `wrong-password`, `email-already-in-use`, `requires-recent-login`.
3. Viết mapper function (trên giấy hoặc scratch file):

### Template

```dart
// Pseudo-code — không cần compile
AppFirebaseAuthException mapFirebaseAuthError(Object? exception) {
  if (exception is FirebaseAuthException) {
    return switch (exception.code) {
      'invalid-email' => AppFirebaseAuthException(
        kind: AppFirebaseAuthExceptionKind.invalidEmail,
        rootException: exception,
      ),
      // TODO: map 'user-not-found' → userDoesNotExist
      // TODO: map 'wrong-password' → invalidLoginCredentials
      // TODO: map 'email-already-in-use' → usernameAlreadyInUse
      // TODO: map 'requires-recent-login' → requiresRecentLogin
      _ => AppFirebaseAuthException(
        kind: AppFirebaseAuthExceptionKind.unknown,
        rootException: exception,
      ),
    };
  }
  return AppFirebaseAuthException(
    kind: AppFirebaseAuthExceptionKind.unknown,
    rootException: exception,
  );
}
```

4. Hoàn thành 4 TODOs.
5. So sánh pattern mapper này với `DioExceptionMapper` — điểm giống/khác?

### Câu hỏi suy nghĩ
- Firebase error codes là `String` (e.g., `'invalid-email'`). Risk gì so với dùng enum? Cách mitigate?
- Tại sao mapper luôn có fallback `_ =>` hoặc catch-all cuối?
- Mapper này nên implement `AppExceptionMapper<AppFirebaseAuthException>` hay standalone function? Trade-off?

### ✅ Checklist hoàn thành
- [ ] Map đủ 5 Firebase error codes → đúng `AppFirebaseAuthExceptionKind`
- [ ] Fallback `_` bắt mọi unknown codes
- [ ] Final fallback cho non-`FirebaseAuthException` input
- [ ] So sánh có justification với `DioExceptionMapper`
- [ ] Trả lời 3 câu hỏi suy nghĩ

---

## ⭐⭐⭐ Exercise 5: AI Dojo — 🧪 Test Generation

### 🤖 AI Dojo — Test Generation cho Exception Handling

**Mục tiêu**: Dùng AI sinh unit tests cho exception handler — đánh giá chất lượng test và tìm edge cases AI bỏ sót.

**Bước thực hiện**:

1. Copy nội dung [exception_handler.dart](../../base_flutter/lib/exception/exception_handler/exception_handler.dart) vào clipboard.

2. Gửi prompt sau cho AI:

```
Tôi có class ExceptionHandler xử lý AppExceptionAction (showDialog, showSnackBar,
forceLogout...) trong Flutter project dùng Riverpod.

Hãy generate unit tests bằng mocktail:
- Mỗi test case cover 1 AppExceptionAction switch case
- Mock dependencies: Ref, AppNavigator, AppPreferences
- Test forceLogout fallback khi logout throws exception
- Test onRetry callback khi user tap retry trên dialog

Code:
[PASTE exception_handler.dart]
```

3. Copy test code AI sinh ra → tạo file `test/exception/exception_handler_test.dart` → chạy `dart analyze` kiểm tra compile.

4. Đánh giá tests AI tạo:
   - Có cover đủ switch cases không? Thiếu case nào?
   - Assertions có ý nghĩa (verify navigation gọi đúng) hay chỉ "no exception"?
   - Mock setup có đúng Riverpod pattern không?

**✅ Tiêu chí đánh giá**:
- [ ] AI generate ≥ 5 test cases cover các AppExceptionAction khác nhau
- [ ] Bạn thử compile tests → identify lỗi cần fix (AI hiếm khi generate test chạy 100% ngay)
- [ ] Bạn identify ≥ 1 edge case AI bỏ sót (ví dụ: concurrent exception handling)
- [ ] Bạn **không** chấp nhận test chỉ assert "no error thrown" — yêu cầu verify behavior cụ thể
- [ ] Test code follow project conventions: dùng mocktail, naming rõ ràng, mock setup đúng Riverpod pattern

---

## 📋 Mini-Guide: Tạo Custom Exception mới

Khi cần thêm một loại exception mới vào project, follow 3 bước sau:

### Bước 1: Tạo exception class extends AppException

```dart
// lib/exception/app_xxx_exception.dart
class AppXxxException extends AppException {
  AppXxxException({
    required this.kind,
    super.rootException,
    super.onRetry,
  }) : super();

  final AppXxxExceptionKind kind;

  @override
  String get message => switch (kind) {
    AppXxxExceptionKind.someError => 'Some error message', // hardcode tạm — M11 sẽ dùng l10n key
    // ... handle tất cả kinds (exhaustive)
  };

  @override
  AppExceptionAction get action => AppExceptionAction.showDialog;
  // Chọn action phù hợp: showDialog, doNothing, showSnackBar...

  @override
  String toString() => 'AppXxxException(kind: $kind, ${super.toString()})';
}

enum AppXxxExceptionKind {
  someError,
  anotherError,
}
```

### Bước 2: Thêm mapper (nếu cần convert từ third-party exception)

```dart
// lib/exception/exception_mapper/xxx_exception_mapper.dart
class XxxExceptionMapper extends AppExceptionMapper<AppXxxException> {
  @override
  AppXxxException map({required Object? exception, ...}) {
    if (exception is AppXxxException) return exception; // idempotent
    // Map raw exception → typed AppXxxException
    return AppXxxException(kind: AppXxxExceptionKind.someError, rootException: exception);
  }
}
```

### Bước 3: Export và thêm error message

1. Chạy `make ep` → tự động export file mới vào `index.dart`
2. Thêm localization keys vào file `.i18n.json` cho `message` getter (hoặc hardcode tạm)
3. `ExceptionHandler` **không cần sửa** — vì nó dispatch theo `AppExceptionAction` enum, không theo exception type

> ⚠️ **Lưu ý:** Nếu exception dùng `action = doNothing` → caller (ViewModel) phải tự handle hiển thị error. `ExceptionHandler` sẽ skip.

---

## Exercise Summary

| # | Exercise | Độ khó | Concept chính | Thời lượng ước tính |
|---|----------|--------|--------------|-------------------|
| 1 | Trace Exception Flow | ⭐ | Hierarchy, Mapping, Handler | ~20 phút |
| 2 | Add ValidationExceptionKind | ⭐ | Typed Subtypes, Exhaustive Switch | ~15 phút |
| 3 | Create Exception Subtype | ⭐⭐ | Hierarchy, Action-Driven | ~30 phút |
| 4 | Map Firebase Auth Error | ⭐⭐ | Mapper Pattern | ~25 phút |
| 5 | AI Dojo — Test Generation | ⭐⭐⭐ | Unit test generation, critical evaluation | ~30 phút |

→ Tiếp theo: [04-verify.md](./04-verify.md) — checklist tự đánh giá kết quả.

<!-- AI_VERIFY: generation-complete -->
