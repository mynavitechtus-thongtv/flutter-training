import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:nalsflutter/index.dart';

import '../../../../common/index.dart';

void main() {
  group(
    'CommonAppBar',
    () {
      testGoldens('when leadingIcon is none', (tester) async {
        await tester.testWidget(
          filename: 'CommonAppBar/when leadingIcon is none',
          widget: Scaffold(
            appBar: CommonAppBar(
              text: 'Title',
              leadingIcon: LeadingIcon.none,
            ),
            body: const SizedBox.shrink(),
          ),
        );
      });

      testGoldens('when leadingIcon is back', (tester) async {
        await tester.testWidget(
          filename: 'CommonAppBar/when leadingIcon is back',
          widget: Scaffold(
            appBar: CommonAppBar(
              text: 'Title',
            ),
            body: const SizedBox.shrink(),
          ),
        );
      });

      testGoldens('when leadingIcon is close', (tester) async {
        await tester.testWidget(
          filename: 'CommonAppBar/when leadingIcon is close',
          widget: Scaffold(
            appBar: CommonAppBar(
              text: 'Title',
              leadingIcon: LeadingIcon.close,
            ),
            body: const SizedBox.shrink(),
          ),
        );
      });

      testGoldens('when titleType is logo', (tester) async {
        await tester.testWidget(
          filename: 'CommonAppBar/when titleType is logo',
          widget: Scaffold(
            appBar: CommonAppBar(
              titleType: AppBarTitle.logo,
              leadingIcon: LeadingIcon.none,
            ),
            body: const SizedBox.shrink(),
          ),
        );
      });

      testGoldens('long text', (tester) async {
        await tester.testWidget(
          filename: 'CommonAppBar/long text',
          widget: Scaffold(
            appBar: CommonAppBar(
              titleType: AppBarTitle.text,
              leadingIcon: LeadingIcon.none,
              text:
                  'This is a very long title that should be truncated if it exceeds the available space',
            ),
            body: const SizedBox.shrink(),
          ),
        );
      });
    },
  );

  group(
    'back',
    () {
      testGoldens('default', (tester) async {
        await tester.testWidget(
          filename: 'back/default',
          widget: CommonAppBar.back(text: 'Title'),
        );
      });
    },
  );
}
