# Visual tangible artefacts

- [Contributing to Visual tangible artefacts](#contributing-to-visual-tangible-artefacts)
  - [Feature Contributions](#feature-contributions)
  - [App Naming Conventions (Dart)](#app-naming-conventions-dart)
    - [Types](#types)
    - [Extensions](#extensions)
    - [Variables, Functions, Parameters](#variables-functions-parameters)
    - [Directories and Files](#directories-and-files)
    - [Import Prefixes](#import-prefixes)
    - [Acronyms and Abbreviations](#acronyms-and-abbreviations)
    - [Formatting](#formatting-your-dart-code)
    - [Document Your Dart Code](#formatting-your-dart-code)
  - [API Naming Conventions (C#)](#api-naming-conventions-c)
    - [Types](#types-csharp)
    - [Methods, Properties, Events](#methods-properties-events)
    - [Variables, Parameters](#variables-parameters)
    - [Constants](#constants)
    - [Interfaces](#interfaces)
    - [Namespaces](#namespaces)
    - [Files](#files)
    - [Acronyms](#acronyms)
    - [Formatting your CSharp](#formatting-your-csharp-code)
    - [Document Your CSharp Code](#document-your-csharp-code)
---

# Contributing to Visual tangible artefacts

## Feature Contributions
### Feature Contributions
- **Issue Creation and Branching:**
  1. When adding new features, **create an issue** on GitHub to track the feature or bug fix.
  2. Create a new **branch** from the issue and use that branch for development.
  3. Once development is complete, submit a **pull request** and pull it to main*.
     
     *It might be easier for you to pull main, into the feature branch, testing it, and then pulling feature to main
     
     ![Branching strategy](https://github.com/aau-giraf/Visual-tangible-artefacts/blob/main/resources/Branching.png)
     
### App Naming Conventions (Dart)

#### Types csharp
- **Classes, Enums, Typedefs, and Type Parameters**: Use `PascalCase/UpperCamelCase`.
  ```dart
  class SliderMenu { ... }
  typedef Predicate<T> = bool Function(T value);

## App Naming Conventions (Dart)
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
### Formatting your dart code
Use ``dart format`` to format your code 
For other formatting guidlines refer to [dart.dev styling guidlines](https://dart.dev/effective-dart/style)
# [DOCUMENT YOUR CODE!](https://dart.dev/effective-dart/documentation)
## API Naming Conventions (C#)
### Types
- **Classes, Enums, and Structs**: Use `PascalCase`.
  ```csharp
  class MyClass { ... }
  enum Colors { Red, Green, Blue }
  ```

### Methods, Properties, Events
- **Methods, Properties, and Events**: Use `PascalCase`.
  ```csharp
  public void FetchData() { ... }
  public string Name { get; set; }
  ```

### Variables, Parameters
- **Variables and Parameters**: Use `camelCase`.
  ```csharp
  int itemCount = 3;
  void SetItemCount(int itemCount) { ... }
  ```

### Constants
- **Constants**: Use `PascalCase` with the `const` modifier.
  ```csharp
  const int MaxItems = 10;
  ```

### Interfaces
- **Interfaces**: Prefix with an "I" and use `PascalCase`.
  ```csharp
  public interface IMyInterface { ... }
  ```

### Namespaces
- **Namespaces**: Use `PascalCase`.
  ```csharp
  namespace MyApplication.Data
  {
    // ...
  }
  ```

### Files
- **Files**: Each file should contain a single class, interface, or enum, named after the type it contains. Use `PascalCase` for file names.
  ```
  MyClass.cs
  IMyInterface.cs
  Colors.cs
  ```

### Acronyms
- **Acronyms**: Capitalize acronyms that are two letters or fewer. For longer acronyms, use `PascalCase`.
  ```csharp
  class IOHandler { ... }
  class HttpRequest { ... }
  ```
  
### Formatting your CSharp code
- Use a consistent style for code formatting. Refer to the official [C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions).

### Document Your CSharp Code
- Document your code using comments (`///`). Refer to [Microsoft documentation guidelines](https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/xmldoc/).
