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

part of 'cli.dart';

/// {@template jetleaf_application_cli}
/// The **central JetLeaf CLI entrypoint** responsible for dispatching
/// subcommands, handling global flags, and providing a consistent
/// interface for interacting with the JetLeaf ecosystem.
///
/// This class implements [Cli] and can be invoked via:
/// ```bash
/// dart run jetleaf_cli <command> [options]
/// ```
///
/// or from a compiled binary:
/// ```bash
/// ./jl <command> [options]
/// ```
///
/// ### Responsibilities
/// 1. **Display the CLI header and branding**
///    - Shows JetLeaf CLI version, website, and helpful tips.
/// 2. **Global flag handling**
///    - Recognizes `--version` / `-v` to display CLI version.
///    - Recognizes `--help` / `-h` or empty arguments to show help.
/// 3. **Command dispatch**
///    - Resolves the subcommand using [CommandRunner] instances.
///    - Passes remaining arguments to the command runner.
/// 4. **Error handling and guidance**
///    - Handles unknown commands gracefully.
///    - Prompts the user to show available commands if an unknown command is used.
/// 5. **Exit codes**
///    - Returns `0` for successful execution.
///    - Returns `1` for unknown commands or fatal errors.
///
/// ### Execution Flow
/// ```text
/// ┌─────────────────────────────┐
/// │  ApplicationCli.run(args)   │
/// └─────────────────────────────┘
///            │
///            ▼
///   Display CLI header (version, tips)
///            │
///            ▼
///   Check for global flags (--help, --version)
///            │
///            ├─> --version? → VersionCommandRunner.run(args)
///            │
///            ├─> --help / empty? → HelpCommandRunner.run(args)
///            │
///            ▼
///   Extract command name and arguments
///            │
///            ▼
///   Resolve [CommandRunner] for the given command
///            │
///            ├─> Found → commandRunner.run(commandArgs)
///            │
///            └─> Not Found → Log error, prompt for help, exit(1)
/// ```
///
/// ### Example Usage
/// ```bash
/// # Show general help
/// jl --help
///
/// # Show version
/// jl --version
///
/// # Run development server
/// jl dev --entry lib/main.dart --watch
///
/// # Run production build
/// jl prod --entry lib/main.dart
/// ```
///
/// ### Integration with CommandRunner
/// Each subcommand implements [CommandRunner] and provides:
/// - `command` – the CLI keyword for the command.
/// - `description` – a human-readable explanation.
/// - `usage` – a full usage string including options and examples.
/// - `run(List<String> args)` – executes the command logic.
///
/// `ApplicationCli` locates the appropriate [CommandRunner] and
/// forwards the relevant arguments while handling global concerns
/// such as help, version, and error reporting.
///
/// ### Notes
/// - This CLI entrypoint is synchronous in terms of initialization
///   but asynchronous for actual command execution via `Future`.
/// - Supports prompt-driven interactions if a command requires
///   missing information (e.g., entry files, directories).
/// - Uses a consistent [CliLogger] session for CLI output, errors,
///   warnings, and informational messages.
/// {@endtemplate}
final class ApplicationCli implements Cli {
  /// {@macro jetleaf_application_cli}
  const ApplicationCli();

  @override
  Future<void> run(List<String> args) async {
    final CliLogger logger = cliSession.get("CLI");

    // 1️⃣ Fetch the JetLeaf CLI version
    final String version = await getRunningVersion();

    // 2️⃣ Display the CLI header with branding and tips
    print('''
🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃
🍃
🍃 🌐 Website : https://jetleaf.hapnium.com        
🍃 🚀 Running : JetLeaf CLI v$version
🍃 🛠️  Powered by Hapnium — the Dart backend engine
🍃 💡 Tip     : Type 'jl --help' to see available commands
🍃
🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃 🍃
''');

    // 3️⃣ Handle global flags first
    if (args.contains('--version') || args.contains('-v')) {
      return VersionCommandRunner().run(args);
    }

    if (args.isEmpty || args.contains('--help') || args.contains('-h') || args.contains('help')) {
      return HelpCommandRunner().run(args);
    }

    // 4️⃣ Extract the command name and arguments
    final String commandName = args.first;
    final List<String> commandArgs = args.skip(1).toList();

    CommandRunner? commandRunner;

    // 5️⃣ Attempt to find a corresponding CommandRunner
    try {
      commandRunner = HelpCommandRunner.RUNNERS.firstWhere((cmd) => cmd.canUse(commandName));
    } catch (e) {
      logger.error('❌ Unknown command: "$commandName".');

      // Prompt the user to show help
      final bool showHelp = prompt.getBool('Would you like to see the list of available commands?', defaultsTo: true);

      if (showHelp) {
        await HelpCommandRunner().run(args);
      }

      // Exit with error code
      exit(1);
    }

    // 6️⃣ Delegate to the command runner with the remaining arguments
    return commandRunner.run(commandArgs);
  }
}