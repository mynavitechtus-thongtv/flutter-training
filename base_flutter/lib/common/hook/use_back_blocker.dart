import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../index.dart';

/// Result of [useBackBlocker] hook.
///
/// - [isAllowed]: `true` when back/pop is allowed, `false` when blocked.
/// - [handleNavigation]: Call to allow and perform navigation (pop or custom action).
typedef BackBlockerResult = ({
  bool isAllowed,
  void Function(VoidCallback? action) handleNavigation,
});

/// Hook to intercept and control back button / system back gesture.
///
/// Use when you need to show a confirmation (e.g. "Leave without saving?") before
/// allowing the user to pop the current route.
///
/// ## Typical flow
///
/// 1. Wrap the page with [PopScope] and set `canPop: !isAllowed`.
/// 2. When user presses back, pop is blocked and [PopScope.onPopInvokedWithResult]
///    is called with `didPop: false`.
/// 3. Show a confirm dialog in the callback.
/// 4. If user confirms, call [handleNavigation] (or [handleNavigation](customAction)).
/// 5. The hook sets [isAllowed] to true and schedules `nav.pop()` (or the custom
///    action) for the next frame.
///
/// ## Usage example
///
/// ```dart
/// class MyPage extends HookConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final nav = ref.read(appNavigatorProvider);
///     final backBlocker = useBackBlocker(nav);
///
///     return PopScope(
///       canPop: backBlocker.isAllowed,
///       onPopInvokedWithResult: (didPop, result) async {
///         if (didPop) return;
///         final confirmed = await showConfirmDialog(
///           context: context,
///           message: 'Leave without saving?',
///         );
///         if (confirmed) {
///           backBlocker.handleNavigation(null);
///         }
///       },
///       child: Scaffold(...),
///     );
///   }
/// }
/// ```
///
/// ## Custom action
///
/// To run custom logic instead of [AppNavigator.pop]:
///
/// ```dart
/// backBlocker.handleNavigation(() {
///   // Custom logic before leaving
///   nav.popAndPush(SomeRoute());
/// });
/// ```
///
/// [nav] is used for default pop when [handleNavigation] is called with `null`.
BackBlockerResult useBackBlocker(AppNavigator nav) {
  final isAllowedToPop = useState(false);

  void handleNavigation(VoidCallback? action) {
    isAllowedToPop.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (action != null) {
        action();
      } else {
        nav.pop();
      }
    });
  }

  return (isAllowed: isAllowedToPop.value, handleNavigation: handleNavigation);
}
