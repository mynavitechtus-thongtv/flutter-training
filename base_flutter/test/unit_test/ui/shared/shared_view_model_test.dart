import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nalsflutter/index.dart';

import '../../../common/index.dart';

void main() {
  late SharedViewModel sharedViewModel;

  setUp(() {
    sharedViewModel = SharedViewModel(ref);
  });

  group('deviceToken', () {
    test('when `firebaseMessagingService.deviceToken` returns a non-null value', () async {
      const dummyDeviceToken = 'token123';
      const expectedDeviceToken = 'token123';

      when(() => firebaseMessagingService.deviceToken).thenAnswer((_) async => dummyDeviceToken);
      final result = await sharedViewModel.deviceToken;

      expect(result, expectedDeviceToken);
    });

    test('when `firebaseMessagingService.deviceToken` returns null', () async {
      const String? dummyDeviceToken = null;
      const expectedDeviceToken = '';

      when(() => firebaseMessagingService.deviceToken).thenAnswer((_) async => dummyDeviceToken);
      final result = await sharedViewModel.deviceToken;

      expect(result, expectedDeviceToken);
    });

    test('when `firebaseMessagingService.deviceToken` throws an error', () async {
      final dummyError = Exception();

      when(() => firebaseMessagingService.deviceToken).thenThrow(dummyError);

      expect(await sharedViewModel.deviceToken, '');
    });
  });
}
