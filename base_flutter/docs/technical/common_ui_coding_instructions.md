#### 1. Dimensions - Always use .rps extension
```dart
// GOOD - Responsive sizing
Container(
  width: 100.rps,
  height: 50.rps,
  margin: EdgeInsets.all(16.rps),
  padding: EdgeInsets.symmetric(horizontal: 12.rps, vertical: 8.rps),
  child: CommonText('Hello', style: style(color: color.onSurface, fontSize: 16.rps)),
)

// BAD - Fixed sizing
Container(
  width: 100,
  height: 50,
  margin: EdgeInsets.all(16),
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  child: Text('Hello', style: TextStyle(color: Colors.black, fontSize: 16)),
)
```

#### 2. Colors - Use color.*

Don't use Color(0xFF<hex_color>) or Colors.<color_name> directly, use color.<color_name> instead. If the <color_name> does not exist in AppColors(lib/resource/app_colors.dart), create it.

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  return Container(
    color: color.surface,
    child: CommonText(
      'Hello',
      style: TextStyle(color: color.onSurface),
    ),
  );
}
```

#### 3. Text Styles - Use style() helper

- If the text style does exist in AppTextStyle(lib/resource/app_text_style.dart) like regularNoneMedium, regularNoneRegular, regularTightBold, etc., use it directly.
- If the text style does not exist in AppTextStyle(lib/resource/app_text_style.dart), use the style() function like below:

```dart
CommonText(
  'Title',
  style: style(
    fontSize: 24.rps,
    fontWeight: FontWeight.w600,
    color: color.primary,
  ),
)
```

#### 4. Strings - Use `slang` package for localization

- Use t.<group>.<key> for strings
- `t` is already declared, just use it. Do not declare it again like `final t = Translations.of(context);`
- group name should be the same as the screen name in camelCase
- key name should be in camelCase

```dart
// GOOD - Localized strings
CommonText(t.home.welcomeMessage)
CommonAppBar.back(text: t.home.profileTitle)

// BAD - Hardcoded strings
CommonText('Welcome!')
CommonAppBar.back(text: 'Profile')
```

#### 5. Dummy Data - Use realistic values
```dart
// GOOD - Realistic dummy data
const mockUser = UserModel(
  id: 12345,
  name: '田中太郎',
  email: 'tanaka@example.com',
  phoneNumber: '090-1234-5678',
  birthDate: '1990-05-15',
  address: '東京都渋谷区神南1-1-1',
);

// BAD - Unrealistic dummy data
const mockUser = UserModel(
  id: 1,
  name: 'Test User',
  email: 'test@test.com',
);
```

#### 6. Always Use Common Components
- Prioritize using the common widgets available in lib/ui/component/ folder
      - Use CommonAppBar instead of AppBar
      - Use CommonDivider instead of Divider
      - Use CommonImage instead of Image, Icon or SvgPicture
      - Use CommonScaffold instead of Scaffold
      - Use CommonText instead of Text
      - Use Text.rich instead of RichText
      - Use CommonProgressIndicator instead of CircularProgressIndicator

- For local image, use CommonImage.svg() for .svg files and CommonImage.asset() for .png files with path image.<image_name>

```dart
// GOOD
CommonScaffold(
  appBar: CommonAppBar.back(),
  body: CommonContainer(
    child: CommonText('Hello'),
  ),
)

// BAD
Scaffold(
  appBar: AppBar(),
  body: Container(
    child: Text('Hello'),
  ),
)
```

#### 7. Strings from Figma

- Do not hardcode any strings, add all fixed strings that are not dynamic data to lib/resource/l10n/ja.i18n.json:
  - Key should be in camelCase. If the string already exists in any `.i18n.json` file, reuse it.
  - Key name should be translated from value to English. Example: "ifYouWishToCancelAfter24HoursPleaseCallTheOwnerDirectly": "24時間以降のキャンセルはサロンへ直接お電話ください", "jp": "JP"
- Don't translate the string to other languages, only translate the key name to English.
- Add the same key to all language files (ja, en, etc.) with appropriate translations
- After adding strings, run `make ln` to generate localization files
- In UI code, use t.<group>.<key> for strings.
- Some special strings that are not declared in the `.i18n.json` file — such as 'yyyy-MM-dd', '*', and others — should be declared in the lib/common/constant.dart file.

#### 8. Avoid deprecated APIs

- 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss.

```
// BAD
const Color(0xFF6A6565).withOpacity(0.1) // deprecated

// GOOD
const Color(0xFF6A6565).withValues(alpha: 0.1)
```

#### 9. Other Rules

- Keep helper widgets that belong to a page in the same file as private classes (prefix with `_`). Only move a widget to `lib/ui/component` when it is reused in multiple pages or becomes generic.

- Each feature directory under `lib/ui/page` must contain exactly three entry files: `<feature>_page.dart`, `<feature>_view_model.dart`, and `<feature>_state.dart`. Shared utilities go to their dedicated module folders (components, popups, shared) instead of adding more files inside the feature directory.

- UI files (pages and private widgets) must stay declarative. They can read state via providers and invoke view-model callbacks, but they cannot reach `appPreferences`, `appApiService`, `appDatabase`, or any other data-source/service directly. Move such logic to the view model or to a domain/service layer and expose only the data/state the UI needs.

- Prioritize using flutter_hooks: useScrollController() for scroll controllers, useTextEditingController() for text editing controllers,...

- One file has only one public widget class, do not create multiple public widget classes in one file, private classes are allowed

- Avoid duplicated code, create reusable widgets in lib/ui/component/ folder

- For input components like TextField, prioritize creating fields in the state and managing them in the ViewModel instead of using controllers directly in the Page

#### 10. Generate code from Figma Rules

- Search all images from design and check assets/images folder:
   - If matching file exists: Use it with CommonImage(lib/ui/component/ui_kit/common_image.dart) for next step
     - For .svg files: Use `CommonImage.svg()` constructor
     - For .png files: Use `CommonImage.asset()` constructor
   - If no matching file exists: Do not download the image to assets/images folder and do not use the image in the UI code

- Follow the spec in the *_spec.md file in [snake_case_screen_name] folder

- If the spec file specifies a component that does not exist, create it in lib/ui/component/ folder

- Text color must be same as Figma design

- Font size must be same as Figma design

- Layout/widget alignment must be the same as design

- Do not modify any existing strings, colors or images

- Use `make fb` instead of dart run build_runner build

- Use `make ln` to generate localization files after adding strings

- Use `make ga` to generate assets after adding images
