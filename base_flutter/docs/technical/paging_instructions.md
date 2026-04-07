# Paging Instructions

## Overview

Paging (pagination) loads API data in pages, reducing network load and improving performance when displaying large lists.

## Architecture

Paging implementation consists of three layers:

```
┌─────────────────────────────────────────┐
│              UI Layer                    │
│  (Page, State, ViewModel)                │
│  - CommonPagingController                │
│  - CommonPagedListView/GridView          │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│        PagingExecutor Layer              │
│  - PagingExecutor                        │
│  - PagingParams                          │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│            API Layer                     │
│  - AppApiService                         │
│  - PagingDataResponse                    │
└─────────────────────────────────────────┘
```

## 1. API Layer

### API Method Requirements

When spec requires paging, API method MUST have:

1. **Parameters**: `page` and `limit`
2. **Return type**: `PagingDataResponse<T>`
3. **successResponseDecoderType**: `SuccessResponseDecoderType.paging`

### Structure

```dart
// lib/data_source/api/app_api_service.dart

Future<PagingDataResponse<ApiUserData>?> getUsers({
  required int page,
  required int? limit,
}) {
  return _randomUserApiClient.request(
    method: RestMethod.get,
    path: '/users',
    queryParameters: {
      'page': page,
      'results': limit, // or 'limit' depending on API backend
    },
    successResponseDecoderType: SuccessResponseDecoderType.paging,
    decoder: (json) => ApiUserData.fromJson(
      json.safeCast<Map<String, dynamic>>() ?? {},
    ),
  );
}
```

### With Filters

```dart
// API: GET /api/jobs?page=1&limit=20&category=tech&location=tokyo
Future<PagingDataResponse<ApiJobData>?> getJobs({
  required int page,
  required int? limit,
  String? category,
  String? location,
}) {
  return _apiClient.request(
    method: RestMethod.get,
    path: '/jobs',
    queryParameters: {
      'page': page,
      'limit': limit,
      if (category != null) 'category': category,
      if (location != null) 'location': location,
    },
    successResponseDecoderType: SuccessResponseDecoderType.paging,
    decoder: (json) => ApiJobData.fromJson(
      json.safeCast<Map<String, dynamic>>() ?? {},
    ),
  );
}
```

## 2. PagingExecutor Layer

### File Location

```
lib/data_source/api/paging/
├── base/
│   └── load_more_executor.dart               # Base class (don't modify)
├── get_users_paging_executor.dart            # Example (method specific)
└── {method_name}_paging_executor.dart        # One executor per API method
```

### Structure

Each paging feature needs two classes inside `{method_name}_paging_executor.dart`:

1. **`{MethodName}PagingParams`** – Extends `PagingParams`, holds filter/sort params.
2. **`{MethodName}PagingExecutor`** – Extends `PagingExecutor<T, Params>`, calls the API.

### Template

```dart
// lib/data_source/api/paging/get_companies_paging_executor.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../../../index.dart';

final getCompaniesPagingExecutorProvider = Provider<GetCompaniesPagingExecutor>(
  (ref) => getIt.get<GetCompaniesPagingExecutor>(),
);

class GetCompaniesPagingParams extends PagingParams {
  GetCompaniesPagingParams({
    this.q,
    this.status,
    this.sort,
    this.order,
  });

  final String? q;
  final String? status;
  final String? sort;
  final String? order;
}

@Injectable()
class GetCompaniesPagingExecutor
    extends PagingExecutor<Company, GetCompaniesPagingParams> {
  GetCompaniesPagingExecutor(this.appApiService);

  final AppApiService appApiService;

  @protected
  @override
  Future<PagedList<Company>> action({
    required int page,
    required int limit,
    required GetCompaniesPagingParams? params,
  }) async {
    final response = await appApiService.getCompanies(
      page: page,
      perPage: limit,
      q: params?.q,
      status: params?.status,
      sort: params?.sort,
      order: params?.order,
    );

    return PagedList(
      data: response?.results ?? const <Company>[],
      next: response?.next,
      total: response?.total,
    );
  }
}
```

### Example: Simple Executor (No Params)

```dart
final getUsersPagingExecutorProvider = Provider<GetUsersPagingExecutor>(
  (ref) => getIt.get<GetUsersPagingExecutor>(),
);

class GetUsersPagingParams extends PagingParams {
  GetUsersPagingParams();
}

@Injectable()
class GetUsersPagingExecutor extends PagingExecutor<UserResource, GetUsersPagingParams> {
  GetUsersPagingExecutor(this.appApiService);

  final AppApiService appApiService;

  @protected
  @override
  Future<PagedList<UserResource>> action({
    required int page,
    required int limit,
    required GetUsersPagingParams? params,
  }) async {
    final response = await appApiService.getUsers(page: page, perPage: limit);

    return PagedList(data: response?.results ?? const <UserResource>[], next: response?.next);
  }
}
```

## 3. UI Layer

The UI Layer consists of three files: State, ViewModel, and Page.

### 3.1. State

File location: `lib/ui/page/{page_name}/view_model/{page_name}_state.dart`

#### Variant 1: Default (CommonProgressIndicator)

**When to use:** Spec does not require shimmer loading.

```dart
@freezed
sealed class {PageName}State extends BaseState with _${PageName}State {
  const {PageName}State._();

  factory {PageName}State({
    // LoadMoreOutput for paging data
    @Default(LoadMoreOutput<Api{Entity}Data>(data: <Api{Entity}Data>[]))
        LoadMoreOutput<Api{Entity}Data> {entities},
    
    // Exception state for load more errors
    AppException? load{Entity}sException,
    
    // NO isShimmerLoading property
    
    // Other state properties...
  }) = _{PageName}State;
}
```

#### Variant 2: Shimmer Loading

**When to use:** Spec explicitly requires shimmer loading effect.

```dart
@freezed
sealed class {PageName}State extends BaseState with _${PageName}State {
  const {PageName}State._();

  factory {PageName}State({
    // LoadMoreOutput for paging data
    @Default(LoadMoreOutput<Api{Entity}Data>(data: <Api{Entity}Data>[]))
        LoadMoreOutput<Api{Entity}Data> {entities},
    
    // Shimmer loading state for first load (ONLY when spec requires)
    @Default(false) bool isShimmerLoading,
    
    // Exception state for load more errors
    AppException? load{Entity}sException,
    
    // Other state properties...
  }) = _{PageName}State;
}
```

### 3.2. ViewModel

File location: `lib/ui/page/{page_name}/view_model/{page_name}_view_model.dart`

#### Variant 1: Default (CommonProgressIndicator)

```dart
final {pageName}ViewModelProvider =
    StateNotifierProvider.autoDispose<{PageName}ViewModel, CommonState<{PageName}State>>(
  (ref) => {PageName}ViewModel(ref),
);

class {PageName}ViewModel extends BaseViewModel<{PageName}State> {
  {PageName}ViewModel(
    this._ref,
  ) : super(CommonState(data: {PageName}State()));

  final Ref _ref;

  // Public fetch method (called from Page)
  Future<void> fetch{Entity}s({
    required bool isInitialLoad,
    // Add params if needed
    String? category,
    SortBy? sortBy,
  }) {
    return _get{Entity}s(
      isInitialLoad: isInitialLoad,
      category: category,
      sortBy: sortBy,
    );
  }

  // Private implementation with runCatching
  Future<void> _get{Entity}s({
    required bool isInitialLoad,
    String? category,
    SortBy? sortBy,
  }) async {
    return runCatching(
      action: () async {
        // Clear error state (NO isShimmerLoading)
        data = data.copyWith(load{Entity}sException: null);

        // Execute load more
        final output = await _ref.read(get{Entity}sPagingExecutorProvider).execute(
          isInitialLoad: isInitialLoad,
          params: Get{Entity}sPagingParams(
            category: category,
            sortBy: sortBy,
          ),
        );

        // Update state with data
        data = data.copyWith({entities}: output);
      },
      doOnError: (e) async {
        // Set error state
        data = data.copyWith(load{Entity}sException: e);
      },
      // NO doOnSuccessOrError (no shimmer to clear)
      handleLoading: false, // Don't show global loading
      handleErrorWhen: (_) => false, // Handle error manually
    );
  }
}
```

#### Variant 2: Shimmer Loading

```dart
Future<void> _get{Entity}s({
  required bool isInitialLoad,
  String? category,
  SortBy? sortBy,
}) async {
  return runCatching(
    action: () async {
      // Set loading state (WITH isShimmerLoading)
      data = data.copyWith(
        isShimmerLoading: isInitialLoad,
        load{Entity}sException: null,
      );

      // Execute load more
      final output = await _ref.read(get{Entity}sPagingExecutorProvider).execute(
        isInitialLoad: isInitialLoad,
        params: Get{Entity}sPagingParams(
          category: category,
          sortBy: sortBy,
        ),
      );

      // Update state with data
      data = data.copyWith({entities}: output);
    },
    doOnError: (e) async {
      // Set error state
      data = data.copyWith(load{Entity}sException: e);
    },
    doOnSuccessOrError: () async {
      // Clear shimmer loading
      data = data.copyWith(isShimmerLoading: false);
    },
    handleLoading: false, // Don't show global loading
    handleErrorWhen: (_) => false, // Handle error manually
  );
}
```

**Key Points:**
- Public `fetch{Entity}s()` method called from Page
- Private `_get{Entity}s()` with `runCatching`
- `handleLoading: false` - Don't show global loading
- `handleErrorWhen: (_) => false` - Manual error handling
- `load{Entity}sException` for error state
- (Shimmer only) `isShimmerLoading` for first load
- (Shimmer only) `doOnSuccessOrError` to clear shimmer

### 3.3. Page

File location: `lib/ui/page/{page_name}/{page_name}_page.dart`

**IMPORTANT:**
1. **Check design/spec** to choose widget: `CommonPagedListView`, `CommonPagedGridView`, `CommonPagedSliverList`, or `CommonPagedSliverGrid`
2. **Check spec** to determine loading indicator: Default (CommonProgressIndicator) or Shimmer

#### Variant 1: Default (CommonProgressIndicator)

```dart
@RoutePage(name: '{PageName}Route')
class {PageName}Page extends BasePage<{PageName}State,
    AutoDisposeStateNotifierProvider<{PageName}ViewModel, CommonState<{PageName}State>>> {
  const {PageName}Page({super.key});

  @override
  ScreenViewEvent get screenViewEvent =>
      ScreenViewEvent(screenName: ScreenName.{pageName}Page);

  @override
  AutoDisposeStateNotifierProvider<{PageName}ViewModel, CommonState<{PageName}State>>
      get provider => {pageName}ViewModelProvider;

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    // 1. Create CommonPagingController
    final pagingController = useMemoized(() => CommonPagingController<Api{Entity}Data>(
      fetchPage: (_, isInitialLoad) async {
        await ref.read(provider.notifier).fetch{Entity}s(isInitialLoad: isInitialLoad);
        final output = ref.read(provider.select((value) => value.data.{entities})).data;
        return output;
      },
    ));

    // 2. Dispose controller on unmount
    useEffect(
      () {
        return () {
          pagingController.dispose();
        };
      },
      [],
    );

    // 3. Listen to error state and update controller
    ref.listen(
      provider.select((value) => value.data.load{Entity}sException),
      (previous, next) {
        if (previous != next && next != null) {
          pagingController.error = next;
        }
      },
    );

    return CommonScaffold(
      appBar: CommonAppBar.back(text: l10n.{pageName}),
      body: RefreshIndicator(
        onRefresh: () async => pagingController.refresh(),
        child: CommonPagedListView<Api{Entity}Data>(
          pagingController: pagingController,
          animateTransitions: false,
          itemBuilder: (context, {entity}, index) {
            return _{Entity}Item({entity}: {entity});
          },
        ),
      ),
    );
  }
}

// Item widget
class _{Entity}Item extends StatelessWidget {
  const _{Entity}Item({required this.{entity}, super.key});

  final Api{Entity}Data {entity};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.rps),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            {entity}.title,
            style: style(fontSize: 16.rps, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.rps),
          CommonText(
            {entity}.description,
            style: style(fontSize: 14.rps),
          ),
        ],
      ),
    );
  }
}
```

**Key Components:**
1. `CommonPagingController` - Paging logic
2. `useEffect` - Dispose controller
3. `ref.listen` - Listen error state
4. `RefreshIndicator` - Pull-to-refresh
5. `CommonPagedListView` - Default progress indicators (no shimmer)

#### Variant 2: Shimmer Loading

```dart
@override
Widget buildPage(BuildContext context, WidgetRef ref) {
  // 1. Create CommonPagingController
  final pagingController = useMemoized(() => CommonPagingController<Api{Entity}Data>(
    fetchPage: (_, isInitialLoad) async {
      await ref.read(provider.notifier).fetch{Entity}s(isInitialLoad: isInitialLoad);
      final output = ref.read(provider.select((value) => value.data.{entities})).data;
      return output;
    },
  ));

  // 2. Dispose controller on unmount
  useEffect(
    () {
      return () {
        pagingController.dispose();
      };
    },
    [],
  );

  // 3. Listen to error state and update controller
  ref.listen(
    provider.select((value) => value.data.load{Entity}sException),
    (previous, next) {
      if (previous != next && next != null) {
        pagingController.error = next;
      }
    },
  );

  return CommonScaffold(
    shimmerEnabled: true,
    appBar: CommonAppBar.back(text: l10n.{pageName}),
    body: Consumer(
      builder: (context, ref, child) {
        final {entities} = ref.watch(provider.select((value) => value.data.{entities}));
        final isShimmerLoading = ref.watch(
          provider.select((value) => value.data.isShimmerLoading),
        );

        return RefreshIndicator(
          onRefresh: () async => pagingController.refresh(),
          child: isShimmerLoading && {entities}.data.isEmpty
              ? const _ListViewLoader() // Full-screen shimmer
              : CommonPagedListView<Api{Entity}Data>(
                  pagingController: pagingController,
                  animateTransitions: false,
                  itemBuilder: (context, {entity}, index) {
                    return ShimmerLoading(
                      isLoading: isShimmerLoading,
                      loadingWidget: const _LoadingItem(),
                      child: _{Entity}Item({entity}: {entity}),
                    );
                  },
                ),
        );
      },
    ),
  );
}

// Loading item widget for shimmer
class _LoadingItem extends StatelessWidget {
  const _LoadingItem();

  @override
  Widget build(BuildContext context) {
    return RoundedRectangleShimmer(
      width: double.infinity,
      height: 80.rps,
    );
  }
}

// Shimmer loading ListView for first load
class _ListViewLoader extends StatelessWidget {
  const _ListViewLoader();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: Constant.shimmerItemCount,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.rps, vertical: 8.rps),
        child: const ShimmerLoading(
          loadingWidget: _LoadingItem(),
          isLoading: true,
          child: _LoadingItem(),
        ),
      ),
    );
  }
}
```

**Key Components:**
1. `Consumer` - Watch shimmer state
2. `isShimmerLoading` - Shimmer loading state
3. `_ListViewLoader` - Full-screen shimmer for first load
4. `ShimmerLoading` - Per-item shimmer during refresh
5. `_LoadingItem` - Shimmer loading widget

## Widget Selection

Choose widget type based on design:

### Available Widgets

| Widget | Use Case | Example |
|--------|----------|---------|
| `CommonPagedListView` | Vertical/horizontal list | User list, notification list |
| `CommonPagedGridView` | Grid layout | Product grid, image gallery |
| `CommonPagedSliverList` | List in `CustomScrollView` | Complex scroll with multiple sections |
| `CommonPagedSliverGrid` | Grid in `CustomScrollView` | Complex scroll with multiple sections |

### Decision Tree

```
Has CustomScrollView/Sliver widgets?
├─ Yes → Sliver variant
│  ├─ List layout? → CommonPagedSliverList
│  └─ Grid layout? → CommonPagedSliverGrid
│
└─ No → Normal variant
   ├─ List layout? → CommonPagedListView
   └─ Grid layout? → CommonPagedGridView
```

### Examples

#### Simple Vertical List

```dart
CommonPagedListView<ApiUserData>(
  pagingController: pagingController,
  animateTransitions: false,
  itemBuilder: (context, user, index) {
    return UserCard(user: user);
  },
);
```

#### Grid Layout

```dart
CommonPagedGridView<ApiProductData>(
  pagingController: pagingController,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.7,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  ),
  itemBuilder: (context, product, index) {
    return ProductCard(product: product);
  },
);
```

#### Sliver List (Complex Scroll)

```dart
CustomScrollView(
  slivers: [
    SliverAppBar(title: Text('Products')),
    
    // Header section
    SliverToBoxAdapter(
      child: HeaderWidget(),
    ),
    
    // Paged list section
    CommonPagedSliverList<ApiProductData>(
      pagingController: pagingController,
      itemBuilder: (context, product, index) {
        return ProductCard(product: product);
      },
    ),
  ],
);
```

## Loading Indicators

### Type 1: CommonProgressIndicator (Default)

**When to use:** Default; if spec does not require shimmer loading effect.

**Behavior:**
- First load: `CommonFirstPageProgressIndicator` (circular loading)
- Load more: `CommonNewPageProgressIndicator` (circular loading at bottom)
- No shimmer effect

### Type 2: Shimmer Loading

**When to use:** Only when spec explicitly requires shimmer loading effect.

**Behavior:**
- First load: `_ListViewLoader` (full-screen shimmer)
- Refresh: `ShimmerLoading` per item
- Load more: Default progress indicator at bottom

### Comparison Table

| Aspect | CommonProgressIndicator | Shimmer Loading |
|--------|------------------------|-----------------|
| **When to use** | Default, no requirement | When spec requires |
| **State property** | No `isShimmerLoading` | Need `isShimmerLoading` |
| **ViewModel logic** | No shimmer handling | Handle shimmer state |
| **Page complexity** | Simple (no Consumer) | Complex (Consumer + conditional) |
| **Widgets needed** | No extra widgets | Need `_LoadingItem`, `_ListViewLoader` |
| **First load** | Circular indicator | Shimmer effect |
| **Refresh** | Circular indicator | Shimmer per item |
| **Load more** | Circular indicator | Circular indicator |

### Decision Flow

```
Check spec.md or design
│
├─ "Show shimmer loading effect"?
│  ├─ Yes → Use Shimmer Loading
│  │  └─ Add isShimmerLoading, _LoadingItem, _ListViewLoader
│  │
│  └─ No → Use CommonProgressIndicator (Default)
│     └─ Simple implementation, no extra code
```

## Best Practices

### 1. Error Handling

```dart
// ViewModel
Future<void> _getUsers({ }) async {
  return runCatching(
    action: () async { },
    doOnError: (e) async {
      // Set error state for pagingController
      data = data.copyWith(loadUsersException: e);
    },
    handleLoading: false, // IMPORTANT: Don't show global loading
    handleErrorWhen: (_) => false, // IMPORTANT: Handle error manually
  );
}

// Page
ref.listen(
  provider.select((value) => value.data.loadUsersException),
  (previous, next) {
    if (previous != next && next != null) {
      pagingController.error = next; // Update controller error
    }
  },
);
```

### 2. Loading Indicator Selection

**Rule:** Check spec.md first to determine loading indicator type.

```dart
// GOOD - Default: CommonProgressIndicator (simple)
// When spec DOESN'T require shimmer
factory MyListState({
  @Default(LoadMoreOutput<ApiItemData>(data: <ApiItemData>[])) LoadMoreOutput<ApiItemData> items,
  AppException? loadItemsException,
  // NO isShimmerLoading
}) = _MyListState;

// GOOD - Shimmer Loading (complex)
// When spec EXPLICITLY requires shimmer
factory MyListState({
  @Default(LoadMoreOutput<ApiItemData>(data: <ApiItemData>[])) LoadMoreOutput<ApiItemData> items,
  @Default(false) bool isShimmerLoading, // Add this
  AppException? loadItemsException,
}) = _MyListState;
```

### 3. Filter Implementation

```dart
// State - Store current filters
factory JobListState({
  @Default(LoadMoreOutput<ApiJobData>(data: <ApiJobData>[])) LoadMoreOutput<ApiJobData> jobs,
  String? selectedCategory, // Current filter
  JobSortBy? selectedSortBy, // Current sort
}) = _JobListState;

// ViewModel - Apply filters when fetching
Future<void> fetchJobs({
  required bool isInitialLoad,
  String? category,
  JobSortBy? sortBy,
}) async {
  // Save filters to state
  data = data.copyWith(
    selectedCategory: category,
    selectedSortBy: sortBy,
  );
  
  await _getJobs(
    isInitialLoad: isInitialLoad,
    category: category,
    sortBy: sortBy,
  );
}

// Page - Refresh when filters change
void onCategoryChanged(String? category) {
  ref.read(provider.notifier).fetchJobs(
    isInitialLoad: true, // Reset to page 1
    category: category,
    sortBy: state.selectedSortBy,
  );
  pagingController.refresh();
}
```

### 4. Dispose Pattern

```dart
// Page - ALWAYS dispose pagingController
useEffect(
  () {
    return () {
      pagingController.dispose();
    };
  },
  [],
);
```

### 5. Pull-to-Refresh

```dart
// Page - Wrap with RefreshIndicator
return RefreshIndicator(
  onRefresh: () async => pagingController.refresh(),
  child: CommonPagedListView<ApiUserData>( ),
);
```

## Summary Checklist

### API Layer
- [ ] API method has parameters `page` and `limit`
- [ ] Return type is `PagingDataResponse<T>`
- [ ] Set `successResponseDecoderType: SuccessResponseDecoderType.paging`
- [ ] Decoder returns correct model type

### PagingExecutor Layer
- [ ] Create `{MethodName}PagingParams` extends `PagingParams`
- [ ] Create `{MethodName}PagingExecutor` extends `PagingExecutor<T, P>`
- [ ] Implement `action()` method calling API service
- [ ] Return `PagedList` with `data`, `next`, `total`
- [ ] Add `@Injectable()` annotation
- [ ] Create provider `{methodName}PagingExecutorProvider`

### State
- [ ] Add `LoadMoreOutput<ApiEntityData> {entities}`
- [ ] Add `AppException? load{Entity}sException`
- [ ] Add `bool isShimmerLoading` (only when spec requires shimmer)
- [ ] Add filter/sort properties (if any)

### ViewModel
- [ ] Public `fetch{Entity}s()` method
- [ ] Private `_get{Entity}s()` with `runCatching`
- [ ] Set `handleLoading: false`
- [ ] Set `handleErrorWhen: (_) => false`
- [ ] Update `load{Entity}sException` in doOnError
- [ ] Update `isShimmerLoading` in action (if spec requires shimmer)
- [ ] Clear `isShimmerLoading` in doOnSuccessOrError (if spec requires shimmer)

### Page
- [ ] Check spec/design to choose widget: `CommonPagedListView`, `CommonPagedGridView`, `CommonPagedSliverList`, or `CommonPagedSliverGrid`
- [ ] Check spec to choose loading indicator: Default (CommonProgressIndicator) or Shimmer
- [ ] Create `CommonPagingController` with `useMemoized`
- [ ] `fetchPage` callback calls ViewModel
- [ ] Return data from state
- [ ] `useEffect` to dispose controller
- [ ] `ref.listen` for error state
- [ ] `RefreshIndicator` for pull-to-refresh
- [ ] (If shimmer) Conditional rendering: `_ListViewLoader` vs `CommonPagedListView`
- [ ] (If shimmer) `ShimmerLoading` for items
- [ ] (If shimmer) Create `_LoadingItem` widget
- [ ] (If shimmer) Create `_ListViewLoader` widget

## Commands

```bash
# Generate code after creating executor
make fb

# Run app to test paging
flutter run
```
