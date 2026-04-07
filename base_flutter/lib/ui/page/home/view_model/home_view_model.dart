import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../index.dart';

final homeViewModelProvider =
    StateNotifierProvider.autoDispose<HomeViewModel, CommonState<HomeState>>(
  (ref) => HomeViewModel(ref),
);

class HomeViewModel extends BaseViewModel<HomeState> {
  HomeViewModel(this._ref) : super(CommonState(data: HomeState()));

  final Ref _ref;

  Future<void> fetchNotifications({required bool isInitialLoad}) {
    return _fetchNotifications(isInitialLoad: isInitialLoad);
  }

  Future<void> _fetchNotifications({required bool isInitialLoad}) async {
    return runCatching(
      action: () async {
        data = data.copyWith(
            notifications: data.notifications.copyWith(
          exception: null,
          isLoading: true,
        ));
        final output = await _ref.read(getNotificationsPagingExecutorProvider).execute(
              isInitialLoad: isInitialLoad,
            );
        if (isInitialLoad) {
          data = data.copyWith(
            notifications: output,
          );
        } else {
          data = data.copyWith(
            notifications: data.notifications.copyWith(
              data: [...data.notifications.data, ...output.data],
              isLastPage: output.isLastPage,
            ),
          );
        }
      },
      doOnError: (e) async {
        data = data.copyWith(notifications: data.notifications.copyWith(exception: e));
      },
      handleLoading: false,
      handleErrorWhen: (_) => false,
    );
  }

  Future<void> refresh() async {
    data = data.copyWith(
      notifications: data.notifications.copyWith(
        data: [],
        exception: null,
      ),
    );
    await fetchNotifications(isInitialLoad: true);
  }
}
