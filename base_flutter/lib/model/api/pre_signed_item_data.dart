import 'package:freezed_annotation/freezed_annotation.dart';

part 'pre_signed_item_data.freezed.dart';
part 'pre_signed_item_data.g.dart';

@freezed
sealed class PreSignedItemData with _$PreSignedItemData {
  const factory PreSignedItemData({
    @Default('') @JsonKey(name: 'url') String url,
    @Default('') @JsonKey(name: 'path') String path,
  }) = _PreSignedItemData;

  factory PreSignedItemData.fromJson(Map<String, dynamic> json) => _$PreSignedItemDataFromJson({
        ...json,
        'url': json['url'] ??
            (json['presigned_url'] != null ? json['presigned_url']['url'] : null) ??
            '',
        'path': json['path'] ??
            (json['presigned_url'] != null ? json['presigned_url']['path'] : null) ??
            '',
      });
}
