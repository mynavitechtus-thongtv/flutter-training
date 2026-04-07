import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../../../common/index.dart';

class MockGetNotificationsPagingExecutor extends Mock implements GetNotificationsPagingExecutor {}

void main() {
  late HomeViewModel homeViewModel;
  late MockGetNotificationsPagingExecutor mockPagingExecutor;

  setUp(() {
    mockPagingExecutor = MockGetNotificationsPagingExecutor();
    when(() => ref.read(getNotificationsPagingExecutorProvider)).thenReturn(mockPagingExecutor);
    homeViewModel = HomeViewModel(ref);
  });

  group('fetchNotifications', () {
    group('happy', () {
      test('when initial load succeeds', () async {
        const dummyNotifications = LoadMoreOutput<NotificationData>(
          data: [
            NotificationData(id: 1, title: 'Title 1', body: 'Body 1'),
          ],
          isLastPage: false,
          total: 10,
        );
        when(() => mockPagingExecutor.execute(isInitialLoad: true))
            .thenAnswer((_) async => dummyNotifications);

        await homeViewModel.fetchNotifications(isInitialLoad: true);

        expect(homeViewModel.data.notifications.data, dummyNotifications.data);
        expect(homeViewModel.data.notifications.isLastPage, false);
        expect(homeViewModel.data.notifications.exception, isNull);
        verify(() => mockPagingExecutor.execute(isInitialLoad: true)).called(1);
      });

      test('when load more succeeds', () async {
        homeViewModel = HomeViewModel(ref);
        when(() => ref.read(getNotificationsPagingExecutorProvider)).thenReturn(mockPagingExecutor);
        const initialData = LoadMoreOutput<NotificationData>(
          data: [NotificationData(id: 1, title: 'A', body: 'B')],
          isLastPage: false,
          total: 5,
        );
        when(() => mockPagingExecutor.execute(isInitialLoad: false))
            .thenAnswer((_) async => const LoadMoreOutput<NotificationData>(
                  data: [
                    NotificationData(id: 2, title: 'Title 2', body: 'Body 2'),
                  ],
                  isLastPage: true,
                  total: 5,
                ));

        homeViewModel.data = homeViewModel.data.copyWith(
          notifications: initialData,
        );
        await homeViewModel.fetchNotifications(isInitialLoad: false);

        expect(homeViewModel.data.notifications.data.length, 2);
        expect(homeViewModel.data.notifications.isLastPage, true);
        verify(() => mockPagingExecutor.execute(isInitialLoad: false)).called(1);
      });
    });

    group('unhappy', () {
      test('when executor throws', () async {
        final dummyException = RemoteException(
          kind: RemoteExceptionKind.network,
        );
        when(() => mockPagingExecutor.execute(isInitialLoad: true)).thenThrow(dummyException);

        await homeViewModel.fetchNotifications(isInitialLoad: true);

        expect(
          homeViewModel.data.notifications.exception,
          isA<RemoteException>(),
        );
        verify(() => mockPagingExecutor.execute(isInitialLoad: true)).called(1);
      });
    });
  });

  group('refresh', () {
    group('happy', () {
      test('when refresh clears data and fetches initial load', () async {
        const dummyOutput = LoadMoreOutput<NotificationData>(
          data: [NotificationData(id: 1, title: 'R', body: 'R')],
          isLastPage: true,
          total: 1,
        );
        when(() => mockPagingExecutor.execute(isInitialLoad: true))
            .thenAnswer((_) async => dummyOutput);

        await homeViewModel.refresh();

        expect(homeViewModel.data.notifications.data, dummyOutput.data);
        verify(() => mockPagingExecutor.execute(isInitialLoad: true)).called(1);
      });
    });

    group('unhappy', () {
      test('when fetch after refresh fails', () async {
        when(() => mockPagingExecutor.execute(isInitialLoad: true))
            .thenThrow(RemoteException(kind: RemoteExceptionKind.timeout));

        await homeViewModel.refresh();

        expect(homeViewModel.data.notifications.exception, isNotNull);
      });
    });
  });
}
