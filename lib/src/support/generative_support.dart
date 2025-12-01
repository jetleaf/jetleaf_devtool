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

part of 'support.dart';

/// {@template generative_support}
/// Provides the core code-generation utilities used during JetLeaf’s bootstrap
/// build process.
///
/// `GenerativeSupport` is responsible for transforming *runtime resources* and
/// *package metadata* into statically generated Dart wrapper classes that JetLeaf
/// can load reflectively at runtime. It extends [WritingSupport], inheriting
/// file-system utilities and string helpers used by the generator.
///
/// # Responsibilities
///
/// `GenerativeSupport` implements the two major phases of JetLeaf’s build
/// pipeline:
///
/// ## 1. Asset Embedding (`generateAndWriteAssets`)
///
/// Scans a target package for all non-Dart resource files:
///
/// - HTML templates  
/// - JSON/YAML/TOML configuration files  
/// - Static web assets (CSS, JS)  
/// - Images, binaries, misc files  
///
/// Each discovered resource is converted into a **strongly typed**
/// `GenerativeAsset` subclass containing:
///
/// - The asset’s file path
/// - The asset’s file name
/// - The originating package name
/// - A literal `Uint8List` representing the file’s raw bytes
/// - A **zero-argument constructor**, required for runtime mirror instantiation
///
/// Asset classes are emitted into:
///
/// ```text
/// <buildDir>/jetleaf_generated/assets/*.dart
/// ```
///
/// JetLeaf’s runtime bootstrapper then discovers these classes via mirrors and
/// registers them as available embedded assets.
///
///
/// ## 2. Package Metadata Embedding (`generateAndWritePackages`)
///
/// Reads `.dart_tool/package_graph.json` and emits a `GenerativePackage` class
/// for every package found in the graph—including transitive dependencies.
///
/// Generated classes contain:
///
/// - Package name  
/// - Package version  
/// - Language version  
/// - Whether it is the root package  
/// - File system path  
/// - Root URI  
/// - A **zero-argument constructor** for reflective instantiation  
///
/// Package classes are emitted into:
///
/// ```text
/// <buildDir>/jetleaf_generated/packages/*.dart
/// ```
///
/// These classes are later used by JetLeaf tooling and runtime systems to
/// introspect dependencies without re-parsing the project’s `.dart_tool`
/// metadata.
///
///
/// # Naming & Sanitization Helpers
///
/// The class also provides:
///
/// - [`sanitizePackageName`] — normalizes any package name into a valid Dart
///   PascalCase identifier.
///
/// - [`sanitizeFileName`] — extracts the base file name, strips extensions,
///   removes invalid characters, and converts it into PascalCase.
///
/// These helpers ensure that generated class names:
///
/// - are always valid Dart identifiers  
/// - never start with a number  
/// - contain no punctuation or symbols  
/// - remain deterministic across builds  
///
///
/// # Spinner Integration
///
/// Both generation methods display a CLI spinner to provide real-time feedback
/// during long-running IO operations:
///
/// - Start messages (e.g., “🔍 Embedding assets…”)  
/// - Success messages including output path and counts  
/// - Informational messages when nothing is generated  
///
/// This improves user experience in JetLeaf’s bootstrap command-line flow.
///
///
/// # Error Handling
///
/// - Missing assets or empty dependency graphs are treated as valid states—no
///   errors are thrown.
/// - File writing errors or IO exceptions are allowed to bubble up, so the
///   calling build system can surface them properly.
/// - Metadata extraction is delegated entirely to [FileUtility]; no silent
///   corrections occur.
///
///
/// # Usage
///
/// This class is used internally by:
///
/// - JetLeaf Bootstrap Generator  
/// - JetLeaf CLI (`jetleaf create`, `jetleaf build`, etc.)  
///
/// It is **not** intended for direct consumption by application developers.
/// Instead, they benefit from the generated wrappers indirectly when
/// JetLeaf loads assets and package metadata at runtime.
///
///
/// # Extension Points
///
/// Tooling authors may extend `GenerativeSupport` to customize:
///
/// - additional resource formats  
/// - different output directory structures  
/// - alternative generation templates  
///
/// The class is designed to be flexible but is **not** meant to be modified
/// by end-users of the JetLeaf framework.
///
///
/// # Summary
///
/// `GenerativeSupport` is the backbone of JetLeaf’s compile-time resource and
/// metadata embedding system. It converts dynamic files and package metadata
/// into static Dart code that JetLeaf can load at runtime via mirrors—enabling
/// predictable, reflection-safe, and high-performance access to resources
/// without requiring them to remain on disk.
///
/// This class should only be invoked by JetLeaf’s internal build processes and
/// is not part of the public API surface.
/// {@endtemplate}
abstract class GenerativeSupport extends WritingSupport {
  /// {@macro generative_support}
  const GenerativeSupport();

  /// Discovers all non-Dart resource files in the target package and generates
  /// strongly-typed Dart wrapper classes (`GenerativeAsset`) for each of them.
  ///
  /// This method performs the full “asset embedding” step of the JetLeaf
  /// bootstrap process. It scans the user’s package, collects every file that
  /// qualifies as an embeddable resource (HTML, JSON, configuration files,
  /// templates, images, etc.), and emits a Dart file for each asset containing:
  ///
  /// - Static metadata:  
  ///   - package name  
  ///   - file path within the package  
  ///   - file name  
  ///
  /// - A no-argument constructor (required for runtime mirror instantiation)
  /// - A `Uint8List` literal containing the asset’s raw bytes
  ///
  /// The generated classes extend `GenerativeAsset` and follow this pattern:
  ///
  /// ```dart
  /// final class <SanitizedClassName> extends GenerativeAsset {
  ///   <SanitizedClassName>();
  ///
  ///   @override
  ///   String getFilePath() => '...';
  ///
  ///   @override
  ///   String getFileName() => '...';
  ///
  ///   @override
  ///   String? getPackageName() => '...';
  ///
  ///   @override
  ///   Uint8List getContentBytes() => Uint8List.fromList([0x00, 0xFF, ...]);
  /// }
  /// ```
  ///
  /// ## Output Location
  ///
  /// All generated asset wrappers are written to:
  ///
  /// ```text
  /// <buildDir>/<jetleaf_generated>/assets/*.dart
  /// ```
  ///
  /// The directory is created automatically if missing. Each generated file:
  ///
  /// - Is named using `snake_case` based on the constructed class name  
  /// - Contains full JetLeaf copyright & license headers  
  /// - Is marked as **auto-generated** (do not edit)
  ///
  /// ## Return Value
  ///
  /// Returns a `String` containing import statements pointing to all
  /// generated asset classes. These imports must later be inserted into the
  /// bootstrap runtime file so that the generated resources are included in the
  /// final `.dill`.
  ///
  /// Example returned import:
  ///
  /// ```dart
  /// import 'generated/assets/my_app_logo_generative_asset.dart';
  /// ```
  ///
  /// ## Spinner Output
  ///
  /// A CLI spinner is displayed during generation:
  ///
  /// - Starts: “🔍 Embedding assets into Dart classes…”  
  /// - Success (with assets): “✅ Embedded N resources into Dart classes …”  
  /// - Success (none found): “ℹ️ No non-Dart resource files found to embed.”  
  ///
  /// ## Parameters
  ///
  /// - **[targetPath]**  
  ///   The absolute path to the final bootstrap file. Used to compute relative
  ///   paths for import generation.
  ///
  /// - **[packageName]**  
  ///   The name of the package whose assets are being discovered.
  ///
  /// - **[fileUtils]**  
  ///   The utility responsible for discovering resource files and reading bytes.
  ///   Must expose:
  ///     - `discoverAllResources`
  ///     - `resource.getContentBytes()`
  ///     - file/format helpers
  ///
  /// ## Behavior Summary
  ///
  /// 1. Starts a spinner  
  /// 2. Ensures the output directory exists  
  /// 3. Discovers all embeddable resources in the package  
  /// 4. For each resource:
  ///    - Sanitizes names for safe class identifiers  
  ///    - Converts the file’s binary bytes to a Dart byte literal  
  ///    - Generates a fully documented Dart file  
  ///    - Adds an import entry to the returned set  
  /// 5. Stops the spinner with a success message  
  ///
  /// ## Error Handling
  ///
  /// - The method does **not throw** for missing assets; it simply emits none.  
  /// - File I/O errors from `writeAsString` propagate upward to the caller.
  /// - Byte reading is delegated fully to `fileUtils`.
  ///
  /// ## Performance Notes
  ///
  /// - Byte lists are embedded directly into the generated Dart files, making
  ///   access extremely fast at runtime.
  /// - Resources are not tree-shaken out of the final AOT build because the
  ///   generated files are imported explicitly.
  ///
  /// This method is used during the JetLeaf bootstrap generation phase and is
  /// not intended for direct invocation outside the build system.
  @protected
  Future<String> generateAndWriteAssets(String targetPath, String packageName, FileUtility fileUtils, CliLogger logger) async {
    final spinner = Spinner('🔍 Embedding assets into dart classes...');
    spinner.start();

    final outputPath = p.join(p.dirname(targetPath), "generated_assets.dart");
    final outputFile = File(outputPath);

    if (!outputFile.existsSync()) {
      await outputFile.create(recursive: true);
    }

    final resources = await fileUtils.discoverAllResources(packageName);
    if (resources.isNotEmpty) {
      await writeGeneratedAssets(resources, outputPath, outputFile);
      spinner.stop();
      logger.info('✅ Embedded ${resources.length} resources into dart classes in ${outputFile.path}');
    } else {
      spinner.stop();
      logger.warn('ℹ️ No non-dart resource files found to embed.');
    }

    return p.relative(outputPath, from: p.dirname(targetPath));
  }

  /// Discovers all Dart packages listed in the project's package graph and
  /// generates strongly-typed Dart metadata wrappers (`GenerativePackage`) for
  /// each one.
  ///
  /// This method powers the “package embedding” stage of JetLeaf’s bootstrap
  /// generation. It reads `.dart_tool/package_graph.json` (via
  /// [FileUtility.readPackageGraphDependencies]) and produces a dedicated Dart
  /// class for every package—including transitive dependencies—containing:
  ///
  /// - compile-time metadata (name, version, language version)  
  /// - file system paths  
  /// - the package’s root URI  
  /// - whether the package is the *root application package*  
  ///
  /// Each wrapper is emitted as a class extending `GenerativePackage` with a
  /// **zero-argument constructor**, which is essential because JetLeaf instantiates
  /// packages through mirrors during runtime bootstrapping.
  ///
  /// Example generated class:
  ///
  /// ```dart
  /// final class httpGenerativePackage extends GenerativePackage {
  ///   httpGenerativePackage();
  ///
  ///   @override
  ///   String getName() => 'http';
  ///
  ///   @override
  ///   String getVersion() => '1.2.0';
  ///
  ///   @override
  ///   String? getLanguageVersion() => '3.3';
  ///
  ///   @override
  ///   bool getIsRootPackage() => false;
  ///
  ///   @override
  ///   String? getFilePath() => '/.../.pub-cache/...';
  ///
  ///   @override
  ///   String? getRootUri() => 'package:http/';
  /// }
  /// ```
  ///
  /// ## Output Location
  ///
  /// All generated package wrappers are written to:
  ///
  /// ```text
  /// <buildDir>/<jetleaf_generated>/packages/*.dart
  /// ```
  ///
  /// The directory is automatically created if missing.
  ///
  /// Each file contains:
  ///
  /// - JetLeaf license header  
  /// - auto-generated notice  
  /// - import for `GenerativePackage`  
  /// - detailed macro documentation template  
  /// - sanitized, stable class name derived from the package name  
  ///
  /// File names are produced using `snake_case`:
  ///
  /// ```text
  /// my_package_generative_package.dart
  /// ```
  ///
  /// ## Return Value
  ///
  /// Returns a `String` containing the import line referencing the newly package file.
  /// These imports are later injected into JetLeaf’s
  /// bootstrap entrypoint, ensuring the generated packages are **preserved**
  /// during compilation.
  ///
  /// Example returned value:
  ///
  /// ```dart
  /// {
  ///   "import 'package:jetleaf_lang/lang.dart' show GenerativePackage;",
  ///   "import 'generated/packages/http_generative_package.dart';",
  ///   ...
  /// }
  /// ```
  ///
  /// ## Spinner Output
  ///
  /// A CLI spinner is displayed while the generator runs:
  ///
  /// - Start: “🔍 Embedding packages into Dart classes…”  
  /// - Success: “✅ Generated N PackageInfo files in path”  
  /// - No dependencies: Informational message, not an error  
  ///
  /// ## Behavior Breakdown
  ///
  /// 1. Start spinner  
  /// 2. Ensure output directory exists  
  /// 3. Read dependency graph from the project’s `.dart_tool` directory  
  /// 4. For each discovered package:
  ///    - Sanitize its name for use in a Dart class  
  ///    - Create a `<Name>GenerativePackage` class  
  ///    - Generate metadata getter overrides  
  ///    - Write the file to the packages directory  
  ///    - Record its import path  
  /// 5. Stop spinner with contextual success message  
  ///
  /// ## Parameters
  ///
  /// - **[targetPath]**  
  ///   The absolute path to the final bootstrap file that will import the
  ///   generated package classes.
  ///
  /// - **[project]**  
  ///   A directory representing the root of the current project.  
  ///   Used by [FileUtility] to locate `.dart_tool/package_graph.json`.
  ///
  /// - **[fileUtils]**  
  ///   Provides the package graph parser. Must expose:
  ///   - `readPackageGraphDependencies(Directory)`
  ///   - metadata getters such as `getName()`, `getVersion()`, etc.
  ///
  /// ## Error Handling
  ///
  /// - If `.dart_tool/package_graph.json` is missing or unreadable, the method
  ///   simply yields no generated files and prints an informational notice.
  /// - File write errors propagate to the caller.
  /// - The generator never silently swallows invalid package metadata; it embeds
  ///   exactly what the graph provides.
  ///
  /// ## Performance Notes
  ///
  /// - Generated classes store only lightweight metadata—no file content—
  ///   resulting in minimal code size impact.
  /// - Package metadata is embedded at compile time and loaded instantly at
  ///   runtime through mirrors.
  ///
  /// This method is used exclusively during JetLeaf’s bootstrap generation
  /// and should not be invoked manually outside the build system.
  @protected
  Future<String> generateAndWritePackages(String targetPath, Directory project, FileUtility fileUtils, CliLogger logger) async {
    final spinner = Spinner('🔍 Embedding packages into dart classes...');
    spinner.start();

    final outputPath = p.join(p.dirname(targetPath), "generated_packages.dart");
    final outputFile = File(outputPath);

    if (!outputFile.existsSync()) {
      await outputFile.create(recursive: true);
    }

    final resources = await fileUtils.readPackageGraphDependencies(project);
    if (resources.isNotEmpty) {
      await writeGeneratedPackages(resources, outputPath, outputFile);
      spinner.stop();
      logger.info('✅ Generated ${resources.length} package info files in ${outputFile.path}');
    } else {
      spinner.stop();
      logger.warn('ℹ️ No dependencies found in .dart_tool/package_graph.json to generate package info for.');
    }

    return p.relative(outputPath, from: p.dirname(targetPath));
  }
}