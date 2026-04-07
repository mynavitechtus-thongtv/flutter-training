import 'package:flutter/material.dart';

class LoadingStateProvider extends InheritedWidget {
  const LoadingStateProvider({
    required this.isLoading,
    required super.child,
    super.key,
  });

  final bool isLoading;

  static LoadingStateProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LoadingStateProvider>();
  }

  static bool isLoadingOf(BuildContext context) {
    return maybeOf(context)?.isLoading ?? false;
  }

  @override
  bool updateShouldNotify(LoadingStateProvider oldWidget) {
    return isLoading != oldWidget.isLoading;
  }
}
