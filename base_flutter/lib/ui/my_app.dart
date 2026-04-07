import 'package:auto_route/auto_route.dart';
import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../index.dart';

class MyApp extends HookConsumerWidget {
  const MyApp({required this.initialResource, super.key});

  final InitialResource initialResource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);

    LocaleSettings.setLocaleRawSync('ja');

    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        return TranslationProvider(
          child: DevicePreview(
            enabled: Config.enableDevicePreview,
            builder: (_) => MaterialApp.router(
              builder: (context, child) {
                final widget = MediaQuery.withClampedTextScaling(
                  maxScaleFactor: Constant.appMaxTextScaleFactor,
                  minScaleFactor: Constant.appMinTextScaleFactor,
                  child: child ?? const SizedBox.shrink(),
                );

                return Config.enableDevicePreview
                    ? DevicePreview.appBuilder(context, widget)
                    : widget;
              },
              routerDelegate: appRouter.delegate(
                deepLinkBuilder: (deepLink) {
                  return DeepLink(_mapRouteToPageRouteInfo());
                },
                navigatorObservers: () => [AppNavigatorObserver()],
              ),
              routeInformationParser: appRouter.defaultRouteParser(),
              title: Constant.materialAppTitle,
              color: Constant.taskMenuMaterialAppColor,
              themeMode: ThemeMode.light,
              theme: lightTheme,
              darkTheme: darkTheme,
              debugShowCheckedModeBanner: kDebugMode,
              localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) =>
                  supportedLocales.map((e) => e.languageCode).contains(locale?.languageCode)
                      ? locale
                      : const Locale('ja'),
              locale:
                  Config.enableDevicePreview ? DevicePreview.locale(context) : const Locale('ja'),
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          ),
        );
      },
    );
  }

  List<PageRouteInfo> _mapRouteToPageRouteInfo() {
    return [const SplashRoute()];
  }
}
