import 'dart:convert';
import 'dart:io';

/// Initialize project configuration based on JSON config in setting_initial_config.md
/// Usage: dart run tools/dart_tools/lib/init_project.dart

// Constants
const List<String> _iosFlavors = ['Develop', 'Qa', 'Staging', 'Production'];
const List<String> _defaultFlavors = ['develop', 'qa', 'staging', 'production'];
const String _flutterImagePrefix = 'ghcr.io/cirruslabs/flutter:';

// Template for setting_initial_config.md
const String _initProjectTemplate = '''Fill in the values below, then run `make init` command

```json
{
  "prodApplicationId": "jp.flutter.app",
  "prodBundleId": "jp.flutter.app",
  "flutterVersion": "3.38.7",
  "projectCode": "NFT",
  "figma": {
    "designDeviceWidth": 375.0,
    "designDeviceHeight": 812.0
  },
  "appMinTextScaleFactor": 1.0,
  "appMaxTextScaleFactor": 1.0
}
```
''';

// Default google-services.json template
const String _defaultGoogleServicesJson = '''{
  "project_info": {
    "project_number": "598926766937",
    "project_id": "nals-flutter-prod",
    "storage_bucket": "nals-flutter-prod.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:598926766937:android:9592c6941fa17be8aed248",
        "android_client_info": {
          "package_name": "jp.flutter.app"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyCze5HFUzvhuLptqlcAIWk2n2KmZs_irwE"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
''';

// Default GoogleService-Info.plist template
const String _defaultGoogleServiceInfoPlist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_KEY</key>
    <string>AIzaSyBxANyodWvHiKesOIUWDaVl3by734uSFYM</string>
    <key>GCM_SENDER_ID</key>
    <string>598926766937</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>jp.flutter.app</string>
    <key>PROJECT_ID</key>
    <string>nals-flutter-prod</string>
    <key>STORAGE_BUCKET</key>
    <string>nals-flutter-prod.firebasestorage.app</string>
    <key>IS_ADS_ENABLED</key>
    <false></false>
    <key>IS_ANALYTICS_ENABLED</key>
    <false></false>
    <key>IS_APPINVITE_ENABLED</key>
    <true></true>
    <key>IS_GCM_ENABLED</key>
    <true></true>
    <key>IS_SIGNIN_ENABLED</key>
    <true></true>
    <key>GOOGLE_APP_ID</key>
    <string>1:598926766937:ios:1c8adfe6a3d424b2aed248</string>
</dict>
</plist>
''';

String pathOf(String root, String relative) =>
    root.endsWith('/') ? (root + relative) : (root + '/' + relative);

/// Get applicationId for a flavor based on production applicationId
String _getApplicationIdForFlavor(String prodApplicationId, String flavor) {
  if (flavor == 'production') {
    return prodApplicationId;
  }
  return '$prodApplicationId.$flavor';
}

/// Get bundleId for a flavor based on production bundleId
String _getBundleIdForFlavor(String prodBundleId, String flavor) {
  if (flavor == 'production') {
    return prodBundleId;
  }
  return '$prodBundleId.$flavor';
}

// Create setting_initial_config.md if it doesn't exist
Future<bool> _createInitProjectFileIfNotExists(String projectRoot) async {
  final initPath = pathOf(projectRoot, 'setting_initial_config.md');
  final initFile = File(initPath);

  if (!await initFile.exists()) {
    await initFile.writeAsString(_initProjectTemplate);
    print('✅ Created setting_initial_config.md file');
    print(
        '🔗 Please configure project at: \x1b]8;;file://$initPath\x1b\\setting_initial_config.md\x1b]8;;\x1b\\');
    return true;
  }
  return false;
}

// Validation functions
List<String> _validateConfig(Map<String, dynamic> config) {
  final errors = <String>[];

  // Required fields
  if (!config.containsKey('prodApplicationId') || config['prodApplicationId'] == null) {
    errors.add('Missing required field: prodApplicationId');
  }

  if (!config.containsKey('prodBundleId') || config['prodBundleId'] == null) {
    errors.add('Missing required field: prodBundleId');
  }

  if (!config.containsKey('flutterVersion') || config['flutterVersion'] == null) {
    errors.add('Missing required field: flutterVersion');
  }

  if (!config.containsKey('projectCode') || config['projectCode'] == null) {
    errors.add('Missing required field: projectCode');
  }

  // Figma validation
  final figma = config['figma'] as Map?;
  if (figma != null) {
    if (!figma.containsKey('designDeviceWidth') || figma['designDeviceWidth'] == null) {
      errors.add('Missing required field: figma.designDeviceWidth');
    }
    if (!figma.containsKey('designDeviceHeight') || figma['designDeviceHeight'] == null) {
      errors.add('Missing required field: figma.designDeviceHeight');
    }
  }

  return errors;
}

// Error handling wrapper
Future<void> _updateWithErrorHandling(String component, Future<void> Function() updateFn) async {
  try {
    await updateFn();
    print('✅ Updated $component');
  } catch (e) {
    stderr.writeln('❌ Failed to update $component: $e');
    stderr.writeln('💡 Please check your configuration and try again');
    exitCode = 1;
  }
}

Future<void> main(List<String> args) async {
  final projectRoot = Directory.current.path;
  final inputPath = pathOf(projectRoot, 'setting_initial_config.md');
  final readmePath = pathOf(projectRoot, 'README.md');

  // Create setting_initial_config.md if it doesn't exist
  final wasCreated = await _createInitProjectFileIfNotExists(projectRoot);
  if (wasCreated) {
    print('📝 Please fill in the configuration information and run the command again.');
    return;
  }

  final inputFile = File(inputPath);
  final readmeFile = File(readmePath);

  if (!await inputFile.exists()) {
    stderr.writeln('setting_initial_config.md not found at $inputPath');
    exitCode = 1;
    return;
  }
  if (!await readmeFile.exists()) {
    stderr.writeln('README.md not found at $readmePath');
    exitCode = 1;
    return;
  }

  final inputContent = await inputFile.readAsString();
  final jsonConfigRaw = _extractJsonBlock(inputContent);
  if (jsonConfigRaw == null) {
    stderr.writeln('Could not find valid JSON block in setting_initial_config.md');
    exitCode = 1;
    return;
  }

  Map<String, dynamic> config;
  try {
    config = json.decode(jsonConfigRaw) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('❌ Invalid JSON in setting_initial_config.md: $e');
    stderr.writeln('💡 Please check your JSON syntax');
    exitCode = 1;
    return;
  }

  // Validate config
  final validationErrors = _validateConfig(config);
  if (validationErrors.isNotEmpty) {
    stderr.writeln('❌ Configuration validation failed:');
    for (final error in validationErrors) {
      stderr.writeln('  • $error');
    }
    exitCode = 1;
    return;
  }

  print('📖 Config loaded and validated from setting_initial_config.md');

  // Apply changes with error handling
  await _updateWithErrorHandling('README.md', () => _updateReadme(projectRoot, config));
  await _updateWithErrorHandling(
      'Android build.gradle', () => _updateAndroidBuildGradle(projectRoot, config));
  await _updateWithErrorHandling(
      'iOS xcconfig files', () => _updateIosXcconfig(projectRoot, config));
  await _updateWithErrorHandling('Constants file', () => _updateConstants(projectRoot, config));
  await _updateWithErrorHandling(
      'Dart defines files', () => _writeDartDefines(projectRoot, config));
  await _updateWithErrorHandling(
      'Bitbucket pipelines', () => _updateBitbucketPipelines(projectRoot, config));
  await _updateWithErrorHandling('Codemagic YAML', () => _updateCodemagicYaml(projectRoot, config));
  await _updateWithErrorHandling('Jenkinsfile', () => _updateJenkinsfile(projectRoot, config));
  await _updateWithErrorHandling(
      'GitHub workflows', () => _updateGithubWorkflows(projectRoot, config));
  await _updateWithErrorHandling(
      'Lefthook scripts', () => _updateLefthookScripts(projectRoot, config));
  await _updateWithErrorHandling(
      'Environment config', () => _updateEnvDefault(projectRoot, config));
  await _updateWithErrorHandling(
      'Android Manifest', () => _updateAndroidManifest(projectRoot, config));
  await _updateWithErrorHandling(
      'Local Push Notification', () => _updateLocalPushNotification(projectRoot, config));
  await _updateWithErrorHandling(
      'MainActivity package', () => _updateMainActivityPackage(projectRoot, config));
  await _updateWithErrorHandling('Export Options', () => _updateExportOptions(projectRoot, config));
  await _updateWithErrorHandling(
      'Firebase config files', () => _createFirebaseConfigFiles(projectRoot, config));

  if (exitCode == 0) {
    print('✅ Project updated successfully.');
  } else {
    print('❌ Some updates failed. Please check the errors above.');
  }

  // Print warning about iOS bundle identifier
  _printIosBundleIdentifierWarning(config);
}

void _printIosBundleIdentifierWarning(Map<String, dynamic> config) {
  final prodBundleId = config['prodBundleId']?.toString() ?? '';
  if (prodBundleId.isEmpty) return;

  print('');
  print('⚠️  WARNING: Manual action required for iOS!');
  print('─────────────────────────────────────────────────────────────────');
  print('To complete the iOS configuration, you must manually update Bundle Identifier for each flavor in Xcode.');
  print('This will update ios/Runner.xcodeproj/project.pbxproj accordingly.');
  print('─────────────────────────────────────────────────────────────────');
}

Future<void> _updateReadme(String root, Map<String, dynamic> config) async {
  final readmeFile = File(pathOf(root, 'README.md'));
  var readme = await readmeFile.readAsString();

  final flutterSdk = config['flutterVersion']?.toString();

  if (flutterSdk != null && flutterSdk.isNotEmpty) {
    readme = _replaceBulletValue(
      readme,
      keyPattern: RegExp(r'^-\s+Flutter SDK:\s*.*$', multiLine: true),
      replacement: '- Flutter SDK: $flutterSdk',
    );
  }

  // Remove config JSON block if exists
  readme = _removeConfigJsonBlock(readme);

  // Clean up excessive blank lines
  readme = _cleanupBlankLines(readme);

  await readmeFile.writeAsString(readme);
}

Future<void> _updateAndroidBuildGradle(String root, Map<String, dynamic> config) async {
  final androidFile = File(pathOf(root, 'android/app/build.gradle'));
  if (!await androidFile.exists()) {
    throw Exception('android/app/build.gradle not found');
  }
  var content = await androidFile.readAsString();

  final prodApplicationId = config['prodApplicationId']?.toString() ?? '';

  if (prodApplicationId.isNotEmpty) {
    // Update namespace with production applicationId
    content = content.replaceAllMapped(RegExp(r'^(\s*)namespace\s*=\s*"[^"]+"', multiLine: true),
        (m) => '${m.group(1)}namespace = "$prodApplicationId"');

    // Update defaultConfig applicationId
    content = content.replaceAllMapped(
        RegExp(r'^(\s*)applicationId\s*=\s*"[^"]+"', multiLine: true),
        (m) => '${m.group(1)}applicationId = "$prodApplicationId"');

    // Update applicationIds for each flavor
    for (final flavor in _defaultFlavors) {
      final appId = _getApplicationIdForFlavor(prodApplicationId, flavor);

      // Update applicationId for specific flavor
      final flavorPattern = RegExp('$flavor\\s*\\{[\\s\\S]*?\\}');
      content = content.replaceAllMapped(flavorPattern, (match) {
        var flavorContent = match.group(0)!;

        flavorContent = flavorContent.replaceAllMapped(
            RegExp(r'applicationId\s+"[^"]+"'), (m) => 'applicationId "$appId"');

        return flavorContent;
      });
    }
  }

  await androidFile.writeAsString(content);
}

Future<void> _updateIosXcconfig(String root, Map<String, dynamic> config) async {
  final prodBundleId = config['prodBundleId']?.toString() ?? '';
  if (prodBundleId.isEmpty) return;

  for (final f in _iosFlavors) {
    final file = File(pathOf(root, 'ios/Flutter/$f.xcconfig'));
    if (!await file.exists()) continue;
    var c = await file.readAsString();

    final flavorKey = f.toLowerCase();
    final bundleId = _getBundleIdForFlavor(prodBundleId, flavorKey);

    c = c.replaceFirst(RegExp(r'^PRODUCT_BUNDLE_IDENTIFIER=.*', multiLine: true),
        'PRODUCT_BUNDLE_IDENTIFIER=$bundleId');

    await file.writeAsString(c);
  }
}

Future<void> _updateConstants(String root, Map<String, dynamic> config) async {
  final constFile = File(pathOf(root, 'lib/common/constant.dart'));
  if (!await constFile.exists()) {
    throw Exception('lib/common/constant.dart not found');
  }

  var content = await constFile.readAsString();

  // Update figma design constants
  final figma = config['figma'] as Map<String, dynamic>?;
  if (figma != null) {
    if (figma['designDeviceWidth'] != null) {
      content = _updateConstantValue(content, 'designDeviceWidth', figma['designDeviceWidth']);
    }
    if (figma['designDeviceHeight'] != null) {
      content = _updateConstantValue(content, 'designDeviceHeight', figma['designDeviceHeight']);
    }
  }

  // Update text scale factor constants
  if (config['appMinTextScaleFactor'] != null) {
    content =
        _updateConstantValue(content, 'appMinTextScaleFactor', config['appMinTextScaleFactor']);
  }
  if (config['appMaxTextScaleFactor'] != null) {
    content =
        _updateConstantValue(content, 'appMaxTextScaleFactor', config['appMaxTextScaleFactor']);
  }

  await constFile.writeAsString(content);
}

String _updateConstantValue(String content, String key, dynamic value) {
  final valueStr = value is num ? value.toString() : "'$value'";
  final pattern = RegExp('^(\\s*)static const $key\\s*=\\s*[^;]+;', multiLine: true);

  if (pattern.hasMatch(content)) {
    return content.replaceAllMapped(pattern, (match) {
      final indent = match.group(1) ?? '  ';
      return '${indent}static const $key = $valueStr;';
    });
  }

  return content;
}

Future<void> _writeDartDefines(String root, Map<String, dynamic> config) async {
  final dir = Directory(pathOf(root, 'dart_defines'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  for (final flavor in _defaultFlavors) {
    final map = <String, dynamic>{
      'FLAVOR': flavor,
    };

    final file = File(pathOf(root, 'dart_defines/$flavor.json'));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(map));
  }
}

Future<void> _updateBitbucketPipelines(String root, Map<String, dynamic> config) async {
  final file = File(pathOf(root, 'bitbucket-pipelines.yml'));
  if (!await file.exists()) return;
  var c = await file.readAsString();

  final flutterSdk = config['flutterVersion']?.toString();
  if (flutterSdk != null && flutterSdk.isNotEmpty) {
    c = c.replaceFirst(
        RegExp(r'^image:\s+ghcr\.io/cirruslabs/flutter:\d+\.\d+\.\d+', multiLine: true),
        'image: $_flutterImagePrefix$flutterSdk');
  }

  final projectCode = config['projectCode']?.toString() ?? '';
  if (projectCode.isNotEmpty) {
    c = _updateProjectCodeInContent(c, projectCode);
  }

  await file.writeAsString(c);
}

String _updateProjectCodeInContent(String content, String projectCode) {
  final branchTypes = ['feature', 'bugfix', 'hotfix', 'release'];
  for (final type in branchTypes) {
    content = content.replaceAll(RegExp("'$type/[A-Z]+'-\*'"), "'$type/$projectCode-*'");
    content = content.replaceAll("'$type/NFT-*'", "'$type/$projectCode-*'");
  }
  return content;
}

Future<void> _updateCodemagicYaml(String root, Map<String, dynamic> config) async {
  final file = File(pathOf(root, 'codemagic.yaml'));
  if (!await file.exists()) return;

  final flutterSdk = config['flutterVersion']?.toString();

  if (flutterSdk != null && flutterSdk.isNotEmpty) {
    await _updateVersionInFile(
      file.path,
      RegExp(r'^(\s*)flutter:\s*(\d+\.\d+\.\d+)', multiLine: true),
      flutterSdk,
      '{indent}flutter: {version}',
    );
  }

  final prodApplicationId = config['prodApplicationId']?.toString();
  if (prodApplicationId != null) {
    var content = await file.readAsString();

    // Update ANDROID_PACKAGE_NAME_* variables for each flavor
    final devAppId = _getApplicationIdForFlavor(prodApplicationId, 'develop');
    final qaAppId = _getApplicationIdForFlavor(prodApplicationId, 'qa');
    final stgAppId = _getApplicationIdForFlavor(prodApplicationId, 'staging');

    content = content.replaceAllMapped(
      RegExp(r'ANDROID_PACKAGE_NAME_DEV:\s*"[^"]*"'),
      (match) => 'ANDROID_PACKAGE_NAME_DEV: "$devAppId"',
    );
    content = content.replaceAllMapped(
      RegExp(r'ANDROID_PACKAGE_NAME_QA:\s*"[^"]*"'),
      (match) => 'ANDROID_PACKAGE_NAME_QA: "$qaAppId"',
    );
    content = content.replaceAllMapped(
      RegExp(r'ANDROID_PACKAGE_NAME_STG:\s*"[^"]*"'),
      (match) => 'ANDROID_PACKAGE_NAME_STG: "$stgAppId"',
    );

    // Update Google Play package name with staging applicationId
    content = content.replaceAllMapped(
      RegExp(
          r"LATEST_GOOGLE_PLAY_BUILD_NUMBER=\$\(google-play get-latest-build-number --package-name '[^']+'\)"),
      (match) =>
          "LATEST_GOOGLE_PLAY_BUILD_NUMBER=\$(google-play get-latest-build-number --package-name '$stgAppId')",
    );

    await file.writeAsString(content);
  }
}

Future<bool> _updateVersionInFile(
    String filePath, RegExp pattern, String newVersion, String replacement) async {
  final file = File(filePath);
  if (!await file.exists()) return false;
  var content = await file.readAsString();
  final current = pattern.firstMatch(content);
  final currentVal = current?.group(2);
  if (currentVal != null && currentVal != newVersion) {
    content = content.replaceAllMapped(pattern, (m) {
      final indent = m.group(1) ?? '';
      return replacement.replaceAll('{indent}', indent).replaceAll('{version}', newVersion);
    });
    await file.writeAsString(content);
    return true;
  }
  return false;
}

Future<void> _updateJenkinsfile(String root, Map<String, dynamic> config) async {
  final file = File(pathOf(root, 'Jenkinsfile'));
  if (!await file.exists()) return;

  final flutterSdk = config['flutterVersion']?.toString();
  if (flutterSdk != null && flutterSdk.isNotEmpty) {
    var content = await file.readAsString();
    final current = RegExp(r'ghcr\.io/cirruslabs/flutter:(\d+\.\d+\.\d+)').firstMatch(content);
    final currentVal = current?.group(1);
    if (currentVal != null && currentVal != flutterSdk) {
      content = content.replaceAll(
          RegExp(r"ghcr\.io/cirruslabs/flutter:\d+\.\d+\.\d+"), '$_flutterImagePrefix$flutterSdk');
      await file.writeAsString(content);
    }
  }
}

Future<void> _updateGithubWorkflows(String root, Map<String, dynamic> config) async {
  final dir = Directory(pathOf(root, '.github/workflows'));
  if (!await dir.exists()) return;
  final flutterSdk = config['flutterVersion']?.toString();
  if (flutterSdk == null || flutterSdk.isEmpty) return;

  await for (final e in dir.list(recursive: false, followLinks: false)) {
    if (e is! File) continue;
    if (!e.path.endsWith('.yaml') && !e.path.endsWith('.yml')) continue;

    await _updateVersionInFile(
      e.path,
      RegExp(r'^(\s*)FLUTTER_VERSION:\s*"(\d+\.\d+\.\d+)"', multiLine: true),
      flutterSdk,
      '{indent}FLUTTER_VERSION: "{version}"',
    );
  }
}

Future<void> _updateLefthookScripts(String root, Map<String, dynamic> config) async {
  final projectCode = config['projectCode']?.toString();
  if (projectCode == null || projectCode.isEmpty) return;

  // Update commit-msg script
  final commitMsgFile = File(pathOf(root, '.lefthook/commit-msg/commit-msg.sh'));
  if (await commitMsgFile.exists()) {
    var content = await commitMsgFile.readAsString();

    content = content.replaceAllMapped(
      RegExp(r'([A-Z0-9]+)(-\\d\+|\-\d+|\-\[0\-9\]\+)'),
      (match) => '$projectCode${match.group(2)}',
    );

    await commitMsgFile.writeAsString(content);
  }

  // Update pre-commit script
  final preCommitFile = File(pathOf(root, '.lefthook/pre-commit/pre-commit.sh'));
  if (await preCommitFile.exists()) {
    var content = await preCommitFile.readAsString();

    content = content.replaceAllMapped(
      RegExp(r'([A-Z0-9]+)(-\\d\+|\-\d+|\-\[0\-9\]\+)'),
      (match) => '$projectCode${match.group(2)}',
    );

    await preCommitFile.writeAsString(content);
  }
}

Future<void> _updateEnvDefault(String root, Map<String, dynamic> config) async {
  final envFile = File(pathOf(root, '.env.default'));

  final envContent = <String>[];

  envContent.add('# Environment variables for Fastlane');
  envContent.add('# This file contains default values for CI/CD configuration');
  envContent.add('');
  envContent.add('SLACK_HOOKS_URL_SUCCESS=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK');
  envContent.add('SLACK_HOOKS_URL_ERROR=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK');
  envContent.add('MENTIONS_SUCCESS=@channel');
  envContent.add('MENTIONS_ERROR=@minhnt3');
  envContent.add('FIREBASE_TOKEN=1//0000000000000000000000000000000000000000');
  envContent.add('');
  envContent.add('# Flavors');
  envContent.add('DEV_FLAVOR=develop');
  envContent.add('QA_FLAVOR=qa');
  envContent.add('STG_FLAVOR=staging');
  envContent.add('PROD_FLAVOR=production');
  envContent.add('');
  envContent.add('# App Store IDs');
  envContent.add('DEV_APP_STORE_ID=');
  envContent.add('QA_APP_STORE_ID=');
  envContent.add('STG_APP_STORE_ID=');
  envContent.add('PROD_APP_STORE_ID=');
  envContent.add('');
  envContent.add('# Team IDs (App Store Connect)');
  envContent.add('QA_TEAM_ID=');
  envContent.add('PROD_TEAM_ID=');
  envContent.add('');
  envContent.add('# App Store Connect API Key');
  envContent.add('QA_KEY_ID=');
  envContent.add('PROD_KEY_ID=');
  envContent.add('QA_KEY_FILEPATH=');
  envContent.add('PROD_KEY_FILEPATH=');
  envContent.add('QA_ISSUER_ID=');
  envContent.add('PROD_ISSUER_ID=');
  envContent.add('');
  envContent.add('# TestFlight external groups');
  envContent.add('DEV_TEST_FLIGHT_EXTERNAL_GROUPS=testers');
  envContent.add('QA_TEST_FLIGHT_EXTERNAL_GROUPS=testers');
  envContent.add('STG_TEST_FLIGHT_EXTERNAL_GROUPS=testers');
  envContent.add('PROD_TEST_FLIGHT_EXTERNAL_GROUPS=testers');
  envContent.add('');
  envContent.add('# Firebase App Distribution (Android)');
  envContent.add('DEV_FIREBASE_APP_ID=');
  envContent.add('QA_FIREBASE_APP_ID=');
  envContent.add('STG_FIREBASE_APP_ID=');
  envContent.add('PROD_FIREBASE_APP_ID=');
  envContent.add('');
  envContent.add('# Firebase App Distribution groups');
  envContent.add('DEV_FIREBASE_GROUPS=testers');
  envContent.add('QA_FIREBASE_GROUPS=testers');
  envContent.add('STG_FIREBASE_GROUPS=testers');
  envContent.add('PROD_FIREBASE_GROUPS=testers');

  await envFile.writeAsString(envContent.join('\n') + '\n');
}

Future<void> _updateAndroidManifest(String root, Map<String, dynamic> config) async {
  final manifestFile = File(pathOf(root, 'android/app/src/main/AndroidManifest.xml'));
  if (!await manifestFile.exists()) return;

  final prodApplicationId = config['prodApplicationId']?.toString();
  if (prodApplicationId == null || prodApplicationId.isEmpty) return;

  var content = await manifestFile.readAsString();

  // Update package attribute in manifest tag (only the package attribute, not ${applicationId} variables)
  content = content.replaceAllMapped(
    RegExp(r'<manifest[^>]*package="[^"]*"'),
    (match) {
      // Only replace the package attribute value, keep everything else
      return match
          .group(0)!
          .replaceFirst(RegExp(r'package="[^"]*"'), 'package="$prodApplicationId"');
    },
  );

  // Note: Do NOT modify android:value="${applicationId}" as it's a Gradle variable
  // that resolves to the correct applicationId at build time for each flavor

  await manifestFile.writeAsString(content);
}

Future<void> _updateLocalPushNotification(String root, Map<String, dynamic> config) async {
  final notificationFile =
      File(pathOf(root, 'lib/common/helper/local_push_notification_helper.dart'));
  if (!await notificationFile.exists()) return;

  final prodApplicationId = config['prodApplicationId']?.toString();
  if (prodApplicationId == null || prodApplicationId.isEmpty) return;

  var content = await notificationFile.readAsString();

  // Update _channelId constant
  content = content.replaceAllMapped(
    RegExp(r"static const _channelId = '[^']*';"),
    (match) => "static const _channelId = '$prodApplicationId';",
  );

  await notificationFile.writeAsString(content);
}

Future<void> _updateMainActivityPackage(String root, Map<String, dynamic> config) async {
  final prodApplicationId = config['prodApplicationId']?.toString();
  if (prodApplicationId == null || prodApplicationId.isEmpty) return;

  // Update MainActivity.kt package and file path
  final oldMainActivityPath =
      pathOf(root, 'android/app/src/main/kotlin/jp/flutter/app/MainActivity.kt');
  final newMainActivityPath = pathOf(root,
      'android/app/src/main/kotlin/${prodApplicationId.replaceAll('.', '/')}/MainActivity.kt');

  // Create new directory structure first
  final newDir = Directory(
      pathOf(root, 'android/app/src/main/kotlin/${prodApplicationId.replaceAll('.', '/')}'));
  await newDir.create(recursive: true);

  final oldMainActivityFile = File(oldMainActivityPath);
  final newMainActivityFile = File(newMainActivityPath);

  if (await oldMainActivityFile.exists()) {
    var content = await oldMainActivityFile.readAsString();
    await newMainActivityFile.writeAsString(content);
    await oldMainActivityFile.delete();
  }

  if (await newMainActivityFile.exists()) {
    var content = await newMainActivityFile.readAsString();

    if (content.contains('package jp.flutter.app')) {
      content = content.replaceAll('package jp.flutter.app', 'package $prodApplicationId');
    } else {
      content = content.replaceAllMapped(
        RegExp(r'package [a-zA-Z0-9_.]+'),
        (match) => 'package $prodApplicationId',
      );
    }

    await newMainActivityFile.writeAsString(content);
  } else {
    final content = '''package $prodApplicationId

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
''';

    await newMainActivityFile.writeAsString(content);
  }
}

Future<void> _updateExportOptions(String root, Map<String, dynamic> config) async {
  final exportOptionsFile = File(pathOf(root, 'ios/exportOptions.plist'));
  if (!await exportOptionsFile.exists()) return;

  var prodBundleId = config['prodBundleId']?.toString() ?? '';
  if (prodBundleId.isEmpty) {
    prodBundleId = config['prodApplicationId']?.toString() ?? '';
  }
  if (prodBundleId.isEmpty) return;

  var content = await exportOptionsFile.readAsString();

  // Update bundle identifier in provisioningProfiles
  content = content.replaceAllMapped(
    RegExp(r'<key>[^<]*</key>\s*<string>[^<]*</string>(?=\s*</dict>)'),
    (match) => '<key>$prodBundleId</key>\n\t\t<string>distribution_flutter_codebase</string>',
  );

  await exportOptionsFile.writeAsString(content);
}

Future<void> _createFirebaseConfigFiles(String root, Map<String, dynamic> config) async {
  final prodApplicationId = config['prodApplicationId']?.toString() ?? 'jp.flutter.app';
  final prodBundleId = config['prodBundleId']?.toString() ?? prodApplicationId;

  // Create Android google-services.json for each flavor
  for (final flavor in _defaultFlavors) {
    final androidFlavorDir = Directory(pathOf(root, 'android/app/src/$flavor'));
    final googleServicesFile = File(pathOf(root, 'android/app/src/$flavor/google-services.json'));

    if (!await googleServicesFile.exists()) {
      // Create directory if not exists
      if (!await androidFlavorDir.exists()) {
        await androidFlavorDir.create(recursive: true);
      }

      // Generate google-services.json with correct package name
      final packageName = _getApplicationIdForFlavor(prodApplicationId, flavor);
      final googleServicesContent = _defaultGoogleServicesJson.replaceAll(
        '"package_name": "jp.flutter.app"',
        '"package_name": "$packageName"',
      );

      await googleServicesFile.writeAsString(googleServicesContent);
      print('  📄 Created android/app/src/$flavor/google-services.json');
    }
  }

  // Create iOS GoogleService-Info.plist for each flavor
  for (final flavor in _defaultFlavors) {
    final iosFlavorDir = Directory(pathOf(root, 'ios/config/$flavor'));
    final googleServiceInfoFile = File(pathOf(root, 'ios/config/$flavor/GoogleService-Info.plist'));

    if (!await googleServiceInfoFile.exists()) {
      // Create directory if not exists
      if (!await iosFlavorDir.exists()) {
        await iosFlavorDir.create(recursive: true);
      }

      // Generate GoogleService-Info.plist with correct bundle ID
      final bundleId = _getBundleIdForFlavor(prodBundleId, flavor);
      final googleServiceInfoContent = _defaultGoogleServiceInfoPlist.replaceAll(
        '<string>jp.flutter.app</string>',
        '<string>$bundleId</string>',
      );

      await googleServiceInfoFile.writeAsString(googleServiceInfoContent);
      print('  📄 Created ios/config/$flavor/GoogleService-Info.plist');
    }
  }
}

String? _extractJsonBlock(String content) {
  final regex = RegExp(r'```json\s*([\s\S]*?)\s*```', multiLine: true);
  final match = regex.firstMatch(content);
  if (match == null) return null;

  var jsonContent = match.group(1)!;
  jsonContent = _fixJsonComments(jsonContent);

  return jsonContent;
}

String _replaceBulletValue(String input,
    {required RegExp keyPattern, required String replacement}) {
  if (keyPattern.hasMatch(input)) {
    return input.replaceFirst(keyPattern, replacement);
  }
  final lines = input.split('\n');
  final reqIndex = lines.indexWhere((l) => l.trim() == '### Requirements');
  if (reqIndex != -1) {
    lines.insert(reqIndex + 1, replacement.trimRight());
    return lines.join('\n');
  }
  return input;
}

String _cleanupBlankLines(String content) {
  final lines = content.split('\n');
  final cleaned = <String>[];
  bool lastWasBlank = false;

  for (final line in lines) {
    final isBlank = line.trim().isEmpty;

    if (isBlank) {
      if (!lastWasBlank) {
        cleaned.add(line);
      }
      lastWasBlank = true;
    } else {
      cleaned.add(line);
      lastWasBlank = false;
    }
  }

  return cleaned.join('\n');
}

String _removeConfigJsonBlock(String readme) {
  const startMarker = '<!-- CONFIG_INPUT_START -->';
  const endMarker = '<!-- CONFIG_INPUT_END -->';
  if (readme.contains(startMarker) && readme.contains(endMarker)) {
    final pattern = RegExp('$startMarker[\\s\\S]*?$endMarker', multiLine: true);
    return readme.replaceFirst(pattern, '');
  }
  return readme;
}

String _fixJsonComments(String jsonContent) {
  var lines = jsonContent.split('\n');
  lines = lines.map((line) {
    final commentIndex = line.indexOf('//');
    if (commentIndex != -1) {
      final beforeComment = line.substring(0, commentIndex);
      final quotes = beforeComment.split('"').length - 1;
      if (quotes % 2 == 0) {
        return beforeComment.trimRight();
      }
    }
    return line;
  }).toList();

  var result = lines.join('\n');
  result = result.replaceAll(RegExp(r',\s*}'), '}');
  result = result.replaceAll(RegExp(r',\s*]'), ']');

  return result;
}
