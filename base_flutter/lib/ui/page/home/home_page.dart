import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../index.dart';

@RoutePage()
class HomePage extends BasePage<HomeState,
    AutoDisposeStateNotifierProvider<HomeViewModel, CommonState<HomeState>>> {
  const HomePage({super.key});

  @override
  ScreenViewEvent get screenViewEvent => ScreenViewEvent(screenName: ScreenName.homePage);

  @override
  AutoDisposeStateNotifierProvider<HomeViewModel, CommonState<HomeState>> get provider =>
      homeViewModelProvider;

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(provider.select((value) => value.data.notifications));
    final isLoading = ref.watch(provider.select((value) => value.data.notifications.isLoading));
    final hasError = ref.watch(provider.select((value) => value.data.notifications.hasError));

    return CommonScaffold(
      shimmerEnabled: true,
      appBar: CommonAppBar(
        text: l10n.home,
        leadingIcon: LeadingIcon.none,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(provider.notifier).refresh(),
          child: InfiniteList(
            itemCount: notifications.data.length,
            hasReachedMax: notifications.isLastPage,
            isLoading: isLoading,
            hasError: hasError,
            error: notifications.exception,
            onFetchData: () {
              ref.read(provider.notifier).fetchNotifications(
                    isInitialLoad: notifications.data.isEmpty,
                  );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications.data[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color.grey2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.grey1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.image.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CommonImage.network(
                            url: notification.image,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __) => Container(
                              width: 56,
                              height: 56,
                              color: color.grey2,
                              child: Icon(
                                Icons.image_not_supported,
                                color: color.grey1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (notification.title.isNotEmpty)
                              CommonText(
                                notification.title,
                                style: style(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: color.black,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (notification.body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              CommonText(
                                notification.body,
                                style: style(
                                  fontSize: 14,
                                  color: color.black2,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (notification.createdAt.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              CommonText(
                                notification.createdAt,
                                style: style(
                                  fontSize: 12,
                                  color: color.grey1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
