import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../index.dart';

extension AnalyticsHelperOnLoginPage on AnalyticsHelper {
  void _logLoginButtonClickEvent() {
    logEvent(
      NormalEvent(
        screenName: ScreenName.loginPage,
        eventName: EventConstants.loginButtonClick,
      ),
    );
  }

  void _logEyeIconClickEvent({
    required bool obscureText,
  }) {
    logEvent(
      NormalEvent(
        screenName: ScreenName.loginPage,
        eventName: EventConstants.eyeIconClick,
        parameter: ObscureTextParameter(
          obscureText: obscureText,
        ),
      ),
    );
  }
}

@RoutePage()
class LoginPage extends BasePage<LoginState,
    AutoDisposeStateNotifierProvider<LoginViewModel, CommonState<LoginState>>> {
  const LoginPage({super.key});

  @override
  ScreenViewEvent get screenViewEvent => ScreenViewEvent(screenName: ScreenName.loginPage);

  @override
  AutoDisposeStateNotifierProvider<LoginViewModel, CommonState<LoginState>> get provider =>
      loginViewModelProvider;

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();

    return CommonScaffold(
      body: Stack(
        children: [
          CommonImage.asset(
            path: image.imageBackground,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          CommonScrollbarWithIosStatusBarTapDetector(
            routeName: LoginRoute.name,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  CommonText(
                    l10n.login,
                    style: style(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: color.black,
                    ),
                  ),
                  const SizedBox(height: 50),
                  PrimaryTextField(
                    title: l10n.email,
                    hintText: l10n.email,
                    onChanged: (email) => ref.read(provider.notifier).setEmail(email),
                    keyboardType: TextInputType.text,
                    suffixIcon: const Icon(Icons.email),
                  ),
                  const SizedBox(height: 24),
                  PrimaryTextField(
                    title: l10n.password,
                    hintText: l10n.password,
                    onChanged: (password) => ref.read(provider.notifier).setPassword(password),
                    keyboardType: TextInputType.visiblePassword,
                    onEyeIconPressed: (obscureText) {
                      ref
                          .read(analyticsHelperProvider)
                          ._logEyeIconClickEvent(obscureText: obscureText);
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final onPageError = ref.watch(
                        provider.select((value) => value.data.onPageError),
                      );
                      return Visibility(
                        visible: onPageError.isNotEmpty,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: CommonText(
                            onPageError,
                            style: style(fontSize: 14, color: color.red1),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, child) {
                      final isLoginButtonEnabled = ref.watch(
                        provider.select((value) => value.data.isLoginButtonEnabled),
                      );
                      return ElevatedButton(
                        onPressed: isLoginButtonEnabled
                            ? () {
                                ref.read(analyticsHelperProvider)._logLoginButtonClickEvent();
                                ref.read(provider.notifier).login();
                              }
                            : null,
                        style: ButtonStyle(
                          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
                          backgroundColor: WidgetStateProperty.all(
                            color.black.withValues(alpha: isLoginButtonEnabled ? 1 : 0.5),
                          ),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                        ),
                        child: CommonText(
                          l10n.login,
                          style: style(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
