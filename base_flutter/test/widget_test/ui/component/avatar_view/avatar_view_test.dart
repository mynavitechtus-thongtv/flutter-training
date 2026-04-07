import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:nalsflutter/index.dart';

import '../../../../common/index.dart';

void main() {
  group(
    'AvatarView',
    () {
      testGoldens('when text is empty', (tester) async {
        await tester.testWidget(
          filename: 'AvatarView/when text is empty',
          widget: const UnconstrainedBox(child: AvatarView(text: '')),
        );
      });

      testGoldens('when text is not empty', (tester) async {
        await tester.testWidget(
          filename: 'AvatarView/when text is not empty',
          widget: const UnconstrainedBox(child: AvatarView(text: 'Minh')),
        );
      });

      testGoldens('when isActive is true', (tester) async {
        await tester.testWidget(
          filename: 'AvatarView/when isActive is true',
          widget: const UnconstrainedBox(child: AvatarView(text: 'Minh', isActive: true)),
        );
      });

      testGoldens(
        'when backgroundColor is red textColor is blue',
        (tester) async {
          await tester.testWidget(
            filename: 'AvatarView/when backgroundColor is red textColor is blue',
            widget: UnconstrainedBox(
              child: AvatarView(
                text: 'Minh',
                backgroundColor: Colors.red,
                textStyle: style(color: Colors.blue, fontSize: 28),
              ),
            ),
          );
        },
      );
    },
  );
}
