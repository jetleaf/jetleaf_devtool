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

import 'dart:io';

// import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:vm_service/vm_service.dart';

import '../command_runner/command_runner.dart';
import '../common/logger.dart';
import '../support/support.dart';
import 'file_watcher.dart';

part 'application_project_watcher.dart';

/// {@template jetleaf_project_watcher}
/// Defines the contract for **development-time project monitoring**, enabling
/// hot-reload, hot-restart, and dynamic rebuild flows within a JetLeaf
/// application.
///
/// A [ProjectWatcher] integrates with the Dart **VM Service** and the JetLeaf
/// **development build pipeline** to react to changes such as:
/// - Source code modifications  
/// - Asset or package updates  
/// - VM isolate reload notifications  
/// - Manual reload requests  
///
/// Watchers ensure that development builds remain reactive, up-to-date, and
/// capable of automatically regenerating bootstrap files or performing
/// incremental rebuilds when needed.
///
/// ### Watch Lifecycle
/// When [watch] is invoked, the watcher:
/// 1. Connects to and configures the provided [VmService]  
/// 2. Registers isolate, debugging, and reload-related event listeners  
/// 3. Starts monitoring the supplied [entryPoint] and its dependencies  
/// 4. Enables automatic rebuilds if [autoRebuild] is `true`  
///
/// ### Manual Reloads
/// Call [triggerReload] to initiate a full reload cycle, typically triggered by:
/// - File watcher events  
/// - JetLeaf CLI (`jetleaf dev`)  
/// - IDE extensions  
///
/// ### Usage Example
/// ```dart
/// final watcher = ApplicationProjectWatcher();
/// final vmService = await connectToVmService();
///
/// await watcher.watch(
///   vmService,
///   File('lib/main.dart'),
///   true, // auto rebuild on change
/// );
///
/// // Trigger a manual reload (e.g., user pressed "r")
/// await watcher.triggerReload();
/// ```
///
/// ### Design Notes
/// - Watchers run only in **development mode**.
/// - `autoRebuild` allows implementations to toggle incremental rebuild
///   behavior, useful for speeding up rebuilds in large projects.
/// - The watcher should remain active until the VM connection closes or the
///   development toolchain terminates.
///
/// ### See Also
/// - [VmService] — Dart VM Service protocol  
/// - JetLeaf development tooling  
/// - ApplicationProjectWatcher (in `application_project_watcher.dart`)  
/// {@endtemplate}
abstract interface class ProjectWatcher {
  /// Starts watching the project using the provided [vmService] connection.
  ///
  /// Implementations should attach VM event listeners, monitor the project’s
  /// [entryPoint], and — if [autoRebuild] is `true` — automatically initiate
  /// rebuilds when files change.
  Future<void> watch(VmService vmService, File entryPoint, bool autoRebuild, Directory project, CliLogger logger);

  /// Manually triggers a reload cycle.
  ///
  /// Implementations should:
  /// - Refresh relevant runtime state  
  /// - Coordinate with the build/runtime pipeline  
  /// - Invoke VM reload APIs as needed  
  ///
  /// Common callers include file watchers, CLI tools, and development
  /// IDE integrations.
  Future<void> triggerReload();
}