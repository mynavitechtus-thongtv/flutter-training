# Shared Provider Instructions

## Overview

`shared_provider.dart` contains global Riverpod providers for sharing data across multiple screens. When data changes on one screen, all other screens listening to the provider automatically update.

## When to Use SharedProvider

### Use SharedProvider when:

1. **Data needs synchronization across multiple screens**
   - Favorite/Like status
   - Cart items count
   - Notification count
   - User profile (avatar, name)
   - App settings (language, theme, font size)

2. **Data needs persistence and restoration**
   - User preferences
   - App configuration
   - Last selected filters/sort options

3. **Data can be changed from multiple places**
   - Job favorite status (JobListPage, JobDetailPage, FavoritePage)
   - Cart items (ProductListPage, ProductDetailPage, CartPage)

### Do NOT use SharedProvider when:

1. Data is used in a single screen → use that screen's ViewModel
2. Data is only passed from screen A to screen B → use navigation arguments
3. Temporary UI state (form input, scroll position) → keep as local state

## SharedProvider vs ViewModel

| Aspect | SharedProvider | ViewModel |
|--------|----------------|-----------|
| **Scope** | Global, multiple screens | Local, single screen |
| **Lifecycle** | App-wide | Screen-wide |
| **Data Sync** | Auto-sync between screens | No sync |
| **Use Case** | Shared data, settings | Screen-specific logic |
| **Type** | StateProvider, NotifierProvider | StateNotifierProvider |

## Patterns

### Pattern 1: StateProvider with Auto-Save

For simple state that should be persisted to SharedPreferences.

```dart
// lib/ui/shared/shared_provider.dart
final languageCodeProvider = StateProvider<LanguageCode>(
  (ref) {
    // Listen to changes and auto-save
    ref.listenSelf((previous, next) {
      ref.appPreferences.saveLanguageCode(next.value);
    });

    // Load initial value from SharedPreferences
    return LanguageCode.fromValue(ref.appPreferences.languageCode);
  },
);

// Usage
final languageCode = ref.watch(languageCodeProvider);
ref.read(languageCodeProvider.notifier).state = LanguageCode.en;
```

### Pattern 2: NotifierProvider with Complex Logic

For complex state with business logic (CRUD operations, API calls).

```dart
// State class
class FavoriteJobsState {
  const FavoriteJobsState({
    this.favoriteJobIds = const {},
    this.isLoading = false,
  });

  final Set<String> favoriteJobIds;
  final bool isLoading;

  FavoriteJobsState copyWith({
    Set<String>? favoriteJobIds,
    bool? isLoading,
  }) { /* ... */ }

  bool isFavorite(String jobId) => favoriteJobIds.contains(jobId);
}

// Notifier class
class FavoriteJobsNotifier extends Notifier<FavoriteJobsState> {
  @override
  FavoriteJobsState build() {
    final savedIds = ref.appPreferences.favoriteJobIds;
    return FavoriteJobsState(favoriteJobIds: savedIds);
  }

  Future<void> toggleFavorite(String jobId) async {
    final isFavorite = state.isFavorite(jobId);
    
    // Optimistic update
    final newIds = Set<String>.from(state.favoriteJobIds);
    if (isFavorite) {
      newIds.remove(jobId);
    } else {
      newIds.add(jobId);
    }
    state = state.copyWith(favoriteJobIds: newIds);

    // Save to API and SharedPreferences
    try {
      if (isFavorite) {
        await ref.appApiService.unfavoriteJob(jobId);
      } else {
        await ref.appApiService.favoriteJob(jobId);
      }
      await ref.appPreferences.saveFavoriteJobIds(newIds);
    } catch (e) {
      // Rollback on error
      state = state.copyWith(favoriteJobIds: state.favoriteJobIds);
      rethrow;
    }
  }
}

// Provider
final favoriteJobsProvider = NotifierProvider<FavoriteJobsNotifier, FavoriteJobsState>(
  () => FavoriteJobsNotifier(),
);

// Usage
final favoriteState = ref.watch(favoriteJobsProvider);
final isFavorite = favoriteState.isFavorite(jobId);
ref.read(favoriteJobsProvider.notifier).toggleFavorite(jobId);
```

### Pattern 3: StreamProvider for Real-time Data

For real-time data from WebSocket, Firestore, or Streams.

```dart
// Provider listens to notification stream
final notificationCountProvider = StreamProvider<int>((ref) {
  return ref.firebaseMessagingService.notificationCountStream;
});

// Usage
final notificationCount = ref.watch(notificationCountProvider).value ?? 0;
```

## Best Practices

### 1. Naming Convention

```dart
// GOOD - Clear, descriptive names
final languageCodeProvider = StateProvider<LanguageCode>(...);
final favoriteJobsProvider = NotifierProvider<FavoriteJobsNotifier, FavoriteJobsState>(...);
final currentUserProvider = StateProvider<UserModel?>(...);

// BAD - Vague names
final langProvider = StateProvider<LanguageCode>(...);
final jobsProvider = NotifierProvider<JobsNotifier, JobsState>(...);
```

### 2. Auto-Save to Persistence

```dart
// GOOD - Auto-save when state changes
final settingsProvider = StateProvider<Settings>(
  (ref) {
    ref.listenSelf((previous, next) {
      ref.appPreferences.saveSettings(next); // Auto-save
    });
    return ref.appPreferences.settings;
  },
);
```

### 3. Optimistic Updates with Rollback

```dart
// GOOD - Optimistic update + rollback on error
Future<void> toggleFavorite(String jobId) async {
  final oldState = state;
  
  // Optimistic update
  final newIds = Set<String>.from(state.favoriteJobIds);
  if (state.isFavorite(jobId)) {
    newIds.remove(jobId);
  } else {
    newIds.add(jobId);
  }
  state = state.copyWith(favoriteJobIds: newIds);

  try {
    await ref.appApiService.toggleFavorite(jobId);
  } catch (e) {
    // Rollback on error
    state = oldState;
    rethrow;
  }
}
```

### 4. Use `select` to Optimize Rebuilds

```dart
// GOOD - Only rebuild when itemCount changes
final cartItemCount = ref.watch(cartProvider.select((state) => state.itemCount));

// BAD - Rebuild when any cart property changes
final cartState = ref.watch(cartProvider);
final itemCount = cartState.itemCount;
```

### 5. Clear SharedProvider on Logout

```dart
// GOOD - Clear shared data on logout
class SharedViewModel {
  Future<void> logout() async {
    try {
      await _ref.appApiService.logout();
    } catch (e) {
      Log.e('logout error', errorObject: e);
    } finally {
      // Clear all shared providers
      _ref.invalidate(currentUserProvider);
      _ref.invalidate(favoriteJobsProvider);
      _ref.invalidate(cartProvider);
      
      await _ref.appPreferences.clearCurrentUserData();
      await _ref.nav.replaceAll([const LoginRoute()]);
    }
  }
}
```

## Decision Tree

```
Where is the data used?
├─ Single screen
│  └─ Use that screen's ViewModel
│
└─ Multiple screens
   ├─ Needs real-time sync?
   │  ├─ Yes → SharedProvider (NotifierProvider)
   │  └─ No → Pass via navigation args
   │
   └─ App-wide settings?
      └─ Yes → SharedProvider (StateProvider with auto-save)
```

## Summary Rules

1. Use SharedProvider for data that must sync across multiple screens
2. Use StateProvider for simple state with auto-save
3. Use NotifierProvider for complex state with business logic
4. Use StreamProvider for real-time data
5. Auto-save state to SharedPreferences on changes
6. Use optimistic updates with rollback on error
7. Use `select` to optimize rebuilds
8. Handle null/empty cases with default values
9. Clear providers on logout
10. Document sync behavior in comments
