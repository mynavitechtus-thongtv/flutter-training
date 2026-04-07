import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../index.dart';

final sharedViewModelProvider = Provider((_ref) => SharedViewModel(_ref));

class SharedViewModel {
  SharedViewModel(this._ref);

  final Ref _ref;

  Future<String> get deviceToken async {
    try {
      final deviceToken = await _ref.read(firebaseMessagingServiceProvider).deviceToken;

      return deviceToken ?? '';
    } catch (e) {
      Log.e('Error getting device token: $e');
      return '';
    }
  }

  Future<void> forceLogout() async {
    // ignore: avoid_try_catch_in_shared_view_model
    try {
      await _ref.read(appPreferencesProvider).clearCurrentUserData();
    } catch (e) {
      Log.e('force logout error: $e', errorObject: e);
    } finally {
      await _ref.read(appNavigatorProvider).replaceAll([const LoginRoute()]);
    }
  }
}
