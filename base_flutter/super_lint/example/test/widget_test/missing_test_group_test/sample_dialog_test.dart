// ignore_for_file: avoid_hard_coded_strings, prefer_named_parameters, missing_golden_test
// ~.~.~.~.~.~.~.~ THE FOLLOWING CASES SHOULD NOT BE WARNED ~.~.~.~.~.~.~.~

// Valid: test has one group per constructor (SampleDialog, foo, bar)
void validTest() {
  group('SampleDialog', () {});
  group('foo', () {});
  group('bar', () {});
}

void group(String name, void Function() body) => body();
