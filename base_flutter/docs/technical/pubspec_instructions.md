# Pubspec Instructions

## Overview

Guidelines for managing dependencies in `pubspec.yaml`.

## Rules

### 1. Explain New Dependencies

When suggesting new dependencies from `pub.dev`, explain their benefits and why they are needed.

```yaml
# GOOD - With explanation
# Adding 'image_picker' for selecting images from gallery/camera
# Benefits: Official Flutter plugin, well-maintained, supports iOS/Android
image_picker: 5.0.0

# BAD - No explanation
image_picker: 5.0.0
```

### 2. Do Not Use 'any' Version

Never use `any` as a dependency version.

```yaml
# BAD
dio: any

# GOOD
dio: 5.3.3
```

### 3. Do Not Use '^' Prefix

Do not use `^` prefix for dependency versions.

```yaml
# BAD
dio: ^5.3.3

# GOOD
dio: 5.3.3
```

### 4. Handle Version Conflicts

If adding a library causes conflicts with other libraries, adjust the version of the **added library only**. Do not arbitrarily change versions of existing libraries.

```yaml
# BAD - Changing existing library version
dependencies:
  dio: 4.0.0  # Changed from 5.3.3 to resolve conflict
  new_package: 2.0.0

# GOOD - Adjust new library version
dependencies:
  dio: 5.3.3  # Keep existing version
  new_package: 1.5.0  # Use compatible version
```

## Summary Rules

1. **Explain benefits** when adding new dependencies
2. **Never use `any`** as version
3. **Never use `^`** prefix
4. **Adjust new library version** to resolve conflicts, not existing ones
5. **Use exact versions** (e.g., `dio: 5.3.3`).
