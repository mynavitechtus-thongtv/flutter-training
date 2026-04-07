# Custom Lint Implementation Guide

## Overview

This guide provides comprehensive guidelines for creating custom lint rules using the `super_lint` package.

## Quick Reference

| Step | Action | Files |
|------|--------|-------|
| 1 | Create rule | `super_lint/lib/src/rules/{lint_name}.dart` |
| 2 | Export rule | `super_lint/lib/src/index.dart` |
| 3 | Register rule | `super_lint/lib/super_lint.dart` |
| 4 | Create tests | `super_lint/example/lib/{lint_name}_test/` |
| 5 | Configure | `analysis_options.yaml` + `super_lint/example/analysis_options.yaml` |
| 6 | Update docs | [Super Lint Rules](./super_lint_rules.md) and [super_lint/README.md](../../super_lint/README.md) **(add at the end of list)** |

## Critical Rules

1. **Always use `CommonLintRule`** - Never use `DartLintRule` directly
2. **Extend `CommonLintParameter`** - For parameter handling and includes/excludes
3. **Never use deprecated APIs** - Check docs and similar lint rules when deprecated
4. **Use `RuleConfig`** - For proper configuration handling
5. **Provide quick fixes** - Implement `CommonQuickFix` for auto-correction

## File Structure Requirements

### 1. Core Lint Implementation

**Create lint rule file**: `super_lint/lib/src/lints/{lint_name}.dart`

```dart
import '../index.dart';

class YourLintRule extends CommonLintRule<_YourLintRuleParameter> {
  YourLintRule(
    CustomLintConfigs configs,
  ) : super(
          RuleConfig(
            name: 'your_lint_rule',
            configs: configs,
            paramsParser: _YourLintRuleParameter.fromMap,
            problemMessage: (_) => 'Your problem message here',
          ),
        );

  @override
  Future<void> check(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
    String rootPath,
  ) async {
    final code = this.code.copyWith(
          errorSeverity: parameters.severity ?? this.code.errorSeverity,
        );

    // Implementation here - use context.registry
    context.registry.addMethodInvocation((node) {
      // Your logic
      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [
        _YourLintRuleFix(config),
      ];
}

class _YourLintRuleFix extends CommonQuickFix<_YourLintRuleParameter> {
  _YourLintRuleFix(super.config);

  @override
  Future<void> run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) async {
    // Quick fix implementation
    context.registry.addMethodInvocation((node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Fix message',
        priority: 70,
      );
      
      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.sourceRange, 'fixed code');
      });
    });
  }
}

class _YourLintRuleParameter extends CommonLintParameter {
  const _YourLintRuleParameter({
    super.excludes = const [],
    super.includes = const [],
    super.severity,
    // Add custom parameters here
  });

  static _YourLintRuleParameter fromMap(Map<String, dynamic> map) {
    return _YourLintRuleParameter(
      excludes: safeCastToListString(map['excludes']),
      includes: safeCastToListString(map['includes']),
      severity: convertStringToErrorSeverity(map['severity']),
      // Parse custom parameters here
    );
  }
}
```

**Export the rule**: Add to `super_lint/lib/src/index.dart`

```dart
export 'lints/your_lint_rule.dart';
```

**Register the rule**: Add to `super_lint/lib/super_lint.dart`

```dart
import 'src/lints/your_lint_rule.dart';

PluginBase createPlugin() => _SuperLintPlugin();

class _SuperLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    // ... existing rules
    YourLintRule(configs),  // Note: Pass configs, not const
  ];
}
```

### 2. Test Implementation

**Create test file**: `super_lint/example/lib/{lint_name}_test/`

Test files must include two sections:

```dart
// THE FOLLOWING CASES SHOULD NOT BE WARNED
void validCase1() {
  // Valid code example
}

// THE FOLLOWING CASES SHOULD BE WARNED
void invalidCase1() {
  // expect_lint: your_lint_rule
  // Invalid code that should trigger the lint
}
```

**Verify tests**: Run from `super_lint/example`

```bash
cd super_lint/example
dart run custom_lint
```

### 3. Configuration

**Main config**: `analysis_options.yaml`

```yaml
custom_lint:
  rules:
    - your_lint_rule
```

**Example config with options**: `super_lint/example/analysis_options.yaml`

```yaml
custom_lint:
  rules:
    - your_lint_rule:
        option1: value1
        option2: value2
```

### 4. Documentation

Update both documentations:
- **[Super Lint Rules](./super_lint_rules.md)**: Add rule summary (1-2 lines) at the end of the list
- **[super_lint/README.md](../../super_lint/README.md)**: Add detailed examples with Good/Bad cases

**[!] Important**: Always add new rules **at the end** of the list, not in the middle with a specific number.
- Example: If there are 39 rules, the new rule should be #40
- Never renumber existing rules

## Implementation Guidelines

### 1. Research First
- **ALWAYS** search for similar existing lint rules in `super_lint/lib/src/lints/`
- Study their setup and implementation patterns
- Follow the exact structure of existing rules

### 2. Handle Deprecated APIs
- **NEVER use deprecated APIs** in implementation
- **Check API documentation** when you encounter deprecation warnings
- **Study similar lint rules** to see how they handle the same API
- **Use replacement APIs** as recommended in deprecation messages
- Example: If `DartLintRule` was deprecated, check how other rules use `CommonLintRule`

### 3. Architecture
- **Always use `CommonLintRule<T>`** where T extends `CommonLintParameter`
- **Use `RuleConfig`** for configuration handling
- **Provide `CommonQuickFix`** for auto-correction
- **Use `context.registry`** for AST traversal
- **Never use `DartLintRule` directly**

### 4. Code Quality
- No compilation errors
- No deprecated API usage
- Follow project conventions
- All imports from `'../index.dart'`

### 4. Test Coverage
- **Valid cases**: Code that should NOT trigger the lint
- **Invalid cases**: Code that SHOULD trigger the lint (use `// expect_lint: <lint_name>`)

## Best Practices

### Naming Conventions
- Use snake_case for lint rule names
- Use descriptive names: `avoid_*`, `prefer_*`, `require_*`

### Error Messages
- Write clear, actionable error messages
- Provide specific correction guidance
- Include examples when helpful

### Performance
- Avoid expensive operations
- Use appropriate visitor patterns for AST traversal
- Cache expensive computations

## Validation Checklist

Before submitting:

- [ ] All required files created/modified
- [ ] Code compiles without errors
- [ ] Test file includes valid and invalid cases
- [ ] Configuration set up in both analysis_options.yaml files
- [ ] Rule properly exported and registered
- [ ] Error messages are clear and actionable
- [ ] No deprecated APIs used
- [ ] Code follows project conventions
- [ ] Documentation updated in README.md (added at the end of list)
- [ ] Tests pass: `cd super_lint/example && dart run custom_lint`

## Example: Complete Implementation

### Step 1: Create Rule

```dart
// super_lint/lib/src/lints/prefer_const_constructor.dart
import '../index.dart';

class PreferConstConstructor extends CommonLintRule<_PreferConstConstructorParameter> {
  PreferConstConstructor(
    CustomLintConfigs configs,
  ) : super(
          RuleConfig(
            name: 'prefer_const_constructor',
            configs: configs,
            paramsParser: _PreferConstConstructorParameter.fromMap,
            problemMessage: (_) => 'Prefer using const constructors when possible',
          ),
        );

  @override
  Future<void> check(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
    String rootPath,
  ) async {
    final code = this.code.copyWith(
          errorSeverity: parameters.severity ?? this.code.errorSeverity,
        );

    context.registry.addInstanceCreationExpression((node) {
      // Check if can be const
      if (!node.isConst && /* can be const logic */) {
        reporter.atNode(node, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [
        _PreferConstConstructorFix(config),
      ];
}

class _PreferConstConstructorFix extends CommonQuickFix<_PreferConstConstructorParameter> {
  _PreferConstConstructorFix(super.config);

  @override
  Future<void> run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) async {
    context.registry.addInstanceCreationExpression((node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add const keyword',
        priority: 70,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(node.offset, 'const ');
      });
    });
  }
}

class _PreferConstConstructorParameter extends CommonLintParameter {
  const _PreferConstConstructorParameter({
    super.excludes = const [],
    super.includes = const [],
    super.severity,
  });

  static _PreferConstConstructorParameter fromMap(Map<String, dynamic> map) {
    return _PreferConstConstructorParameter(
      excludes: safeCastToListString(map['excludes']),
      includes: safeCastToListString(map['includes']),
      severity: convertStringToErrorSeverity(map['severity']),
    );
  }
}
```

### Step 2: Export

```dart
// super_lint/lib/src/index.dart
export 'lints/prefer_const_constructor.dart';
```

### Step 3: Register

```dart
// super_lint/lib/super_lint.dart
import 'src/lints/prefer_const_constructor.dart';

class _SuperLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    PreferConstConstructor(configs),  // Pass configs
  ];
}
```

### Step 4: Create Tests

```dart
// super_lint/example/lib/prefer_const_constructor_test/test.dart

// THE FOLLOWING CASES SHOULD NOT BE WARNED
const widget = MyWidget();

// THE FOLLOWING CASES SHOULD BE WARNED
// expect_lint: prefer_const_constructor
final widget = MyWidget();
```

### Step 5: Configure

```yaml
# analysis_options.yaml
custom_lint:
  rules:
    - prefer_const_constructor
```

### Step 6: Update Documentation

Add rule to both files **at the end of the list**:
- **[Super Lint Rules](./super_lint_rules.md)**: Add summary (1-2 lines)
- **[super_lint/README.md](../../super_lint/README.md)**: Add detailed examples
- If there are 39 rules, this will be rule #40
- Never insert in the middle or renumber existing rules

### Step 7: Test

```bash
cd super_lint/example
dart run custom_lint
```

## Common Patterns

### Using Context Registry

```dart
// For method invocations
context.registry.addMethodInvocation((node) {
  if (node.methodName.name == 'targetMethod') {
    reporter.atNode(node, code);
  }
});

// For instance creations (constructors)
context.registry.addInstanceCreationExpression((node) {
  if (node.constructorName.type.toString() == 'Widget') {
    reporter.atNode(node, code);
  }
});

// For string literals
context.registry.addSimpleStringLiteral((node) {
  if (node.value.isEmpty) {
    reporter.atNode(node, code);
  }
});

// For variable declarations
context.registry.addVariableDeclaration((node) {
  reporter.atNode(node, code);
});
```

### Custom Parameters

```dart
class _MyLintParameter extends CommonLintParameter {
  const _MyLintParameter({
    super.excludes = const [],
    super.includes = const [],
    super.severity,
    this.maxLength = 100,  // Custom parameter
    this.bannedWords = const [],  // Custom list
  });

  final int maxLength;
  final List<String> bannedWords;

  static _MyLintParameter fromMap(Map<String, dynamic> map) {
    return _MyLintParameter(
      excludes: safeCastToListString(map['excludes']),
      includes: safeCastToListString(map['includes']),
      severity: convertStringToErrorSeverity(map['severity']),
      maxLength: map['max_length'] as int? ?? 100,
      bannedWords: safeCastToListString(map['banned_words']),
    );
  }
}
```

### Configuration in analysis_options.yaml

```yaml
custom_lint:
  rules:
    - my_lint_rule:
        severity: error
        max_length: 50
        banned_words:
          - forbidden
          - deprecated
        excludes:
          - '**/*_test.dart'
          - '**/generated/**'
        includes:
          - 'lib/**'
```
