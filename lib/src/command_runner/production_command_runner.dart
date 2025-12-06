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

/// {@template production_command_runner}
/// A CLI command responsible for building a JetLeaf application in **production mode**.
///
/// The [ProductionCommandRunner] orchestrates the end-to-end build pipeline
/// for JetLeaf applications — including proxy generation, bootstrap
/// compilation, and final artifact output. It serves as the primary entry point
/// for developers and CI/CD environments when executing:
///
/// ```bash
/// jl build
/// ```
///
/// ### Core Responsibilities
/// - Executes the **Dart Build Runner** to generate proxy and metadata sources.
/// - Invokes [ProductionProjectBuilder] to generate the JetLeaf production
///   bootstrap file for the chosen [CompilerType] (currently only [CompilerType.JIT]).
/// - Performs the **compilation step**, producing the final `.dill` or executable
///   binary (once AOT/EXE modes are supported).
/// - Displays structured build summaries, timings, and file statistics.
///
/// ### Design Philosophy
/// This runner follows JetLeaf’s composable CLI command architecture, extending
/// the base [CommandRunner] interface. It is designed to remain stateless,
/// delegating all heavy lifting to specialized subsystems such as:
///
/// - [_runBuildRunner] — Handles build_runner subprocesses.
/// - [ProductionProjectBuilder] — Generates the runtime bootstrap entrypoint.
/// - [_compile] — Invokes the Dart compiler or AOT toolchain.
/// - [CliLogger] — Manages structured terminal logging and error reporting.
///
/// ### Command Usage
/// ```bash
/// Usage: jl build [options]
///
/// Description:
///   Build the application in production mode.
///
/// Note:
///   Compilation for AOT (.exe, .aot) support is not yet implemented.
///   As of JetLeaf v1.0.0, builds target only JIT (.dill).
///
/// Options:
///   -h,   --help       Show this help message (Flag).
///   -e,   --entry      Specify the entry file for the application.
///   -p,   --path       Path to executable file (e.g., "build/").
///   -n,   --name       Name of the executable file (e.g., "server").
///   -ed,  --exclude    Directories/Files to exclude from scanner.
///   -in,  --include    Directories/Files to include in the scanner.
///
/// Examples:
///   jl build --entry lib/main.dart
/// ```
///
/// ### Example (JIT Compilation)
/// ```dart
/// final runner = ProductionCommandRunner();
/// await runner.run(['--entry', 'lib/main.dart', '--path', 'build/', '--name', 'server']);
/// ```
///
/// Output:
/// ```bash
/// 🍃 JetLeaf Build Summary
/// 📦 Output .dill File:     build/server.dill
/// 🗂️ File Size:             2.3 MB
/// 🧪 Compiler Used:         JIT
/// ✅ Build Completed Successfully in 2134ms
/// ```
///
/// ### Build Stages
/// 1. **Proxy Generation**
///    - Invokes [_runBuildRunner] to execute `build_runner`.
///    - Generates proxy metadata files under `_jetleaf/`.
///
/// 2. **Bootstrap Generation**
///    - Constructs a [ProductionProjectBuilder] with the project’s entrypoint.
///    - Creates a generated bootstrap file that the compiler uses.
///
/// 3. **Compilation**
///    - Invokes `_compile` to build the `.dill` or future `.exe` artifact.
///    - Displays a detailed build summary and runtime tips.
///
/// ### Error Handling
/// - Any runtime failure during build steps triggers a structured CLI error
///   message and terminates with exit code `1`.
/// - Wraps all stages in a `Stopwatch` to provide performance metrics.
///
/// ### References
/// - [ProductionProjectBuilder] — Generates the bootstrap entrypoint for production builds.
/// - [_runBuildRunner] — Manages proxy generation using Dart’s build system.
/// - [CompilerType] — Enum defining available compiler backends (JIT, AOT, EXE).
/// - [CliLogger] — Structured logger for JetLeaf CLI output.
/// - [CommandRunner] — Base class for all JetLeaf CLI subcommands.
///
/// {@endtemplate}
final class ProductionCommandRunner extends CommandRunner {
  /// Creates a new production-mode JetLeaf command runner instance.
  ///
  /// This runner is typically instantiated internally by the `jl` CLI
  /// command dispatcher but can also be invoked manually for custom build
  /// orchestration or CI/CD automation.
  /// 
  /// {@macro production_command_runner}
  const ProductionCommandRunner();

  @override
  String get command => 'build';

  @override
  String get description => 'Build the application in production mode.';

  @override
  CliLogger get logger => cliSession.get(command.toUpperCase());

  @override
  String get usage => '''
Usage: jl $command [options]

Description:
  $description

Note:
  Compilation for AOT (.exe, .aot) support is not yet implemented. As at v1.0.0, JetLeaf compiles only for JIT (.dill)

Options:
  -h,   --help          Show this help message (Flag).
  -e,   --entry         Specify the entry file for the application.
  -p,   --path          Path to executable file (e.g., "build/").
  -n,   --name          Name of the executable file (e.g., "server").
  -ed,  --exclude       Directories/Files to exclude from scanner
  -in,  --include       Directories/Files to include in the scanner.
  -ni,  --no-interact   Disable interactive terminal - mostly for non-interactive terminals like docker. Provide answers via env or args.

Examples:
  jl $command --entry lib/main.dart
''';

  @override
  Future<void> run(List<String> args) async {
    final stopWatch = Stopwatch()..start();
    final project = Directory.current;
    final defaultPathFolder = "build";
    final defaultExecName = 'server';

    String? appPath;
    String? pathFolder = defaultPathFolder;
  
    try {
      Set<File> dartFiles = {};
      final noInteract = args.contains('--no-interact');
      File mainEntryFile = await _getEntryFile(args, logger, project, dartFiles.addAll, noInteract);
      final packageName = await _readPkgName(logger, project);

      // ------------------------------------------------------------
      // 🧩 STEP 1: Proxy generation + proxy entrypoint execution
      // ------------------------------------------------------------
      await _runBuildRunner(project, logger);

      pathFolder = _getArgValue(args, ['-p', '--path']);

      // Prompt for path file if not provided
      if (pathFolder == null || pathFolder.isEmpty) {
        if (noInteract) {
          pathFolder = _getValue(pathFolder, System.getEnvVar('JL_PATH_FOLDER'), defaultPathFolder);
        } else {
          pathFolder = prompt.get('Enter the path folder (Eg. $defaultPathFolder/)', defaultsTo: '$defaultPathFolder/');
        }
      }

      String? name = _getArgValue(args, ['-n', '--name']);

      // Prompt for name file if not provided
      if (name == null || name.isEmpty) {
        if (noInteract) {
          name = _getValue(name, System.getEnvVar('JL_EXEC_NAME'), defaultExecName);
        } else {
          name = prompt.get('Enter the executable file name (Eg. server)', defaultsTo: defaultExecName);
        }
      }

      String excluded = _getArgValue(args, ['--exclude', '-ed']) ?? System.getEnvVar('JL_BUILD_EXCLUDE') ?? '';
      String included = _getArgValue(args, ['--include', '-in']) ?? System.getEnvVar('JL_BUILD_INCLUDE') ?? '';
      List<String> excludeDirs = excluded.isEmpty ? [] : StringUtils.commaDelimitedListToStringList(excluded);
      List<String> includeDirs = included.isEmpty ? [] : StringUtils.commaDelimitedListToStringList(included);

      // 🔹 Ask for excluded directories if none provided
      if (!noInteract) {
        if (excludeDirs.isEmpty && prompt.getBool('Any directories to exclude from scanning?', defaultsTo: false)) {
          excludeDirs = StringUtils.commaDelimitedListToStringList(
            prompt.get('Enter comma-separated directories to exclude (e.g., "temp,dist")', defaultsTo: ''),
          );
        }

        // 🔹 Ask for included directories if none provided
        if (includeDirs.isEmpty && prompt.getBool('Any directories to include from scanning?', defaultsTo: false)) {
          includeDirs = StringUtils.commaDelimitedListToStringList(
            prompt.get('Enter comma-separated directories to include (e.g., "src,lib")', defaultsTo: ''),
          );
        }
      }

      final compiler = CompilerType.JIT;
      final outputPath = p.join(pathFolder, '$name${_getFileType(compiler)}');
      appPath = outputPath;
      final sourcePath = p.join(project.path, pathFolder, '${packageName}_bootstrap.dart');

      // 🔹 Run JetLeaf bootstrap code generator
      final config = RuntimeScannerConfiguration(
        skipTests: true,
        reload: true,
        packagesToScan: [...includeDirs],
        writeDeclarationsToFiles: true,
        outputPath: '$pathFolder/generated',
        packagesToExclude: [
          'collection',
          'analyzer',
          "r:.*/example/.*",
          "r:.*/test/.*",
          "r:.*/tool/.*",
          "r:.*/benchmark/.*",
          "r:.*/.dart_tool/.*",
          "r:.*/build/.*",
          ...excludeDirs
        ],
        filesToExclude: excludeDirs.filter((e) => e.isNotEmpty).map((exclude) => File(p.isAbsolute(exclude.trim()) ? exclude.trim() : p.join(project.path, exclude.trim()))).toList(),
      );
      FileUtility fileUtils = FileUtility(logger.info, logger.warn, logger.error, config, (file, uri) => true);

      await fileUtils.scanAllDependenciesForDartFiles(
        dartFiles,
        config.filesToScan.map((f) => f.path).toSet(),
        config.filesToExclude.map((f) => f.path).toSet()
      );

      final builder = ProductionProjectBuilder(compiler, outputPath, sourcePath);
      final finalArgs = args;
      finalArgs.add(Constant.JETLEAF_GENERATED_DIR_NAME);

      final result = await builder.build(this, mainEntryFile, packageName, dartFiles.toList(), fileUtils, project, finalArgs);

      print('''
🍃 JetLeaf Build Summary
────────────────────────────────────────────────────────────

📂 Package:               $packageName
📦 Output ${_getFileType(compiler)} File:     ${p.normalize(outputPath)}
🗂️ Output File Size:      ${result.getFormattedSize()}
🧪 Compiler Used:         ${compiler.name}

📊 Generation Stats:\n${_buildGenerationStats(dartFiles.toList(), excludeDirs, includeDirs, result.getMetrics())}

📁 Resources & Assets:
  • All resources and JetLeaf assets are now embedded directly into the ${_getFileType(compiler)} file.

✅ Build Completed Successfully in ${stopWatch.elapsedMilliseconds}ms

🚀 Next Steps:
  • Run the app:
      ${_getRunCommand(compiler, outputPath)}

📘 Tips:
  • Dev resources:        https://jetleaf.hapnium.com/docs

────────────────────────────────────────────────────────────
🔧 Powered by JetLeaf — the Dart backend engine 🍃
  ''');
      stopWatch.stop();
    } catch (e) {
      stopWatch.stop();
      logger.error('Error during build run: $e');
      exit(1);
    } finally {
      final buildDir = Directory(p.join(project.path, pathFolder));

      if (buildDir.existsSync()) {
        // Normalized path of the file to keep
        final keepPath = appPath != null ? p.normalize(p.join(project.path, appPath)) : null;

        // Only look at top-level items
        for (final entity in buildDir.listSync(recursive: false)) {
          final entityPath = p.normalize(entity.path);

          // Skip the file we want to keep
          if (keepPath != null && p.equals(entityPath, keepPath)) {
            continue;
          }

          try {
            entity.deleteSync(recursive: true);
          } catch (e) {
            logger.warn('Failed to delete ${entity.path}: $e');
          }
        }
      }
    }
  }

  /// Returns the appropriate command string to execute a compiled JetLeaf
  /// application, depending on the selected [CompilerType] type.
  ///
  /// This helper ensures that the correct runtime invocation is used
  /// for each compilation target:
  ///
  /// - **[CompilerType.JIT]** → Runs the app using the Dart VM JIT interpreter via  
  ///   `dart run <target>`.
  /// - **[CompilerType.AOT]** → Executes an AOT-compiled `.aot` snapshot directly  
  ///   with the Dart runtime using `dart <target>`.
  /// - **[CompilerType.EXE]** → Executes a native binary directly by returning the  
  ///   normalized file path to the executable.
  ///
  /// The returned command is a string suitable for passing to
  /// [Process.start] or logging purposes.
  ///
  /// Example:
  /// ```dart
  /// final command = _getRunCommand(Compiler.JIT, 'build/main.dill');
  /// print(command); // dart run build/main.dill
  /// ```
  ///
  /// See also:
  /// - [CompilerType], which defines the supported compilation modes.
  String _getRunCommand(CompilerType compiler, String target) {
    switch (compiler) {
      case CompilerType.JIT:
        return 'dart run ${p.normalize(target)}';
      case CompilerType.AOT:
        return 'dart ${p.normalize(target)}';
      case CompilerType.EXE:
        return p.normalize(target);
    }
  }

  /// Resolves the file extension associated with the given [compiler] mode.
  ///
  /// This is primarily used for determining output file types when generating
  /// target build paths or displaying human-readable output in logs.
  ///
  /// Example:
  /// ```dart
  /// print(getFileType(Compiler.JIT)); // .dill
  /// print(getFileType(Compiler.EXE)); // .exe
  /// ```
  ///
  /// Returns:
  ///   The file extension corresponding to the selected [CompilerType].
  ///
  /// Parameters:
  /// - [compiler]: The [CompilerType] variant (JIT, AOT, EXE).
  String _getFileType(CompilerType compiler) {
    switch (compiler) {
      case CompilerType.JIT:
        return '.dill';
      case CompilerType.AOT:
        return '.aot';
      case CompilerType.EXE:
        return '.exe';
    }
  }
}