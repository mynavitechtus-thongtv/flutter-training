import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../../index.dart';

final firebaseFirestoreServiceProvider = Provider<FirebaseFirestoreService>(
  (ref) => getIt.get<FirebaseFirestoreService>(),
);

@LazySingleton()
class FirebaseFirestoreService {
  // ignore: unused_field
  static const _pathUsers = 'users';
}
