// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';

import '../../../index.dart';

class ConfirmDialog extends BasePopup {
  const ConfirmDialog._({
    required this.message,
    this.onConfirm,
    this.onCancel,
    this.confirmButtonText,
    this.cancelButtonText,
  }) : super(popupId: 'ConfirmDialog_$message');

  final String message;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? confirmButtonText;
  final String? cancelButtonText;

  factory ConfirmDialog.deleteAccount({
    required VoidCallback doOnConfirm,
  }) {
    return ConfirmDialog._(
      message: l10n.deleteAccountConfirm,
      onConfirm: doOnConfirm,
    );
  }

  factory ConfirmDialog.logOut({
    required VoidCallback doOnConfirm,
  }) {
    return ConfirmDialog._(
      message: l10n.logoutConfirm,
      onConfirm: doOnConfirm,
    );
  }

  @override
  Widget buildPopup(BuildContext context) {
    return AlertDialog.adaptive(
      title: CommonText(
        message,
        style: style(
          color: color.black,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: CommonText(cancelButtonText ?? l10n.cancel, style: null),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          child: CommonText(confirmButtonText ?? l10n.ok, style: null),
        ),
      ],
    );
  }
}
