# Logging Instructions

## Overview

In this project, **DO NOT use `print()`** for logging. Instead, use the `Log` class provided in `lib/common/util/log.dart`.

## Why Not Use `print()`

- Cannot be controlled (enable/disable)
- No log categorization (debug, error, api, event)
- No color coding for easy distinction
- No information about class/function being logged
- No timestamp
- No stack trace for errors

## Log Types

### 1. Log.d() - Debug Log

Used to log debug information, track flow, variable values.

```dart
// Normal log
Log.d('User logged in successfully');

// Log with custom color
Log.d('API response received', color: LogColor.green);

// Log with class/function name
Log.d('Fetching user data', name: 'UserRepository');

// Log with specific mode
Log.d('POST /api/users', mode: LogMode.api);
```

**Parameters:**
- `message`: Log content (required)
- `color`: Display color (default: yellow)
- `mode`: Log type (default: normal)
- `name`: Class/function name
- `time`: Custom timestamp

**Available Colors:**
- `LogColor.black`, `LogColor.white`, `LogColor.red`
- `LogColor.green`, `LogColor.yellow`, `LogColor.blue`, `LogColor.cyan`

**Available Modes:**
- `LogMode.all` - All logs
- `LogMode.api` - API-related logs
- `LogMode.logEvent` - Event tracking logs
- `LogMode.normal` - Normal logs

### 2. Log.e() - Error Log

**RULE: MUST use Log.e() in all catch blocks**

```dart
// BAD - Don't use print in catch
try {
  await someOperation();
} catch (e) {
  print('Error: $e'); // BAD!
}

// GOOD - Must use Log.e()
try {
  await someOperation();
} catch (e, stackTrace) {
  Log.e(
    'Failed to perform operation',
    errorObject: e,
    stackTrace: stackTrace,
  );
}

// GOOD - Log error with complete information
try {
  final user = await userRepository.getUser(userId);
} catch (e, stackTrace) {
  Log.e(
    'Failed to fetch user with id: $userId',
    name: 'UserRepository',
    errorObject: e,
    stackTrace: stackTrace,
    mode: LogMode.api,
  );
  rethrow;
}
```

**Parameters:**
- `errorMessage`: Error description (required)
- `name`: Class/function name
- `errorObject`: Error object from catch
- `stackTrace`: Stack trace from catch
- `color`: Color (default: red)
- `mode`: Log type (default: normal)
- `time`: Timestamp

### 3. Log.prettyJson() - Format JSON

To log JSON data with pretty format:

```dart
final jsonData = {
  'userId': 123,
  'name': 'John Doe',
  'email': 'john@example.com',
};

// BAD - JSON compressed to 1 line
Log.d('User data: $jsonData');

// GOOD - JSON formatted nicely
Log.d('User data:\n${Log.prettyJson(jsonData)}');

// Result:
// User data:
// {
//   "userId": 123,
//   "name": "John Doe",
//   "email": "john@example.com"
// }
```

Or in LogMixin:

```dart
class UserRepository with LogMixin {
  void processUser(Map<String, dynamic> userData) {
    logD('Processing user:\n${LogMixin.prettyResponse(userData)}');
  }
}
```

## Best Practices

### 1. Try-Catch MUST Have Log.e()

```dart
// GOOD
try {
  await riskyOperation();
} catch (e, stackTrace) {
  Log.e('Operation failed', errorObject: e, stackTrace: stackTrace);
  // Handle error
}

// BAD - Catch without logging
try {
  await riskyOperation();
} catch (e) {
  // Do nothing - BAD!
}
```

### 2. Log with Clear Context

```dart
// BAD - Not clear
Log.d('Success');

// GOOD - Clear with context
Log.d('User registration completed successfully for email: $email');
```

### 3. Use Appropriate LogMode

```dart
// API calls
Log.d('GET /api/users', mode: LogMode.api);

// Analytics/Tracking events
Log.d('User clicked login button', mode: LogMode.logEvent);

// Business logic
Log.d('Calculating total price', mode: LogMode.normal);
```

### 4. Log Error with Complete Information

```dart
// BAD - Missing information
try {
  await someOperation();
} catch (e) {
  Log.e('Error');
}

// GOOD - Complete information
try {
  await someOperation();
} catch (e, stackTrace) {
  Log.e(
    'Failed to perform operation X with params: $params',
    name: 'ClassName.methodName',
    errorObject: e,
    stackTrace: stackTrace,
  );
}
```

### 5. Don't Log Sensitive Data

```dart
// BAD - Log password
Log.d('User password: $password');

// BAD - Log token
Log.d('Auth token: $token');

// GOOD - Hide sensitive data
Log.d('User authenticated successfully');
Log.d('Token received: ${token.substring(0, 10)}...');
```

## Summary Rules

1. **NEVER use `print()`**
2. **Use `Log.d()` for debug logs**
3. **ALWAYS use `Log.e()` in catch blocks**
4. **Use `Log.prettyJson()` for JSON data**
5. **Log with clear and complete context**
6. **Don't log sensitive data (password, token)**
7. **Always capture both `e` and `stackTrace` in catch**
