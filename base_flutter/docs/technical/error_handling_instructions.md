# Error Handling Instructions

## Overview

The project uses `AppException` base class and `ExceptionHandler` for consistent error handling. All custom exceptions extend `AppException` and specify their UI behavior via `AppExceptionAction`.

## Core Concepts

### AppException Base Class

```dart
abstract class AppException implements Exception {
  AppException({
    this.onRetry,
    this.rootException,
  });

  final Object? rootException;
  Future<void> Function()? onRetry;

  String get message; // Required
  AppExceptionAction get action; // Required
  bool get recordError => false; // Optional
  bool get isForcedErrorToHandle => false; // Optional
}
```

### AppExceptionAction Types

| Action | Behavior |
|--------|----------|
| `showSnackBar` | Display SnackBar at bottom |
| `showDialog` | Display error dialog |
| `showDialogWithRetry` | Dialog with Retry button |
| `showForceLogoutDialog` | Dialog + force logout |
| `showNonCancelableDialog` | Non-dismissible dialog |
| `showMaintenanceDialog` | Maintenance dialog |
| `doNothing` | Silent (no UI) |

## Common Pattern: Auto Error Handling

**Step 1: Create Exception**

```dart
class ValidationException extends AppException {
  ValidationException({
    required this.errors,
    super.rootException,
  });

  final Map<String, String> errors;

  @override
  String get message => errors.values.firstOrNull ?? 'Validation failed';

  @override
  AppExceptionAction get action => AppExceptionAction.showSnackBar;
}
```

**Step 2: Throw Exception**

```dart
class UserApiService {
  Future<User> createUser(UserInput input) async {
    final errors = _validateInput(input);
    if (errors.isNotEmpty) {
      throw ValidationException(errors: errors);
    }
    return await _createUserApi(input);
  }
}
```

**Step 3: Auto-handled by ExceptionHandler**

```dart
class CreateUserViewModel extends BaseViewModel<CreateUserState> {
  Future<void> onCreatePressed() async {
    await runCatching(
      action: () async {
        await ref.appApiService.createUser(userInput);
        await ref.nav.pop();
      },
      actionName: 'create_user',
    );
    // ValidationException auto shows SnackBar
  }
}
```

## Exception Examples

### Network Exception with Retry

```dart
class NetworkException extends AppException {
  NetworkException({
    required this.type,
    super.rootException,
    super.onRetry,
  });

  final NetworkExceptionType type;

  @override
  String get message {
    return switch (type) {
      NetworkExceptionType.noInternet => l10n.noInternetException,
      NetworkExceptionType.timeout => l10n.timeoutException,
      NetworkExceptionType.hostNotFound => l10n.canNotConnectToHost,
    };
  }

  @override
  AppExceptionAction get action => AppExceptionAction.showDialogWithRetry;

  @override
  bool get recordError => true;
}

enum NetworkExceptionType { noInternet, timeout, hostNotFound }
```

### Authentication Exception

```dart
class AuthenticationException extends AppException {
  AuthenticationException({
    required this.reason,
    super.rootException,
  });

  final AuthErrorReason reason;

  @override
  String get message {
    return switch (reason) {
      AuthErrorReason.tokenExpired => l10n.tokenExpired,
      AuthErrorReason.unauthorized => l10n.unauthorized,
      AuthErrorReason.accountDeleted => l10n.accountDeleted,
    };
  }

  @override
  AppExceptionAction get action => AppExceptionAction.showForceLogoutDialog;

  @override
  bool get isForcedErrorToHandle => true;
}

enum AuthErrorReason { tokenExpired, unauthorized, accountDeleted }
```

### Silent Exception

```dart
class AnalyticsException extends AppException {
  AnalyticsException({
    required this.errorMessage,
    super.rootException,
  });

  final String errorMessage;

  @override
  String get message => errorMessage;

  @override
  AppExceptionAction get action => AppExceptionAction.doNothing;
}
```

## Custom Error Handling: handleErrorWhen

Use `handleErrorWhen` to intercept exceptions before `ExceptionHandler` processes them.

### Use Case 1: Check Error ID

```dart
Future<void> onLoginPressed() async {
  await runCatching(
    action: () async {
      await ref.appApiService.login(email, password);
      await ref.nav.replaceAll([const TopRoute()]);
    },
    handleErrorWhen: (exception) async {
      if (exception is RemoteException &&
          exception.generalServerErrorId == Constant.userNotVerifiedErrorId) {
        await _showVerifyAccountDialog();
        return false; // Skip ExceptionHandler
      }
      return true; // Use ExceptionHandler
    },
    actionName: 'login',
  );
}
```

### Use Case 2: Inline Form Errors

```dart
Future<void> onSubmitForm() async {
  await runCatching(
    action: () async {
      await ref.appApiService.submitUserProfile(profile);
    },
    handleErrorWhen: (exception) async {
      if (exception is ValidationException) {
        data = data.copyWith(validationErrors: exception.errors);
        return false; // Show inline, skip dialog
      }
      return true; // Show dialog for other errors
    },
  );
}
```

### Use Case 3: Custom Navigation

```dart
Future<void> loadUserData() async {
  await runCatching(
    action: () async {
      final user = await ref.appApiService.getUserProfile();
      data = data.copyWith(user: user);
    },
    handleErrorWhen: (exception) async {
      if (exception is AuthenticationException &&
          exception.reason == AuthErrorReason.accountDeleted) {
        await ref.nav.replaceAll([const AccountDeletedRoute()]);
        return false;
      }
      return true;
    },
  );
}
```

### Use Case 4: Silent Fail

```dart
Future<void> trackAnalyticsEvent() async {
  await runCatching(
    action: () async {
      await ref.appApiService.logAnalytics(event);
    },
    handleErrorWhen: (exception) async {
      Log.e('Analytics failed', errorObject: exception);
      return false; // Silent fail
    },
  );
}
```

## handleErrorWhen Return Values

```dart
handleErrorWhen: (exception) async {
  if (/* need custom handling */) {
    // Do custom handling (inline errors, navigation, silent fail, etc.)
    return false; // Skip ExceptionHandler
  }
  return true; // Use ExceptionHandler
}
```

**Return `false` when:**
- Show inline errors in form fields
- Navigate to specific screen
- Silent fail (ignore error)
- Custom dialog/snackbar logic
- Handle specific error codes

**Return `true` when:**
- Use default error handling
- Show dialog/snackbar per AppExceptionAction

## Error Handling Flow

```
Error occurs → Throw AppException
                    ↓
runCatching catches exception
                    ↓
handleErrorWhen provided?
   ├─ Yes → return false? → Custom handling (done)
   │         └─ return true → Continue to ExceptionHandler
   └─ No → Continue to ExceptionHandler
                    ↓
ExceptionHandler.handleException(exception)
                    ↓
Switch on exception.action:
   - showSnackBar → Show SnackBar
   - showDialog → Show error dialog
   - showDialogWithRetry → Show dialog with retry button
   - showForceLogoutDialog → Force logout + navigate to login
   - showNonCancelableDialog → Non-cancelable dialog
   - showMaintenanceDialog → Maintenance dialog
   - doNothing → Silent (no UI)
```

## Rules Summary

1. Extend `AppException` for all custom exceptions
2. Default path: auto-handled by ExceptionHandler
3. Custom path: use `handleErrorWhen` in `runCatching`
4. Return `false` in `handleErrorWhen` to skip ExceptionHandler
5. Return `true` in `handleErrorWhen` to use ExceptionHandler
6. Always use common flow unless specifications explicitly requires custom handling
7. Use exact `action`, `message`, `recordError`, and `isForcedErrorToHandle` values as specified in specifications. Apply default values only when specifications don't explicitly define them.
