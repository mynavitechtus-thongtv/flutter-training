# Module 12: Data Layer & API Integration

## Tổng quan

Module này đi sâu vào **data layer** — kiến trúc API client, service facade, response decoder pipeline, error mapping, và local storage. Bạn sẽ đọc `DioBuilder` (Dio factory), `RestApiClient` (generic REST client), `AuthAppServerApiClient` / `NoneAuthAppServerApiClient` (concrete clients), `AppApiService` (service facade), `AppPreferences` (encrypted local storage), `AppDatabase` (DB wrapper) — hiểu cách data layer tổ chức, request lifecycle, và security patterns.

**Cycle:** CODE (đọc data layer files) → EXPLAIN (hiểu patterns) → PRACTICE (trace + build + extend).

**Prerequisite:** Hoàn thành [Module 2 — Architecture](../module-02-architecture-barrel/) (DI `@LazySingleton`, `get_it`), [Module 3 — Common Layer](../module-03-common-layer/) (`Constant` config), [Module 4 — Exception Handling](../module-04-exception-handling/) (`DioExceptionMapper`, `RemoteException`), và [Module 7 — Base ViewModel](../module-07-base-viewmodel/) (`runCatching` pattern).

---

## 🔄 Re-Anchor — Ôn lại M2-M4, M7

|| Module | Concept cần nhớ | Kết nối M12 |
|--------|-----------------|-------------|
| **M2 — Architecture** | `@LazySingleton`, `getIt`, Riverpod Provider bridge | `AppApiService`, `AppPreferences`, clients đều DI-managed |
| **M3 — Common Layer** | `Constant` class (`appApiBaseUrl`, timeouts) | `DioBuilder` đọc config từ `Constant` |
| **M4 — Exception Handling** | `DioExceptionMapper` → `RemoteException`, `RemoteExceptionKind` | `RestApiClient` catch → map → throw `RemoteException` |
| **M7 — Base ViewModel** | `runCatching` wrap API calls, error → `ExceptionHandler` | ViewModel gọi `AppApiService` bên trong `runCatching` |

→ Nếu bất kỳ concept nào chưa rõ → quay lại module tương ứng trước khi tiếp tục.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Mô tả được `RestApiClient.request<FirstOutput, FinalOutput>()` — generic types, decoder callback, error handling flow?
2. Phân biệt được Auth vs NoneAuth client — interceptor chain khác nhau thế nào, khi nào dùng cái nào?
3. Biết chọn đúng `SuccessResponseDecoderType` cho response format cụ thể?
4. Hiểu tại sao `AppApiService` wrap clients (facade pattern) thay vì ViewModel gọi client trực tiếp?
5. Biết khi nào dùng `EncryptedSharedPreferences` vs `SharedPreferences` vs `FlutterSecureStorage`?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 13 — Middleware & Interceptors](../module-13-middleware-interceptor-chain/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

8 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

|| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | Service Facade Pattern | 🔴 MUST-KNOW | AppApiService = single entry, ViewModel chỉ biết facade |
| 2 | REST Client Architecture | 🔴 MUST-KNOW | Generic request, decoder callback, method dispatch |
| 3 | Auth vs Non-Auth Clients | 🔴 MUST-KNOW | Interceptor chain differentiation, token injection |
| 4 | Response Decoder Pipeline | 🟡 SHOULD-KNOW | Strategy pattern, SuccessResponseDecoderType |
| 5 | Error → Exception Mapping | 🟡 SHOULD-KNOW | DioException → RemoteException, consistent typing |
| 6 | Local Storage Patterns | 🟡 SHOULD-KNOW | 3-tier storage, encrypted tokens, logout cleanup |
| 7 | Data Layer Structure | 🟡 SHOULD-KNOW | Folder organization, data source separation — detailed reference |
| 8 | Success Response Decoder Types | 🟢 AI-GENERATE | Flat/Nested/Wrapped response enum variants — AI generate, verify output |

**Phân bố:** 🔴 ~38% · 🟡 ~50% · 🟢 ~12%

---

## 📂 Files trong Module này

|| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Đọc DioBuilder → RestApiClient → Auth/NoneAuth clients → AppApiService → AppPreferences → AppDatabase | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 8 concepts từ data layer patterns | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 5 bài tập trace + add endpoint + storage + decoder + AI review | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + cross-check | VERIFY — kiểm tra |

### Exercises tóm tắt

|| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Trace Full API Call Lifecycle | ⭐ |
| 2 | Add New API Endpoint | ⭐ |
| 3 | Implement Secure Storage | ⭐⭐ |
| 4 | Custom Response Decoder | ⭐⭐ |
| 5 | AI Prompt Dojo — Architecture Review | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [app_api_service.dart](../../base_flutter/lib/data_source/api/app_api_service.dart) — service facade, 3 injected clients (216 lines)
- [rest_api_client.dart](../../base_flutter/lib/data_source/api/client/base/rest_api_client.dart) — generic REST client (133 lines)
- [dio_builder.dart](../../base_flutter/lib/data_source/api/client/base/dio_builder.dart) — Dio factory (31 lines)
- [auth_app_server_api_client.dart](../../base_flutter/lib/data_source/api/client/auth_app_server_api_client.dart) — auth client, 7 interceptors (37 lines)
- [none_auth_app_server_api_client.dart](../../base_flutter/lib/data_source/api/client/none_auth_app_server_api_client.dart) — non-auth client, 5 interceptors (29 lines)
- [base_success_response_decoder.dart](../../base_flutter/lib/data_source/api/json_decoder/base_success_response_decoder.dart) — decoder pipeline (60 lines)
- [base_error_response_decoder.dart](../../base_flutter/lib/data_source/api/json_decoder/base_error_response_decoder.dart) — error decoder
- [dio_exception_mapper.dart](../../base_flutter/lib/exception/exception_mapper/dio_exception_mapper.dart) — DioException → RemoteException (M4)
- [access_token_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/access_token_interceptor.dart) — Bearer token injection
- [app_preferences.dart](../../base_flutter/lib/data_source/preference/app_preferences.dart) — 3-tier local storage (81 lines)
- [app_database.dart](../../base_flutter/lib/data_source/database/app_database.dart) — DB wrapper (15 lines)
- [notification_data.dart](../../base_flutter/lib/model/api/notification_data.dart) — Freezed model example (M4, M12, M7 reference)

---

## Unlocks (Module 13+)

Sau khi hoàn thành Module 12, bạn sẽ:

- **Module 13 — Middleware & Interceptors:** Deep dive interceptor middleware — `RefreshTokenInterceptor` flow, retry logic, connectivity check. Mở rộng error handling từ M4 + M12.
- **Module 15 — Capstone Login:** Full login feature — `AppApiService.login()` → save tokens → navigate. Kết hợp M5 (navigation) + M8 (state) + M12 (API).
- **Module 18 — Testing:** Mock `AppApiService`, test `RestApiClient` với fake Dio, verify decoder pipeline. Unit test data layer.

<!-- AI_VERIFY: generation-complete -->
