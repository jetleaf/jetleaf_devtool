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
/// A base class for project builders that need to generate formatted
/// source code for Dart projects.
///
/// This builder provides utilities for formatting command-line arguments
/// and directory paths into Dart code literals. It extends
/// [PackageSupport] and can be used as a foundation for
/// code generation tools, bootstrapping scripts, or CLI project generators.
///
/// ### Responsibilities
/// - Formatting `List<String>` arguments into Dart list literals for
///   code generation.
/// - Formatting directory paths into `File` objects for generated code.
/// - Supporting both inline (compact) and multi-line (readable) formatting
///   based on configurable limits.
///
/// ### Example Usage
/// ```dart
/// final builder = MyFormatBuilder();
/// 
/// // Format arguments inline
/// final args = builder.formatArgs(['--watch', '--dev']);
/// print(args); // ['--watch', '--dev']
/// 
/// // Format directory paths as File objects
/// final dirs = builder.formatDirs(Directory.current, ['lib', 'src']);
/// print(dirs); // [File('lib'), File('src')];
/// ```
/// {@endtemplate}
abstract class FormatSupport extends PackageSupport {
  /// {@macro format_support}
  const FormatSupport();
  
  /// Formats a list of command-line [args] into a Dart list literal string.
  ///
  /// - If [args.length] <= [inlineLimit], outputs a single-line list:
  ///   ```dart
  ///   ['--watch', '--dev']
  ///   ```
  /// - Otherwise, formats each argument on its own line with indentation:
  ///   ```dart
  ///   [
  ///     '--watch',
  ///     '--dev',
  ///     '--verbose',
  ///   ]
  ///   ```
  ///
  /// [inlineLimit] defaults to 6 and can be customized.
  @protected
  String formatArgs(List<String> args, [int inlineLimit = 6]) {
    if (args.length <= inlineLimit) {
      // One-line format
      final inline = args.map((arg) => "'$arg'").join(', ');
      return "[$inline]";
    } else {
      // Multi-line format
      final lines = args.map((arg) => "  '$arg',").join('\n');
      return "[\n$lines\n]";
    }
  }

  /// Formats a list of directory paths as `File` objects in Dart code.
  ///
  /// - If [directories.length] <= [inlineLimit], outputs a single-line list:
  ///   ```dart
  ///   [File('lib'), File('src')]
  ///   ```
  /// - Otherwise, outputs a multi-line list for readability:
  ///   ```dart
  ///   [
  ///     File('lib'),
  ///     File('src'),
  ///     File('bin'),
  ///   ]
  ///   ```
  ///
  /// Paths can be absolute or relative. Relative paths are joined with
  /// the provided [project] directory.
  ///
  /// [inlineLimit] defaults to 1.
  @protected
  String formatDirs(Directory project, List<String> directories, [int inlineLimit = 1]) {
    if (directories.isEmpty) {
      return '[]';
    }

    final formattedDirs = directories.map((dir) {
      // Check if path is already absolute
      if (dir.isEmpty) {
        return "";
      } else if (p.isAbsolute(dir.trim())) {
        return "File('${dir.trim()}')";
      } else {
        final direct = p.join(project.path, dir.trim());
        return "File('$direct')";
      }
    }).where((file) => file.isNotEmpty).toList();

    if (formattedDirs.length <= inlineLimit) {
      // One-line format
      return '[${formattedDirs.join(', ')}]';
    } else {
      // Multi-line format
      final lines = formattedDirs.map((dir) => '  $dir,').join('\n');
      return '[\n$lines\n]';
    }
  }

  /// Converts a byte count into a human-readable string using standard
  /// binary prefixes (B, KB, MB).
  ///
  /// Useful for displaying build output sizes or cache file statistics.
  ///
  /// Example:
  /// ```dart
  /// print(_formatBytes(512));        // 512B
  /// print(_formatBytes(16384));      // 16.0KB
  /// print(_formatBytes(5242880));    // 5.0MB
  /// ```
  ///
  /// Returns:
  ///   A formatted string with a numeric value and unit suffix.
  ///
  /// Parameters:
  /// - [bytes]: The file size in bytes.
  @protected
  String formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}