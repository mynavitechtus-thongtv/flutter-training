import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../index.dart';

part 'notification_data.freezed.dart';
part 'notification_data.g.dart';

@freezed
sealed class NotificationData with _$NotificationData {
  const NotificationData._();

  const factory NotificationData({
    @Default(0) @JsonKey(name: 'id') int id,
    @Default('') @JsonKey(name: 'title') String title,
    @Default('') @JsonKey(name: 'body') String body,
    @Default('') @JsonKey(name: 'image') String image,
    @Default('') @JsonKey(name: 'created_at') String createdAt,
  }) = _NotificationData;

  factory NotificationData.fromJson(Map<String, dynamic> json) => _$NotificationDataFromJson(json);

  factory NotificationData.from(RemoteMessage? data) {
    return NotificationData(
      title: data?.notification?.title ?? '',
      body: data?.notification?.body ?? '',
      image: safeCast<String>(data?.data['image']) ?? '',
    );
  }
}
