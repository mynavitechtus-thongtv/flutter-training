import 'dart:io';

void main() {
  final flavors = {
    'develop': 'jp.flutter.app.dev',
    'qa': 'jp.flutter.app.qa',
    'staging': 'jp.flutter.app.stg',
    'production': 'jp.flutter.app',
  };

  for (final entry in flavors.entries) {
    final flavor = entry.key;
    final bundleId = entry.value;

    final androidJson = '''{
  "project_info": {
    "project_number": "123456789012",
    "project_id": "dummy-project",
    "storage_bucket": "dummy-project.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789012:android:0000000000000000000000",
        "android_client_info": {
          "package_name": "$bundleId"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyDummyDummyDummyDummyDummyDummyDum"
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
}''';

    final iosPlist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>AIzaSyDummyDummyDummyDummyDummyDummyDum</string>
	<key>GCM_SENDER_ID</key>
	<string>123456789012</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>$bundleId</string>
	<key>PROJECT_ID</key>
	<string>dummy-project</string>
	<key>STORAGE_BUCKET</key>
	<string>dummy-project.appspot.com</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<true/>
	<key>IS_GCM_ENABLED</key>
	<true/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>1:123456789012:ios:0000000000000000000000</string>
</dict>
</plist>''';

    final adDir = Directory('android/app/src/$flavor');
    if (!adDir.existsSync()) adDir.createSync(recursive: true);
    File('${adDir.path}/google-services.json').writeAsStringSync(androidJson);

    final ioDir = Directory('ios/config/$flavor');
    if (!ioDir.existsSync()) ioDir.createSync(recursive: true);
    File('${ioDir.path}/GoogleService-Info.plist').writeAsStringSync(iosPlist);
  }

  print("Firebase dummy configs generated successfully!");
}
