# Concepts — Những khái niệm từ App Entrypoint

> Mỗi concept dưới đây được trích từ code đã đọc trong [01-code-walk.md](./01-code-walk.md). Cycle: **CODE → EXPLAIN → PRACTICE**.

---

## 1. Flutter App Entry Point 🔴 MUST-KNOW

**WHY:** Mọi Flutter app đều bắt đầu từ `main()`. Hiểu sai entry point = không debug được boot crash.

<!-- AI_VERIFY: base_flutter/lib/main.dart#L12-L16 -->
```dart
Future<void> main() async => runZonedGuarded(
      _runMyApp,
      (error, stackTrace) => _reportError(error: error, stackTrace: stackTrace),
    );
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § main()](./01-code-walk.md#main--entry-point-với-error-boundary)

**EXPLAIN:**

Dart runtime khi launch app sẽ tìm function `main()` — đây là **entry point duy nhất**. Trong Flutter:

- `main()` chỉ cần gọi `runApp(Widget)` để mount widget tree lên screen
- Mọi setup (Firebase, DI, splash) phải xảy ra **trước** `runApp()`
- `main()` có thể `async` — cho phép `await` các init steps

`runApp()` nhận một `Widget` và attach nó vào root của rendering pipeline:

```
main() → runApp(MyWidget) → Flutter engine render MyWidget lên screen
```

> 💡 **FE Perspective**
> **Flutter:** `main()` là entry point duy nhất, gọi `runApp(Widget)` để mount widget tree lên screen.
> **React/Vue tương đương:** `ReactDOM.createRoot(el).render(<App />)` hoặc `createApp(App).mount('#app')`.
> **Khác biệt quan trọng:** Dart có đúng 1 entry point (`main()`), không có nhiều entry file như webpack config.

**PRACTICE:** Mở [main.dart](../../base_flutter/lib/main.dart), trace từ `main()` → `_runMyApp()` → `runApp()`. Xác nhận `runApp` là dòng cuối cùng trong boot sequence.

### 💡 Hot Reload vs Hot Restart

Khi phát triển Flutter, bạn dùng hai cơ chế cập nhật code mà không cần rebuild toàn bộ:

| | Hot Reload | Hot Restart |
|---|---|---|
| Speed | ~1s | ~3-5s |
| State | Preserved | Reset |
| When | Widget changes | State/init changes |

- **Hot Reload** (`r` trong terminal hoặc ⚡ trong IDE): Inject code mới vào running Dart VM, rebuild widget tree. State của `StatefulWidget` / Riverpod providers **giữ nguyên**. Dùng khi sửa UI (widget build methods, styles).
- **Hot Restart** (`R` trong terminal hoặc 🔄 trong IDE): Restart toàn bộ app từ `main()`. State **bị reset**. Dùng khi thay đổi `initState()`, static fields, `const` values, hoặc thêm/xóa providers.

> 💡 **FE Perspective**
> **Flutter:** Hot Reload inject code changes ~1s, giữ state. Hot Restart restart từ `main()` ~3-5s, reset state.
> **React/Vue tương đương:** Vite HMR ≈ Hot Reload (giữ component state). Full page refresh ≈ Hot Restart.
> **Khác biệt quan trọng:** Flutter Hot Reload chỉ áp dụng cho widget tree changes. Thay đổi `main()`, static/const values cần Hot Restart — FE HMR không có phân biệt này.

---

## 2. WidgetsFlutterBinding.ensureInitialized() 🔴 MUST-KNOW

**WHY:** Quên gọi = crash khi dùng bất kỳ plugin nào trước `runApp()`.

<!-- AI_VERIFY: base_flutter/lib/main.dart#L19 -->
```dart
final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § _runMyApp()](./01-code-walk.md#_runmyapp--boot-sequence)

**EXPLAIN:**

`WidgetsFlutterBinding` là cầu nối giữa **Dart framework** và **native platform** (Android/iOS engine). Gọi `ensureInitialized()` đảm bảo:

1. **Services binding** — platform channels sẵn sàng (giao tiếp Dart ↔ native)
2. **Rendering binding** — rendering pipeline initialized
3. **Gestures binding** — gesture recognition ready

**Khi nào PHẢI gọi?** Khi có bất kỳ operation nào **trước `runApp()`** mà cần platform interaction:
- `Firebase.initializeApp()` — cần platform channel
- `SharedPreferences.getInstance()` — cần native storage
- `SystemChrome.*` — cần platform services

**Rule of thumb:** Nếu `main()` **chỉ** gọi `runApp()` → không cần. Nếu có **bất kỳ `await` nào** trước `runApp()` → **bắt buộc** gọi `ensureInitialized()` trước.

> 💡 **FE Perspective**
> **Flutter:** `WidgetsFlutterBinding.ensureInitialized()` khởi tạo binding giữa Dart framework và native platform — bắt buộc trước mọi plugin.
> **React/Vue tương đương:** Closest analogy: `ReactDOM.createRoot(document.getElementById('root'))` — khởi tạo bridge giữa framework và rendering surface, không phải event-based như `DOMContentLoaded`.
> **Khác biệt quan trọng:** Không có equivalent trực tiếp trong web FE — Flutter cần binding vì giao tiếp với native platform (Android/iOS engine).

**PRACTICE:**

> 🧪 **Thử ngay**: Mở [main.dart](../../base_flutter/lib/main.dart), comment out dòng `WidgetsFlutterBinding.ensureInitialized()` → chạy `flutter run` → quan sát crash/error. Dự đoán dòng nào sẽ crash đầu tiên khi run? (Hint: `Firebase.initializeApp()` cần platform binding). Uncomment lại khi xong.

---

## 3. runZonedGuarded — Global Error Handling 🟡 SHOULD-KNOW

> 💡 **TL;DR**: `runZonedGuarded` = global try/catch that also catches async errors. Mọi unhandled error trong app đều đổ về đây.

**WHY:** Uncaught errors không bị handle = app crash silently. Pattern này đảm bảo mọi error đều được log + report.

<!-- AI_VERIFY: base_flutter/lib/main.dart#L12-L16 -->
```dart
Future<void> main() async => runZonedGuarded(
      _runMyApp,
      (error, stackTrace) => _reportError(error: error, stackTrace: stackTrace),
    );
```
<!-- END_VERIFY -->
<!-- AI_VERIFY: base_flutter/lib/main.dart#L30-L33 -->
```dart
void _reportError({required error, required StackTrace stackTrace}) {
  Log.e(error, stackTrace: stackTrace, name: 'Uncaught exception');
  FirebaseCrashlytics.instance.recordError(error, stackTrace);
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § _reportError()](./01-code-walk.md#_reporterror--global-error-handler)

**EXPLAIN:**

Dart có concept **Zone** — một execution context bao bọc async operations. `runZonedGuarded` tạo một zone mới với error handler:

```
Zone (error zone)
├── _runMyApp()
│   ├── Firebase.initializeApp()    ← nếu throw → error handler bắt
│   ├── AppInitializer.init()       ← nếu throw → error handler bắt
│   └── runApp(...)                 ← runtime errors → error handler bắt
│
└── onError(error, stackTrace)      ← _reportError()
    ├── Log.e()                     ← log local cho dev
    └── Crashlytics.recordError()   ← report remote cho production
```

**Hai loại error cần handle:**
1. **Synchronous errors** trong zone → `runZonedGuarded` bắt
2. **Flutter framework errors** (widget build, layout) → cần thêm `FlutterError.onError` (không có trong file này, nhưng Flutter default handler print ra console)

> ⚠️ **Lưu ý**: `runZonedGuarded` chỉ bắt Dart async/sync errors. Flutter framework errors (build phase, layout overflow) bị framework catch trước khi đến zone — cần set `FlutterError.onError` riêng để handle. Hiện tại `base_flutter` **chưa set** `FlutterError.onError` — Flutter default handler sẽ print error ra console. Trong production, bạn nên thêm vào `AppInitializer.init()`:
> ```dart
> FlutterError.onError = (details) {
>   Log.e(details.exception, stackTrace: details.stack);
> };
> ```

> 💡 **FE Perspective**
> **Flutter:** `runZonedGuarded` tạo error zone bao bọc toàn bộ app — mọi uncaught exception đều được bắt và report.
> **React/Vue tương đương:** `window.addEventListener('error', handler)` + `unhandledrejection` handler. Crashlytics ≈ Sentry/DataDog.
> **Khác biệt quan trọng:** Dart Zone bắt cả sync + async errors trong cùng một mechanism, FE cần 2 event listeners riêng.

**PRACTICE:** Đọc `_reportError()` — xác nhận tuân thủ [log_instructions.md](../../base_flutter/docs/technical/log_instructions.md): dùng `Log.e()` thay vì `print()`.

> 📌 `LogColor` là enum định nghĩa ANSI color codes cho console output — giúp phân biệt log levels bằng màu sắc. Chi tiết xem [Module 3 — Logging](../module-03-common-layer/02-concept.md).

---

## 4. App Initialization Sequence 🟡 SHOULD-KNOW

**WHY:** Sai thứ tự init = crash. Hiểu sequence để debug khi app không khởi động được.

<!-- AI_VERIFY: base_flutter/lib/app_initializer.dart#L8-L19 -->
```dart
static Future<void> init() async {
  Env.init();
  await configureInjection();
  await getIt.get<PackageHelper>().init();
  await SystemChrome.setPreferredOrientations(
    getIt.get<DeviceHelper>().deviceType == DeviceType.phone
        ? Constant.mobileOrientation
        : Constant.tabletOrientation,
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § app_initializer](./01-code-walk.md#app_initializerdart--khởi-tạo-hệ-thống)

**EXPLAIN:**

Sequence đầy đủ từ `main()` đến screen:

| Bước | Code | Lý do thứ tự |
|------|------|--------------|
| 1 | `ensureInitialized()` | Platform binding — mọi thứ khác cần nó |
| 2 | `FlutterNativeSplash.preserve()` | Giữ splash — UX trong lúc init |
| 3 | `Firebase.initializeApp()` | Firebase SDK — cần binding (bước 1) |
| 4 | `Env.init()` | Đọc environment — DI cần biết flavor |
| 5 | `configureInjection()` | Setup DI container — cần env (bước 4) |
| 6 | `PackageHelper.init()` | Package info — cần DI (bước 5) |
| 7 | `SystemChrome.*` | Orientation + UI mode — cần DI (bước 5) |
| 8 | `runApp(ProviderScope(MyApp))` | Mount widget tree — tất cả init xong |

> 💡 **Note:** Concept table liệt kê **8 bước app-logic chính**. Exercise 1 yêu cầu trace **12 bước đầy đủ** bao gồm thêm 4 bước infrastructure/framework:
> - `main()` entry + `runZonedGuarded` wrapper (bước 1-2 trong Exercise)
> - `_loadInitialResource()` (pre-mount data loading)
> - `ProviderScope` + `AppProviderObserver` setup (Riverpod wrapper)
>
> 4 bước này là boilerplate/framework wrappers — không thuộc core init logic nhưng cần thiết để trace toàn bộ boot path. Đã giải thích tại [01-code-walk § main()](./01-code-walk.md#main--entry-point-với-error-boundary) và [01-code-walk § _runMyApp()](./01-code-walk.md#_runmyapp--boot-sequence).

> ⚠️ **Exercise Note**: Bài tập Exercise 1 yêu cầu liệt kê **12 bước** bao gồm cả 4 bước framework wrapper (`WidgetsFlutterBinding`, `runZonedGuarded`, `FlutterError.onError`, `runApp`). Xem [03-exercise.md](03-exercise.md) để biết chi tiết.

**Dependency chain:** Bước N phụ thuộc bước N-1. Đảo thứ tự = runtime error.

> 💡 **FE Perspective**
> **Flutter:** `AppInitializer.init()` chạy tuần tự: Env → DI → PackageHelper → SystemChrome. Mỗi bước phụ thuộc bước trước.
> **React/Vue tương đương:** Angular `APP_INITIALIZER` token hoặc Nuxt.js plugins system — chạy tuần tự khi boot.
> **Khác biệt quan trọng:** Flutter init bao gồm platform-specific steps (orientation, UI mode) mà web FE không có.

**PRACTICE:** Vẽ diagram boot sequence trên giấy/whiteboard, đánh số từ 1-8.

---

## 5. Dependency Injection (get_it + injectable) 🟡 SHOULD-KNOW

**WHY:** DI là cách project tổ chức dependencies. Không hiểu DI = không thể thêm service mới.

<!-- AI_VERIFY: base_flutter/lib/di.dart#L8-L16 -->
```dart
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
→ Đã đọc trong [01-code-walk § di.dart](./01-code-walk.md#didart--dependency-injection-setup)

**EXPLAIN:**

DI trong project dùng 2 package phối hợp:

| Package | Vai trò | Khi nào chạy |
|---------|---------|--------------|
| `get_it` | Service locator — container chứa dependencies | Runtime |
| `injectable` | Annotation + codegen → auto-register | Build time |

**Flow đăng ký dependency:**
```
1. Developer annotate class:   @injectable class UserRepo { ... }
2. Chạy make fb:               injectable_generator scan annotations
3. Generate di.config.dart:     getIt.registerFactory(() => UserRepo(...))
4. Runtime configureInjection():getIt.init() → tất cả dependency sẵn sàng
5. Sử dụng:                    getIt.get<UserRepo>()
```

**`ServiceModule`** — pattern cho third-party classes (không thể annotate trực tiếp):
- `@module` — đánh dấu class chứa factory methods
- `@preResolve` — resolve async trước khi DI container ready
- `SharedPreferences.getInstance()` là `Future` → cần `@preResolve`

> 💡 **FE Perspective**
> **Flutter:** `GetIt` + `@injectable` annotation → codegen auto-register tất cả dependency. Zero reflection, zero runtime cost.
> **React/Vue tương đương:** InversifyJS container hoặc NestJS `@Injectable()` decorator.
> **Khác biệt quan trọng:** Dart codegen toàn bộ DI registration (build-time), JS DI frameworks dùng reflection/metadata (runtime overhead).

> Sẽ deep dive DI patterns ở [Module 2 — Architecture](../module-02-architecture-barrel/).

**PRACTICE:** Mở [di.dart](../../base_flutter/lib/di.dart), xác nhận `configureInjection()` được gọi từ `AppInitializer.init()` (M0 đã học: cặp `injectable` ↔ `injectable_generator` trong [pubspec.yaml](../../base_flutter/pubspec.yaml)).

---

## 6. ProviderScope — Riverpod Root 🟢 AI-GENERATE

**WHY:** Mọi Riverpod provider đều cần `ProviderScope` ở root. Thiếu = runtime crash.

<!-- AI_VERIFY: base_flutter/lib/main.dart#L24-L28 -->
```dart
runApp(ProviderScope(
  observers: [AppProviderObserver()],
  child: MyApp(initialResource: initialResource),
));
```
<!-- END_VERIFY -->
→ Đã đọc trong [01-code-walk § _runMyApp()](./01-code-walk.md#_runmyapp--boot-sequence)

**EXPLAIN:**

`ProviderScope` là **root widget** của Riverpod state management:

- Tạo `ProviderContainer` — nơi lưu trữ state của tất cả providers
- **Phải wrap** toàn bộ widget tree (đặt ở ngoài cùng, trước `MyApp`)
- `observers` — list các observer để hook vào lifecycle:
  - `AppProviderObserver` log khi provider create/update/dispose/fail (debug tool)

```
ProviderScope (container lưu state)
└── MyApp (root widget)
    └── ... (widget tree — provider consumers)
```

> Đây chỉ là introduction. Deep dive Riverpod tại [Module 8 — State Management](../module-08-riverpod-state/).

> 💡 **FE Perspective**
> **Flutter:** `ProviderScope` là root widget của Riverpod — tạo container lưu state cho tất cả providers.
> **React/Vue tương đương:** React `<Provider store={store}>` (Redux) hoặc Vue `app.use(pinia)`.
> **Khác biệt quan trọng:** Riverpod providers tự register qua codegen, không cần truyền store object. `AppProviderObserver` ≈ Redux DevTools middleware.

**PRACTICE:** Mở [app_provider_observer.dart](../../base_flutter/lib/ui/base/app_provider_observer.dart). Đọc 4 override methods (`didAddProvider`, `didDisposeProvider`, `didUpdateProvider`, `providerDidFail`). Xác nhận dùng `Log.d()` cho logging (tuân thủ [log_instructions.md](../../base_flutter/docs/technical/log_instructions.md)).

---

## Badge Summary

| # | Concept | Badge |
|---|---------|-------|
| 1 | Flutter App Entry Point | 🔴 MUST-KNOW |
| 2 | WidgetsFlutterBinding | 🔴 MUST-KNOW |
| 3 | runZonedGuarded | 🟡 SHOULD-KNOW |
| 4 | Init Sequence | 🟡 SHOULD-KNOW |
| 5 | DI (get_it + injectable) | 🟡 SHOULD-KNOW |
| 6 | ProviderScope | 🟢 AI-GENERATE |
| 7 | Firebase Integration | 🟢 AI-GENERATE |

**Phân bố:** 🔴 ~29% · 🟡 ~43% · 🟢 ~28%
---

## 7. Firebase Integration 🟢 AI-GENERATE

**WHY:** Firebase được init trong boot sequence nhưng thường bị bỏ qua. Hiểu cách Firebase khởi tạo và integrate với Flutter giúp debug issues khi app không nhận push notifications hoặc crashlytics không hoạt động.

<!-- AI_VERIFY: base_flutter/lib/main.dart -->

**EXPLAIN:**

**Boot sequence với Firebase:**

```dart
// main.dart
await Firebase.initializeApp();           // Bước 1: Init Firebase
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError; // Bước 2: Crashlytics
```

**3 Firebase services trong base_flutter:**

| Service | Package | Mục đích |
|---------|---------|---------|
| Firebase Core | `firebase_core` | App init |
| Crashlytics | `firebase_crashlytics` | Crash reporting |
| Messaging | `firebase_messaging` | Push notifications |

> Chi tiết Firebase Messaging trong [Module Optional B — Push & Deep Linking](../module-optional-B-push-deeplink/).

> Firebase Flutter dùng platform channels bên dưới — FlutterFire plugins wrap native SDK. Xem [Module Optional A — Platform Channels](../module-optional-A-platform-channels/).

**PRACTICE:** Trace Firebase init trong `main.dart`. Tìm `Firebase.initializeApp()` và `FirebaseCrashlytics.instance.recordFlutterError`.

---

📖 [Glossary](../_meta/glossary.md)
<!-- AI_VERIFY: generation-complete -->