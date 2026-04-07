import 'dart:io';

void main(List<String> args) {
  final forceEnable = args.contains('--force-enable') || args.contains('-f');

  if (forceEnable) {
    print('🚀 Force Enable Custom Lint...\n');
  } else {
    print('🔄 Toggle Custom Lint Configuration...\n');
  }

  final projectRoot = Directory.current;
  final rootPath = projectRoot.path;

  final targets = [
    _PubspecTarget('Shared app', '$rootPath/apps/shared/pubspec.yaml'),
    _PubspecTarget('Salon app', '$rootPath/apps/salon_app/pubspec.yaml'),
    _PubspecTarget('User app', '$rootPath/apps/user_app/pubspec.yaml'),
    _PubspecTarget('Super lint package', '$rootPath/packages/super_lint/pubspec.yaml'),
  ];

  final missingTargets = <_PubspecTarget>[];
  final existingTargets = <_PubspecTarget>[];

  for (final target in targets) {
    if (target.file.existsSync()) {
      existingTargets.add(target);
    } else {
      missingTargets.add(target);
    }
  }

  if (existingTargets.isEmpty) {
    print('❌ Error: Unable to locate any target pubspec.yaml files.');
    exit(1);
  }

  for (final target in missingTargets) {
    print(
      '⚠️  Skipping ${target.label} '
      '(${target.relativePath(rootPath)}): file not found.',
    );
  }

  final primaryContent = existingTargets.first.file.readAsStringSync();
  final isCurrentlyEnabled = _isCustomLintEnabled(primaryContent);
  final desiredState = forceEnable ? true : !isCurrentlyEnabled;

  print('📊 Current state: ${isCurrentlyEnabled ? "ENABLED ✅" : "DISABLED ❌"}');
  print('🎯 Target state: ${desiredState ? "ENABLED ✅" : "DISABLED ❌"}\n');

  for (final target in existingTargets) {
    final file = target.file;
    final originalContent = file.readAsStringSync();
    final updatedContent = _setCustomLintState(originalContent, desiredState);

    if (originalContent == updatedContent) {
      print('ℹ️  No changes needed: ${target.relativePath(rootPath)}');
      continue;
    }

    file.writeAsStringSync(updatedContent);
    print('✅ Updated: ${target.relativePath(rootPath)}');
  }

  print('\n🎉 Custom lint is now: ${desiredState ? "ENABLED ✅" : "DISABLED ❌"}');
  print('\n💡 Next steps: Restart Dart Analysis Server');
}

bool _isCustomLintEnabled(String content) {
  final lines = content.split('\n');
  var inDevDependencies = false;

  for (final line in lines) {
    if (line.trim() == 'dev_dependencies:') {
      inDevDependencies = true;
      continue;
    }

    if (inDevDependencies && line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('\t')) {
      inDevDependencies = false;
    }

    if (!inDevDependencies) {
      continue;
    }

    if (_lineTargetsKey(line, 'custom_lint:') && !_isCommented(line)) {
      return true;
    }
  }

  return false;
}

String _setCustomLintState(String content, bool shouldEnable) {
  final lines = content.split('\n');
  final result = <String>[];

  var inDevDependencies = false;
  var expectingSuperLintPath = false;

  for (final line in lines) {
    if (line.trim() == 'dev_dependencies:') {
      inDevDependencies = true;
      expectingSuperLintPath = false;
      result.add(line);
      continue;
    }

    if (inDevDependencies && line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('\t')) {
      inDevDependencies = false;
      expectingSuperLintPath = false;
    }

    if (!inDevDependencies) {
      result.add(line);
      continue;
    }

    final matchesCustomLint = _lineTargetsKey(line, 'custom_lint:');
    final matchesSuperLint = _lineTargetsKey(line, 'super_lint:');
    final matchesSuperLintPath = expectingSuperLintPath && _lineTargetsKey(line, 'path:');

    if (matchesSuperLint) {
      expectingSuperLintPath = true;
    } else if (!matchesSuperLintPath) {
      expectingSuperLintPath = false;
    }

    if (matchesCustomLint || matchesSuperLint || matchesSuperLintPath) {
      result.add(shouldEnable ? _uncommentLine(line) : _commentLine(line));
      if (matchesSuperLintPath) {
        expectingSuperLintPath = false;
      }
      continue;
    }

    result.add(line);
  }

  return result.join('\n');
}

bool _lineTargetsKey(String line, String key) {
  final trimmedLeft = line.trimLeft();

  if (trimmedLeft.startsWith('#')) {
    final uncommented = trimmedLeft.substring(1).trimLeft();
    return uncommented.startsWith(key);
  }

  return trimmedLeft.startsWith(key);
}

bool _isCommented(String line) {
  return line.trimLeft().startsWith('#');
}

String _commentLine(String line) {
  if (_isCommented(line)) {
    return line;
  }

  final trimmed = line.trimLeft();
  final indentLength = line.length - trimmed.length;
  final indent = line.substring(0, indentLength);
  return '$indent# ${trimmed.trimLeft()}';
}

String _uncommentLine(String line) {
  final trimmed = line.trimLeft();
  if (!trimmed.startsWith('#')) {
    return line;
  }

  final indentLength = line.length - trimmed.length;
  final indent = line.substring(0, indentLength);
  final content = trimmed.substring(1).trimLeft();
  return '$indent$content';
}

String _relativePath(String rootPath, String fullPath) {
  if (!fullPath.startsWith(rootPath)) {
    return fullPath;
  }

  final withoutRoot = fullPath.substring(rootPath.length);
  if (withoutRoot.startsWith(Platform.pathSeparator)) {
    return withoutRoot.substring(1);
  }

  return withoutRoot;
}

class _PubspecTarget {
  _PubspecTarget(this.label, this.path);

  final String label;
  final String path;

  File get file => File(path);

  String relativePath(String rootPath) => _relativePath(rootPath, path);
}
