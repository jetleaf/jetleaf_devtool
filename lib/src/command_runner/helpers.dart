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

/// Retrieves the current version of the JetLeaf CLI.
///
/// This method attempts to determine the CLI version from multiple sources,
/// following a prioritized lookup order:
///
/// 1. **Local `pubspec.yaml`** – If present in the current working directory,
///    reads the version from the `version:` field.
/// 2. **`.dart_tool/package_config.json`** – Scans the package configuration
///    to locate the `jetleaf_cli` package (useful when the CLI is activated
///    globally or as a dependency), and reads its version from its
///    `pubspec.yaml`.
/// 3. **Environment variable fallback** – Returns the value from the
///    `JETLEAF_CLI_VERSION` compile-time environment variable if available,
///    or `"unknown"` if not found.
///
/// Returns:
///   A [Future] that completes with the resolved version string of JetLeaf CLI.
///
/// Example:
/// ```dart
/// final version = await getCliVersion();
/// print('JetLeaf CLI version: $version');
/// ```
///
/// This function never throws; if any lookup fails, it safely falls back to
/// `"unknown"`.
Future<String> getRunningVersion() async {
  // 1️⃣ Try local pubspec.yaml (if running from source)
  final localPubspec = File('pubspec.yaml');
  if (await localPubspec.exists()) {
    final version = _extractVersion(await localPubspec.readAsString());
    if (version != null) return version;
  }

  // 2️⃣ Try global pub cache (e.g., ~/.pub-cache or %APPDATA%\Pub\Cache)
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  final pubCacheDir = Platform.isWindows
      ? Directory('$home/AppData/Roaming/Pub/Cache')
      : Directory('$home/.pub-cache');

  if (await pubCacheDir.exists()) {
    final parser = YamlParser();
    final jetleafDirs = pubCacheDir
        .listSync(recursive: true)
        .whereType<Directory>()
        .where((d) => d.path.contains('jetleaf'));

    for (final dir in jetleafDirs) {
      final pubspec = File('${dir.path}/pubspec.yaml');
      if (await pubspec.exists()) {
        final asset = AssetResource(await pubspec.readAsString());
        final parsed = parser.parseAsset(asset);
        if (parsed['name'] == 'jetleaf') {
          final version = _extractVersion(await pubspec.readAsString());
          if (version != null) return version;
        }
      }
    }
  }

  // 3️⃣ Try to resolve via package_config (if CLI is invoked via `dart run`)
  final configFile = File('.dart_tool/package_config.json');
  if (await configFile.exists()) {
    final config = jsonDecode(await configFile.readAsString());
    if (config is Map && config['packages'] is List) {
      for (final pkg in config['packages']) {
        if (pkg is Map && pkg['name'] == 'jetleaf') {
          final pkgPath = pkg['rootUri'];
          final pubspec = File('$pkgPath/pubspec.yaml');
          if (await pubspec.exists()) {
            final version = _extractVersion(await pubspec.readAsString());
            if (version != null) return version;
          }
        }
      }
    }
  }

  // 4️⃣ Fallback to environment-defined version or unknown
  return const String.fromEnvironment('JETLEAF_VERSION', defaultValue: 'unknown');
}

String? _extractVersion(String content) {
  // Matches versions like:
  // 1.0.0
  // 1.0.0+2
  // 1.0.0-beta
  // 1.0.0-beta+2
  final match = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+(?:[-+][^\s]+)?)\s*$',
    multiLine: true,
  ).firstMatch(content);

  return match?.group(1)?.trim();
}

/// Resolves the application's main entry file from the provided [args].
///
/// This helper determines which Dart file should serve as the application's
/// bootstrap entry point. It follows these steps:
///
/// 1. Attempts to extract the `--entry` (`-e`) argument from [args].
/// 2. If no entry file is provided, prompts the user interactively
///    to specify one via the CLI.
/// 3. If the user input is empty, automatically searches the project
///    for a Dart file containing both:
///    - A `void` or `Future<void>` `main(List<String> args)` method, and  
///    - A call to `JetApplication.run(...)`.
///
/// Returns the resolved [File] reference pointing to the main entry file.
///
/// Throws:
/// - [Exception] if no valid entry file can be found in the project.
///
/// Example:
/// ```dart
/// final entryFile = await _getEntryFile(args, logger, Directory.current);
/// print('Resolved entry: ${entryFile.path}');
/// ```
Future<File> _getEntryFile(List<String> args, CliLogger logger, Directory project, [OnFilesLoaded? onFound, bool noInteract = false]) async {
  String? entry = _getArgValue(args, ['-e', '--entry']);

  // 🔹 Prompt for entry file if missing
  if (noInteract) {
    entry ??= _getValue(entry, Platform.environment['JL_ENTRY'], '');
  } else {
    entry ??= prompt.get('Enter the entry file path', defaultsTo: '');
  }

  File mainEntryFile;

  if(entry.isEmpty) {
    mainEntryFile = await _findMainEntryFile(logger, project, onFound);
  } else {
    mainEntryFile = File(p.join(project.path, entry));
  }

  return mainEntryFile;
}

/// Retrieves the value of a command-line argument from [args] matching any of the provided [keys].
///
/// This utility searches through the argument list for a key that matches one of the
/// given [keys] (e.g., `--entry`, `-e`) and returns its corresponding value.
/// It supports both assignment and positional styles:
///
/// - `--entry=lib/main.dart`  → returns `lib/main.dart`
/// - `--entry lib/main.dart`  → returns `lib/main.dart`
///
/// If none of the keys are found, `null` is returned.
///
/// Example:
/// ```dart
/// final entry = _getArgValue(['--entry', 'lib/main.dart'], ['-e', '--entry']);
/// print(entry); // lib/main.dart
/// ```
///
/// Returns:
/// - A [String] value if a matching argument is found.
/// - `null` if no matching argument or value exists.
String? _getArgValue(List<String> args, List<String> keys) {
  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if (keys.any((k) => arg.startsWith('$k='))) {
      return arg.split('=')[1];
    } else if (keys.contains(arg) && i + 1 < args.length) {
      return args[i + 1];
    }
  }

  return null;
}

/// Returns the first non-empty value from the provided sources, falling back to a default.
///
/// This utility is used to support both interactive and non-interactive modes in the
/// JetLeaf build command, allowing values to be supplied via:
/// 1. Command-line arguments (`argValue`)
/// 2. Environment variables (`envVar`)
/// 3. A default value (`defaultValue`)
///
/// The precedence is:
/// 1. `argValue` (highest priority)
/// 2. `envVar`
/// 3. `defaultValue` (lowest priority)
///
/// Example usage:
/// ```dart
/// final pathFolder = _getValue(cliArg, Platform.environment['JL_BUILD_PATH'], 'build/');
/// ```
/// In non-interactive mode, this ensures that the build can proceed without prompts.
String _getValue(String? argValue, String? envVar, String defaultValue) {
  if (argValue != null && argValue.isNotEmpty) return argValue;
  if (envVar != null && envVar.isNotEmpty) return envVar;
  return defaultValue;
}

/// Locates the primary Dart entry file containing `void main(...)` and a call
/// to `JetApplication.run(...)`, used as the bootstrap entry point.
///
/// This method recursively scans all Dart files in the current working
/// directory, searching for files that:
/// - Define a `main` function (either `void main` or `Future<void> main`)
/// - Contain a call to `JetApplication.run(...)`
///
/// If exactly one matching file is found, it is returned as the main entry file.
/// If multiple candidates are found, a warning is logged and an [Exception]
/// is thrown to prevent ambiguity.
/// If no candidates are found, an [Exception] is thrown to indicate that
/// no valid entry point was detected.
///
/// The method also displays a spinner during the search process for improved
/// CLI feedback and allows optional inspection of all scanned files via [onFound].
///
/// Example:
/// ```dart
/// final entryFile = await _findMainEntryFile(logger, (files) {
///   print('Scanned ${files.length} Dart files.');
/// });
/// print('Main entry: ${entryFile.path}');
/// ```
///
/// Parameters:
/// - [logger]: A [CliLogger] used to print warnings and status updates.
/// - [onFound]: An optional callback that receives the list of all Dart files
///   discovered during the scan.
///
/// Throws:
/// - [Exception] if multiple or no main entry files are found.
///
/// Returns:
/// - A [File] representing the detected main entry point.
Future<File> _findMainEntryFile(CliLogger logger, Directory project, [OnFilesLoaded? onFound]) async {
  final spinner = Spinner('🔍 Searching for void main(...) and JetApplication.run(...)/JetApplication for bootstrap entry... in ${Directory.current}');
  spinner.start();

  final allDartFiles = await _findDartFiles(project);

  if (onFound != null) {
    onFound(allDartFiles);
  }

  final mainCandidates = <File>[];
  for (final file in allDartFiles) {
    final content = await file.readAsString();
    if (_countMainFunctions(content) == 1 && _containsJetApplicationRun(content) && p.isWithin(p.join(project.path, Constant.LIB), file.path)) {
      mainCandidates.add(file);
    }
  }

  if (mainCandidates.isEmpty) {
    logger.error('No file calling void main(...) with JetApplication.run(...) was found to bootstrap. Make sure the main method has (List<String> args), atleast');
    exit(1);
  } else if (mainCandidates.length > 1) {
    logger.warn('⚠️  Multiple entry files found with void main(...) and JetApplication.run:');
    for (var i = 0; i < mainCandidates.length; i++) {
      logger.warn('  [${i + 1}] ${mainCandidates[i].path}');
    }
    logger.error('Multiple entry files found. Cannot determine single entry for bootstrap. Please ensure only one main function with JetApplication.run exists in your source code.');
    exit(1);
  }

  spinner.stop(successMessage: '✅ Found main entry point: ${mainCandidates.first.path}');

  return mainCandidates.first;
}

/// Recursively finds all `.dart` files in the specified [directory].
///
/// This scans the entire directory tree (non-symlink) and returns
/// a list of all files ending in `.dart`.
///
/// Example:
/// ```dart
/// final files = await FileUtils.findDartFiles(Directory.current);
/// print('Found ${files.length} Dart files');
/// ```
Future<List<File>> _findDartFiles(Directory directory) async {
  final result = <File>[];
  if (!directory.existsSync()) return result;

  await for (final entity in directory.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      result.add(entity);
    }
  }
  
  return result;
}

/// Counts the number of top-level `main()` functions in [content].
///
/// This is helpful for detecting potential entry points in a Dart source file.
///
/// Example:
/// ```dart
/// int count = FileUtils.countMainFunctions(File('main.dart').readAsStringSync());
/// ```
int _countMainFunctions(String content) {
  final mainRegex = RegExp(
    r'(?:void|Future\s*<\s*void\s*>)\s+main\s*\(\s*([^\)]*)\s*\)\s*(?:async\s*)?\{',
    multiLine: true,
    dotAll: true,
  );
  return mainRegex.allMatches(content).length;
}

/// Checks whether the Dart source [content] calls `JetApplication.run()`.
///
/// This can be used to identify the main bootstrapping class in a JetLeaf project.
///
/// Example:
/// ```dart
/// bool hasRun = FileUtils.containsJetApplicationRun(File('main.dart').readAsStringSync());
/// ```
bool _containsJetApplicationRun(String content) {
  return content.contains('JetApplication.run(') || content.contains('JetApplication');
}

/// Reads the package name from `pubspec.yaml`.
/// Throws an exception if the package name cannot be determined.
Future<String> _readPkgName(CliLogger logger, Directory project) async {
  final spinner = Spinner('Reading package name...');
  spinner.start();

  final packageName = await _readPackageName(project);
  if (packageName == null) {
    throw Exception('Could not determine package name from pubspec.yaml. Ensure pubspec.yaml exists in the current directory.');
  }
  spinner.stop(successMessage: 'Detected package name: $packageName');

  return packageName;
}

/// Reads the package name from pubspec.yaml.
Future<String?> _readPackageName(Directory projectRoot) async {
  final pubspecFile = File(p.join(projectRoot.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    return null;
  }
  final lines = await pubspecFile.readAsLines();
  for (final line in lines) {
    if (line.startsWith('name:')) {
      return line.substring('name:'.length).trim();
    }
  }
  return null;
}

/// Wraps text while preserving indentation and newlines.
/// This respects the start-of-line spaces for formatted usage blocks.
List<String> _preserveWrap(String line, int width) {
  // Keep original indentation
  final indentMatch = RegExp(r'^(\s*)').firstMatch(line);
  final indent = indentMatch?.group(1) ?? '';
  final text = line.trimRight();

  // If it already fits, no need to wrap
  if (text.length + indent.length <= width) return [line];

  final result = <String>[];
  var current = StringBuffer(indent);
  final words = text.split(' '); // split only by single space, not all whitespace

  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    // Add a space before each word except the first
    final nextWord = (i == 0 ? '' : ' ') + word;

    if (current.length + nextWord.length > width) {
      result.add(current.toString());
      current = StringBuffer(indent)..write(word);
    } else {
      current.write(nextWord);
    }
  }

  if (current.isNotEmpty) result.add(current.toString());
  return result;
}

/// Executes a Dart `build_runner` process within the specified [project] directory.
///
/// This internal utility method is responsible for coordinating proxy and code
/// generation tasks required by JetLeaf’s **runtime scanner**, **proxy system**,
/// or **compile-time dependency metadata** workflows. It provides a robust,
/// signal-aware interface for executing and monitoring Dart build processes.
///
/// ### Overview
/// JetLeaf’s proxy generation pipeline relies on Dart’s [`build_runner`](https://pub.dev/packages/build_runner)
/// to transform annotated classes, compile runtime metadata, and produce
/// generated source artifacts (typically under `_jetleaf/` or `.dart_tool/`).
/// This helper encapsulates that process, ensuring safe execution, error
/// handling, and user interruption forwarding.
///
/// ### Features
/// - **Supports both one-shot and watch modes:**  
///   When [watch] is `true`, it invokes `dart run build_runner watch`, enabling
///   continuous rebuilds as files change. Otherwise, it runs a one-time build.
/// - **Safe output handling:**  
///   Automatically passes `--delete-conflicting-outputs` to clean stale
///   generated files unless disabled.
/// - **Signal forwarding:**  
///   Propagates `SIGINT` and `SIGTERM` signals to the spawned process so that
///   user interruptions (e.g., `Ctrl + C`) cleanly stop `build_runner`.
/// - **Timeout support:**  
///   Optional [timeout] enforces an upper bound on the build duration,
///   preventing hanging builds in CI/CD pipelines or corrupted states.
///
/// ### Parameters
/// - [project]: The working directory where the `build_runner` process will be executed.
/// - [logger]: The [CliLogger] instance responsible for structured build output.
/// - [deleteConflictingOutputs]: If `true` (default), passes
///   `--delete-conflicting-outputs` to prevent build cache conflicts.
/// - [watch]: If `true`, runs `build_runner` in watch mode for continuous builds.
/// - [timeout]: Optional [Duration] that limits the maximum allowed build time.
///
/// ### Behavior
/// 1. Spawns a child Dart process using [Process.start].
/// 2. Streams build output directly to the console (`inheritStdio`).
/// 3. Subscribes to system termination signals to ensure graceful shutdown.
/// 4. Waits for the process to exit and validates its exit code.
/// 5. Throws [StateError] if the process exits with a non-zero code or times out.
///
/// ### Example
/// ```dart
/// await _runBuildRunner(
///   Directory.current,
///   cliSession.get('BUILD'),
///   deleteConflictingOutputs: true,
///   watch: false,
///   timeout: Duration(minutes: 5),
/// );
/// ```
///
/// ### Error Handling
/// - Throws [StateError] if the build process fails or exits abnormally.
/// - Throws [StateError] on timeout if [timeout] is provided and exceeded.
///
/// ### See Also
/// - [Process.start] — Dart’s standard API for spawning subprocesses.
/// - [CliLogger] — JetLeaf’s structured logger for CLI command execution.
/// - [DevBootstrapBuilder] and [ProductionBootstrapBuilder] — classes that
///   use `_runBuildRunner` as part of the proxy generation workflow.
/// - [ApplicationRuntimeScanner] — orchestrates build-triggered scanning
///   and metadata emission during runtime analysis.
///
/// {@macro build_runner_executor}
Future<void> _runBuildRunner(Directory project, CliLogger logger, {
  bool deleteConflictingOutputs = true,
  bool watch = false,
  Duration? timeout,
}) async {
  final args = <String>['run', 'build_runner', watch ? 'watch' : 'build'];
  if (deleteConflictingOutputs && !watch) {
    args.add('--delete-conflicting-outputs');
  }

  logger.info('🔨 Running `dart ${args.join(' ')}` in ${project.path}');

  final proc = await Process.start(
    'dart',
    args,
    workingDirectory: project.path,
    mode: ProcessStartMode.inheritStdio,
  );

  // Forward signals to child so user Ctrl+C works as expected
  final sigintSub = ProcessSignal.sigint.watch().listen((_) => proc.kill());
  final sigtermSub = ProcessSignal.sigterm.watch().listen((_) => proc.kill());

  // Optionally support a timeout
  final exitCodeFuture = proc.exitCode;
  int exitCode;
  if (timeout != null) {
    exitCode = await exitCodeFuture.timeout(timeout, onTimeout: () {
      proc.kill();
      throw StateError('Proxy generation timed out after $timeout');
    });
  } else {
    exitCode = await exitCodeFuture;
  }

  await sigintSub.cancel();
  await sigtermSub.cancel();

  logger.info('✅ Proxy generation finished completed (exit $exitCode)');
}

String _buildGenerationStats(List<File> dartFiles, List<String> excludeDirs, List<String> includeDirs, Map<String, String> metrics) {
  final finalMetrics = {
    'Dart Files Scanned': dartFiles.length.toString(),

    if (excludeDirs.isNotEmpty) ...{
      'Excluded Directories': excludeDirs.join(', '),
    },

    if (includeDirs.isNotEmpty) ...{
      'Included Directories': includeDirs.join(', '),
    },
    
    ...metrics
  };

  if (finalMetrics.isEmpty) return '';

  final maxKeyLength = finalMetrics.keys.fold<int>(
    0,
    (max, key) => key.length > max ? key.length : max,
  );

  final buffer = StringBuffer();

  for (final entry in finalMetrics.entries) {
    final key = entry.key.padRight(maxKeyLength);
    buffer.writeln('  • $key   ${entry.value}');
  }

  return buffer.toString();
}