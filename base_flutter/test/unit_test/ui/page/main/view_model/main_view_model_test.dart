import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../../../common/index.dart';

class _MockStreamSubscription<T> extends Mock implements StreamSubscription<T> {}

void main() {
  late MainViewModel mainViewModel;

  setUp(() {
    mainViewModel = MainViewModel(ref);
  });

  group('init', () {
    group('happy', () {
      test('when init completes all steps', () async {
        when(() => localPushNotificationHelper.init(any())).thenAnswer((_) async => {});
        when(() => permissionHelper.requestNotificationPermission()).thenAnswer((_) async => true);
        when(() => firebaseMessagingService.onTokenRefresh).thenAnswer((_) => const Stream.empty());
        when(() => firebaseMessagingService.onMessageOpenedApp)
            .thenAnswer((_) => const Stream.empty());
        when(() => firebaseMessagingService.initialMessage).thenAnswer((_) async => null);

        await mainViewModel.init();

        verify(() => localPushNotificationHelper.init(any())).called(1);
        verify(() => permissionHelper.requestNotificationPermission()).called(1);
        expect(mainViewModel.onTokenRefreshSubscription, isNotNull);
        expect(mainViewModel.onMessageOpenedAppSubscription, isNotNull);
      });
    });

    group('unhappy', () {
      test('when initLocalPushNotification throws', () async {
        when(() => localPushNotificationHelper.init(any())).thenThrow(Exception('Init failed'));
        when(() => permissionHelper.requestNotificationPermission()).thenAnswer((_) async => true);
        when(() => firebaseMessagingService.onTokenRefresh).thenAnswer((_) => const Stream.empty());
        when(() => firebaseMessagingService.onMessageOpenedApp)
            .thenAnswer((_) => const Stream.empty());

        expect(mainViewModel.init(), throwsA(isA<Exception>()));
      });
    });
  });

  group('initLocalPushNotification', () {
    group('happy', () {
      test('when init succeeds', () async {
        when(() => localPushNotificationHelper.init(any())).thenAnswer((_) async => {});

        await mainViewModel.initLocalPushNotification();

        verify(() => localPushNotificationHelper.init(any())).called(greaterThanOrEqualTo(1));
      });
    });

    group('unhappy', () {
      test('when init throws', () async {
        when(() => localPushNotificationHelper.init(any())).thenThrow(Exception('Init failed'));

        expect(mainViewModel.initLocalPushNotification(), throwsA(isA<Exception>()));
      });
    });
  });

  group('requestPermissions', () {
    group('happy', () {
      test('when request succeeds', () async {
        when(() => permissionHelper.requestNotificationPermission()).thenAnswer((_) async => true);

        await mainViewModel.requestPermissions();

        verify(() => permissionHelper.requestNotificationPermission()).called(1);
      });
    });

    group('unhappy', () {
      test('when request throws', () async {
        when(() => permissionHelper.requestNotificationPermission())
            .thenThrow(Exception('Permission denied'));

        try {
          await mainViewModel.requestPermissions();
          fail('Expected Exception to be thrown');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });
  });

  group('listenOnDeviceTokenRefresh', () {
    group('happy', () {
      test('when called subscribes to onTokenRefresh', () {
        when(() => firebaseMessagingService.onTokenRefresh).thenAnswer((_) => const Stream.empty());

        mainViewModel.listenOnDeviceTokenRefresh();

        expect(mainViewModel.onTokenRefreshSubscription, isNotNull);
        verify(() => firebaseMessagingService.onTokenRefresh).called(greaterThanOrEqualTo(1));
      });

      test('when called again cancels previous subscription', () {
        final mockSubscription = _MockStreamSubscription<String>();
        when(() => mockSubscription.cancel()).thenAnswer((_) async => {});
        when(() => firebaseMessagingService.onTokenRefresh)
            .thenAnswer((_) => Stream<String>.value('token'));

        mainViewModel.listenOnDeviceTokenRefresh();
        mainViewModel.onTokenRefreshSubscription = mockSubscription;
        mainViewModel.listenOnDeviceTokenRefresh();

        verify(() => mockSubscription.cancel()).called(1);
      });
    });

    // No validation or error path that affects state
    // ignore: empty_test_group
    group('unhappy', () {});
  });

  group('listenOnMessageOpenedApp', () {
    group('happy', () {
      test('when called subscribes to onMessageOpenedApp', () {
        when(() => firebaseMessagingService.onMessageOpenedApp)
            .thenAnswer((_) => const Stream.empty());

        mainViewModel.listenOnMessageOpenedApp();

        expect(mainViewModel.onMessageOpenedAppSubscription, isNotNull);
        verify(() => firebaseMessagingService.onMessageOpenedApp).called(greaterThanOrEqualTo(1));
      });

      test('when called again cancels previous subscription', () {
        final mockSubscription = _MockStreamSubscription<RemoteMessage>();
        when(() => mockSubscription.cancel()).thenAnswer((_) async => {});
        when(() => firebaseMessagingService.onMessageOpenedApp)
            .thenAnswer((_) => Stream<RemoteMessage>.value(const RemoteMessage()));

        mainViewModel.listenOnMessageOpenedApp();
        mainViewModel.onMessageOpenedAppSubscription = mockSubscription;
        mainViewModel.listenOnMessageOpenedApp();

        verify(() => mockSubscription.cancel()).called(1);
      });
    });

    // ignore: empty_test_group
    group('unhappy', () {});
  });

  group('getInitialMessage', () {
    group('happy', () {
      test('when initialMessage is null', () async {
        when(() => firebaseMessagingService.initialMessage).thenAnswer((_) async => null);

        await mainViewModel.getInitialMessage();

        verify(() => firebaseMessagingService.initialMessage).called(greaterThanOrEqualTo(1));
      });

      test('when initialMessage is not null', () async {
        const remoteMessage = RemoteMessage();
        when(() => firebaseMessagingService.initialMessage).thenAnswer((_) async => remoteMessage);

        await mainViewModel.getInitialMessage();

        verify(() => firebaseMessagingService.initialMessage).called(greaterThanOrEqualTo(1));
      });
    });

    group('unhappy', () {
      test('when initialMessage throws', () async {
        when(() => firebaseMessagingService.initialMessage).thenThrow(Exception('Failed'));

        await mainViewModel.getInitialMessage();

        verify(() => firebaseMessagingService.initialMessage).called(greaterThanOrEqualTo(1));
      });
    });
  });

  group('dispose', () {
    group('happy', () {
      test('when dispose is called cancels subscriptions and sets null', () {
        final mockOnMessageOpenedApp = _MockStreamSubscription<RemoteMessage>();
        final mockOnTokenRefresh = _MockStreamSubscription<String>();
        when(() => mockOnMessageOpenedApp.cancel()).thenAnswer((_) async => {});
        when(() => mockOnTokenRefresh.cancel()).thenAnswer((_) async => {});

        mainViewModel.onMessageOpenedAppSubscription = mockOnMessageOpenedApp;
        mainViewModel.onTokenRefreshSubscription = mockOnTokenRefresh;

        mainViewModel.dispose();

        verify(() => mockOnMessageOpenedApp.cancel()).called(1);
        verify(() => mockOnTokenRefresh.cancel()).called(1);
        expect(mainViewModel.onMessageOpenedAppSubscription, isNull);
        expect(mainViewModel.onTokenRefreshSubscription, isNull);
      });

      test('when dispose is called with null subscriptions does not throw', () {
        mainViewModel.onMessageOpenedAppSubscription = null;
        mainViewModel.onTokenRefreshSubscription = null;

        expect(() => mainViewModel.dispose(), returnsNormally);
      });
    });

    // dispose is cleanup only, no error path
    // ignore: empty_test_group
    group('unhappy', () {});
  });
}
