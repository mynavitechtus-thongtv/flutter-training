# Constant Instructions

## Overview

**DO NOT hardcode** fixed values (magic values) in code. All fixed values must be declared as constants.

## Quick Reference

| Type | Example | Location |
|------|---------|----------|
| URLs | `https://api.example.com` | Global (`Constant`) |
| Formats | `dd/MM/yyyy`, `#,###` | Global (`Constant`) |
| Error codes | `1300`, `ERR-0001` | Global (`Constant`) |
| Durations | `Duration(seconds: 3)` | Global (`Constant`) |
| Magic numbers | `18`, `20`, `30` | Local if used in 1 file, Global otherwise |
| Magic chars | `@`, `,`, `*` | Local if used in 1 file, Global otherwise |
| Magic strings | `active`, `premium` | Local if used in 1 file, Global otherwise |
| Layout values | `16.0`, `24.0` | Local (component-specific) |

## Core Rule: Where to Declare

### Local Constant (In File)
**When**: Used in **ONE file only**

```dart
// lib/ui/page/login/login_page.dart
class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  // Private constants for this file only
  static const _minPasswordLength = 8;
  static const _maxPasswordLength = 20;
  static const _passwordHintDelay = Duration(seconds: 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (password.length < _minPasswordLength) { /* ... */ }
  }
}
```

### Global Constant (In `Constant` class)
**When**: Used in **multiple files** or has global nature

```dart
// lib/common/constant.dart
class Constant {
  const Constant._();

  // URLs - Used in multiple API services
  static const apiBaseUrl = 'https://api.example.com/';
  
  // Formats - Used in multiple pages
  static const fddMMyyyy = 'dd/MM/yyyy';
  static const fHHmm = 'HH:mm';
  
  // Error codes - Used in multiple error handlers
  static const invalidRefreshToken = 1300;
  static const userNotVerifiedErrorId = '30021';
  
  // Durations - Used in multiple components
  static const snackBarDuration = Duration(seconds: 3);
  static const animationDuration = Duration(milliseconds: 300);
  
  // Pagination - Used in multiple list screens
  static const initialPage = 1;
  static const itemsPerPage = 20;
}
```

## Cases That Require Constants

### 1. URLs and Endpoints

```dart
// BAD - Hardcoded URL
final response = await dio.get('https://api.example.com/users');

// GOOD - URL constant
class Constant {
  static const apiBaseUrl = 'https://api.example.com/';
}
final response = await dio.get('${Constant.apiBaseUrl}users');
```

### 2. Date/Time Formats

```dart
// BAD - Hardcoded format
final formattedDate = DateFormat('dd/MM/yyyy').format(date);

// GOOD - Format constant
class Constant {
  static const fddMMyyyy = 'dd/MM/yyyy';
  static const fHHmm = 'HH:mm';
}
final formattedDate = DateFormat(Constant.fddMMyyyy).format(date);
```

### 3. Magic Numbers

```dart
// BAD - Magic numbers
if (age >= 18) { /* ... */ }
if (itemsPerPage == 20) { /* ... */ }

// GOOD - Named constants
class Constant {
  static const minAdultAge = 18;
  static const itemsPerPage = 20;
  static const apiTimeout = Duration(seconds: 30);
}
if (age >= Constant.minAdultAge) { /* ... */ }
```

### 4. Magic Characters

```dart
// BAD - Magic characters
if (text.contains('@')) { /* email */ }
final parts = text.split(',');

// GOOD - Character constants
class Constant {
  static const atSign = '@';
  static const comma = ',';
  static const asterisk = '*';
}
if (text.contains(Constant.atSign)) { /* email */ }
final parts = text.split(Constant.comma);
```

### 5. Magic Strings

```dart
// BAD - Magic strings
if (status == 'active') { /* ... */ }
prefs.getString('user_id');

// GOOD - String constants
class Constant {
  static const statusActive = 'active';
  static const userIdKey = 'user_id';
}
if (status == Constant.statusActive) { /* ... */ }
prefs.getString(Constant.userIdKey);
```

### 6. Error Codes

```dart
// BAD - Hardcoded error codes
if (errorCode == 1300) { /* invalid refresh token */ }

// GOOD - Error code constants
class Constant {
  static const invalidRefreshToken = 1300;
  static const multipleDeviceLogin = 1602;
}
if (errorCode == Constant.invalidRefreshToken) { /* ... */ }
```

### 7. Durations

```dart
// BAD - Hardcoded durations
await Future.delayed(Duration(seconds: 3));

// GOOD - Duration constants
class Constant {
  static const snackBarDuration = Duration(seconds: 3);
  static const animationDuration = Duration(milliseconds: 500);
}
await Future.delayed(Constant.snackBarDuration);
```

### 8. Pagination Values

```dart
// BAD - Hardcoded pagination
final page = 1;
final limit = 20;

// GOOD - Pagination constants
class Constant {
  static const initialPage = 1;
  static const itemsPerPage = 20;
  static const invisibleItemsThreshold = 3;
}
final page = Constant.initialPage;
final limit = Constant.itemsPerPage;
```

## Decision Guide

### Local Constant (In File) When:
- Constant is only used in 1 file
- Constant is related to specific UI/layout of that component
- Constant is an implementation detail

**Examples:**
```dart
// Component-specific layout values
static const _cardPadding = 16.0;
static const _iconSize = 24.0;

// Page-specific constraints
static const _maxFormWidth = 400.0;
static const _inputHeight = 48.0;
```

### Global Constant (In `Constant`) When:
- Constant is used in **2+ files**
- Constant is a common business rule
- Constant is a common app config
- **Not sure** → Prefer global (avoid duplication later)

**Examples:**
```dart
// API config - used in all API calls
static const connectTimeout = Duration(seconds: 30);

// Date formats - used in multiple pages
static const fddMMyyyy = 'dd/MM/yyyy';

// Business constraints - used in multiple features
static const minAdultAge = 18;
static const maxImageSize = 5 * 1024 * 1024; // 5MB
```

## Special Cases

### UI Text vs Constants

**Do NOT create constants for UI text** - Use t.<group>.<key> for strings:

```dart
// BAD - UI text in constant
class Constant {
  static const welcomeText = 'Welcome!';
}

// GOOD - UI text in .i18n.json files
// en.i18n.json
{
  "home": {
    "welcomeMessage": "Welcome!",
    "profileTitle": "Profile"
  }
}

// Usage
CommonText(t.home.welcomeMessage)
```

**Create constants for logic strings**:

```dart
// GOOD - Logic strings
class Constant {
  static const asterisk = '*'; // Display required field
  static const dateFormatPattern = 'yyyy-MM-dd'; // Format date
  static const emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'; // Regex
}
```

### Enum Values vs Constants

When there are multiple related values, consider using enum:

```dart
// Less good - Multiple related constants
class Constant {
  static const genderMale = 0;
  static const genderFemale = 1;
  static const genderOther = 2;
}

// Better - Enum
enum Gender {
  male(0),
  female(1),
  other(2);

  const Gender(this.value);
  final int value;
}
```

## Summary Rules

1. **Always create constants** for: URLs, formats, magic numbers, magic chars, magic strings, error codes, durations, paths
2. **Used in 1 file** → Private constant in that file (prefix with `_`)
3. **Used in multiple files** → Global constant in `lib/common/constant.dart`
4. **Do NOT create constants** for UI text → Use `.i18n.json` files
5. **When unsure** → Prefer global constant (avoid duplication later)
6. **Group constants** by category with clear comments
7. **Constant names** must clearly describe their purpose

## Complete Example

```dart
// lib/common/constant.dart
class Constant {
  const Constant._();

  // ===== API Configuration =====
  static const apiBaseUrl = 'https://api.example.com/';
  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);

  // ===== Date/Time Formats =====
  static const fddMMyyyy = 'dd/MM/yyyy';
  static const fHHmm = 'HH:mm';
  static const fyyyyMMdd = 'yyyy-MM-dd';

  // ===== Error Codes =====
  static const invalidRefreshToken = 1300;
  static const multipleDeviceLogin = 1602;
  static const userNotVerifiedErrorId = '30021';

  // ===== Pagination =====
  static const initialPage = 1;
  static const itemsPerPage = 20;
  static const invisibleItemsThreshold = 3;

  // ===== Durations =====
  static const snackBarDuration = Duration(seconds: 3);
  static const animationDuration = Duration(milliseconds: 300);
  static const debounceDelay = Duration(milliseconds: 500);

  // ===== Business Rules =====
  static const minAdultAge = 18;
  static const maxImageSize = 5 * 1024 * 1024; // 5MB
  static const maxFileNameLength = 100;

  // ===== Special Characters =====
  static const asterisk = '*';
  static const atSign = '@';
  static const comma = ',';
  static const space = ' ';
}
```

## Validation Checklist

- [ ] No hardcoded URLs, formats, or magic values in code
- [ ] Constants used in 1 file are declared locally with `_` prefix
- [ ] Constants used in multiple files are in `lib/common/constant.dart`
- [ ] UI text uses `.i18n.json` files, not constants
- [ ] Related values use enum instead of multiple constants
- [ ] Constant names clearly describe their purpose
- [ ] Constants are grouped by category with comments
