import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:nalsflutter/index.dart';

import '../../../../common/index.dart';

void main() {
  group(
    'MaintenanceModeDialog',
    () {
      testGoldens(
        'default',
        (tester) async {
          await tester.testWidget(
            filename: 'MaintenanceModeDialog/default',
            widget: const MaintenanceModeDialog(
              message: 'メンテナンス中です。しばらくお待ちください。',
            ),
            fullHeightDeviceCases: [],
            includeTextScalingCase: false,
          );
        },
      );

      testGoldens(
        'long message',
        (tester) async {
          await tester.testWidget(
            filename: 'MaintenanceModeDialog/long message',
            widget: const MaintenanceModeDialog(
              message:
                  '現在システムのメンテナンスを行っております。ご利用の皆様には大変ご不便をおかけいたしますが、完了までしばらくお待ちくださいますようお願い申し上げます。',
            ),
            fullHeightDeviceCases: [],
            includeTextScalingCase: false,
          );
        },
      );

      testGoldens(
        'long message with line break',
        (tester) async {
          await tester.testWidget(
            filename: 'MaintenanceModeDialog/long message with line break',
            widget: const MaintenanceModeDialog(
              message: 'メンテナンス中です。\n\n完了までしばらくお待ちください。\nご不便をおかけして申し訳ございません。',
            ),
            fullHeightDeviceCases: [],
            includeTextScalingCase: false,
          );
        },
      );
    },
  );
}
