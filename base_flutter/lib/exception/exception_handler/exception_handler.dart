import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../index.dart';

final exceptionHandlerProvider = Provider<ExceptionHandler>(
  (ref) => ExceptionHandler(
    ref,
  ),
);

class ExceptionHandler {
  const ExceptionHandler(
    this._ref,
  );

  final Ref _ref;

  Future<void> handleException(AppException appException) async {
    if (appException.recordError) {
      await _ref.read(crashlyticsHelperProvider).recordError(
            exception: appException,
            stack: StackTrace.current,
            reason: appException.message,
          );
    }

    Log.e('handleException: $appException');

    switch (appException.action) {
      case AppExceptionAction.showSnackBar:
        _ref
            .read(appNavigatorProvider)
            .showSnackBar(CommonSnackBar.error(message: appException.message));
        break;
      case AppExceptionAction.showDialog:
        await _ref.read(appNavigatorProvider).showDialog(
              ErrorDialog.error(message: appException.message),
            );
        break;
      case AppExceptionAction.showDialogWithRetry:
        if (appException.onRetry != null) {
          await _ref.read(appNavigatorProvider).showDialog(
            ErrorDialog.errorWithRetry(
              message: appException.message,
              onRetryPressed: () async {
                await appException.onRetry?.call();
              },
            ),
          );
        } else {
          await _ref.read(appNavigatorProvider).showDialog(
            ErrorDialog.error(message: appException.message),
          );
        }
        break;
      case AppExceptionAction.showForceLogoutDialog:
        await _ref.read(appNavigatorProvider).showDialog(
              ErrorDialog.error(message: appException.message),
            );
        try {
          await _ref.read(sharedViewModelProvider).forceLogout();
        } catch (e) {
          Log.e('force logout error: $e');
          await _ref.read(appNavigatorProvider).replaceAll([const LoginRoute()]);
        }
        break;
      case AppExceptionAction.showNonCancelableDialog:
        await _ref.read(appNavigatorProvider).showDialog(
              ErrorDialog.error(message: appException.message),
              barrierDismissible: false,
              canPop: false,
            );
        break;
      case AppExceptionAction.showMaintenanceDialog:
        await _ref.read(appNavigatorProvider).showDialog(
              MaintenanceModeDialog(
                message: appException.message,
              ),
              barrierDismissible: false,
              canPop: false,
            );
        break;
      case AppExceptionAction.doNothing:
        break;
    }
  }
}
