# State Management Instructions

## Overview

This document provides guidelines for implementing state management using MVVM architecture with Riverpod.

## Critical Rules

### 1. When using dummy data to build the UI
- First add the corresponding fields to the State class, then assign dummy values from the ViewModel by updating `data` (e.g., `data = data.copyWith(...)`). Avoid keeping temporary UI data in widgets.

```dart
// lib/ui/page/top/view_model/top_state.dart
@freezed
class TopState extends BaseState with _$TopState {
  const factory TopState({
    @Default(<String>[]) List<String> companies,
    @Default(false) bool canStartReading,
  }) = _TopState;
}

// lib/ui/page/top/view_model/top_view_model.dart
class TopViewModel extends BaseViewModel<TopState> {
  TopViewModel() : super(const CommonState(data: TopState()));

  Future<void> loadDummy() async {
    // Set dummy data via state, not local widget variables
    data = data.copyWith(
      companies: const ['株式会社Sample A', '株式会社Sample B'],
      canStartReading: true,
    );
  }
}

// In Page (reactively read from state)
final companies = ref.watch(provider.select((s) => s.data.companies));
```

- Do not add dummy data to `.i18n.json` files.

```dart
// BAD - Dummy data in .i18n.json files
{
  "companyAName": "株式会社Sample A",
  "companyBName": "株式会社Sample B",
}
```

### 2. Use ref.watch + select for granular rebuilds
- Use `ref.watch(provider.select(...))` to rebuild only when selected fields change.

```dart
// Only rebuilds when canStartReading changes
final canStart = ref.watch(provider.select((s) => s.data.canStartReading));
```

### 3. Providers are top-level final variables and use autoDispose
- Define providers at top-level as `final`. For ViewModel providers, use `autoDispose`.

```dart
final topViewModelProvider =
    StateNotifierProvider.autoDispose<TopViewModel, CommonState<TopState>>(
  (ref) => TopViewModel(ref),
);
```

### 4. ViewModel receives Ref and must not hold UI state
- Inject `Ref` via constructor for dependencies. Keep UI state in `data` only.

```dart
class TopViewModel extends BaseViewModel<TopState> {
  TopViewModel(this.ref) : super(const CommonState(data: TopState()));
  final Ref ref;
}
```

### 5. Detail screens use .family.autoDispose
- Parameterized screens should use `StateNotifierProvider.family.autoDispose`.

```dart
final detailProvider =
    StateNotifierProvider.family.autoDispose<DetailViewModel, CommonState<DetailState>, String>(
  (ref, id) => DetailViewModel(ref, id),
);
```

### 6. Use ref.read in callbacks; avoid ref.watch in callbacks and ref.read for UI
- Use `ref.watch` only where rebuilds are needed; use `ref.read` inside callbacks to avoid unintended rebuilds. Do not use `ref.read` to fetch values for UI inside `build`/`buildPage`.

```dart
// Good: use ref.read in callbacks (no rebuild)
@override
Widget buildPage(BuildContext context, WidgetRef ref) {
  final companies = ref.watch(provider.select((s) => s.data.companies));

  return CommonScaffold(
    appBar: CommonAppBar.home(
      onNotificationPressed: ref.read(provider.notifier).onNotificationPressed,
      onMenuPressed: ref.read(provider.notifier).onMenuPressed,
      showNotificationBadge: ref.read(provider.notifier).showNotificationBadge,
    ),
    body: Column(
    children: [
      ...companies.map((company) => CommonText(company)),
    ],
  ));
}
```

```dart
// Bad: ref.read inside build or buildPage for UI (not reactive)
@override
Widget buildPage(BuildContext context, WidgetRef ref) {
  // BAD
  final viewModel = ref.read(provider.notifier);

  useEffect(() {
    Future.microtask(viewModel.init);
    
    return null;
  }, const []);

  return CommonScaffold(
    appBar: CommonAppBar.home(
      onNotificationPressed: viewModel.onNotificationPressed,
      onMenuPressed: viewModel.onMenuPressed,
      showNotificationBadge: viewModel.showNotificationBadge,
    ),
    body: Column(
    children: [
      ...viewModel.companies.map((company) => CommonText(company)),
    ],
  ));
}
```

### 7. Use ref.listen for side effects only
- Use `ref.listen` to respond to state changes with side effects (e.g., navigation, snackbars, logging). Do not render UI with `listen`.

```dart
ref.listen<CommonState<TopState>>(provider, (prev, next) {
  if (prev?.isLoading == true && next.isLoading == false) {
    // show success dialog
  }
});
```

### 8. It’s safe to place ref.listen inside build
- Declaring `ref.listen` inside `build`/`buildPage` is acceptable for side effects only.

```dart
@override
Widget buildPage(BuildContext context, WidgetRef ref) {
  ref.listen(provider, (prev, next) {
    if (next.appException != null) {
      // Trigger a dialog/snackbar here
    }
  });
  // ... UI
  return CommonScaffold(body: Container());
}
```

## Core Riverpod Rules

### 1. Using Ref in Riverpod

- `Ref` object is essential for accessing providers, managing lifecycles, and handling dependencies
- In functional providers, obtain `Ref` as a parameter
- In class-based providers, access it as a property of the Notifier
- In widgets, use `WidgetRef` (a subtype of `Ref`)
- Use `ref.watch` to reactively listen; `ref.read` for one-time access; `ref.listen` for imperative subscriptions

```dart
// Functional provider with Ref
final otherProvider = Provider<int>((ref) => 0);
final provider = Provider<int>((ref) {
  final value = ref.watch(otherProvider);
  return value * 2;
});

// Using WidgetRef in widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(myProvider);
    return Text('$value');
  }
}
```

### 2. Combining Requests

- Use `ref.watch` to combine providers (reactive and declarative)
- When using `ref.watch` with asynchronous providers, use `.future` to await the value
- Avoid calling `ref.watch` inside imperative code (e.g., callbacks or Notifier methods)
- Use `ref.read` only when you cannot use `ref.watch` (e.g., inside Notifier methods)

### 3. Auto Dispose & State Disposal

- By default (with code generation), provider state is destroyed when no longer listened to
- Opt out with `keepAlive: true` or `ref.keepAlive()`
- Always enable automatic disposal for providers with parameters (prevent memory leaks)
- Use `ref.onDispose` to register cleanup logic
- Use `ref.invalidate` to manually force destruction of provider state

### 4. Eager Initialization

- Providers are initialized lazily by default
- To eagerly initialize, explicitly read or watch it at the root of your application
- Place eager initialization in a public widget (e.g., `MyApp`) rather than `main()`

### 5. First Provider & Network Requests

- Always wrap your app with `ProviderScope` at the root
- Place business logic (network requests) inside providers
- Providers are lazy—logic only executes when first read
- Define provider variables as `final` and at top level (global scope)
- Use `Consumer` or `ConsumerWidget` to access providers via `ref`
- Handle loading and error states using `AsyncValue` API

### 6. Passing Arguments to Providers

- Use provider "families" to pass arguments (add `.family` after provider type)
- With code generation, add parameters directly to annotated function
- Always enable `autoDispose` for providers with parameters
- Equality (`==`) of parameters determines caching

```dart
// With code generation
@riverpod
Future<User> user(UserRef ref, String userId) async {
  return await ref.appApiService.getUser(userId);
}

// Usage
final user = ref.watch(userProvider('123'));
```

### 7. Provider Observers (Logging & Error Reporting)

- Use `ProviderObserver` to listen to all events in provider tree
- Extend `ProviderObserver` class and override methods:
  - `didAddProvider`: called when provider is added
  - `didUpdateProvider`: called when provider is updated
  - `didDisposeProvider`: called when provider is disposed
  - `providerDidFail`: called when synchronous provider throws error
- Register observers in `ProviderScope` or `ProviderContainer`

### 8. Performing Side Effects

- Use Notifiers to expose methods for side effects (POST, PUT, DELETE)
- Define provider variables as `final` and at top level
- Expose public methods on Notifiers for UI to trigger state changes
- In UI event handlers, use `ref.read` to call Notifier methods
- After side effect, update UI state by:
  - Setting new state directly if server returns updated data
  - Calling `ref.invalidateSelf()` to refresh provider
  - Manually updating local cache

### 9. Testing Providers

- Always create new `ProviderContainer` (unit tests) or `ProviderScope` (widget tests) for each test
- Never share `ProviderContainer` instances between tests
- Use `overrides` parameter to inject mocks or fakes
- Prefer mocking dependencies (repositories) rather than Notifiers directly

## Basic Implementation Flow

### Creating a New Page

#### Step 1: Define the State

```dart
// lib/ui/page/feature/view_model/feature_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared/index.dart';

part 'feature_state.freezed.dart';

@freezed
class FeatureState extends BaseState with _$FeatureState {
  const factory FeatureState({
    @Default([]) List<DataModel> items,
    @Default('') String searchQuery,
    DataModel? selectedItem,
  }) = _FeatureState;
}
```

#### Step 2: Create the ViewModel

```dart
// lib/ui/page/feature/view_model/feature_view_model.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/index.dart';

import '../../../../index.dart';

final featureViewModelProvider = 
    StateNotifierProvider.autoDispose<FeatureViewModel, CommonState<FeatureState>>(
  (ref) => FeatureViewModel(ref),
);

class FeatureViewModel extends BaseViewModel<FeatureState> {
  FeatureViewModel(this._ref) : super(CommonState(data: FeatureState()));

  final Ref _ref;

  Future<void> loadData() async {
    await runCatching(
      action: () async {
        final apiService = _ref.read(appApiServiceProvider);
        final result = await apiService.getFeatureData();
        data = data.copyWith(items: result);
      },
    );
  }

  void updateSearchQuery(String query) {
    data = data.copyWith(searchQuery: query);
  }

  Future<void> selectItem(DataModel item) async {
    await runCatching(
      action: () async {
        data = data.copyWith(selectedItem: item);
        // Additional logic
      },
    );
  }
}
```

#### Step 3: Create the Page

```dart
// lib/ui/page/feature/feature_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/index.dart';

import '../../../index.dart';

class FeaturePage extends BasePage<FeatureState, 
    StateNotifierProvider<FeatureViewModel, CommonState<FeatureState>>> {
  const FeaturePage({super.key});

  @override
  StateNotifierProvider<FeatureViewModel, CommonState<FeatureState>> 
      get provider => featureViewModelProvider;

  @override
  ScreenViewEvent get screenViewEvent => ScreenViewEvent(
    screenName: AppScreenName.feature,
  );

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);

    return CommonScaffold(
      appBar: CommonAppBar.back(text: l10n.featureTitle),
      body: state.data.items.isEmpty
          ? const EmptyStateWidget()
          : ListView.builder(
              itemCount: state.data.items.length,
              itemBuilder: (context, index) {
                final item = state.data.items[index];
                return FeatureItemCard(
                  item: item,
                  onTap: () => ref.read(provider.notifier).selectItem(item),
                );
              },
            ),
    );
  }
}
```

## Summary Rules

1. **Wrap app with ProviderScope** at root
2. **Use `ref.watch`** for reactive listening
3. **Use `ref.read`** for one-time access (not in build)
4. **Use `ref.listen`** for side effects only
5. **Providers are top-level final variables**
6. **All ViewModel providers use autoDispose**
7. **Use `.family` for providers with parameters**
8. **Always enable autoDispose for parameterized providers**
9. **Create new ProviderContainer for each test**
10. **Use overrides to inject mocks in tests**

## Key Files Reference

- [base_view_model.dart](../../lib/ui/base/base_view_model.dart) - BaseViewModel implementation
- [base_page.dart](../../lib/ui/base/base_page.dart) - BasePage implementation
- [common_state.dart](../../lib/ui/base/common_state.dart) - CommonState implementation
