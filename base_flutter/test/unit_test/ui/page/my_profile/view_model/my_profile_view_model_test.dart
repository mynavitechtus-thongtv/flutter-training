import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../../../common/index.dart';

void main() {
  late MyProfileViewModel myProfileViewModel;

  setUp(() {
    myProfileViewModel = MyProfileViewModel(ref);
  });

  group('getMe', () {
    group('happy', () {
      test('when getMe succeeds', () async {
        const dummyUserData = UserData(
          id: 1,
          email: 'user@example.com',
        );
        when(() => appApiService.getMe()).thenAnswer((_) async => dummyUserData);

        await myProfileViewModel.getMe();

        expect(myProfileViewModel.data.userData, dummyUserData);
        verify(() => appApiService.getMe()).called(1);
      });
    });

    group('unhappy', () {
      test('when getMe fails', () async {
        when(() => appApiService.getMe())
            .thenThrow(RemoteException(kind: RemoteExceptionKind.network));

        await myProfileViewModel.getMe();

        expect(myProfileViewModel.state.appException, isA<RemoteException>());
        verify(() => appApiService.getMe()).called(1);
      });
    });
  });

  group('logout', () {
    group('happy', () {
      test('when logout succeeds and forceLogout is called', () async {
        when(() => appApiService.logout()).thenAnswer((_) async => {});
        when(() => sharedViewModel.forceLogout()).thenAnswer((_) async => {});

        await myProfileViewModel.logout();

        verify(() => appApiService.logout()).called(1);
        verify(() => sharedViewModel.forceLogout()).called(1);
      });
    });

    group('unhappy', () {
      test('when logout fails forceLogout is still called from finally', () async {
        when(() => appApiService.logout())
            .thenThrow(RemoteException(kind: RemoteExceptionKind.network));
        when(() => sharedViewModel.forceLogout()).thenAnswer((_) async => {});

        await myProfileViewModel.logout();

        verify(() => appApiService.logout()).called(1);
        verify(() => sharedViewModel.forceLogout()).called(1);
      });
    });
  });

  group('deleteAccount', () {
    group('happy', () {
      test('when deleteAccount succeeds and forceLogout is called', () async {
        when(() => appApiService.deleteAccount()).thenAnswer((_) async => {});
        when(() => sharedViewModel.forceLogout()).thenAnswer((_) async => {});

        await myProfileViewModel.deleteAccount();

        verify(() => appApiService.deleteAccount()).called(1);
        verify(() => sharedViewModel.forceLogout()).called(greaterThanOrEqualTo(1));
      });
    });

    group('unhappy', () {
      test('when deleteAccount fails forceLogout is still called from finally', () async {
        when(() => appApiService.deleteAccount())
            .thenThrow(RemoteException(kind: RemoteExceptionKind.network));
        when(() => sharedViewModel.forceLogout()).thenAnswer((_) async => {});

        await myProfileViewModel.deleteAccount();

        verify(() => appApiService.deleteAccount()).called(1);
        verify(() => sharedViewModel.forceLogout()).called(1);
      });
    });
  });
}
