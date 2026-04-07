# Common Coding Rules

## Flutter & Dart Standards

- Follow Flutter version 3.35.6 documentation
- Do not use deprecated APIs
- Follow Flutter & Dart Best Practices in [flutter_dart_instructions.md](flutter_dart_instructions.md)
- Follow all flutter_lints rules declared in [flutter_lints_rules.md](./flutter_lints_rules.md)
- Follow all custom_lint rules declared in [Super Lint Rules](./super_lint_rules.md)

## Code Quality Standards

- **Line length**: Maximum 100 characters
- **No compile errors**: Code must compile successfully
- **No linter errors**: All linter rules must pass
- **Consistent formatting**: Follow project formatting standards
- **Naming conventions**: Follow rules in [naming_rules.md](naming_rules.md)

## Import and Export Rules

### Export Rules
- All public APIs/files must be exported through index.dart
- Keep index.dart organized and up-to-date
- Run `make ep` to auto-generate exports

### Import Rules

- Always use relative imports index.dart

```dart
// GOOD
import '../../../index.dart';
```
```dart 
// BAD
import '../models/user.dart';
import './widgets/button.dart';
```

- If there are any compile errors when importing `index.dart`, try running `make ep`.

## Security Guidelines

- Never hardcode secrets or API keys
- Use encryption for sensitive data storage
- Follow OWASP guidelines for mobile security
- Store sensitive config in environment variables or secure storage

## Make Commands

Prioritize using make commands instead of flutter commands directly:

```bash
# Get packages for all modules
make pg

# Run build_runner for code generation
make fb

# Format code
make fm

# Check lint
make sl

# Generate assets (images, fonts, etc.)
make ga

# Generate localization files
make ln

# Export all files to index.dart
make ep

# Run golden tests
flutter test [test_path] --tags=golden

# Update golden test files
flutter test [test_path] --update-goldens --tags=golden
```

## Before Finishing

- **If there are any `.dart` files changed**: Run `make fm` and `make ep` to format code and export all files to index.dart
- If `make fm` or `make ep` results in an error, just acknowledge the error and continue without investigating it
