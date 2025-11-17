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

/// {@template jetleaf_hot_reload_command_runner}
/// A command runner that triggers a **manual hot-reload** of the currently
/// running JetLeaf development application.
///
/// The `HotReloadCommandRunner` integrates with JetLeaf’s development pipeline
/// by delegating to the active [ProjectWatcher], invoking
/// [ProjectWatcher.triggerReload] to refresh the runtime state and optionally
/// rebuild the project as needed.
///
/// This command is typically invoked through:
/// - JetLeaf CLI (`jl reload`)
/// - IDE tooling or plugin integrations
/// - Custom development scripts
///
/// ### Behavior
/// When executed, this command:
/// 1. Resolves the active project watcher  
/// 2. Issues a reload request via `_watcher.triggerReload()`  
/// 3. Logs output using JetLeaf’s CLI logging infrastructure  
///
/// It does **not** modify build inputs, restart the watcher, or rebuild the
/// project directly. All reload mechanics are delegated to the watcher.
///
/// ### Usage Example
/// ```bash
/// $ jl reload
/// 🔁 Reloading application...
/// ✔ Reload complete
/// ```
///
/// ### Design Notes
/// - This command is only meaningful in **development mode**.
/// - It relies on the globally injected or initialized watcher instance.
/// - All reloading logic is intentionally delegated to the watcher to avoid
///   coupling CLI commands to runtime pipelines.
///
/// ### Example Behavior
/// | Command        | Behavior                         |
/// |----------------|----------------------------------|
/// | `jl reload`    | Triggers watcher-managed reload  |
///
/// ### See Also
/// - [ProjectWatcher.triggerReload]
/// - [CommandRunner]
/// - JetLeaf Development Runtime  
/// {@endtemplate}
final class HotReloadCommandRunner extends CommandRunner {
  /// {@macro jetleaf_hot_reload_command_runner}
  const HotReloadCommandRunner();

  @override
  String get command => 'reload';

  @override
  String get description => 'Reloads the running application during development.';

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
    await _watcher.triggerReload();
  }
}