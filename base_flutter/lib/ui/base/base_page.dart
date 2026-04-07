import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../index.dart';

abstract class BasePage<ST extends BaseState, P extends ProviderListenable<CommonState<ST>>>
    extends HookConsumerWidget {
  const BasePage({super.key});

  P get provider;
  ScreenViewEvent get screenViewEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppColors.of(context);

    final loadingOverlayEntry = useState<OverlayEntry?>(null);

    ref.listen(
      provider.select((value) => value.appException),
      (previous, next) {
        if (previous != next && next != null) {
          handleException(next, ref);
        }
      },
    );

    ref.listen(provider.select((value) => value.isLoading), (previous, next) {
      if (next == true && loadingOverlayEntry.value == null) {
        _showLoadingOverlay(context: context, loadingOverlayEntry: loadingOverlayEntry);
      } else if (previous == true && next == false && loadingOverlayEntry.value != null) {
        _hideLoadingOverlay(loadingOverlayEntry);
      }
    });

    return FocusDetector(
      key: Key(screenViewEvent.fullKey),
      onVisibilityGained: () => onVisibilityChanged(ref),
      child: buildPage(context, ref),
    );
  }

  void _showLoadingOverlay({
    required BuildContext context,
    required ValueNotifier<OverlayEntry?> loadingOverlayEntry,
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          const ModalBarrier(
            dismissible: false,
            // ignore: avoid_hard_coded_colors
            color: Colors.black54,
          ),
          Center(child: buildPageLoading()),
        ],
      ),
    );
    overlay.insert(entry);
    loadingOverlayEntry.value = entry;
  }

  void _hideLoadingOverlay(ValueNotifier<OverlayEntry?> loadingOverlayEntry) {
    final entry = loadingOverlayEntry.value;
    if (entry != null) {
      entry.remove();
      loadingOverlayEntry.value = null;
    }
  }

  // ignore: prefer_named_parameters
  void onVisibilityChanged(WidgetRef ref) {
    ref.read(analyticsHelperProvider).logScreenView(screenViewEvent);
  }

  Widget buildPageLoading() => const CommonProgressIndicator();

  // ignore: prefer_named_parameters
  Widget buildPage(BuildContext context, WidgetRef ref);

  // ignore: prefer_named_parameters
  Future<void> handleException(
    AppException appException,
    WidgetRef ref,
  ) async {
    await ref.read(exceptionHandlerProvider).handleException(appException);
  }
}
