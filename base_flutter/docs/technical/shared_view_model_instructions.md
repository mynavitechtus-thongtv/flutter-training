# SharedViewModel Instructions

## Overview

Guidelines for using `SharedViewModel` to implement shared logic that requires data access (API, Database, SharedPreferences) across multiple ViewModels.

## SharedViewModel vs AppUtil

| Aspect | SharedViewModel | AppUtil |
|--------|----------------|---------|
| **Purpose** | Shared logic with data access | Pure utility functions |
| **Data Access** | Yes (via `ref`) | No |
| **Dependencies** | API, DB, Preferences | None |
| **Type** | Class with Ref | Static utility class |

## When to Use SharedViewModel

**Use SharedViewModel when:**
- Function needs access to API/Database/SharedPreferences
- Function is used in multiple ViewModels
- Function needs dependencies injected via `ref`

**Use AppUtil when:**
- Function is pure logic (validation, formatting, calculation)
- Function does NOT need data access
- Function does not require dependencies

## Structure

```dart
// lib/ui/shared/shared_view_model.dart
final sharedViewModelProvider = Provider((_ref) => SharedViewModel(_ref));

class SharedViewModel {
  SharedViewModel(this._ref);

  final Ref _ref;

  // Shared methods here
  Future<void> logout() async { /* ... */ }
  Future<String> get deviceToken async { /* ... */ }
}

// Usage in ViewModel
class MyViewModel extends BaseViewModel<MyState> {
  Future<void> onLogoutPressed() async {
    await runCatching(
      action: () async {
        await ref.sharedViewModel.logout(); // Reuse shared logic
      },
      actionName: 'logout',
    );
  }
}
```

## Rule: Do NOT try/catch in SharedViewModel Methods

IMPORTANT: Methods in SharedViewModel must NOT use try/catch; otherwise `runCatching` cannot handle errors.

```dart
// BAD - Try/catch prevents runCatching
class SharedViewModel {
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final profile = await _ref.appApiService.getUserProfile(userId);
      return profile;
    } catch (e) {
      // Error caught here!
      Log.e('Error getting profile', errorObject: e);
      rethrow; // Has rethrow but still not good
    }
  }
}

// GOOD - No try/catch; let runCatching handle errors
class SharedViewModel {
  Future<UserProfile> getUserProfile(String userId) async {
    // No try/catch, throw exception directly
    final profile = await _ref.appApiService.getUserProfile(userId);
    return profile;
    // If error occurs, exception will bubble up
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    // No try/catch
    await _ref.appApiService.updateSettings(settings);
    await _ref.appPreferences.saveUserSettings(settings);
    // If error occurs, exception will bubble up
  }
}

// GOOD - runCatching in ViewModel will catch errors
class ProfileViewModel extends BaseViewModel<ProfileState> {
  Future<void> loadProfile() async {
    await runCatching(
      action: () async {
        // Error from SharedViewModel will be caught here
        final profile = await ref.sharedViewModel.getUserProfile(userId);
        data = data.copyWith(profile: profile);
      },
      // runCatching will handle error properly
    );
  }
}
```

## Exception: Try/catch Only When Spec Requires Silent Failure

Only use try/catch in SharedViewModel when spec.md or prompt explicitly requires that the method should not handle or show errors.

```dart
// GOOD - Try/catch when spec requires silent fail
class SharedViewModel {
  // spec.md: "Logout API call should not show error if fails"
  Future<void> logout() async {
    try {
      final refreshToken = await _ref.appPreferences.refreshToken;
      await _ref.appApiService.postAuthLogout(refreshToken: refreshToken);
    } catch (e) {
      // Spec requirement: silent fail, log only
      Log.e('logout error: $e', errorObject: e);
    } finally {
      // Always force logout even if API call fails
      await forceLogout();
    }
  }

  // spec.md: "Device token fetching should not fail the app"
  Future<String> get deviceToken async {
    try {
      final token = await _ref.firebaseMessagingService.deviceToken;
      if (token != null) {
        await _ref.appPreferences.saveDeviceToken(token);
      }
      return token ?? '';
    } catch (e) {
      // Spec requirement: return empty string on error
      Log.e('Failed to get device token', errorObject: e);
      return ''; // Silent fail
    }
  }
}
```

## Decision Tree: SharedViewModel vs AppUtil

```
Function used in multiple places?
├─ No → Write directly in ViewModel
└─ Yes → Need data access (API/DB/Prefs)?
    ├─ No → AppUtil (static utility)
    └─ Yes → SharedViewModel (with Ref)
```

## Summary Rules

1. **SharedViewModel for shared logic with data access**
2. **AppUtil for pure utility functions**
3. **No try/catch by default** (let runCatching handle errors)
4. **Try/catch only when spec requires silent fail**
5. **Always call SharedViewModel methods inside runCatching**
