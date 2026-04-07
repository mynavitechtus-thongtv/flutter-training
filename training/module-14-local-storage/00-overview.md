# Module 14: Local Storage — SharedPreferences, Encrypted Storage & Isar

## Tổng quan

Module này đi sâu vào **local storage layer** — cơ chế persistence cho user data trên device. Bạn sẽ đọc `AppPreferences` (3 storage tiers: plain SharedPreferences, EncryptedSharedPreferences, FlutterSecureStorage), phân tích security classification cho mỗi key (tokens → encrypted, flags → plain), hiểu DI pattern (`@LazySingleton` + Riverpod Provider), `clearCurrentUserData()` logout cleanup, và `AppDatabase` (Isar wrapper) — nắm khi nào dùng key-value vs structured database.

**Cycle:** CODE (đọc AppPreferences + AppDatabase) → EXPLAIN (hiểu storage tiers + security) → PRACTICE (thêm keys + migrate + secure storage).

**Prerequisite:** Hoàn thành [Module 12 — Data Layer](../module-12-data-layer/) (data layer structure, `lib/data_source/`), [Module 13 — Error Handling](../module-13-middleware-interceptor-chain/) (interceptors dùng `AppPreferences` cho token read/save).

---

## 🔄 Re-Anchor — Ôn lại M12, M13

| Module | Concept cần nhớ | Kết nối M14 |
|--------|-----------------|-------------|
| **M12 — Data Layer** | `AppApiService` facade, `lib/data_source/` structure — `api/`, `preference/`, `database/`, `firebase/` | M14 deep dive vào `preference/` và `database/` — hai sub-folders chưa được cover |
| **M13 — Interceptor Chain** | `AccessTokenInterceptor` đọc token, `RefreshTokenInterceptor` save token mới | Interceptors **consume** `AppPreferences` — M14 giải thích **provider** side: data lưu ở đâu, encrypted thế nào |

→ Nếu bất kỳ concept nào chưa rõ → quay lại module tương ứng trước khi tiếp tục.

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Phân biệt được SharedPreferences sync read / async write và giải thích tại sao?
2. Biết `EncryptedSharedPreferences` wrap `SharedPreferences` instance, encrypt value bằng AES?
3. Giải thích `FlutterSecureStorage` dùng iOS Keychain (`KeychainAccessibility.first_unlock`) + Android EncryptedSharedPreferences?
4. Phân loại được: token → encrypted, flag → plain, PIN → secure storage?
5. Mô tả `clearCurrentUserData()` dùng `Future.wait()` xóa selective keys, không `clear()` toàn bộ?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 15 — Capstone Login](../module-15-capstone-login/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## 🏷️ Badge Summary

7 concepts rút ra từ code walk, phân loại theo mức độ cần nắm:

| # | Concept | Badge | Ý nghĩa |
|---|---------|-------|----------|
| 1 | SharedPreferences — Sync Read / Async Write | 🔴 MUST-KNOW | Foundation storage — mọi app đều dùng |
| 2 | Encrypted Storage — EncryptedSharedPreferences | 🔴 MUST-KNOW | Token security baseline — sai = data leak |
| 3 | FlutterSecureStorage — Hardware-Backed | 🟡 SHOULD-KNOW | Highest security tier — project chưa dùng (`unused_field`), hiểu để dùng khi cần |
| 4 | Security Tiers — Data Classification | 🟡 SHOULD-KNOW | Decision matrix cho đúng tier |
| 5 | AppPreferences as DI Service | 🟡 SHOULD-KNOW | Injectable, testable, single-instance |
| 6 | Isar Database — NoSQL Local DB | � SHOULD-KNOW | Structured data — detailed reference with comparisons & decision tree |
| 7 | Logout & Clear Data Pattern | 🟢 AI-GENERATE | Cleanup correctness, Future.wait |

**Phân bố:** 🔴 ~29% · 🟡 ~57% · 🟢 ~14%

---

## 📂 Files trong Module này

| File | Nội dung | Vai trò |
|------|----------|---------|
| [01-code-walk.md](./01-code-walk.md) | Walk AppPreferences: constructor 3 tiers → keys → methods → clear → DI + AppDatabase | CODE — quan sát |
| [02-concept.md](./02-concept.md) | 7 concepts từ storage patterns: encryption tiers, DI, Isar, logout | EXPLAIN — giải thích |
| [03-exercise.md](./03-exercise.md) | 5 bài tập: trace → add key → migration → secure field → AI review | PRACTICE — làm tay |
| [04-verify.md](./04-verify.md) | Checklist tự đánh giá + exercise verification | VERIFY — kiểm tra |

### Exercises tóm tắt

| # | Bài tập | Độ khó |
|---|---------|--------|
| 1 | Read & Trace AppPreferences Usage | ⭐ |
| 2 | Add New Preference Key (`languageCode`) | ⭐ |
| 3 | Key Migration — Plain to Encrypted | ⭐⭐ |
| 4 | Add Encrypted Field with FlutterSecureStorage | ⭐⭐ |
| 5 | AI Prompt Dojo — Storage Architecture Review | ⭐⭐⭐ |

---

## 🔗 Liên kết

- [app_preferences.dart](../../base_flutter/lib/data_source/preference/app_preferences.dart) — SharedPreferences + Encrypted + Secure (84 lines)
- [app_database.dart](../../base_flutter/lib/data_source/database/app_database.dart) — Isar DB wrapper (15 lines)
- [access_token_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/access_token_interceptor.dart) — consumer: reads token from AppPreferences (19 lines)
- [refresh_token_interceptor.dart](../../base_flutter/lib/data_source/api/middleware/refresh_token_interceptor.dart) — consumer: saves new tokens to AppPreferences (140 lines)

---

## Unlocks (Module 15+)

Sau khi hoàn thành Module 14, bạn sẽ:
- Hiểu nơi tokens được persist — foundation cho **M15 (Capstone Login)**: login flow save tokens → interceptors read tokens → refresh flow update tokens
- Biết `clearCurrentUserData()` pattern — dùng trong logout flow (M15)
- Phân biệt storage tiers — áp dụng cho mọi feature cần persistence (settings, cache, credentials)

<!-- AI_VERIFY: generation-complete -->
