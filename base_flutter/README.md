## Getting Started

### Requirements

- Flutter SDK: 3.38.7
- CocoaPods: 1.16.2
- JVM: 17+

### How to run

1. cd to root folder of project
2. Run `make gen_env`
3. Config [dart_defines](dart_defines) if any
4. Run `make sync`
5. Copy `.vscode/sample/settings.json` and paste to `.vscode/settings.json`
6. Run `make dummy_firebase` to generate dummy Firebase configs (prevents crash if no real credentials are provided).
7. (Optional) Replace dummy `google-services.json` in android/app/src/`{flavor_name}`/ and `GoogleService-Info.plist` in ios/config/`{flavor_name}`/ with real ones to enable Firebase features.
8. Run app via IDE
9. Install [lefthook](https://github.com/evilmartians/lefthook)
10. Run `lefthook install`
11. Install [fastlane](https://docs.fastlane.tools/getting-started/ios/setup/)
12. Run `make fastlane_update_plugins` if fastlane has been installed before

## How to init project (For Team Leader only)

- [1. Init Project](#1-init-project)
- [2. Config Dart Define](#2-config-dart-define)
- [3. Config Firebase](#3-config-firebase)
- [4. Config Lefthook](#4-config-lefthook)
- [5. Config Fastlane](#5-config-fastlane)
- [6. Generate All Pages](#6-generate-all-pages)
- [7. Generate App Colors](#7-generate-app-colors)
- [8. Generate App Text Styles](#8-generate-app-text-styles)

### 1. Init Project
- Fill the JSON values in the [setting_initial_config.md](setting_initial_config.md) file
- Run `make init`

### 2. Config Dart Define

- Share `.json` files in [dart_defines](dart_defines) to members

### 3. Config Firebase

- Share `google-services.json` and `GoogleService-Info.plist` to members *(Optional: Project has dummy files for trainees)*
- Check [How to run (step 6 & 7)](#How-to-run)

### 4. Config Lefthook

- Update commit message rule: [commit-msg.sh](.lefthook/commit-msg/commit-msg.sh)
- Update branch name rule: [pre-commit.sh](.lefthook/pre-commit/pre-commit.sh)

### 5. Config Fastlane

- Put the `.p8` file in folder [ios](ios)
- Update config values in [.env.default](.env.default)
- Share `.p8` file and [.env.default](.env.default) to members

### 6. Generate all pages
- Fill all pages need to be generated in [lib/ui/page/input_pages.md](lib/ui/page/input_pages.md) file
- Run `make gap` to generate all empty pages including `*.freezed.dart`, `*.gr.dart` files without running the command `make fb`

### 7. Generate app colors
- Make sure Figma MCP is running
- Use the [generate-app-colors command](.cursor/commands/generate-app-colors.md) with [figma_link] replaced by your Figma link to generate app colors in [lib/resource/app_colors.dart](lib/resource/app_colors.dart) file

### 8. Generate app text styles
- Make sure Figma MCP is running
- Use the [generate-app-text-styles command](.cursor/commands/generate-app-text-styles.md) with [figma_link] replaced by your Figma link to generate app text styles in [lib/resource/app_text_styles.dart](lib/resource/app_text_styles.dart) file
