import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:nalsflutter/index.dart';
import '../../../../common/index.dart';

void main() {
  group(
    'CommonDivider',
    () {
      testGoldens('horizontal', (tester) async {
        await tester.testWidget(
          filename: 'CommonDivider/horizontal',
          widget: const CommonDivider(
            dividerColor: Colors.black,
            thickness: 2,
          ),
          includeTextScalingCase: false,
        );
      });

      testGoldens('vertical', (tester) async {
        await tester.testWidget(
          filename: 'CommonDivider/vertical',
          widget: const SizedBox(
            height: 100,
            child: CommonDivider(
              direction: DividerDirection.vertical,
              dividerColor: Colors.black,
              thickness: 2,
            ),
          ),
          includeTextScalingCase: false,
        );
      });

      testGoldens('horizontal with indent', (tester) async {
        await tester.testWidget(
          filename: 'CommonDivider/horizontal with indent',
          widget: const CommonDivider(
            dividerColor: Colors.black,
            thickness: 2,
            indent: 8,
            endIndent: 8,
          ),
          includeTextScalingCase: false,
        );
      });
    },
  );
}
