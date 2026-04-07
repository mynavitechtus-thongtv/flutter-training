import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../index.dart';

part 'pre_signed_urls_data.freezed.dart';
part 'pre_signed_urls_data.g.dart';

@freezed
sealed class PreSignedUrlsData with _$PreSignedUrlsData {
  const factory PreSignedUrlsData({
    @Default(<PreSignedItemData>[])
    @JsonKey(name: 'presigned_urls')
    List<PreSignedItemData> presignedUrls,
  }) = _PreSignedUrlsData;

  factory PreSignedUrlsData.fromJson(Map<String, dynamic> json) =>
      _$PreSignedUrlsDataFromJson(json);
}
