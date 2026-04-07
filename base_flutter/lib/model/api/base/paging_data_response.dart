import 'package:freezed_annotation/freezed_annotation.dart';

part 'paging_data_response.freezed.dart';
part 'paging_data_response.g.dart';

@Freezed(genericArgumentFactories: true)
sealed class PagingDataResponse<T> with _$PagingDataResponse<T> {
  const factory PagingDataResponse({
    @JsonKey(name: 'data') List<T>? data,
    @JsonKey(name: 'pagination') Pagination? pagination,
  }) = _PagingDataResponse<T>;

  factory PagingDataResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$PagingDataResponseFromJson(json, fromJsonT);
}

@freezed
sealed class Pagination with _$Pagination {
  factory Pagination({
    @JsonKey(name: 'current_page') int? page,
    @JsonKey(name: 'per_page') int? offset,
    @JsonKey(name: 'total_item') int? total,
    @JsonKey(name: 'has_more') bool? hasMore,
  }) = _Pagination;
  factory Pagination.fromJson(Map<String, dynamic> json) => _$PaginationFromJson(json);
}
