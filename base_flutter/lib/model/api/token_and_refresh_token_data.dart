import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_and_refresh_token_data.freezed.dart';
part 'token_and_refresh_token_data.g.dart';

@freezed
sealed class TokenAndRefreshTokenData with _$TokenAndRefreshTokenData {
  const factory TokenAndRefreshTokenData({
    @Default('') @JsonKey(name: 'access_token') String accessToken,
    @Default('') @JsonKey(name: 'refresh_token') String refreshToken,
    @Default('') @JsonKey(name: 'firebase_token') String firebaseToken,
  }) = _TokenAndRefreshTokenData;

  factory TokenAndRefreshTokenData.fromJson(Map<String, dynamic> json) =>
      _$TokenAndRefreshTokenDataFromJson(json);
}
