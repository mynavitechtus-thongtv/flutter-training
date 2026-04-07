import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:nalsflutter/index.dart';

import '../../../../common/index.dart';

void main() {
  group(
    'deleteAccount',
    () {
      testGoldens(
        'default',
        (tester) async {
          await tester.testWidget(
            filename: 'deleteAccount/default',
            widget: ConfirmDialog.deleteAccount(doOnConfirm: () {}),
            fullHeightDeviceCases: [],
            includeTextScalingCase: false,
          );
        },
      );
    },
  );

  group(
    'logOut',
    () {
      testGoldens(
        'default',
        (tester) async {
          await tester.testWidget(
            filename: 'logOut/default',
            widget: ConfirmDialog.logOut(doOnConfirm: () {}),
            fullHeightDeviceCases: [],
            includeTextScalingCase: false,
          );
        },
      );
    },
  );
}
