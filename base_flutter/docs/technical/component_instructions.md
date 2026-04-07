# Reusable Component Instructions

## Overview

This guide provides comprehensive guidelines for creating reusable UI components in the project.

## Common Rules

- Follow the instructions in [common_ui_coding_instructions.md](common_ui_coding_instructions.md)

## Specific Rules

### 1. File and API Shape

**Location**: `lib/ui/component/<component_name>/<component_name>.dart`

**One Public Widget Per File**:
- Expose exactly **one public widget class per file**
- Keep additional layout helpers private (prefixed with `_`)
- Design constructors to be flexible for all variants

```dart
// GOOD - One public widget, flexible parameters
class UserCard extends HookConsumerWidget {
  const UserCard({
    super.key,
    required this.user,
    this.onTap,
    this.showAvatar = true,
    this.trailing,
  });

  final UserModel user;
  final VoidCallback? onTap;
  final bool showAvatar;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildCard();
  }

  // Private helper widgets
  Widget _buildCard() { /* ... */ }
  Widget _buildAvatar() { /* ... */ }
}

// BAD - Multiple public widgets in one file
class UserCard extends StatelessWidget { /* ... */ }
class UserAvatar extends StatelessWidget { /* ... */ }
class UserInfo extends StatelessWidget { /* ... */ }
```

### 2. Documentation

Document each component with Dart doc comments:

```dart
/// A card component that displays user information with an optional avatar.
///
/// Usage:
/// ```dart
/// UserCard(
///   user: userData,
///   showAvatar: true,
///   onTap: () => navigateToProfile(),
/// )
/// ```
///
/// Parameters:
/// - [user]: The user data to display
/// - [onTap]: Optional callback when card is tapped
/// - [showAvatar]: Whether to show user avatar (default: true)
/// - [trailing]: Optional trailing widget (e.g., icon button)
class UserCard extends HookConsumerWidget {
  // Implementation...
}
```

### 3. Flexibility and Reusability

**Support Multiple Variants**:
- Use parameters for flexibility
- Create named constructors for common variants
- Avoid hardcoding values

```dart
// GOOD - Flexible with named constructors
class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.icon,
  });

  // Named constructor for primary variant
  const CommonButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  }) : backgroundColor = AppColors.primary,
       textColor = AppColors.onPrimary,
       icon = null;

  // Named constructor for secondary variant
  const CommonButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  }) : backgroundColor = AppColors.secondary,
       textColor = AppColors.onSecondary,
       icon = null;

  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final Widget? icon;

  // Implementation...
}

// BAD - Too rigid, not reusable
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Hardcoded!
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
```

### 4. Flutter Hooks

Use `flutter_hooks` for controllers:

```dart
// GOOD - Using hooks
class SearchField extends HookConsumerWidget {
  const SearchField({
    super.key,
    this.onChanged,
  });

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();

    return CommonTextField(
      controller: controller,
      onChanged: onChanged,
      // ...
    );
  }
}

// BAD - StatefulWidget for simple controller
class SearchField extends StatefulWidget {
  // Requires initState, dispose, more boilerplate
}
```

### 5. Golden Tests

**Test Structure**:
- One test group per constructor variant
- Each group contains `happy` and `unhappy` sub-groups
- Group name = constructor name (or "default" for single constructor)

#### Multiple Named Constructors

```dart
// test/widget_test/ui/component/common_button/common_button_test.dart
void main() {
  // Test group for 'primary' constructor
  group('primary', () {
    group('happy', () {
      testGoldens('default state', (tester) async {
        await tester.testWidget(
          filename: 'common_button/primary/default state',
          widget: CommonButton.primary(
            text: 'Submit',
            onPressed: () {},
          ),
        );
      });

      testGoldens('with loading', (tester) async {
        await tester.testWidget(
          filename: 'common_button/primary/with loading',
          widget: CommonButton.primary(
            text: 'Submit',
            onPressed: () {},
            isLoading: true,
          ),
        );
      });
    });

    group('unhappy', () {
      testGoldens('with very long text', (tester) async {
        await tester.testWidget(
          filename: 'common_button/primary/with very long text',
          widget: CommonButton.primary(
            text: 'This is a very long button text that might overflow',
            onPressed: () {},
          ),
        );
      });
    });
  });

  // Test group for 'secondary' constructor
  group('secondary', () {
    group('happy', () {
      testGoldens('default state', (tester) async {
        await tester.testWidget(
          filename: 'common_button/secondary/default state',
          widget: CommonButton.secondary(
            text: 'Cancel',
            onPressed: () {},
          ),
        );
      });
    });

    group('unhappy', () {
      testGoldens('with very long text', (tester) async {
        await tester.testWidget(
          filename: 'common_button/secondary/with very long text',
          widget: CommonButton.secondary(
            text: 'This is a very long button text',
            onPressed: () {},
          ),
        );
      });
    });
  });
}
```

#### Single Constructor (Use "default")

```dart
// test/widget_test/ui/component/user_card/user_card_test.dart
void main() {
  group('default', () {
    group('happy', () {
      testGoldens('with all fields', (tester) async {
        await tester.testWidget(
          filename: 'user_card/default/with all fields',
          widget: UserCard(
            user: mockUser,
            showAvatar: true,
          ),
        );
      });

      testGoldens('with trailing icon', (tester) async {
        await tester.testWidget(
          filename: 'user_card/default/with trailing icon',
          widget: UserCard(
            user: mockUser,
            trailing: CommonImage.svg(image.iconChevronRight),
          ),
        );
      });
    });

    group('unhappy', () {
      testGoldens('with very long name', (tester) async {
        await tester.testWidget(
          filename: 'user_card/default/with very long name',
          widget: UserCard(
            user: mockUser.copyWith(
              name: 'This is a very long user name that might overflow',
            ),
          ),
        );
      });

      testGoldens('with empty avatar', (tester) async {
        await tester.testWidget(
          filename: 'user_card/default/with empty avatar',
          widget: UserCard(
            user: mockUser.copyWith(avatarUrl: null),
          ),
        );
      });
    });
  });
}
```

**Test Guidelines**:
- Group name = constructor name (e.g., `primary`, `secondary`) or `default`
- `happy`: Normal/expected use cases with typical data
- `unhappy`: Edge cases (long text, empty states, overflow, null values)
- Filename format: `component_name/constructorName/test description`
- Test ALL constructor variants
- Test ALL parameter combinations

### 7. When to Create a Component

**Create in `lib/ui/component/<component_name>/` when**:
- Widget is **reused in multiple pages**
- Widget is **generic enough** for different contexts
- Widget has **complex logic** that should be isolated

**Keep as private widget (`_WidgetName`) when**:
- Widget is only used **once** in a single page
- Widget is **too specific** to that page's context
- Widget is a **simple layout helper**

```dart
// GOOD - Reusable component
// lib/ui/component/status_badge/status_badge.dart
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    // Generic badge that can be used anywhere
  }
}

// GOOD - Private helper in page
// lib/ui/page/user_profile/user_profile_page.dart
class UserProfilePage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommonScaffold(
      body: Column(
        children: [
          _buildHeader(), // Private helper
          _buildContent(), // Private helper
        ],
      ),
    );
  }

  // Private widgets specific to this page
  Widget _buildHeader() { /* ... */ }
  Widget _buildContent() { /* ... */ }
}
```

## Validation Checklist

Before submitting a component:

- [ ] File location: `lib/ui/component/<component_name>/<component_name>.dart`
- [ ] Only one public widget per file
- [ ] Private helpers prefixed with `_`
- [ ] Dart doc comments with usage examples
- [ ] Flexible parameters (avoid hardcoded values)
- [ ] Named constructors for common variants
- [ ] Uses `flutter_hooks` for controllers
- [ ] Golden tests for all constructors
- [ ] Each constructor has `happy` and `unhappy` groups
- [ ] No lint errors
- [ ] No compile errors
