// ignore_for_file: missing_golden_test
import 'package:flutter/material.dart';

import '../../../index.dart';

/// The type definition for the [InfiniteList.itemBuilder].
typedef ItemBuilder = Widget Function(BuildContext context, int index);

/// The type definition for the [InfiniteList.errorBuilder].
typedef InfiniteListErrorBuilder = Widget Function(BuildContext context, AppException? exception);

/// Default value to [InfiniteList.loadingBuilder].
Widget defaultInfiniteListLoadingBuilder(BuildContext buildContext) {
  return const Center(
    child: Padding(
      padding: EdgeInsets.all(8),
      child: CircularProgressIndicator.adaptive(),
    ),
  );
}

/// Default value to [InfiniteList.errorBuilder].
// ignore: prefer_named_parameters
Widget defaultInfiniteListErrorBuilder(BuildContext context, AppException? exception) {
  return Center(
    child: CommonText(
      exception?.message ?? 'Error'.hardcoded,
      style: style(fontSize: 14, color: color.red1),
    ),
  );
}

/// Default value to [InfiniteList.emptyBuilder].
Widget defaultInfiniteListEmptyBuilder(BuildContext buildContext) {
  return Center(
    child: CommonText(
      'No data found'.hardcoded,
      style: style(fontSize: 14, color: color.grey1),
    ),
  );
}

/// Default value to [InfiniteList.debounceDuration].
const defaultDebounceDuration = Duration(milliseconds: 100);
