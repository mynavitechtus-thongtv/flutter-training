// ignore_for_file: missing_golden_test
import 'package:flutter/material.dart';

import '../../../index.dart';

class CommonScaffold extends StatelessWidget {
  const CommonScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.hideKeyboardWhenTouchOutside = true,
    this.shimmerEnabled = false,
    this.showBanner = true,
    this.useSafeArea = true,
    this.enabledEdgeToEdge = false,
    this.scaffoldKey,
    this.isLoading,
    this.preventActionWhenLoading = true,
  });

  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool hideKeyboardWhenTouchOutside;
  final bool shimmerEnabled;
  final bool showBanner;
  final Key? scaffoldKey;
  final bool useSafeArea;
  final bool enabledEdgeToEdge;
  final bool? isLoading;
  final bool preventActionWhenLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveIsLoading = isLoading ?? LoadingStateProvider.isLoadingOf(context);
// ignore: prefer_common_widgets
    final scaffold = Scaffold(
      key: scaffoldKey,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor ?? Colors.white,
      body: IgnorePointer(
        ignoring: preventActionWhenLoading && effectiveIsLoading,
        child: SafeArea(
          top: enabledEdgeToEdge ? false : useSafeArea,
          bottom: enabledEdgeToEdge ? false : useSafeArea,
          left: enabledEdgeToEdge ? false : useSafeArea,
          right: enabledEdgeToEdge ? false : useSafeArea,
          child: shimmerEnabled ? Shimmer(child: body) : body ?? const SizedBox.shrink(),
        ),
      ),
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );

    final scaffoldWithBanner = Env.flavor == Flavor.production ||
            Env.flavor == Flavor.test ||
            Env.flavor == Flavor.staging ||
            !showBanner
        ? scaffold
        : Banner(
            location: BannerLocation.topStart,
            message: Env.flavor.name,
            // ignore: avoid_hard_coded_colors
            color: Colors.green.withValues(alpha: 0.6),
            // ignore: avoid_using_text_style_constructor_directly
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
            textDirection: TextDirection.ltr,
            child: scaffold,
          );

    return hideKeyboardWhenTouchOutside
        ? GestureDetector(
            onTap: () => ViewUtil.hideKeyboard(context),
            child: scaffoldWithBanner,
          )
        : scaffoldWithBanner;
  }
}
