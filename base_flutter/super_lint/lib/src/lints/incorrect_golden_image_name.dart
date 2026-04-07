import 'package:collection/collection.dart';

import '../index.dart';

class IncorrectGoldenImageName extends CommonLintRule<_IncorrectGoldenImageNameOption> {
  IncorrectGoldenImageName(
    CustomLintConfigs configs,
  ) : super(
          RuleConfig(
            name: lintName,
            configs: configs,
            paramsParser: _IncorrectGoldenImageNameOption.fromMap,
            problemMessage: (_) =>
                'Golden image filename must start with parent group name and equal the test description',
          ),
        );

  static const String lintName = 'incorrect_golden_image_name';

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

    // Only process test files
    if (!resolver.path.endsWith('_test.dart')) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      // Check if this is a testWidget method call inside testGoldens
      if (node.methodName.name != 'testWidget') {
        return;
      }

      // Find the parent testGoldens call to get the test description
      AstNode? current = node.parent;
      MethodInvocation? testGoldensNode;
      String? testDescription;

      while (current != null) {
        if (current is MethodInvocation && current.methodName.name == 'testGoldens') {
          testGoldensNode = current;
          if (current.argumentList.arguments.isNotEmpty) {
            final firstArg = current.argumentList.arguments[0];
            if (firstArg is StringLiteral) {
              testDescription = firstArg.stringValue;
            }
          }
          break;
        }
        current = current.parent;
      }

      if (testDescription == null || testGoldensNode == null) {
        return;
      }

      // Find the nearest parent group() that contains this testGoldens
      String? groupName;
      current = testGoldensNode.parent;
      while (current != null) {
        if (current is MethodInvocation && current.methodName.name == 'group') {
          if (current.argumentList.arguments.isNotEmpty) {
            final firstArg = current.argumentList.arguments[0];
            if (firstArg is StringLiteral) {
              groupName = firstArg.stringValue;
            }
          }
          break;
        }
        current = current.parent;
      }

      // If no parent group, skip (filename rule is based on group name)
      if (groupName == null || groupName.isEmpty) {
        return;
      }

      // Find the filename argument in testWidget call
      final filenameArg = node.argumentList.arguments
          .whereType<NamedExpression>()
          .firstWhereOrNull((arg) => arg.name.label.name == 'filename');

      if (filenameArg?.expression is! StringLiteral) {
        return;
      }

      final filenameExpression = filenameArg!.expression as StringLiteral;
      final filenameValue = filenameExpression.stringValue;

      if (filenameValue == null) {
        return;
      }

      // Check Rule 1: filename must start with parent group name
      if (!filenameValue.startsWith('$groupName/')) {
        reporter.atNode(
          filenameExpression,
          code.copyWith(
            problemMessage:
                'Golden image filename must start with "$groupName/" (parent group name)',
          ),
        );
        return;
      }

      // Check Rule 2: the part after "$groupName/" must equal the test description
      final expected = '$groupName/$testDescription';
      if (filenameValue != expected) {
        reporter.atNode(
          filenameExpression,
          code.copyWith(
            problemMessage:
                'Golden image filename must equal "$expected" (group name / test description)',
          ),
        );
      }
    });
  }

  @override
  List<Fix> getFixes() => [
        _IncorrectGoldenImageNameFix(config),
      ];
}

class _IncorrectGoldenImageNameFix extends CommonQuickFix<_IncorrectGoldenImageNameOption> {
  _IncorrectGoldenImageNameFix(super.config);

  @override
  Future<void> run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) async {
    // Only handle in test files
    if (!resolver.path.endsWith('_test.dart')) return;

    context.registry.addMethodInvocation((node) {
      // Only handle testWidget calls
      if (node.methodName.name != 'testWidget') return;

      // Ensure the reported error is on this node's filename argument
      final filenameArg = node.argumentList.arguments
          .whereType<NamedExpression>()
          .firstWhereOrNull((a) => a.name.label.name == 'filename');
      if (filenameArg == null) return;

      final expr = filenameArg.expression;
      if (expr is! StringLiteral) return;

      if (!expr.sourceRange.intersects(analysisError.sourceRange)) return;

      // Locate the surrounding testGoldens to grab description
      AstNode? current = node.parent;
      MethodInvocation? testGoldensNode;
      String? testDescription;
      while (current != null) {
        if (current is MethodInvocation && current.methodName.name == 'testGoldens') {
          testGoldensNode = current;
          if (current.argumentList.arguments.isNotEmpty) {
            final firstArg = current.argumentList.arguments[0];
            if (firstArg is StringLiteral) {
              testDescription = firstArg.stringValue;
            }
          }
          break;
        }
        current = current.parent;
      }
      if (testDescription == null || testGoldensNode == null) return;

      // Find the nearest parent group() that contains this testGoldens
      String? groupName;
      current = testGoldensNode.parent;
      while (current != null) {
        if (current is MethodInvocation && current.methodName.name == 'group') {
          if (current.argumentList.arguments.isNotEmpty) {
            final firstArg = current.argumentList.arguments[0];
            if (firstArg is StringLiteral) {
              groupName = firstArg.stringValue;
            }
          }
          break;
        }
        current = current.parent;
      }
      if (groupName == null || groupName.isEmpty) return;

      final expected = '$groupName/$testDescription';

      final changeBuilder = reporter.createChangeBuilder(
        message: "Set filename to '$expected'",
        priority: 70,
      );
      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(expr.sourceRange, "'$expected'");
      });
    });
  }
}

class _IncorrectGoldenImageNameOption extends CommonLintParameter {
  const _IncorrectGoldenImageNameOption({
    super.excludes = const [],
    super.includes = const [],
    super.severity,
  });

  static _IncorrectGoldenImageNameOption fromMap(Map<String, dynamic> map) {
    return _IncorrectGoldenImageNameOption(
      excludes: safeCastToListString(map['excludes']),
      includes: safeCastToListString(map['includes']),
      severity: convertStringToErrorSeverity(map['severity']),
    );
  }
}
