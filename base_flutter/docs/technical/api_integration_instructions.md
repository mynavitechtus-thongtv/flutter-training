# API Integration Instructions

## Overview

This document provides comprehensive guidelines for API integration in the project, focusing on creating API service functions and model classes using the established patterns.

## Core Rules

1. **Check existing models first** - Do not create new models if they already exist in the project
2. **Use Freezed for all API models** - For immutability and JSON serialization
3. **Always provide default values** - Use `@Default()` for all non-nullable fields
4. **Map JSON keys properly** - Use `@JsonKey(name: 'api_field_name')` for all fields

## Core Components

- **RestApiClient**: Base client for all HTTP requests with built-in error handling and response decoding
- **AppApiService**: Service layer containing all API endpoint methods
- **Model Classes**: Data transfer objects using Freezed for immutability and JSON serialization
- **Converters**: Custom JSON converters for complex data types like DateTime, enums, etc.

## API Service Pattern

### Basic Request Structure

```dart
Future<ReturnType?> methodName({
  required String param1,
  int? optionalParam,
}) async {
  final response = await _authAppServerApiClient.request<ModelType, ResponseWrapper<ModelType>>(
    method: RestMethod.post,
    path: 'api/v1/endpoint',
    body: {
      'param1': param1,
      if (optionalParam != null) 'optional_param': optionalParam,
    },
    decoder: (json) => ModelType.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
  );
  
  return response?.data ?? const ModelType();
}
```

### Key Points:
- Always provide fallback values: `response?.data ?? const ModelType()`
- Use safe casting: `json.safeCast<Map<String, dynamic>>() ?? {}`
- Use conditional parameters: `if (param != null) 'key': param`

## SuccessResponseDecoderType

Choose the appropriate decoder type based on API response format:

| Type | Response Format | Use Case |
|------|----------------|----------|
| `dataJsonObject` (default) | `{data: {...}}` | Single object wrapped in data |
| `dataJsonArray` | `{data: [...]}` | Array wrapped in data |
| `jsonObject` | `{id: 1, ...}` | Direct object response |
| `jsonArray` | `[{...}, {...}]` | Direct array response |
| `paging` | `{data: [...], meta: {...}}` | Paginated responses |
| `plain` | Plain text/empty | No JSON decoding needed |

### Examples:

**dataJsonObject (default)**:
```dart
Future<ApiUserData> getUser({required int id}) async {
  final response = await _authAppServerApiClient.request<ApiUserData, DataResponse<ApiUserData>>(
    method: RestMethod.get,
    path: 'api/v1/users/$id',
    // successResponseDecoderType: SuccessResponseDecoderType.dataJsonObject, // Can be omitted
    decoder: (json) => ApiUserData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
  );
  return response?.data ?? const ApiUserData();
}
```

**dataJsonArray**:
```dart
Future<DataListResponse<ApiUserTypeData>?> getUserTypes() {
  return _authAppServerApiClient.request(
    method: RestMethod.get,
    path: 'api/v1/user-types',
    successResponseDecoderType: SuccessResponseDecoderType.dataJsonArray,
    decoder: (json) => ApiUserTypeData.fromJson(json.safeCast<Map<String, dynamic>>() ?? {}),
  );
}
```

**plain** (for void responses):
```dart
Future<void> confirmEmail({required String token}) async {
  await _authAppServerApiClient.request(
    method: RestMethod.post,
    path: 'api/v1/user/email/confirm',
    body: {'confirmation_token': token},
    successResponseDecoderType: SuccessResponseDecoderType.plain,
  );
}
```

## Custom Response Decoder

Use `customSuccessResponseDecoder` when you need to:
- Extract data from response headers
- Perform complex response transformation
- Extract specific nested fields

```dart
Future<ApiTokenData?> signIn({
  required String email,
  required String password,
}) async {
  return _noneAuthAppServerApiClient.request(
    method: RestMethod.post,
    path: 'api/v1/auth/sign_in',
    body: {'email': email, 'password': password},
    customSuccessResponseDecoder: (response) {
      final headerMap = response.headers.map;
      final bodyMap = response.data;
      
      return ApiTokenData(
        accessToken: headerMap[Constant.accessTokenKey]?.firstOrNull ?? '',
        client: headerMap[Constant.clientKey]?.firstOrNull ?? '',
        uid: headerMap[Constant.uidKey]?.firstOrNull ?? '',
        userId: int.tryParse(bodyMap['data']?['id']?.toString() ?? '0') ?? 0,
      );
    }
  );
}
```

## Custom Headers & Options

Use `Options` parameter for custom headers, timeouts, or content types:

```dart
Future<void> resetPassword({
  required String uid,
  required String accessToken,
  required String password,
}) async {
  await _noneAuthAppServerApiClient.request(
    method: RestMethod.put,
    path: 'api/v1/auth/password',
    options: Options(
      headers: {
        Constant.uidKey: uid,
        Constant.accessTokenKey: accessToken,
      },
      receiveTimeout: Duration(seconds: 30),
    ),
    body: {
      'password': password,
      'password_confirmation': password,
    },
  );
}
```

## Model Class Structure

### Basic Pattern

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../index.dart';

part 'api_user_data.freezed.dart';
part 'api_user_data.g.dart';

@freezed
sealed class ApiUserData with _$ApiUserData {
  const ApiUserData._(); // Required for custom methods

  const factory ApiUserData({
    @Default(0) int id,
    @Default('') @JsonKey(name: 'user_name') String name,
    @Default('') @JsonKey(name: 'email') String email,
    @ApiDateTimeConverter() @JsonKey(name: 'created_at') DateTime? createdAt,
    @Default(UserStatus.active) @JsonKey(name: 'status') UserStatus status,
  }) = _ApiUserData;

  factory ApiUserData.fromJson(Map<String, dynamic> json) => 
      _$ApiUserDataFromJson(json);

  // Custom methods
  String get displayName => name.isEmpty ? 'Unnamed User' : name;
  bool get isActive => status == UserStatus.active;
}
```

### Naming Conventions

- **API Models**: `Api[EntityName]Data` (e.g., `ApiUserData`, `ApiProductData`)
- **Enums**: `[EntityName][PropertyName]` (e.g., `UserStatus`, `ProductType`)
- **Converters**: `[Type]Converter` (e.g., `ApiDateTimeConverter`)

### Default Values

```dart
const factory ApiUserData({
  @Default(0) int id,                           // Primitive: 0
  @Default('') String name,                     // String: empty
  @Default(false) bool isActive,                // Boolean: false
  @Default([]) List<String> tags,               // List: empty
  @Default(ApiAddress()) ApiAddress address,    // Object: default constructor
  DateTime? createdAt,                          // Nullable: no @Default needed
}) = _ApiUserData;
```

## Enum Implementation

```dart
enum UserStatus {
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('deleted')
  deleted;

  String get code => switch (this) {
    UserStatus.active => 'active',
    UserStatus.inactive => 'inactive',
    UserStatus.deleted => 'deleted',
  };

  static UserStatus fromCode(String code) => switch (code) {
    'active' => UserStatus.active,
    'inactive' => UserStatus.inactive,
    'deleted' => UserStatus.deleted,
    _ => UserStatus.active, // Default fallback
  };

  String get displayName => switch (this) {
    UserStatus.active => 'Active',
    UserStatus.inactive => 'Inactive',
    UserStatus.deleted => 'Deleted',
  };
}
```

## DateTime Converter

```dart
import 'package:json_annotation/json_annotation.dart';
import '../../../index.dart';

class ApiDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const ApiDateTimeConverter();

  @override
  DateTime? fromJson(String? dateString) => DateTimeUtil.tryParse(dateString)?.toLocal();

  @override
  String? toJson(DateTime? object) => object?.formatApiString();
}

// Usage in model
@ApiDateTimeConverter() @JsonKey(name: 'created_at') DateTime? createdAt,
```

## Validation in Models

Add validation methods to ensure data integrity:

```dart
@freezed
sealed class ApiUserData with _$ApiUserData {
  const ApiUserData._();
  
  const factory ApiUserData({...}) = _ApiUserData;
  
  factory ApiUserData.fromJson(Map<String, dynamic> json) => _$ApiUserDataFromJson(json);
  
  // Validation methods
  bool get hasValidEmail => email.contains('@') && email.isNotEmpty;
  bool get hasValidName => name.isNotEmpty && name.length <= 50;
  
  List<String> get validationErrors {
    final errors = <String>[];
    if (!hasValidName) errors.add('Invalid name');
    if (!hasValidEmail) errors.add('Invalid email');
    return errors;
  }
  
  bool get isValid => validationErrors.isEmpty;
}
```

## Code Generation

Before finishing, run this command to generate the necessary build files:

```bash
make fb
```

## Common Mistakes to Avoid

- Missing `@Default()` for non-nullable fields
- Not using `@JsonKey(name:)` for API field mapping
- Forgetting `const factory` and `const ClassName._()` pattern
- Not providing fallback values (`?? const Model()`)
- Creating duplicate models without checking existing ones
- Using wrong `SuccessResponseDecoderType` for response format
- Not using `safeCast` for type safety
- Missing `sealed` keyword in Freezed classes

## Best Practices Summary

1. Always provide fallback values: `response?.data ?? const Model()`
2. Use safe casting: `json.safeCast<Map<String, dynamic>>() ?? {}`
3. Use conditional body parameters: `if (param != null) 'key': param`
4. Add validation methods to models
5. Use descriptive names following conventions
6. Add custom methods for computed properties
7. Handle nullable fields appropriately
8. Run code generation after model changes

This comprehensive guide covers all essential patterns for API integration in the codebase.
