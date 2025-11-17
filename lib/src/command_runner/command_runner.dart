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

// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../common/constant.dart';
import '../common/logger.dart';
import '../common/prompts.dart' as prompt;
import '../common/spinner.dart';
import '../cli/cli.dart';
import '../common/compiler_type.dart';
import '../project_builder/development_project_builder.dart';
import '../project_builder/production_project_builder.dart';
import '../watcher/project_watcher.dart';

part 'development_command_runner.dart';
part 'production_command_runner.dart';
part 'proxy_command_runner.dart';
part 'hot_reload_command_runner.dart';
part 'info_command_runner.dart';
part 'version_command_runner.dart';
part 'help_command_runner.dart';
part 'helpers.dart';
part 'pause_command_runner.dart';

@internal
FrontendServerClient? frontendClient;

@internal
CompileResult? compilationResult;

/// Watches the active project for file system changes (such as additions,
/// modifications, or deletions).  
/// 
/// This watcher is responsible for triggering rebuilds or regeneration steps
/// when the project’s files change.  
/// 
/// Uses an [ApplicationProjectWatcher] implementation by default.
final ProjectWatcher _watcher = ApplicationProjectWatcher();

/// {@template jetleaf_command_runner}
/// A base contract for implementing **JetLeaf CLI subcommands**.
///
/// Each `CommandRunner` defines a distinct CLI command (e.g., `dev`, `build`,
/// `prod`) and encapsulates its logic, help text, and logging behavior.
///
/// Implementations of this class are automatically discovered and executed
/// by the JetLeaf CLI core depending on the command name.
///
/// ### Responsibilities
/// - Identify which CLI command it handles through the [command] property.
/// - Provide human-readable help text via [description] and [usage].
/// - Execute command logic in [run].
/// - Maintain a scoped [logger] session for structured output.
///
/// ### Example
/// ```dart
/// final class DevCommandRunner extends CommandRunner {
///   @override
///   String get command => 'dev';
///
///   @override
///   String get description => 'Starts the JetLeaf application in development mode.';
///
///   @override
///   Logger get logger => Logger('DevCommand');
///
///   @override
///   Future<void> run(List<String> args) async {
///     logger.info('Starting development server...');
///     await startDevServer();
///   }
///
///   @override
///   String get usage => 'jetleaf dev [options]';
/// }
/// ```
///
/// ### Lifecycle
/// 1. **Command Resolution**  
///    The CLI system matches user input against [command].
///
/// 2. **Execution**  
///    Once selected, [run] is invoked with parsed or raw arguments.
///
/// 3. **Logging and Reporting**  
///    Implementations use [logger] for structured CLI output.
///
/// ### Notes
/// - `CommandRunner` classes are generally stateless and lightweight.
/// - Use [canUse] to verify if the runner supports a given [cliCommand].
///
/// ### See Also
/// - [CliLogger] – provides contextual logging for the command.
/// {@endtemplate}
abstract class CommandRunner implements Cli {
  /// {@macro jetleaf_command_runner}
  const CommandRunner();

  /// The name of the CLI subcommand (e.g., `'dev'`, `'build'`, `'prod'`).
  String get command;

  /// A brief description of what the subcommand does.
  ///
  /// Displayed in CLI usage or help screens.
  String get description;

  /// The logger session associated with this CLI command.
  ///
  /// Used for scoping logs and differentiating command outputs.
  CliLogger get logger;

  /// Checks whether this runner supports the provided [cliCommand].
  ///
  /// Returns `true` if the CLI input corresponds to this command’s [command] name.
  bool canUse(String cliCommand) => cliCommand.equals(command);

  /// The formatted usage message for this CLI subcommand.
  ///
  /// Should provide a concise summary of arguments, flags, or examples.
  String get usage;
}

/// A callback invoked when a list of [File] objects has been loaded.
///
/// Example usage:
/// ```dart
/// void handleFiles(List<File> files) {
///   print('Loaded ${files.length} files.');
/// }
/// 
/// OnFilesLoaded callback = handleFiles;
/// ```
typedef OnFilesLoaded = void Function(List<File> files);