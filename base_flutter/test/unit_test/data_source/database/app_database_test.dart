import 'package:flutter_test/flutter_test.dart';
import 'package:nalsflutter/index.dart';

import '../../../common/index.dart';

void main() {
  // ignore: unused_local_variable
  late AppDatabase appDatabase;

  setUp(() async {
    appDatabase = AppDatabase(appPreferences);
  });
}
