// ignore_for_file: avoid_hard_coded_strings, prefer_named_parameters, missing_golden_test
// ~.~.~.~.~.~.~.~ THE FOLLOWING CASES SHOULD BE WARNED ~.~.~.~.~.~.~.~

// Invalid: missing groups for foo and bar (source has SampleDialogMissingGroup, foo, bar)
void invalidMissingGroups() {
  // expect_lint: missing_test_group
  group('SampleDialog', () {});
  // missing group('foo') and group('bar')
}

void group(String name, void Function() body) => body();
