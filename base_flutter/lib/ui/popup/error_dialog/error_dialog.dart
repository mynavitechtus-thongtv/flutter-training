import 'package:flutter/material.dart';

import '../../../index.dart';

class ErrorDialog extends BasePopup {
  const ErrorDialog._({
    super.key,
    required super.popupId,
    required this.message,
    this.onRetryPressed,
  });

  /// Factory constructor for simple error dialog with OK button only
  factory ErrorDialog.error({
    Key? key,
    required String message,
  }) {
    return ErrorDialog._(
      key: key,
      popupId: 'ErrorDialog.error_$message'.hardcoded,
      message: message,
    );
  }

  /// Factory constructor for error dialog with Retry button
  factory ErrorDialog.errorWithRetry({
    Key? key,
    required String message,
    required VoidCallback onRetryPressed,
  }) {
    return ErrorDialog._(
      key: key,
      popupId: 'ErrorDialog.errorWithRetry_$message'.hardcoded,
      message: message,
      onRetryPressed: onRetryPressed,
    );
  }

  final String message;
  final VoidCallback? onRetryPressed;

  bool get _hasRetry => onRetryPressed != null;

  @override
  Widget buildPopup(BuildContext context) {
    return AlertDialog.adaptive(
      actions: [
        if (_hasRetry)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: CommonText(
              l10n.cancel,
              style: null,
            ),
          ),
        TextButton(
          onPressed: _hasRetry
              ? () {
                  Navigator.of(context).pop();
                  onRetryPressed?.call();
                }
              : () => Navigator.of(context).pop(),
          child: CommonText(
            _hasRetry ? l10n.retry : l10n.ok,
            style: null,
          ),
        ),
      ],
      content: CommonText(
        message,
        style: null,
      ),
    );
  }
}
