import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../../../common/index.dart';

void main() {
  late SplashViewModel splashViewModel;

  setUp(() {
    splashViewModel = SplashViewModel(ref);
  });

  group('init', () {
    group('happy', () {
      test('when user is logged in navigates to MainRoute', () async {
        when(() => appPreferences.isLoggedIn).thenReturn(true);
        when(() => navigator.replaceAll(any())).thenAnswer((_) async => true);

        await splashViewModel.init();

        verify(() => navigator.replaceAll([MainRoute()])).called(1);
      });

      test('when user is not logged in navigates to LoginRoute', () async {
        when(() => appPreferences.isLoggedIn).thenReturn(false);
        when(() => navigator.replaceAll(any())).thenAnswer((_) async => true);

        await splashViewModel.init();

        verify(() => navigator.replaceAll([const LoginRoute()])).called(1);
      });
    });

    group('unhappy', () {
      test('when replaceAll throws', () async {
        when(() => appPreferences.isLoggedIn).thenReturn(true);
        when(() => navigator.replaceAll(any())).thenThrow(Exception('Navigation failed'));

        await splashViewModel.init();

        verify(() => navigator.replaceAll([MainRoute()])).called(1);
      });
    });
  });
}
