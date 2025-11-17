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

/// {@template cli_constant}
/// A centralized repository of constant values used across the JetLeaf CLI.
///
/// The [CliConstant] class defines command-line flags, directory names, and
/// other symbolic constants that are used throughout the JetLeaf tooling
/// ecosystem (e.g., in [ApplicationCli], [CommandRunner], and build pipelines).
///
/// This class is intentionally **non-instantiable**, as it serves purely as a
/// static configuration holder for CLI argument parsing and internal directory
/// management. To ensure immutability and consistency, all members are declared
/// as compile-time `const` values.
///
/// ### Key Responsibilities
/// - Defines consistent flag names for developer tooling (`--jetleaf-dev`, `--watch`, etc.)
/// - Standardizes the structure of generated resource directories (e.g., `lib/_jetleaf`)
/// - Ensures CLI feature parity between development, build, and runtime modes
///
/// ### References
/// - [ApplicationCli] – The main entry point for handling CLI arguments.
/// - [CommandRunner] – Subcommand abstraction that consumes these constants.
/// - [ApplicationFileWatcher] – Uses flags such as [DEV_HOT_RELOAD_FLAG].
/// - [CliArgumentParser] – May parse and interpret these constants during boot.
/// - [JetLeafVersion] – Often displayed alongside CLI flags.
///
/// ### Example
/// ```dart
/// void main(List<String> args) {
///   if (args.contains(CliConstant.DEV_FLAG)) {
///     print("Running JetLeaf in developer mode.");
///   }
///
///   if (args.contains(CliConstant.DEV_HOT_RELOAD_FLAG)) {
///     print("Hot reload is enabled.");
///   }
/// }
/// ```
///
/// ### Notes
/// - The `GENERATED_DIR_NAME` directory (`_jetleaf/`) is framework-reserved.
/// - Flag names are case-sensitive and should **not** be renamed without
///   corresponding updates in command parsing logic.
///
/// {@endtemplate}
final class CliConstant {
  /// Private constructor to prevent instantiation.
  ///
  /// Use the static constants directly instead.
  const CliConstant._();

  /// Flag used to enable JetLeaf developer mode.
  ///
  /// When present, the CLI runs in development mode with enhanced logging,
  /// validation, and debugging support.
  ///
  /// Example: `jl <command> --jetleaf-dev`
  static const String DEV_FLAG = '--jetleaf-dev';

  /// Enables JetLeaf hot reload functionality during development.
  ///
  /// Example: `jl <command> --watch`
  static const String DEV_HOT_RELOAD_FLAG = '--watch';

  /// Disables JetLeaf hot reload functionality.
  ///
  /// Example: `jl <command> --no-watch`
  static const String DEV_HOT_RELOAD_FLAG_NEGATION = '--no-watch';
}