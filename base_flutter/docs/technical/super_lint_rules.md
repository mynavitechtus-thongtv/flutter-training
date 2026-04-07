# Super Lint Rules

This document lists all custom lint rules in the `super_lint` package. Each entry summarizes the expectation enforced by the rule in this repository.

## Overview

The project uses custom lint rules specifically designed for coding standards and best practices. 

For implementation details, see [Custom Lint Implementation Guide](./custom_lint_instructions.md).

## Rule Reference

### 1. avoid_unnecessary_async_function

- **Summary**: Avoid creating async functions without asynchronous computation. Remove async keyword if no await is used.
- **Example**:
  ```dart
  // Incorrect
  Future<void> processData() async {
    final data = [1, 2, 3];
    data.forEach(print);  // No async operation
  }

  // Correct
  void processData() {
    final data = [1, 2, 3];
    data.forEach(print);
  }
  ```

### 2. prefer_named_parameters

- **Summary**: Use named parameters for functions or constructors with more than 2 parameters.
- **Example**:
  ```dart
  // Incorrect (3 positional parameters)
  void processUser(String name, int age, bool isActive) { ... }

  // Correct (3 named parameters)
  void processUser({
    required String name,
    required int age,
    required bool isActive,
  }) { ... }
  ```

### 3. prefer_is_empty_string

- **Summary**: Use .isEmpty instead of == '' to check for empty strings.
- **Example**:
  ```dart
  // Incorrect
  if (text == '') { ... }

  // Correct
  if (text.isEmpty) { ... }
  ```

### 4. prefer_is_not_empty_string

- **Summary**: Use .isNotEmpty instead of != '' to check for non-empty strings.
- **Example**:
  ```dart
  // Incorrect
  if (text != '') { ... }

  // Correct
  if (text.isNotEmpty) { ... }
  ```

### 5. incorrect_todo_comment

- **Summary**: TODO comments must include username, description, and issue number (#0 if no issue exists).
- **Example**:
  ```dart
  // Incorrect
  // TODO: Fix this later
  // TODO Fix bug

  // Correct
  // TODO(minh): Add error handling for network requests #123
  // TODO(minh): Refactor authentication logic #0
  ```

### 6. prefer_async_await

- **Summary**: Prefer async/await syntax over .then() invocations for better readability.
- **Example**:
  ```dart
  // Incorrect
  Future<String> fetchData() {
    return apiService.getData().then((data) {
      return data.toString();
    }).catchError((error) {
      print('Error: $error');
      return '';
    });
  }

  // Correct
  Future<String> fetchData() async {
    try {
      final data = await apiService.getData();
      return data.toString();
    } catch (error) {
      print('Error: $error');
      return '';
    }
  }
  ```

### 7. test_folder_must_mirror_lib_folder

- **Summary**: Test file names must end with '_test' and mirror the 'lib' folder structure.
- **Example**:
  ```
  lib/
  ├── ui/
  │   ├── page/
  │   │   ├── login_page.dart
  │   │   └── home_page.dart
  │   └── component/
  │       └── button.dart
  └── data_source/
      └── api_service.dart

  test/
  ├── unit_test/
  │   └── data_source/
  │       └── api_service_test.dart
  └── widget_test/
      ├── ui/
      │   ├── page/
      │   │   ├── login_page_test.dart
      │   │   └── home_page_test.dart
      │   └── component/
      │       └── button_test.dart
  ```

### 8. avoid_hard_coded_colors

- **Summary**: Avoid hard-coding colors except Colors.transparent; use color constants instead.
- **Example**:
  ```dart
  // Incorrect
  Container(
    color: Color(0xFFFF0000),  // Hard-coded color
    child: Text('Hello'),
  )

  // Incorrect
  Container(
    color: Colors.white,   // Use color constant
    child: Text('Hello'),
  )

  // Correct
  Container(
    color: color.primary,   // Use color
    child: CommonText('Hello'),
  )
  ```

### 9. prefer_common_widgets

- **Summary**: Use project-specific common widgets instead of basic Flutter widgets.
- **Example**:
  ```dart
  // Incorrect
  Scaffold(
    appBar: AppBar(title: Text('Title')),
    body: Center(child: Text('Content')),
  )

  // Correct
  CommonScaffold(
    title: 'Title',
    body: Center(child: CommonText('Content')),
  )
  ```

### 10. avoid_hard_coded_strings

- **Summary**: Use string constants or localization instead of hard-coded strings in UI components, pages, and view models.
- **Example**:
  ```dart
  // Incorrect
  CommonText('Welcome to our app!');  // Hard-coded string

  // Correct
  CommonText(Constant.welcomeMessage);  // Use string constant
  CommonText(t.login.welcomeMessage);       // Use localization
  ```

### 11. incorrect_parent_class

- **Summary**: Classes ending with 'Page' or 'PageState' must extend specific parent classes (BasePage, BaseStatefulPageState, or StatefulHookConsumerWidget).
- **Example**:
  ```dart
  // Correct
  class HomePage extends BasePage { ... }
  class LoginPageState extends BaseStatefulPageState { ... }

  // Incorrect
  class HomePage extends StatelessWidget { ... }  // Should extend BasePage
  class LoginPageState extends State { ... }      // Should extend BaseStatefulPageState
  ```

### 12. prefer_importing_index_file

- **Summary**: Import from index files instead of individual files for better organization.
- **Example**:
  ```dart
  // Incorrect
  import 'package:my_app/utils/date_utils.dart';
  import 'package:my_app/utils/string_utils.dart';
  import '../button.dart';

  // Correct
  import '../index.dart';  // All exports in one place
  ```

### 13. avoid_using_text_style_constructor_directly

- **Summary**: Use predefined text styles or style function instead of creating TextStyle directly.
- **Example**:
  ```dart
  // Incorrect
  CommonText(
    'Hello',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  )

  // Correct
  CommonText(
    'Hello',
    style: AppTextStyles.bodyMediumBold,
  )

  // Correct
  CommonText(
    'Hello',
    style: style(
      fontSize: 16.rps,
      fontWeight: FontWeight.bold,
      color: color.black,
    ),
  )
  ```

### 14. incorrect_screen_name_parameter_value

- **Summary**: Screen name parameter values must match the file name (converted to camelCase).
- **Example**:
  ```dart
  // In file: sign_up_page.dart
  // Incorrect
  SomeWidget(screenName: ScreenName.loginPage)

  // Correct
  SomeWidget(screenName: ScreenName.signUpPage)  // Matches file name
  ```

### 15. incorrect_event_parameter_name

- **Summary**: Event parameter names in ParameterConstants class must use snake_case naming.
- **Example**:
  ```dart
  // In ParameterConstants class
  // Incorrect
  static const String userName = 'user_name';
  static const String USER_ID = 'user_id';  // Not snake_case

  // Correct
  static const String user_name = 'user_name';
  static const String user_id = 'user_id';
  ```

### 16. incorrect_event_parameter_type

- **Summary**: Event parameters in AnalyticParameter classes must use only String, int, or double types.
- **Example**:
  ```dart
  class LoginEvent extends AnalyticParameter {
    @override
    Map<String, Object> get parameters => {
      'user_id': userId,        // String
      'login_count': 5,         // int
      'login_time': 123.45,     // double
      'is_premium': true,       // bool not allowed
      'device_info': device,    // Custom object not allowed
    };
  }
  ```

### 17. incorrect_event_name

- **Summary**: Event names in EventConstants class must use snake_case naming.
- **Example**:
  ```dart
  // In EventConstants class
  // Incorrect
  static const String userLogin = 'user_login';
  static const String USER_LOGOUT = 'user_logout';  // Not snake_case

  // Correct
  static const String user_login = 'user_login';
  static const String user_logout = 'user_logout';
  ```

### 18. incorrect_screen_name_enum_value

- **Summary**: ScreenName enum values must have correct screenEventPrefix (snake_case without '_page') and screenClass (UpperFirstCase) formats.
- **Example**:
  ```dart
  enum ScreenName {
    // Incorrect
    signUpPage(
      screenEventPrefix: 'sign_up_page',  // Should not end with '_page'
      screenClass: 'signUpPage',          // Should be UpperFirstCase
    ),

    // Correct
    signUpPage(
      screenEventPrefix: 'sign_up',       // snake_case without '_page'
      screenClass: 'SignUpPage',          // UpperFirstCase
    ),
  }
  ```

### 19. avoid_dynamic

- **Summary**: Avoid using dynamic type; use specific types or Object? instead.
- **Example**:
  ```dart
  // Incorrect
  void processData(dynamic data) {
    print(data.length);  // Runtime error if data has no length
  }

  // Correct
  void processData(Object? data) {
    if (data is List) {
      print(data.length);
    }
  }
  ```

### 20. avoid_nested_conditions

- **Summary**: Avoid deeply nested if statements and ternary operators; use early returns instead. Maximum allowed nesting level is 3.
- **Example**:
  ```dart
  // Correct (3 levels or less)
  void validateInput(String? input) {
    if (input == null) return;  // Level 1
    if (input.isEmpty) return;  // Level 1

    if (input.length > 10) {    // Level 1
      if (input.contains('@')) { // Level 2
        // Process valid input
      }
    }
  }

  // Incorrect (more than 3 levels)
  void processData(String? data) {
    if (data != null) {           // Level 1
      if (data.isNotEmpty) {      // Level 2
        if (data.length > 5) {    // Level 3
          if (data.startsWith('A')) { // Level 4 - VIOLATION!
            // Process data
          }
        }
      }
    }
  }
  ```

### 21. avoid_try_catch_in_shared_view_model

- **Summary**: Do not use try-catch in SharedViewModel; throw exceptions for runCatching to handle.
- **Example**:
  ```dart
  class MyViewModel extends SharedViewModel {
    // Incorrect
    void loadData() {
      try {
        final data = apiService.getData();
        // process data
      } catch (e) {
        // handle error
      }
    }

    // Correct
    void loadData() {
      // Throw exception, let runCatching handle it
      final data = apiService.getData();
      // process data
    }
  }
  ```

### 22. avoid_using_if_else_with_enums

- **Summary**: Use switch statements with enums instead of if-else chains.
- **Example**:
  ```dart
  enum Status { loading, success, error }

  // Incorrect
  void handleStatus(Status status) {
    if (status == Status.loading) {
      showLoading();
    } else if (status == Status.success) {
      showSuccess();
    } else if (status == Status.error) {
      showError();
    }
  }

  // Correct
  void handleStatus(Status status) => switch (status) {
    Status.loading => showLoading(),
    Status.success => showSuccess(),
    Status.error => showError(),
  };
  ```

### 23. avoid_using_unsafe_cast

- **Summary**: Avoid unsafe type casting with 'as'; use type checking with 'is' or 'safeCast' function instead.
- **Example**:
  ```dart
  // Incorrect
  void processData(dynamic data) {
    final list = data as List<String>;  // Unsafe cast
    print(list.first);
  }

  // Correct
  void processData(dynamic data) {
    if (data is List<String>) {  // Safe type check
      print(data.first);
    }
  }

  // Correct - use for dynamic type
  void processData(dynamic data) {
    final list = safeCast<List<String>>(data);
    print(list?.first);
  }

  // Correct - use for non-dynamic type
  void processData(Object data) {
    final list = data.safeCast<List<String>>();
    print(list?.first);
  }
  ```

### 24. missing_log_in_catch_block

- **Summary**: Catch blocks must include logging before rethrowing or handling errors.
- **Example**:
  ```dart
  // Incorrect
  try {
    riskyOperation();
  } catch (e) {
    // No logging
    rethrow;
  }

  // Correct
  try {
    riskyOperation();
  } catch (e) {
    Log.e('Error in riskyOperation', error: e);  // Log before handling
    rethrow;
  }
  ```

### 25. missing_run_catching

- **Summary**: Use runCatching for error handling instead of try-catch blocks in specific contexts.
- **Example**:
  ```dart
  // Incorrect
  try {
    final result = await apiCall();
    processResult(result);
  } catch (e) {
    handleError(e);
  }

  // Correct
  runCatching(action: () async {
    final result = await apiCall();
    processResult(result);
  });
  ```

### 26. util_functions_must_be_static

- **Summary**: Utility functions in util classes must be declared as static.
- **Example**:
  ```dart
  // Incorrect
  String formatDate(DateTime date) {
     return '${date.year}-${date.month}-${date.day}';
  }

  class DateUtils {
    // Correct
    static String formatDate(DateTime date) {
      return '${date.year}-${date.month}-${date.day}';
    }
  }
  ```

### 27. missing_extension_method_for_events

- **Summary**: Event classes must have corresponding extension methods.
- **Example**:
  ```dart
  class LoginEvent extends AnalyticParameter {
    // This event class needs a corresponding extension method
  }

  // Required extension method
  extension LoginEventExtension on LoginEvent {
    void track() {
      Analytics.track(this);
    }
  }
  ```

### 28. missing_common_scrollbar

- **Summary**: Use common scrollbar widget for scrollable content instead of basic widgets.
- **Example**:
  ```dart
  // Incorrect
  SingleChildScrollView(
    child: Column(
      children: [...],
    ),
  )

  // Correct
  CommonScaffold(
    body: CommonScrollbarWithIosStatusBarTapDetector(
        routeName: LoginRoute.name,
        controller: scrollController,
        child: SingleChildScrollView(
           controller: scrollController,
        ),
    ),
  )
  ```

### 29. incorrect_freezed_default_value_type

- **Summary**: Values passed to @Default() in freezed classes must have compatible types with annotated fields.
- **Example**:
  ```dart
  @freezed
  class User with _$User {
    const factory User({
      @Default('John') String name,      // Correct: String default for String field
      @Default(25) int age,              // Correct: int default for int field
      @Default('admin') String role,     // Correct: String default for String field
      @Default(0) String name,              // Incorrect: int default for String field
    }) = _User;
  }
  ```

### 30. prefer_single_widget_per_file

- **Summary**: Each file should contain only one widget class for better organization.
- **Example**:
  ```dart
  // Incorrect: Multiple widgets in one file
  // login_widgets.dart
  class LoginButton extends StatelessWidget { ... }
  class LoginTextField extends StatelessWidget { ... }

  // Correct: One widget per file
  // login_button.dart
  class LoginButton extends StatelessWidget { ... }

  // login_text_field.dart
  class LoginTextField extends StatelessWidget { ... }
  ```

### 31. require_matching_file_and_class_name

- **Summary**: File names must match the main class name using snake_case.
- **Example**:
  ```dart
  // Incorrect
  // Filename: user_profile_page.dart
  class UserProfile extends StatelessWidget { ... }

  // Correct
  // Filename: user_profile.dart
  class UserProfile extends StatelessWidget { ... }
  ```

### 32. missing_golden_test

- **Summary**: Widget files must have corresponding golden test files in the test folder.
- **Example**:
  ```
  # If you have these widget files:
  lib/ui/page/login_page.dart
  lib/ui/component/button.dart

  # You must have corresponding test files:
  test/widget_test/ui/page/login_page_test.dart
  test/widget_test/ui/component/button_test.dart
  ```

### 33. avoid_using_datetime_now

- **Summary**: Use DateTimeUtil.now instead of DateTime.now() for testability. In test widget files, use fixed DateTime values.
- **Example**:
  ```dart
  // Incorrect
  final now = DateTime.now();  // Not testable

  // Correct in production code
  final now = DateTimeUtil.now;  // Testable

  // Correct in test files
  final fixedTime = DateTime(2024, 1, 1);  // Fixed value for testing
  ```

### 34. empty_test_group

- **Summary**: Test groups must not be empty; include at least one test case.
- **Example**:
  ```dart
  // Incorrect
  group('Login tests', () {
    // No tests inside
  });

  // Correct
  group('Login tests', () {
    test('should validate email', () {
      // test implementation
    });
  });
  ```

### 35. incorrect_golden_image_name

- **Summary**: Golden image filenames must start with page name and match test description.
- **Example**:
  ```dart
  // Correct filename: [constructor name]/[test case].png

  // Incorrect filename: [test case].png (missing constructor name)
  ```

### 36. invalid_test_group_name

- **Summary**: Group name must be in the list of valid group names: happy, unhappy
- **Example**:
  ```dart
  // Correct
  group('happy', () { ... });
  group('unhappy', () { ... });

  // Incorrect
  group('normal', () { ... });     // Not in the list of valid group names
  ```

### 37. missing_test_group

- **Summary**: Test file must have one `group()` per constructor (default + factory/named) from the corresponding source file. The lint counts constructors in the lib file and requires the test file to have the same number of groups with matching names (e.g. class name for default, factory name for factory).
- **Example**:
  ```dart
  // Source: confirm_dialog.dart has ConfirmDialog (default), deleteAccount, logOut

  // Incorrect - missing groups for deleteAccount and logOut
  void main() {
    group('ConfirmDialog', () { ... });
  }

  // Correct - one group per constructor
  void main() {
    group('ConfirmDialog', () { ... });
    group('deleteAccount', () { ... });
    group('logOut', () { ... });
  }
  ```

### 38. avoid_using_enum_name_as_key

- **Summary**: Do not use enum names directly as keys in storage; use string constants to avoid issues when refactoring.
- **Example**:
  ```dart
  enum UserRole { admin, user, guest }

  // Incorrect
  prefs.setString(UserRole.admin.name, 'value');  // Direct enum name

  // Correct
  static const keyUserId = 'userId';
  prefs.setString(keyUserId, 'value');
  ```

-### 39. incorrect_i18n_group_name
-
- **Summary**: Enforces that each screen file only accesses its allowed i18n group. By default the allowed group is derived from the snake_case file name (e.g. `upload_file_page.dart` → `t.uploadFile.*`) plus `t.common.*`. Some files (like `login_page.dart`) use a custom mapping (`t.login.*`).
- **Example**:
  ```dart
  // Correct inside login_page.dart
  CommonText(t.login.passwordLabel);
  CommonText(t.common.ok);

  // Incorrect inside login_page.dart
  // expect_lint: incorrect_i18n_group_name
  CommonText(t.home.title);

  // Incorrect inside upload_file_page.dart
  // expect_lint: incorrect_i18n_group_name
  CommonText(t.uploadFile.uploadPhoto);
  ```
