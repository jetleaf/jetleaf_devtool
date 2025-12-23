import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

void writeGeneratedHeader(StringBuffer buffer, Object libraryName) {
  // ASCII art as raw string
  const asciiArt = r'''
// 🍃      _      _   _                __  ______  
// 🍃     | | ___| |_| |    ___  __ _ / _| \ \ \ \ 
// 🍃  _  | |/ _ \ __| |   / _ \/ _` | |_   \ \ \ \
// 🍃 | |_| |  __/ |_| |__|  __/ (_| |  _|  / / / /
// 🍃  \___/ \___|\__|_____\___|\__,_|_|   /_/_/_/ 
// 🍃
''';

  buffer.writeln('''
// ignore_for_file: unused_import, depend_on_referenced_packages, duplicate_import, deprecated_member_use, unnecessary_import
//
${asciiArt.trim()}
//
// AUTO-GENERATED proxy for [$libraryName] package
// Do not edit manually.
//
// ---------------------------------------------------------------------------
// JetLeaf Framework 🍃
//
// Copyright (c) ${DateTime.now().year} Hapnium & JetLeaf Contributors
//
// Licensed under the MIT License. See LICENSE file in the root of the jetleaf project
//
// This file is part of the JetLeaf Framework, a modern, modular backend
// framework for Dart.
//
// For documentation and usage, visit:
// https://jetleaf.hapnium.com/docs
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃
''');
}

/// Writes the generated source code [output] to the given [file].
///
/// This helper ensures that the target directory exists before writing,
/// and trims trailing whitespace for cleaner diffs in version control.
///
/// - Creates parent directories recursively if missing.
/// - Overwrites any existing file at the same location.
///
/// @param output The generated Dart source string to write.
/// @param path The output file system path (absolute or relative).
Future<void> writeGeneratedOutput(String output, File file) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(output.trim());
}

/// Build a safe import alias from an import path.
///
/// Examples:
///  - package:glob/list_local_fs.dart -> pkg_glob_list_local_fs
///  - package:my-lib/src/foo/bar.dart -> pkg_my_lib_bar
///  - dart:async -> dart_async
///  - ../utils/file-helper.dart -> utils_file_helper
String buildImportAlias(String importPath, {Set<String>? used}) {
  String sanitize(String s) {
    // keep letters, digits and underscores only
    var out = s.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return out;
  }

  String alias;
  if (importPath.startsWith('package:')) {
    final pkgAndPath = importPath.substring('package:'.length); // e.g. "glob/list_local_fs.dart"
    final parts = pkgAndPath.split('/');
    final pkgName = parts.first.replaceAll('-', '_'); // "glob" or "my-lib" -> "my_lib"
    final fileName = parts.last.split('.').first.replaceAll('-', '_'); // "list_local_fs.dart" -> "list_local_fs"
    alias = 'pkg_${sanitize(pkgName)}_${sanitize(fileName)}';
  } else if (importPath.startsWith('dart:')) {
    alias = 'dart_${sanitize(importPath.substring('dart:'.length))}';
  } else {
    // relative path or other scheme -> sanitize whole string and remove path separators
    final cleaned = importPath.replaceAll(RegExp(r'[/\\]+'), '_');
    alias = "file${sanitize(cleaned)}";
  }

  // Optional: avoid collisions by appending suffix _2, _3, ...
  if (used != null) {
    var base = alias;
    var i = 2;
    while (used.contains(alias) && alias.isNotEmpty) {
      alias = '${base}_$i';
      i++;
    }
    used.add(alias);
  }

  return alias.replaceAll(RegExp(r'_+'), '_');
}

/// Generates a safe, deterministic alias for a library [Uri].
///
/// This aliasing strategy prevents namespace collisions and ensures
/// valid Dart identifiers when multiple libraries are imported with
/// similar paths.
///
/// ### Behavior
/// Converts URIs such as:
/// - `package:foo/bar/baz.dart` → `pkg_foo_bar_baz`
/// - `dart:async` → `pkg_async`
///
/// The resulting alias:
/// - Removes URI schemes (`package:`, `dart:`, `file:`)
/// - Removes `.dart` suffixes
/// - Replaces all non-alphanumeric characters with underscores.
///
/// ### Example
/// ```dart
/// final uri = Uri.parse('package:my_lib/src/utils/helper.dart');
/// print(_aliasForUri(uri)); // pkg_my_lib_src_utils_helper
/// ```
///
/// ### Returns
/// A valid Dart identifier safe to use as an import alias.
String aliasForUri(Uri uri) {
  // For package: URIs, use package name + rest
  final s = uri.toString();
  final withoutScheme = s.replaceAll(RegExp(r'(^.*:)|(\.dart$)'), ''); // remove scheme and .dart
  final safe = withoutScheme.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  return 'pkg_$safe';
}

/// Writes structured and sorted `import` statements into the provided
/// [StringBuffer] for code generation.
///
/// This function ensures all necessary Dart and package imports — including
/// user-defined, JetLeaf core, and dynamically generated ones — are organized
/// and formatted in a clean, deterministic order before the runtime
/// bootstrap file is written.
///
/// Import ordering rules:
/// 1. All `dart:` imports are written first (alphabetically).
/// 2. A blank line separates system imports from `package:` imports.
/// 3. Generated package imports receive unique aliases (e.g., `pkg_example`)
///    to avoid name collisions.
/// 4. The user’s main entry file import is always written last as:
///    ```dart
///    import '<packageUri>' as user_main_lib;
///    ```
///
/// Example:
/// ```dart
/// final buffer = StringBuffer();
/// _writeImports(buffer, 'package:my_app/main.dart', [
///   'package:my_app/src/services/api_service.dart',
///   'package:my_app/src/models/user.dart',
/// ]);
/// print(buffer.toString());
/// ```
///
/// Output:
/// ```dart
/// import 'dart:io';
///
/// import 'package:jetleaf/jetleaf.dart';
/// import 'package:jetleaf_lang/lang.dart';
/// import 'package:my_app/src/models/user.dart' as pkg_user;
/// import 'package:my_app/src/services/api_service.dart' as pkg_api_service;
///
/// import 'package:my_app/main.dart' as user_main_lib;
/// ```
///
/// Parameters:
/// - [buffer]: The output buffer where formatted imports are written.
/// - [generatedImports]: A list of discovered or auto-generated import URIs.
///
/// Notes:
/// - Duplicate imports are automatically deduplicated using a `Set`.
/// - Generated imports receive safe alias names derived from their file names.
/// - Default JetLeaf core libraries are always included automatically.
void writeGeneratedImports(StringBuffer buffer, Map<String, List<String>> generatedImports, {bool aliased = true}) {
  // All import URIs (the keys of the map)
  final imports = generatedImports.keys.toList();

  // Split into dart: imports and others
  final dartImports = imports.where((i) => i.startsWith('dart:')).toList()..sort();
  final packageImports = imports.where((i) => !i.startsWith('dart:')).toList()..sort();

  void writeImports(List<String> list) {
    for (final i in list) {
      final symbols = generatedImports[i];
      final showClause = (symbols != null && symbols.isNotEmpty) ? " show ${symbols.join(', ')}" : "";
      final alias = aliased ? " as ${buildImportAlias(i)}" : "";
      buffer.writeln("import '$i'$alias$showClause;");
    }
  }

  // Write dart imports
  writeImports(dartImports);

  if (dartImports.isNotEmpty && packageImports.isNotEmpty) {
    buffer.writeln();
  }

  // Write package imports
  writeImports(packageImports);

  buffer.writeln();
}

Future<List<String>> writeGeneratedAssets(List<Asset> assets, String outputPath, File outputFile) async {
  final buffer = StringBuffer();
  final instances = <String>[];
  final assetList = assets.filterWhere((asset) {
    final filePath = asset.getFilePath();
    return filePath.contains(".env") || filePath.contains("/${Constant.RESOURCES_DIR_NAME}/");
  });

  // Write header
  writeGeneratedHeader(buffer, outputPath);
  writeGeneratedImports(buffer, {
    "dart:typed_data": [],
    "package:jetleaf_lang/lang.dart": ["GenerativeAsset"]
  }, aliased: false);

  final addedItem = <String>{};
  final generatedNames = <String, String>{};

  for (final asset in assetList) {
    if (!addedItem.add(asset.getFilePath())) {
      continue;
    }

    final generatedPackageName = "$GenerativeAsset${assets.indexOf(asset)}";
    final sanitizedPackageName = sanitizePackageName(asset.getPackageName() ?? generatedPackageName);
    final sanitizedFileName = sanitizeFileName(asset.getFileName());
    final fileExtension = asset.getFilePath().split('.').last;
    String className = 'Generative$sanitizedPackageName$sanitizedFileName${fileExtension.capitalizeFirst}Asset';

    if (generatedNames[className] case final generated?) {
      className = "$className${Uuid.timeBasedUuid().toCompactString()}";
    } else {
      generatedNames.put(className, "");
    }

    final fileContentBytes = asset.getContentBytes();
    final byteListString = fileContentBytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');

    buffer.write('''

/// {@template ${className.toLowerCase().snakeCase()}}
/// A generated asset representing the file:
///
/// **Package:** `${asset.getPackageName()}`  
/// **Path:** `${asset.getFilePath()}`  
/// **File:** `${asset.getFileName()}`
///
/// This class is auto-generated by JetLeaf during the asset build phase.
///
/// It exposes:
/// - the asset's file path
/// - the file name
/// - the package it belongs to
/// - the embedded binary bytes of the asset
///
/// The constructor intentionally has **no arguments** so that JetLeaf can
/// instantiate it reflectively at runtime (via mirrors).
///
/// Do not modify manually. This file will be regenerated.
/// {@endtemplate}
final class $className extends GenerativeAsset {
  /// {@macro ${className.toLowerCase().snakeCase()}}
  $className();

  @override
  String getFilePath() => '${asset.getFilePath()}';

  @override
  String getFileName() => '${asset.getFileName()}';

  @override
  String? getPackageName() => '${asset.getPackageName()}';

  @override
  Uint8List getContentBytes() => Uint8List.fromList([$byteListString]);
}
''');

    instances.add("$className()");
  }

  await writeGeneratedOutput(buffer.toString(), outputFile);
  return instances;
}

/// Sanitizes a package name to be used as part of a Dart class name.
/// Converts to PascalCase and removes invalid characters.
String sanitizePackageName(String packageName) {
  // Replace non-alphanumeric characters with spaces, then convert to PascalCase
  final sanitized = packageName
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
      .split(' ')
      .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
      .join();
  return sanitized.isEmpty ? 'UnnamedPackage' : sanitized;
}

/// Sanitizes a file name to be used as part of a Dart class name.
/// Converts to PascalCase and removes invalid characters.
String sanitizeFileName(String fileName) {
  // Remove file extension
  final nameWithoutExtension = p.basenameWithoutExtension(fileName);
  // Replace non-alphanumeric characters with spaces, then convert to PascalCase
  final sanitized = nameWithoutExtension
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
      .split(' ')
      .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
      .join();
  return sanitized.isEmpty ? 'UnnamedFile' : sanitized;
}

Future<List<String>> writeGeneratedPackages(List<Package> packages, String outputPath, File outputFile) async {
  final buffer = StringBuffer();
  final instances = <String>[];

  // Write header
  writeGeneratedHeader(buffer, outputPath);
  writeGeneratedImports(buffer, {
    "package:jetleaf_lang/lang.dart": ["GenerativePackage"]
  }, aliased: false);

  for (final package in packages) {
    final sanitizedPackageName = sanitizePackageName(package.getName());
    final className = 'Generative${sanitizedPackageName}Package';
    final jetleafDeps = package.getJetleafDependencies().map((dep) => "'$dep'").join(', ');
    final deps = package.getDependencies().map((dep) => "'$dep'").join(', ');
    final devDeps = package.getDevDependencies().map((dep) => "'$dep'").join(', ');

    buffer.write('''

/// {@template ${className.toLowerCase().snakeCase()}}
/// A generated representation of a Dart package discovered during the
/// JetLeaf package build step.
///
/// This class provides compile-time metadata for the package:
///
/// - **Name:** `${package.getName()}`  
/// - **Version:** `${package.getVersion()}`  
/// - **Language version:** `${package.getLanguageVersion()}`  
/// - **Is root package:** `${package.getIsRootPackage()}`  
/// - **File system path:** `${package.getFilePath()}`  
/// - **Root URI:** `${package.getRootUri()}`
/// - **Jetleaf Dependencies:** `[$jetleafDeps]`
/// - **Dependencies:** `[$deps]`
/// - **Dev Dependencies:** `[$devDeps]`
///
/// The constructor intentionally has **no arguments**, allowing JetLeaf to
/// instantiate it reflectively at runtime using mirrors.
///
/// This class is generated automatically.  
/// **Do not edit manually.**
/// {@endtemplate}
final class $className extends GenerativePackage {
  /// {@macro ${className.toLowerCase().snakeCase()}}
  $className();

  @override
  String getName() => '${package.getName()}';

  @override
  String getVersion() => '${package.getVersion()}';

  @override
  String? getLanguageVersion() => '${package.getLanguageVersion()}';

  @override
  bool getIsRootPackage() => ${package.getIsRootPackage()};

  @override
  String? getFilePath() => '${package.getFilePath()}';

  @override
  String? getRootUri() => '${package.getRootUri()}';

  @override
  Iterable<String> getJetleafDependencies() => [$jetleafDeps];

  @override
  Iterable<String> getDependencies() => [$deps];

  @override
  Iterable<String> getDevDependencies() => [$devDeps];
}
''');

    instances.add("$className()");
  }

  await writeGeneratedOutput(buffer.toString(), outputFile);

  return instances;
}