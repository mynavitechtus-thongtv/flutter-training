import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:nalsflutter/index.dart';

import '../../../../common/index.dart';

void main() {
  group(
    'CommonScaffold',
    () {
      testGoldens('basic', (tester) async {
        await tester.testWidget(
          filename: 'CommonScaffold/basic',
          widget: CommonScaffold(
            appBar: CommonAppBar(
              text: 'Title',
              leadingIcon: LeadingIcon.none,
            ),
            body: const Center(child: Text('Body')),
          ),
          includeTextScalingCase: false,
        );
      });

      testGoldens('with drawer and fab', (tester) async {
        await tester.testWidget(
          filename: 'CommonScaffold/with drawer and fab',
          widget: CommonScaffold(
            appBar: CommonAppBar(
              text: 'Title',
              leadingIcon: LeadingIcon.none,
            ),
            body: const Center(child: Text('Body')),
            drawer: const Drawer(child: Text('Drawer')),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
          includeTextScalingCase: false,
        );
      });
    },
  );
}
