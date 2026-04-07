# Exercises — Thực hành App Entrypoint

> ⚠️ Tất cả bài tập thực hiện **trên codebase `base_flutter`** — không tạo project mới.
> Prerequisite: Đã hoàn thành `make sync` thành công ([M0 Exercise 2](../module-00-dart-primer/03-exercise.md)).

---

## ⭐ Exercise 1: Trace the Boot Sequence

**Mục tiêu:** Hiểu rõ thứ tự khởi động app — từ `main()` đến widget hiển thị trên screen.

### Hướng dẫn

1. Mở [main.dart](../../base_flutter/lib/main.dart).
2. Bắt đầu từ function `main()`, trace qua từng dòng code.
3. Khi gặp function call (VD: `AppInitializer.init()`), mở file tương ứng và trace tiếp.
4. Điền bảng dưới đây theo thứ tự **thực thi thực tế**:

### Template (copy vào file note riêng)

| Bước | Function/Method | File | Async? | Mục đích |
|------|----------------|------|--------|----------|
| 1 | `main()` | main.dart | ✅ | ? |
| 2 | `runZonedGuarded(...)` | main.dart | — | ? |
| 3 | `WidgetsFlutterBinding.ensureInitialized()` | main.dart | ❌ | ? |
| 4 | ? | ? | ? | Giữ splash screen |
| 5 | ? | ? | ? | Firebase |
| 6 | ? | ? | ? | Environment |
| 7 | ? | ? | ? | DI container |
| 8 | ? | ? | ? | Package info |
| 9 | ? | ? | ? | Orientation |
| 10 | ? | ? | ? | Edge-to-edge |
| 11 | ? | ? | ? | Load resource |
| 12 | `runApp(...)` | main.dart | ❌ | Mount widget tree |

> 💡 **FE Perspective**
> **Flutter:** Trace boot sequence từ `main()` → `_runMyApp()` → `AppInitializer.init()` → `runApp()` — đọc theo execution order.
> **React/Vue tương đương:** Trace `index.js` → `App.js` → `setupStore()` → `ReactDOM.render()`.
> **Khác biệt quan trọng:** Flutter boot có nhiều bước hơn (binding, splash, Firebase, DI, SystemChrome) so với FE bootstrap đơn giản hơn.

### ✅ Checklist hoàn thành
- [ ] Điền đủ 12 bước trong bảng
- [ ] Xác định đúng file chứa mỗi function
- [ ] Đánh dấu đúng bước nào async (`await`)
- [ ] Giải thích ngắn cột "Mục đích" cho mỗi bước

---

## ⭐⭐ Exercise 2: Add an Initialization Step

> 📱 **Thiết lập Emulator / Simulator**
>
> Bài tập này cần chạy app trên device. FE developers lần đầu làm mobile cần setup emulator/simulator trước.
>
> **Android Emulator** (cần Android Studio đã cài):
> 1. Mở Android Studio → **Virtual Device Manager** (icon điện thoại ở toolbar, hoặc **Tools → Device Manager**)
> 2. Click **Create Virtual Device** → chọn **Pixel 6** (hoặc bất kỳ device nào)
> 3. Chọn system image: **API 34** (Android 14) → **Download** nếu chưa có → **Next** → **Finish**
> 4. Click ▶️ để start emulator
> 5. Verify: chạy `flutter devices` trong terminal — phải thấy emulator trong danh sách
>
> **iOS Simulator** (chỉ trên macOS, cần Xcode đã cài):
> 1. Mở terminal: `open -a Simulator`
> 2. Hoặc: Xcode → **Settings** → **Platforms** → tải iOS runtime nếu cần
> 3. Menu **File → Open Simulator** → chọn iPhone 15 Pro
> 4. Verify: `flutter devices` — phải thấy simulator
>
> **Chrome** (để test nhanh):
> - `flutter run -d chrome` — không cần setup thêm
>
> ⚠️ Lần đầu tạo emulator sẽ download ~2-3 GB. Hãy setup trước khi bắt đầu exercise.
>
> Xem thêm: [base_flutter/README.md](../../base_flutter/README.md) | [Android Emulator docs](https://developer.android.com/studio/run/emulator) | [iOS Simulator docs](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device)

**Mục tiêu:** Thêm bước init mới vào `AppInitializer` — hiểu cách mở rộng boot sequence.

### Scenario

Team yêu cầu log thời gian boot (từ `AppInitializer.init()` bắt đầu đến kết thúc).

### Hướng dẫn từng bước

**Bước 1 — Mở [app_initializer.dart](../../base_flutter/lib/app_initializer.dart)**

**Bước 2 — Thêm `Stopwatch` đo thời gian:**

Sửa method `init()` — thêm 3 dòng:
```dart
static Future<void> init() async {
  final stopwatch = Stopwatch()..start();     // ← thêm

  Env.init();
  await configureInjection();
  await getIt.get<PackageHelper>().init();
  await SystemChrome.setPreferredOrientations(
    getIt.get<DeviceHelper>().deviceType == DeviceType.phone
        ? Constant.mobileOrientation
        : Constant.tabletOrientation,
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  stopwatch.stop();                            // ← thêm
  Log.d(                                       // ← thêm
    'AppInitializer completed in ${stopwatch.elapsedMilliseconds}ms',
    name: 'AppInitializer',
  );
}
```

> ⚠️ **Quan trọng:** Dùng `Log.d()` — **KHÔNG** dùng `print()` (xem [log_instructions.md](../../base_flutter/docs/technical/log_instructions.md)).

**Bước 3 — Chạy app trên emulator/simulator:**

> ⚠️ **Prerequisite:** Cần ít nhất 1 device configured. Chạy `flutter devices` — nếu không thấy device nào, setup emulator trước ([Android](https://developer.android.com/studio/run/emulator) / [iOS Simulator](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device)). Bài tập này cần chạy `flutter run` để thấy log output — `flutter analyze` không phát hiện được kết quả runtime.

```bash
flutter run
```
Quan sát console output — tìm dòng log `AppInitializer completed in XXms`.

**Bước 4 — Revert thay đổi:**
```bash
git checkout lib/app_initializer.dart
```

### Expected output
- App khởi động bình thường (không crash)
- Console có dòng log chứa thời gian boot (VD: `AppInitializer completed in 342ms`)
- Log hiển thị với color (nếu terminal hỗ trợ)

### ✅ Checklist hoàn thành
- [ ] Thêm `Stopwatch` đúng vị trí (đầu và cuối `init()`)
- [ ] Dùng `Log.d()` (tuân thủ log_instructions.md)
- [ ] App chạy không lỗi
- [ ] Nhìn thấy log timing trong console
- [ ] Đã revert lại trạng thái ban đầu

---

## ⭐⭐ Exercise 3: Trace DI Registration

**Mục tiêu:** Hiểu flow DI codegen — từ annotation đến runtime registration.

### Hướng dẫn

**Bước 1 — Mở [di.dart](../../base_flutter/lib/di.dart)**

Xác nhận `@InjectableInit()` annotation và `getIt.init()` call.

**Bước 2 — Mở file generated `di.config.dart`:**
```bash
cat lib/di.config.dart | head -40
```

> File này do `injectable_generator` tạo ra (đã học ở [M0 § codegen](../module-00-dart-primer/02-concept.md#3-code-generation-pipeline--should-know)). Không edit!

**Bước 3 — Trả lời câu hỏi:**

1. `di.config.dart` register bao nhiêu dependency? (Đếm số lần `registerFactory` / `registerSingleton` / `registerLazySingleton`)
2. `SharedPreferences` được register bằng method nào? (`registerFactory` hay `registerSingletonAsync`?)
3. Tìm `PackageHelper` trong `di.config.dart` — nó là factory hay singleton?
4. Có dependency nào phụ thuộc dependency khác không? (Hint: constructor injection)

> 💡 **FE Perspective**
> **Flutter:** Inspect `di.config.dart` (file generated) để hiểu DI container register những gì — file đọc được, không ẩn.
> **React/Vue tương đương:** Inspect NestJS `app.module.ts` generated metadata để hiểu IoC container.
> **Khác biệt quan trọng:** Dart gen code ra file đọc được (`di.config.dart`), NestJS ẩn trong decorator metadata (khó inspect).

### ✅ Checklist hoàn thành
- [ ] Đã đọc `di.config.dart` (file generated)
- [ ] Đếm được số dependency registered
- [ ] Xác định `SharedPreferences` registration type
- [ ] Tìm thấy `PackageHelper` và xác định lifecycle (factory/singleton)

---

## ⭐⭐⭐ Exercise 4: Implement Custom Boot Logger (🤖 AI Prompt Dojo)

**Mục tiêu:** Dùng AI tạo custom logger class cho boot sequence — sau đó **review và đánh giá output**.

### Scenario

Bạn muốn tạo một `BootLogger` class chuyên log từng bước init với timestamp + duration.

### Bước 1 — Viết prompt cho AI

Copy prompt sau vào AI assistant (Copilot Chat):

```
Create a Dart class `BootLogger` for tracking Flutter app initialization steps.

Requirements:
- Use Stopwatch internally to track total boot time
- Method `step(String name)` to log completion of each init step with cumulative time
- Method `finish()` to log total boot time
- Use Log.d() from the project (NOT print()) with name: 'BootLogger'
- Use LogColor.cyan for step logs, LogColor.green for finish log
- Class should be const-constructible with private constructor
- Static methods only (utility class pattern matching AppInitializer)

Context: This will be used in AppInitializer.init() in a Flutter project.
Log class is imported via 'index.dart' barrel file.
```

### Bước 2 — Đánh giá AI output

Kiểm tra output theo tiêu chí:

| # | Tiêu chí | Pass? |
|---|----------|-------|
| 1 | Dùng `Log.d()` thay vì `print()` | ? |
| 2 | `LogColor.cyan` cho steps, `LogColor.green` cho finish | ? |
| 3 | Có `const BootLogger._()` (private constructor) | ? |
| 4 | Dùng `Stopwatch` (không phải `DateTime.now()`) | ? |
| 5 | Static methods only | ? |
| 6 | Import `index.dart` (không import file cụ thể) | ? |

### Bước 3 — Fix và test (optional)

Nếu muốn test thực tế:
1. Tạo file `lib/common/util/boot_logger.dart` với code đã fix
2. Tích hợp vào `AppInitializer.init()`:
```dart
static Future<void> init() async {
  BootLogger.start();
  Env.init();
  BootLogger.step('Env.init');
  await configureInjection();
  BootLogger.step('configureInjection');
  // ... các bước khác
  BootLogger.finish();
}
```
3. Chạy `flutter run` và xác nhận output
4. **Revert tất cả thay đổi** sau khi test

### ✅ Checklist hoàn thành
- [ ] Viết prompt cho AI
- [ ] Đánh giá output theo 6 tiêu chí
- [ ] Ghi chú điểm nào AI làm đúng, điểm nào sai
- [ ] (Optional) Test trên emulator và xác nhận log output
- [ ] Đã revert tất cả thay đổi (nếu test)

---

## Exercises Summary

| # | Exercise | Độ khó | Concept liên quan |
|---|----------|--------|-------------------|
| 1 | Trace the Boot Sequence | ⭐ | Entry Point, Init Sequence |
| 2 | Add an Initialization Step | ⭐⭐ | Init Sequence, Log conventions |
| 3 | Trace DI Registration | ⭐⭐ | DI (get_it + injectable) |
| 4 | Custom Boot Logger (🤖 AI) | ⭐⭐⭐ | Log conventions, Utility class pattern |

<!-- AI_VERIFY: generation-complete -->