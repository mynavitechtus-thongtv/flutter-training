import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../index.dart';

/// Returns a [FocusNode] and automatically re-focuses it when the app resumes
/// from background (common on iOS when swiping between apps).
///
/// Usage (inside a HookWidget/HookConsumerWidget build):
/// `final inputFocusNode = useFocusNodeRefocusOnResume(context);`
FocusNode useFocusNodeRefocusOnResume(BuildContext context) {
  final focusNode = useFocusNode();
  final controller = useRef(RefocusOnResumeController()).value;

  useOnAppLifecycleStateChange((previous, current) {
    if (context.mounted) {
      controller.handleLifecycleStateChange(
        state: current,
        context: context,
        node: focusNode,
      );
    }
  });

  return focusNode;
}
