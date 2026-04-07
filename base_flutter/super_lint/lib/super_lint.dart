import 'src/index.dart';

PluginBase createPlugin() => _SuperLintPlugin();

class _SuperLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      AvoidUnnecessaryAsyncFunction(configs),
      PreferNamedParameters(configs),
      PreferIsEmptyString(configs),
      PreferIsNotEmptyString(configs),
      PreferAsyncAwait(configs),
      TestFolderMustMirrorLibFolder(configs),
      AvoidHardCodedColors(configs),
      PreferCommonWidgets(configs),
      AvoidHardCodedStrings(configs),
      IncorrectParentClass(configs),
      PreferImportingIndexFile(configs),
      AvoidUsingTextStyleConstructorDirectly(configs),
      IncorrectScreenNameParameterValue(configs),
      IncorrectEventParameterName(configs),
      IncorrectEventParameterType(configs),
      IncorrectEventName(configs),
      IncorrectScreenNameEnumValue(configs),
      AvoidDynamic(configs),
      AvoidUsingEnumNameAsKey(configs),
      AvoidUsingUnsafeCast(configs),
      MissingRunCatching(configs),
      UtilFunctionsMustBeStatic(configs),
      MissingCommonScrollbar(configs),
      IncorrectFreezedDefaultValueType(configs),
      PreferSingleWidgetPerFile(configs),
      RequireMatchingFileAndClassName(configs),
      MissingGoldenTest(configs),
      MissingTestGroup(configs),
      AvoidUsingDateTimeNow(configs),
      IncorrectGoldenImageName(configs),
    ];
  }
}
