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

import '../command_runner/command_runner.dart';

/// {@template jetleaf_project_builder}
/// Base interface for **building project artifacts** in the JetLeaf ecosystem.
///
/// A [ProjectBuilder] defines a contract for generating [Project] instances,
/// whether for development workflows ([DevelopmentProjectBuilder]) or
/// production builds ([ProductionProjectBuilder]).
///
/// The builder handles tasks such as:
/// - Generating imports for source, package, and asset files  
/// - Writing a main entry point or bootstrap function  
/// - Compiling or preparing the final project artifact  
/// - Calculating metrics like file counts, imports, or size
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
/// print(project.getLocation().path);
/// print(project.getFormattedSize());
/// print(project.getMetrics());
/// ```
///
/// ### See Also
/// - [Project]
/// - [ProductionProjectBuilder]
/// - [DevelopmentProjectBuilder]
/// {@endtemplate}
abstract interface class ProjectBuilder {
  /// Const constructor to allow usage in const contexts if needed.
  const ProjectBuilder();
  
  /// Builds a [Project] artifact based on the provided entry point, package,
  /// and source files.
  ///
  /// Parameters:
  /// - [runner]: The [CommandRunner] for logging and CLI interaction.  
  /// - [entry]: The main Dart entry file for the project.  
  /// - [packageName]: The package name associated with the project.  
  /// - [dartFiles]: A list of Dart source files to include.  
  /// - [fileUtils]: Utility functions for file operations.  
  /// - [project]: The project directory.  
  /// - [args]: Additional arguments to pass to the generated main function or build pipeline.
  Future<Project> build(
    CommandRunner runner,
    File entry,
    String packageName,
    List<File> dartFiles,
    FileUtility fileUtils,
    Directory project,
    List<String> args,
  );
}

/// {@template jetleaf_project}
/// Base interface representing a **software project artifact**.
///
/// A [Project] provides metadata about a built or development-ready project,
/// including its location on disk, formatted size, and optional metrics
/// (such as lines of code, number of files, or generated imports).
///
/// Implementations may represent production-ready builds ([ProductionProject])
/// or development artifacts ([DevelopmentProject]).
///
/// ### Usage Example
/// ```dart
/// void printProjectInfo(Project project) {
///   print('Location: ${project.getLocation().path}');
///   print('Size: ${project.getFormattedSize()}');
///   print('Metrics: ${project.getMetrics()}');
/// }
/// ```
///
/// ### See Also
/// - [ProductionProject]
/// - [DevelopmentProject]
/// {@endtemplate}
abstract interface class Project {
  /// Returns the file or directory representing the project's location on disk.
  File getLocation();

  /// Returns the human-readable, preformatted size of the project (e.g., `"12.4 MB"`).
  String getFormattedSize();

  /// Returns a map of development or build metrics associated with this project.
  Map<String, String> getMetrics();
}