import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../index.dart';

final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, CommonState<LoginState>>(
  (ref) => LoginViewModel(ref),
);

class LoginViewModel extends BaseViewModel<LoginState> {
  LoginViewModel(this._ref) : super(const CommonState(data: LoginState()));

  final Ref _ref;

  void setEmail(String email) {
    data = data.copyWith(
      email: email,
      onPageError: '',
    );
  }

  void setPassword(String password) {
    data = data.copyWith(
      password: password,
      onPageError: '',
    );
  }

  FutureOr<void> login() async {
    await runCatching(
      action: () async {
        final email = data.email.trim();
        // --- BYPASS API MOCK ---
        // final response = await _ref.read(appApiServiceProvider).login(
        //       email: email,
        //       password: data.password,
        //     );

        final deviceToken = await _ref.read(sharedViewModelProvider).deviceToken;
        Log.d('deviceToken: $deviceToken'.hardcoded);

        await Future.wait([
          _ref.read(appPreferencesProvider).saveAccessToken('mock_access_token'),
          _ref.read(appPreferencesProvider).saveRefreshToken('mock_refresh_token'),
          _ref.read(appPreferencesProvider).saveIsLoggedIn(true),
        ]);

        await _ref.read(appNavigatorProvider).replaceAll([MainRoute()]);
      },
      handleErrorWhen: (_) => false,
      doOnError: (e) async {
        data = data.copyWith(onPageError: e.message);
      },
    );
  }
}
