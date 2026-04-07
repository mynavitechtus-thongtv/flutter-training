import 'package:flutter/material.dart';

import '../../../index.dart';

/// Snack bar component that mirrors the design system states and supports
/// configurable title/message content with dismiss handling.
class CommonSnackBar extends BasePopup {
  const CommonSnackBar._({
    super.key,
    required super.popupId,
    required this.message,
    required this.backgroundColor,
  });

  /// Creates a success snack bar using the success color palette.
  factory CommonSnackBar.success({
    Key? key,
    required String message,
  }) {
    return CommonSnackBar._(
      popupId: 'CommonSnackBar.success_$message'.hardcoded,
      key: key,
      message: message,
      backgroundColor: color.green1,
    );
  }

  factory CommonSnackBar.info({
    Key? key,
    required String message,
  }) {
    return CommonSnackBar._(
      popupId: 'CommonSnackBar.info_$message'.hardcoded,
      key: key,
      message: message,
      backgroundColor: color.grey1,
    );
  }

  /// Creates an error snack bar using the error color palette.
  factory CommonSnackBar.error({
    Key? key,
    required String message,
  }) {
    return CommonSnackBar._(
      popupId: 'CommonSnackBar.error_$message'.hardcoded,
      key: key,
      message: message,
      backgroundColor: color.red1,
    );
  }

  final String message;
  final Color backgroundColor;

  @override
  Widget buildPopup(BuildContext context) {
    return SnackBar(
      duration: Constant.snackBarDuration,
      backgroundColor: backgroundColor,
      content: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildTexts()),
              const SizedBox(width: 12),
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTexts() {
    return CommonText(
      message,
      style: style(
        color: color.white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      },
      child: CommonImage.svg(
        path: image.iconClose,
        width: 24,
        height: 24,
        foregroundColor: color.white,
      ),
    );
  }
}
