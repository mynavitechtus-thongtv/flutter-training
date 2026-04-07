import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../../../common/index.dart';

void main() {
  late LoginViewModel loginViewModel;

  setUp(() {
    loginViewModel = LoginViewModel(ref);
  });

  group('setEmail', () {
    group('happy', () {
      test('when email is changed', () {
        const dummyEmail = 'test@example.com';

        loginViewModel.setEmail(dummyEmail);

        expect(loginViewModel.data.email, dummyEmail);
        expect(loginViewModel.data.onPageError, '');
      });
    });

    // Simple state update with no validation
    // ignore: empty_test_group
    group('unhappy', () {});
  });

  group('setPassword', () {
    group('happy', () {
      test('when password is changed', () {
        const dummyPassword = 'Password1!';

        loginViewModel.setPassword(dummyPassword);

        expect(loginViewModel.data.password, dummyPassword);
        expect(loginViewModel.data.onPageError, '');
      });
    });

    // Simple state update with no validation
    // ignore: empty_test_group
    group('unhappy', () {});
  });

  group('login', () {
    const dummyEmail = 'test@example.com';
    const dummyPassword = 'Password1!';
    const dummyAccessToken = 'access_token_1';
    const dummyRefreshToken = 'refresh_token_1';
    const dummyDeviceToken = 'fcm_token_001';
    const dummyLoginResponse = TokenAndRefreshTokenData(
      accessToken: dummyAccessToken,
      refreshToken: dummyRefreshToken,
    );

    group('happy', () {
      test('when login succeeds', () async {
        loginViewModel.setEmail(dummyEmail);
        loginViewModel.setPassword(dummyPassword);

        when(() => appApiService.login(
              email: dummyEmail,
              password: dummyPassword,
            )).thenAnswer((_) async => dummyLoginResponse);
        when(() => sharedViewModel.deviceToken).thenAnswer((_) async => dummyDeviceToken);
        when(() => appPreferences.saveAccessToken(any())).thenAnswer((_) async => true);
        when(() => appPreferences.saveRefreshToken(any())).thenAnswer((_) async => true);
        when(() => appPreferences.saveIsLoggedIn(true)).thenAnswer((_) async => true);
        when(() => navigator.replaceAll(any())).thenAnswer((_) async => true);

        await loginViewModel.login();

        verify(() => appApiService.login(
              email: dummyEmail,
              password: dummyPassword,
            )).called(1);
        verify(() => appPreferences.saveAccessToken(dummyAccessToken)).called(1);
        verify(() => appPreferences.saveRefreshToken(dummyRefreshToken)).called(1);
        verify(() => appPreferences.saveIsLoggedIn(true)).called(1);
        verify(() => navigator.replaceAll([MainRoute()])).called(1);
      });
    });

    group('unhappy', () {
      test('when login fails with network error', () async {
        loginViewModel.setEmail(dummyEmail);
        loginViewModel.setPassword(dummyPassword);

        when(() => appApiService.login(
              email: dummyEmail,
              password: dummyPassword,
            )).thenThrow(RemoteException(kind: RemoteExceptionKind.network));

        await loginViewModel.login();

        expect(loginViewModel.data.onPageError, isNotEmpty);
        verifyNever(() => navigator.replaceAll(any()));
      });

      test('when login fails and sets onPageError', () async {
        loginViewModel.setEmail(dummyEmail);
        loginViewModel.setPassword(dummyPassword);

        when(() => appApiService.login(
              email: dummyEmail,
              password: dummyPassword,
            )).thenThrow(RemoteException(kind: RemoteExceptionKind.unknown));

        await loginViewModel.login();

        expect(loginViewModel.data.onPageError, isNotEmpty);
      });
    });
  });
}
