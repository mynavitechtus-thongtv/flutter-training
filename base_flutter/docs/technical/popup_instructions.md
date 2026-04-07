# Popup Instructions

## Common Rules

- Follow the instructions in [common_ui_coding_instructions.md](common_ui_coding_instructions.md)

## Popup-Specific Rules

### 1. Factory Constructor Pattern

Each popup should have **ONE private constructor** and **multiple factory constructors** (one for each Figma design variant).

**Structure:**
```dart
// lib/ui/popup/confirm_dialog/confirm_dialog.dart
class ConfirmDialog extends BasePopup {
  // 1. Private constructor with ALL possible parameters
  const ConfirmDialog._({
    super.key,
    this.title,
    this.message,
    this.iconPath,
    this.confirmButtonText,
    this.doOnConfirm,
    this.cancelButtonText,
    this.isSecondaryFilledCancelButton = false,
    this.doOnCancel,
    this.isHorizontalButtons = false,
    this.isTransparentCancelButtons = false,
  }) : super(popupId: 'ConfirmDialog_${title ?? ''}_${message ?? ''}');

  final String? title;
  final String? message;
  final String? iconPath;
  final String? confirmButtonText;
  final VoidCallback? doOnConfirm;
  final String? cancelButtonText;
  final bool? isSecondaryFilledCancelButton;
  final VoidCallback? doOnCancel;
  final bool? isHorizontalButtons;
  final bool? isTransparentCancelButtons;

  // 2. Factory constructor for each Figma design
  
  /// Factory method for password reset completed dialog
  /// Creates a confirm dialog specifically for password reset completion
  factory ConfirmDialog.passwordResetCompleted({
    required VoidCallback doOnConfirm,
  }) {
    return ConfirmDialog._(
      title: t.passwordUpdated.title,
      message: t.passwordUpdated.description,
      iconPath: Assets.images.success,
      confirmButtonText: t.passwordUpdated.backToLogin,
      doOnConfirm: doOnConfirm,
    );
  }

  /// Factory method for error dialog
  /// Creates a confirm dialog specifically for error messages
  factory ConfirmDialog.error({
    required VoidCallback doOnConfirm,
    String? customMessage,
  }) {
    return ConfirmDialog._(
      title: t.confirmDialog.error.title,
      message: customMessage ?? t.confirmDialog.error.message,
      iconPath: Assets.images.error,
      confirmButtonText: t.confirmDialog.error.confirmButtonText,
      doOnConfirm: doOnConfirm,
    );
  }

  /// Factory method for account verification required dialog
  /// Creates a confirm dialog with two buttons (confirm and cancel)
  factory ConfirmDialog.accountVerificationRequired() {
    return ConfirmDialog._(
      title: t.verifyAccount.title,
      message: t.verifyAccount.message,
      confirmButtonText: t.verifyAccount.button,
      cancelButtonText: t.common.cancel,
      isTransparentCancelButtons: true,
      isHorizontalButtons: false,
    );
  }

  /// Factory method for discard changes dialog
  /// Creates a confirm dialog with horizontal buttons
  factory ConfirmDialog.discardChanges({
    required VoidCallback doOnConfirm,
  }) {
    return ConfirmDialog._(
      title: t.confirmDialog.discardChanges.title,
      message: t.confirmDialog.discardChanges.message,
      confirmButtonText: t.confirmDialog.discardChanges.confirmButtonText,
      cancelButtonText: t.common.cancel,
      isSecondaryFilledCancelButton: true,
      isHorizontalButtons: true,
      doOnConfirm: doOnConfirm,
    );
  }

  @override
  Widget buildPopup(BuildContext context) {
    // Implementation...
  }
}
```

**Usage:**
```dart
// lib/ui/page/login/view_model/login_view_model.dart
class LoginViewModel extends BaseViewModel<LoginState> {
  Future<void> _showRequestVerifyAccountDialog() async {
    final result = await _ref.nav.showDialog<bool>(
      ConfirmDialog.accountVerificationRequired(),
      barrierDismissible: false,
      canPop: false,
    );

    if (result == true) {
      // Handle confirm action
      await _ref.nav.push(/* ... */);
    }
  }

  Future<void> _showDiscardChangesDialog() async {
    final result = await _ref.nav.showDialog<bool>(
      ConfirmDialog.discardChanges(
        doOnConfirm: () {
          // Handle discard action
        },
      ),
    );
  }
}
```

**Key Points:**
- **One private constructor** (`_`) with all parameters
- **One factory constructor per Figma design** (named descriptively)
- Each factory returns `PopupClassName._(...)` with specific parameters
- Add documentation comment for each factory explaining its purpose
- Use `ref.nav.showDialog(PopupName.factoryConstructorName(...))` to display

### 2. Scrollable Content Structure

For dialogs with many options or long content, use this specific structure:

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    // Title section (fixed at top)
    Padding(
      padding: EdgeInsets.all(16.rps),
      child: CommonText(
        title,
        style: style(
          fontSize: 18.rps,
          fontWeight: FontWeight.bold,
          color: color.onSurface,
        ),
      ),
    ),
    
    // Scrollable content area
    Flexible(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // List of options, long text, etc.
          ],
        ),
      ),
    ),
    
    // Buttons section (fixed at bottom, always visible)
    Padding(
      padding: EdgeInsets.all(16.rps),
      child: Row(
        children: [
          Expanded(
            child: CommonButton.text(
              text: t.common.cancel,
              onPressed: () => ref.nav.pop(),
            ),
          ),
          SizedBox(width: 8.rps),
          Expanded(
            child: CommonButton.text(
              text: t.common.confirm,
              onPressed: onConfirm,
            ),
          ),
        ],
      ),
    ),
  ],
)
```

### 3. Flexibility and Parameters

- Make the popup flexible with parameters for different use cases
- Add proper documentation comments for the popup
- Ensure the popup can be customized without creating duplicate code

```dart
/// A reusable confirmation dialog that can display success, error, or info messages.
///
/// Usage:
/// ```dart
/// await ref.nav.showDialog(
///   ConfirmDialog.success(
///     message: 'Your changes have been saved',
///     onConfirm: () => ref.nav.pop(),
///   ),
/// );
/// ```
class ConfirmDialog extends HookConsumerWidget {
  // Implementation...
}
```

### 4. Golden Tests

- Create **one test group for EACH factory constructor**
- Each factory constructor group contains **2 sub-groups**: `happy` and `unhappy`
- Group name = factory constructor name (or "default" for single constructor)
- Generate snapshots for all test cases

#### Multiple Factory Constructors

```dart
// test/widget_test/ui/popup/confirm_dialog/confirm_dialog_test.dart
void main() {
  group('passwordResetCompleted', () {
    group('happy', () {
      testGoldens('default state', (tester) async {
        await tester.testWidget(
          filename: 'confirm_dialog/passwordResetCompleted/default state',
          widget: ConfirmDialog.passwordResetCompleted(
            doOnConfirm: () {},
          ),
        );
      });
    });

    group('unhappy', () {
      testGoldens('with very long message', (tester) async {
        await tester.testWidget(
          filename: 'confirm_dialog/passwordResetCompleted/with very long message',
          widget: ConfirmDialog.passwordResetCompleted(
            doOnConfirm: () {},
          ),
        );
      });
    });
  });

  group('error', () {
    group('happy', () {
      testGoldens('default state', (tester) async {
        await tester.testWidget(
          filename: 'confirm_dialog/error/default state',
          widget: ConfirmDialog.error(
            doOnConfirm: () {},
          ),
        );
      });

      testGoldens('with custom message', (tester) async {
        await tester.testWidget(
          filename: 'confirm_dialog/error/with custom message',
          widget: ConfirmDialog.error(
            doOnConfirm: () {},
            customMessage: 'Custom error message here',
          ),
        );
      });
    });

    group('unhappy', () {
      testGoldens('with extremely long error message', (tester) async {
        await tester.testWidget(
          filename: 'confirm_dialog/error/with extremely long error message',
          widget: ConfirmDialog.error(
            doOnConfirm: () {},
            customMessage: 'This is a very long error message that should test '
                'how the dialog handles text overflow and multiple lines. '
                'It should wrap properly and not break the UI layout.',
          ),
        );
      });
    });
  });

  group('accountVerificationRequired', () {
    group('happy', () {
      testGoldens('default state with two buttons', (tester) async {
        await tester.testWidget(
          filename: 'confirm_dialog/accountVerificationRequired/default state',
          widget: ConfirmDialog.accountVerificationRequired(),
        );
      });
    });

    group('unhappy', () {
      testGoldens('with very long title and message', (tester) async {
        await tester.testWidget(
          filename: 'confirm_dialog/accountVerificationRequired/long content',
          widget: ConfirmDialog.accountVerificationRequired(),
        );
      });
    });
  });

  group('discardChanges', () {
    group('happy', () {
      testGoldens('default state with horizontal buttons', (tester) async {
        await tester.testWidget(
          filename: 'confirm_dialog/discardChanges/default state',
          widget: ConfirmDialog.discardChanges(
            doOnConfirm: () {},
          ),
        );
      });
    });

    group('unhappy', () {
      testGoldens('with very long button text', (tester) async {
        await tester.testWidget(
          filename: 'confirm_dialog/discardChanges/long button text',
          widget: ConfirmDialog.discardChanges(
            doOnConfirm: () {},
          ),
        );
      });
    });
  });
}
```

#### Single Constructor (Use "default")

For popups with only one constructor (no factory constructors), use `default` as the group name:

```dart
// test/widget_test/ui/popup/loading_dialog/loading_dialog_test.dart
void main() {
  group('default', () {
    group('happy', () {
      testGoldens('default state', (tester) async {
        await tester.testWidget(
          filename: 'loading_dialog/default/default state',
          widget: const LoadingDialog(),
        );
      });

      testGoldens('with custom message', (tester) async {
        await tester.testWidget(
          filename: 'loading_dialog/default/with custom message',
          widget: const LoadingDialog(
            message: 'Loading data...',
          ),
        );
      });
    });

    group('unhappy', () {
      testGoldens('with very long message', (tester) async {
        await tester.testWidget(
          filename: 'loading_dialog/default/with very long message',
          widget: const LoadingDialog(
            message: 'This is a very long loading message that should test '
                'how the dialog handles text overflow and wrapping properly.',
          ),
        );
      });
    });
  });
}
```

**Test Group Guidelines:**
- **Group name = factory constructor name** (e.g., `passwordResetCompleted`, `error`) or `default`
- **happy group**: Normal/expected use cases with typical data
- **unhappy group**: Edge cases (long text, empty states, overflow scenarios)
- **Filename format**: `popup_name/factoryConstructorName/test description`
- Test ALL factory constructors
- Test ALL parameter variations for each factory
