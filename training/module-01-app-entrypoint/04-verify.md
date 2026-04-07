# Verification — Kiểm tra kết quả Module 1

> Đối chiếu bài làm với [log_instructions.md](../../base_flutter/docs/technical/log_instructions.md) và [flutter_dart_instructions.md](../../base_flutter/docs/technical/flutter_dart_instructions.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được `main()` làm gì và tại sao `runApp()` là dòng cuối? | Entry Point | 🔴 |
| 2 | Tôi biết khi nào **bắt buộc** gọi `WidgetsFlutterBinding.ensureInitialized()`? | WidgetsFlutterBinding | 🔴 |
| 3 | Tôi mô tả được `runZonedGuarded` bắt loại error nào? | Error Handling | 🟡 |
| 4 | Tôi liệt kê đúng thứ tự 8+ bước trong boot sequence? | Init Sequence | 🟡 |
| 5 | Tôi giải thích được flow `@injectable` → codegen → `getIt.init()`? | DI Setup | 🟡 |
| 6 | Tôi biết `ProviderScope` cần đặt ở đâu và tại sao? | ProviderScope | 🟢 |

**Target:** 2/2 Yes cho 🔴 MUST-KNOW, tối thiểu 5/6 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace the Boot Sequence ⭐

- [ ] Bảng có đủ **12 bước** từ `main()` đến `runApp()`
- [ ] Thứ tự chính xác: binding → splash → firebase → env → DI → packageHelper → orientation → UIMode → resource → runApp
- [ ] Đánh dấu đúng bước nào `async` (có `await`)
- [ ] Cột "Mục đích" không để trống

**Cross-check:** Mở [main.dart](../../base_flutter/lib/main.dart) + [app_initializer.dart](../../base_flutter/lib/app_initializer.dart), đối chiếu từng dòng.

### Exercise 2 — Add an Initialization Step ⭐⭐

- [ ] `Stopwatch` tạo ở đầu `init()`, `.stop()` ở cuối
- [ ] Dùng `Log.d()` — **KHÔNG** dùng `print()`
- [ ] Param `name: 'AppInitializer'` có trong `Log.d()` call
- [ ] App chạy không crash
- [ ] Đã revert (`git checkout lib/app_initializer.dart`)

**Cross-check [log_instructions.md](../../base_flutter/docs/technical/log_instructions.md):**

| Rule | Kiểm tra |
|------|----------|
| Không dùng `print()` | Có `print()` trong code thêm vào? |
| `Log.d()` cho debug info | Dùng `Log.d()` (không phải `Log.e()` — đây không phải error) |
| Param `name` để identify source | Có `name: 'AppInitializer'` hoặc tương tự? |

### Exercise 3 — Trace DI Registration ⭐⭐

- [ ] Đã đọc `di.config.dart` (file generated)
- [ ] Đếm được tổng số dependency registrations
- [ ] Xác định `SharedPreferences` → `registerSingletonAsync` (do `@preResolve`)
- [ ] Xác định `PackageHelper` lifecycle type

**Cross-check:** Chạy `grep -c 'register' lib/di.config.dart` để đếm registrations.

### Exercise 4 — Custom Boot Logger (🤖 AI) ⭐⭐⭐

- [ ] AI output đánh giá qua 6 tiêu chí trong exercise
- [ ] Ít nhất 4/6 tiêu chí pass
- [ ] Ghi chú cụ thể điểm AI làm sai (nếu có)
- [ ] (Optional) Test chạy thành công trên emulator
- [ ] Đã revert tất cả thay đổi

---

## 3. docs/technical Cross-Check 🔴

Các rule từ [log_instructions.md](../../base_flutter/docs/technical/log_instructions.md) áp dụng cho M1:

| Rule | Áp dụng ở đâu trong M1 | Kiểm tra |
|------|------------------------|----------|
| KHÔNG dùng `print()` | `_reportError()`, Exercise 2 & 4 | Code không có `print()`? |
| `Log.e()` **bắt buộc** trong catch block | `_reportError()` dùng `Log.e()` | Xác nhận `Log.e()` có `stackTrace` param? |
| `Log.d()` cho debug info | Exercise 2 timing log, `AppProviderObserver` | Dùng đúng log level? (`.d()` cho info, `.e()` cho error) |
| Log modes (`api`, `logEvent`, `normal`) | `AppProviderObserver` dùng default `normal` | Hiểu khi nào dùng mode nào? |
| LogColor cho visual distinction | Exercise 4 yêu cầu cyan/green | Dùng màu hợp lý? |

Các rule từ [flutter_dart_instructions.md](../../base_flutter/docs/technical/flutter_dart_instructions.md):

| Rule | Áp dụng ở đâu | Kiểm tra |
|------|---------------|----------|
| Private constructor cho utility class | `AppInitializer._()` | Hiểu pattern? |
| `const` constructor khi possible | `const InitialResource()` | Biết khi nào dùng `const`? |
| Named parameters cho > 2 params | `_reportError({required error, ...})` | Tuân thủ? |

---

## 4. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Quên `ensureInitialized()` trước async operations | `ServicesBinding` null → crash | Thêm làm dòng đầu tiên trong `_runMyApp()` |
| 2 | Dùng `print()` thay vì `Log.e()`/`Log.d()` | Vi phạm coding convention, không kiểm soát log | Thay bằng `Log` class |
| 3 | Đặt `ProviderScope` **bên trong** `MyApp` | Riverpod providers không accessible ở root | `ProviderScope` phải wrap `MyApp` |
| 4 | Sai thứ tự init (VD: gọi DI trước `Env.init()`) | RuntimeError vì env chưa sẵn sàng | Tuân thủ sequence trong `AppInitializer` |
| 5 | Edit file `di.config.dart` manually | Mất thay đổi khi chạy `make fb` | Chỉ edit `di.dart`, chạy codegen |
| 6 | Thiếu `@preResolve` cho async dependency | `getIt.get<T>()` trả về `Future` thay vì resolved value | Thêm `@preResolve` annotation |

---

## 5. Module Completion Criteria

Hoàn thành **tất cả** mục dưới đây để pass Module 1:

- [ ] **C1:** Self-Assessment ≥ 5/6 Yes (bắt buộc 2 câu 🔴 đều Yes)
- [ ] **C2:** Exercise 1 — bảng boot sequence 12 bước đầy đủ và chính xác
- [ ] **C3:** Exercise 2 — thêm timing log đúng convention + revert
- [ ] **C4:** Exercise 3 — trace xong DI registration, trả lời 4 câu hỏi
- [ ] **C5:** Exercise 4 — AI prompt + đánh giá ≥ 4/6 tiêu chí
- [ ] **C6:** Không có `print()` trong bất kỳ code nào viết trong module
- [ ] **C7:** Không còn file test/temp trong `lib/` (đã cleanup)
- [ ] **C8:** `git status` clean (không có uncommitted changes từ exercises)

> ✅ **Pass:** C1–C8 tất cả checked → chuyển sang [Module 02 — Architecture](../module-02-architecture-barrel/).
> ❌ **Chưa pass:** Quay lại exercise/concept chưa hoàn thành, đối chiếu lại checklist.

<!-- AI_VERIFY: generation-complete -->