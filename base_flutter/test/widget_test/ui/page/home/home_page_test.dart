import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../../common/index.dart';

class MockHomeViewModel extends StateNotifier<CommonState<HomeState>>
    with Mock
    implements HomeViewModel {
  MockHomeViewModel(super.state) {
    when(() => refresh()).thenAnswer((_) async {});
    when(() => fetchNotifications(isInitialLoad: any(named: 'isInitialLoad')))
        .thenAnswer((_) async {});
  }
}

void main() {
  group(
    'HomePage',
    () {
      testGoldens(
        'when notifications are not empty',
        (tester) async {
          await tester.testWidget(
            filename: 'HomePage/when notifications are not empty',
            widget: const HomePage(),
            customPump: (tester) async {
              await tester.pump();
              await tester.pump(const Duration(seconds: 2));
            },
            overrides: [
              homeViewModelProvider.overrideWith(
                (ref) => MockHomeViewModel(
                  CommonState(
                    data: HomeState(
                      notifications: const LoadMoreOutput<NotificationData>(
                        data: [
                          NotificationData(
                            title: 'お知らせタイトル',
                            body: 'お知らせの本文です。',
                            image: testImageUrl,
                            createdAt: '2024/01/15 10:30',
                          ),
                          NotificationData(
                            title: '2件目の通知',
                            body: '2件目のお知らせ本文',
                            image: '',
                            createdAt: '2024/01/14 09:00',
                          ),
                        ],
                        isLastPage: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

      testGoldens(
        'when notifications are empty',
        (tester) async {
          await tester.testWidget(
            filename: 'HomePage/when notifications are empty',
            widget: const HomePage(),
            customPump: (tester) async {
              await tester.pump();
              await tester.pump(const Duration(seconds: 2));
            },
            overrides: [
              homeViewModelProvider.overrideWith(
                (ref) => MockHomeViewModel(
                  CommonState(
                    data: HomeState(
                      notifications: const LoadMoreOutput<NotificationData>(
                        data: [],
                        isLastPage: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

      testGoldens(
        'when notifications have error',
        (tester) async {
          await tester.testWidget(
            filename: 'HomePage/when notifications have error',
            widget: const HomePage(),
            customPump: (tester) async {
              await tester.pump();
              await tester.pump(const Duration(seconds: 2));
            },
            overrides: [
              homeViewModelProvider.overrideWith(
                (ref) => MockHomeViewModel(
                  CommonState(
                    data: HomeState(
                      notifications: LoadMoreOutput<NotificationData>(
                        data: const [],
                        isLastPage: true,
                        exception: RemoteException(kind: RemoteExceptionKind.unknown),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
