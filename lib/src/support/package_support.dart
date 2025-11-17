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

/// {@template package_support}
/// A specialized project builder that provides utilities for resolving
/// Dart source files to `package:` URIs within a project.
///
/// This class extends [Support] and adds support
/// for package-aware path resolution, allowing tools and code generators
/// to convert absolute or relative file paths into valid Dart package
/// import URIs.
///
/// ### Responsibilities
/// - Resolving files within the current project's `lib/` directory to
///   proper `package:` URIs.
/// - Delegating non-project files to a [FileUtility] instance for
///   resolution, which may handle dependencies or external packages.
///
/// ### Usage Example
/// ```dart
/// final builder = MyPackageBuilder();
/// final packageUri = builder.resolveToPackageUri(
///   '/home/user/my_project/lib/src/foo.dart',
///   'my_project',
///   Directory('/home/user/my_project'),
///   fileUtils,
/// );
/// print(packageUri); // package:my_project/src/foo.dart
/// ```
/// {@endtemplate}
abstract class PackageSupport extends Support {
  /// {@macro package_support}
  const PackageSupport();

  /// Resolves an absolute file path to a `package:` URI if it belongs
  /// to the current project's `lib/` directory.
  ///
  /// If the file is outside the current project, delegates resolution
  /// to the provided [FileUtility].
  ///
  /// Parameters:
  /// - [absoluteFilePath]: The absolute path to the Dart source file.
  /// - [currentPackageName]: The Dart package name for the current project.
  /// - [project]: The root directory of the project.
  /// - [fileUtils]: A utility instance capable of resolving non-project
  ///   files to package URIs.
  ///
  /// Returns:
  /// - A `String` representing the `package:` URI if resolvable.
  /// - `null` if the file cannot be resolved to a package URI.
  @protected
  String? resolveToPackageUri(String absoluteFilePath, String currentPackageName, Directory project, FileUtility fileUtils) {
    final normalizedAbsoluteFilePath = p.normalize(absoluteFilePath);

    // Check if it's in the current project's lib directory
    final currentProjectLibPath = p.normalize(p.join(project.path, 'lib'));
    if (p.isWithin(currentProjectLibPath, normalizedAbsoluteFilePath)) {
      final relativePath = p.relative(normalizedAbsoluteFilePath, from: currentProjectLibPath);
      final cleanedRelativePath = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
      return 'package:$currentPackageName/$cleanedRelativePath';
    }

    return fileUtils.resolveToPackageUri(absoluteFilePath, currentPackageName, project);
  }
}