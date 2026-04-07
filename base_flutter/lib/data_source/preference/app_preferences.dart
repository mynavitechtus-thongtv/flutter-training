import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../index.dart';

final appPreferencesProvider = Provider((ref) => getIt.get<AppPreferences>());

@LazySingleton()
class AppPreferences {
  AppPreferences(this._sharedPreference)
      : _encryptedSharedPreferences = EncryptedSharedPreferences(prefs: _sharedPreference),
        _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  final SharedPreferences _sharedPreference;
  final EncryptedSharedPreferences _encryptedSharedPreferences;
  // ignore: unused_field
  final FlutterSecureStorage _secureStorage;

  // keys should be removed when logout
  static const keyAccessToken = 'accessToken';
  static const keyRefreshToken = 'refreshToken';
  static const keyUserId = 'userId';
  static const keyIsLoggedIn = 'isLoggedIn';

  Future<void> saveAccessToken(String token) async {
    await _encryptedSharedPreferences.setString(
      keyAccessToken,
      token,
    );
  }

  Future<String> get accessToken {
    return _encryptedSharedPreferences.getString(keyAccessToken);
  }

  Future<void> saveIsLoggedIn(bool isLoggedIn) async {
    await _sharedPreference.setBool(keyIsLoggedIn, isLoggedIn);
  }

  bool get isLoggedIn {
    return _sharedPreference.getBool(keyIsLoggedIn) ?? false;
  }

  Future<void> saveRefreshToken(String token) async {
    await _encryptedSharedPreferences.setString(
      keyRefreshToken,
      token,
    );
  }

  Future<String> get refreshToken {
    return _encryptedSharedPreferences.getString(keyRefreshToken);
  }

  Future<bool> saveUserId(int userId) {
    return _sharedPreference.setInt(keyUserId, userId);
  }

  int get userId {
    return _sharedPreference.getInt(keyUserId) ?? -1;
  }

  Future<void> clearCurrentUserData() async {
    await Future.wait(
      [
        _sharedPreference.remove(keyAccessToken),
        _sharedPreference.remove(keyRefreshToken),
        _sharedPreference.remove(keyUserId),
        _sharedPreference.remove(keyIsLoggedIn),
      ],
    );
  }
}
