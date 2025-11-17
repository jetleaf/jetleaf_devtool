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

/// {@template proxy_command_runner}
/// A CLI command responsible for generating **proxy subclasses** for runtime
/// method interception within the JetLeaf framework.
///
/// The [ProxyCommandRunner] is a foundational tool in JetLeaf’s
/// **compile-time code generation pipeline**. It orchestrates the scanning
/// of Dart source files for interceptable classes and produces proxy
/// subclasses (prefixed with `$$`) that delegate their method invocations
/// through JetLeaf’s interception and reflection systems.
///
/// ### Purpose
/// Proxy generation enables **aspect-oriented programming (AOP)** patterns in
/// JetLeaf, allowing developers to:
/// - Inject logic before, after, or around method calls
/// - Apply annotations for behavior-driven interception
/// - Enable runtime reflection in restricted compilation environments
///
/// ### Command Overview
/// ```bash
/// Usage: jl proxy [options]
///
/// Description:
///   Generates proxy subclasses for runtime method interception.
///
/// Details:
///   This command scans your project for eligible Dart classes and generates
///   proxy subclasses (prefixed with $$) that override each method to route
///   invocations through the interception layer. These proxies can be used
///   to trace, log, or modify method behavior dynamically at runtime.
///
/// Notes:
///   • Classes marked `final` or imported from external libraries are skipped.
///   • Generated proxies are stored in the designated output directory
///     (e.g., `lib/generated/`) and can be imported directly where needed.
///
/// Examples:
///   jl proxy
/// ```
///
/// ### How It Works
/// When executed, this command internally invokes [_runBuildRunner] to start
/// the **Dart Build Runner** process, which scans the project for annotated
/// classes and generates corresponding proxy source files:
///
/// ```text
/// ├─ lib/
/// │  ├─ services/
/// │  │  ├─ user_service.dart
/// │  │  └─ $$user_service.dart    ← Generated proxy subclass
/// │  └─ generated/
/// │     └─ $$database_client.dart ← Generated proxy for interceptable client
/// ```
///
/// Each proxy class is dynamically linked to JetLeaf’s
/// [MethodInterceptorDispatcher] during runtime, enabling the framework’s
/// interception mechanisms such as:
/// - Logging, metrics, or analytics collection
/// - Transactional wrapping
/// - Access control or authorization checks
/// - Conditional method decoration
///
/// ### Integration With Other Commands
/// The proxy generation process is a **core dependency** of the
/// [ProductionCommandRunner] and [DevCommandRunner], both of which invoke
/// this logic implicitly during their build pipelines. However, developers
/// can also run `jl proxy` directly to validate proxy generation in isolation.
///
/// ### Example
/// ```dart
/// final runner = ProxyCommandRunner();
/// await runner.run([]);
/// ```
///
/// Output:
/// ```bash
/// 🔨 Running `dart run build_runner build` in /my/project
/// ✅ Proxy generation finished successfully (exit 0)
/// ```
///
/// ### Error Handling
/// - If any build step fails, the process terminates with a descriptive
///   log message and `exit(1)`.
/// - Build Runner errors, syntax issues, or invalid annotations are
///   automatically surfaced by the JetLeaf logger for developer visibility.
///
/// ### References
/// - [_runBuildRunner] → Launches the Dart Build Runner process
/// - [CliLogger] → Handles structured log output and error tracing
/// - [MethodInterceptorDispatcher] → Coordinates interception at runtime
/// - [ConditionalMethodInterceptor] → Defines conditions for proxy invocation
///
/// ### See Also
/// - [ProductionCommandRunner] — Compiles proxies into final artifacts
/// - [Interceptable] — Mixin enabling method interception on target objects
/// - [ChainedMethodInterceptor] — Manages multi-layer interception logic
///
/// {@endtemplate}
final class ProxyCommandRunner extends CommandRunner {
  /// {@macro proxy_command_runner}
  ///
  /// Instantiates a CLI command runner dedicated to proxy generation. This
  /// runner integrates directly with JetLeaf’s build lifecycle and can be
  /// invoked either independently or as part of a composite build pipeline.
  const ProxyCommandRunner();

  @override
  String get command => 'proxy';

  @override
  String get description => 'Generates proxy subclasses for runtime method interception.';

  @override
  CliLogger get logger => cliSession.get(command.toUpperCase());

  @override
  String get usage => '''
Usage: jl $command [options]

Description:
$description

Details:
This command scans your project for eligible Dart classes and generates
proxy subclasses (prefixed with \$\$) that override each method to route
invocations through the interception layer. These proxies can be used
to trace, log, or modify method behavior dynamically at runtime.

Notes:
• Classes marked final or imported from external libraries will be
skipped, and warnings will be logged.
• Generated proxies are written to a designated output directory
(e.g., "lib/generated/") and can be imported where needed.

Examples:
jl $command
''';

  @override
  Future<void> run(List<String> args) async {
    final stopWatch = Stopwatch()..start();
  
    try {
      final project = Directory.current;
      await _runBuildRunner(project, logger);
      stopWatch.stop();
    } catch (e) {
      stopWatch.stop();
      logger.error('Error during build run: $e');
      exit(1);
    }
  }
}