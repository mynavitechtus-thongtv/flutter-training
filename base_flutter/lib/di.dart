import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: prefer_importing_index_file
import 'di.config.dart';

@module
abstract class ServiceModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}

final GetIt getIt = GetIt.instance;
@InjectableInit()
Future<void> configureInjection() => getIt.init();
