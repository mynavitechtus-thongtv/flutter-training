import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../index.dart';

final myProfileViewModelProvider =
    StateNotifierProvider.autoDispose<MyProfileViewModel, CommonState<MyProfileState>>(
  (ref) => MyProfileViewModel(ref),
);

class MyProfileViewModel extends BaseViewModel<MyProfileState> {
  MyProfileViewModel(this._ref)
      : super(
          const CommonState(data: MyProfileState()),
        );

  final Ref _ref;

  Future<void> getMe() {
    return runCatching(
      action: () async {
        final userData = await _ref.read(appApiServiceProvider).getMe();
        data = data.copyWith(userData: userData);
      },
    );
  }

  Future<void> logout() {
    return runCatching(
      action: () async {
        await _ref.read(appApiServiceProvider).logout();
      },
      doOnCompleted: () async => await _ref.read(sharedViewModelProvider).forceLogout(),
      handleErrorWhen: (_) => false,
    );
  }

  Future<void> deleteAccount() async {
    return runCatching(
      action: () async {
        await _ref.read(appApiServiceProvider).deleteAccount();
      },
      doOnCompleted: () async => await _ref.read(sharedViewModelProvider).forceLogout(),
      handleErrorWhen: (_) => false,
    );
  }
}
