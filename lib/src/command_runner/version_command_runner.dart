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

part of 'command_runner.dart';

/// {@template jetleaf_version_command_runner}
/// A built-in CLI subcommand that displays the current **JetLeaf CLI**
/// and related tooling version.
///
/// The `VersionCommandRunner` is automatically available in the JetLeaf
/// command-line interface as `jl --version`.
///
/// ### Behavior
/// When executed, this runner attempts to determine the JetLeaf version
/// through multiple strategies:
///
/// 1. **Local `pubspec.yaml` lookup**  
///    Searches for a `version:` field in the project’s root `pubspec.yaml`.
///
/// 2. **`.dart_tool/package_config.json` lookup**  
///    Resolves the version of the `jetleaf_cli` package when JetLeaf is
///    installed globally or as part of a workspace.
///
/// 3. **Environment fallback**  
///    Reads from the environment variable `JETLEAF_CLI_VERSION` if defined.
///    Defaults to `"unknown"` when no version can be resolved.
///
/// ### Example
/// ```bash
/// $ jl --version
/// 🍃 JetLeaf CLI Version: 1.3.7
/// ```
///
/// ### Error Handling
/// Any I/O or JSON parsing errors are caught internally and reported using
/// [logger.error], ensuring that the CLI never crashes unexpectedly.
///
/// ### See Also
/// - [CommandRunner] – base contract for all JetLeaf CLI commands.
/// - [CliLogger] – structured logging API for consistent CLI output.
/// {@endtemplate}
final class VersionCommandRunner extends CommandRunner {
  /// Creates a new instance of the `--version` CLI command.
  ///
  /// {@macro jetleaf_version_command_runner}
  const VersionCommandRunner();

  @override
  String get command => '--version';

  @override
  String get description => 'Displays the current version of the JL CLI and related tooling.';

  @override
  CliLogger get logger => cliSession.get(command.toUpperCase());

  @override
  String get usage => '''
Usage: jl $command

Description:
  $description
''';

  @override
  Future<void> run(List<String> args) async {
    try {
      String version = await getRunningVersion();

      // ✅ Output version
      logger.info('🍃 JetLeaf CLI Version: $version');
    } catch (e, st) {
      logger.error('Failed to fetch version: $e');
      logger.error(st.toString());
    }
  }
}