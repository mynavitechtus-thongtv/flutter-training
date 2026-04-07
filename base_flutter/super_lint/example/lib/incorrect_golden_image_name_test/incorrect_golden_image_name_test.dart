// ignore_for_file: avoid_hard_coded_strings, prefer_single_widget_per_file, avoid_dynamic, avoid_unnecessary_async_function, prefer_named_parameters
// ~.~.~.~.~.~.~.~ THE FOLLOWING CASES SHOULD NOT BE WARNED ~.~.~.~.~.~.~.~

// Valid case: filename starts with parent group name and equals group/test description
void validGoldenTest1() {
  group('incorrect_golden_image_name', () {
    testGoldens(
      'email + password empty',
      (tester) async {
        await tester.testWidget(
          filename: 'incorrect_golden_image_name/email + password empty',
          widget: const MockWidget(),
        );
      },
    );
  });
}

// ~.~.~.~.~.~.~.~ THE FOLLOWING CASES SHOULD BE WARNED ~.~.~.~.~.~.~.~

// Invalid case: wrong group name prefix
void invalidGoldenTest1() {
  group('incorrect_golden_image_name', () {
    testGoldens(
      'normal state',
      (tester) async {
        await tester.testWidget(
          // expect_lint: incorrect_golden_image_name
          filename: 'wrong_page/normal state',
          widget: const MockWidget(),
        );
      },
    );
  });
}

// Invalid case: missing group name prefix
void invalidGoldenTest2() {
  group('incorrect_golden_image_name', () {
    testGoldens(
      'error state',
      (tester) async {
        await tester.testWidget(
          // expect_lint: incorrect_golden_image_name
          filename: 'error state',
          widget: const MockWidget(),
        );
      },
    );
  });
}

// Invalid case: filename with wrong description
void invalidGoldenTest3() {
  group('incorrect_golden_image_name', () {
    testGoldens(
      'success state',
      (tester) async {
        await tester.testWidget(
          // expect_lint: incorrect_golden_image_name
          filename: 'incorrect_golden_image_name/different description',
          widget: const MockWidget(),
        );
      },
    );
  });
}

// Invalid case: wrong group name in prefix
void invalidGoldenTest4() {
  group('incorrect_golden_image_name', () {
    testGoldens(
      'default state',
      (tester) async {
        await tester.testWidget(
          // expect_lint: incorrect_golden_image_name
          filename: 'incorrect_golden_image_name_page/default state',
          widget: const MockWidget(),
        );
      },
    );
  });
}

// Invalid case: empty filename
void invalidGoldenTest5() {
  group('incorrect_golden_image_name', () {
    testGoldens(
      'empty test',
      (tester) async {
        await tester.testWidget(
          // expect_lint: incorrect_golden_image_name
          filename: '',
          widget: const MockWidget(),
        );
      },
    );
  });
}

// Mock classes and functions for testing
class MockWidget {
  const MockWidget();
}

void testGoldens(String description, dynamic Function(dynamic) test) {}
void group(String name, void Function() body) => body();

class WidgetTester {
  Future<void> testWidget({
    required String filename,
    required dynamic widget,
  }) async {}
}
