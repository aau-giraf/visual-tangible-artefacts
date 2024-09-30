# Visual tangible artefacts
# Contributing to Visual tangible artefacts
## Feature Contributions
### Feature Contributions
- **Issue Creation and Branching:**
  1. When adding new features, **create an issue** on GitHub to track the feature or bug fix.
  2. Create a new **branch** from the issue and use that branch for development.
  3. Once development is complete, submit a **pull request** for review.
## Naming Conventions
### Types
- **Classes, Enums, Typedefs, and Type Parameters**: Use `PascalCase/UpperCamelCase`.
  ```dart
  class SliderMenu { ... }
  typedef Predicate<T> = bool Function(T value);
  ```
### Extensions
- **Extensions:** Use `PascalCase/UpperCamelCase`.
  ```dart
  extension MyFancyList<T> on List<T> { ... }
  ```
### Variables, Functions, Parameters
- **Variables, Functions, Parameters, and Named Constants:** Use `camelCase/lowerCamelCase`.
  ```dart
  var itemCount = 3;
  void alignItems(bool clearItems) { ... }
  ```
### Directories and Files
- **Directories and Files:** Use `lowercase_with_underscores`.
  ```
  lib/
  my_widget.dart
  utils/
    string_helpers.dart
  ```
### Import Prefixes
- **Import Prefixes:** Use `lowercase_with_underscores`.
### Acronyms and Abbreviations
- **Acronyms and Abbreviations:** Capitalize acronyms and abbreviations longer than two letters like words.
  ```dart
  class HttpRequest { ... }
  ``
**Formatting:** Use ``dart format`` to format your code 
For other formatting guidlines refer to [dart.dev styling guidlines](https://dart.dev/effective-dart/style)
# [DOCUMENT YOUR CODE!](https://dart.dev/effective-dart/documentation)
