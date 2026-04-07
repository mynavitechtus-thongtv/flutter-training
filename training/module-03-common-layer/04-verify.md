# Verification — Kiểm tra kết quả Module 3

> Đối chiếu bài làm với [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) và [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md).

---

## 1. Self-Assessment Checklist

Trả lời **Yes / No** cho từng câu. Nếu **No** → quay lại concept tương ứng trong [02-concept.md](./02-concept.md).

| # | Câu hỏi | Concept | Badge |
|---|---------|---------|-------|
| 1 | Tôi giải thích được tại sao `Config` dùng `static const` + `kDebugMode` thay vì runtime variable? | Configuration Pattern | 🔴 |
| 2 | Tôi biết `Constant` class giúp tránh magic numbers và tại sao dùng `Duration` thay vì `int`? | Constants & Magic Numbers | 🔴 |
| 3 | Tôi trace được flow: `dart_defines/develop.json` → `--dart-define` → `Env.flavor`? | Environment Management | 🔴 |
| 4 | Tôi phân biệt `Log.d()` (static) vs `logD()` (mixin) và biết khi nào dùng cái nào? | Logging System | 🟡 |
| 5 | Tôi mô tả `Result<T>` union type, dùng `when()`/`map()`, và giải thích `fromAsyncAction`? | Result Type | 🟡 |
| 6 | Tôi viết được extension method trên nullable type và hiểu scope của extensions? | Extensions & Utilities | 🟡 |
| 7 | Tôi hiểu helper pattern: `@LazySingleton` + Riverpod provider + single responsibility? | Helper Architecture | 🟢 |

**Target:** 3/3 Yes cho 🔴 MUST-KNOW, tối thiểu 6/7 tổng.

---

## 2. Exercise Verification

### Exercise 1 — Trace Config Usage ⭐

- [ ] Bảng trace có đủ **3 fields** (`enableGeneralLog`, `enableLogInterceptor`, `enableNavigatorObserverLog`)
- [ ] Mỗi field: xác định file sử dụng + dòng code + effect khi = false
- [ ] `enableGeneralLog` → `Log._enableLog` → guard trong `Log.d()`/`Log.e()`
- [ ] Giải thích tại sao `enableDevicePreview = false` hardcode (không dùng `kDebugMode`)

**Cross-check:** Chạy `grep -rn 'Config\.' lib/` trong `base_flutter`, verify output khớp với bảng.

### Exercise 2 — Env Flavor Investigation ⭐

- [ ] Bảng so sánh 4 environments có đủ keys
- [ ] `FLAVOR` values khớp: develop / qa / staging / production
- [ ] Default flavor khi test = `test` (từ `defaultValue: 'test'` trong `String.fromEnvironment`)
- [ ] Giải thích `const` (String.fromEnvironment = const constructor) vs `late` (Flavor.values.byName = runtime call)

**Cross-check:** Mở từng file `dart_defines/*.json`, verify values khớp với bảng.

### Exercise 3 — Build Result Pattern ⭐⭐

- [ ] Scenario A: `when()` handle cả `success` và `failure`
- [ ] Scenario B: chain 2 operations, failure propagates correctly
- [ ] Scenario C: `fromAsyncAction` shorter, auto-log error
- [ ] Giải thích: `on AppException catch` — chỉ catch **expected** errors, unexpected exceptions bubble up

**Cross-check [result.dart](../../base_flutter/lib/common/type/result.dart):**

| Pattern | Kiểm tra |
|---------|----------|
| `when()` exhaustive | Code handle cả `success` + `failure`? |
| `fromAsyncAction` | Dùng đúng function signature `Future<T> Function()`? |
| Generic type `T` | Type parameter consistent across chain? |

### Exercise 4 — Write Extension Method ⭐⭐

- [ ] `truncate()` → cắt đúng positions, thêm `...`, handle empty string
- [ ] `capitalizeFirst` → handle empty string (return `''`), uppercase first char
- [ ] `orDefault()` → nullable extension, return default khi null
- [ ] Pattern consistency: naming + style match project `extension.dart`

**Cross-check [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md):**

| Rule | Kiểm tra |
|------|----------|
| Extension name: PascalCase + `Extensions` suffix | `StringExtensions` ✅ |
| Method name: camelCase, verb phrase | `truncate`, `capitalizeFirst` ✅ |
| File name: snake_case | `string_util.dart` ✅ |
| Getter vs method | Property → getter, action → method | 

### Exercise 5 — AI Prompt Dojo ⭐⭐⭐

- [ ] AI output đánh giá qua 6 tiêu chí
- [ ] ≥ 4/6 tiêu chí pass
- [ ] AI nhận diện đúng compile-time const pattern
- [ ] AI **KHÔNG** suggest `print()` thay `dev.log()`
- [ ] AI hiểu Result = union type (không nhầm với simple wrapper)

---

## 3. Concept Cross-Check 🔴

Kiểm tra hiểu biết qua các câu hỏi scenario:

| # | Scenario | Đáp án đúng | Concept |
|---|----------|-------------|---------|
| 1 | Build release → `Config.enableGeneralLog` = ? | `false` (kDebugMode = false ở release) | Config |
| 2 | `Constant.itemsPerPage` sai giá trị → ảnh hưởng bao nhiêu files? | Tất cả files dùng `Constant.itemsPerPage` (tra bằng grep) | Constants |
| 3 | `flutter test` không có `--dart-define` → `Env.flavor` = ? | `Flavor.test` (defaultValue) | Env |
| 4 | `Log.d('test')` ở release build → output? | Không log (kDebugMode guard) | Logging |
| 5 | `Result.failure(e)` → caller quên handle failure → ? | Compiler warning nếu dùng `when()`, runtime error nếu dùng `.data` | Result |
| 6 | Extension `on String?` vs `on String` → gọi trên `null`? | Nullable extension OK, non-nullable extension compile error | Extension |

---

## 4. docs/technical Cross-Check

Các rule từ [common_coding_rules.md](../../base_flutter/docs/technical/common_coding_rules.md) áp dụng cho M3:

| Rule | Áp dụng ở đâu trong M3 | Kiểm tra |
|------|------------------------|----------|
| `static const` class pattern | Config, Constant, Env | Hiểu tại sao `const Config._()` private constructor? |
| `kDebugMode` usage | Config fields | Biết tree-shaking effect? |
| DI annotations (`@LazySingleton`) | Helper classes | Khi nào dùng `@LazySingleton` vs `@Injectable`? |
| Barrel file import | Mọi common files | `import '../../index.dart'` — không direct import? |

Các rule từ [naming_rules.md](../../base_flutter/docs/technical/naming_rules.md) áp dụng cho M3:

| Rule | Áp dụng ở đâu | Kiểm tra |
|------|---------------|----------|
| File names: snake_case | `config.dart`, `object_util.dart` | Không có camelCase file names |
| Class names: PascalCase | `Config`, `Log`, `ConnectivityHelper` | Consistency |
| Enum values: camelCase | `Flavor.develop`, `LogMode.normal` | Không UPPER_CASE |
| Extension names: PascalCase + purpose | `NullableListExtensions`, `BuildContextExtensions` | Descriptive naming |
| Private prefix: `_` | `Config._()`, `Log._enableLog`, `Env._flavorKey` | Private == underscore |

---

## 5. Common Mistakes

| # | Sai lầm | Hậu quả | Fix |
|---|---------|---------|-----|
| 1 | Dùng `print()` thay vì `Log.d()` | Log còn ở release build, không filter được | Luôn dùng `Log.d()` / `logD()` |
| 2 | Hardcode magic number (`limit: 20`) | Đổi 1 chỗ quên chỗ khác | Dùng `Constant.itemsPerPage` |
| 3 | Quên handle `Result.failure` | App crash hoặc silent error | Luôn dùng `when()` / `map()` (exhaustive) |
| 4 | Catch tất cả exceptions `catch (e)` | Swallow unexpected errors | Dùng `on AppException catch (e)` |
| 5 | Tạo extension trùng method name | Ambiguous call, compile error | Prefix extension name unique, scope carefully |
| 6 | Dùng `late` khi có thể `const` | Mất compile-time optimization | Check: expression = const constructor? → dùng `const` |
| 7 | Helper không register DI | Null khi get từ `getIt` | Thêm `@LazySingleton()` hoặc `@Injectable()` |

---

## 6. Module Completion Gate

Hoàn thành module khi:

- [ ] Self-assessment: ≥ 6/7 Yes
- [ ] Exercise 1 + 2: hoàn thành đúng (trace verified bằng grep)
- [ ] Exercise 3: Result pattern code compilable, handle cả 2 cases
- [ ] Exercise 4: Extension methods pass test cases
- [ ] Exercise 5: ≥ 4/6 AI evaluation pass
- [ ] Hiểu sự khác biệt `const` vs `late` vs `final` trong context Config/Env

**Nếu pass → tiến đến:**
- [Module 4 — Exception Layer](../module-04-exception-handling/) — `AppException`, error mapping, error handling (dùng `Result.failure` từ M3)
- [Module 7 — Base UI Framework](../module-07-base-viewmodel/) — state management dùng `Result<T>` cho ViewModel data flow
- [Module 8 — State Management](../module-08-riverpod-state/) — Riverpod providers dùng helpers từ M3

<!-- AI_VERIFY: generation-complete -->
