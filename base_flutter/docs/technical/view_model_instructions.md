# ViewModel Instructions

## Overview

Guidelines for implementing ViewModels using MVVM architecture with Riverpod and `BaseViewModel`.

## Core Rules

### 1. Mandatory: Wrap API/Database/Preferences Calls in runCatching

All calls to `ref.appPreferences`, `ref.appApiService`, and `ref.appDatabase` inside ViewModel classes MUST be wrapped in `runCatching`.

```dart
// GOOD
Future<void> loadUserData() async {
  await runCatching(
    action: () async {
      final userData = await ref.appApiService.getUserProfile();
      data = data.copyWith(user: userData);
    },
  );
}

// BAD - Not wrapped in runCatching
Future<void> loadUserData() async {
  final userData = await ref.appApiService.getUserProfile();
  data = data.copyWith(user: userData);
}
```

### 2. Use actionName for User Actions

When a function is triggered by user events (e.g., `onPressed`, `onTap`), you MUST set an `actionName` to prevent spam clicks/taps.

```dart
// GOOD - Provides actionName for button press
Future<void> onSubmitButtonPressed() async {
  await runCatching(
    action: () async {
      await ref.appApiService.submitForm(formData);
      ref.nav.pop();
    },
    actionName: 'submit_form', // Prevent spam clicking
  );
}

// GOOD - Each item has own loading state
Future<void> onDeleteItemPressed(String itemId) async {
  await runCatching(
    action: () async {
      await ref.appApiService.deleteItem(itemId);
      _removeItemFromList(itemId);
    },
    actionName: 'delete_$itemId', // Each item has own loading state
  );
}

// UI uses actionName to disable button
CommonButton.text(
  text: 'Submit',
  isLoading: state.isDoingAction('submit_form'), // Button disabled while loading
  onPressed: () => viewModel.onSubmitButtonPressed(),
)
```

### 3. Handle Errors with handleErrorWhen

By default, `ExceptionHandler` processes all errors in a common way (dialog, snackbar, force logout, etc.). For custom handling or ignoring errors, use `handleErrorWhen`.

**How it works:**
- Return `true`: handle via common path (show dialog/snackbar)
- Return `false`: do not use common path — handle or ignore it yourself

**Use Case 1: Custom handling for specific errors**

```dart
// GOOD - Custom handling for specific errors, common for others
Future<void> onSubmitForm() async {
  await runCatching(
    action: () async {
      await ref.appApiService.submitUserProfile(profile);
    },
    handleErrorWhen: (exception) async {
      if (exception is InvalidCredentialsException) {
        data = data.copyWith(errorMessage: 'Invalid email or password');
        return false; // Don't show common error dialog
      } else if (exception is AccountLockedException) {
        data = data.copyWith(errorMessage: 'Account locked. Please contact support.');
        return false; // Don't show common error dialog
      }
      
      // Other exceptions: show error dialog (common handling)
      return true;
    },
  );
}
```

**Use Case 2: Ignore certain errors**

```dart
// GOOD - Ignore error if specified in prompt
Future<void> trackUserAction() async {
  await runCatching(
    action: () async {
      await ref.appApiService.logAnalytics(event);
    },
    handleErrorWhen: (exception) async {
      // Analytics tracking failure shouldn't bother user
      Log.e('Analytics tracking failed', errorObject: exception);
      return false; // Don't show error to user
    },
  );
}
```

**Summary:**
- `handleErrorWhen` returns `true` → handled by `ExceptionHandler` (dialog/snackbar)
- `handleErrorWhen` returns `false` → NOT handled by common path; you handle or ignore it
- No `handleErrorWhen` → by default, handled by `ExceptionHandler`

### 4. Follow the Spec File

A ViewModel MUST follow specifications in `*_spec.md` located in the `[snake_case_screen_name]` folder.

```dart
// Example: lib/ui/page/user_profile/user_profile_spec.md
/*
## User Profile Spec

### API Endpoints
- GET /api/users/{userId} - Get user profile
- PUT /api/users/{userId} - Update user profile

### Business Logic
- Maximum bio length: 500 characters
- Profile photo max size: 5MB
- Required fields: name, email

### Validation
- Email must be valid format
- Name must be 2-50 characters
- Bio max 500 characters
*/

// ViewModel implementation must follow the spec:
class UserProfileViewModel extends BaseViewModel<UserProfileState> {
  @override
  UserProfileState get initialState => const UserProfileState();

  Future<void> loadUserProfile(String userId) async {
    await runCatching(
      action: () async {
        // Use the API endpoint from spec
        final user = await ref.appApiService.get('/api/users/$userId');
        data = data.copyWith(user: user);
      },
    );
  }

  Future<void> onSavePressed() async {
    // Follow validation rules from spec
    final nameError = AppUtil.validateName(data.name, minLength: 2, maxLength: 50);
    final emailError = AppUtil.validateEmail(data.email);
    final bioError = AppUtil.validateTextLength(data.bio, maxLength: 500);

    if (nameError != null || emailError != null || bioError != null) {
      data = data.copyWith(
        nameError: nameError,
        emailError: emailError,
        bioError: bioError,
      );
      return;
    }

    await runCatching(
      action: () async {
        await ref.appApiService.put('/api/users/${data.user.id}', data: {
          'name': data.name,
          'email': data.email,
          'bio': data.bio,
        });
        ref.nav.pop();
      },
      actionName: 'save_profile',
    );
  }
}
```

### 5. Validation Logic in AppUtil

All validation logic MUST be declared in `AppUtil` (`lib/common/util/app_util.dart`). Do NOT write validation directly inside ViewModel.

```dart
// GOOD - Validation in AppUtil
// lib/common/util/app_util.dart
class AppUtil {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }
    return null;
  }

  static String? validateName(String? name, {int minLength = 2, int maxLength = 50}) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
    if (name.length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    if (name.length > maxLength) {
      return 'Name must not exceed $maxLength characters';
    }
    return null;
  }

  static String? validatePassword(String? password, {int minLength = 8}) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }
}

// ViewModel uses validation from AppUtil
class LoginViewModel extends BaseViewModel<LoginState> {
  Future<void> onLoginPressed() async {
    // GOOD - Call validation from AppUtil
    final emailError = AppUtil.validateEmail(data.email);
    final passwordError = AppUtil.validatePassword(data.password);

    if (emailError != null || passwordError != null) {
      data = data.copyWith(
        emailError: emailError,
        passwordError: passwordError,
      );
      return;
    }

    await runCatching(
      action: () async {
        await ref.appApiService.login(data.email, data.password);
        await ref.nav.replaceAll([const TopRoute()]);
      },
      actionName: 'login',
    );
  }
}
```

**Benefits of centralizing validation in AppUtil:**
- Reusability: validation can be reused across many ViewModels
- Maintainability: change in one place applies to entire app
- Testability: easy to unit test in isolation
- Consistency: consistent validation rules across app

### 6. Shared Logic in SharedViewModel

For detailed guidelines on using SharedViewModel for shared logic with data access, see [shared_view_model_instructions.md](shared_view_model_instructions.md).

**Quick Summary:**
- Use `SharedViewModel` for shared logic that needs API/DB/Prefs access
- Use `AppUtil` for pure utility functions without data access
- No try/catch in SharedViewModel methods (let runCatching handle errors)
- Exception: try/catch only when spec requires silent failure

**Decision Tree:**
```
Function used in multiple places?
├─ No → Write directly in ViewModel
└─ Yes → Need data access (API/DB/Prefs)?
    ├─ No → AppUtil (static utility)
    └─ Yes → SharedViewModel (with Ref)
```

## runCatching Parameters

### Method Signature

```dart
Future<void> runCatching({
  required Future<void> Function() action,
  Future<void> Function()? doOnRetry,
  Future<void> Function(AppException)? doOnError,
  Future<void> Function()? doOnSuccessOrError,
  Future<void> Function()? doOnCompleted,
  bool handleLoading = true,
  FutureOr<bool> Function(AppException)? handleRetryWhen,
  FutureOr<bool> Function(AppException)? handleErrorWhen,
  int? maxRetries = 2,
  String? actionName,
})
```

### Key Parameters

#### `action` (required)
The main operation to execute.

#### `handleLoading` (default: true)
Control whether to show global loading indicator.

```dart
// Show loading indicator (default)
await runCatching(
  action: () async { /* API call */ },
  handleLoading: true, // Shows loading spinner
);

// Background operation without loading
await runCatching(
  action: () async { /* background sync */ },
  handleLoading: false, // No loading indicator
);
```

#### `actionName`
Track specific action loading states for UI.

```dart
// Delete specific item with loading state
await runCatching(
  action: () async {
    await apiService.deleteItem(itemId);
  },
  actionName: 'delete_$itemId',
);

// UI checks specific loading state
CommonButton.text(
  text: 'Delete',
  isLoading: state.isDoingAction('delete_${item.id}'),
  onPressed: () => viewModel.deleteItem(item.id),
)
```

#### `doOnError`
Custom error handling per operation.

```dart
await runCatching(
  action: () async {
    await apiService.uploadImage(imageFile);
  },
  doOnError: (exception) async {
    if (exception is NetworkException) {
      _showToast('Network error. Please check your connection.');
    } else if (exception is FileSizeException) {
      _showToast('File too large. Please select a smaller image.');
    }
  },
);
```

#### `maxRetries` (default: 2)
Control automatic retry attempts.

```dart
// Critical operation with more retries
await runCatching(
  action: () async {
    await apiService.saveUserProfile(profile);
  },
  maxRetries: 5, // Retry up to 5 times
);

// One-time operation with no retries
await runCatching(
  action: () async {
    await apiService.deleteAccount();
  },
  maxRetries: 0, // No automatic retries
);
```

## CommonState Properties

### Structure

```dart
class CommonState<T extends BaseState> {
  const CommonState({
    required T data,                    // Your specific state data
    AppException? appException,         // Current exception (if any)
    bool isLoading = false,            // Global loading state
    bool isFirstLoading = false,       // First time loading state
    Map<String, bool> doingAction = {}, // Specific action loading states
  });
  
  bool isDoingAction(String actionName); // Check if specific action is running
}
```

### Properties Explained

#### `data` (required)
Your specific feature state.

```dart
// In ViewModel
class UserProfileState extends BaseState {
  const UserProfileState({
    this.user,
    this.isEditing = false,
    this.validationErrors = const {},
  });
  
  final UserModel? user;
  final bool isEditing;
  final Map<String, String> validationErrors;
}

// Access in UI
final userState = ref.watch(userProfileProvider);
final user = userState.data.user; // Access your specific data
```

#### `isLoading`
Global loading state for entire page.

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(provider);
  
  if (state.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  
  return YourContent();
}
```

#### `isFirstLoading`
Different UI for initial load vs refresh.

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(provider);
  
  if (state.isFirstLoading) {
    return const SkeletonLoader(); // Full-screen loader for first time
  }
  
  return RefreshIndicator(
    onRefresh: () => viewModel.refreshData(),
    child: ListView(
      children: [
        if (state.isLoading) const LinearProgressIndicator(), // Progress bar for refresh
        ...buildContentList(state.data),
      ],
    ),
  );
}
```

#### `doingAction` Map & `isDoingAction(String actionName)`
Track multiple simultaneous action states.

```dart
// ViewModel - Multiple actions
Future<void> likePost(String postId) async {
  await runCatching(
    action: () async {
      await apiService.likePost(postId);
    },
    actionName: 'like_$postId',
  );
}

// UI - Different loading states for each action
Widget buildPostActions(PostModel post, WidgetRef ref) {
  final state = ref.watch(postsProvider);
  
  return Row(
    children: [
      CommonButton.icon(
        icon: Icons.favorite,
        isLoading: state.isDoingAction('like_${post.id}'),
        onPressed: () => ref.read(postsProvider.notifier).likePost(post.id),
      ),
      CommonButton.icon(
        icon: Icons.delete,
        isLoading: state.isDoingAction('delete_${post.id}'),
        onPressed: () => ref.read(postsProvider.notifier).deletePost(post.id),
      ),
    ],
  );
}
```

## Summary Rules

1. **Wrap all API/DB/Prefs calls** in `runCatching`
2. **Use `actionName`** for user-triggered actions (prevent spam)
3. **Use `handleErrorWhen`** for custom error handling
4. **Follow `*_spec.md`** specifications
5. **Validation in `AppUtil`**, not in ViewModel
6. **Shared logic with data access** → `SharedViewModel`
7. **No try/catch in SharedViewModel** (default)
8. **Try/catch only when spec requires silent fail**

## Key Files Reference

- [base_view_model.dart](../../lib/ui/base/base_view_model.dart) - BaseViewModel implementation
- [common_state.dart](../../lib/ui/base/common_state.dart) - CommonState implementation
- [shared_view_model.dart](../../lib/ui/shared/shared_view_model.dart) - SharedViewModel implementation
- [app_util.dart](../../lib/common/util/app_util.dart) - Validation utilities
