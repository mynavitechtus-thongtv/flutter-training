import 'dart:convert';
import 'dart:io';

/// Tool to generate API methods from OpenAPI JSON specification
///
/// Usage: dart tools/dart_tools/lib/generate_api_from_openapi.dart [--input_path=path] [--apis=method_path,method_path] [--replace=true/false] [--output_path=path]

/// - input_path: path to the folder containing the OpenAPI JSON file
/// - apis: filter specific APIs by method and path (e.g., apis=get_v1/search,post_v2/city)
/// - replace: true to replace all code below marker, false to append (default: true)
/// - output_path: custom output directory (default: lib/data_source/api and lib/model/api)
void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ Error: Please provide folder path containing OpenAPI JSON file');
    print(
        'Usage: dart tools/dart_tools/lib/generate_api_from_openapi.dart [--input_path=path] [--apis=method_path,method_path] [--replace=true/false] [--output_path=path]');
    print('Examples:');
    print('  dart tools/dart_tools/lib/generate_api_from_openapi.dart --input_path=api_doc');
    print(
        '  dart tools/dart_tools/lib/generate_api_from_openapi.dart --input_path=api_doc --apis=get_v1/search,post_v2/city');
    print(
        '  dart tools/dart_tools/lib/generate_api_from_openapi.dart --input_path=api_doc --replace=false');
    print(
        '  dart tools/dart_tools/lib/generate_api_from_openapi.dart --input_path=api_doc --output_path=api_doc');
    exit(1);
  }

  // Parse additional arguments
  String? apisFilter;
  bool replace = true;
  String? outputPath;
  String? inputPath;
  String wrappedBy = 'data';

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--apis=')) {
      apisFilter = arg.substring(7);
    } else if (arg.startsWith('--replace=')) {
      final replaceStr = arg.substring(10).toLowerCase();
      replace = replaceStr == 'true';
    } else if (arg.startsWith('--output_path=')) {
      outputPath = arg.substring(14);
    } else if (arg.startsWith('--input_path=')) {
      inputPath = arg.substring(13);
    } else if (arg.startsWith('--wrapped_by=')) {
      final v = arg.substring(13).trim().toLowerCase();
      if (v == 'data' || v == 'results' || v == 'result') {
        wrappedBy = v == 'results' ? 'result' : v;
      }
    }
  }

  final generator = ApiGenerator();

  try {
    generator.generateFromFolder(
      inputPath!,
      apisFilter: apisFilter,
      replace: replace,
      outputPath: outputPath,
      wrappedBy: wrappedBy,
    );
    print('✅ Successfully generated API methods from OpenAPI!');
    print(
        '⚠️  WARNING: We only use _authAppServerApiClient for all APIs. For APIs that should use _noneAuthAppServerApiClient, you must manually modify them.');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

class ApiGenerator {
  static const String appApiServicePath = 'lib/data_source/api/app_api_service.dart';
  static const String modelApiPath = 'lib/model/api/respone';
  static const String requestModelPath = 'lib/model/api/request';
  static const String enumPath = 'lib/model/enum';
  static const String generatedMethodsMarker =
      '// GENERATED CODE - DO NOT MODIFY OR DELETE THIS COMMENT';

  late String _appApiServicePath;
  late String _modelApiPath;
  late String _requestModelPath;
  late String _enumPath;
  late bool _replace;
  late Set<String> _allowedApis;
  late String _wrappedBy;
  final Map<String, String> _schemaNameCache = {};
  final Set<String> _usedModelNames = {};
  final Map<String, String> _endpointResponseNameCache = {};
  final Map<String, String> _endpointArrayItemNameCache = {};

  void generateFromFolder(
    String folderPath, {
    String? apisFilter,
    bool replace = true,
    String? outputPath,
    String wrappedBy = 'data',
  }) {
    // Initialize configuration
    _replace = replace;
    _allowedApis = _parseApisFilter(apisFilter);
    _wrappedBy = wrappedBy;

    if (outputPath != null) {
      _appApiServicePath = '$outputPath/app_api_service.dart';
      _modelApiPath = '$outputPath/model';
      _requestModelPath = '$outputPath/request';
      _enumPath = '$outputPath/enum';
    } else {
      _appApiServicePath = appApiServicePath;
      _modelApiPath = modelApiPath;
      _requestModelPath = requestModelPath;
      _enumPath = enumPath;
    }
    print('📁 Checking folder: $folderPath');
    if (_allowedApis.isNotEmpty) {
      print('🔍 Filtering APIs: ${_allowedApis.join(', ')}');
    }
    print('🔄 Replace mode: $_replace');
    print('📂 Output paths:');
    print('  - API Service: $_appApiServicePath');
    print('  - Response Models: $_modelApiPath');
    print('  - Request Models: $_requestModelPath');
    print('  - Enums: $_enumPath');
    print('  - Wrapped by: $_wrappedBy');

    // Check if folder exists
    final folder = Directory(folderPath);
    if (!folder.existsSync()) {
      throw Exception('Folder does not exist: $folderPath');
    }

    // Find JSON files in folder
    final jsonFiles = folder
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.json'))
        .toList();

    if (jsonFiles.isEmpty) {
      throw Exception('No JSON files found in folder: $folderPath');
    }

    if (jsonFiles.length > 1) {
      print('⚠️ Multiple JSON files found, using: ${jsonFiles.first.path}');
    }

    final openApiFilePath = jsonFiles.first.path;
    generateFromOpenApi(openApiFilePath);
  }

  Set<String> _parseApisFilter(String? apisFilter) {
    if (apisFilter == null || apisFilter.isEmpty) {
      return <String>{};
    }

    return apisFilter.split(',').map((api) => api.trim().toLowerCase()).toSet();
  }

  bool _shouldIncludeEndpoint(EndpointInfo endpoint) {
    if (_allowedApis.isEmpty) return true;

    // Create key in format: method_path (e.g., "get_v1/search", "post_v2/city")
    final key = '${endpoint.method.toLowerCase()}_${endpoint.path}'.toLowerCase();
    return _allowedApis.contains(key);
  }

  void generateFromOpenApi(String openApiFilePath) {
    print('📖 Reading OpenAPI file: $openApiFilePath');

    // Read OpenAPI JSON file
    final openApiFile = File(openApiFilePath);
    if (!openApiFile.existsSync()) {
      throw Exception('OpenAPI file does not exist: $openApiFilePath');
    }

    final openApiContent = openApiFile.readAsStringSync();
    final openApiData = jsonDecode(openApiContent) as Map<String, dynamic>;

    // Ensure DataResponse key matches wrappedBy (data|result)
    _syncDataResponseKey();

    print('🔍 Analyzing endpoints...');

    // Analyze endpoints
    final endpoints = _analyzeEndpoints(openApiData);
    print('📊 Found ${endpoints.length} endpoints');

    // Validate wrapped key presence for included endpoints (non-blocking)
    _logMissingWrappedSchemas(endpoints);

    // Generate API methods
    print('🛠️ Generating API methods...');
    final apiMethods = _generateApiMethods(endpoints);

    // Generate model classes
    print('🏗️ Generating model classes...');
    final generatedModels = _generateModelClasses(endpoints, openApiData);

    // Update app_api_service.dart file
    print('📝 Updating app_api_service.dart...');
    _updateAppApiService(apiMethods);

    print(
        '✨ Generated ${apiMethods.length} API methods and ${generatedModels.length} model classes');
  }

  void _syncDataResponseKey() {
    try {
      final filePath = 'lib/model/api/base/data_response.dart';
      final file = File(filePath);
      if (!file.existsSync()) {
        print('⚠️  DataResponse file not found: $filePath');
        return;
      }
      var content = file.readAsStringSync();

      final wantResult = _wrappedBy == 'result';

      String replaceKeySingle(String input) {
        if (wantResult) {
          return input.replaceAll(
              "@JsonKey(name: 'data') T? data,", "@JsonKey(name: 'result') T? data,");
        } else {
          return input.replaceAll(
              "@JsonKey(name: 'result') T? data,", "@JsonKey(name: 'data') T? data,");
        }
      }

      String replaceKeyList(String input) {
        if (wantResult) {
          return input.replaceAll(
              "@JsonKey(name: 'data') List<T>? data,", "@JsonKey(name: 'result') List<T>? data,");
        } else {
          return input.replaceAll(
              "@JsonKey(name: 'result') List<T>? data,", "@JsonKey(name: 'data') List<T>? data,");
        }
      }

      final updated = replaceKeyList(replaceKeySingle(content));
      if (updated != content) {
        file.writeAsStringSync(updated);
        print('🛠️  Updated DataResponse key to ${wantResult ? 'result' : 'data'}');
      } else {
        print('ℹ️  DataResponse key already set to ${wantResult ? 'result' : 'data'}');
      }
    } catch (e) {
      print('⚠️  Could not update DataResponse key: $e');
    }
  }

  void _logMissingWrappedSchemas(List<EndpointInfo> endpoints) {
    final problems = <String>[];
    for (final e in endpoints) {
      if (!_shouldIncludeEndpoint(e)) continue;
      // Only validate if there is a declared response schema
      if (e.responseSchema == null) continue;
      if (e.wrappedResponseSchema == null) {
        problems.add('${e.method} ${e.path} -> missing wrapped key "$_wrappedBy"');
      }
    }
    if (problems.isNotEmpty) {
      final message = [
        '⚠️ Wrapped key "$_wrappedBy" not found in some endpoint responses:',
        ...problems.map((p) => ' - $p'),
      ].join('\n');
      print(message);
    }
  }

  List<EndpointInfo> _analyzeEndpoints(Map<String, dynamic> openApiData) {
    final endpoints = <EndpointInfo>[];
    final paths = openApiData['paths'] as Map<String, dynamic>? ?? {};
    final components = openApiData['components'] as Map<String, dynamic>? ?? {};

    for (final pathEntry in paths.entries) {
      final path = pathEntry.key;
      final methods = pathEntry.value as Map<String, dynamic>;

      for (final methodEntry in methods.entries) {
        final method = methodEntry.key;
        final details = methodEntry.value as Map<String, dynamic>;

        final rawResponseSchema = _extractResponseSchema(details, components);
        final resolvedResponseSchema = _resolveSchema((rawResponseSchema ?? {}), components);
        final wrappedResponseSchema = _extractWrappedSchema(resolvedResponseSchema, components);
        final responseSchemaName = _extractSchemaRefName(rawResponseSchema);

        final endpoint = EndpointInfo(
          method: method.toUpperCase(),
          path: path,
          queryParams: _extractQueryParams(details),
          hasBody: _hasRequestBody(details),
          bodySchema: _extractRequestBodySchema(details, components),
          responseSchema: resolvedResponseSchema,
          wrappedResponseSchema: wrappedResponseSchema,
          responseSchemaName: responseSchemaName,
          operationId: details['operationId'] as String?,
          summary: details['summary'] as String?,
          tags: (details['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        );

        endpoints.add(endpoint);
      }
    }

    return endpoints;
  }

  List<QueryParam> _extractQueryParams(Map<String, dynamic> details) {
    final parameters = details['parameters'] as List<dynamic>? ?? [];
    final queryParams = <QueryParam>[];

    for (final param in parameters) {
      final paramMap = param as Map<String, dynamic>;
      if (paramMap['in'] == 'query') {
        final schema = paramMap['schema'] as Map<String, dynamic>? ?? {};
        queryParams.add(QueryParam(
          name: paramMap['name'] as String,
          type: schema['type'] as String? ?? 'string',
          required: paramMap['required'] as bool? ?? false,
        ));
      }
    }

    return queryParams;
  }

  bool _hasRequestBody(Map<String, dynamic> details) {
    return details.containsKey('requestBody');
  }

  Map<String, dynamic>? _extractRequestBodySchema(
      Map<String, dynamic> details, Map<String, dynamic> components) {
    final requestBody = details['requestBody'] as Map<String, dynamic>?;
    if (requestBody == null) return null;

    final content = requestBody['content'] as Map<String, dynamic>? ?? {};
    final jsonContent = content['application/json'] as Map<String, dynamic>? ?? {};
    final schema = jsonContent['schema'] as Map<String, dynamic>? ?? {};

    return _resolveSchema(schema, components);
  }

  Map<String, dynamic>? _extractResponseSchema(
      Map<String, dynamic> details, Map<String, dynamic> components) {
    final responses = details['responses'] as Map<String, dynamic>? ?? {};
    final successResponse = responses['200'] ?? responses['201'] ?? responses['202'];

    if (successResponse == null) return null;

    final successMap = successResponse as Map<String, dynamic>;
    final content = successMap['content'] as Map<String, dynamic>? ?? {};
    final jsonContent = content['application/json'] as Map<String, dynamic>? ?? {};
    final schema = jsonContent['schema'] as Map<String, dynamic>? ?? {};

    return schema;
  }

  String? _extractSchemaRefName(Map<String, dynamic>? schema) {
    if (schema == null) return null;

    if (schema['\$ref'] is String) {
      final ref = schema['\$ref'] as String;
      if (ref.startsWith('#/components/schemas/')) {
        return ref.split('/').last;
      }
    }

    for (final key in const ['allOf', 'oneOf', 'anyOf']) {
      if (schema[key] is List) {
        for (final item in schema[key] as List) {
          final refName = _extractSchemaRefName(item as Map<String, dynamic>?);
          if (refName != null) {
            return refName;
          }
        }
      }
    }

    return null;
  }

  Map<String, dynamic> _resolveSchema(
      Map<String, dynamic> schema, Map<String, dynamic> components) {
    if (schema.containsKey('\$ref')) {
      final ref = schema['\$ref'] as String;
      if (ref.startsWith('#/components/schemas/')) {
        final schemaName = ref.split('/').last;
        final schemas = components['schemas'] as Map<String, dynamic>? ?? {};
        final resolvedSchema = schemas[schemaName] as Map<String, dynamic>? ?? {};
        // Recursively resolve any nested references
        return _resolveSchema(resolvedSchema, components);
      }
    }
    return schema;
  }

  Map<String, dynamic>? _extractWrappedSchema(
    Map<String, dynamic> schema,
    Map<String, dynamic> components,
  ) {
    // Handle allOf with merged properties
    Map<String, dynamic> effective = schema;
    if (schema.containsKey('allOf')) {
      final allOf = schema['allOf'] as List<dynamic>;
      final merged = <String, dynamic>{'type': 'object', 'properties': <String, dynamic>{}};
      for (final item in allOf) {
        final itemSchema = _resolveSchema((item as Map<String, dynamic>), components);
        if (itemSchema['properties'] is Map<String, dynamic>) {
          (merged['properties'] as Map<String, dynamic>)
              .addAll((itemSchema['properties'] as Map<String, dynamic>));
        }
      }
      effective = merged;
    }

    if (effective['type'] == 'object' && effective['properties'] is Map<String, dynamic>) {
      final props = effective['properties'] as Map<String, dynamic>;
      final key = _wrappedBy;
      if (props.containsKey(key)) {
        final wrapped = _resolveSchema(props[key] as Map<String, dynamic>, components);
        return wrapped;
      }
    }
    return null;
  }

  // Removed unused: _generateExampleFromSchema

  // Removed unused: _resolveRef

  List<String> _generateApiMethods(List<EndpointInfo> endpoints) {
    final methods = <String>[];

    // Build a set of all v1 paths for v2 comparison
    final v1Paths = endpoints.where((e) => !e.path.startsWith('/v2/')).map((e) => e.path).toSet();

    for (final endpoint in endpoints) {
      if (!_shouldIncludeEndpoint(endpoint)) continue;

      final methodCode = _generateSingleApiMethod(endpoint, v1Paths);
      methods.add(methodCode);
    }

    return methods;
  }

  String _generateSingleApiMethod(EndpointInfo endpoint, Set<String> v1Paths) {
    final methodName = _generateMethodName(endpoint.path, endpoint.method, v1Paths);

    // Determine which client to use based on security requirements
    final client = _getClientForEndpoint(endpoint);

    // Determine wrapped schema (data/results)
    final wrappedSchema = endpoint.wrappedResponseSchema;

    // Return type and decoder type
    String returnType;
    String decoderType;
    String decoderLine = '';

    // Always use DataResponse/DataListResponse; key is normalized via _syncDataResponseKey

    if (wrappedSchema == null || _isEffectivelyVoidSchema(wrappedSchema)) {
      // Wrap as <Wrapper<void>>
      returnType = 'Future<DataResponse<void>?>';
      decoderType = 'SuccessResponseDecoderType.dataJsonObject';
      decoderLine = '      decoder: (_) => Object(),';
    } else if ((wrappedSchema['type'] == 'array') || (wrappedSchema.containsKey('items'))) {
      // list
      final itemsSchema = (wrappedSchema['items'] as Map<String, dynamic>? ?? {});
      final primitiveItem = _getPrimitiveDartType(itemsSchema);
      if (primitiveItem != null) {
        // List of primitives (String/int/bool/double)
        returnType = 'Future<DataListResponse<$primitiveItem>?>';
        decoderType = 'SuccessResponseDecoderType.dataJsonArray';
        decoderLine =
            '      decoder: (json) => json.safeCast<$primitiveItem>()${_primitiveDefaultSuffix(primitiveItem)},';
      } else if ((itemsSchema['\$ref'] as String?)?.startsWith('#/components/schemas/') ?? false) {
        final ref = itemsSchema['\$ref'] as String;
        final rawName = ref.split('/').last;
        final itemType = _resolveSchemaClassName(rawName);
        returnType = 'Future<DataListResponse<$itemType>?>';
        decoderType = 'SuccessResponseDecoderType.dataJsonArray';
        decoderLine =
            "      decoder: (json) => $itemType.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),";
      } else {
        final itemType = _generateArrayItemModelName(endpoint);
        returnType = 'Future<DataListResponse<$itemType>?>';
        decoderType = 'SuccessResponseDecoderType.dataJsonArray';
        decoderLine =
            "      decoder: (json) => $itemType.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),";
      }
    } else {
      // object or primitive
      final primitive = _getPrimitiveDartType(wrappedSchema);
      if (primitive != null) {
        returnType = 'Future<DataResponse<$primitive>?>';
        decoderType = 'SuccessResponseDecoderType.dataJsonObject';
        decoderLine =
            '      decoder: (json) => json.safeCast<$primitive>()${_primitiveDefaultSuffix(primitive)},';
      } else {
        final responseModelName = _generateWrappedResponseModelName(endpoint);
        returnType = 'Future<DataResponse<$responseModelName>?>';
        decoderType = 'SuccessResponseDecoderType.dataJsonObject';
        decoderLine =
            "      decoder: (json) => $responseModelName.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),";
      }
    }

    // Generate parameters
    final params = <String>[];
    BodyParamsGenerationResult? bodyParams;

    // Required params first
    final requiredParams = endpoint.queryParams.where((p) => p.required).toList();
    final optionalParams = endpoint.queryParams.where((p) => !p.required).toList();

    for (final param in requiredParams) {
      final dartType = param.type == 'integer' ? 'int' : 'String';
      params.add('required $dartType ${_toCamelCase(param.name)}');
    }

    for (final param in optionalParams) {
      final dartType = param.type == 'integer' ? 'int' : 'String';
      params.add('$dartType? ${_toCamelCase(param.name)}');
    }

    if (endpoint.hasBody) {
      bodyParams = _prepareBodyParameters(endpoint);
      if (bodyParams != null && bodyParams.paramSignatures.isNotEmpty) {
        params.addAll(bodyParams.paramSignatures);
      }
    }

    // Generate method body
    final methodLines = <String>[];

    // Add method signature - only add {} if there are parameters
    if (params.isNotEmpty) {
      methodLines.addAll([
        '  $returnType $methodName({',
        '    ${params.join(',\n    ')},',
        '  }) async {',
      ]);
    } else {
      methodLines.addAll([
        '  $returnType $methodName() async {',
      ]);
    }

    if (bodyParams != null && bodyParams.bodySetupLines.isNotEmpty) {
      methodLines.addAll(bodyParams.bodySetupLines);
    }

    methodLines.addAll([
      '    return $client.request(',
      '      method: RestMethod.${endpoint.method.toLowerCase()},',
      "      path: '${endpoint.path.startsWith('/') ? endpoint.path.substring(1) : endpoint.path}',",
    ]);

    if (endpoint.queryParams.isNotEmpty) {
      methodLines.add('      queryParameters: {');
      for (final param in endpoint.queryParams) {
        final camelName = _toCamelCase(param.name);
        if (param.required) {
          methodLines.add("        '${param.name}': $camelName,");
        } else {
          methodLines.add("        if ($camelName != null) '${param.name}': $camelName,");
        }
      }
      methodLines.add('      },');
    }

    if (bodyParams != null) {
      methodLines.add('      body: ${bodyParams.bodyArgument},');
    }

    methodLines.add('      successResponseDecoderType: $decoderType,');
    if (decoderLine.isNotEmpty) {
      methodLines.add(decoderLine);
    }
    methodLines.addAll([
      '    );',
      '  }',
    ]);

    return methodLines.join('\n');
  }

  bool _isEffectivelyVoidSchema(Map<String, dynamic> schema) {
    // If schema is explicitly nullable -> treat as void wrapper
    if ((schema['nullable'] as bool?) == true) return true;

    final type = schema['type'] as String?;
    if (type == null) return true;

    if (type == 'object') {
      final props = schema['properties'] as Map<String, dynamic>?;
      if (props == null || props.isEmpty) return true;
    }

    return false;
  }

  BodyParamsGenerationResult? _prepareBodyParameters(EndpointInfo endpoint) {
    final schema = endpoint.bodySchema;
    if (schema == null || schema.isEmpty) {
      return null;
    }

    // Use request model class for body
    final requestModelName = _generateRequestModelName(endpoint);

    return BodyParamsGenerationResult(
      paramSignatures: ['required $requestModelName request'],
      bodySetupLines: const [],
      bodyArgument: 'request.toJson()',
    );
  }

  String? _getPrimitiveDartType(Map<String, dynamic> schema) {
    final type = schema['type'] as String?;
    switch (type) {
      case 'string':
        return 'String';
      case 'integer':
        return 'int';
      case 'number':
        return 'double';
      case 'boolean':
        return 'bool';
      default:
        return null;
    }
  }

  String _getClientForEndpoint(EndpointInfo endpoint) {
    // Check if endpoint requires authentication based on security field
    // For now, we'll use a simple heuristic based on path patterns
    if (endpoint.path.contains('/auth/') &&
        (endpoint.method == 'POST' && endpoint.path.contains('/login'))) {
      return '_noneAuthAppServerApiClient';
    }
    return '_authAppServerApiClient';
  }

  String _generateMethodName(String path, String method, Set<String> v1Paths) {
    final cleanPath = _cleanPathForName(path);

    // Convert to proper camelCase method name
    String methodName;
    if (method == 'GET') {
      methodName = 'get${_toPascalCase(cleanPath)}';
    } else if (method == 'POST') {
      methodName = 'post${_toPascalCase(cleanPath)}';
    } else if (method == 'PUT') {
      methodName = 'put${_toPascalCase(cleanPath)}';
    } else if (method == 'PATCH') {
      methodName = 'patch${_toPascalCase(cleanPath)}';
    } else if (method == 'DELETE') {
      methodName = 'delete${_toPascalCase(cleanPath)}';
    } else {
      methodName = _toCamelCase(cleanPath);
    }

    // Handle v2 endpoints - add V2 suffix if needed
    if (path.startsWith('/v2/')) {
      // Check if there's a v1 equivalent
      final v1Path = path.replaceFirst('/v2/', '/');
      if (v1Paths.contains(v1Path)) {
        methodName += 'V2';
      }
    }

    return methodName;
  }

  String _generateResponseModelName(EndpointInfo endpoint) {
    final key = '${endpoint.method}_${endpoint.path}';
    final cached = _endpointResponseNameCache[key];
    if (cached != null) {
      return cached;
    }

    final schemaName = endpoint.responseSchemaName;
    if (schemaName != null && schemaName.isNotEmpty) {
      final resolved = _resolveSchemaClassName(schemaName);
      _endpointResponseNameCache[key] = resolved;
      return resolved;
    }

    final cleanPath = _cleanPathForName(endpoint.path);
    final formatted = _normalizeSchemaName(cleanPath);
    final name = _registerModelName(formatted);
    _endpointResponseNameCache[key] = name;

    return name;
  }

  String _generateWrappedResponseModelName(EndpointInfo endpoint) {
    final schemaName = endpoint.responseSchemaName;
    if (schemaName != null && schemaName.isNotEmpty) {
      return _resolveSchemaClassName(schemaName);
    }

    final cleanPath = _cleanPathForName(endpoint.path);
    final formatted = _normalizeSchemaName(cleanPath);
    return _registerModelName(formatted);
  }

  String _generateArrayItemModelName(EndpointInfo endpoint) {
    final key = '${endpoint.method}_${endpoint.path}_item';
    final cached = _endpointArrayItemNameCache[key];
    if (cached != null) {
      return cached;
    }

    final cleanPath = _cleanPathForName(endpoint.path);
    final base = '${_toPascalCase(cleanPath)}Item';
    final formatted = _applyResponseModelNaming(base);
    final name = _registerModelName(formatted);
    _endpointArrayItemNameCache[key] = name;

    return name;
  }

  String _generateRequestModelName(EndpointInfo endpoint) {
    final cleanPath = _cleanPathForName(endpoint.path);
    var base = _toPascalCase(cleanPath);

    // Remove "Data" suffix if present (case-insensitive)
    if (base.endsWith('Data')) {
      base = base.substring(0, base.length - 4);
    }

    final requestName = '${base}Request';

    // Don't use _registerModelName for request models to avoid auto-appending "Data"
    // Request models should have unique names without collision
    return requestName;
  }

  // Removed unused: _generateRequestModelName

  // Removed unused: _generateModelName

  String _normalizeSchemaName(String name) {
    var result = name;
    if (result.contains('__')) {
      final parts = result.split('__');
      if (parts.isNotEmpty) {
        result = parts.last;
      }
    }
    result = result.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    if (!result.contains('_')) {
      if (result.isEmpty) {
        return 'Model';
      }
      return result[0].toUpperCase() + result.substring(1);
    }

    final segments = result
        .split('_')
        .where((segment) => segment.isNotEmpty)
        .map(
          (segment) => segment[0].toUpperCase() + segment.substring(1).toLowerCase(),
        )
        .join('');

    return segments.isEmpty ? 'Model' : segments;
  }

  String _cleanPathForName(String path) {
    var clean = path.replaceFirst('/', '').replaceAll('v2/', '');

    // Special handling for complex paths like 'getRecommendations/savedSearches'
    // Remove common prefixes that shouldn't be in method names
    clean = clean.replaceFirst('get', '');
    clean = clean.replaceFirst('post', '');
    clean = clean.replaceFirst('put', '');
    clean = clean.replaceFirst('patch', '');
    clean = clean.replaceFirst('delete', '');

    // Convert hyphens and slashes to underscores
    clean = clean.replaceAll(RegExp(r'[-/]'), '_');
    clean = clean.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    clean = clean.replaceAll(RegExp(r'_+'), '_');
    return clean.replaceAll(RegExp(r'^_|_$'), '');
  }

  String _applyResponseModelNaming(String base) {
    return base.isEmpty ? 'Model' : base;
  }

  String _registerModelName(String desired) {
    var candidate = desired;
    while (_usedModelNames.contains(candidate)) {
      candidate = '${candidate}Data';
    }
    _usedModelNames.add(candidate);
    return candidate;
  }

  String _resolveSchemaClassName(String rawName) {
    final cached = _schemaNameCache[rawName];
    if (cached != null) {
      return cached;
    }

    final className = rawName;
    _schemaNameCache[rawName] = className;
    _usedModelNames.add(className);

    return className;
  }

  void _updateAppApiService(List<String> apiMethods) {
    final file = File(_appApiServicePath);
    if (!file.existsSync()) {
      // Try to copy from the default location if using custom output path
      if (_appApiServicePath != appApiServicePath) {
        final sourceFile = File(appApiServicePath);
        if (sourceFile.existsSync()) {
          print('📋 Copying app_api_service.dart from ${sourceFile.path} to $_appApiServicePath');
          // Create directory if it doesn't exist
          file.parent.createSync(recursive: true);
          // Copy file content
          file.writeAsStringSync(sourceFile.readAsStringSync());
        } else {
          throw Exception('Source app_api_service.dart file does not exist: ${sourceFile.path}');
        }
      } else {
        throw Exception('app_api_service.dart file does not exist: $_appApiServicePath');
      }
    }

    var content = file.readAsStringSync();

    // Find marker position
    var markerIndex = content.indexOf(generatedMethodsMarker);

    // If marker doesn't exist, add it before the last closing brace
    if (markerIndex == -1) {
      print('🔧 Marker not found, adding it automatically...');
      final classEndIndex = content.lastIndexOf('}');
      if (classEndIndex == -1) {
        throw Exception('Could not find class end');
      }

      // Insert marker before the last closing brace
      final beforeClassEnd = content.substring(0, classEndIndex);
      final afterClassEnd = content.substring(classEndIndex);
      content = '$beforeClassEnd\n  $generatedMethodsMarker\n$afterClassEnd';
      markerIndex = content.indexOf(generatedMethodsMarker);
    }

    // Find class end position (last closing brace)
    final classEndIndex = content.lastIndexOf('}');
    if (classEndIndex == -1) {
      throw Exception('Could not find class end');
    }

    final newMethods = apiMethods.join('\n\n');
    String newContent;

    if (_replace) {
      // Replace mode: Remove all methods after marker
      final beforeMarker = content.substring(0, markerIndex + generatedMethodsMarker.length);
      final afterClass = content.substring(classEndIndex);
      newContent = '$beforeMarker\n\n$newMethods\n$afterClass';
    } else {
      // Append mode: Add new methods before class end
      final beforeClassEnd = content.substring(0, classEndIndex);
      final afterClassEnd = content.substring(classEndIndex);
      newContent = '$beforeClassEnd\n\n$newMethods\n$afterClassEnd';
    }

    // Write file
    file.writeAsStringSync(newContent);

    final mode = _replace ? 'replaced' : 'appended';
    print('📝 ${mode.toUpperCase()} ${apiMethods.length} API methods in $_appApiServicePath');
  }

  List<String> _generateModelClasses(
      List<EndpointInfo> endpoints, Map<String, dynamic> openApiData) {
    final generatedModels = <String>[];
    final processedSchemas = <String>{};

    // Get components schemas
    final components = openApiData['components'] as Map<String, dynamic>? ?? {};
    final schemas = components['schemas'] as Map<String, dynamic>? ?? {};

    // Collect referenced component schemas from wrapped response schemas
    final referencedSchemaNames = <String>{};
    for (final endpoint in endpoints) {
      if (!_shouldIncludeEndpoint(endpoint)) continue;
      final wrappedSchema = endpoint.wrappedResponseSchema;
      if (wrappedSchema == null) continue;
      _collectRefSchemaNames(wrappedSchema, referencedSchemaNames);
    }

    // Recursively expand references: include transitive component dependencies
    bool added;
    do {
      added = false;
      final current = List<String>.from(referencedSchemaNames);
      for (final name in current) {
        final comp = schemas[name] as Map<String, dynamic>?;
        if (comp == null) continue;
        final beforeLen = referencedSchemaNames.length;
        _collectRefSchemaNames(comp, referencedSchemaNames);
        if (referencedSchemaNames.length > beforeLen) added = true;
      }
    } while (added);

    for (final schemaName in referencedSchemaNames) {
      if (_isRequestSchema(schemaName) || _shouldSkipSchema(schemaName)) continue;
      if (processedSchemas.contains(schemaName)) continue;
      final schema = schemas[schemaName] as Map<String, dynamic>?;
      if (schema == null) continue;
      processedSchemas.add(schemaName);

      final modelName = _resolveSchemaClassName(schemaName);
      final result = _generateModelFileFromSchema(
        modelName,
        schema,
        components,
      );
      final fileName = _modelNameToFileName(modelName);
      _writeModelFile(fileName, result.mainContent);
      generatedModels.add(modelName);
      if (result.nestedClasses.isNotEmpty) {
        _writeNestedClassFiles(result.nestedClasses, generatedModels);
      }
    }

    // Generate wrapped response models for endpoints
    for (final endpoint in endpoints) {
      if (!_shouldIncludeEndpoint(endpoint)) continue;

      final wrappedSchema = endpoint.wrappedResponseSchema;
      if (wrappedSchema == null) continue;

      String modelName;
      if (wrappedSchema['type'] == 'array') {
        final itemsSchema = wrappedSchema['items'] as Map<String, dynamic>? ?? {};
        final ref = itemsSchema['\$ref'] as String?;
        if (ref != null && ref.startsWith('#/components/schemas/')) {
          continue;
        }
        modelName = _generateArrayItemModelName(endpoint);
        final result = _generateModelFileFromSchema(
          modelName,
          itemsSchema,
          components,
        );
        final fileName = _modelNameToFileName(modelName);
        _writeModelFile(fileName, result.mainContent);
        generatedModels.add(modelName);
        if (result.nestedClasses.isNotEmpty) {
          _writeNestedClassFiles(result.nestedClasses, generatedModels);
        }
      } else {
        modelName = _generateResponseModelName(endpoint);
        final result = _generateModelFileFromSchema(
          modelName,
          wrappedSchema,
          components,
        );
        final fileName = _modelNameToFileName(modelName);
        _writeModelFile(fileName, result.mainContent);
        generatedModels.add(modelName);
        if (result.nestedClasses.isNotEmpty) {
          _writeNestedClassFiles(result.nestedClasses, generatedModels);
        }
      }
    }

    // Generate request models from bodySchema
    print('🏗️ Generating request models...');
    for (final endpoint in endpoints) {
      if (!_shouldIncludeEndpoint(endpoint)) continue;

      final bodySchema = endpoint.bodySchema;
      if (bodySchema == null || bodySchema.isEmpty) continue;

      final requestModelName = _generateRequestModelName(endpoint);
      final result = _generateRequestModelFileFromSchema(
        requestModelName,
        bodySchema,
        components,
      );
      final fileName = _modelNameToFileName(requestModelName);
      _writeRequestModelFile(fileName, result.mainContent);
      generatedModels.add(requestModelName);
      if (result.nestedClasses.isNotEmpty) {
        _writeNestedRequestClassFiles(result.nestedClasses, generatedModels);
      }
    }

    return generatedModels;
  }

  void _writeNestedClassFiles(
    List<NestedClassInfo> nestedClasses,
    List<String> generatedModels,
  ) {
    for (final nested in nestedClasses) {
      if (generatedModels.contains(nested.className)) continue;
      final nestedResult = _buildGenerationResult(nested.className, nested.result);
      final nestedFileName = _modelNameToFileName(nested.className);
      _writeModelFile(nestedFileName, nestedResult.mainContent);
      generatedModels.add(nested.className);
      _usedModelNames.add(nested.className);
      if (nestedResult.nestedClasses.isNotEmpty) {
        _writeNestedClassFiles(nestedResult.nestedClasses, generatedModels);
      }
    }
  }

  void _collectRefSchemaNames(dynamic schema, Set<String> out) {
    if (schema == null) return;
    if (schema is Map<String, dynamic>) {
      if (schema.containsKey('\$ref')) {
        final ref = schema['\$ref'] as String;
        if (ref.startsWith('#/components/schemas/')) {
          out.add(ref.split('/').last);
        }
      }
      // Dive into object properties
      if (schema['type'] == 'object' && schema['properties'] is Map<String, dynamic>) {
        final props = schema['properties'] as Map<String, dynamic>;
        for (final v in props.values) {
          _collectRefSchemaNames(v, out);
        }
      }
      // Dive into array items
      if (schema['type'] == 'array' && schema['items'] is Map<String, dynamic>) {
        _collectRefSchemaNames(schema['items'], out);
      }
      // Handle allOf/oneOf/anyOf merges
      for (final key in const ['allOf', 'oneOf', 'anyOf']) {
        if (schema[key] is List) {
          for (final item in (schema[key] as List)) {
            _collectRefSchemaNames(item, out);
          }
        }
      }
    }
  }

  bool _isRequestSchema(String schemaName) {
    // Skip schemas that are clearly request models
    final requestPatterns = [
      'Request',
      'LoginRequest',
      'RegisterRequest',
      'VerifyOtpRequest',
      'ResendOtpRequest',
      'RefreshRequest',
      'LogoutRequest',
      'ForgotPasswordRequest',
      'ResetPasswordRequest',
    ];

    return requestPatterns.any((pattern) => schemaName.contains(pattern));
  }

  bool _shouldSkipSchema(String schemaName) {
    // Skip ApiError and other unnecessary schemas
    final skipPatterns = [
      'ApiError',
      'Request',
    ];

    return skipPatterns.any((pattern) => schemaName.contains(pattern));
  }

  // Removed unused: _extractAllSchemas

  // Removed unused: _extractSchemasRecursively

  ModelGenerationResult _generateModelFileFromSchema(
    String modelName,
    Map<String, dynamic> schema, [
    Map<String, dynamic>? components,
  ]) {
    final classResult = _generateModelClassFromSchema(
      modelName,
      schema,
      components: components,
    );

    if (classResult.mainClass.trim().isEmpty) {
      return ModelGenerationResult(mainContent: '', nestedClasses: const []);
    }

    return _buildGenerationResult(modelName, classResult);
  }

  ModelGenerationResult _generateRequestModelFileFromSchema(
    String modelName,
    Map<String, dynamic> schema, [
    Map<String, dynamic>? components,
  ]) {
    final classResult = _generateRequestModelClassFromSchema(
      modelName,
      schema,
      components: components,
    );

    if (classResult.mainClass.trim().isEmpty) {
      return ModelGenerationResult(mainContent: '', nestedClasses: const []);
    }

    return _buildGenerationResult(modelName, classResult);
  }

  ModelGenerationResult _buildGenerationResult(
    String className,
    ModelClassResult classResult,
  ) {
    final fileName = _modelNameToFileName(className);
    final imports = _generateImports(fileName);

    final buffer = StringBuffer()
      ..writeln(imports)
      ..writeln()
      ..writeln(classResult.mainClass.trim());

    final remaining = <NestedClassInfo>[];

    for (final nested in classResult.nestedClasses) {
      if (nested.shouldEmbed) {
        _usedModelNames.add(nested.className);
        buffer
          ..writeln()
          ..writeln(_composeEmbeddedClass(nested));
        remaining.addAll(
          nested.result.nestedClasses.where((child) => !child.shouldEmbed).toList(),
        );
      } else {
        remaining.add(nested);
      }
    }

    return ModelGenerationResult(
      mainContent: buffer.toString(),
      nestedClasses: remaining,
    );
  }

  String _composeEmbeddedClass(NestedClassInfo info) {
    final buffer = StringBuffer()..writeln(info.result.mainClass.trim());

    final embeddedChildren = info.result.nestedClasses.where((child) => child.shouldEmbed).toList();
    for (final child in embeddedChildren) {
      buffer
        ..writeln()
        ..writeln(_composeEmbeddedClass(child));
    }

    return buffer.toString();
  }

  // Removed unused: _generateModelFileWithNested

  ModelClassResult _generateModelClassFromSchema(
    String modelName,
    Map<String, dynamic> schema, {
    String? prefix,
    Map<String, dynamic>? components,
    int depth = 0,
  }) {
    final className = prefix != null ? '$prefix$modelName' : modelName;
    final privateClassName = '_\$${className}';
    final factoryName = '_$className';
    final nestedClasses = <NestedClassInfo>[];

    if (schema.containsKey('allOf')) {
      final allOf = schema['allOf'] as List<dynamic>;
      final mergedSchema = <String, dynamic>{};
      final allRequired = <String>[];

      for (final item in allOf) {
        final itemSchema = item as Map<String, dynamic>;
        final resolvedSchema =
            components != null ? _resolveSchema(itemSchema, components) : itemSchema;

        if (resolvedSchema.containsKey('properties')) {
          final properties = resolvedSchema['properties'] as Map<String, dynamic>;
          mergedSchema.addAll(properties);
        }

        if (resolvedSchema.containsKey('required')) {
          final required =
              (resolvedSchema['required'] as List<dynamic>?)?.cast<String>() ?? <String>[];
          allRequired.addAll(required);
        }
      }

      if (mergedSchema.isNotEmpty) {
        final fieldsResult = _generateFieldsFromSchema(
          mergedSchema,
          allRequired,
          className,
          components,
          depth,
        );
        nestedClasses.addAll(fieldsResult.nestedClasses);

        if (fieldsResult.fields.isNotEmpty) {
          final mainClass = '''@freezed
sealed class $className with $privateClassName {
  const $className._();

  const factory $className({
${fieldsResult.fields.map((f) => '    $f').join(',\n')},
  }) = $factoryName;

  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
}''';

          return ModelClassResult(
            mainClass: mainClass,
            nestedClasses: nestedClasses,
          );
        }
      }
    } else if (schema['type'] == 'object' && schema.containsKey('properties')) {
      final properties = schema['properties'] as Map<String, dynamic>;
      final requiredFields = (schema['required'] as List<dynamic>?)?.cast<String>() ?? <String>[];

      final fieldsResult = _generateFieldsFromSchema(
        properties,
        requiredFields,
        className,
        components,
        depth,
      );
      nestedClasses.addAll(fieldsResult.nestedClasses);

      if (fieldsResult.fields.isEmpty) {
        return ModelClassResult(mainClass: '', nestedClasses: nestedClasses);
      }

      final mainClass = '''@freezed
sealed class $className with $privateClassName {
  const $className._();

  const factory $className({
${fieldsResult.fields.map((f) => '    $f').join(',\n')},
  }) = $factoryName;

  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
}''';

      return ModelClassResult(
        mainClass: mainClass,
        nestedClasses: nestedClasses,
      );
    }

    return ModelClassResult(mainClass: '', nestedClasses: const []);
  }

  ModelClassResult _generateRequestModelClassFromSchema(
    String modelName,
    Map<String, dynamic> schema, {
    String? prefix,
    Map<String, dynamic>? components,
    int depth = 0,
  }) {
    final className = prefix != null ? '$prefix$modelName' : modelName;
    final privateClassName = '_\$${className}';
    final factoryName = '_$className';
    final nestedClasses = <NestedClassInfo>[];

    if (schema.containsKey('allOf')) {
      final allOf = schema['allOf'] as List<dynamic>;
      final mergedSchema = <String, dynamic>{};
      final allRequired = <String>[];

      for (final item in allOf) {
        final itemSchema = item as Map<String, dynamic>;
        final resolvedSchema =
            components != null ? _resolveSchema(itemSchema, components) : itemSchema;

        if (resolvedSchema.containsKey('properties')) {
          final properties = resolvedSchema['properties'] as Map<String, dynamic>;
          mergedSchema.addAll(properties);
        }

        if (resolvedSchema.containsKey('required')) {
          final required =
              (resolvedSchema['required'] as List<dynamic>?)?.cast<String>() ?? <String>[];
          allRequired.addAll(required);
        }
      }

      if (mergedSchema.isNotEmpty) {
        final fieldsResult = _generateRequestFieldsFromSchema(
          mergedSchema,
          allRequired,
          className,
          components,
          depth,
        );
        nestedClasses.addAll(fieldsResult.nestedClasses);

        if (fieldsResult.fields.isNotEmpty) {
          final mainClass = '''@freezed
sealed class $className with $privateClassName {
  const $className._();

  const factory $className({
${fieldsResult.fields.map((f) => '    $f').join(',\n')},
  }) = $factoryName;

  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
}''';

          return ModelClassResult(
            mainClass: mainClass,
            nestedClasses: nestedClasses,
          );
        }
      }
    } else if (schema['type'] == 'object' && schema.containsKey('properties')) {
      final properties = schema['properties'] as Map<String, dynamic>;
      final requiredFields = (schema['required'] as List<dynamic>?)?.cast<String>() ?? <String>[];

      final fieldsResult = _generateRequestFieldsFromSchema(
        properties,
        requiredFields,
        className,
        components,
        depth,
      );
      nestedClasses.addAll(fieldsResult.nestedClasses);

      if (fieldsResult.fields.isEmpty) {
        return ModelClassResult(mainClass: '', nestedClasses: nestedClasses);
      }

      final mainClass = '''@freezed
sealed class $className with $privateClassName {
  const $className._();

  const factory $className({
${fieldsResult.fields.map((f) => '    $f').join(',\n')},
  }) = $factoryName;

  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
}''';

      return ModelClassResult(
        mainClass: mainClass,
        nestedClasses: nestedClasses,
      );
    }

    return ModelClassResult(mainClass: '', nestedClasses: const []);
  }

  ModelClassResult _generateModelClassWithNested(
    String modelName,
    dynamic responseExample, {
    String? prefix,
    int depth = 0,
  }) {
    if (responseExample == null) {
      return ModelClassResult(mainClass: '', nestedClasses: const []);
    }

    final className = prefix != null ? '$prefix$modelName' : modelName;
    final privateClassName = '_\$${className}';
    final factoryName = '_$className';
    final nestedClasses = <NestedClassInfo>[];

    if (responseExample is Map<String, dynamic>) {
      final fieldsResult = _generateFieldsWithNested(responseExample, className, depth);
      nestedClasses.addAll(fieldsResult.nestedClasses);
      if (fieldsResult.fields.isEmpty) {
        return ModelClassResult(mainClass: '', nestedClasses: nestedClasses);
      }

      final mainClass = '''@freezed
sealed class $className with $privateClassName {
  const $className._();

  const factory $className({
${fieldsResult.fields.map((f) => '    $f').join(',\n')},
  }) = $factoryName;

  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
}''';

      return ModelClassResult(
        mainClass: mainClass,
        nestedClasses: nestedClasses,
      );
    }

    return ModelClassResult(mainClass: '', nestedClasses: const []);
  }

  String _generateImports(String fileName) {
    return '''import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../index.dart';

part '$fileName.freezed.dart';
part '$fileName.g.dart';''';
  }

  FieldGenerationResult _generateFieldsFromSchema(
    Map<String, dynamic> properties,
    List<String> requiredFields,
    String parentClassName,
    Map<String, dynamic>? components,
    int depth,
  ) {
    final fields = <String>[];
    final nestedClasses = <NestedClassInfo>[];

    for (final entry in properties.entries) {
      final fieldName = entry.key;
      final fieldSchema = entry.value as Map<String, dynamic>;
      final dartFieldName = _toCamelCase(fieldName);

      String fieldType = '';
      String defaultValue = '';
      bool shouldAddField = true;

      final dartType = _getDartTypeFromSchema(
        fieldSchema,
        parentClassName,
        fieldName,
        nestedClasses,
        components,
        depth,
      );

      if (dartType == null) {
        shouldAddField = false;
      } else {
        // Check if dartType already has nullable syntax
        final isAlreadyNullable = dartType.endsWith('?');

        // Remove nullable syntax if present - we'll handle it ourselves
        fieldType = isAlreadyNullable ? dartType.substring(0, dartType.length - 1) : dartType;

        // Check if this is an enum field
        final enumValues = fieldSchema['enum'] as List<dynamic>?;
        final isEnum = enumValues != null && enumValues.isNotEmpty;

        // Always gen default for ALL types including objects
        if (fieldType == 'String') {
          defaultValue = "@Default('')";
        } else if (fieldType == 'int') {
          defaultValue = '@Default(0)';
        } else if (fieldType == 'double') {
          defaultValue = '@Default(0.0)';
        } else if (fieldType == 'bool') {
          defaultValue = '@Default(false)';
        } else if (fieldType.startsWith('List<')) {
          defaultValue = '@Default([])';
        } else if (fieldType.startsWith('Map<')) {
          defaultValue = '@Default({})';
        } else if (isEnum) {
          // For enum types, always use 'none' as default
          defaultValue = '@Default($fieldType.none)';
        } else if (!fieldType.endsWith('?')) {
          // For object types, gen default with empty constructor
          final isPrimitive = fieldType == 'String' ||
              fieldType == 'int' ||
              fieldType == 'double' ||
              fieldType == 'bool';
          final isCollection = fieldType.startsWith('List<') || fieldType.startsWith('Map<');
          if (!isPrimitive && !isCollection) {
            defaultValue = '@Default($fieldType())';
          }
        }
      }

      if (shouldAddField && fieldType.isNotEmpty) {
        final jsonKey = "@JsonKey(name: '$fieldName')";
        final annotations = <String>[];
        if (!fieldType.endsWith('?') && defaultValue.isNotEmpty) {
          annotations.add(defaultValue);
        }
        annotations.add(jsonKey);
        final field = '${annotations.join(' ')} $fieldType $dartFieldName';
        fields.add(field);
      }
    }

    return FieldGenerationResult(fields: fields, nestedClasses: nestedClasses);
  }

  FieldGenerationResult _generateRequestFieldsFromSchema(
    Map<String, dynamic> properties,
    List<String> requiredFields,
    String parentClassName,
    Map<String, dynamic>? components,
    int depth,
  ) {
    final fields = <String>[];
    final nestedClasses = <NestedClassInfo>[];

    for (final entry in properties.entries) {
      final fieldName = entry.key;
      final fieldSchema = entry.value as Map<String, dynamic>;
      final dartFieldName = _toCamelCase(fieldName);
      final isRequired = requiredFields.contains(fieldName);

      String fieldType = '';
      String defaultValue = '';
      bool shouldAddField = true;

      final dartType = _getDartTypeFromSchema(
        fieldSchema,
        parentClassName,
        fieldName,
        nestedClasses,
        components,
        depth,
      );

      if (dartType == null) {
        shouldAddField = false;
      } else {
        // Check if dartType already has nullable syntax
        final isAlreadyNullable = dartType.endsWith('?');

        // Check if field is nullable from schema
        final isNullableFromSchema = (fieldSchema['nullable'] as bool? ?? false);

        // Remove nullable syntax if present
        final baseType = isAlreadyNullable ? dartType.substring(0, dartType.length - 1) : dartType;

        // Determine final nullable status:
        // - If not required → nullable (no default)
        // - If nullable in schema → nullable (no default)
        // - Otherwise → non-nullable with default
        if (!isRequired || isNullableFromSchema) {
          fieldType = '$baseType?';
        } else {
          fieldType = baseType;
          // Add default for required non-nullable fields
          if (fieldType == 'String') {
            defaultValue = "@Default('')";
          } else if (fieldType == 'int') {
            defaultValue = '@Default(0)';
          } else if (fieldType == 'double') {
            defaultValue = '@Default(0.0)';
          } else if (fieldType == 'bool') {
            defaultValue = '@Default(false)';
          } else if (fieldType.startsWith('List<')) {
            defaultValue = '@Default([])';
          } else if (fieldType.startsWith('Map<')) {
            defaultValue = '@Default({})';
          }
        }
      }

      if (shouldAddField && fieldType.isNotEmpty) {
        final jsonKey = "@JsonKey(name: '$fieldName')";
        final annotations = <String>[];
        if (defaultValue.isNotEmpty) {
          annotations.add(defaultValue);
        }
        annotations.add(jsonKey);
        final field = '${annotations.join(' ')} $fieldType $dartFieldName';
        fields.add(field);
      }
    }

    return FieldGenerationResult(fields: fields, nestedClasses: nestedClasses);
  }

  String? _getDartTypeFromSchema(
    Map<String, dynamic> schema,
    String parentClassName,
    String fieldName,
    List<NestedClassInfo> nestedClasses, [
    Map<String, dynamic>? components,
    int depth = 0,
  ]) {
    if (schema.containsKey('\$ref')) {
      final ref = schema['\$ref'] as String;
      if (ref.startsWith('#/components/schemas/')) {
        final rawName = ref.split('/').last;
        return _resolveSchemaClassName(rawName);
      }
    }

    final type = schema['type'] as String?;
    final nullable = schema['nullable'] as bool? ?? false;

    switch (type) {
      case 'string':
        final enumValues = schema['enum'] as List<dynamic>?;
        if (enumValues != null && enumValues.isNotEmpty) {
          // Generate simple enum name
          final enumName = _toPascalCase(fieldName);
          final enumContent = _generateEnumClass(enumName, enumValues.cast<String>());
          // Write enum to separate directory
          _writeEnumFile(enumName, enumContent);
          return enumName;
        }
        return nullable ? 'String?' : 'String';

      case 'integer':
        return nullable ? 'int?' : 'int';

      case 'number':
        return nullable ? 'double?' : 'double';

      case 'boolean':
        return nullable ? 'bool?' : 'bool';

      case 'array':
        final items = schema['items'] as Map<String, dynamic>? ?? {};
        final itemType = _getDartTypeFromSchema(
          items,
          parentClassName,
          '${fieldName}Item',
          nestedClasses,
          components,
          depth,
        );
        if (itemType == null) return 'List<dynamic>';
        return 'List<$itemType>';

      case 'object':
        if (schema.containsKey('properties')) {
          final nestedClassName = '${parentClassName}${_toPascalCase(fieldName)}';
          final nestedResult = _generateModelClassFromSchema(
            nestedClassName,
            schema,
            components: components,
            depth: depth + 1,
          );
          if (nestedResult.mainClass.trim().isNotEmpty) {
            nestedClasses.add(
              NestedClassInfo(
                className: nestedClassName,
                result: nestedResult,
                shouldEmbed: true,
              ),
            );
            nestedClasses.addAll(nestedResult.nestedClasses);
            return nullable ? '$nestedClassName?' : nestedClassName;
          }
        }
        return nullable ? 'Map<String, dynamic>?' : 'Map<String, dynamic>';

      default:
        return nullable ? 'dynamic?' : 'dynamic';
    }
  }

  String _generateEnumClass(String className, List<String> values) {
    // Convert className to simple enum name (remove Enum suffix if present)
    final enumName =
        className.endsWith('Enum') ? className.substring(0, className.length - 4) : className;

    // Add 'none' as first value if not already present
    final enumValues = <String>[];
    if (!values.contains('none')) {
      enumValues.add('none');
    }
    enumValues.addAll(values);

    return '''import 'package:json_annotation/json_annotation.dart';

enum $enumName {
${enumValues.map((v) => "  @JsonValue('$v')\n  $v,").join('\n')}
}''';
  }

  String _primitiveDefaultSuffix(String primitive) {
    switch (primitive) {
      case 'String':
        return " ?? ''";
      case 'int':
        return ' ?? 0';
      case 'double':
        return ' ?? 0.0';
      case 'bool':
        return ' ?? false';
      default:
        return '';
    }
  }

  FieldGenerationResult _generateFieldsWithNested(
    Map<String, dynamic> responseExample,
    String parentClassName,
    int depth,
  ) {
    final fields = <String>[];
    final nestedClasses = <NestedClassInfo>[];

    for (final entry in responseExample.entries) {
      final fieldName = entry.key;
      final fieldValue = entry.value;
      final dartFieldName = _toCamelCase(fieldName);

      String fieldType = '';
      String defaultValue = '';
      bool shouldAddField = true;

      if (fieldValue == null) {
        fieldType = 'String?';
        defaultValue = '';
      } else if (fieldValue is String) {
        fieldType = 'String';
        defaultValue = "@Default('')";
      } else if (fieldValue is int) {
        fieldType = 'int';
        defaultValue = '@Default(0)';
      } else if (fieldValue is double) {
        fieldType = 'double';
        defaultValue = '@Default(0.0)';
      } else if (fieldValue is bool) {
        fieldType = 'bool';
        defaultValue = '@Default(false)';
      } else if (fieldValue is List) {
        if (fieldValue.isEmpty) {
          fieldType = 'List<dynamic>';
          defaultValue = '@Default([])';
        } else {
          final itemResult = _getListItemTypeWithNested(
            fieldValue.first,
            parentClassName,
            fieldName,
            depth,
          );
          fieldType = 'List<${itemResult.type}>';
          defaultValue = '@Default([])';
          nestedClasses.addAll(itemResult.nestedClasses);
        }
      } else if (fieldValue is Map<String, dynamic>) {
        // If the nested object has no fields OR nested class ends up empty -> skip this field entirely
        if (fieldValue.isEmpty) {
          shouldAddField = false;
        } else {
          final nestedClassName = '${parentClassName}${_toPascalCase(dartFieldName)}';
          final nestedResult = _generateModelClassWithNested(
            nestedClassName,
            fieldValue,
            depth: depth + 1,
          );
          if (nestedResult.mainClass.trim().isEmpty) {
            shouldAddField = false;
          } else {
            fieldType = '$nestedClassName?';
            nestedClasses.add(
              NestedClassInfo(
                className: nestedClassName,
                result: nestedResult,
                shouldEmbed: true,
              ),
            );
          }
        }
      } else {
        fieldType = 'dynamic';
        defaultValue = '';
      }

      if (shouldAddField && fieldType.isNotEmpty) {
        final jsonKey = "@JsonKey(name: '$fieldName')";
        final field = fieldType.endsWith('?')
            ? '$jsonKey $fieldType $dartFieldName'
            : '$defaultValue $jsonKey $fieldType $dartFieldName';

        fields.add(field);
      }
    }

    return FieldGenerationResult(fields: fields, nestedClasses: nestedClasses);
  }

  ListItemResult _getListItemTypeWithNested(
    dynamic item,
    String parentClassName,
    String fieldName,
    int depth,
  ) {
    if (item is String) {
      return ListItemResult(type: 'String', nestedClasses: const []);
    }
    if (item is int) {
      return ListItemResult(type: 'int', nestedClasses: const []);
    }
    if (item is double) {
      return ListItemResult(type: 'double', nestedClasses: const []);
    }
    if (item is bool) {
      return ListItemResult(type: 'bool', nestedClasses: const []);
    }

    if (item is Map<String, dynamic>) {
      final itemClassName = '${parentClassName}${_toPascalCase(fieldName)}Item';
      final itemResult = _generateModelClassWithNested(
        itemClassName,
        item,
        depth: depth + 1,
      );

      if (itemResult.mainClass.trim().isEmpty) {
        return ListItemResult(type: 'Map<String, dynamic>', nestedClasses: const []);
      }

      final nestedClasses = <NestedClassInfo>[
        NestedClassInfo(
          className: itemClassName,
          result: itemResult,
          shouldEmbed: true,
        ),
        ...itemResult.nestedClasses,
      ];

      return ListItemResult(type: itemClassName, nestedClasses: nestedClasses);
    }

    return ListItemResult(type: 'dynamic', nestedClasses: const []);
  }

  String _modelNameToFileName(String modelName) {
    if (modelName.isEmpty) return '';

    // Convert PascalCase to snake_case
    var fileName = modelName
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]}_${match[2]}')
        .toLowerCase();

    return fileName;
  }

  void _writeModelFile(String fileName, String content) {
    final filePath = '$_modelApiPath/$fileName.dart';
    final file = File(filePath);

    // Create directory if it doesn't exist
    file.parent.createSync(recursive: true);

    // If content is empty, skip writing file
    if (content.trim().isEmpty) return;

    // Update imports in the content
    final updatedContent = content
        .replaceFirst(
            "part '${_modelNameToFileName('')}.freezed.dart';", "part '$fileName.freezed.dart'")
        .replaceFirst("part '${_modelNameToFileName('')}.g.dart';", "part '$fileName.g.dart';");

    file.writeAsStringSync(updatedContent);
  }

  void _writeRequestModelFile(String fileName, String content) {
    final filePath = '$_requestModelPath/$fileName.dart';
    final file = File(filePath);

    // Create directory if it doesn't exist
    file.parent.createSync(recursive: true);

    // If content is empty, skip writing file
    if (content.trim().isEmpty) return;

    // Update imports in the content
    final updatedContent = content
        .replaceFirst(
            "part '${_modelNameToFileName('')}.freezed.dart';", "part '$fileName.freezed.dart'")
        .replaceFirst("part '${_modelNameToFileName('')}.g.dart';", "part '$fileName.g.dart';");

    file.writeAsStringSync(updatedContent);
  }

  void _writeNestedRequestClassFiles(
    List<NestedClassInfo> nestedClasses,
    List<String> generatedModels,
  ) {
    for (final nested in nestedClasses) {
      if (generatedModels.contains(nested.className)) continue;
      final nestedResult = _buildGenerationResult(nested.className, nested.result);
      final nestedFileName = _modelNameToFileName(nested.className);
      _writeRequestModelFile(nestedFileName, nestedResult.mainContent);
      generatedModels.add(nested.className);
      _usedModelNames.add(nested.className);
      if (nestedResult.nestedClasses.isNotEmpty) {
        _writeNestedRequestClassFiles(nestedResult.nestedClasses, generatedModels);
      }
    }
  }

  void _writeEnumFile(String enumName, String content) {
    final fileName = _modelNameToFileName(enumName);
    final filePath = '$_enumPath/$fileName.dart';
    final file = File(filePath);

    // Create directory if it doesn't exist
    file.parent.createSync(recursive: true);

    // If content is empty, skip writing file
    if (content.trim().isEmpty) return;

    file.writeAsStringSync(content);
  }

  String _toPascalCase(String input) {
    if (input.isEmpty) return '';

    return input
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => _capitalizeWord(word))
        .join('');
  }

  String _capitalizeWord(String word) {
    if (word.isEmpty) return '';

    // Simple capitalization - first letter uppercase, rest lowercase
    return word[0].toUpperCase() + word.substring(1);
  }

  String _toCamelCase(String input) {
    if (input.isEmpty) return '';

    // Handle cases like 'salary_type' -> 'salaryType' or 'salaryType' -> 'salaryType'
    if (input.contains('_')) {
      // Convert from snake_case
      final parts = input.split('_').where((part) => part.isNotEmpty).toList();
      if (parts.isEmpty) return '';

      final result = parts.first.toLowerCase() +
          parts
              .skip(1)
              .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
              .join('');
      return result;
    } else {
      // Already in camelCase or PascalCase, ensure first letter is lowercase
      return input[0].toLowerCase() + input.substring(1);
    }
  }
}

class EndpointInfo {
  final String method;
  final String path;
  final List<QueryParam> queryParams;
  final bool hasBody;
  final Map<String, dynamic>? bodySchema;
  final Map<String, dynamic>? responseSchema;
  final Map<String, dynamic>? wrappedResponseSchema;
  final String? responseSchemaName;
  final String? operationId;
  final String? summary;
  final List<String> tags;

  EndpointInfo({
    required this.method,
    required this.path,
    required this.queryParams,
    required this.hasBody,
    this.bodySchema,
    this.responseSchema,
    this.wrappedResponseSchema,
    this.responseSchemaName,
    this.operationId,
    this.summary,
    this.tags = const [],
  });
}

class QueryParam {
  final String name;
  final String type;
  final bool required;

  QueryParam({
    required this.name,
    required this.type,
    required this.required,
  });
}

class BodyParamsGenerationResult {
  BodyParamsGenerationResult({
    required this.paramSignatures,
    required this.bodySetupLines,
    required this.bodyArgument,
  });

  final List<String> paramSignatures;
  final List<String> bodySetupLines;
  final String bodyArgument;
}

class ModelGenerationResult {
  ModelGenerationResult({
    required this.mainContent,
    required this.nestedClasses,
  });

  final String mainContent;
  final List<NestedClassInfo> nestedClasses;
}

class ModelClassResult {
  ModelClassResult({
    required this.mainClass,
    required this.nestedClasses,
  });

  final String mainClass;
  final List<NestedClassInfo> nestedClasses;
}

class FieldGenerationResult {
  FieldGenerationResult({
    required this.fields,
    required this.nestedClasses,
  });

  final List<String> fields;
  final List<NestedClassInfo> nestedClasses;
}

class ListItemResult {
  ListItemResult({
    required this.type,
    required this.nestedClasses,
  });

  final String type;
  final List<NestedClassInfo> nestedClasses;
}

class NestedClassInfo {
  NestedClassInfo({
    required this.className,
    required this.result,
    required this.shouldEmbed,
  });

  final String className;
  final ModelClassResult result;
  final bool shouldEmbed;
}
