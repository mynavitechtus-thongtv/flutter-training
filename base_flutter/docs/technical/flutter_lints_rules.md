# Flutter Lint Rules

This document lists every standard Dart/Flutter lint enabled in `analysis_options.yaml`.
Each entry links to the official lint description on dart.dev and summarizes the
expectation enforced in this repository.

## Overview

The Flutter/Dart analyzer runs with `flutter_lints` plus additional project-specific
settings. 

## Rule Reference
### 1. always_declare_return_types

- **Summary**: Always annotate return types on functions, methods, and getters to avoid implicit dynamic.

### 2. annotate_overrides

- **Summary**: Add @override whenever overriding a member from a superclass or interface.

### 3. avoid_empty_else

- **Summary**: Remove empty else blocks; use an if-only statement or provide logic.

### 4. avoid_init_to_null

- **Summary**: Do not assign null when declaring variables; they are null by default.

### 5. avoid_multiple_declarations_per_line

- **Summary**: Declare a single variable, field, or getter per line for clarity.

### 6. avoid_null_checks_in_equality_operators

- **Summary**: Inside operator== overrides, avoid explicit null checks; use 'identical' or pattern recommended by Dart.

### 7. avoid_print

- **Summary**: Never use print for logging; rely on the project logging utilities.

### 8. avoid_return_types_on_setters

- **Summary**: Setters always return void implicitly; omit explicit return types.

### 9. avoid_shadowing_type_parameters

- **Summary**: Do not reuse the same generic type parameter name in nested scopes.

### 10. avoid_types_as_parameter_names

- **Summary**: Parameter names should not match a type name.

### 11. avoid_unnecessary_containers

- **Summary**: Skip wrapping widgets in Container when Padding, SizedBox, or DecoratedBox would be simpler.

### 12. avoid_unused_constructor_parameters

- **Summary**: Remove constructor parameters that are never read.

### 13. avoid_void_async

- **Summary**: Avoid async functions that return void; prefer Future<void>.

### 14. prefer_void_to_null

- **Summary**: Use void instead of the deprecated Null return type.

### 15. void_checks

- **Summary**: Do not use values of type void, e.g., assigning the result of a void function.

### 16. await_only_futures

- **Summary**: Only await Future or Future-like objects.

### 17. cancel_subscriptions

- **Summary**: Always cancel StreamSubscription instances to avoid leaks.

### 18. directives_ordering

- **Summary**: Group imports as dart, package, project, then relative, each separated by a blank line.

### 19. empty_constructor_bodies

- **Summary**: Use a semicolon rather than an empty constructor body.

### 20. exhaustive_cases

- **Summary**: Switch statements over enums must handle every value or provide a default.

### 21. file_names

- **Summary**: Name files using lowercase_with_underscores.

### 22. library_names

- **Summary**: Library names must be lowercase_with_underscores.

### 23. library_prefixes

- **Summary**: Import prefixes must be lowercase_with_underscores.

### 24. collection_methods_unrelated_type

- **Summary**: Avoid calling collection methods with objects of unrelated types (e.g., list.contains with wrong type).

### 25. literal_only_boolean_expressions

- **Summary**: Boolean expressions should not consist solely of literals like 'if (true)'.

### 26. missing_whitespace_between_adjacent_strings

- **Summary**: Add whitespace between adjacent string literals if the result needs separation.

### 27. no_duplicate_case_values

- **Summary**: Switch statements cannot repeat case values.

### 28. null_closures

- **Summary**: Do not pass null where a closure is expected; pass an empty closure instead.

### 29. prefer_adjacent_string_concatenation

- **Summary**: Prefer placing string literals next to each other instead of using '+'.

### 30. prefer_conditional_assignment

- **Summary**: Use '??=' when assigning a value only if the variable is null.

### 31. prefer_const_constructors

- **Summary**: Mark constructor invocations as const when all arguments are compile-time constants.

### 32. prefer_const_constructors_in_immutables

- **Summary**: Constructors in immutable classes should be const.

### 33. prefer_const_declarations

- **Summary**: Use const for variables whose values never change and are compile-time constants.

### 34. prefer_contains

- **Summary**: Use collection.contains(element) instead of collection.indexOf(element) != -1.

### 35. prefer_equal_for_default_values

- **Summary**: Specify default parameter values using '=' rather than using nullable workarounds.

### 36. prefer_final_fields

- **Summary**: Fields that are only set once should be declared final.

### 37. prefer_final_locals

- **Summary**: Local variables that are not reassigned should be final.

### 38. prefer_generic_function_type_aliases

- **Summary**: Use the new generic function type alias syntax (typedef F<T> = T Function();).

### 39. prefer_if_null_operators

- **Summary**: Prefer the '??' operator over explicit null checks when selecting a fallback.

### 40. prefer_interpolation_to_compose_strings

- **Summary**: Use string interpolation instead of concatenation with '+'.

### 41. prefer_is_empty

- **Summary**: Call .isEmpty to test for emptiness instead of length == 0.

### 42. prefer_is_not_empty

- **Summary**: Call .isNotEmpty rather than length > 0.

### 43. prefer_single_quotes

- **Summary**: Use single quotes for string literals when no interpolation/escapes are needed.

### 44. prefer_spread_collections

- **Summary**: When possible, use collection spread operators instead of manual addAll chains.

### 45. recursive_getters

- **Summary**: Getter implementations must not recursively call themselves.

### 46. sized_box_for_whitespace

- **Summary**: Prefer SizedBox for fixed spacing instead of Container.

### 47. sort_pub_dependencies

- **Summary**: Sort dependencies, dev_dependencies, etc., alphabetically in pubspec.yaml.

### 48. throw_in_finally

- **Summary**: Do not throw exceptions from a finally block.

### 49. type_init_formals

- **Summary**: Use initializing formals in constructors instead of assigning parameters inside the body.

### 50. unawaited_futures

- **Summary**: Do not ignore returned Futures; await them or wrap with unawaited.

### 51. unnecessary_const

- **Summary**: Remove redundant const keywords.

### 52. unnecessary_new

- **Summary**: Do not use the 'new' keyword.

### 53. unnecessary_null_in_if_null_operators

- **Summary**: Avoid writing expressions like 'foo ?? null'.

### 54. unnecessary_parenthesis

- **Summary**: Remove parentheses that do not change evaluation order.

### 55. unnecessary_string_escapes

- **Summary**: Only escape characters that must be escaped.

### 56. unnecessary_string_interpolations

- **Summary**: Avoid interpolations when a literal string is sufficient.

### 57. unnecessary_this

- **Summary**: Do not prefix with 'this.' unless required to disambiguate.

### 58. unrelated_type_equality_checks

- **Summary**: Avoid equality comparisons between objects of unrelated types.

### 59. use_full_hex_values_for_flutter_colors

- **Summary**: Specify colors with 8 digit hex literals (0xAARRGGBB).

### 60. use_function_type_syntax_for_parameters

- **Summary**: Prefer the function type syntax 'void Function()' for parameters.

### 61. valid_regexps

- **Summary**: Regular expressions must be valid at compile time.

### 62. close_sinks

- **Summary**: Close instances of IOSink/StreamController/etc. to prevent resource leaks.

### 63. flutter_style_todos

- **Summary**: Write TODO comments using the Flutter style: TODO(username): message.

### 64. camel_case_extensions

- **Summary**: Name extensions using UpperCamelCase.

### 65. camel_case_types

- **Summary**: Class, enum, typedef, and mixin names must use UpperCamelCase.

### 66. constant_identifier_names

- **Summary**: Constant identifiers should use lowerCamelCase by default (or a consistent prefix if opted).

### 67. non_constant_identifier_names

- **Summary**: Non-constant variable, parameter, and method names must be lowerCamelCase.

### 68. prefer_relative_imports

- **Summary**: Import files within the same package using relative paths.

### 69. use_super_parameters

- **Summary**: Use super-initializer parameters when forwarding constructor parameters to the superclass.

