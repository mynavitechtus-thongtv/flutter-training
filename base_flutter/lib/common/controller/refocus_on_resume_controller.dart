import 'dart:async';

import 'package:flutter/material.dart';

typedef RefocusGuard = bool Function(FocusNode node);

class RefocusOnResumeController {
  static FocusNode? _lastPrimaryFocusBeforePause;

  bool _shouldRefocusOnResume = false;

  void handleGoingBackground(FocusNode node) {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (node.hasFocus && currentFocus == node) {
      _shouldRefocusOnResume = true;
      _lastPrimaryFocusBeforePause = node;
    }
  }

  Future<void> handleResumed({
    required BuildContext context,
    required FocusNode node,
    RefocusGuard? extraGuard,
    Duration delay = const Duration(milliseconds: 50),
  }) async {
    if (!_shouldRefocusOnResume || node.hasFocus) return;

    if (_lastPrimaryFocusBeforePause != node) {
      _shouldRefocusOnResume = false;
      return;
    }

    await Future<void>.delayed(delay);
    if (!context.mounted || node.hasFocus) {
      _shouldRefocusOnResume = false;
      return;
    }

    final currentFocus = FocusManager.instance.primaryFocus;
    final isAnotherTextInputFocused = currentFocus != null &&
        currentFocus != node &&
        currentFocus.context?.widget is EditableText;

    _shouldRefocusOnResume = false;

    if (isAnotherTextInputFocused) return;

    if (extraGuard != null && !extraGuard(node)) return;

    node.requestFocus();
  }

  void reset() {
    _shouldRefocusOnResume = false;
  }

  void handleLifecycleStateChange({
    required AppLifecycleState state,
    required BuildContext context,
    required FocusNode node,
  }) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        handleGoingBackground(node);
        break;
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            handleResumed(
              context: context,
              node: node,
            );
          }
        });
        break;
      default:
        break;
    }
  }
}

/// Mixin to handle app lifecycle for refocus on resume.
///
/// Components using this mixin only need to override:
/// - [canManageFocus]: Whether this widget can manage focus lifecycle.
///   Usually `true` when the widget creates its own [FocusNode].
/// - [focusNode]: The [FocusNode] to refocus when app resumes.
///
/// Example:
/// ```dart
/// class _MyWidgetState extends State<MyWidget>
///     with WidgetsBindingObserver, RefocusOnResumeMixin {
///   late FocusNode _focusNode;
///
///   @override
///   bool get canManageFocus => widget.focusNode == null;
///
///   @override
///   FocusNode? get focusNode => _focusNode;
///
///   @override
///   void initState() {
///     super.initState();
///     _focusNode = widget.focusNode ?? FocusNode();
///   }
///
///   @override
///   void dispose() {
///     disposeRefocusOnResume();
///     _focusNode.dispose();
///     super.dispose();
///   }
/// }
/// ```
mixin RefocusOnResumeMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  late final RefocusOnResumeController _refocusController = RefocusOnResumeController();
  bool _isObserverAdded = false;
  bool _isSetup = false;

  bool get canManageFocus;
  FocusNode? get focusNode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupIfNeeded();
  }

  void _setupIfNeeded() {
    if (_isSetup) return;

    final node = focusNode;
    if (canManageFocus && node != null) {
      if (!_isObserverAdded) {
        WidgetsBinding.instance.addObserver(this);
        _isObserverAdded = true;
      }
      _isSetup = true;
    }
  }

  void disposeRefocusOnResume() {
    if (_isObserverAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserverAdded = false;
    }
    _refocusController.reset();
    _isSetup = false;
  }

  @override
  void dispose() {
    disposeRefocusOnResume();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!canManageFocus) {
      return;
    }

    final node = focusNode;
    if (node == null) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _refocusController.handleGoingBackground(node);
        break;
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentNode = focusNode;
          if (mounted && currentNode != null) {
            _refocusController.handleResumed(
              context: context,
              node: currentNode,
            );
          }
        });
        break;
      default:
        break;
    }
  }
}
