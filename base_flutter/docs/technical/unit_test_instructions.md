# Unit Test Instructions

## Overview

All core logic in the project MUST have unit tests. This document explains how to write tests that conform to the project's standards.

## [!] Critical Notes

### Note 1: Test According to Spec — Do NOT Code to Make Tests Pass

IMPORTANT: If a `*_spec.md` file exists, tests MUST follow the spec. Do not write tests just so existing code passes.

```dart
// BAD - Write test to make code pass
// Spec: "Email validation should reject emails longer than 320 characters"
test('when email is valid', () {
  // Code allows 500 chars
  // Test written to pass with 500 chars instead of following spec 320 chars
  final isValid = AppUtil.isValidEmail('a' * 500 + '@example.com');
  expect(isValid, isTrue); // Wrong! Not following spec!
});

// GOOD - Test follows spec
// Spec: "Email validation should reject emails longer than 320 characters"
test('when email exceeds 320 characters', () {
  final longEmail = '${'a' * 310}@example.com';
  final isValid = AppUtil.isValidEmail(longEmail);
  
  expect(isValid, isFalse); // Correct! Follows spec!
});
```

**Correct workflow:**
1. Read the spec in `*_spec.md`
2. Write tests based on spec requirements
3. Run tests → they will fail initially
4. Fix the code to make tests pass
5. Do NOT edit tests merely to make code pass

### Note 2: If Code Is Hard to Test → Refactor Code, Do NOT Skip Tests

If you cannot mock dependencies when writing tests, the code is likely hard to test.

**Decision Flow:**

```
Unable to mock a dependency?
│
├─ Is it a hard-coded class?
│  └─ Yes → Refactor: use dependency injection (via ref or constructor)
│
├─ Is it a static method?
│  └─ Yes → Refactor: wrap it in an injectable class or pass as parameter
│
├─ Is it a global singleton?
│  └─ Yes → Refactor: inject via ref or constructor
│
└─ Cannot refactor (external package, platform code)?
   ├─ Try: wrap it in a Helper class (injectable)
   └─ Still cannot mock? → Skip tests for that file
```

**Example: Refactoring Hard-to-Test Code**

```dart
// BAD - Hard to test (hard-coded dependency)
class MyViewModel extends BaseViewModel<MyState> {
  Future<void> loadData() async {
    final apiService = AppApiService(); // Hard-coded!
    final data = await apiService.fetchData();
    this.data = this.data.copyWith(data: data);
  }
}

// GOOD - Easy to test (dependency injection)
class MyViewModel extends BaseViewModel<MyState> {
  Future<void> loadData() async {
    // Inject via ref, can mock
    final data = await ref.appApiService.fetchData();
    this.data = this.data.copyWith(data: data);
  }
}

// Test: Mock ref.appApiService
when(() => appApiService.fetchData()).thenAnswer((_) async => dummyData);
```

**Summary Rules:**
1. Refactor code first to make it testable (dependency injection, wrappers)
2. Wrap hard dependencies in Helper classes
3. Use abstractions (interfaces) for external dependencies
4. Last resort: skip tests only if truly impossible to test

## Mandatory Rules

### 1. Group Name Must Match Function Name

```dart
// GOOD - Group name matches function name
class MyViewModel {
  Future<void> onSubmitPressed() async { }
  void onNameChanged(String value) { }
}

void main() {
  group('onSubmitPressed', () { });
  group('onNameChanged', () { });
}

// GOOD - Extension methods use ExtensionName.methodName
extension ObjectExt on Object? {
  T? safeCast<T>() { }
  R let<R>(R Function(Object?) block) { }
}

void main() {
  group('ObjectExt.safeCast', () { });
  group('ObjectExt.let', () { });
}

// GOOD - Extension on built-in types
extension DateTimeExt on DateTime {
  String toStringWithFormat(String format) { }
  DateTime get lastDateOfMonth { }
}

void main() {
  group('DateTime.toStringWithFormat', () { });
  group('DateTime.lastDateOfMonth', () { });
}

// BAD - Group name doesn't match
void main() {
  group('submit button test', () { }); // Wrong!
  group('name change', () { });        // Wrong!
  group('safeCast', () { });           // Wrong! Should be ObjectExt.safeCast
  group('toStringWithFormat', () { }); // Wrong! Should be DateTime.toStringWithFormat
}
```

### 2. Subgroups: happy and unhappy

Each function's tests MUST contain two subgroups: `happy` and `unhappy`.

```dart
// GOOD - Has happy and unhappy groups
group('onSubmitPressed', () {
  group('happy', () {
    test('when all fields are valid', () { });
    test('when user has permission', () { });
  });
  
  group('unhappy', () {
    test('when email is empty', () { });
    test('when password is invalid', () { });
    test('when API returns error', () { });
  });
});

// BAD - No happy/unhappy groups
group('onSubmitPressed', () {
  test('when all fields are valid', () { });
  test('when email is empty', () { });
});
```

**Happy cases:** Function behaves correctly (no errors).  
**Unhappy cases:** Errors, validation failures, or exceptions are thrown.

**Important**: If a `happy` or `unhappy` group has no test cases, you MUST add a comment explaining why:

```dart
group('onNameChanged', () {
  group('happy', () {
    test('when name is changed', () {
      viewModel.onNameChanged('John');
      expect(viewModel.data.name, 'John');
    });
  });

  // No validation for name field, accepts any value
  // ignore: empty_test_group
  group('unhappy', () {});
});
```

### 3. All Functions Must Have Tests

If AI generates code for a function, it **MUST** write unit tests for that function.

**Excluded from testing (no tests required):**

```
lib/data_source/api/client/*_client.dart
lib/data_source/api/*_service.dart
lib/data_source/api/middleware/custom_log_interceptor.dart
lib/data_source/api/middleware/base_interceptor.dart
lib/data_source/firebase/
lib/data_source/preference/app_preferences.dart
lib/model/mapper/base/base_data_mapper.dart
lib/exception/app_exception.dart
lib/exception/exception_mapper/app_exception_mapper.dart
lib/common/config.dart
lib/common/constant.dart
lib/common/env.dart
lib/common/type/
lib/common/util/log.dart
lib/common/util/ref_ext.dart
lib/common/util/view_util.dart
lib/main.dart
lib/ui/my_app.dart
lib/di.dart
lib/di.config.dart
lib/index.dart
lib/app_initializer.dart
lib/ui/base/
lib/ui/component/
lib/ui/popup/
lib/ui/page/*_page.dart
lib/navigation/
lib/resource/
```

### 4. Private Functions Need @visibleForTesting

If a private function needs testing, add `@visibleForTesting` annotation.

```dart
// GOOD - Private function with @visibleForTesting
class MyViewModel extends BaseViewModel<MyState> {
  @visibleForTesting
  bool isValidInput(String input) {
    return input.isNotEmpty && input.length > 3;
  }
}

// Test file
test('isValidInput returns true for valid input', () {
  expect(viewModel.isValidInput('test'), isTrue);
});
```

### 5. Do NOT Use state_notifier_test Package

```dart
// BAD - Don't use state_notifier_test
import 'package:state_notifier_test/state_notifier_test.dart';

stateNotifierTest<MyViewModel, MyState>( );

// GOOD - Use standard flutter_test
import 'package:flutter_test/flutter_test.dart';

test('when state changes', () {
  // Test implementation
});
```

### 6. Void Functions Must Verify Calls

If a function returns `void`, use `verify()` to check calls.

```dart
// GOOD - Verify for void functions
test('when onNameChanged is called', () {
  viewModel.onNameChanged('John');
  
  // Verify state updated
  expect(viewModel.data.name, 'John');
  
  // Verify no API calls (if applicable)
  verifyNever(() => appApiService.updateName(any()));
});

test('when logout is called', () async {
  await sharedViewModel.logout();
  
  // Verify all expected calls
  verify(() => appApiService.postAuthLogout(refreshToken: any(named: 'refreshToken'))).called(1);
  verify(() => appPreferences.clearCurrentUserData()).called(1);
  verify(() => navigator.replaceAll([const LoginRoute()])).called(1);
});
```

### 7. Reuse base_test.dart and test_util.dart

**MUST** import and reuse utilities from `test/common/`:

```dart
// GOOD - Reuse common test utilities
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../common/index.dart'; // Import common test utilities

void main() {
  // Reuse mocks from base_test.dart: ref, navigator, appApiService, etc.
  late MyViewModel viewModel;
  
  setUp(() {
    viewModel = MyViewModel(ref);
  });
}

// BAD - Creating duplicate mocks
class _MockRef extends Mock implements Ref {} // Already in base_test.dart!
class _MockAppApiService extends Mock implements AppApiService {} // Already in base_test.dart!
```

## Test Patterns

### Pattern 1: ViewModel Tests

```dart
// test/unit_test/ui/page/login/view_model/login_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../../../common/index.dart';

void main() {
  late LoginViewModel loginViewModel;

  setUp(() {
    loginViewModel = LoginViewModel(ref);
  });

  group('onEmailChanged', () {
    group('happy', () {
      test('when email is changed', () {
        const newEmail = 'test@example.com';

        loginViewModel.onEmailChanged(newEmail);

        expect(loginViewModel.data.email, newEmail);
        expect(loginViewModel.data.emailError, '');
      });
    });

    // Simple state update with no validation
    // ignore: empty_test_group
    group('unhappy', () {});
  });

  group('onLoginPressed', () {
    const dummyEmail = 'test@example.com';
    const dummyPassword = 'Password1!';

    group('happy', () {
      test('when login success', () async {
        loginViewModel.onEmailChanged(dummyEmail);
        loginViewModel.onPasswordChanged(dummyPassword);

        when(() => appApiService.login(dummyEmail, dummyPassword))
            .thenAnswer((_) async {});
        when(() => navigator.replaceAll([const HomeRoute()]))
            .thenAnswer((_) async => true);

        await loginViewModel.onLoginPressed();

        verify(() => appApiService.login(dummyEmail, dummyPassword)).called(1);
        verify(() => navigator.replaceAll([const HomeRoute()])).called(1);
      });
    });

    group('unhappy', () {
      test('when email is empty', () async {
        loginViewModel.onEmailChanged('');

        await loginViewModel.onLoginPressed();

        expect(loginViewModel.data.emailError, isNotEmpty);
        verifyNever(() => appApiService.login(any(), any()));
      });

      test('when login fails with network error', () async {
        loginViewModel.onEmailChanged(dummyEmail);
        loginViewModel.onPasswordChanged(dummyPassword);

        final dummyException = RemoteException(
          kind: RemoteExceptionKind.network,
        );

        when(() => appApiService.login(dummyEmail, dummyPassword))
            .thenThrow(dummyException);

        await loginViewModel.onLoginPressed();

        expect(loginViewModel.state.appException, isA<RemoteException>());
        verifyNever(() => navigator.replaceAll(any()));
      });
    });
  });
}
```

### Pattern 2: Util Tests

```dart
// test/unit_test/common/util/app_util_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nalsflutter/index.dart';

void main() {
  group('formatPrice', () {
    group('happy', () {
      test('when price is 1000', () {
        final formattedPrice = AppUtil.formatPrice(1000);
        expect(formattedPrice, equals('￥1,000'));
      });

      test('when price is 0', () {
        final formattedPrice = AppUtil.formatPrice(0);
        expect(formattedPrice, equals('￥0'));
      });
    });

    group('unhappy', () {
      test('when price is negative', () {
        final formattedPrice = AppUtil.formatPrice(-1);
        expect(formattedPrice, equals('-￥1'));
      });
    });
  });

  group('isValidPassword', () {
    group('happy', () {
      test('when password meets all requirements', () {
        final isValid = AppUtil.isValidPassword('Password1!');
        expect(isValid, isTrue);
      });
    });

    group('unhappy', () {
      test('when password is too short', () {
        final isValid = AppUtil.isValidPassword('Pass1!');
        expect(isValid, isFalse);
      });

      test('when password missing uppercase', () {
        final isValid = AppUtil.isValidPassword('password1!');
        expect(isValid, isFalse);
      });

      test('when password missing digit', () {
        final isValid = AppUtil.isValidPassword('Password!!');
        expect(isValid, isFalse);
      });
    });
  });
}
```

### Pattern 3: Provider Tests

```dart
// test/unit_test/ui/shared/shared_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../common/index.dart';

void main() {
  group('languageCodeProvider', () {
    group('happy', () {
      test('when language code is available', () {
        when(() => appPreferences.languageCode).thenReturn(Constant.en);
        when(() => appPreferences.saveLanguageCode(Constant.en))
            .thenAnswer((_) async => true);

        final container = TestUtil.createContainer(
          overrides: [
            appPreferencesProvider.overrideWith((_) => appPreferences),
          ],
        );

        final result = container.read(languageCodeProvider);

        expect(result, LanguageCode.fromValue(Constant.en));
        verify(() => appPreferences.saveLanguageCode(Constant.en)).called(1);
      });
    });

    group('unhappy', () {
      test('when language code is empty', () {
        when(() => appPreferences.languageCode).thenReturn('');
        when(() => appPreferences.saveLanguageCode(LanguageCode.defaultValue.value))
            .thenAnswer((_) async => true);

        final container = TestUtil.createContainer(
          overrides: [
            appPreferencesProvider.overrideWith((_) => appPreferences),
          ],
        );

        final result = container.read(languageCodeProvider);

        expect(result, LanguageCode.defaultValue);
        verify(() => appPreferences.saveLanguageCode(LanguageCode.defaultValue.value)).called(1);
      });
    });
  });
}
```

## Best Practices

### 1. Use setUp() and tearDown()

```dart
void main() {
  late MyViewModel viewModel;

  setUp(() {
    // Initialize before each test
    viewModel = MyViewModel(ref);
  });

  tearDown(() {
    // Clean up after each test (if needed)
  });
}
```

### 2. Use Descriptive Dummy Data Names

```dart
// GOOD - Clear dummy data names
const dummyEmail = 'test@example.com';
const dummyPassword = 'Password1!';
const dummyUserId = '123';
final dummyUser = UserModel(id: '123', name: 'John');
final dummyException = RemoteException(kind: RemoteExceptionKind.network);

// BAD - Unclear names
const email = 'test@example.com';
const password = 'Password1!';
final user = UserModel(id: '123', name: 'John');
```

### 3. Test Edge Cases

```dart
group('formatPrice', () {
  group('happy', () {
    test('when price is positive', () { });
    test('when price is zero', () { });
    test('when price has decimals', () { });
  });
  
  group('unhappy', () {
    test('when price is negative', () { });
    test('when price is very large', () { });
    test('when price has many decimal places', () { });
  });
});
```

### 4. Test Async Functions Properly

```dart
// GOOD - Use async/await
test('when async function completes', () async {
  final result = await myViewModel.loadData();
  expect(result, isNotNull);
});

// BAD - Missing async/await
test('when async function completes', () {
  final result = myViewModel.loadData(); // Returns Future, not value!
  expect(result, isNotNull); // Wrong!
});
```

### 5. Isolate Tests (No Side Effects)

```dart
// GOOD - Each test is independent
test('test 1', () {
  viewModel.onEmailChanged('test1@example.com');
  expect(viewModel.data.email, 'test1@example.com');
});

test('test 2', () {
  // Fresh viewModel from setUp()
  viewModel.onEmailChanged('test2@example.com');
  expect(viewModel.data.email, 'test2@example.com');
});

// BAD - Tests depend on each other
test('test 1', () {
  viewModel.counter = 5;
});

test('test 2', () {
  // Assumes counter is still 5 from test 1!
  expect(viewModel.counter, 5);
});
```

## Summary Checklist

### [!] Critical Rules
- [ ] **Tests MUST follow spec** (if `*_spec.md` exists), not written to make code pass
- [ ] **Cannot mock?** → Refactor code first, only skip test when truly impossible

### Standard Rules
- [ ] Group name = function name
- [ ] Has 2 subgroups: `happy` and `unhappy`
- [ ] Empty test groups have `// ignore: empty_test_group` with reason
- [ ] All functions have tests (except excluded files)
- [ ] Private functions have `@visibleForTesting` (if need testing)
- [ ] Do NOT use `state_notifier_test`
- [ ] Void functions have `verify()` calls
- [ ] Reuse `base_test.dart` and `test_util.dart`
- [ ] Import `../../../common/index.dart`
- [ ] Test descriptions are clear
- [ ] Test edge cases
- [ ] Async functions have `async`/`await`
- [ ] Tests are independent, no side effects

## Commands

```bash
# Run all unit tests
make ut

# Run specific test file
flutter test test/unit_test/ui/page/login/view_model/login_view_model_test.dart

# Run tests with coverage
make cov_ut

# Run tests in a directory
flutter test test/unit_test/common/util/
```

## Key Files Reference

- [base_test.dart](../../test/common/base_test.dart) - Mock setup, global config
- [test_util.dart](../../test/common/test_util.dart) - Test utilities, extensions
