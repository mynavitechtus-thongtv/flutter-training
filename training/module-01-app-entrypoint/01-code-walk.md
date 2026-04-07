# Code Walk — App Entrypoint & Bootstrap

> 📌 **Recap từ Module 0:**
> - `pubspec.yaml`: cấu trúc project, dependency pinning, annotation ↔ generator pattern ([M0 § pubspec](../module-00-dart-primer/01-code-walk.md#pubspecyaml--trung-tâm-khai-báo-project))
> - `make sync`: workflow cài deps + codegen ([M0 § makefile](../module-00-dart-primer/01-code-walk.md#makefile--automation-shortcuts))
> - `injectable` + `injectable_generator`: DI codegen pair ([M0 § dependency](../module-00-dart-primer/02-concept.md#2-dependency-management--should-know))
>
> Nếu chưa nắm vững → quay lại [Module 0](../module-00-dart-primer/) trước.

---

## main.dart — Điểm vào của ứng dụng

<!-- AI_VERIFY: base_flutter/lib/main.dart#L1-L9 -->
```dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'index.dart';
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/main.dart)

> 🔎 **Quan sát**
> - `dart:async` — thư viện core cho `Future`, `runZonedGuarded` (không cần cài thêm)
> - `index.dart` — barrel file export toàn bộ `lib/`. Mọi class trong project import qua đây → giải thích chi tiết ở [Module 2](../module-02-architecture-barrel/00-overview.md)
> - Imports chia 3 nhóm: dart SDK → packages → project files. Đây là convention Dart (không bắt buộc nhưng `analysis_options` enforce)
> - **Hỏi:** `hooks_riverpod` import ở đây nhưng chưa thấy dùng. Nó dùng ở đâu?

> 💡 **FE Perspective**
> **Flutter:** `index.dart` là barrel file duy nhất ở root `lib/` — export toàn bộ project, generated tự động.
> **React/Vue tương đương:** `index.ts` barrel export, `import { ... } from '@/index'`.
> **Khác biệt quan trọng:** Dart convention dùng một `index.dart` duy nhất (generated), FE thường có nhiều barrel files thủ công.

---

### main() — Entry point với error boundary

<!-- AI_VERIFY: base_flutter/lib/main.dart#L12-L16 -->
```dart
// ignore: avoid_unnecessary_async_function
Future<void> main() async => runZonedGuarded(
      _runMyApp,
      (error, stackTrace) => _reportError(error: error, stackTrace: stackTrace),
    );
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/main.dart)

> 🔎 **Quan sát**
> - `main()` là **entry point bắt buộc** — Dart runtime tìm function `main` trong file được chỉ định (mặc định `lib/main.dart`)
> - `runZonedGuarded` wrap toàn bộ app trong một **Zone** (Dart concept — execution context cô lập, có thể intercept errors + async operations bên trong nó, tương tự `try/catch` nhưng bao trùm cả async code) — mọi uncaught exception đều bị bắt
> - Param 1: `_runMyApp` — function chính chạy app
> - Param 2: error handler — nhận `error` + `stackTrace`, forward đến `_reportError`
> - `// ignore: avoid_unnecessary_async_function` — suppress lint vì `runZonedGuarded` cần `async` ở outer function
> - **Hỏi:** Nếu bỏ `runZonedGuarded`, uncaught exception sẽ xảy ra điều gì?

> 💡 **FE Perspective**
> **Flutter:** `runZonedGuarded` tạo error zone bao bọc toàn bộ app — bắt mọi uncaught sync + async exception.
> **React/Vue tương đương:** `window.onerror` + `unhandledrejection` handler, hoặc React `ErrorBoundary` (nhưng chỉ cho UI).
> **Khác biệt quan trọng:** Zone trong Dart bắt cả sync + async errors ở cấp toàn ứng dụng, React ErrorBoundary chỉ bắt render errors trong UI tree.

---

### _runMyApp() — Boot sequence

<!-- AI_VERIFY: base_flutter/lib/main.dart#L18-L28 -->
```dart
Future<void> _runMyApp() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();
  await AppInitializer.init();
  final initialResource = _loadInitialResource();
  runApp(ProviderScope(
    observers: [AppProviderObserver()],
    child: MyApp(initialResource: initialResource),
  ));
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/main.dart)

> 🔎 **Quan sát**
> - **Thứ tự quan trọng!** Mỗi bước phụ thuộc bước trước:
>   1. `WidgetsFlutterBinding.ensureInitialized()` — khởi tạo binding giữa Dart và native platform
>   2. `FlutterNativeSplash.preserve(...)` — giữ splash screen hiển thị trong lúc init
>   3. `Firebase.initializeApp()` — khởi tạo Firebase (cần binding ở bước 1)
>   4. `AppInitializer.init()` — env, DI, orientation (cần Firebase ở bước 3)
>   5. `_loadInitialResource()` — load dữ liệu ban đầu
>   6. `runApp(...)` — mount widget tree vào screen
> - `ProviderScope` wrap toàn bộ `MyApp` — đây là **root của Riverpod** state management
> - `AppProviderObserver()` — observer để log lifecycle của providers (debug tool)
> - **Hỏi:** Tại sao `_loadInitialResource()` không cần `await`? Khi nào thì cần `await`?

> 💡 **FE Perspective**
> **Flutter:** Boot sequence tuần tự: binding → splash → Firebase → DI → config → `runApp(ProviderScope(MyApp))`.
> **React/Vue tương đương:** `firebase.initializeApp()` → `setupDI()` → `ReactDOM.createRoot(el).render(<Provider store={store}><App />)`.
> **Khác biệt quan trọng:** Riverpod `ProviderScope` không cần truyền store — providers tự register qua codegen. Flutter có thêm native binding + splash step.

---

### _reportError() — Global error handler

<!-- AI_VERIFY: base_flutter/lib/main.dart#L30-L33 -->
```dart
void _reportError({required error, required StackTrace stackTrace}) {
  Log.e(error, stackTrace: stackTrace, name: 'Uncaught exception');
  FirebaseCrashlytics.instance.recordError(error, stackTrace);
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/main.dart)

> 🔎 **Quan sát**
> - `Log.e()` — **project logger**, không dùng `print()` (xem [log_instructions.md](../../base_flutter/docs/technical/log_instructions.md))
> - `FirebaseCrashlytics.instance.recordError(...)` — gửi error lên Firebase Crashlytics (production monitoring)
> - Hai action cho mỗi error: log local (dev debug) + report remote (production tracking)
> - **Hỏi:** Tại sao dùng `Log.e()` thay vì `print()`? (Gợi ý: đọc [log_instructions.md](../../base_flutter/docs/technical/log_instructions.md))

> 💡 **FE Perspective**
> **Flutter:** `Log.e()` (local logging) + `FirebaseCrashlytics.recordError()` (remote reporting) — dual strategy cho mọi uncaught error.
> **React/Vue tương đương:** `Sentry.captureException(error)` + `console.error()`. Custom logger ≈ Winston/Pino trong Node.js.
> **Khác biệt quan trọng:** Dart project dùng `Log` class riêng (không dùng `print()`), FE thường dùng `console.*` trực tiếp.

---

### _loadInitialResource() — Load dữ liệu khởi tạo

<!-- AI_VERIFY: base_flutter/lib/main.dart#L35-L37 -->
```dart
InitialResource _loadInitialResource() {
  return const InitialResource();
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/main.dart)

> 🔎 **Quan sát**
> - Hiện tại trả về `const InitialResource()` — một empty object. Tương lai sẽ load cached data, feature flags, etc.
> - `InitialResource` là freezed class ([xem source](../../base_flutter/lib/model/entity/initial_resource.dart)) — immutable, có `==` comparison tự động
> - `const` constructor: object được tạo **compile-time**, không tốn allocation lúc runtime
> - **Hỏi:** Tại sao tách thành function riêng thay vì inline `const InitialResource()` trong `runApp()`?

> 💭 Suy nghĩ trước khi đọc concept — đáp án ở [02-concept.md](./02-concept.md)

---

## app_initializer.dart — Khởi tạo hệ thống

<!-- AI_VERIFY: base_flutter/lib/app_initializer.dart#L1-L20 -->
```dart
import 'package:flutter/services.dart';

import 'index.dart';

class AppInitializer {
  const AppInitializer._();

  static Future<void> init() async {
    Env.init();
    await configureInjection();
    await getIt.get<PackageHelper>().init();
    await SystemChrome.setPreferredOrientations(
      getIt.get<DeviceHelper>().deviceType == DeviceType.phone
          ? Constant.mobileOrientation
          : Constant.tabletOrientation,
    );
    // Edge to Edge
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/app_initializer.dart)

> 🔎 **Quan sát**
> - `const AppInitializer._()` — **private constructor** + `const` → class **không thể khởi tạo** từ bên ngoài. Đây là pattern "utility class" trong Dart (tương đương `abstract final class` ở Dart 3)
> - `static Future<void> init()` — method duy nhất, gọi từ `main.dart` line 22
> - **Init sequence bên trong:**
>   1. `Env.init()` — đọc environment variables (flavor: develop/qa/staging/production)
>   2. `configureInjection()` — setup DI container (get_it + injectable)
>   3. `getIt.get<PackageHelper>().init()` — package info (version, build number)
>   4. `SystemChrome.setPreferredOrientations(...)` — lock orientation theo device type
>   5. `SystemChrome.setEnabledSystemUIMode(...)` — edge-to-edge display
> - Sau `configureInjection()`, có thể dùng `getIt.get<T>()` để lấy bất kỳ dependency nào
> - **Hỏi:** Tại sao `Env.init()` phải chạy **trước** `configureInjection()`?

> 💡 **FE Perspective**
> **Flutter:** `AppInitializer` là utility class (private constructor + static methods) chạy init tuần tự: Env → DI → PackageHelper → SystemChrome.
> **React/Vue tương đương:** Module initialization: `dotenv.config()` → `createDI()` → `container.get(Service).init()`.
> **Khác biệt quan trọng:** `SystemChrome` API (lock rotation, status bar) là platform-specific — không có equivalent trong web FE.

---

## di.dart — Dependency Injection Setup

<!-- AI_VERIFY: base_flutter/lib/di.dart#L1-L16 -->
```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: prefer_importing_index_file
import 'di.config.dart';

@module
abstract class ServiceModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}

final GetIt getIt = GetIt.instance;
@InjectableInit()
Future<void> configureInjection() => getIt.init();
```
<!-- END_VERIFY -->

→ [Mở file gốc](../../base_flutter/lib/di.dart)

> 🔎 **Quan sát**
> - `GetIt` — service locator pattern. `getIt` là **singleton instance** dùng toàn app
> - `@InjectableInit()` — annotation cho `injectable_generator` → generate file `di.config.dart` chứa toàn bộ DI registration
> - `getIt.init()` — method generated trong `di.config.dart`, register tất cả dependency đã annotate
> - `ServiceModule` — module cung cấp **third-party dependencies** (không thể annotate trực tiếp)
>   - `@module` — đánh dấu class chứa các factory/singleton
>   - `@preResolve` — resolve async **trước khi** DI ready (vì `SharedPreferences.getInstance()` là `Future`)
> - `import 'di.config.dart'` — import file generated. `// ignore: prefer_importing_index_file` vì file này không nên export qua barrel
> - **Hỏi:** `getIt.get<PackageHelper>()` ở `app_initializer.dart` — `PackageHelper` được register ở đâu?

> 💡 **FE Perspective**
> **Flutter:** `GetIt` service locator + `@injectable` annotation → codegen `di.config.dart` auto-register tất cả dependency.
> **React/Vue tương đương:** InversifyJS container hoặc NestJS IoC container — manual bind `container.bind<T>(TYPES.T).to(...)`.
> **Khác biệt quan trọng:** Dart auto-register qua codegen (zero manual bind, zero runtime overhead), JS DI frameworks cần manual bind hoặc dùng reflection.

---

## 📊 Code Walk Summary

| File | Dòng | Vai trò | Key Pattern |
|------|------|---------|-------------|
| [main.dart](../../base_flutter/lib/main.dart) | 37 | Entry point + error boundary | `runZonedGuarded` + `runApp` |
| [app_initializer.dart](../../base_flutter/lib/app_initializer.dart) | 20 | System initialization | Static utility class + sequential init |
| [di.dart](../../base_flutter/lib/di.dart) | 16 | DI container setup | `GetIt` + `injectable` codegen |

### Boot Sequence (toàn cảnh)

```
main() ─── runZonedGuarded ───┐
                               ▼
                          _runMyApp()
                               │
            ┌──────────────────┼───────────────────┐
            ▼                  ▼                    ▼
   ensureInitialized()   Firebase.init()    AppInitializer.init()
                                                    │
                               ┌────────────────────┼────────────────────┐
                               ▼                    ▼                    ▼
                          Env.init()       configureInjection()    SystemChrome
                                                    │
                                                    ▼
                                              runApp(ProviderScope(MyApp))
```

> 📱 **Lưu ý cho FE developers:** Để chạy app Flutter cần emulator (Android) hoặc simulator (iOS). Nếu chưa setup, xem hướng dẫn chi tiết tại [Exercise 2 — Emulator/Simulator Setup](03-exercise.md#-exercise-2-add-an-initialization-step) trước khi thực hành.

> ⏭️ **Forward:** Architecture patterns sẽ được giải thích chi tiết ở [Module 2 — Architecture](../module-02-architecture-barrel/). State management với `ProviderScope` sẽ deep dive tại [Module 8 — State Management](../module-08-riverpod-state/).

<!-- AI_VERIFY: generation-complete -->
