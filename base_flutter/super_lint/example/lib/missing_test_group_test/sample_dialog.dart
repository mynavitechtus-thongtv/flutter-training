/// Sample dialog with default and factory constructors for missing_test_group lint example.
class SampleDialog {
  const SampleDialog({required this.message});

  final String message;

  factory SampleDialog.foo({required String message}) {
    return SampleDialog(message: message);
  }

  factory SampleDialog.bar({required String message}) {
    return SampleDialog(message: message);
  }
}
