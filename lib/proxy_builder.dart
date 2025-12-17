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

// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_lang/jetleaf_lang.dart' show getNonNecessaryPackages;
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'proxy_generator.dart';
import 'src/utils.dart';

/// {@template proxy_builder}
/// # ProxyBuilder
///
/// A [Builder] implementation responsible for generating proxy subclasses
/// of annotated classes (e.g., those annotated with `@Service`, `@Component`,
/// `@Controller`, etc.) during JetLeaf’s build phase.
///
/// The `ProxyBuilder` integrates with the `build_runner` toolchain to
/// transform `.dart` source files into corresponding `.proxy.dart` files
/// that contain interception-ready subclasses. These generated proxies
/// serve as runtime wrappers that enable JetLeaf’s method interception,
/// dependency injection, and lifecycle management mechanisms.
///
/// ---
///
/// ## ⚙️ How It Works
/// 1. **File Filtering** — Skips generation for any files inside the
///    [Constant.GENERATED_DIR_NAME] directory to prevent recursive
///    proxy generation.
/// 2. **Library Resolution** — Uses the `BuildStep.resolver` to resolve
///    the Dart library represented by the input asset.
/// 3. **Annotation Discovery** — Passes the library to the
///    [ProxyGenerator], which identifies stereotype annotations such as
///    `@Service` or `@Component`.
/// 4. **Proxy Generation** — For each discovered class, a proxy subclass
///    is emitted that wraps method calls in interception logic using
///    [Interceptable] and [MethodInterceptorDispatcher].
/// 5. **Output Storage** — The generated code is written to:
///    - The standard `.proxy.dart` file in the same directory, and
///    - A project-wide generated directory (`_jetleaf/`) for bootstrap inclusion.
///
/// ---
///
/// ## 🧩 Example
///
/// Suppose you have a service class:
///
/// ```dart
/// @Service()
/// class UserService {
///   String greet(String name) => 'Hello, $name';
/// }
/// ```
///
/// After running `dart run build_runner build`, `ProxyBuilder` will
/// generate a file named:
///
/// ```text
/// lib/user_service.proxy.dart
/// ```
///
/// containing:
///
/// ```dart
/// final class $$UserService with Interceptable implements UserService, ClassGettable<UserService> {
///   final UserService delegate;
///   $$UserService(this.delegate);
///
///   @override
///   String greet(String name) async =>
///       this.when<String>(() async => delegate.greet(name), delegate, 'greet',
///         MethodArguments(positionalArgs: [name]));
/// }
/// ```
///
/// ---
///
/// ## 📂 Output Organization
/// - Local proxy output: `lib/*.proxy.dart`
/// - Global generated proxy store:
///   `${Constant.GENERATED_DIR_NAME}/<package>/<path>_proxy.dart`
///
/// This dual output structure allows JetLeaf’s CLI (`jl build`) to include
/// proxies directly in the build bootstrap phase.
///
/// ---
///
/// ## 🧠 Notes
/// - Files inside `_jetleaf/` are ignored to avoid recursive proxy generation.
/// - SDK libraries (`dart:` imports) are skipped during analysis.
/// - The [ProxyGenerator] is stateless and can safely be reused across builds.
///
/// ---
///
/// ## See also
/// - [ProxyGenerator] — the core generator that emits proxy class source
/// - [Interceptable] — the mixin injected into generated proxy classes
/// - [MethodInterceptorDispatcher] — handles runtime interception flow
/// - [Constant] — defines `_jetleaf` as the generated resource directory
///
/// {@endtemplate}
class ProxyBuilder extends Builder {
  /// {@macro proxy_builder}
  ProxyBuilder();

  static const String KEYWORD = "package:jetleaf";
  static const String DART = "dart:";

  @override
  final buildExtensions = const { '.dart': ['.proxy.dart'], };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    
    // 1️⃣ Skip generated, part, and hidden files
    final path = inputId.path;

    if (path.startsWith(Constant.GENERATED_DIR_NAME)) {
      return;
    }

    if (inputId.package.startsWith("jetleaf") || inputId.uri.toString().startsWith(KEYWORD)) {
      return;
    }

    if (inputId.uri.toString().startsWith(DART)) {
      return;
    }

    final skip = [
      ...getNonNecessaryPackages(),
      "fixnum",
      "graphs",
      "http_multi_server",
      "io",
      "jetson",
      "jtl",
      "matcher",
      "collection",
      "string_scanner",
      "mime",
      "pool",
      "pubspec_parse",
      "checked_yaml",
      "json_annotation",
      "shelf_web_socket",
      "shelf",
      "http_parser",
      "args",
      "logging",
      "source_span",
      "watcher",
      "boolean_selector",
      "stack_trace",
      "stream_transform",
      "convert",
      "file",
      "glob",
      "package_config",
      "path",
      "term_glyph",
      "yaml",
      "meta",
      "async",
      "typed_data",
      "crypto",
      "stream_channel",
      "web",
      "web_socket",
      "web_socket_channel",
    ];

    if (skip.any((s) => s.equals(inputId.package))) {
      return;
    }

    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      return;
    }

    // 2️⃣ Try to see if this is a valid Dart library before resolving
    if (!await buildStep.resolver.isLibrary(inputId)) {
      return; // Skip part files and non-library units
    }

    final resolver = buildStep.resolver;
    final lib = await resolver.libraryFor(inputId);

    // 3️⃣ Skip SDK libs and analyzer internals
    if (lib.isInSdk || lib.uri.toString().startsWith(DART) || lib.identifier.contains(DART)) return;
    if (lib.uri.toString().startsWith(KEYWORD)) return;

    if ((await buildStep.inputLibrary).firstFragment.importedLibraries.map((i) => i.uri.toString()).toList().none((im) => im.contains(KEYWORD))) {
      return;
    }

    final reader = LibraryReader(lib);
    final generator = ProxyGenerator();
    final output = await generator.generate(reader, buildStep);
    if (output.trim().isEmpty) return;

    // Store the result in the global map
    final inputPath = buildStep.inputId.path; // e.g. lib/core/config.dart
    final relPath = p.withoutExtension(inputPath);
    final outputPath = '${Constant.GENERATED_DIR_NAME}/${relPath.replaceFirst("lib", '${buildStep.inputId.package}_proxies')}_proxy.dart';
    await writeGeneratedOutput(output, File(outputPath));
    
    final outputId = inputId.changeExtension('.proxy.dart');
    await buildStep.writeAsString(outputId, output);
  }
}

/// {@template proxy_builder_factory}
/// Factory entrypoint for JetLeaf’s proxy code generator.
///
/// This function is invoked automatically by `build_runner` when
/// JetLeaf’s build extensions are registered in `build.yaml`.
///
/// Example `build.yaml` snippet:
/// ```yaml
/// targets:
///   $default:
///     builders:
///       jetleaf|proxy_builder:
///         generate_for:
///           - lib/**.dart
/// ```
///
/// Returns a new instance of [ProxyBuilder].
///
/// {@endtemplate}
Builder proxyBuilder(BuilderOptions options) => ProxyBuilder();