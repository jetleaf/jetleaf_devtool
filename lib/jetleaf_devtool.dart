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

/// 🛠 **JetLeaf Devtool**
///
/// The JetLeaf Devtool provides a set of development utilities for
/// JetLeaf projects, including CLI tools, project building, file
/// watching, and command execution support.
///
/// This library is designed to streamline development workflows,
/// automate repetitive tasks, and provide live feedback during
/// project development.
///
///
/// ## 🔑 Core Components
///
/// ### 💻 Command-Line Interface
/// - `cli.dart` — core CLI entry point and interface for executing
///   development tasks
///
/// ### 🏃 Command Runner
/// - `command_runner.dart` — executes registered commands with
///   arguments and manages command lifecycle
///
/// ### 📦 Project Builder
/// - `project_builder.dart` — handles project compilation, build
///   scripts, and automated project tasks
///
/// ### 🔧 Support Utilities
/// - `support.dart` — helper functions and utilities to support
///   development operations
///
/// ### 👀 File & Project Watchers
/// - `file_watcher.dart` — watches files for changes and triggers
///   configured actions
/// - `project_watcher.dart` — monitors the project directory and
///   automates tasks such as rebuilds, reloads, or other developer
///   workflows
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to integrate development tooling into your
/// JetLeaf project:
/// ```dart
/// import 'package:jetleaf_devtool/jetleaf_devtool.dart';
///
/// final watcher = ProjectWatcher();
/// watcher.watch();
/// ```
///
/// Provides automated file watching, command execution, and project
/// building capabilities to enhance the developer experience.
///
///
/// © 2025 Hapnium & JetLeaf Contributors
library;

export 'src/cli/cli.dart';
export 'src/command_runner/command_runner.dart';
export 'src/project_builder/project_builder.dart';
export 'src/support/support.dart';
export 'src/watcher/file_watcher.dart';
export 'src/watcher/project_watcher.dart';