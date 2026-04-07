import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:nalsflutter/index.dart';

import '../../../../common/index.dart';

void main() {
  group(
    'iconData',
    () {
      testGoldens('default', (tester) async {
        await tester.testWidget(
          filename: 'iconData/default',
          widget: UnconstrainedBox(
            child: CommonImage.iconData(
              iconData: Icons.add,
              size: 48,
            ),
          ),
          includeTextScalingCase: false,
        );
      });
    },
  );

  group(
    'asset',
    () {
      testGoldens('default', (tester) async {
        await tester.testWidget(
          filename: 'asset/default',
          widget: UnconstrainedBox(
            child: CommonImage.asset(
              path: image.imageAppIcon,
              width: 234,
              height: 506,
            ),
          ),
          includeTextScalingCase: false,
        );
      });
    },
  );

  group(
    'network',
    () {
      testGoldens('default', (tester) async {
        await tester.testWidget(
          filename: 'network/default',
          widget: UnconstrainedBox(child: CommonImage.network(url: testImageUrl)),
          includeTextScalingCase: false,
        );
      });
    },
  );

  group(
    'svg',
    () {
      testGoldens('default', (tester) async {
        await tester.testWidget(
          filename: 'svg/default',
          widget: UnconstrainedBox(child: CommonImage.svg(path: image.iconBack)),
          includeTextScalingCase: false,
        );
      });
    },
  );

  group(
    'memory',
    () {
      testGoldens('default', (tester) async {
        final bytes = File('assets/images/image_app_icon.png').readAsBytesSync();
        await tester.testWidget(
          filename: 'memory/default',
          widget: UnconstrainedBox(
            child: CommonImage.memory(
              bytes: bytes,
              width: 48,
              height: 48,
            ),
          ),
          includeTextScalingCase: false,
        );
      });
    },
  );
}
