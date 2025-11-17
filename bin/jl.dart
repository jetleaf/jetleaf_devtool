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

import 'package:jetleaf_devtool/src/cli/cli.dart';

/// Entry point for the JetLeaf CLI.
///
/// This initializes the CLI system and delegates execution to
/// [ApplicationCli], which handles command dispatch, global flags,
/// help/version output, and subcommand execution.
///
/// ### Usage
/// ```bash
/// dart run jl <command> [options]
/// ```
///
/// Example:
/// ```bash
/// # Show general help
/// dart run jl --help
///
/// # Run the development server
/// dart run jl dev --entry lib/main.dart --watch
/// ```
/// 
/// Usage:
/// dart jl dev            # Development mode (no build)
/// dart jl build          # Build and run mode
/// dart jl help           # Display help information
/// dart jl --version      # Display version information
/// 
/// [chmod +x ~/Documents/Hapnium/jetleaf_framework/jetleaf_devtool/bin/jl.dart]
/// [dart pub global activate --source path .]
Future<void> main(List<String> arguments) async {
  // 1️⃣ Instantiate the CLI implementation
  const Cli cli = ApplicationCli();

  // 2️⃣ Delegate execution to ApplicationCli
  //    - Handles global flags (--help, --version)
  //    - Resolves subcommands (dev, prod, hot reload, etc.)
  //    - Prompts user if necessary for missing arguments
  await cli.run(arguments);

  // 3️⃣ Exit is handled internally by ApplicationCli/CommandRunner
  //    in case of errors or unknown commands.
}