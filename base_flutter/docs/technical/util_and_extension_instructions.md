# Util and Extension Instructions

## Overview

Guidelines for organizing utility functions, extensions, and helper classes in `lib/common`.

## Decision Tree

```
Do you need a utility function/method?
│
├─ Add method to existing type (String, List, DateTime...)?
│  └─ Yes → Extension (extension.dart or relevant util file)
│
├─ Require external dependencies (packages, services)?
│  └─ Yes → Helper class (lib/common/helper/)
│
└─ Pure function/static method?
   │
   ├─ Project-specific logic (business rules, specific formats)?
   │  └─ Yes → AppUtil (app_util.dart)
   │
   └─ Generic logic reusable across projects?
      └─ Yes → Separate util file (date_time_util.dart, file_util.dart, ...)
```

## 1. AppUtil - Project-Specific Utilities

### When to Use AppUtil

- Project-specific validation rules
- Formatting with specific symbols/formats (￥, 円, project date formats)
- Business logic helpers (discount calculations based on project rules)
- Project-specific constants and helpers

### Do NOT Use AppUtil When

- Logic is generic and reusable across projects
- Standard utility unrelated to business logic
- Requires external dependencies

### Structure

```dart
// lib/common/util/app_util.dart
class AppUtil {
  AppUtil._(); // Private constructor

  // Project-specific validation
  static bool isValidPassword(String password) {
    // Password rules SPECIFIC to this project:
    // - 8-16 characters
    // - Must have uppercase, lowercase, digit, special char
    final value = password.trim();
    if (value.length < 8 || value.length > 16) {
      return false;
    }
    // ... project-specific validation
  }

  // Project-specific formatting
  static String formatPrice(double price) {
    // Format price with symbol ￥ - specific to this project
    return NumberFormat.currency(symbol: '￥', decimalDigits: 0).format(price);
  }

  // Project-specific validation for Japanese
  static bool isKatakana(String value) {
    // Validate Katakana - specific to Japanese project
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^([ァ-ン]|ー)+$').hasMatch(trimmed);
  }
}
```

## 2. Separate Util Files - Generic Utilities

### When to Create Separate Util File

- Generic and not specific to this project
- Reusable across many projects
- Free of external dependencies
- Grouped by domain (date/time, file, view, object...)

### Common Util Files

#### DateTimeUtil - Generic Date/Time Utilities

```dart
// lib/common/util/date_time_util.dart
class DateTimeUtil {
  DateTimeUtil._();

  // Generic: Get current time (reusable)
  static DateTime get now => clock.now();
  static DateTime get today => now.withTimeAtStartOfDay();

  // Generic: Calculate days between dates (reusable)
  static int daysBetween({
    required DateTime from,
    required DateTime to,
  }) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Generic: UTC/Local conversion (reusable)
  static DateTime utcToLocal(int utcTimestampMillis) {
    return DateTime.fromMillisecondsSinceEpoch(
      utcTimestampMillis,
      isUtc: true,
    ).toLocal();
  }
}
```

#### FileUtil - Generic File Utilities

```dart
// lib/common/util/file_util.dart
class FileUtil {
  // Generic: Get image from URL (reusable)
  static Future<File?> getImageFileFromUrl(String imageUrl) async {
    try {
      return DefaultCacheManager().getSingleFile(imageUrl);
    } catch (e) {
      Log.e('Error fetching image from URL: $e');
      return null;
    }
  }

  // Generic: Get MIME type (reusable)
  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }
}
```

#### ViewUtil - Generic UI Utilities

```dart
// lib/common/util/view_util.dart
class ViewUtil {
  const ViewUtil._();

  // Generic: Prevent double-click (reusable)
  static int _lastClickTime = 0;

  static void safeClick({
    required VoidCallback onPressed,
    int intervalMs = 500,
  }) {
    final currentTime = DateTimeUtil.now.millisecondsSinceEpoch;
    if (currentTime - _lastClickTime > intervalMs) {
      _lastClickTime = currentTime;
      onPressed();
    }
  }

  // Generic: Hide keyboard (reusable)
  static void hideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
```

## 3. Extensions - Add Methods to Existing Types

### When to Use Extensions

- Add convenience methods to built-in types
- Make code more readable with method chaining
- Encapsulate common operations on types

### Structure

```dart
// lib/common/util/extension.dart

// Extensions for nullable types
extension NullableListExtensions<T> on List<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

extension NullableStringExtensions on String? {
  bool get isNotNullAndNotEmpty => this != null && this!.isNotEmpty;
}

// Extensions for non-nullable types
extension StringExtensions on String {
  String plus(String other) => this + other;
  
  String? get firstOrNull => isNotEmpty ? this[0] : null;
  
  bool equalsIgnoreCase(String secondString) =>
      toLowerCase() == secondString.toLowerCase();
  
  bool containsIgnoreCase(String secondString) =>
      toLowerCase().contains(secondString.toLowerCase());
}

// Extensions for List
extension ListExtensions<T> on List<T> {
  List<T> plus(T element) {
    return appendElement(element).toList(growable: false);
  }

  List<T> minus(T element) {
    return exceptElement(element).toList(growable: false);
  }
}

// Extensions for DateTime
extension DateTimeExtensions on DateTime {
  String toStringWithFormat(String format, {String? locale}) {
    return DateFormat(format, locale).format(this);
  }

  DateTime get lastDateOfMonth {
    return DateTime(year, month + 1, 0);
  }

  DateTime withTimeAtStartOfDay() {
    return DateTime(year, month, day);
  }
}

// Extensions for BuildContext
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  FocusScopeNode get focusScope => FocusScope.of(this);
}

// Extensions for ScrollController
extension ScrollControllerExtensions on ScrollController {
  bool scrollToTop({
    int durationInMilliseconds = 300,
    Curve curve = Curves.easeOut,
  }) {
    if (!hasClients) return false;
    
    animateTo(
      0,
      duration: Duration(milliseconds: durationInMilliseconds),
      curve: curve,
    );
    return true;
  }
}
```

### Extension vs Static Method

```dart
// BAD - Static method requires passing object
class StringUtil {
  static bool containsIgnoreCase(String text, String search) {
    return text.toLowerCase().contains(search.toLowerCase());
  }
}
// Usage: StringUtil.containsIgnoreCase(text, search)

// GOOD - Extension method, more readable
extension StringExtensions on String {
  bool containsIgnoreCase(String search) {
    return toLowerCase().contains(search.toLowerCase());
  }
}
// Usage: text.containsIgnoreCase(search)
```

## 4. Helper Classes - With Dependencies

### When to Create Helper Class

- Need external dependencies (packages like `device_info_plus`, `permission_handler`)
- Need dependency injection (via `@LazySingleton()`, Provider)
- Logic requires state or instance variables
- Want to wrap external packages for easier testing and maintenance

### Structure

```dart
// lib/common/helper/device_helper.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:injectable/injectable.dart';

// Provider to access the helper
final deviceHelperProvider = Provider<DeviceHelper>(
  (ref) => getIt.get<DeviceHelper>(),
);

// Helper class with dependency injection
@LazySingleton()
class DeviceHelper {
  // Dependencies: device_info_plus, flutter_udid packages
  
  Future<String> get deviceId async {
    return await FlutterUdid.udid;
  }

  Future<String> get deviceModelName async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    } else {
      final androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.brand} ${androidInfo.device}';
    }
  }

  DeviceType get deviceType {
    const phoneMaxWidth = 550;
    const smallPhoneMaxWidth = 380;
    
    final deviceWidth = MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    ).size.shortestSide;
    
    return deviceWidth < smallPhoneMaxWidth
        ? DeviceType.smallPhone
        : deviceWidth < phoneMaxWidth
            ? DeviceType.phone
            : DeviceType.tablet;
  }
}
```

### Helper vs Util

| Aspect | Helper | Util |
|--------|--------|------|
| **Dependencies** | Yes (packages) | No |
| **Injection** | Required (@LazySingleton) | No (static) |
| **State** | Can have | Stateless |
| **Testability** | Mock-able | Pure functions |
| **Examples** | DeviceHelper, PermissionHelper | DateTimeUtil, FileUtil |

## Best Practices

### 1. Private Constructors for Util Classes

```dart
// GOOD - Private constructor, only static methods
class AppUtil {
  AppUtil._(); // Cannot instantiate
  
  static bool isValidEmail(String email) { }
}
```

### 2. Group Related Functions

```dart
// GOOD - Group by domain
class DateTimeUtil {
  static DateTime get now { }
  static int daysBetween({ }) { }
  static DateTime utcToLocal( ) { }
  // All date/time related
}

// BAD - Mixing unrelated functions
class Util {
  static DateTime get now { }
  static String getMimeType( ) { }
  static void hideKeyboard( ) { }
  // Mixed concerns!
}
```

### 3. Error Handling in Utils

```dart
// GOOD - Handle errors gracefully
class FileUtil {
  static Future<File?> getImageFileFromUrl(String imageUrl) async {
    try {
      return DefaultCacheManager().getSingleFile(imageUrl);
    } catch (e) {
      Log.e('Error fetching image from URL: $e');
      return null; // Return null on error
    }
  }
}
```

### 4. Use Extensions for Readability

```dart
// BAD - Nested static method calls
final result = StringUtil.capitalize(
  StringUtil.trim(
    StringUtil.replaceAll(text, 'old', 'new')
  )
);

// GOOD - Method chaining with extensions
final result = text
    .replaceAll('old', 'new')
    .trim()
    .capitalize();
```

### 5. Inject Helpers, Not Utils

```dart
// GOOD - Helper with injection
@LazySingleton()
class DeviceHelper {
  Future<String> get deviceId async { }
}

final deviceHelperProvider = Provider<DeviceHelper>(
  (ref) => getIt.get<DeviceHelper>(),
);

// Usage in ViewModel
class MyViewModel extends BaseViewModel<MyState> {
  Future<void> init() async {
    final deviceId = await ref.deviceHelper.deviceId;
  }
}

// GOOD - Util without injection (static)
class DateTimeUtil {
  static DateTime get now => clock.now();
}

// Usage anywhere
final now = DateTimeUtil.now;
```

## Summary Rules

### AppUtil (Project-Specific)
1. Business rules specific to project
2. Validation with project-specific rules
3. Formatting with specific symbols/formats
4. Project-specific constants and helpers
5. Static methods, private constructor

### Separate Util Files (Generic)
1. Generic logic, reusable for many projects
2. Group by domain (date/time, file, view...)
3. No external dependencies
4. Static methods, private constructor
5. Can contain related extensions

### Extensions
1. Add methods to existing types
2. Make code more readable
3. Method chaining
4. Null-safe extensions (`on Type?`)

### Helper Classes
1. Have external dependencies
2. Need dependency injection
3. Wrap external packages
4. Can have state/instance variables
5. Use `@LazySingleton()` and Provider

## Key Files Reference

- [app_util.dart](../../lib/common/util/app_util.dart) - Project-specific utilities
- [date_time_util.dart](../../lib/common/util/date_time_util.dart) - Generic date/time utilities
- [file_util.dart](../../lib/common/util/file_util.dart) - Generic file utilities
- [extension.dart](../../lib/common/util/extension.dart) - Extensions for existing types
- [device_helper.dart](../../lib/common/helper/device_helper.dart) - Device helper with dependencies
