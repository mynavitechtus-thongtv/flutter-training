# Navigation Instructions

## Overview

Use `AppNavigator` (accessed via `ref.nav`) to perform all navigation actions.

```dart
// GOOD - Use ref.nav for normal cases
await ref.nav.push(const ProfileRoute());
await ref.nav.pop();
await ref.nav.showDialog(...);
```

**Exception:** When dialog/popup has `canPop: false`, must use `Navigator.of(context).pop()` to close:

```dart
// Dialog with canPop: false
await ref.nav.showDialog(
  ForceUpdateDialog(),
  canPop: false,
  barrierDismissible: false,
);

// Inside ForceUpdateDialog - must use Navigator.of(context).pop()
CommonButton.text(
  text: 'Update Now',
  onPressed: () {
    Navigator.of(context).pop(); // Required with canPop: false
    // ref.nav.pop() will NOT work!
  },
)
```

## Navigation Methods

### 1. push() - Navigate to New Screen

**When to use:** Navigate to a new screen and keep the current screen on the stack.

```dart
// Basic push
await ref.nav.push(const UserDetailRoute(userId: '123'));

// Push and receive result
final result = await ref.nav.push<bool>(const ConfirmDialogRoute());
if (result == true) {
  // User confirmed
}
```

**Use cases:**
- Navigate to detail screen
- Navigate to edit screen
- Any screen that needs to be returned to

### 2. replaceAll() - Replace Entire Stack

**When to use:** Clear the entire navigation stack and create a new one. Usually used after authentication changes.

```dart
// Replace entire stack with home screen
await ref.nav.replaceAll([const HomeRoute()]);

// Replace with multiple screens
await ref.nav.replaceAll([
  const MainRoute(),
  const ProfileRoute(),
]);
```

**Use cases:**
- **After successful login** → `replaceAll([const TopRoute()])`
- **After logout** → `replaceAll([const LoginRoute()])`
- **Session expired** → `replaceAll([const LoginRoute()])`

**Common mistakes:**
```dart
// BAD - Using push after login
await ref.nav.push(const HomeRoute()); // User can go back to login!

// GOOD - Using replaceAll after login
await ref.nav.replaceAll([const TopRoute()]); // Cannot go back
```

### 3. pop() - Go Back

**When to use:** Go back to the previous screen.

```dart
// Simple pop
await ref.nav.pop();

// Pop with result
await ref.nav.pop<bool>(result: true);

// Pop with complex result
await ref.nav.pop<UserModel>(result: updatedUser);
```

**Use cases:**
- Close current screen
- Cancel action and go back
- Save data and return to previous screen

### 4. Other Navigation Methods

#### replace() - Replace Current Screen
```dart
await ref.nav.replace(const HomeRoute());
```

#### popAndPush() - Replace with Animation
```dart
await ref.nav.popAndPush(const NewPasswordRoute());
```

#### popUntilRoot() - Back to Root
```dart
ref.nav.popUntilRoot();
```

#### popUntilRouteName() - Back to Specific Screen
```dart
ref.nav.popUntilRouteName('HomeRoute');
```

## Dialog Methods

### showDialog() - Show Dialog

```dart
// Basic dialog
await ref.nav.showDialog(
  ConfirmDialog.success(
    doOnConfirm: () {},
  ),
);

// Dialog with result
final confirmed = await ref.nav.showDialog<bool>(
  ConfirmDialog.discardChanges(
    doOnConfirm: () {},
  ),
);

// Dialog cannot be dismissed
await ref.nav.showDialog(
  ErrorDialog.error(message: 'Error occurred'),
  barrierDismissible: false,
  canPop: false,
);
```

**Parameters:**
- `barrierDismissible`: Can tap outside to close (default: `true`)
- `useSafeArea`: Respect safe area (default: `false`)
- `useRootNavigator`: Use root navigator (default: `true`)
- `canPop`: Can use back button to close (default: `true`)

### showGeneralDialog() - Show Custom Dialog

```dart
await ref.nav.showGeneralDialog(
  CustomAnimatedDialog(),
  transitionDuration: Duration(milliseconds: 300),
  transitionBuilder: (context, animation, secondaryAnimation, child) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  },
);
```

## Bottom Sheet Methods

### showModalBottomSheet() - Show Bottom Sheet

```dart
// Basic bottom sheet
await ref.nav.showModalBottomSheet(
  SelectOptionsBottomSheet(options: options),
);

// Full-height scrollable bottom sheet
await ref.nav.showModalBottomSheet(
  FilterBottomSheet(),
  isScrollControlled: true,
);

// Bottom sheet with result
final selectedOption = await ref.nav.showModalBottomSheet<String>(
  OptionsBottomSheet(),
);
```

**Parameters:**
- `isScrollControlled`: Allow full height (default: `false`)
- `useRootNavigator`: Use root navigator (default: `false`)
- `isDismissible`: Can dismiss by tapping outside (default: `true`)
- `enableDrag`: Can drag down to dismiss (default: `true`)
- `canPop`: Can use back button to close (default: `true`)

## SnackBar Methods

### showSnackBar() - Show SnackBar

```dart
// Success snackbar
ref.nav.showSnackBar(
  CommonSnackBar.success(message: 'Saved successfully'),
);

// Error snackbar
ref.nav.showSnackBar(
  CommonSnackBar.error(message: 'Failed to save'),
);

// Info snackbar
ref.nav.showSnackBar(
  CommonSnackBar.info(message: 'Please wait...'),
);
```

## Tab Navigation Methods

### navigateToBottomTab() - Switch Tab

```dart
// Switch to tab index 0
ref.nav.navigateToBottomTab(index: 0);

// Switch without animation
ref.nav.navigateToBottomTab(index: 1, notify: false);
```

### popUntilRootOfCurrentBottomTab() - Reset Current Tab

```dart
// Reset current tab to root
ref.nav.popUntilRootOfCurrentBottomTab();
```

## Adding New Routes to app_router.dart

**Rule:** Every time you create a new Page, **REQUIRED** must add route to `lib/navigation/routes/app_router.dart`.

### AutoRoute vs buildCustomRoute

#### Use `AutoRoute` - Page has AppBar with Back button

If page has `CommonAppBar.back()` (back button):

```dart
// lib/navigation/routes/app_router.dart
@override
List<AutoRoute> get routes => [
  AutoRoute(page: UserDetailRoute.page), // Has back button
  AutoRoute(page: EditProfileRoute.page), // Has back button
  AutoRoute(page: SettingsRoute.page), // Has back button
];
```

**When to use `AutoRoute`:**
- Page has `CommonAppBar.back()`
- Page has standard navigation (user can go back)
- Page is detail/edit/sub-page of flow

#### Use `buildCustomRoute` - Page has Close button or no AppBar

If page has `CommonAppBar.close()` or no AppBar (full screen):

```dart
// lib/navigation/routes/app_router.dart
@override
List<AutoRoute> get routes => [
  buildCustomRoute(
    page: LoginRoute.page,
    transitionsBuilder: TransitionsBuilders.fadeIn,
  ), // Full screen login, no back
  
  buildCustomRoute(
    page: OnboardingRoute.page,
    transitionsBuilder: TransitionsBuilders.fadeIn,
  ), // Full screen onboarding
  
  buildCustomRoute(
    page: ImageViewerRoute.page,
    transitionsBuilder: TransitionsBuilders.fadeIn,
  ), // Full screen viewer with close button
];
```

**When to use `buildCustomRoute`:**
- Page has `CommonAppBar.close()` (X button)
- Page has no AppBar (full screen)
- Page is modal-like screen (login, onboarding, image viewer)
- Page needs fade-in transition instead of slide

### Complete Example

```dart
// lib/navigation/routes/app_router.dart
@override
List<AutoRoute> get routes => [
  // Full screen pages (no AppBar or close button)
  buildCustomRoute(
    page: SplashRoute.page,
    transitionsBuilder: TransitionsBuilders.fadeIn,
  ),
  buildCustomRoute(
    page: LoginRoute.page,
    transitionsBuilder: TransitionsBuilders.fadeIn,
  ),
  
  // Normal pages with back button
  AutoRoute(page: HomeRoute.page),
  AutoRoute(page: ProfileRoute.page),
  AutoRoute(page: EditProfileRoute.page),
  AutoRoute(page: SettingsRoute.page),
];
```

## Rules for Dialog Parameters

**IMPORTANT:** Do not arbitrarily set parameters when calling `showDialog`, `showModalBottomSheet`, `showSnackBar`. All must **be based on spec.md file or prompt**.

### Do not arbitrarily decide:

1. **canPop parameter:**
```dart
// BAD - Arbitrarily set canPop: false
await ref.nav.showDialog(
  ErrorDialog(),
  canPop: false, // Do not arbitrarily set!
);

// GOOD - Check spec.md or prompt first
// If spec.md says: "User cannot dismiss error dialog"
// Then set canPop: false
```

2. **barrierDismissible parameter:**
```dart
// BAD - Arbitrarily set barrierDismissible: false
await ref.nav.showDialog(
  ConfirmDialog(),
  barrierDismissible: false, // Do not arbitrarily set!
);

// GOOD - Only set if spec.md or prompt requires
```

3. **showSnackBar:**
```dart
// BAD - Arbitrarily show snackbar after action
await saveData();
ref.nav.showSnackBar(
  CommonSnackBar.success(message: 'Saved!'), // Do not arbitrarily show!
);

// GOOD - Only show if spec.md or prompt requires
// spec.md: "Show success snackbar after saving"
await saveData();
ref.nav.showSnackBar(
  CommonSnackBar.success(message: l10n.savedSuccessfully),
);
```

### When is it allowed to set?

**Only when spec.md or prompt EXPLICITLY requires:**

```markdown
<!-- spec.md -->
## Error Handling
- Force update dialog cannot be dismissed (canPop: false, barrierDismissible: false)
- Success message shown as snackbar after completing action
- Confirmation dialog can be dismissed by tapping outside
```

**Based on the spec above, code as follows:**

```dart
// GOOD - Spec explicitly says "cannot be dismissed"
await ref.nav.showDialog(
  ForceUpdateDialog(),
  canPop: false,
  barrierDismissible: false,
);

// GOOD - Spec explicitly says "success message shown as snackbar"
await completeAction();
ref.nav.showSnackBar(
  CommonSnackBar.success(message: l10n.actionCompleted),
);
```

### Default Values (when spec does not mention)

If spec.md or prompt **does NOT mention**, use default values:

```dart
// Default values - NO need to explicitly set
await ref.nav.showDialog(
  MyDialog(),
  // barrierDismissible: true, // Default
  // canPop: true, // Default
  // useRootNavigator: true, // Default
);
```

## Summary Rules

1. **Always use `ref.nav`** (except when canPop: false then use Navigator.of(context).pop())
2. **Use `replaceAll`** after login/logout/force logout
3. **Use `push`** for normal navigation (can go back)
4. **Use `replace`** when you do not want user to go back to old screen
5. **Add route to app_router.dart**: AutoRoute for back button, buildCustomRoute for close/no AppBar
6. **Do not arbitrarily set dialog parameters** - must be based on spec.md or prompt
7. **Do not arbitrarily showSnackBar, showDialog, showModalBottomSheet** - only when spec.md or prompt requires
8. **Always handle results** from dialogs and navigation when needed
