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

/// {@template writing_support}
/// Base class for JetLeaf project builders that generate and write
/// source code files, including imports, bootstrap main functions, and headers.
///
/// This class extends [ImportSupport] and adds writing-specific
/// capabilities such as:
/// - Writing formatted and aliased Dart `import` statements.
/// - Generating a standardized `main` entry function for the JetLeaf application.
/// - Writing output buffers to disk files with directory creation support.
/// - Adding auto-generated JetLeaf headers for branding and metadata.
///
/// Typical usage involves:
/// 1. Generating import URIs with [writeImports].
/// 2. Writing the main entry function using [writeMainFunction].
/// 3. Writing the output buffer to a target file via [writeTarget].
/// 4. Optionally, adding a JetLeaf auto-generated header with [writeHeader].
///
/// This class is intended for internal JetLeaf code generation tasks and
/// is usually extended by concrete builders that implement project-specific
/// logic for runtime bootstrapping.
/// {@endtemplate}
abstract class WritingSupport extends ImportSupport {
  /// {@macro writing_support}
  const WritingSupport();

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
  @protected
  void writeImports(StringBuffer buffer, Iterable<String> generatedImports, {bool aliased = true}) {
    final spinner = Spinner('🔍 Writing import statements of length ${generatedImports.length}...');
    spinner.start();

    writeGeneratedImports(buffer, generatedImports.toMap((v) => v, (v) => []), aliased: aliased);

    spinner.stop(successMessage: '✅ Done writing ${generatedImports.length} import statements.');
  }

  /// Writes the main entry function into the provided [buffer].
  ///
  /// This generates a `main` function that serves as the bootstrap for a
  /// JetLeaf application. It delegates execution to the user’s main entry
  /// library, passing along any provided command-line [args].
  ///
  /// The generated `main` function is asynchronous and includes comments
  /// explaining its purpose.
  ///
  /// Example output for `packageName = 'my_app'` and `args = ['--watch']`:
  /// ```dart
  /// /// The entry point for the JetLeaf application.
  /// Future<void> main() async {
  ///   // -------------------------------------------------------------------------
  ///   // Call the user's main function
  ///   // -------------------------------------------------------------------------
  ///   // Pass all arguments received by this bootstrap to the user's main entry point.
  ///   my_app_entry_library.main(['--watch']);
  /// }
  /// ```
  @protected
  void writeMainFunction(StringBuffer buffer, String packageName, CliLogger logger, List<String> args, bool isAsync) {
    final spinner = Spinner('🔍 Writing main function entry for $packageName...');
    spinner.start();

    final argsLiteral = formatArgs(args);

    buffer.writeln('''
/// The entry point for the JetLeaf application.
Future<void> main() async {
  // -------------------------------------------------------------------------
  // Call the user's main function
  // -------------------------------------------------------------------------
  // Pass all arguments received by this bootstrap to the user's main entry point.
  ${isAsync ? "await " : ""}${buildEntryAlias(packageName)}.main($argsLiteral);
}
  ''');

    spinner.stop();
    logger.info("✅ Done writing the main function for $packageName");
  }

  /// Determines whether the entrypoint `main()` function in the given Dart file
  /// is asynchronous.
  ///
  /// This function:
  /// - Parses the file into an AST using the Dart analyzer
  /// - Searches for a top-level function named `main`
  /// - Checks whether its return type is `Future`
  /// - Or whether the function body is marked `async`
  ///
  /// Returns `true` if `main` is asynchronous, otherwise `false`.
  ///
  /// Throws if the file cannot be read or contains invalid Dart syntax.
  Future<bool> isAsyncMain(File file) async {
    final result = parseString(content: await file.readAsString());

    for (final declaration in result.unit.declarations) {
      if (declaration is FunctionDeclaration && declaration.name.lexeme == 'main') {
        final returnType = declaration.returnType?.toSource() ?? '';
        final isFuture = returnType.startsWith('Future');

        final isAsync = declaration.functionExpression.body.isAsynchronous;

        return isFuture || isAsync;
      }
    }

    return false;
  }

  /// Writes the contents of [buffer] to the specified [target] file.
  ///
  /// Ensures that the parent directories exist by creating them recursively.
  /// This method is asynchronous and guarantees that the file content is fully
  /// written before completing.
  ///
  /// Example:
  /// ```dart
  /// final buffer = StringBuffer();
  /// writeMainFunction(buffer, 'my_app', ['--watch']);
  /// await writeTarget(File('build/bootstrap.dart'), buffer);
  /// ```
  /// This will create `build/bootstrap.dart` with the generated main function.
  @protected
  Future<void> writeTarget(File target, StringBuffer buffer, CliLogger logger) async {
    final spinner = Spinner('🔍 Writing generated buffer to ${target.path}...');
    spinner.start();

    final result = buffer.toString();
    result.trim();

    await writeGeneratedOutput(result, target);

    spinner.stop();
    logger.info("✅ Done writing generated buffer to ${target.path}");
  }

  /// Writes the standardized JetLeaf auto-generated file header into the given
  /// [StringBuffer], including ASCII branding, metadata, and copyright notice.
  ///
  /// This header is appended at the top of every generated bootstrap file,
  /// clearly identifying the file as part of the JetLeaf framework's
  /// code generation process.
  ///
  /// The header includes:
  /// - ASCII-styled JetLeaf logo and branding 🍃
  /// - License and copyright information
  /// - Framework versioning notes
  /// - “Do not edit manually” disclaimer
  ///
  /// Parameters:
  /// - [buffer]: The [StringBuffer] to write the header into.
  /// - [packageName]: The target Dart package being bootstrapped.
  @protected
  void writeHeader(StringBuffer buffer, String packageName, CliLogger logger, [String info = "bootstrap entry"]) {
    final spinner = Spinner('🔍 Writing header for $packageName...');
    spinner.start();

    writeGeneratedHeader(buffer, packageName);

    spinner.stop();
    logger.info("✅ Done writing header for $packageName");
  }
}