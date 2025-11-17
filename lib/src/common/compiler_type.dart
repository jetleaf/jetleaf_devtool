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

import 'package:jetleaf_lang/lang.dart';

/// {@template compiler_enum}
/// Defines the **compilation strategy** used by the JetLeaf runtime and
/// build system.
///
/// The [CompilerType] enum determines how application metadata, dependency
/// graphs, and reflection data are discovered and provided to the runtime.
///
/// Each compilation mode impacts the **startup time**, **runtime performance**,
/// and **deployment portability** of a JetLeaf application.
///
/// ### Overview
/// | Mode | Description | Typical Use Case |
/// |------|--------------|------------------|
/// | [JIT] | Performs reflection-based metadata discovery at runtime. | Local development, rapid prototyping, or hot reload scenarios. |
/// | [AOT] | Pre-generates metadata at compile time and embeds it into the binary. | Production builds or constrained environments where reflection is unavailable. |
/// | [EXE] | Similar to AOT, but specifically used for standalone executable compilation targets. | Native executable builds, CI/CD pipelines, or containerized environments. |
///
/// ### Key Differences
/// - **JIT Mode:**
///   - Enables dynamic scanning and runtime injection.
///   - Offers maximum flexibility with reflection-based discovery.
///   - Requires runtime access to source metadata.
///
/// - **AOT Mode:**
///   - Removes reflection overhead.
///   - Produces faster startup and smaller runtime footprint.
///   - Requires the metadata generator to run at build time.
///
/// - **EXE Mode:**
///   - Extends [AOT] with executable-specific optimizations.
///   - Typically used when compiling to self-contained binaries (`dart compile exe`).
///
/// ### Example
/// ```dart
/// void main() {
///   final compiler = Compiler.fromString('AOT');
///
///   switch (compiler) {
///     case Compiler.JIT:
///       print('Running in Just-In-Time mode');
///       break;
///     case Compiler.AOT:
///       print('Running in Ahead-Of-Time mode');
///       break;
///     case Compiler.EXE:
///       print('Running in Executable (AOT) mode');
///       break;
///   }
/// }
/// ```
///
/// ### References
/// - [RuntimeCompiler] — Manages runtime metadata loading based on the selected [CompilerType].
/// - [MetadataGenerator] — Responsible for metadata emission in AOT/EXE modes.
/// - [ApplicationRuntimeScanner] — Uses [CompilerType] to determine discovery strategy.
/// - [JetLeafConfig] — Stores the selected compiler mode in the runtime configuration.
/// {@endtemplate}
enum CompilerType {
  /// {@macro compiler_enum}
  ///
  /// **Just-In-Time** mode — metadata is discovered dynamically using reflection
  /// at runtime. This mode is ideal for development environments and hot reload
  /// workflows, as it allows immediate code changes to be reflected without
  /// recompilation.
  JIT,

  /// {@macro compiler_enum}
  ///
  /// **Ahead-Of-Time** mode — metadata is pre-generated during build time and
  /// embedded into the compiled binary. Reflection is replaced by static data
  /// lookups, improving startup performance and runtime determinism.
  AOT,

  /// {@macro compiler_enum}
  ///
  /// **Executable (EXE)** mode — identical to [AOT] in metadata behavior, but
  /// optimized for self-contained executable targets. Used primarily for native
  /// binary deployments or cross-platform JetLeaf CLI tools.
  EXE;

  /// Creates a [CompilerType] instance from a string representation.
  ///
  /// Accepts case-sensitive names (`'JIT'`, `'AOT'`, `'EXE'`). Throws an
  /// [UnsupportedOperationException] if an invalid name is provided.
  ///
  /// ### Example
  /// ```dart
  /// final compiler = Compiler.fromString('JIT');
  /// print(compiler); // Compiler.JIT
  /// ```
  ///
  /// ### Throws
  /// - [UnsupportedOperationException] — If [name] does not match any valid
  ///   [CompilerType] value.
  ///
  /// ### See Also
  /// - [CompilerType] enum values for available compilation strategies.
  /// - [JetLeafVersion] for the currently supported JetLeaf build environment.
  static CompilerType fromString(String name) {
    switch (name) {
      case 'JIT':
        return CompilerType.JIT;
      case 'AOT':
        return CompilerType.AOT;
      case 'EXE':
        return CompilerType.EXE;
      default:
        throw UnsupportedOperationException('Invalid compiler type: $name');
    }
  }
}