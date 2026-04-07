# Module 18 – Code Walk: Testing Infrastructure & Unit Test Case Study

> **Mục tiêu**: Đọc hiểu test infrastructure — global config, mock setup, test utilities, và unit test thực tế với `LoginViewModel`.

📌 **Recap**: M7 (BaseViewModel) · M8 (Riverpod providers) · M15 (LoginViewModel flow)

---

## 1. Test Folder Structure

<!-- AI_VERIFY: section-structure -->

```
test/
├── flutter_test_config.dart     ← Global config: golden toolkit, font loading, threshold
├── common/
│   ├── base_test.dart           ← Global mocks registration (setUpAll/setUp)
│   ├── test_config.dart         ← Test device sizes, locale, theme config
│   ├── test_device.dart         ← Device abstraction cho golden tests
│   ├── test_util.dart           ← Helper: createContainer, buildRouterMaterialApp
│   └── index.dart               ← Barrel export
├── unit_test/
│   ├── common/util/             ← Utility tests
│   ├── data_source/database/    ← Database layer tests
│   └── ui/page/
│       ├── login/view_model/    ← ⭐ LoginViewModel test — case study
│       └── ...
├── widget_test/ui/              ← Widget + Golden tests
└── assets/                      ← Mock assets

integration_test/
├── t1_login_failed.dart         ← E2E login flow test
├── common/                      ← Integration test utilities
├── screenshots/                 ← Captured screenshots
└── test_driver/                 ← Test driver entry point
```
<!-- END_VERIFY -->

Flutter tách rõ `test/` (fast, in-process) và `integration_test/` (cần device/emulator). `flutter_test_config.dart` = global setup tương đương `jest.config.ts`.

---

## 2. flutter_test_config.dart — Global Test Configuration

<!-- AI_VERIFY: base_flutter/test/flutter_test_config.dart -->
📂 `../../base_flutter/test/flutter_test_config.dart`

```dart
// Flutter test runner tự động gọi testExecutable()
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      adjustDiff();        // ← Custom golden comparator
      await loadFonts();   // ← Load tất cả fonts cho golden tests
      base.main();         // ← Gọi base_test.dart setup mocks
      return testMain();
    },
    config: GoldenToolkitConfiguration(enableRealShadows: true),
  );
}
```

### 2.1 adjustDiff() — Custom Golden Threshold

```dart
void adjustDiff() {
  const _acceptableErrorThresholdValue = 0.003 / 100; // ← 0.003% tolerance

  if (goldenFileComparator is LocalFileComparator) {
    final testUrl = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = LocalFileComparatorWithThreshold(
      Uri.parse('$testUrl/test.dart'),
      acceptableErrorThresholdValue: _acceptableErrorThresholdValue,
    );
  }
}
```

Golden images khác nhau nhỏ giữa các máy (font rendering, anti-aliasing) — threshold 0.003% tránh false-positive. `LocalFileComparatorWithThreshold` extends `LocalFileComparator`, override `compare()` để pass khi `diffPercent <= threshold`.

### 2.2 loadFonts() — Font Loading cho Golden Tests

```dart
Future<void> loadFonts() async {
  await loadAppFonts();  // ← GoldenToolkit built-in

  // MaterialIcons từ Flutter SDK
  final materialIconsFontLoader = FontLoader('MaterialIcons')..addFont(_loadMaterialIconFont());
  await materialIconsFontLoader.load();

  // NotoSansJP — 9 weights cho CupertinoSystemDisplay + CupertinoSystemText
  final fontSFDisplayLoader = FontLoader('CupertinoSystemDisplay')
    ..addFont(rootBundle.load('.../NotoSansJP-Regular.ttf'))
    ..addFont(rootBundle.load('.../NotoSansJP-Thin.ttf'));
    // ... (9 weights total)
  await fontSFDisplayLoader.load();

  // CupertinoIcons
  final cupertinoIconsFontLoader = FontLoader('packages/cupertino_icons/CupertinoIcons')
    ..addFont(rootBundle.load('assets/fonts/Cupertino/CupertinoIcons.ttf'));
  await cupertinoIconsFontLoader.load();
}
```

Nếu không load fonts, golden images render text bằng Ahem font (monospaced rectangles) → không match pixel-perfect.

---

## 3. base_test.dart — Global Mock Registration

<!-- AI_VERIFY: base_flutter/test/common/base_test.dart -->
📂 `../../base_flutter/test/common/base_test.dart`

```dart
void main() {
  // ① Set locale, color, theme trước mọi test
  LocaleSettings.setLocaleRawSync(TestConfig.defaultLocale.languageCode);
  AppColors.current = AppColors.defaultAppColor;
  AppThemes.currentAppThemeType = AppThemeType.light;

  // ② setUpAll: chạy 1 lần — register fallback values cho mocktail
  setUpAll(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    HttpOverrides.global = null;

    registerFallbackValue(RequestOptions());
    registerFallbackValue(DioException(requestOptions: RequestOptions()));
    registerFallbackValue(const PageRouteInfo(''));
    registerFallbackValue(const RemoteMessage());
    registerFallbackValue(RestMethod.get);
    // ...
  });

  // ③ setUp: chạy trước MỖI test — wire up mock providers
  setUp(() {
    initializeDateFormatting();

    when(() => ref.read(appNavigatorProvider)).thenReturn(navigator);
    when(() => ref.read(exceptionHandlerProvider)).thenReturn(exceptionHandler);
    when(() => ref.read(appPreferencesProvider)).thenReturn(appPreferences);
    when(() => ref.read(appApiServiceProvider)).thenReturn(appApiService);
    // ... tất cả core providers
  });

  // ④ tearDown: reset toàn bộ mock state
  tearDown(() {
    resetMocktailState();
  });
}
```

**Key:** `registerFallbackValue()` — mocktail yêu cầu khi dùng `any()` matcher với non-nullable types (Dart null-safety, JS không cần). `resetMocktailState()` đảm bảo test isolation.

---

## 4. test_util.dart — Test Helpers

<!-- AI_VERIFY: base_flutter/test/common/test_util.dart -->
📂 `../../base_flutter/test/common/test_util.dart`

### 4.1 createContainer() — ProviderContainer cho Unit Tests

```dart
static ProviderContainer createContainer({
  ProviderContainer? parent,
  List<Override> overrides = const [],
  List<ProviderObserver>? observers,
}) {
  final container = ProviderContainer(
    parent: parent,
    overrides: overrides,
    observers: observers,
  );
  addTearDown(container.dispose);  // ← Tự cleanup sau mỗi test
  return container;
}
```

### 4.2 buildRouterMaterialApp() — Full Widget Tree cho Widget/Golden Tests

```dart
static Widget buildRouterMaterialApp({
  required PageRouteInfo<dynamic> initialRoute,
  required AppRouter appRouter,
  bool isDarkMode = false,
  Locale locale = TestConfig.defaultLocale,
}) {
  return MediaQuery(
    data: const MediaQueryData(
      size: Size(Constant.designDeviceWidth, Constant.designDeviceHeight),
    ),
    child: Builder(builder: (context) {
      return TranslationProvider(
        child: MaterialApp.router(
          routerDelegate: appRouter.delegate(
            deepLinkBuilder: (_) => DeepLink([initialRoute]),
          ),
          theme: lightTheme,
          darkTheme: darkTheme,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      );
    }),
  );
}
```

Widget/golden tests render UI thực tế — cần `MaterialApp`, `MediaQuery`, localization, theme, routing context đầy đủ (tương đương custom `render()` wrapper trong React Testing Library).

---

## 5. ⭐ Case Study: login_view_model_test.dart

<!-- AI_VERIFY: base_flutter/test/unit_test/ui/page/login/view_model/login_view_model_test.dart -->
📂 `../../base_flutter/test/unit_test/ui/page/login/view_model/login_view_model_test.dart`

### 5.1 Setup Pattern

```dart
void main() {
  late LoginViewModel loginViewModel;

  setUp(() {
    loginViewModel = LoginViewModel(ref);  // ← ref đã mock sẵn từ base_test.dart
  });
```

> 💡 **Về `ref` trong tests**: `ref` là mock `WidgetRef` được define trong `base_test.dart` (test utilities). File này auto-import qua barrel file test, nên `ref` available trong mọi test file mà không cần setup riêng. Xem [base_test.dart](../../base_flutter/test/common/base_test.dart).

### 5.2 Group Structure: happy / unhappy

```dart
  group('setEmail', () {
    group('happy', () {
      test('when email is changed', () {
        const dummyEmail = 'test@example.com';
        loginViewModel.setEmail(dummyEmail);
        expect(loginViewModel.data.email, dummyEmail);
        expect(loginViewModel.data.onPageError, '');
      });
    });
    group('unhappy', () {}); // ← Explicit empty cho simple state updates
  });
```

Convention: mỗi method có `group('happy')` + `group('unhappy')`.

### 5.3 Login Happy Path — Full Mock Chain

```dart
  group('login', () {
    const dummyEmail = 'test@example.com';
    const dummyPassword = 'Password1!';
    const dummyLoginResponse = TokenAndRefreshTokenData(
      accessToken: 'access_token_1',
      refreshToken: 'refresh_token_1',
    );

    group('happy', () {
      test('when login succeeds', () async {
        // ① Arrange: set state + mock dependencies
        loginViewModel.setEmail(dummyEmail);
        loginViewModel.setPassword(dummyPassword);

        when(() => appApiService.login(
              email: dummyEmail, password: dummyPassword,
            )).thenAnswer((_) async => dummyLoginResponse);
        when(() => sharedViewModel.deviceToken).thenAnswer((_) async => 'fcm_token');
        when(() => appPreferences.saveAccessToken(any())).thenAnswer((_) async => true);
        when(() => appPreferences.saveRefreshToken(any())).thenAnswer((_) async => true);
        when(() => appPreferences.saveIsLoggedIn(true)).thenAnswer((_) async => true);
        when(() => navigator.replaceAll(any())).thenAnswer((_) async => true);

        // ② Act
        await loginViewModel.login();

        // ③ Assert: verify side effects
        verify(() => appApiService.login(
              email: dummyEmail, password: dummyPassword,
            )).called(1);
        verify(() => appPreferences.saveAccessToken('access_token_1')).called(1);
        verify(() => navigator.replaceAll([MainRoute()])).called(1);
      });
    });
```

### 5.4 Login Unhappy Path — Error Handling

```dart
    group('unhappy', () {
      test('when login fails with network error', () async {
        loginViewModel.setEmail(dummyEmail);
        loginViewModel.setPassword(dummyPassword);

        when(() => appApiService.login(
              email: dummyEmail, password: dummyPassword,
            )).thenThrow(RemoteException(kind: RemoteExceptionKind.network));

        await loginViewModel.login();

        expect(loginViewModel.data.onPageError, isNotEmpty);
        verifyNever(() => navigator.replaceAll(any()));  // ← Không navigate khi lỗi
      });
    });
```

Test unhappy path verify cả **state** (error message) VÀ **side effect** (không navigate).

---

## 6. Widget Tests — Render & Interact với UI Components

Widget test = tầng giữa testing pyramid — nhanh hơn integration test, nhưng kiểm tra UI behavior thực tế mà unit test không cover.

### 6.1 Widget Test File Structure

<!-- AI_VERIFY: base_flutter/test/widget_test/ui/component/primary_text_field/primary_text_field_test.dart -->
📂 `../../base_flutter/test/widget_test/ui/component/primary_text_field/primary_text_field_test.dart`

```dart
void main() {
  group('PrimaryTextField', () {
    // ① Render test — golden snapshot khi text rỗng
    testGoldens('when text is empty', (tester) async {
      await tester.testWidget(
        filename: 'PrimaryTextField/when text is empty',
        widget: PrimaryTextField(
          title: 'Email', hintText: 'Email',
          controller: TextEditingController(text: ''),
        ),
      );
    });

    // ② Interaction test — tap eye icon toggle
    testGoldens('when tapping on the eye icon once', (tester) async {
      await tester.testWidget(
        filename: 'PrimaryTextField/when tapping on the eye icon once',
        widget: PrimaryTextField(
          title: 'Password', hintText: 'Password',
          controller: TextEditingController(text: '123456'),
          keyboardType: TextInputType.visiblePassword,
        ),
        onCreate: (tester, key) async {
          final eyeIconFinder = find.byType(GestureDetector)
              .isDescendantOfKeyIfAny(key);
          expect(eyeIconFinder, findsOneWidget);
          await tester.tap(eyeIconFinder);
        },
      );
    });
  });
}
```

Codebase dùng `testGoldens` (từ `golden_toolkit`) kết hợp render + golden snapshot. `tester.testWidget()` wrap sẵn ProviderScope + MaterialApp — không cần viết boilerplate.

> ⚠️ **Project-specific API:** `testWidget()` là custom helper của project này, KHÔNG phải Flutter SDK API. Flutter SDK dùng `testWidgets()` (có 's'). Xem thêm bảng so sánh tại [02-concept.md § Quick Reference](./02-concept.md#quick-reference).

### 6.2 WidgetTester API Cheat Sheet

| Category | API | Mục đích |
|----------|-----|----------|
| **Render** | `pumpWidget(widget)` | Build + render frame đầu tiên |
| | `pump()` | Render 1 frame tiếp (sau tap/enterText) |
| | `pump(duration)` | Advance time rồi render (timer, debounce) |
| | `pumpAndSettle()` | Pump liên tục until no pending frames |
| **Find** | `find.text('Login')` | Tìm widget chứa text |
| | `find.byType(ElevatedButton)` | Tìm theo type |
| | `find.byKey(Key('id'))` | Tìm theo Key |
| | `find.descendant(of:, matching:)` | Tìm widget con trong widget cha |
| **Assert** | `findsOneWidget` | Đúng 1 widget |
| | `findsNothing` | Không tìm thấy |
| | `findsNWidgets(n)` | Đúng N widgets |
| **Interact** | `tester.tap(finder)` | Tap |
| | `tester.enterText(finder, text)` | Nhập text |
| | `tester.drag(finder, offset)` | Drag/scroll |

### 6.3 Wrapping Widget — ProviderScope + Overrides

```dart
// Codebase pattern — testWidget() là PROJECT CUSTOM helper, wrap ProviderScope + MaterialApp tự động
// ⚠️ Không nhầm với Flutter SDK testWidgets() (có 's')
await tester.testWidget(
  widget: MyWidget(),
  overrides: [someProvider.overrideWith(...)],
);

// Manual wrapping khi cần custom setup:
await tester.pumpWidget(
  ProviderScope(
    overrides: [loginViewModelProvider.overrideWith((_) => mockVM)],
    child: MaterialApp(theme: lightTheme, home: const LoginPage()),
  ),
);
```

### 6.4 Interaction + Assert Pattern

```dart
testWidgets('login button disabled when fields empty', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [/* mock providers */],
      child: const MaterialApp(home: LoginPage()),
    ),
  );

  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  expect(button.onPressed, isNull);  // ← onPressed == null → disabled
});
```

---

## 7. Integration Test Overview

<!-- AI_VERIFY: base_flutter/integration_test/t1_login_failed.dart -->
📂 `../../base_flutter/integration_test/t1_login_failed.dart`

```dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('t1 login failed', (tester) async {
    await tester.runAsync(app.main);          // ← Launch real app
    await tester.openLoginPage();

    await tester.enterText(find.byType(PrimaryTextField).first, 'a');
    await tester.pumpWithDuration(1.seconds);
    await tester.enterText(find.byType(PrimaryTextField).last, 'b');
    await tester.pumpWithDuration(1.seconds);
    await tester.dismissOnScreenKeyboard();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpWithDuration(5.seconds);

    await tester.takeScreenShot(
      binding: binding,
      fileName: 't1/t1_login_failed.png',
    );
  });
}
```

Integration test launch real app trên emulator, interact, capture screenshot. Khác widget test: chạy trên device thật, chậm hơn, nhưng test full integration.

---

## 8. Makefile Commands

```makefile
ut:        # flutter test test/unit_test
wt:        # flutter test test/widget_test
te:        # make ut + make wt
ug:        # Update goldens: flutter test --update-goldens --tags=golden
cov:       # flutter test --coverage + lcov filter + genhtml
cov_ut:    # Coverage unit tests only
cov_wt:    # Coverage widget tests only
```

---

## 9. dart_test.yaml — Minimal Config

<!-- AI_VERIFY: base_flutter/dart_test.yaml -->
📂 `../../base_flutter/dart_test.yaml`

```yaml
tags:
  golden:
```

Custom tag `golden` — chạy/skip golden tests riêng bằng `--tags=golden` hoặc `--exclude-tags=golden`.

---

## Tổng kết Flow

```
flutter test
  → flutter_test_config.dart::testExecutable()
    → GoldenToolkit.runWithConfiguration()
      → adjustDiff()          (set threshold comparator)
      → loadFonts()           (load real fonts)
      → base_test.main()      (register mocks globally)
      → testMain()            (chạy actual test files)
```

Mỗi test file nhận được: **mocks sẵn sàng** + **fonts loaded** + **golden threshold configured** — chỉ cần focus viết test logic.

→ **Tiếp theo**: [02-concept.md](./02-concept.md) — Đi sâu 7 concepts testing trong Flutter.

<!-- AI_VERIFY: generation-complete -->
