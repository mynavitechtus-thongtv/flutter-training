/// Sample for invalid case: test file missing groups.
class SampleDialogMissingGroup {
  const SampleDialogMissingGroup({required this.message});

  final String message;

  factory SampleDialogMissingGroup.foo({required String message}) {
    return SampleDialogMissingGroup(message: message);
  }

  factory SampleDialogMissingGroup.bar({required String message}) {
    return SampleDialogMissingGroup(message: message);
  }
}
