import 'package:flutter/material.dart';

import '../../../index.dart';

class MaintenanceModeDialog extends BasePopup {
  const MaintenanceModeDialog({
    super.key,
    required this.message,
  }) : super(popupId: 'MaintenanceModeDialog');

  final String message;

  @override
  Widget buildPopup(BuildContext context) {
    return CommonScaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: CommonImage.asset(
                path: image.imageAppIcon,
                width: 128,
                height: 128,
              ),
            ),
            const SizedBox(height: 32),
            CommonText(
              l10n.maintenanceTitle,
              style: style(
                height: 1.18,
                color: color.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            CommonText(
              message,
              style: style(
                height: 1.5,
                color: color.black,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
