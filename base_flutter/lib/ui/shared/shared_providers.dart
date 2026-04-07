import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../index.dart';

final currentUserProvider = StateProvider<UserData>((ref) => const UserData());
