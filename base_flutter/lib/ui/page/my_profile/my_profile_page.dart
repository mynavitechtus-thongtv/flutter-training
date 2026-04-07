import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../index.dart';

@RoutePage(name: 'MyProfileRoute')
class MyProfilePage extends BasePage<MyProfileState,
    AutoDisposeStateNotifierProvider<MyProfileViewModel, CommonState<MyProfileState>>> {
  const MyProfilePage({super.key});

  @override
  ScreenViewEvent get screenViewEvent => ScreenViewEvent(screenName: ScreenName.myProfilePage);

  @override
  AutoDisposeStateNotifierProvider<MyProfileViewModel, CommonState<MyProfileState>> get provider =>
      myProfileViewModelProvider;

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    useEffect(
      () {
        Future.microtask(() {
          ref.read(provider.notifier).getMe();
        });

        return null;
      },
      const [],
    );

    final userData = ref.watch(provider.select((value) => value.data.userData));

    return CommonScaffold(
      body: SafeArea(
        // ignore: missing_expanded_or_flexible
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        AvatarView(text: userData.email),
                        const SizedBox(width: 16),
                        Flexible(
                          child: CommonText(
                            userData.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: color.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: CommonText(
                l10n.logout,
                style: style(
                  color: color.black,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                ref.read(appNavigatorProvider).showDialog(ConfirmDialog.logOut(
                      doOnConfirm: () => ref.read(provider.notifier).logout(),
                    ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: CommonText(
                l10n.deleteAccount,
                style: style(
                  color: color.black,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                ref.read(appNavigatorProvider).showDialog(ConfirmDialog.deleteAccount(
                      doOnConfirm: () => ref.read(provider.notifier).deleteAccount(),
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
