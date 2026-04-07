# Page Instructions

## Overview

This document provides guidelines for implementing pages in the project.

## Common Rules

Follow the instructions in [common_ui_coding_instructions.md](common_ui_coding_instructions.md)

## Page-Specific Rules

### 1. Use CommonScaffold

All pages must use `CommonScaffold` as the root widget.

```dart
@override
Widget buildPage(BuildContext context, WidgetRef ref) {
  return CommonScaffold(
    appBar: CommonAppBar.back(text: t.page.pageTitle),
    body: YourContent(),
  );
}
```

### 2. Scrollable Content

For detail pages, edit pages, or confirmation pages with long content, wrap with `SingleChildScrollView`.

```dart
CommonScaffold(
  appBar: CommonAppBar.back(text: t.profile.editProfile),
  body: SingleChildScrollView(
    child: Column(
      children: [
        // Long form content
      ],
    ),
  ),
)
```

### 3. Scrollbar for Scrollable Widgets

If the UI has scrollable widgets, wrap with `CommonScrollbarWithIosStatusBarTapDetector` with the `routeName` parameter set to the route name of the page like `LoginRoute.name` and the `controller` parameter set to the scroll controller that is passed to both the `CommonScrollbarWithIosStatusBarTapDetector` and the scrollable widget.

**Scrollable widgets requiring scrollbar:**
- `SingleChildScrollView`
- `ListView`
- `GridView`
- `NestedScrollView`
- `CustomScrollView`
- `CommonPagedGridView`
- `CommonPagedListView`

```dart
CommonScaffold(
  body: CommonScrollbarWithIosStatusBarTapDetector(
    routeName: LoginRoute.name,
    controller: scrollController,
    child: ListView.builder(
      controller: scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) => ItemCard(items[index]),
    ),
  ),
)
```

### 4. Do Not Code Status Bar UI

Do not manually implement status bar UI.
