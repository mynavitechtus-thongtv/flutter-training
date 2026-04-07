// ignore_for_file: missing_run_catching
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../index.dart';

final mainViewModelProvider =
    StateNotifierProvider.autoDispose<MainViewModel, CommonState<MainState>>(
  (ref) => MainViewModel(ref),
);

class MainViewModel extends BaseViewModel<MainState> {
  MainViewModel(this._ref) : super(const CommonState(data: MainState()));

  final Ref _ref;

  @visibleForTesting
  StreamSubscription<RemoteMessage>? onMessageOpenedAppSubscription;
  @visibleForTesting
  StreamSubscription<String>? onTokenRefreshSubscription;

  FutureOr<void> init() async {
    await initLocalPushNotification();
    await requestPermissions();
    listenOnDeviceTokenRefresh();
    listenOnMessageOpenedApp();
    await getInitialMessage();
  }

  Future<void> initLocalPushNotification() async {
    await _ref.read(localPushNotificationHelperProvider).init((_) async {});
  }

  Future<void> requestPermissions() {
    return _ref.read(permissionHelperProvider).requestNotificationPermission();
  }

  void listenOnDeviceTokenRefresh() {
    onTokenRefreshSubscription?.cancel();
    onTokenRefreshSubscription =
        _ref.read(firebaseMessagingServiceProvider).onTokenRefresh.listen((event) async {
      if (event.isNotEmpty) {
        // post to server
      }
    });
  }

  void listenOnMessageOpenedApp() {
    onMessageOpenedAppSubscription?.cancel();
    onMessageOpenedAppSubscription =
        _ref.read(firebaseMessagingServiceProvider).onMessageOpenedApp.listen((_) async {});
  }

  Future<void> getInitialMessage() async {
    await runCatching(
      action: () async {
        await _ref.read(firebaseMessagingServiceProvider).initialMessage;
      },
      handleErrorWhen: (_) => false,
      handleLoading: false,
    );
  }

  @override
  void dispose() {
    onMessageOpenedAppSubscription?.cancel();
    onTokenRefreshSubscription?.cancel();
    onMessageOpenedAppSubscription = null;
    onTokenRefreshSubscription = null;
    super.dispose();
  }
}
