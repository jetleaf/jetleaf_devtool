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

/// {@template jetleaf_development_command_runner}
/// Launches a JetLeaf application in **development mode**.
///
/// This command is responsible for:
/// - Bootstrapping the JetLeaf runtime in `dev` configuration.
/// - Optionally enabling file watchers for **hot reload**.
/// - Managing inclusion/exclusion of directories during scanning.
/// - Executing the generated bootstrap file.
///
/// ### Usage
/// ```bash
/// jl dev --entry lib/main.dart -w
/// ```
///
/// ### Options
/// | Option | Alias | Description |
/// |--------|--------|-------------|
/// | `--help` | `-h` | Show this help message. |
/// | `--entry` | `-e` | Specify the entry file for the application. |
/// | `--watch` | `-w` | Enable file watching and hot reload. |
/// | `--exclude` | `-ed` | Comma-separated list of directories/files to exclude. |
/// | `--include` | `-in` | Comma-separated list of directories/files to include. |
///
/// ### Example
/// ```bash
/// jl dev --entry=lib/main.dart --watch
/// ```
///
/// ### See Also
/// - [HotReloadCommandRunner]
/// - [DevelopmentBootstrapBuilder]
/// - [CliLogger]
/// {@endtemplate}
final class DevelopmentCommandRunner extends CommandRunner {
  /// {@macro jetleaf_development_command_runner}
  const DevelopmentCommandRunner();

  @override
  String get command => 'dev';

  @override
  String get description => 'Launch the application in development mode.';

  @override
  CliLogger get logger => cliSession.get(command.toUpperCase());

  @override
  String get usage => '''
Usage: jl $command [options]

Description:
  $description

Options:
  -h,   --help          Show this help message (Flag).
  -e,   --entry         Specify the entry file for the application.
  -w,   --watch         Watch for file changes and reload automatically (Automatic hot reload).
  -ed,  --exclude       Directories/Files to exclude from scanner.
  -in,  --include       Directories/Files to include in the scanner.
  -ni,  --no-interact   Disable interactive terminal - mostly for non-interactive terminals like docker. Provide answers via env or args.

Examples:
  jl $command --entry lib/main.dart
  jl $command --entry=lib/main.dart -w
''';

  @override
  Future<void> run(List<String> args) async {
    final stopWatch = Stopwatch()..start();
    final project = Directory.current;
    final buildFolder = 'build';

    try {
      Set<File> dartFiles = {};
      final noInteract = args.contains('--no-interact');
      File mainEntryFile = await _getEntryFile(args, logger, project, dartFiles.addAll, noInteract);
      final packageName = await _readPkgName(logger, project);

      // ------------------------------------------------------------
      // 🧩 STEP 1: Proxy generation + proxy entrypoint execution
      // ------------------------------------------------------------
      await _runBuildRunner(project, logger);
      
      // ------------------------------------------------------------
      // 🛠️ STEP 2: Development builder
      // ------------------------------------------------------------
      final entrypoint = p.join(project.path, Constant.JETLEAF_GENERATED_DIR_NAME, '${packageName}_entry.dart');

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

      final autoRebuild = bool.tryParse(_getArgValue(args, ['--watch', '-w']) ?? "false");

      // 🔹 Run JetLeaf bootstrap code generator
      final config = RuntimeScannerConfiguration(
        skipTests: true,
        reload: true,
        packagesToScan: [...includeDirs],
        writeDeclarationsToFiles: true,
        outputPath: '$buildFolder/generated',
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
      FileUtility fileUtils = FileUtility(logger.info, logger.warn, logger.error, config, true);

      await fileUtils.scanAllDependenciesForDartFiles(
        dartFiles,
        config.filesToScan.map((f) => f.path).toSet(),
        config.filesToExclude.map((f) => f.path).toSet()
      );
      
      final builder = DevelopmentProjectBuilder(File(entrypoint));
      args.add(CliConstant.DEV_FLAG);
      final result = await builder.build(this, mainEntryFile, packageName, dartFiles.toList(), fileUtils, project, args);

      print('''
🍃 JetLeaf Development Summary
────────────────────────────────────────────────────────

📂 Target File:              ${p.normalize(entrypoint)}
🧠 Entry Point Found:        ${mainEntryFile.path}
📦 Package:                  $packageName

📊 Generation Stats:\n${_buildGenerationStats(dartFiles.toList(), excludeDirs, includeDirs, result.getMetrics())}

✅ Development Status:         SUCCESS
   ✔ Bootstrap generated in ${stopWatch.elapsedMilliseconds}ms

🚀 Next:
  • Open ${p.normalize(entrypoint)} to view the generated bootstrap.
  • The application will start automatically.

────────────────────────────────────────────────────────
🔧 Powered by JetLeaf — the Dart backend engine 🍃
''');

      // ------------------------------------------------------------
      // 🚀 STEP 3: Run generated development entrypoint
      // ------------------------------------------------------------
      logger.info('🚀 Starting JetLeaf incremental development VM...');

      if (Platform.isWindows) {
        await Process.run('cls', [], runInShell: true);
      } else {
        stdout.write('\x1B[2J\x1B[0;0H');
      }

      final outputDill = p.join(project.path, buildFolder, 'snapshot.dill');
      final platformDill = p.join(
        p.dirname(p.dirname(Platform.resolvedExecutable)),
        'lib',
        '_internal',
        'vm_platform_strong.dill',
      );

      final frontend = await FrontendServerClient.start(
        'org-dartlang-root:///$entrypoint',
        outputDill,
        platformDill,
        target: 'vm',
        fileSystemRoots: [project.path],
        fileSystemScheme: 'org-dartlang-root',
        verbose: false,
      );
      frontendClient = frontend;

      logger.info('🔧 Compiling project...');
      CompileResult compilation = await frontend.compile();
      compilationResult = compilation;
      frontend.accept();

      final compiledDill = compilation.dillOutput;
      if (compiledDill != null) {
        logger.info('📦 Snapshot ready at: $compiledDill');
        logger.info('🚀 Launching VM...');

        final vmReady = Completer<VmService>();
        final vmProcess = await Process.start(
          Platform.resolvedExecutable,
          [
            '--enable-vm-service=0', // random port
            compiledDill,
          ],
          workingDirectory: project.path,
        );

        vmProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            print(line);

            if (line.contains('Observatory listening on')) {
              final wsUri = '${line.split(' ').last.replaceFirst('http', 'ws').replaceFirst('/ws', '')}ws';
              vmReady.complete(vmServiceConnectUri(wsUri));
            }
        });

        vmProcess.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(stderr.writeln);
        final vmService = await vmReady.future;
        await _watcher.watch(vmService, File(entrypoint), autoRebuild ?? false, project, logger);
        logger.info('🛰️ VM Service connected → Hot reload ready');

        final exit = await vmProcess.exitCode;
        logger.info('🏁 Application exited ($exit)');
      } else {
        logger.error('🏁 Application exited ${compilation.errorCount}');
      }
    } catch (e, st) {
      logger.error('❌ Failed to launch development mode: $e');
      logger.error(st.toString());
    } finally {
      Directory(p.join(project.path, buildFolder)).deleteSync(recursive: true);
    }
  }
}