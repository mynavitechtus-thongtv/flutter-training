import '../../../../../index.dart';

abstract class PagingParams {}

abstract class PagingExecutor<T, P extends PagingParams> {
  PagingExecutor({
    this.initPage = Constant.initialPage,
    this.initOffset = 0,
    this.limit = Constant.itemsPerPage,
  })  : _output = LoadMoreOutput<T>(data: <T>[], page: initPage, offset: initOffset),
        _oldOutput = LoadMoreOutput<T>(data: <T>[], page: initPage, offset: initOffset);

  final int initPage;
  final int initOffset;
  final int limit;

  LoadMoreOutput<T> _output;
  LoadMoreOutput<T> _oldOutput;

  int get page => _output.page;
  int get offset => _output.offset;

  Future<LoadMoreOutput<T>> action({
    required int page,
    required int limit,
    required P? params,
  });

  Future<LoadMoreOutput<T>> execute({
    required bool isInitialLoad,
    P? params,
  }) async {
    try {
      if (isInitialLoad) {
        _output = LoadMoreOutput<T>(data: <T>[], page: initPage, offset: initOffset);
      }
      final loadMoreOutput = await action(page: page, limit: limit, params: params);

      final newOutput = _oldOutput.copyWith(
        data: loadMoreOutput.data,
        otherData: loadMoreOutput.otherData,
        page: isInitialLoad
            ? initPage + (loadMoreOutput.data.isNotEmpty ? 1 : 0)
            : _oldOutput.page + (loadMoreOutput.data.isNotEmpty ? 1 : 0),
        offset: isInitialLoad
            ? (initOffset + loadMoreOutput.data.length)
            : _oldOutput.offset + loadMoreOutput.data.length,
        isLastPage: loadMoreOutput.isLastPage,
        isRefreshSuccess: isInitialLoad,
        total: loadMoreOutput.total,
        isLoading: false,
        exception: null,
      );

      _output = newOutput;
      _oldOutput = newOutput;

      return newOutput;
      // ignore: missing_log_in_catch_block
    } catch (e) {
      Log.e('LoadMoreError: $e');
      _output = _oldOutput;

      throw e is AppException ? e : AppUncaughtException(rootException: e);
    }
  }
}
