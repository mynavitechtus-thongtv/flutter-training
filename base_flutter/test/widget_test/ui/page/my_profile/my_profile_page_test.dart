import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../../common/index.dart';

class MockMyProfileViewModel extends StateNotifier<CommonState<MyProfileState>>
    with Mock
    implements MyProfileViewModel {
  MockMyProfileViewModel(super.state) {
    when(() => getMe()).thenAnswer((_) async {});
  }
}

void main() {
  group(
    'MyProfilePage',
    () {
      testGoldens(
        'when userData has email',
        (tester) async {
          await tester.testWidget(
            filename: 'MyProfilePage/when userData has email',
            widget: const MyProfilePage(),
            overrides: [
              myProfileViewModelProvider.overrideWith(
                (ref) => MockMyProfileViewModel(
                  const CommonState(
                    data: MyProfileState(
                      userData: UserData(
                        email: 'user@example.jp',
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
        'when email is empty',
        (tester) async {
          await tester.testWidget(
            filename: 'MyProfilePage/when email is empty',
            widget: const MyProfilePage(),
            overrides: [
              myProfileViewModelProvider.overrideWith(
                (ref) => MockMyProfileViewModel(
                  const CommonState(
                    data: MyProfileState(
                      userData: UserData(
                        email: '',
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
        'when email is long',
        (tester) async {
          await tester.testWidget(
            filename: 'MyProfilePage/when email is long',
            widget: const MyProfilePage(),
            overrides: [
              myProfileViewModelProvider.overrideWith(
                (ref) => MockMyProfileViewModel(
                  const CommonState(
                    data: MyProfileState(
                      userData: UserData(
                        email: 'very.long.email.address.for.testing.overflow@example.co.jp',
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
