# Flutter Training Glossary

>Tài liệu tham khảo nhanh cho các thuật ngữ xuyên suốt chương trình training. Link đến tất cả 23 modules — nếu thuật ngữ chưa rõ, click vào module tương ứng để đọc thêm.

---

## A

### Abstract Widget
Xem [Widget](#w).

### Access Token Interceptor
Dio interceptor tự động inject `Authorization: Bearer <token>` vào mọi request. Xem [Module 13 — Middleware & Interceptors](../module-13-middleware-interceptor-chain/).

### AI-GENERATE (🟢 Badge)
Concept mà AI có thể generate, developer chỉ cần verify output. Ví dụ: Freezed models, injectable config. Xem [Badge System](../../README.md#%EF%B8%8F-badge-system--skill-triage-cho-thời-đại-ai).

### AI_VERIFY Tag
`<!-- AI_VERIFY: path/to/file.dart -->` — comment trong markdown trỏ đến source file thực trong `base_flutter/`, đảm bảo docs luôn đồng bộ với code. Tồn tại trong tất cả `01-code-walk.md` files.

### AppException
Base class cho tất cả exceptions trong ứng dụng. Xem [Module 4 — Exception Handling](../module-04-exception-handling/).

### AppApiService
Service facade — single entry point cho tất cả API calls từ ViewModel. Xem [Module 12 — Data Layer](../module-12-data-layer/).

### AsyncValue
Riverpod class wrap data + state (loading, error, data). Tương đương React state: `{ data, isLoading, error }`. Xem [Module 8 — Riverpod](../module-08-riverpod-state/).

---

## B

### Barrel File (index.dart)
File export tất cả modules trong một folder. Tương đương React `index.js` barrel exports. Xem [Module 2 — Architecture](../module-02-architecture-barrel/).

### BasePage
Abstract page class chuẩn hoá: `CommonScaffold`, error handling, loading state. Xem [Module 7 — Base ViewModel](../module-07-base-viewmodel/).

### BaseViewModel
Abstract ViewModel class cung cấp `runCatching`, `isLoading`, `error` shared logic. Tương đương React custom hook với error boundary. Xem [Module 7 — Base ViewModel](../module-07-base-viewmodel/).

### Badge System
Hệ thống phân loại concept: 🔴 MUST-KNOW (tự viết), 🟡 SHOULD-KNOW (AI assist), 🟢 AI-GENERATE (AI generate). Xem [Badge System](../../README.md#%EF%B8%8F-badge-system--skill-triage-cho-thời-đại-ai).

### BuildContext
Handle để truy cập InheritedWidget và theme/navigator. Tương đương React `this.context`. Xem [Module 6 — Resource & Theme](../module-06-resource-theme/).

### BuildRunner
CLI tool chạy code generation (freezed, injectable, auto_route, slang). Chạy: `dart run build_runner build --delete-conflicting-outputs`.

---

## C

### Clean Architecture
Phân chia layer: Presentation → Domain → Data. Mỗi layer chỉ phụ thuộc layer bên trong. Xem [Module 2 — Architecture](../module-02-architecture-barrel/).

### Codemagic
CI/CD platform chuyên Flutter. Tự động build iOS/Android từ git push. Xem [Module 19 — CI/CD](../module-19-cicd/).

### CommonScaffold
Wrapper widget cung cấp AppBar, loading overlay, error snackbar chuẩn hoá. Xem [Module 7 — Base ViewModel](../module-07-base-viewmodel/).

### Consumer
Riverpod widget để đọc/watch provider. Tương đương React `useSelector`. Xem [Module 8 — Riverpod](../module-08-riverpod-state/).

### ConsumerStatefulWidget
StatefulWidget có sẵn Riverpod `ref`. Được dùng trong base_flutter cho pages. Xem [Module 8 — Riverpod](../module-08-riverpod-state/).

### ConsumerWidget
StatelessWidget có sẵn Riverpod `ref`. Tương đương React functional component với hooks. Xem [Module 8 — Riverpod](../module-08-riverpod-state/).

### CopyWith
Method trên immutable object (Freezed) để tạo bản sao với một số field thay đổi. Tương đương `{ ...obj, field: newValue }` trong JS. Xem [Module 12 — Data Layer](../module-12-data-layer/).

---

## D

### Deep Linking
Mở app từ URL (ví dụ: `myapp://profile/123`). Xem [Module 5 — Navigation](../module-05-navigation/).

### Dependency Injection (DI)
Pattern inject dependencies vào class qua constructor thay vì khởi tạo bên trong. Dùng `get_it` + `injectable`. Xem [Module 2 — Architecture](../module-02-architecture-barrel/).

### Dio
HTTP client library cho Flutter. Tương đương Axios trong React. Xem [Module 12 — Data Layer](../module-12-data-layer/).

### Dio Interceptor
Middleware hook chạy trước/sau mỗi Dio request. Tương đưng Axios interceptor. Xem [Module 13 — Middleware & Interceptors](../module-13-middleware-interceptor-chain/).

### DioException
Exception được Dio throw khi request thất bại. Map sang `RemoteException` qua `DioExceptionMapper`. Xem [Module 4 — Exception Handling](../module-04-exception-handling/).

### doParse
Pattern map error response JSON sang domain exception. Xem [Module 12 — Data Layer](../module-12-data-layer/).

---

## E

### Element Tree
Tree trung gian giữa Widget và RenderObject. Flutter so sánh element tree để xác định widget nào cần rebuild. Xem [Module 17 — Performance & Animation](../module-17-performance-animation/).

### EncryptedSharedPreferences
SharedPreferences với mã hoá AES. Dùng lưu access token, refresh token. Xem [Module 14 — Local Storage](../module-14-local-storage/).

### Error Boundary
Pattern bắt và xử lý error trong widget tree. Tương đương React ErrorBoundary. Xem [Module 4 — Exception Handling](../module-04-exception-handling/).

### ExceptionHandler
Singleton xử lý error — log, show snackbar, navigate to error page. Xem [Module 4 — Exception Handling](../module-04-exception-handling/).

### ExceptionMapper
Interface map exception sang user-friendly message. `DioExceptionMapper` implements cho Dio errors. Xem [Module 4 — Exception Handling](../module-04-exception-handling/).

---

## F

### Failure
Sealed class đại diện cho error state. Dùng với `Either<Failure, Success>`. Xem [Module 4 — Exception Handling](../module-04-exception-handling/).

### Freezed
Code generation library tạo immutable data classes với `copyWith`, `fromJson`, `toJson`, `==`, `hashCode`. Tương đương Immer + Zod trong React. Xem [Module 0 — Dart Primer](../module-00-dart-primer/).

### Frontend ↔ Flutter Bridge
💡 Callout box trong tài liệu ánh xạ concept từ React/Vue/Angular sang Flutter tương ứng. Tìm kiếm `💡 FE Perspective` trong các file concept.

### Future
Dart type cho asynchronous computation có thể thất bại. Tương đương JavaScript Promise. Xem [Module 0 — Dart Primer](../module-00-dart-primer/).

---

## G

### Generator (Code Generator)
Tool tự động tạo code từ annotations. Ví dụ: Freezed, injectable, auto_route, slang. Xem [BuildRunner](#b).

### get_it
Service locator — global registry cho dependencies. Dùng với `injectable` annotations. Xem [Module 2 — Architecture](../module-02-architecture-barrel/).

---

## H

### Hero Animation
Widget animate một element giữa hai screens. Tương đương Framer Motion `layoutId`. Xem [Module 17 — Performance & Animation](../module-17-performance-animation/).

### HookConsumerWidget
Widget kết hợp Flutter Hooks + Riverpod Consumer. Xem [Module 10 — Flutter Hooks](../module-10-hooks/).

### Hooks (Flutter Hooks)
Functions reuse logic trong widget (useState, useEffect, useRef). API gần như **y hệt** React Hooks. Xem [Module 10 — Flutter Hooks](../module-10-hooks/).

### Hot Reload
Reload code trong ~1 giây, giữ nguyên app state. Dùng khi UI/thứ logic thay đổi.

### Hot Restart
Restart app hoàn toàn, mất app state. Dùng khi thay đổi `main()` hoặc init logic.

---

## I

### i18n (Internationalization)
Multi-language support. Dùng `slang` package — YAML/JSON translation files. Xem [Module 11 — i18n](../module-11-i18n/).

### Immutable Object
Object không thể thay đổi sau khi tạo. Muốn thay đổi → tạo bản sao qua `copyWith`. Freezed tự generate immutable classes. Xem [Module 12 — Data Layer](../module-12-data-layer/).

### Injectable
Annotations (`@LazySingleton`, `@injectable`) cho dependency injection code generation. Xem [Module 2 — Architecture](../module-02-architecture-barrel/).

### Interceptor Chain
Chuỗi Dio interceptors chạy theo thứ tự: connectivity → access token → refresh token → retry → log. Xem [Module 13 — Middleware & Interceptors](../module-13-middleware-interceptor-chain/).

### Isar
NoSQL database cho Flutter (thay thế SQLite). Dùng cho local data persistence. Xem [Module 14 — Local Storage](../module-14-local-storage/).

---

## L

### Late Initialization
`late` keyword cho phép khai báo non-nullable field được init sau. Tương đương optional chaining + definite assignment. Xem [Module 0 — Dart Primer](../module-00-dart-primer/).

### localStorage (Flutter equivalent)
Flutter: `SharedPreferences` (simple), `FlutterSecureStorage` (encrypted), `Isar` (database). Xem [Module 14 — Local Storage](../module-14-local-storage/).

---

## M

### MediaQuery
Widget/extension cung cấp device info (screen size, padding, orientation). Tương đương CSS media queries + `window` object. Xem [Module 6 — Resource & Theme](../module-06-resource-theme/).

### Method Channel
Cơ chế gọi native iOS/Android code từ Flutter. Xem [Module Optional A — Platform Channels](../module-optional-A-platform-channels/).

### Mixin
Dart language feature cho code reuse mà không có diamond problem của multiple inheritance. Tương đương React mixin hoặc TypeScript intersection type. Xem [Module 0 — Dart Primer](../module-00-dart-primer/).

### MVVM (Model-View-ViewModel)
Pattern phân tách UI (View) khỏi business logic (ViewModel). View observe ViewModel qua Riverpod. Xem [Module 7 — Base ViewModel](../module-07-base-viewmodel/).

---

## N

### Navigator
Flutter navigation system quản lý page stack. Xem [Module 5 — Navigation](../module-05-navigation/).

### Null Safety
Dart type system đảm bảo không có null access at compile time. Tương đương TypeScript strict null checks. Xem [Module 0 — Dart Primer](../module-00-dart-primer/).

---

## O

### Object Pool Pattern
Pattern reuse các object đã tạo thay vì tạo mới liên tục. Xem [Module 17 — Performance & Animation](../module-17-performance-animation/).

---

## P

### Paging
Load data theo page/batch thay vì load all. Dùng `PagingExecutor` trong base_flutter. Xem [Module 16 — Popup, Dialog & Paging](../module-16-popup-dialog-paging/).

### Platform Channel
Cơ chế giao tiếp Flutter ↔ Native (iOS/Android). Gồm MethodChannel (request-response) và EventChannel (stream). Xem [Module Optional A — Platform Channels](../module-optional-A-platform-channels/).

### Provider
Riverpod primitive — provider declaration. Có nhiều loại: `Provider`, `StateNotifierProvider`, `FutureProvider`, `StreamProvider`, `FamilyProvider`. Xem [Module 8 — Riverpod](../module-08-riverpod-state/).

### Push Notification
Thông báo gửi từ server đến device. Dùng Firebase Cloud Messaging (FCM). Xem [Module Optional B — Push & Deep Linking](../module-optional-B-push-deeplink/).

---

## R

### Record (Dart 3)
Anonymous immutable struct. `(int, String)` là record với 2 fields. Tương đương TypeScript tuple nhưng mạnh hơn. Xem [Module 0 — Dart Primer](../module-00-dart-primer/).

### Redirect (Navigation)
Navigation guard kiểm tra auth trước khi cho phép truy cập route. Tương đương React Router `protected` route. Xem [Module 5 — Navigation](../module-05-navigation/).

### Ref
Riverpod object dùng trong provider/body để đọc other providers. Có 3 methods: `ref.watch()` (subscribe), `ref.read()` (one-time read), `ref.listen()` (side-effect). Xem [Module 8 — Riverpod](../module-08-riverpod-state/).

### RefreshTokenInterceptor
Dio interceptor tự động refresh access token khi nhận 401, retry request ban đầu. Xem [Module 13 — Middleware & Interceptors](../module-13-middleware-interceptor-chain/).

### RemoteException
Exception type cho API errors. Có `RemoteExceptionKind` enum phân loại: serverError, networkError, timeout, unauthorized, etc. Xem [Module 4 — Exception Handling](../module-04-exception-handling/).

### RenderObject
Low-level object thực hiện painting/layout. Nằm dưới RenderObject tree. Xem [Module 17 — Performance & Animation](../module-17-performance-animation/).

### RepaintBoundary
Widget ngăn không cho child subtree trigger repaint. Tương đương React.memo hoặc CSS `will-change`. Xem [Module 17 — Performance & Animation](../module-17-performance-animation/).

### Re-Anchor
Section trong overview ôn lại concepts từ previous modules cần nhớ trước khi bắt đầu module mới.

### Result Type
Pattern `Result<T>` wrap `T` data hoặc `AppException` error. Dùng với `runCatching`. Xem [Module 4 — Exception Handling](../module-04-exception-handling/).

### RetryOnErrorInterceptor
Dio interceptor tự động retry request khi gặp network error (không phải 4xx/5xx). Xem [Module 13 — Middleware & Interceptors](../module-13-middleware-interceptor-chain/).

### Riverpod
State management + dependency injection framework. Provider-based, compile-safe, testable. Tương đương Redux/Pinia/Zustand trong React/Vue. Xem [Module 8 — Riverpod](../module-08-riverpod-state/).

### Route Guard
Logic kiểm tra trước khi navigation được phép. Tương đương React Router `loader` hoặc Vue Router `beforeEnter`. Xem [Module 5 — Navigation](../module-05-navigation/).

### runCatching
Extension method wrap Future thành `Result<T>` — data hoặc exception. Tương đương Rust `Result::unwrap_or_else`. Xem [Module 7 — Base ViewModel](../module-07-base-viewmodel/).

---

## S

### Sealed Class
Class giới hạn các subclasses. Flutter dùng cho exhaustive switch expressions. Tương đương TypeScript discriminated union. Xem [Module 0 — Dart Primer](../module-00-dart-primer/).

### Selector
Riverpod method `ref.select()` để rebuild chỉ khi specific field thay đổi. Tương đương React `useSelector` với shallow compare. Xem [Module 8 — Riverpod](../module-08-riverpod-state/).

### Semantics
Widget cung cấp accessibility info cho screen reader. Tương đương ARIA labels trong HTML. Xem [Module 9 — Page Structure](../module-09-page-structure/).

### Shimmer
Animation hiển thị skeleton loading. Dùng `shimmer` package. Xem [Module 17 — Performance & Animation](../module-17-performance-animation/).

### slaml
Flutter i18n library dùng YAML/JSON translation files. Tự generate `app_strings.g.dart`. Xem [Module 11 — i18n](../module-11-i18n/).

### Snapshot Testing
Test UI output bằng cách so sánh với golden file. Xem [Module 18 — Testing](../module-18-testing/).

### StateNotifier
Riverpod class quản lý state với immutable updates. Tương đương Redux reducer + action pattern. Xem [Module 8 — Riverpod](../module-08-riverpod-state/).

### Stream
Dart type cho asynchronous data sequence. Tương đương RxJS Observable. Xem [Module 0 — Dart Primer](../module-00-dart-primer/).

### SuccessResponseDecoder
Strategy pattern decode API response theo format (flat, nested, wrapped). Xem [Module 12 — Data Layer](../module-12-data-layer/).

---

## T

### ThemeData
Flutter theme configuration (colors, typography, appBarTheme, etc.). Tương đương CSS variables + ThemeProvider. Xem [Module 6 — Resource & Theme](../module-06-resource-theme/).

### Three-Tree Rendering Pipeline
Flutter render: **Widget Tree** (config) → **Element Tree** (runtime identity) → **RenderObject Tree** (painting). Xem [Module 17 — Performance & Animation](../module-17-performance-animation/).

---

## V

### ViewModel
Class chứa business logic và state cho một page. Dùng với Riverpod. Tương đương React component state + custom hooks. Xem [Module 7 — Base ViewModel](../module-07-base-viewmodel/).

---

## W

### Widget
Immutable config description cho UI. Tương đương React component render function trả về JSX. Có hai loại: `StatelessWidget` và `StatefulWidget`.

### Widget Tree
Tree structure Flutter dùng để describe UI hierarchy. Tương đương React Virtual DOM tree.

### Widget Testing
Test widget render output và interaction. Dùng `tester.widget()` và `tester.tap()`. Xem [Module 18 — Testing](../module-18-testing/).

---

<!-- AI_VERIFY: generation-complete -->
