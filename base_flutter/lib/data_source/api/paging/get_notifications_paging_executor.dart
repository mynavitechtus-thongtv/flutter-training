import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../../../index.dart';

final getNotificationsPagingExecutorProvider = Provider<GetNotificationsPagingExecutor>(
  (ref) => getIt.get<GetNotificationsPagingExecutor>(),
);

class GetNotificationsPagingParams extends PagingParams {
  GetNotificationsPagingParams({
    this.isRead = false,
  });

  final bool isRead;
}

@Injectable()
class GetNotificationsPagingExecutor
    extends PagingExecutor<NotificationData, GetNotificationsPagingParams> {
  GetNotificationsPagingExecutor(this.appApiService);

  final AppApiService appApiService;

  @protected
  @override
  Future<LoadMoreOutput<NotificationData>> action({
    required int page,
    required int limit,
    required GetNotificationsPagingParams? params,
  }) async {
    final response = await appApiService.getNotifications(
      page: page,
      limit: limit,
      isRead: params?.isRead,
    );

    final list = response?.data ?? [];
    final pagination = response?.pagination;
    final hasMore = pagination?.hasMore ?? false;
    final total = pagination?.total ?? 0;

    return LoadMoreOutput(
      data: list,
      isLastPage: !hasMore,
      total: total,
    );
  }
}
