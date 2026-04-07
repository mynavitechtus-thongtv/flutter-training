# Module 18 – Concepts: Testing trong Flutter

> **Mục tiêu**: Nắm vững 7 concepts cốt lõi về testing — từ testing pyramid đến golden test configuration.

📌 **Recap**: M7 (BaseViewModel) · M8 (Riverpod providers) · M15 (LoginViewModel)

---

## Concept 1: Testing Pyramid trong Flutter

<!-- AI_VERIFY: concept-1 -->

```
                    ┌──────────┐
                    │Integration│  ← Chậm, đắt, ít test
                    │   Tests   │     (real app, real device)
                    ├──────────┤
                  │  Golden Tests  │  ← Visual regression
                  │  (pixel diff)  │     (snapshot matching)
                  ├────────────────┤
                │    Widget Tests    │  ← Render widget tree
                │  (pump + interact) │     (find, tap, expect)
                ├────────────────────┤
              │      Unit Tests        │  ← Nhanh nhất, nhiều nhất
              │ (ViewModel, Util, Logic)│     (pure logic, mocks)
              └────────────────────────┘
```
<!-- END_VERIFY -->

| Layer | Tốc độ | Scope | Khi nào dùng |
|-------|--------|-------|--------------|
| **Unit** | ~ms | Logic thuần (ViewModel, utils) | Mọi business logic |
| **Widget** | ~100ms | Single widget / page render | UI behavior, layout |
| **Golden** | ~500ms | Pixel comparison | Visual regression, design consistency |
| **Integration** | ~s–min | Full app trên device/emulator | Critical flows (login, checkout) |

**Trong codebase**, tỷ lệ test:
- `test/unit_test/` — nhiều nhất (mỗi ViewModel, mỗi util)
- `test/widget_test/` — widget + golden kết hợp
- `integration_test/` — chỉ critical flows

> 💡 **FE Perspective**
> **Flutter:** Testing pyramid: Unit (ViewModel) → Widget (pump + interact) → Golden (pixel diff) → Integration (real device).
> **React/Vue tương đương:** Unit (Jest) → Component (React Testing Library) → Visual (Storybook + Chromatic/Percy) → E2E (Cypress/Playwright).
> **Khác biệt quan trọng:** Flutter có **Golden test** built-in (pixel comparison). React cần external tool (Percy/Chromatic).

---

## Concept 2: Flutter Test Configuration — flutter_test_config.dart

<!-- AI_VERIFY: concept-2 -->

Flutter test runner tự động tìm `flutter_test_config.dart` ở root của `test/` và gọi hàm `testExecutable()` trước khi chạy bất kỳ test file nào.

### Lifecycle

```
flutter test
  │
  ├─ ① Tìm test/flutter_test_config.dart
  ├─ ② Gọi testExecutable(testMain)
  │     ├─ GoldenToolkit.runWithConfiguration()
  │     ├─ adjustDiff() → set golden comparator threshold
  │     ├─ loadFonts() → load real fonts cho golden
  │     └─ base.main() → register global mocks
  └─ ③ Chạy testMain() → actual test files
```

### Key config trong codebase

| Config | Giá trị | Mục đích |
|--------|---------|----------|
| `enableRealShadows` | `true` | Render shadow thật, không dùng opaque placeholder |
| Threshold | `0.003 / 100` | Cho phép 0.003% pixel difference |
| Fonts loaded | Noto Sans JP (9 weights), MaterialIcons, CupertinoIcons | Render đúng font trong golden |

### Tại sao load fonts?

Mặc định, Flutter test dùng **Ahem font** — mỗi ký tự là một hình vuông đen. Golden test so sánh pixel-perfect, nên cần load font thật để output chính xác.

> 💡 **FE Perspective**
> **Flutter:** `flutter_test_config.dart` chạy trước mọi test file — setup golden toolkit, load fonts, register mocks.
> **React/Vue tương đương:** `jest.config.ts` với `setupFilesAfterFramework`. Load fonts giống config `@font-face` trong JSDOM.
> **Khác biệt quan trọng:** Flutter test mặc định dùng Ahem font (hình vuông đen) — phải load font thật cho golden test.

---

## Concept 2b: Test Doubles Taxonomy — Mock vs Stub vs Fake vs Spy 🟡 SHOULD-KNOW

**WHY:** Trước khi dùng `mocktail`, cần hiểu **4 loại test double** — mỗi loại phục vụ mục đích khác nhau. Nhầm lẫn terminology → test thiết kế sai.

### Taxonomy

| Double | Mục đích | Ví dụ |
|--------|---------|-------|
| **Stub** | Trả về dữ liệu cố định — **không verify** interactions | `when(() => api.login(...)).thenAnswer((_) async => token)` |
| **Mock** | **Verify** method được gọi đúng (đúng args, đúng số lần) | `verify(() => api.login('email', 'pass')).called(1)` |
| **Fake** | Implementation thật nhưng lightweight (in-memory, no I/O) | `class FakePreferences implements AppPreferences { final _map = {}; ... }` |
| **Spy** | Object thật + ghi lại interactions | `mocktail` không có spy riêng — dùng Mock + `when().thenCallRealMethod()` nếu cần |

> 💡 **Insight:** Trong `mocktail`, cùng 1 class `Mock` có thể đóng vai **cả Stub lẫn Mock**:
> - `when().thenReturn(value)` → đang dùng như **Stub** (cung cấp dữ liệu)
> - `verify().called(n)` → đang dùng như **Mock** (kiểm tra behavior)
>
> Codebase project chủ yếu dùng **Stub pattern** — cung cấp fake data để test ViewModel logic.

> 💡 **FE Perspective — Test Doubles**
>
> | Dart / mocktail | Jest / Testing Library |
> |---|---|
> | `class MockApi extends Mock implements Api {}` | `jest.fn()` (auto-mock) hoặc `jest.mock('./api')` |
> | `when(() => mock.method()).thenReturn(v)` | `mockFn.mockReturnValue(v)` — stub behavior |
> | `verify(() => mock.method()).called(1)` | `expect(mockFn).toHaveBeenCalledTimes(1)` — mock verification |
> | `class FakeDb implements Database { ... }` | Manual fake class hoặc `jest.fn()` with full implementation |
> | Không có built-in spy | `jest.spyOn(object, 'method')` — spy on real object |
>
> **Khác biệt quan trọng:** Jest auto-mock tất cả methods khi `jest.mock()`. Dart `Mock` class requires explicit `when()` setup — un-stubbed methods throw `MissingStubError` (fail-fast, an toàn hơn).

### Quick Reference — Mock vs Stub vs Fake

| Type | Purpose | Ví dụ trong codebase | Khi nào dùng |
|------|---------|---------------------|-------------|
| **Mock** | Verify interactions (method được gọi đúng?) | `verify(() => mock.login(...)).called(1)` | Kiểm tra side effects (API called, token saved) |
| **Stub** | Trả về fixed data (không verify) | `when(() => mock.login(...)).thenAnswer((_) async => token)` | Cung cấp data cho test flow |
| **Fake** | Lightweight real implementation | `class FakePreferences implements AppPreferences { final _map = <String, dynamic>{}; }` | Integration-style test không cần mock framework |

> **Trong project:** Cùng 1 `MockAppApiService` class vừa đóng vai **Stub** (cung cấp data qua `when`) vừa đóng vai **Mock** (verify qua `verify`). Phân biệt ở **cách sử dụng**, không phải cách tạo.

---

## Concept 3: Mocktail — Mock Pattern trong Dart

<!-- AI_VERIFY: concept-3 -->

Codebase dùng **mocktail** (not mockito) — không cần codegen, api rõ ràng hơn.

### 3.1 registerFallbackValue

```dart
registerFallbackValue(RequestOptions());
registerFallbackValue(const PageRouteInfo(''));
```

**Khi nào cần?** Khi dùng `any()` matcher với non-nullable types. Mocktail cần biết "fallback value" để tạo matcher.

```dart
// ✅ Hoạt động vì PageRouteInfo đã registerFallbackValue
when(() => navigator.replaceAll(any())).thenAnswer((_) async => true);

// ❌ Sẽ throw nếu chưa registerFallbackValue cho PageRouteInfo
```

### 3.2 when / thenReturn / thenAnswer / thenThrow

```dart
// Sync return
when(() => ref.read(appNavigatorProvider)).thenReturn(navigator);

// Async return
when(() => appApiService.login(email: any(), password: any()))
    .thenAnswer((_) async => loginResponse);

// Throw exception
when(() => appApiService.login(email: any(), password: any()))
    .thenThrow(RemoteException(kind: RemoteExceptionKind.network));
```

### 3.3 verify / verifyNever

```dart
// Xác nhận method được gọi đúng 1 lần với đúng args
verify(() => appPreferences.saveAccessToken('access_token_1')).called(1);

// Xác nhận method KHÔNG được gọi (unhappy path)
verifyNever(() => navigator.replaceAll(any()));
```

### 3.4 resetMocktailState

```dart
tearDown(() {
  resetMocktailState();  // ← Reset tất cả interaction history
});
```

Quan trọng để đảm bảo **test isolation** — `verify().called(1)` không bị ảnh hưởng bởi test trước.

> 💡 **FE Perspective**
> **Flutter:** mocktail: `when().thenReturn()`, `verify().called(1)`, `registerFallbackValue()` cho non-nullable types.
> **React/Vue tương đương:** Jest mock: `jest.fn().mockReturnValue()`, `expect(fn).toHaveBeenCalledTimes(1)`.
> **Khác biệt quan trọng:** `registerFallbackValue` không có equivalent trong Jest — do Dart null-safety yêu cầu fallback cho `any()` matcher.

---

## Concept 4: Unit Testing ViewModels — Pattern & Convention

<!-- AI_VERIFY: concept-4 -->

### 4.1 Arrange-Act-Assert (AAA) Pattern

```dart
test('when login succeeds', () async {
  // ── Arrange ──
  loginViewModel.setEmail(dummyEmail);
  loginViewModel.setPassword(dummyPassword);
  when(() => appApiService.login(...)).thenAnswer((_) async => response);
  when(() => appPreferences.saveAccessToken(any())).thenAnswer((_) async => true);

  // ── Act ──
  await loginViewModel.login();

  // ── Assert ──
  verify(() => appPreferences.saveAccessToken('token')).called(1);
  verify(() => navigator.replaceAll([MainRoute()])).called(1);
});
```

### 4.2 Group Convention: happy / unhappy

```dart
group('methodName', () {
  group('happy', () {
    test('when success scenario', () { ... });
  });
  group('unhappy', () {
    test('when error scenario', () { ... });
    test('when edge case', () { ... });
  });
});
```

Mỗi public method của ViewModel → 1 group. Bên trong chia `happy` (success) và `unhappy` (error, edge cases).

### 4.3 ProviderContainer trong Unit Tests

```dart
final container = TestUtil.createContainer(
  overrides: [
    someProvider.overrideWith((_) => mockValue),
  ],
);
// addTearDown(container.dispose) đã tự động trong createContainer
```

Pattern này từ M8 (Riverpod) — override providers với mocks, tự cleanup.

### 4.4 Những gì cần test trong ViewModel

| Loại | Ví dụ | Assert |
|------|-------|--------|
| State changes | `setEmail()` thay đổi `data.email` | `expect(vm.data.email, value)` |
| Side effects | `login()` gọi API, save token | `verify(() => api.login(...)).called(1)` |
| Error handling | `login()` khi API throw | `expect(vm.data.onPageError, isNotEmpty)` |
| Navigation | `login()` success → navigate | `verify(() => navigator.replaceAll(...))` |
| Negative | Error → không navigate | `verifyNever(() => navigator.replaceAll(...))` |

> 💡 **FE Perspective**
> **Flutter:** AAA pattern (Arrange-Act-Assert) + group `happy`/`unhappy` per method. `ProviderContainer` với overrides.
> **React/Vue tương đương:** Jest `describe`/`it` blocks + `beforeEach` setup. `renderHook` với custom wrapper.
> **Khác biệt quan trọng:** Flutter test ViewModel trực tiếp (class instance). React test hooks qua `renderHook` wrapper.

---

## Concept 5: Golden Testing — Visual Regression

<!-- AI_VERIFY: concept-5 -->

### 5.1 Golden test là gì?

Golden test render widget thành image, rồi so sánh pixel-by-pixel với "golden file" (reference image) đã lưu. Nếu khác quá threshold → test fail.

```
Code change → render Widget → compare pixels → pass/fail
                                   │
                     golden file (reference image)
```

### 5.2 Golden test trong codebase

**Config** (từ `flutter_test_config.dart`):
- `GoldenToolkit.runWithConfiguration` — enable real shadows
- `LocalFileComparatorWithThreshold` — 0.003% tolerance
- Load fonts thật (Noto Sans JP, MaterialIcons, CupertinoIcons)

**Device sizes** (từ `test_config.dart`):
```dart
enum AppTestDeviceType {
  smallPhone(size: Size(320, 568)),   // iPhone SE
  tall(size: Size(375, 812)),          // iPhone X
  wide(size: Size(412, 730)),          // Pixel 5
  tablet(size: Size(1024, 1366)),      // iPad Pro
}
```

### 5.3 Update Goldens

```bash
# Xóa goldens cũ + generate mới
make ug
# Tương đương:
# find . -type d -name "goldens" -exec rm -rf {} +
# flutter test --update-goldens --tags=golden
```

### 5.4 dart_test.yaml — Tag Config

```yaml
tags:
  golden:
```

Cho phép chạy riêng golden tests: `flutter test --tags=golden` hoặc skip: `flutter test --exclude-tags=golden`.

> 💡 **FE Perspective**
> **Flutter:** Golden test render widget → compare pixel-by-pixel với reference image. Threshold 0.003% tolerance.
> **React/Vue tương đương:** Storybook visual regression + Percy/Chromatic. `--update-goldens` ≈ `--updateSnapshot` trong Jest.
> **Khác biệt quan trọng:** Flutter golden test built-in (`flutter_test`). React cần external service (Percy/Chromatic) và Storybook setup.

---

## Concept 6: Integration Testing — E2E trên Device

<!-- AI_VERIFY: concept-6 -->

### 6.1 Integration test vs Unit/Widget test

| | Unit/Widget | Integration |
|--|------------|-------------|
| App | Mock | Real |
| Device | Không | Emulator / Real device |
| Speed | ms | seconds–minutes |
| Network | Mock | Real (hoặc mock server) |
| Package | `flutter_test` | `integration_test` |

### 6.2 Pattern trong codebase

```dart
final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

testWidgets('t1 login failed', (tester) async {
  await tester.runAsync(app.main);            // Launch real app
  await tester.openLoginPage();               // Custom helper

  await tester.enterText(find.byType(PrimaryTextField).first, 'a');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpWithDuration(5.seconds);

  await tester.takeScreenShot(                // Capture evidence
    binding: binding,
    fileName: 't1/t1_login_failed.png',
  );
});
```

### 6.3 Khi nào viết Integration test?

- **Critical user flows**: Login, checkout, onboarding
- **Cross-feature interactions**: Login → navigate → load data
- **Platform-specific**: Camera, biometrics, deep links

Integration tests chạy chậm → chỉ viết cho critical paths. Unit + widget tests cover phần còn lại.

> 💡 **FE Perspective**
> **Flutter:** Integration test chạy trên real device/emulator với `integration_test` package. Screenshot capture làm evidence.
> **React/Vue tương đương:** Cypress/Playwright E2E tests. `cy.screenshot()` ≈ `tester.takeScreenShot()`.
> **Khác biệt quan trọng:** Flutter integration test cần emulator/device thật. Web E2E chạy trên browser headless — nhanh hơn.

### 6.4 Coverage

```bash
make cov       # Full coverage: unit + widget
make cov_ut    # Unit test coverage only
make cov_wt    # Widget test coverage only
```

Coverage report generate bằng `lcov` + `genhtml`, filter chỉ các file quan trọng (`*_view_model.dart`, `*_util.dart`, `*_page.dart`).

→ **Tiếp theo**: Forward ref → M19 (CI/CD) sẽ integrate `make te` + `make cov` vào pipeline.

---

## Quick Reference

| Concept | Package | Key File |
|---------|---------|----------|
| Test config | `flutter_test` | `flutter_test_config.dart` |
| Mocking | `mocktail` | `base_test.dart` |
| Golden toolkit | `golden_toolkit` | `flutter_test_config.dart` |
| Integration | `integration_test` | `integration_test/` |
| Coverage | `lcov` | `coverage/lcov.info` |

### Flutter SDK vs Project Custom API

> ⚠️ **Quan trọng:** Bảng dưới phân biệt API chuẩn của Flutter SDK và custom helpers riêng của project. Đừng nhầm lẫn khi đọc code hoặc tra docs.

| Flutter SDK (chuẩn) | Project Custom (riêng project) | Ghi chú |
|---|---|---|
| `testWidgets()` | `testWidget()` | Custom helper wrap ProviderScope + MaterialApp, KHÔNG có 's' |
| `pumpWidget()` | custom pump helpers (`pumpWithDuration`) | Project thêm helper cho duration-based pump |
| `find.byType()` | custom finders (`isDescendantOfKeyIfAny`) | Extension method trên `Finder` |
| `expect()` | same | Dùng chung `expect()` từ `flutter_test` |

→ **Tiếp theo**: [03-exercise.md](./03-exercise.md) — Hands-on exercises.

---

📖 [Glossary](../_meta/glossary.md)

<!-- AI_VERIFY: generation-complete -->
