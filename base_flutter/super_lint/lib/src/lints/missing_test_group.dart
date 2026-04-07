import '../index.dart';

class MissingTestGroup extends CommonLintRule<_MissingTestGroupOption> {
  MissingTestGroup(
    CustomLintConfigs configs,
  ) : super(
          RuleConfig(
            name: lintName,
            configs: configs,
            paramsParser: _MissingTestGroupOption.fromMap,
            problemMessage: (_) =>
                'Test file must have one group per constructor (default + factory/named) from the source file',
          ),
        );

  static const String lintName = 'missing_test_group';

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
    final currentPath = resolver.path;
    final relativeCurrentPath = relative(currentPath, from: rootPath).replaceAll(r'\', '/');

    // Only run on test files under test/widget_test
    if (!relativeCurrentPath.startsWith(parameters.testFolderPrefix.replaceAll(r'\', '/')) ||
        !currentPath.endsWith('_test.dart')) {
      return;
    }

    final libPath = _libPathFromTestPath(currentPath, rootPath);
    final libFile = File(libPath);
    if (!libFile.existsSync()) {
      return;
    }

    final constructorNames = _parseConstructorNamesFromLib(libFile.readAsStringSync());
    if (constructorNames.isEmpty) {
      return;
    }

    final requiredNames = constructorNames.toSet();

    context.registry.addCompilationUnit((unit) {
      final collector = _GroupNameCollector();
      unit.visitChildren(collector);
      final collected = collector.names;
      final missing = requiredNames.difference(collected);
      final extra = collected.difference(requiredNames);
      if (missing.isNotEmpty || extra.isNotEmpty) {
        final messages = <String>[];
        if (missing.isNotEmpty) {
          messages.add('missing group(s): ${missing.join(', ')}');
        }
        if (extra.isNotEmpty) {
          messages.add(
              'extra group(s): ${extra.join(', ')} (not in source: ${requiredNames.join(', ')})');
        }
        final errorCode = code.copyWith(
          problemMessage: 'Test must have one group per constructor. ${messages.join('; ')}',
        );
        if (collector.firstGroupNode != null) {
          reporter.atNode(collector.firstGroupNode!, errorCode);
        } else {
          reporter.atOffset(
            offset: 0,
            length: resolver.documentLength,
            errorCode: errorCode,
          );
        }
      }
    });
  }

  /// lib/ui/popup/confirm_dialog/confirm_dialog.dart from test/widget_test/ui/popup/confirm_dialog/confirm_dialog_test.dart
  String _libPathFromTestPath(String testPath, String rootPath) {
    final relativePath = relative(testPath, from: rootPath).replaceAll(r'\', '/');
    final parts = relativePath.split('/');
    final testFolderParts = parameters.testFolderPrefix.split('/');
    int libStartIndex = -1;
    for (var i = 0; i < parts.length; i++) {
      if (i + testFolderParts.length <= parts.length &&
          parts.sublist(i, i + testFolderParts.length).join('/') == testFolderParts.join('/')) {
        libStartIndex = i + testFolderParts.length;
        break;
      }
    }
    if (libStartIndex == -1) return '';
    final afterTest = parts.sublist(libStartIndex);
    if (afterTest.isEmpty) return '';
    final fileName = afterTest.last;
    if (!fileName.endsWith('_test.dart')) return '';
    final baseName = fileName.replaceFirst(RegExp(r'_test\.dart$'), '.dart');
    final libParts = ['lib', ...afterTest.sublist(0, afterTest.length - 1), baseName];
    return join(rootPath, libParts.join('/'));
  }

  /// Parse lib file content to get: public default constructor name (if any) + all factory constructor names.
  /// Only adds class name when there is a public default/named constructor (e.g. "ConfirmDialog(" or "const ConfirmDialog(").
  /// Private constructors (e.g. "ConfirmDialog._(") do not require a test group.
  List<String> _parseConstructorNamesFromLib(String content) {
    final names = <String>[];
    final classMatch =
        RegExp(r'class\s+(\w+)\s*(?:extends|implements|with|\{)').firstMatch(content);
    if (classMatch != null) {
      final className = classMatch.group(1)!;
      // Only add class name if there is a public default constructor: "ClassName(" or "const ClassName("
      // (not "ClassName._(" or "ClassName.name(" which are private or named)
      final hasPublicDefault = RegExp(
        r'(?:const\s+)?' + RegExp.escape(className) + r'\s*\(',
      ).hasMatch(content);
      if (hasPublicDefault) {
        names.add(className);
      }
    }
    // Factory: "factory ClassName.name("
    for (final m in RegExp(r'factory\s+\w+\.(\w+)\s*\(').allMatches(content)) {
      names.add(m.group(1)!);
    }
    return names;
  }

  @override
  List<Fix> getFixes() => [];
}

class _GroupNameCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};
  MethodInvocation? firstGroupNode;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'group' &&
        node.argumentList.arguments.isNotEmpty &&
        node.argumentList.arguments[0] is StringLiteral) {
      firstGroupNode ??= node;
      final value = (node.argumentList.arguments[0] as StringLiteral).stringValue;
      if (value != null && value.isNotEmpty) {
        names.add(value);
      }
    }
    super.visitMethodInvocation(node);
  }
}

class _MissingTestGroupOption extends CommonLintParameter {
  const _MissingTestGroupOption({
    super.excludes = const [],
    super.includes = const [],
    super.severity,
    this.testFolderPrefix = _defaultTestFolderPrefix,
  });

  final String testFolderPrefix;

  static const String _defaultTestFolderPrefix = 'test/widget_test';

  static _MissingTestGroupOption fromMap(Map<String, dynamic> map) {
    return _MissingTestGroupOption(
      excludes: safeCastToListString(map['excludes']),
      includes: safeCastToListString(map['includes']),
      severity: convertStringToErrorSeverity(map['severity']),
      testFolderPrefix: safeCast<String>(map['test_folder_prefix']) ?? _defaultTestFolderPrefix,
    );
  }
}
