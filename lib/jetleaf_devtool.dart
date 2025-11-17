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

/// JetLeaf Bootstrap — Public Library Interface
///
/// This library exposes the primary APIs used for:
/// - Running JetLeaf CLI commands
/// - Executing the JetLeaf command runner
/// - Building and generating project artifacts
/// - Accessing code-generation and bootstrap support utilities
/// - Watching files and projects for changes
///
/// Consumers can import this library to interact with JetLeaf’s
/// build system, code generators, and project watchers.
library;

export 'src/cli/cli.dart';
export 'src/command_runner/command_runner.dart';
export 'src/project_builder/project_builder.dart';
export 'src/support/support.dart';
export 'src/watcher/file_watcher.dart';
export 'src/watcher/project_watcher.dart';