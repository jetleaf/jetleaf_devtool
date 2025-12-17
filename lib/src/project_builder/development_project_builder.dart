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

import 'package:jetleaf_lang/jetleaf_lang.dart';
import 'package:path/path.dart' as p;

import '../command_runner/command_runner.dart';
import '../support/support.dart';
import 'project_builder.dart';

/// {@template jetleaf_development_project_builder}
/// A concrete implementation of [ProjectBuilder] that generates a
/// **development-ready Dart project**.
///
/// The [DevelopmentProjectBuilder] is designed for development workflows,
/// CI/CD testing, or local builds where a bootstrapped Dart entry point is
/// required. It handles:
/// - Generating imports for source files, packages, and assets  
/// - Writing a main bootstrap function  
/// - Producing a [DevelopmentProject] containing the output file and
///   development metrics
///
/// ### Usage Example
/// ```dart
/// final builder = DevelopmentProjectBuilder(File("build/bootstrap.dart"));
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
/// print(project.getLocation().path); // "build/bootstrap.dart"
/// print(project.getFormattedSize());  // e.g., "42 KB"
/// print(project.getMetrics());        // {Dart Class Imports: "5", ...}
/// ```
///
/// ### Design Notes
/// - Immutable; all constructor parameters are final.  
/// - Supports dynamic import generation for source, package, and asset files.  
/// - Calculates development metrics such as number of imports for reporting or CI.  
/// - Produces a [DevelopmentProject] that encapsulates the output file, size,
///   and metrics.
///
/// ### See Also
/// - [ProjectBuilder]
/// - [DevelopmentProject]
/// {@endtemplate}
final class DevelopmentProjectBuilder extends GenerativeSupport implements ProjectBuilder {
  /// The file where the generated bootstrapped Dart file is written.
  final File _output;

  /// {@macro jetleaf_development_project_builder}
  const DevelopmentProjectBuilder(this._output);

  @override
  Future<Project> build(CommandRunner runner, File entry, String packageName, List<File> dartFiles, FileUtility fileUtils, Directory project, List<String> args) async {
    final packageUri = resolveToPackageUri(p.relative(entry.path), packageName, project, fileUtils);

    if (packageUri == null) {
      throw Exception('Could not resolve package URI for main entry file: ${entry.path}. Ensure it is in a recognized source root like "lib/".');
    }
    
    // Step 1: Build entry point and details to include.
    final buffer = StringBuffer();
    final imports = await generateImports(entry, packageName, runner.logger, dartFiles, project, fileUtils);
    final packageImport = await generateAndWritePackages(_output.path, project, fileUtils, runner.logger);
    final assetImport = await generateAndWriteAssets(_output.path, packageName, fileUtils, runner.logger);
    final generatedImports = {...imports, packageImport, assetImport};

    // Step 2: Perform the writing tasks
    writeHeader(buffer, packageName, runner.logger, "bootstrap entry");
    buffer.writeln("import '$packageUri' as ${buildEntryAlias(packageName)};");

    writeImports(buffer, generatedImports);
    writeMainFunction(buffer, packageName, runner.logger, args, await isAsyncMain(entry));
    writeTarget(_output, buffer, runner.logger);

    return DevelopmentProject(_output, formatBytes(await _output.length()), {
      "Dart Class Imports": "${imports.length}",
      "Total Included Imports": "${generatedImports.length}"
    });
  }
}

/// {@template jetleaf_development_project}
/// A concrete implementation of [Project] representing a **development-ready
/// project artifact**.
///
/// A [DevelopmentProject] encapsulates:
/// - The project's **physical location** on disk  
/// - The project's **human-readable, preformatted size** (e.g., `"12.4 MB"`)  
/// - Optional **development metrics**, such as file counts, lines of code,
///   or build statistics
///
/// This class is immutable and optimized for development tooling, testing,
/// or CI/CD pipelines where project metadata and metrics are needed.
///
/// ### Usage Example
/// ```dart
/// final metrics = {'linesOfCode': '2048', 'files': '42'};
/// final project = DevelopmentProject(
///   File("/src/my_app"),
///   "12.4 MB",
///   metrics,
/// );
///
/// print(project.getLocation().path); // "/src/my_app"
/// print(project.getFormattedSize());  // "12.4 MB"
/// print(project.getMetrics());        // {linesOfCode: 2048, files: 42}
/// ```
///
/// ### Design Notes
/// - Immutable: values are provided at construction time and never change.
/// - Supports development workflows by exposing metrics alongside the project.
/// - Provides a clear API for retrieving size, location, and performance/usage metrics.
///
/// ### Example Behavior
/// | Property | Value |
/// |----------|-------|
/// | Location | `/src/my_app` |
/// | Size (formatted) | `"12.4 MB"` |
/// | Metrics | `{"linesOfCode": "2048", "files": "42"}` |
///
/// ### See Also
/// - [Project]
/// - [File]
/// {@endtemplate}
final class DevelopmentProject implements Project {
  /// The total size of the project (e.g., "12 MB").
  final String _size;

  /// The file or directory representing the project's location on disk.
  final File _file;

  /// Development metrics associated with this project (e.g., lines of code).
  final Map<String, String> _metrics;

  /// {@macro jetleaf_development_project}
  const DevelopmentProject(this._file, this._size, this._metrics);

  @override
  String getFormattedSize() => _size;

  @override
  File getLocation() => _file;

  @override
  Map<String, String> getMetrics() => _metrics;
}