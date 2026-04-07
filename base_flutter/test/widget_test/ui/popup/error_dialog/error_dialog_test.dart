import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:nalsflutter/index.dart';

import '../../../../common/index.dart';

void main() {
  group(
    'error',
    () {
      testGoldens(
        'default',
        (tester) async {
          await tester.testWidget(
            filename: 'error/default',
            widget: ErrorDialog.error(message: 'エラーが発生しました'),
            fullHeightDeviceCases: [],
            includeTextScalingCase: false,
          );
        },
      );

      testGoldens(
        'long message',
        (tester) async {
          await tester.testWidget(
            filename: 'error/long message',
            widget: ErrorDialog.error(
              message: '接続に失敗しました。しばらく経ってから再度お試しください。ネットワークの設定をご確認ください。',
            ),
            fullHeightDeviceCases: [],
            includeTextScalingCase: false,
          );
        },
      );
    },
  );

  group(
    'errorWithRetry',
    () {
      testGoldens(
        'default',
        (tester) async {
          await tester.testWidget(
            filename: 'errorWithRetry/default',
            widget: ErrorDialog.errorWithRetry(
              message: 'エラーが発生しました',
              onRetryPressed: () {},
            ),
            fullHeightDeviceCases: [],
            includeTextScalingCase: false,
          );
        },
      );

      testGoldens(
        'long message with line breaks',
        (tester) async {
          await tester.testWidget(
            filename: 'errorWithRetry/long message with line breaks',
            widget: ErrorDialog.errorWithRetry(
              message: '接続に失敗しました。\n\nしばらく経ってから再度お試しください。\nネットワークの設定をご確認ください。',
              onRetryPressed: () {},
            ),
            fullHeightDeviceCases: [],
            includeTextScalingCase: false,
          );
        },
      );
    },
  );
}
