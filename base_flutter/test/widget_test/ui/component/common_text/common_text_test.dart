//ignore_for_file: avoid_using_text_style_constructor_directly
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:nalsflutter/index.dart';

import '../../../../common/index.dart';

void main() {
  group(
    'CommonText',
    () {
      testGoldens('basic', (tester) async {
        await tester.testWidget(
          filename: 'CommonText/basic',
          widget: const UnconstrainedBox(
            child: CommonText(
              'Hello',
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      });

      testGoldens('with max lines and overflow', (tester) async {
        await tester.testWidget(
          filename: 'CommonText/with max lines and overflow',
          widget: const SizedBox(
            width: 100,
            child: CommonText(
              'This is a very long text that should overflow',
              style: TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      });
    },
  );

  group(
    'linkify',
    () {
      testGoldens('default', (tester) async {
        await tester.testWidget(
          filename: 'linkify/default',
          widget: CommonText.linkify(
            'Visit https://example.com',
            style: const TextStyle(fontSize: 16),
            onOpenLink: (link) {},
          ),
        );
      });
    },
  );

  group(
    'canTap',
    () {
      testGoldens('default', (tester) async {
        await tester.testWidget(
          filename: 'canTap/default',
          widget: CommonText.canTap(
            'Visit https://example.com',
            style: const TextStyle(fontSize: 16),
            onTap: () {},
          ),
        );
      });
    },
  );
}
