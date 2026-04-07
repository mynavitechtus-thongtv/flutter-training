# Model Classes Instructions

## Overview

Guidelines for creating and managing model classes: API models, Firebase models, Database models (Isar), State models, Enums, and other models.

## Model Categories

| Type | Location | Purpose |
|------|----------|---------|
| **API Models** | `lib/model/api/` | Data from REST APIs |
| **Firebase Models** | `lib/model/firebase/` | Cloud Firestore data |
| **Database Models** | `lib/model/database/` | Local Isar database |
| **State Models** | `lib/ui/page/.../view_model/` | UI page state |
| **Enum Models** | `lib/model/enum/` | App-wide enums |
| **Other Models** | `lib/model/other/` | Business logic models |

## 1. API Models

### Required Rules

- Use `@freezed`
- Use `@Default()` for all non-nullable fields
- Use `@JsonKey(name: 'field_name')` to map to API fields
- Use `@ApiDateTimeConverter()` for DateTime fields
- Use enums instead of raw Strings where applicable

### Basic Structure

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../index.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
sealed class UserProfile with _$UserProfile {
  const UserProfile._(); // Allows adding custom methods

  const factory UserProfile({
    @Default(0) @JsonKey(name: 'id') int id,
    @Default('') @JsonKey(name: 'email') String email,
    @Default('') @JsonKey(name: 'first_name') String firstName,
    @Default('') @JsonKey(name: 'last_name') String lastName,
    @Default(Gender.notApplicable) @JsonKey(name: 'gender') Gender gender,
    @ApiDateTimeConverter() @JsonKey(name: 'created_at') DateTime? createdAt,
    @Default(Status.unverified) @JsonKey(name: 'status') Status status,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => 
      _$UserProfileFromJson(json);

  // Custom methods
  String get fullName => '$firstName $lastName'.trim();
  bool get hasVerifiedEmail => status == Status.verified;
}
```

### Default Values

```dart
// GOOD - Always provide default value
const factory ApiUserData({
  @Default(0) int id,                           // Number: 0
  @Default('') String name,                     // String: empty
  @Default(false) bool isActive,                // Boolean: false
  @Default([]) List<String> tags,               // List: empty
  @Default(UserStatus.active) UserStatus status, // Enum: default value
  @Default(ApiAddress()) ApiAddress address,     // Object: default constructor
  DateTime? createdAt,                           // Nullable: no @Default needed
}) = _ApiUserData;

// BAD - Missing @Default for non-nullable fields
const factory ApiUserData({
  int id,              // Error: must have @Default
  String name,         // Error: must have @Default
}) = _ApiUserData;
```

### Use Enum in API Models

```dart
// Enum with @JsonEnum
@JsonEnum(valueField: 'value')
enum Gender {
  male(value: 'male'),
  female(value: 'female'),
  notApplicable(value: 'not_applicable');

  final String value;
  const Gender({required this.value});
}

// Use in model
const factory UserProfile({
  @Default(Gender.notApplicable) @JsonKey(name: 'gender') Gender gender,
}) = _UserProfile;
```

## 2. Firebase Models

### Required Rules

- Use `@freezed`
- Use `@Default()` for all fields
- Define constant keys for all fields (pattern: `keyFieldName`)
- Define default values for all fields (pattern: `defaultFieldName`)
- Use `@TimestampConverter()` for DateTime fields
- Use custom converters for nested objects

### Basic Structure

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../index.dart';

part 'firebase_conversation_data.freezed.dart';
part 'firebase_conversation_data.g.dart';

@freezed
sealed class FirebaseConversationData with _$FirebaseConversationData {
  const FirebaseConversationData._();

  const factory FirebaseConversationData({
    @Default(FirebaseConversationData.defaultId)
    @JsonKey(name: FirebaseConversationData.keyId)
    String id,
    
    @Default(FirebaseConversationData.defaultLastMessage)
    @JsonKey(name: FirebaseConversationData.keyLastMessage)
    String lastMessage,
    
    @Default(FirebaseConversationData.defaultCreatedAt)
    @TimestampConverter()
    @JsonKey(name: FirebaseConversationData.keyCreatedAt)
    DateTime? createdAt,
  }) = _FirebaseConversationData;

  factory FirebaseConversationData.fromJson(Map<String, dynamic> json) =>
      _$FirebaseConversationDataFromJson(json);

  // Constant keys - REQUIRED
  static const keyId = 'id';
  static const keyLastMessage = 'last_message';
  static const keyCreatedAt = 'created_at';

  // Default values - REQUIRED
  static const defaultId = '';
  static const defaultLastMessage = '';
  static const defaultCreatedAt = null;

  // Custom methods
  bool get hasMessages => lastMessage.isNotEmpty;
}
```

### Why Use Constant Keys and Default Values

```dart
// Benefits:

// 1. Easier Firestore queries
FirebaseFirestore.instance
    .collection('conversations')
    .where(FirebaseConversationData.keyUpdatedAt, isGreaterThan: Timestamp.now())
    .orderBy(FirebaseConversationData.keyUpdatedAt, descending: true);

// 2. Safer document create/update
FirebaseFirestore.instance
    .collection('conversations')
    .doc(conversationId)
    .set({
      FirebaseConversationData.keyLastMessage: message,
      FirebaseConversationData.keyUpdatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

// 3. Consistency - change in one place
// 4. IDE autocomplete and type-safety
```

## 3. Database Models (Isar)

### Required Rules

- **REQUIRED** File and class name must start with `local_`
- **REQUIRED** Use `@collection` annotation
- **REQUIRED** Override methods: `==`, `hashCode`, `toString()`
- **REQUIRED** Has field `uniqueId` with `@Index(unique: true, replace: true)`
- **REQUIRED** Has field `Id id = Isar.autoIncrement`
- **DO NOT** use `@freezed` (Isar not compatible with Freezed)
- **RECOMMENDED** Use `@Enumerated(EnumType.value, 'code')` for enum
- **RECOMMENDED** Use enum instead of String when possible

### Basic Structure

```dart
import 'package:isar_community/isar.dart';
import '../../index.dart';

part 'local_message_data.g.dart';

@collection
class LocalMessageData {
  LocalMessageData({
    this.uniqueId = '',
    this.userId = '',
    this.conversationId = '',
    this.type = MessageType.text,
    this.status = MessageStatus.sending,
    this.message = '',
    this.createdAt = 0,
    this.updatedAt = 0,
  }) : assert(createdAt > 0);

  // REQUIRED - Auto increment ID
  Id id = Isar.autoIncrement;

  // REQUIRED - Unique identifier with index
  @Index(unique: true, replace: true)
  String uniqueId;

  // Other fields
  String userId;
  String conversationId;

  // Enum with @Enumerated
  @Enumerated(EnumType.value, 'code')
  MessageType type;

  @Enumerated(EnumType.value, 'code')
  MessageStatus status;

  String message;
  int createdAt;
  int updatedAt;

  // REQUIRED - Override toString
  @override
  String toString() {
    return 'LocalMessageData{id: $id, uniqueId: $uniqueId, userId: $userId, '
        'conversationId: $conversationId, type: $type, status: $status, '
        'message: $message, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  // REQUIRED - Override ==
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalMessageData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uniqueId == other.uniqueId &&
          userId == other.userId &&
          conversationId == other.conversationId &&
          type == other.type &&
          status == other.status &&
          message == other.message &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  // REQUIRED - Override hashCode
  @override
  int get hashCode =>
      id.hashCode ^
      uniqueId.hashCode ^
      userId.hashCode ^
      conversationId.hashCode ^
      type.hashCode ^
      status.hashCode ^
      message.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  // Custom methods
  bool get isSending => status == MessageStatus.sending;
  bool get isFailed => status == MessageStatus.failed;
  DateTime get createdDateTime => 
      DateTime.fromMillisecondsSinceEpoch(createdAt);
}
```

### Naming Conventions

```dart
// GOOD - Start with local_
class LocalMessageData { }
class LocalUserSettings { }

// Files:
// local_message_data.dart
// local_user_settings.dart

// BAD - Missing local_ prefix
class MessageData { }    // Error!
class UserSettings { }   // Error!
```

### uniqueId with @Index

```dart
// GOOD - uniqueId with unique index
@collection
class LocalMessageData {
  LocalMessageData({this.uniqueId = ''});

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String uniqueId;  // Typically an ID from Firebase or API
}

// Benefits:
// - Avoid duplicate data
// - replace: true → automatically replaces on duplicate insert
// - Easy to search by uniqueId
```

## 4. State Models

### Required Rules

- **REQUIRED** Extends `BaseState`
- **REQUIRED** Use `@freezed` annotation
- **REQUIRED** Use `@Default()` for all non-nullable fields
- **RECOMMENDED** Add custom getter methods for complex logic
- **DO NOT** contain business logic (only data and computed properties)

### Basic Structure

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../index.dart';

part 'user_profile_state.freezed.dart';

@freezed
sealed class UserProfileState extends BaseState with _$UserProfileState {
  const UserProfileState._();

  const factory UserProfileState({
    UserProfile? userProfile,
    @Default('') String email,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default(Gender.notApplicable) Gender selectedGender,
    @Default(false) bool isEditing,
    @Default({}) Map<String, String> validationErrors,
  }) = _UserProfileState;

  // Custom getters - Computed properties
  bool get hasValidationErrors => validationErrors.isNotEmpty;
  
  bool get canSave => 
      isEditing && 
      email.isNotEmpty && 
      firstName.isNotEmpty && 
      !hasValidationErrors;
  
  String get fullName => '$firstName $lastName'.trim();
  
  String? get emailError => validationErrors['email'];
  String? get firstNameError => validationErrors['firstName'];
}
```

### State with Form Validation

```dart
@freezed
sealed class LoginState extends BaseState with _$LoginState {
  const LoginState._();

  const factory LoginState({
    @Default('') String email,
    @Default('') String password,
    @Default('') String emailError,
    @Default('') String passwordError,
    @Default(false) bool isPasswordVisible,
    @Default(false) bool rememberMe,
  }) = _LoginState;

  // Validation getters
  bool get hasEmailError => emailError.isNotEmpty;
  bool get hasPasswordError => passwordError.isNotEmpty;
  bool get hasAnyError => hasEmailError || hasPasswordError;
  
  bool get isEmailValid => 
      email.isNotEmpty && email.contains('@') && !hasEmailError;
  
  bool get isPasswordValid => 
      password.isNotEmpty && password.length >= 8 && !hasPasswordError;
  
  bool get canSubmit => 
      isEmailValid && isPasswordValid && !hasAnyError;
}
```

## 5. Enum Models

### Two Enum Types

#### 5.1. Enums in UI (Component / Popup / Page)

**When to use:** Enum only used inside a specific UI component

**Location:** Declare directly in component file

```dart
// lib/ui/component/common_divider.dart
class CommonDivider extends StatelessWidget {
  const CommonDivider({
    super.key,
    this.direction = DividerDirection.horizontal,
  });

  final DividerDirection direction;

  @override
  Widget build(BuildContext context) {
    return direction == DividerDirection.horizontal
        ? Divider()
        : VerticalDivider();
  }
}

// Enum declared in same component file
enum DividerDirection {
  vertical,
  horizontal;

  // Use getters instead of extensions
  bool get isHorizontal => this == DividerDirection.horizontal;
  bool get isVertical => this == DividerDirection.vertical;
}
```

#### 5.2. Global Enums

**When to use:**
- Enum from API response
- Enum used in multiple places in app
- Enum related to business logic

**Location:** `lib/model/enum/`

```dart
// lib/model/enum/gender.dart
import 'package:json_annotation/json_annotation.dart';
import '../../index.dart';

// Enum with @JsonEnum for API
@JsonEnum(valueField: 'value')
enum Gender {
  male(value: 'male'),
  female(value: 'female'),
  unknown(value: 'unknown'),
  notApplicable(value: 'not_applicable');

  final String value;
  const Gender({required this.value});

  // Use getter instead of extension method
  String get displayText {
    switch (this) {
      case Gender.male:
        return l10n.signUpGenderMale;
      case Gender.female:
        return l10n.signUpGenderFemale;
      case Gender.unknown:
        return l10n.signUpGenderUnknown;
      case Gender.notApplicable:
        return l10n.signUpGenderNotApplicable;
    }
  }

  bool get isMale => this == Gender.male;
  bool get isFemale => this == Gender.female;
}
```

```dart
// lib/model/enum/message_type.dart
import 'package:freezed_annotation/freezed_annotation.dart';

// Enum with int code for Database (Isar)
@JsonEnum(valueField: 'code')
enum MessageType {
  @JsonValue(0)
  text(0),
  @JsonValue(1)
  image(1),
  @JsonValue(2)
  video(2),
  @JsonValue(3)
  voice(3);

  const MessageType(this.code);
  final int code;

  // Getter methods
  bool get isText => this == MessageType.text;
  bool get isMedia => this == MessageType.image || this == MessageType.video;
  bool get isVoice => this == MessageType.voice;
}
```

### Required Rules for Enum

- **REQUIRED** Use getter methods, **DO NOT** use extension methods
- **REQUIRED** Use `@JsonEnum(valueField: 'value')` or `@JsonValue()` for API enum
- **RECOMMENDED** Use int code for Database enum (Isar)
- **RECOMMENDED** Use switch expression instead of if-else

```dart
// GOOD - Use getter
enum MessageType {
  text(0),
  image(1);

  const MessageType(this.code);
  final int code;

  bool get isText => this == MessageType.text;
  String get displayName => switch (this) {
    MessageType.text => 'Text Message',
    MessageType.image => 'Image Message',
  };
}

// BAD - Use extension method
extension MessageTypeExtension on MessageType {  // DO NOT DO THIS!
  bool get isText => this == MessageType.text;
}
```

## 6. Other Models

### Classification Rules

**Place in `lib/model/other/`** when:
- Model related to business logic
- Base Model used in multiple places
- Model not belonging to API, Firebase, Database, or State

**Place in UI file** when:
- Model only used for 1 specific component, popup or page

### Example: Model in `lib/model/other/`

```dart
// lib/model/other/app_notification.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

@freezed
sealed class AppNotification with _$AppNotification {
  const factory AppNotification({
    @Default('') String image,
    @Default('') String title,
    @Default('') String message,
    @Default('') String conversationId,
  }) = _AppNotification;
}
```

### Example: Model in UI File

```dart
// lib/ui/component/common_dropdown.dart

// Model declared in component file (only used for CommonDropdown)
class CommonDropdownItem<T> {
  const CommonDropdownItem({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class CommonDropdown<T> extends HookWidget {
  const CommonDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
  });

  final List<CommonDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## 7. Converters

### Required Rules

- **REQUIRED** Implements `JsonConverter<T, K>`
- **REQUIRED** Override `fromJson()` and `toJson()`
- **REQUIRED** Place in `lib/model/converter/`
- **RECOMMENDED** Handle null and edge cases

### DateTime Converter for API

```dart
// lib/model/converter/api_date_time_converter.dart
import 'package:json_annotation/json_annotation.dart';
import '../../index.dart';

class ApiDateTimeConverter implements JsonConverter<DateTime?, Map<String, dynamic>> {
  const ApiDateTimeConverter();

  @override
  DateTime? fromJson(Map<String, dynamic> json) => DateTimeUtil.tryParse(
        safeCast(json['date']),
        format: 'yyyy-MM-dd\'T\'HH:mm:ssZ',
      );

  @override
  Map<String, dynamic> toJson(DateTime? object) => {
        'date': object?.toIso8601String(),
      };
}

// Usage in API model
@freezed
sealed class ApiEventData with _$ApiEventData {
  const factory ApiEventData({
    @ApiDateTimeConverter() 
    @JsonKey(name: 'created_at') 
    DateTime? createdAt,
  }) = _ApiEventData;
}
```

### Timestamp Converter for Firebase

```dart
// lib/model/converter/timestamp_converter.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

class TimestampConverter implements JsonConverter<DateTime?, Timestamp?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Timestamp? timestamp) {
    return timestamp?.toDate();
  }

  @override
  Timestamp? toJson(DateTime? date) => 
      date != null ? Timestamp.fromDate(date) : null;
}

// Usage in Firebase model
@freezed
sealed class FirebaseMessageData with _$FirebaseMessageData {
  const factory FirebaseMessageData({
    @TimestampConverter()
    @JsonKey(name: FirebaseMessageData.keyCreatedAt)
    DateTime? createdAt,
  }) = _FirebaseMessageData;

  static const keyCreatedAt = 'created_at';
}
```

## Code Generation Commands

After creating or modifying models, run:

```bash
# Generate Freezed and JSON serialization code
make fb

# Or
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto rebuild when file changes)
flutter packages pub run build_runner watch --delete-conflicting-outputs
```

## Best Practices

### 1. Null Safety and Default Values

```dart
// GOOD - Always has default value or nullable
const factory UserProfile({
  @Default(0) int id,              // Non-null with default
  @Default('') String name,        // Empty string default
  String? nickname,                // Nullable - OK no default
  @Default([]) List<String> tags,  // Empty list default
}) = _UserProfile;

// BAD - Non-nullable without default
const factory UserProfile({
  int id,       // Error!
  String name,  // Error!
}) = _UserProfile;
```

### 2. Custom Methods for Business Logic

```dart
@freezed
sealed class UserProfile with _$UserProfile {
  const UserProfile._();  // ← Required for custom methods

  const factory UserProfile({
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String email,
    @Default(Status.unverified) Status status,
  }) = _UserProfile;

  // Custom methods
  String get fullName => '$firstName $lastName'.trim();
  
  bool get hasFullName => 
      firstName.isNotEmpty && lastName.isNotEmpty;
  
  bool get isVerified => status == Status.verified;
  
  bool get canSendMessage => 
      isVerified && email.isNotEmpty;
}
```

### 3. CopyWith for Partial Updates

```dart
// Freezed automatically generates copyWith
final user = UserProfile(
  id: 1,
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
);

// Update one field
final updatedUser = user.copyWith(email: 'newemail@example.com');

// Update multiple fields
final fullyUpdatedUser = user.copyWith(
  firstName: 'Jane',
  lastName: 'Smith',
  email: 'jane@example.com',
);
```

## Checklist When Creating New Model

### API Model
- [ ] File in `lib/model/api/`
- [ ] Use `@freezed` annotation
- [ ] Has `part 'file_name.freezed.dart'` and `part 'file_name.g.dart'`
- [ ] All non-nullable fields have `@Default()`
- [ ] All fields have `@JsonKey(name: 'api_field_name')`
- [ ] DateTime fields use `@ApiDateTimeConverter()`
- [ ] Enum fields use `@JsonEnum` or `@JsonValue()`
- [ ] Has `factory fromJson()`

### Firebase Model
- [ ] File in `lib/model/firebase/`
- [ ] Use `@freezed` annotation
- [ ] All fields have `@Default()`
- [ ] Define all constant keys (`static const keyFieldName`)
- [ ] Define all default values (`static const defaultFieldName`)
- [ ] DateTime fields use `@TimestampConverter()`
- [ ] Has `factory fromJson()`

### Database Model (Isar)
- [ ] File in `lib/model/database/`
- [ ] File and class name start with `local_`
- [ ] Use `@collection` annotation
- [ ] Has `part 'file_name.g.dart'`
- [ ] Has field `Id id = Isar.autoIncrement`
- [ ] Has field `uniqueId` with `@Index(unique: true, replace: true)`
- [ ] Enum use `@Enumerated(EnumType.value, 'code')`
- [ ] Override `==` operator
- [ ] Override `hashCode`
- [ ] Override `toString()`
- [ ] DO NOT use `@freezed`

### State Model
- [ ] Extends `BaseState`
- [ ] Use `@freezed` annotation
- [ ] Has `part 'state_name.freezed.dart'`
- [ ] All non-nullable fields have `@Default()`
- [ ] Has `const StateName._();` if has custom getters
- [ ] Has custom getters for computed properties
- [ ] DO NOT contain business logic

### Enum
- [ ] Place in correct location (component/page or lib/model/enum/)
- [ ] Use getter methods, DO NOT use extension
- [ ] Global enum has `@JsonEnum(valueField: 'value')` or `@JsonValue()`
- [ ] Database enum has int code
- [ ] Has getter for display text if needed

### Converter
- [ ] File in `lib/model/converter/`
- [ ] Implements `JsonConverter<T, K>`
- [ ] Override `fromJson()` method
- [ ] Override `toJson()` method
- [ ] Handle null cases
- [ ] Handle edge cases
