// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

part of 'support.dart';

/// {@template format_support}
/// An abstract base class for building Dart project import structures
/// dynamically, typically used for runtime code generation or bootstrap
/// entrypoints.
///
/// This class provides common utilities to:
/// - Generate unique library aliases from package names ([buildEntryAlias]).
/// - Scan project directories for Dart source files.
/// - Generate and organize import statements for inclusion in
///   generated bootstrap files.
///
/// Subclasses are expected to implement or override scanning strategies,
/// aliasing rules, and output generation as needed for specific project
/// layouts or conventions.
///
/// ### Usage Example
/// ```dart
/// class MyProjectBuilder extends ImportSupportProjectBuilder {
///   @override
///   Future<void> buildProjectImports() async {
///     final imports = await findAndGenerateImports(logger, projectDir, mainFile, 'my_app');
///     print(imports);
///   }
/// }
/// ```
/// {@endtemplate}
abstract class ImportSupport extends FormatSupport {
  /// {@macro format_support}
  const ImportSupport();
  
  /// Builds a unique alias for the generated entry library of a package.
  ///
  /// This ensures that the generated bootstrap file has a deterministic
  /// library name that avoids collisions with other libraries.
  ///
  /// Example:
  /// ```dart
  /// final alias = buildEntryAlias('my_package'); // 'my_package_entry_library'
  /// ```
  ///
  /// Parameters:
  /// - [packageName]: The name of the Dart package.
  ///
  /// Returns:
  /// - A `String` representing a safe, unique alias for the package’s entry library.
  @protected
  String buildEntryAlias(String packageName) => "${packageName}_entry_library";

  /// Scans the project for Dart source files and generates a list of import
  /// statements required for the runtime bootstrap file.
  ///
  /// This method leverages [FileUtility] and [generateImports] to:
  /// 1. Recursively discover all relevant Dart files within [project].
  /// 2. Generate structured `import` directives for those files.
  /// 3. Return the finalized set of imports to be injected into the
  ///    generated bootstrap entrypoint.
  ///
  /// If no imports are generated (e.g., due to delayed build setup or file
  /// resolution issues), the method automatically retries by invoking itself
  /// recursively until valid imports are found. This ensures that transient
  /// initialization delays (e.g., missing `.dart_tool` files) do not result
  /// in incomplete bootstrap code.
  ///
  /// Example:
  /// ```dart
  /// final imports = await findAndGenerateImports(logger, projectDir, mainFile, 'my_app');
  /// print('Generated ${imports.length} import statements.');
  /// ```
  ///
  /// Parameters:
  /// - [logger]: A [CliLogger] used for informational, warning, and error output.
  /// - [project]: The project’s root directory to search for Dart files.
  /// - [mainEntryFile]: The detected main entrypoint file for the application.
  /// - [packageName]: The current package’s name (used to build proper import URIs).
  ///
  /// Returns:
  /// - A [Future] resolving to a [Set] of generated import strings.
  ///
  /// Throws:
  /// - Any uncaught file or configuration error encountered during scanning.
  /// 
  /// Notes:
  /// - The search skips test, tool, build, and analyzer directories by default.
  /// - Recursion continues until at least one valid import is detected.
  @protected
  Future<Set<String>> findAndGenerateImports(CliLogger logger, Directory project, File mainEntryFile, String packageName, List<String> excludes, List<String> includes, FileUtility fileUtils) async {
    final spinner = Spinner('🔍 Generating imports for $packageName...');
    spinner.start();

    final files = await fileUtils.findDartFiles(project);
    final generatedImports = await generateImports(mainEntryFile, packageName, logger, files.getScannableDartFiles().toList(), project, fileUtils);

    if (generatedImports.isEmpty) {
      return await findAndGenerateImports(logger, project, mainEntryFile, packageName, excludes, includes, fileUtils);
    }

    spinner.stop(successMessage: 'Generated imports for $packageName with ${generatedImports.length} imports.');

    return generatedImports;
  }

  /// Scans all discovered Dart source files and generates a set of valid
  /// `package:` import URIs for inclusion in the runtime bootstrap file.
  ///
  /// This method determines which files should be imported into the generated
  /// entrypoint by:
  /// 1. Resolving each file’s path relative to the project root.
  /// 2. Converting paths into valid `package:` URIs using [FileUtility].
  /// 3. Excluding the main entry file (already imported manually).
  /// 4. Skipping any `part` or `part of` files to prevent duplicate definitions.
  ///
  /// A progress spinner is displayed while imports are being generated, and
  /// the resulting import set is returned once the process completes.
  ///
  /// Example:
  /// ```dart
  /// final imports = await generateImports(
  ///   File('lib/main.dart'),
  ///   'my_app',
  ///   logger,
  ///   allDartFiles,
  ///   utils,
  /// );
  /// ```
  ///
  /// Output:
  /// ```
  /// 🔍 Generating imports for my_app...
  /// ✅ Generated imports for my_app with 42 imports.
  /// ```
  ///
  /// Returns:
  ///   A [Set] of unique `package:` import URIs suitable for insertion
  ///   into a generated Dart file.
  ///
  /// Throws:
  ///   - No exceptions are thrown directly; invalid or part files are skipped.
  ///
  /// Parameters:
  /// - [mainEntryFile]: The primary user entry file (excluded from import list).
  /// - [packageName]: The package name used to resolve `package:` URIs.
  /// - [logger]: The active CLI logger used for logging and status reporting.
  /// - [files]: A list of all discovered Dart files to analyze.
  /// - [utils]: An instance of [FileUtility] that provides file resolution helpers.
  @protected
  Future<Set<String>> generateImports(File mainEntryFile, String packageName, CliLogger logger, List<File> files, Directory project, FileUtility utils) async {
    final spinner = Spinner('🔍 Generating import statements for Dart classes...');
    spinner.start();

    final imports = <String>{};

    for (final file in files) {
      if (file.path == mainEntryFile.path) continue; // Skip the main entry file

      final relativePath = p.relative(file.path);
      final packageUri = resolveToPackageUri(relativePath, packageName, project, utils);
      if (packageUri != null && !utils.isPartFile(file)) {
        imports.add(packageUri);
      }
    }

    if (imports.isNotEmpty) {
      spinner.stop();
      logger.info('✅ Generated ${imports.length} import statements for Dart classes in $packageName');
    } else {
      spinner.stop();
      logger.warn('ℹ️ No dart class files found to create import statement.');
    }

    return imports;
  }

  /// Build a safe import alias from an import path.
  ///
  /// Examples:
  ///  - package:glob/list_local_fs.dart -> pkg_glob_list_local_fs
  ///  - package:my-lib/src/foo/bar.dart -> pkg_my_lib_bar
  ///  - dart:async -> dart_async
  ///  - ../utils/file-helper.dart -> utils_file_helper
  @protected
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
      alias = sanitize(cleaned);
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

    return alias;
  }
}