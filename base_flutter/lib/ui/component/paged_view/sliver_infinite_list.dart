// ignore_for_file: missing_golden_test
import 'package:flutter/widgets.dart';

import '../../../index.dart';

/// The sliver version of [InfiniteList].
///
/// {@macro infinite_list}
///
/// As a infinite list, it is supposed to be the last sliver in the current
/// [ScrollView]. Otherwise, re-fetching data will have an unintuitive behavior.
class SliverInfiniteList extends StatefulWidget {
  /// Constructs a [SliverInfiniteList].
  const SliverInfiniteList({
    required this.itemCount,
    required this.onFetchData,
    required this.itemBuilder,
    super.key,
    this.debounceDuration = defaultDebounceDuration,
    this.isLoading = false,
    this.hasError = false,
    this.hasReachedMax = false,
    this.centerLoading = false,
    this.centerError = false,
    this.centerEmpty = false,
    this.loadingBuilder,
    this.errorBuilder,
    this.error,
    this.separatorBuilder,
    this.emptyBuilder,
    this.findChildIndexCallback,
  });

  /// {@macro debounce_duration}
  final Duration debounceDuration;

  /// {@macro item_count}
  final int itemCount;

  /// {@macro is_loading}
  final bool isLoading;

  /// {@macro has_error}
  final bool hasError;

  /// {@macro has_reached_max}
  final bool hasReachedMax;

  /// {@macro on_fetch_data}
  final VoidCallback onFetchData;

  /// {@macro empty_builder}
  final WidgetBuilder? emptyBuilder;

  /// {@macro loading_builder}
  final WidgetBuilder? loadingBuilder;

  /// {@macro error_builder}
  final InfiniteListErrorBuilder? errorBuilder;

  /// Optional [AppException] passed to [errorBuilder] when [hasError] is true.
  final AppException? error;

  /// {@macro separator_builder}
  final IndexedWidgetBuilder? separatorBuilder;

  /// {@macro item_builder}
  final ItemBuilder itemBuilder;

  /// {@macro center_loading}
  final bool centerLoading;

  /// {@macro center_error}
  final bool centerError;

  /// {@macro center_empty}
  final bool centerEmpty;

  /// {@macro find_child_index_callback}
  final int? Function(Key)? findChildIndexCallback;

  @override
  State<SliverInfiniteList> createState() => _SliverInfiniteListState();
}

class _SliverInfiniteListState extends State<SliverInfiniteList> {
  late final CallbackDebouncer debounce;

  int? _lastFetchedIndex;

  @override
  void initState() {
    super.initState();
    debounce = CallbackDebouncer(widget.debounceDuration);
    attemptFetch();
  }

  @override
  void didUpdateWidget(SliverInfiniteList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.hasReachedMax && oldWidget.hasReachedMax) {
      attemptFetch();
    }
  }

  @override
  void dispose() {
    super.dispose();
    debounce.dispose();
  }

  void attemptFetch() {
    if (!widget.hasReachedMax && !widget.isLoading && !widget.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debounce(widget.onFetchData);
      });
    }
  }

  void onBuiltLast(int lastItemIndex) {
    if (_lastFetchedIndex != lastItemIndex) {
      _lastFetchedIndex = lastItemIndex;
      attemptFetch();
    }
  }

  WidgetBuilder get loadingBuilder => widget.loadingBuilder ?? defaultInfiniteListLoadingBuilder;

  Widget buildErrorWidget(BuildContext context) {
    final builder = widget.errorBuilder ?? defaultInfiniteListErrorBuilder;
    return builder(context, widget.error);
  }

  WidgetBuilder get emptyBuilder => widget.emptyBuilder ?? defaultInfiniteListEmptyBuilder;

  @override
  Widget build(BuildContext context) {
    final hasItems = widget.itemCount != 0;

    final showEmpty = !widget.isLoading && widget.itemCount == 0;
    final showBottomWidget = showEmpty || widget.isLoading || widget.hasError;
    final showSeparator = widget.separatorBuilder != null;
    final separatorCount = !showSeparator ? 0 : widget.itemCount - 1;

    final effectiveItemCount =
        (!hasItems ? 0 : widget.itemCount + separatorCount) + (showBottomWidget ? 1 : 0);
    final lastItemIndex = effectiveItemCount - 1;

    Widget? centeredSliver;

    if (widget.centerLoading && widget.isLoading && effectiveItemCount == 1) {
      centeredSliver = SliverCentralized(child: loadingBuilder(context));
    } else if (widget.centerError && widget.hasError) {
      centeredSliver = SliverCentralized(child: buildErrorWidget(context));
    } else if (widget.centerEmpty && showEmpty) {
      centeredSliver = SliverCentralized(child: emptyBuilder(context));
    }

    if (centeredSliver != null) return centeredSliver;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: effectiveItemCount,
        findChildIndexCallback: widget.findChildIndexCallback,
        (context, index) {
          if (index == lastItemIndex) {
            onBuiltLast(lastItemIndex);
          }
          if (index == lastItemIndex && showBottomWidget) {
            if (widget.hasError) {
              return buildErrorWidget(context);
            } else if (widget.isLoading) {
              return loadingBuilder(context);
            } else {
              return emptyBuilder(context);
            }
          } else {
            final itemIndex = !showSeparator ? index : (index / 2).floor();
            if (showSeparator && index.isOdd) {
              return widget.separatorBuilder!(context, itemIndex);
            } else {
              return widget.itemBuilder(context, itemIndex);
            }
          }
        },
      ),
    );
  }
}
