import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../index.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => getIt.get<AppDatabase>());

@LazySingleton()
class AppDatabase {
  AppDatabase(this.appPreferences);

  final AppPreferences appPreferences;

  int get userId => appPreferences.userId;
}
