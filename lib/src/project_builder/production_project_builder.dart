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

import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../command_runner/command_runner.dart';
import '../common/compiler_type.dart';
import '../common/spinner.dart';
import '../support/support.dart';
import 'project_builder.dart';

/// {@template jetleaf_production_project_builder}
/// A concrete implementation of [ProjectBuilder] that compiles and packages
/// Jetleaf projects into a **production-ready artifact**.
///
/// This builder supports multiple compiler types (JIT, AOT, EXE) and
/// generates a deployable executable or snapshot. It handles:
/// - Preparing the output directory
/// - Generating imports, assets, and package definitions
/// - Writing a main entry point
/// - Executing the Dart compiler with the appropriate command
/// - Validating the output artifact
///
/// Returns a [ProductionProject] containing the built file and its
/// preformatted size.
///
/// ### Usage Example
/// ```dart
/// final builder = ProductionProjectBuilder(
///   CompilerType.EXE,
///   "build/app.exe",
///   "lib/main.dart",
/// );
///
/// final project = await builder.build(
///   runner,
///   File("lib/main.dart"),
///   "my_package",
///   dartFiles,
///   fileUtils,
///   projectDir,
///   [],
/// );
///
/// print(project.getLocation().path); // "build/app.exe"
/// print(project.getFormattedSize());  // e.g., "12.4 MB"
/// ```
///
/// ### Design Notes
/// - Immutable; all constructor parameters are final.
/// - Delegates actual file compilation to the Dart SDK via `Process.run`.
/// - Uses a [Spinner] for CLI feedback during build preparation.
/// - Validates that the output file exists after compilation.
/// - Supports dynamic import and asset generation through JetLeaf support utilities.
///
/// ### See Also
/// - [ProjectBuilder]
/// - [ProductionProject]
/// - [CompilerType]
/// {@endtemplate}
final class ProductionProjectBuilder extends GenerativeSupport implements ProjectBuilder {
  /// The path where the compiled artifact should be written.
  final String _outputPath;

  /// The source directory where the Dart entry point with files, should be written to.
  final String _sourcePath;

  /// The compiler type (JIT, AOT, EXE) to use for building the project.
  final CompilerType _compilerType;

  /// Constructs a new production project builder.
  /// 
  /// {@macro jetleaf_production_project_builder}
  const ProductionProjectBuilder(this._compilerType, this._outputPath, this._sourcePath);

  @override
  Future<Project> build(CommandRunner runner, File entry, String packageName, List<File> dartFiles, FileUtility fileUtils, Directory project, List<String> args) async {
    final packageUri = resolveToPackageUri(p.relative(entry.path), packageName, project, fileUtils);

    if (packageUri == null) {
      throw Exception('Could not resolve package URI for main entry file: ${entry.path}. Ensure it is in a recognized source root like "lib/".');
    }
    
    // Step 1: Prepare the build directory based on the output path
    Spinner spinner = Spinner('Preparing build directory...');
    spinner.start();

    final buildDir = Directory(p.dirname(_outputPath));
    if (!buildDir.existsSync()) {
      runner.logger.info('📁 Creating build directory: ${buildDir.path}');
      await buildDir.create(recursive: true);
    }

    spinner.stop(successMessage: '✅ Build directory prepared successfully.');

    // Step 2: Build entry point and details to include.
    final buffer = StringBuffer();
    final imports = await generateImports(entry, packageName, runner.logger, dartFiles, project, fileUtils);
    final packageImport = await generateAndWritePackages(_sourcePath, project, fileUtils, runner.logger);
    final assetImport = await generateAndWriteAssets(_sourcePath, packageName, fileUtils, runner.logger);
    final generatedImports = {...imports, packageImport, assetImport};

    // Step 3: Perform the writing tasks
    writeHeader(buffer, packageName, runner.logger, "production entry");
    writeImports(buffer, generatedImports);
    buffer.writeln("import '$packageUri' as ${buildEntryAlias(packageName)};");
    
    writeMainFunction(buffer, packageName, runner.logger, args);
    writeTarget(File(_sourcePath), buffer, runner.logger);

    // Step 4: Compile the project
    final command = _getCompilerCommand(_compilerType, _sourcePath, _outputPath);
    final result = await Process.run("dart", command);

    if (result.exitCode != 0) {
      throw Exception('Build failed:\n${result.stderr}');
    }

    final file = File(_outputPath);

    if (!(file.existsSync() || Directory(_outputPath).existsSync())) {
      throw Exception('Build completed but executable file was not created: $_outputPath');
    }

    final fileSize = await file.length();
    return ProductionProject(file, formatBytes(fileSize), {
      "Dart Class Imports": "${imports.length}",
      "Total Included Imports": "${generatedImports.length}"
    });
  }

  /// Builds the appropriate Dart compiler command for the specified [compiler]
  /// type, returning it as a list of CLI arguments ready for `Process.start`.
  ///
  /// This function standardizes JetLeaf’s build pipeline by selecting the
  /// correct Dart compilation mode (JIT, AOT, or native executable) and mapping
  /// it to its corresponding compiler invocation.
  ///
  /// Example:
  /// ```dart
  /// final command = _getCompilerCommand(
  ///   Compiler.EXE,
  ///   'lib/bootstrap.dart',
  ///   'build/main.exe',
  /// );
  /// print(command.join(' '));
  /// // → dart compile exe lib/bootstrap.dart -o build/main.exe
  /// ```
  ///
  /// Returns:
  ///   A list of strings representing the full Dart compile command.
  ///
  /// Parameters:
  /// - [compiler]: The [CompilerType] type (JIT, AOT, or EXE).
  /// - [source]: The path to the source file to compile.
  /// - [target]: The output path for the compiled artifact.
  List<String> _getCompilerCommand(CompilerType compiler, String source, String target) {
    switch (compiler) {
      case CompilerType.JIT:
        return ['compile', 'kernel', source, '-o', target];
      case CompilerType.AOT:
        return ['compile', 'aot-snapshot', source, '-o', target];
      case CompilerType.EXE:
        return ['compile', 'exe', source, '-o', target];
    }
  }
}

/// {@template jetleaf_production_project}
/// A concrete implementation of [Project] representing a **production-ready
/// project artifact**, typically generated or packaged during a build process.
///
/// A [ProductionProject] encapsulates:
/// - The project's **physical location** on disk  
/// - The project's **human-readable, preformatted size** (e.g., `"12.4 MB"`)  
///
/// This class is intentionally minimal and immutable.
/// It is used in build pipelines, deployment tooling, and project packaging
/// flows where concise project metadata is needed.
///
/// ### Usage Example
/// ```dart
/// final project = ProductionProject(
///   File("/dist/app.bundle"),
///   "42.3 MB",
/// );
///
/// print(project.getLocation().path);   // "/dist/app.bundle"
/// print(project.getFormattedSize());   // "42.3 MB"
/// ```
///
/// ### Design Notes
/// - Immutable: values are provided at construction time and never change.
/// - The size is **already formatted**; this class does not compute or
///   recalculate file size.
/// - Optimized for production reporting, logging, and deployment summaries.
///
/// ### Example Behavior
/// | Property | Value |
/// |----------|--------|
/// | Location | `/build/output.pkg` |
/// | Size (formatted) | `"128 MB"` |
///
/// ### See Also
/// - [Project]
/// - [File]
/// {@endtemplate}
final class ProductionProject implements Project {
  /// The total size of the project (e.g., "12 MB").
  final String _size;

  /// The file or directory representing the project's location on disk.
  final File _file;

  final Map<String, String> _metrics;

  /// {@macro jetleaf_production_project}
  const ProductionProject(this._file, this._size, this._metrics);

  @override
  String getFormattedSize() => _size;

  @override
  File getLocation() => _file;

  @override
  Map<String, String> getMetrics() => _metrics;
}