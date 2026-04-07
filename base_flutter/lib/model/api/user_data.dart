import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../index.dart';

part 'user_data.freezed.dart';
part 'user_data.g.dart';

@freezed
sealed class UserData with _$UserData {
  const UserData._();

  const factory UserData({
    @Default(0) @JsonKey(name: 'uid') int id,
    @Default('') @JsonKey(name: 'email') String email,
    @ApiDateTimeConverter() @JsonKey(name: 'dob') DateTime? birthday,
    @Default(Gender.other) @JsonKey(name: 'gender') Gender gender,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);
}
