# Golden Test Instructions

## Overview

This document provides comprehensive guidelines for writing golden tests in this project, ensuring consistent UI testing across all components and pages.

## Test Structure

Golden tests follow a **3-level group structure**:

```
Level 1: Constructor Group (constructor name)
├── Level 2: happy (normal cases)
│   ├── Test case 1
│   ├── Test case 2
│   └── ...
└── Level 2: unhappy (edge cases)
    ├── Test case 1
    ├── Test case 2
    └── ...
```

**Key Points:**
- **Level 1**: Constructor name (class name for default, factory/named constructor name otherwise)
- **Level 2**: Always `'happy'` and `'unhappy'` sub-groups
- **Level 3**: Individual test cases with `testGoldens`

## Quick Reference

| Rule | Requirement |
|------|-------------|
| File naming | `*_test.dart` |
| Path structure | Mirror `lib` folder structure |
| Group structure | Constructor → Happy/Unhappy → Test cases |
| Level 1 name | Constructor name (class name for default) |
| Level 2 names | `'happy'` and `'unhappy'` only |
| Filename pattern | `[constructor name]/[test case]` |

## Core Rules

### 1. File Structure

- Test files must end with `_test.dart`
- Test file paths must mirror the `lib` folder structure
  - Code: `lib/ui/page/splash/splash_page.dart`
  - Test: `test/widget_test/ui/page/splash/splash_page_test.dart`
- Reuse variables/functions from `test/common` - do not create new ones

### 2. Test Group Organization

#### 3-Level Structure

```dart
void main() {
  group('[constructor_name]', () {  // Level 1: Constructor name
    group('happy', () { ... });     // Level 2: Normal cases
    group('unhappy', () { ... });   // Level 2: Edge cases
  });
}
```

#### Level 1: Constructor Groups

| Constructor Type | Group Name | Example |
|-----------------|------------|---------|
| Default | Class name | `'SplashPage'` for `SplashPage()` |
| Factory | Factory name | `'passwordResetCompleted'` for `ConfirmDialog.passwordResetCompleted()` |
| Named | Constructor name | `'withData'` for `MyWidget.withData()` |

#### Level 2: Sub-groups

- **"happy"**: Normal/expected use cases with realistic mock data
- **"unhappy"**: Edge cases, abnormal cases, hidden cases (empty states, long text, max/min values)

**Important**: If a `happy` or `unhappy` group has no test cases, you MUST add a comment explaining why:

```dart
// No edge cases for this simple constructor
// ignore: empty_test_group
group('unhappy', () {});
```

### 3. Filename Pattern

Pattern: `[constructor name]/[test case_description]`

Examples:
- `'SplashPage/default state'` (default constructor)
- `'passwordResetCompleted/default'` (factory constructor)
- `'withData/with full data'` (named constructor)

### 4. Test Case Rules

- Don't write tests for loading cases
- Use clear, descriptive test case descriptions
- Merge similar test cases (e.g., combine all "long text" fields into one test)
- For network images: Pass `hasNetworkImage: true` and use `testImageUrl` variable
- For local images: Pass `""` or `null`

## testWidget Parameters Guide

### Core Parameters (Required)

```dart
await tester.testWidget(
  filename: 'SplashPage/default state', // Required
  widget: const SplashPage(),           // Required
  overrides: [                          // Required
    splashViewModelProvider.overrideWith(
      (ref) => MockSplashViewModel(const CommonState(data: SplashState())),
    ),
  ],
);
```

### Optional Parameters

| Parameter | Use Case | Default |
|-----------|----------|---------|
| `hasNetworkImage` | UI contains network images | `false` |
| `mockToday` | Time-sensitive UI or mock data using `DateTime.now()` | `clock.now()` |
| `additionalDevices` | Test on specific device sizes | `[]` |
| `fullHeightDeviceCases` | Test scrollable content on specific devices | `[]` |
| `includeTextScalingCase` | Test accessibility with different text sizes | `true` |
| `mergeToSingleFile` | Merge all device screenshots into single file | `true` |
| `useMultiScreenGolden` | Test multiple device sizes in one image | `false` |
| `isDarkMode` | Test dark theme | `false` |
| `locale` | Test specific locale | `TestConfig.defaultLocale` |
| `onCreate` | Setup interactions before screenshot. Signature: `(WidgetTester tester, Key? key)` | - |
| `customPump` | Custom pump logic for animations/async | - |

### Parameter Examples

#### Network Images
```dart
await tester.testWidget(
  filename: 'profile/with avatar',
  widget: const ProfilePage(),
  hasNetworkImage: true, // Precache network images
  overrides: [...],
);
```

#### Time-Sensitive Component
```dart
await tester.testWidget(
  filename: 'calendar/january 2024',
  widget: const CalendarWidget(),
  mockToday: DateTime(2024, 1, 15), // Fixed date
  overrides: [...],
);
```

#### Interactive Component
```dart
await tester.testWidget(
  filename: 'form/filled state',
  widget: const FormPage(),
  onCreate: (tester, key) async {
    // key is the widget key (usually null when mergeToSingleFile: true)
    await tester.enterText(find.byType(CommonTextField).first, 'Test Value');
    await tester.pumpAndSettle();
  },
  overrides: [...],
);
```

**Note about `onCreate` parameters:**
- `tester` - WidgetTester instance for interaction
- `key` - Widget key provided by DeviceBuilder (when `mergeToSingleFile: true`) or `null` (when `mergeToSingleFile: false`)

#### Dialog (Fixed Size)
```dart
await tester.testWidget(
  filename: 'dialog/confirmation',
  widget: const ConfirmationDialog(),
  fullHeightDeviceCases: [], // No full height for dialogs
  includeTextScalingCase: false, // Fixed size
  overrides: [...],
);
```

#### Scrollable Content (Full Height)
```dart
await tester.testWidget(
  filename: 'list/long_content',
  widget: const LongListPage(),
  fullHeightDeviceCases: [AppTestDeviceType.iphone13], // Test full height on iPhone 13
  overrides: [...],
);
```

#### Dark Mode
```dart
await tester.testWidget(
  filename: 'profile/dark_mode',
  widget: const ProfilePage(),
  isDarkMode: true, // Test dark theme
  overrides: [...],
);
```

#### Different Locale
```dart
await tester.testWidget(
  filename: 'welcome/english',
  widget: const WelcomePage(),
  locale: const Locale('en'), // Test English locale
  overrides: [...],
);
```

#### Separate Files Per Device
```dart
await tester.testWidget(
  filename: 'complex_layout/responsive',
  widget: const ComplexLayoutPage(),
  mergeToSingleFile: false, // Generate separate file for each device
  overrides: [...],
);
```

## Template Examples

### Example 1: Default Constructor

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:[app]/index.dart';
import 'package:shared/index.dart';

import '../../../../common/index.dart';

class MockSplashViewModel extends StateNotifier<CommonState<SplashState>>
    with Mock
    implements SplashViewModel {
  MockSplashViewModel(super.state);
}

void main() {
  group('SplashPage', () {
    group('happy', () {
      testGoldens('default state', (tester) async {
        await tester.testWidget(
          filename: 'SplashPage/default state',
          widget: const SplashPage(),
          overrides: [
            splashViewModelProvider.overrideWith(
              (ref) => MockSplashViewModel(
                const CommonState(data: SplashState()),
              ),
            ),
          ],
        );
      });
    });
    
    // No edge cases for splash page's simple display
    // ignore: empty_test_group
    group('unhappy', () {});
  });
}
```

### Example 2: Factory Constructors

```dart
void main() {
  // Level 1: First factory constructor
  group('passwordResetCompleted', () {
    group('happy', () {
      testGoldens('default', (tester) async {
        await tester.testWidget(
          filename: 'passwordResetCompleted/default',
          widget: ConfirmDialog.passwordResetCompleted(
            onConfirmPressed: () {},
          ),
        );
      });
    });
    
    group('unhappy', () {
      testGoldens('long text', (tester) async {
        await tester.testWidget(
          filename: 'passwordResetCompleted/long text',
          widget: ConfirmDialog.passwordResetCompleted(
            onConfirmPressed: () {},
          ),
        );
      });
    });
  });
  
  // Level 1: Second factory constructor
  group('error', () {
    group('happy', () {
      testGoldens('default', (tester) async {
        await tester.testWidget(
          filename: 'error/default',
          widget: ConfirmDialog.error(
            message: 'An error occurred',
            onConfirmPressed: () {},
          ),
        );
      });
    });
    
    group('unhappy', () {
      testGoldens('very long error message', (tester) async {
        await tester.testWidget(
          filename: 'error/very long error message',
          widget: ConfirmDialog.error(
            message: 'Very long error message...',
            onConfirmPressed: () {},
          ),
        );
      });
    });
  });
}
```

### Example 3: Named Constructor

```dart
void main() {
  group('withData', () {
    group('happy', () {
      testGoldens('with full data', (tester) async {
        await tester.testWidget(
          filename: 'withData/with full data',
          widget: UserCard.withData(
            name: 'John Doe',
            email: 'john@example.com',
          ),
        );
      });
    });
    
    group('unhappy', () {
      testGoldens('with long name', (tester) async {
        await tester.testWidget(
          filename: 'withData/with long name',
          widget: UserCard.withData(
            name: 'Very Long Name That Exceeds Normal Length...',
            email: 'john@example.com',
          ),
        );
      });
    });
  });
}
```

## Validation Checklist

### Mock Data Quality
- [ ] Use Japanese text for display content
- [ ] Realistic pricing (e.g., 99999 instead of 1000)
- [ ] Realistic time values (e.g., 999 minutes)
- [ ] Complete item lists
- [ ] Long descriptions with line breaks
- [ ] Realistic IDs and numeric values

### Test Structure
- [ ] Correct import statements
- [ ] Mock ViewModel follows pattern
- [ ] 3-level group structure is correct
- [ ] Filename convention is correct
- [ ] Provider overrides are correct
- [ ] Empty test groups have `// ignore: empty_test_group` with reason

### Parameter Usage
- [ ] `hasNetworkImage` set when needed
- [ ] `mockToday` used for time-sensitive components
- [ ] `onCreate` used for interaction testing
- [ ] `fullHeightDeviceCases` set appropriately for scrollable content
- [ ] `includeTextScalingCase` set appropriately
- [ ] `isDarkMode` used when testing dark theme
- [ ] `locale` set when testing different languages
- [ ] `mergeToSingleFile` set to `false` when need separate files per device

### Execution
- [ ] Test runs successfully with `--update-goldens`
- [ ] Test passes with `--tags=golden`
- [ ] No lint errors
- [ ] Golden images generated without errors

## Critical Rules to Follow

### MUST DO:
- Follow 3-level group structure: Constructor → Happy/Unhappy → Test cases
- Level 1 group name = constructor name (exact match)
- Every constructor group has `happy` and `unhappy` sub-groups
- Use correct filename pattern: `[constructor name]/[test case]`
- Reuse utilities from `test/common/index.dart`
- Use realistic mock data with Japanese text
- Set `hasNetworkImage: true` when UI contains network images

### MUST NOT:
- Create duplicate mock classes or utilities
- Skip happy or unhappy groups
- Use incorrect group names
- Test loading states (only use `data` property in `CommonState`)

## Process Guidelines

### Smart Behavior:
- Can process single file, multiple files, or entire folders
- If file already exists with many errors or rule violations → Regenerate from scratch
- If file exists with minor issues → Only update/fix specific issues
- Provide summary after processing all files

### File Processing Logic:
- Determine target files by scanning folders or using provided file paths
- Check if test file already exists and analyze for rule violations
- Generate or regenerate tests following the 3-level structure
- Generate golden images and verify tests pass
- Handle failures by fixing test cases or source code

## Commands Reference

```bash
# Update golden images
flutter test [test_path] --update-goldens --tags=golden

# Run golden tests
flutter test [test_path] --tags=golden

# Run specific constructor group
flutter test [test_path] --tags=golden --name="SplashPage"

# Run specific happy/unhappy group
flutter test [test_path] --tags=golden --name="SplashPage happy"
flutter test [test_path] --tags=golden --name="SplashPage unhappy"

# Find golden files
find test/widget_test -name "*.png" -type f

# Open golden image
open [golden_image_path]
```
