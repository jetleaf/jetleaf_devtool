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

part of 'project_watcher.dart';

final class ApplicationProjectWatcher extends GenerativeSupport implements ProjectWatcher {
  late VmService _vmService;

  ApplicationProjectWatcher();

  @override
  Future<void> watch(VmService vmService, File entryPoint, bool autoRebuild, Directory project, CliLogger logger) async {
    _vmService = vmService;
    final runtime = GLOBAL_RUNTIME_PROVIDER;
    print("Current runtime - $runtime");

    // Initialize the file watcher (monitors the current project root)
    final fileWatcher = ApplicationFileWatcher();

    // Start watching and react to file events by regenerating and recompiling.
    await fileWatcher.start((FileEvent event) async {
      // For now, any relevant event triggers a full regeneration.
      final src = event.getSource();
      print('File event: ${event.runtimeType} -> ${src.path}');

      // Only act on files inside project (avoid build artifacts)
      // if (p.isWithin(Directory.current.path, p.normalize(src.path))) {
      //   await _regenerateAndReload();
      // } else {
      //   print('Event outside project root, ignoring: ${src.path}');
      // }
    });
  }

  // Helper that regenerates bootstrap sources, recompiles and triggers reload
//   Future<void> regenerateAndReload(RuntimeProvider provider, Directory project, File entryPoint, CliLogger logger) async {
//     final config = RuntimeScannerConfiguration(
//       reload: true,
//       updateAssets: true,
//       updatePackages: true,
//     );
//     final fileUtils = FileUtility(logger.info, logger.warn, logger.error, config, true);

//     try {
//       final packageName = await fileUtils.readPackageName();

//       // Discover Dart files for imports
//       final dartFiles = await fileUtils.findDartFiles(project);
//       final imports = await generateImports(entryPoint, packageName, logger, dartFiles.toList(), fileUtils);

//       // Generate packages and assets wrappers (these write files into generated dir)
//       final packageImports = await generateAndWritePackages(entryPoint.path, project, fileUtils);
//       final assetImports = await generateAndWriteAssets(entryPoint.path, packageName, fileUtils);

//       final generatedImports = {...imports, ...packageImports, ...assetImports};

//       // Build the bootstrap source
//       final buffer = StringBuffer();

//       // Header + user main import + generated imports + main function
//       writeHeader(buffer, packageName, 'bootstrap entry (hot-reload)');

//       final packageUri = fileUtils.resolveToPackageUri(p.relative(entryPoint.path), packageName, project);
//       if (packageUri != null) {
//         buffer.writeln("import '$packageUri' as ${buildEntryAlias(packageName)};");
//       } else {
//         // fallback to file import
//         buffer.writeln("import '${p.normalize(entryPoint.path)}' as ${buildEntryAlias(packageName)};");
//       }

//       writeImports(buffer, generatedImports);
// writeMainFunction(buffer, packageName, [CliConstant.DEV_FLAG]);

//       // Write to the entrypoint file
//       await writeTarget(entryPoint, buffer);

//       logger.info('Recompiled and regenerated bootstrap: ${entryPoint.path}');

//       // Try to recompile using frontend client (incremental compile)
//       final client = frontendClient;

//       if (client != null) {
//         // request incremental compile for the changed entrypoint
//         compilationResult = await client.compile([Uri.parse('org-dartlang-root:///${entryPoint.path}')]);
//         client.accept();
//         logger.info('Frontend server recompiled ${entryPoint.path}');

//         // Trigger VM reload if requested
//         if (autoRebuild) {
//           await triggerReload();
//         }
//       } else {
//         logger.warn('Frontend client not available — skipping incremental compile.');
//       }
//     } catch (e, st) {
//       logger.error('Error during regeneration: $e');
//       logger.error(st.toString());
//     }
//   }
  
  @override
  Future<void> triggerReload() async {
    final dillOutput = compilationResult?.dillOutput;
    final vm = await _vmService.getVM();
    final isolates = vm.isolates;

    if (isolates != null && isolates.isNotEmpty) {
      final firstIsolate = isolates.first;
      final isolateId = firstIsolate.id;

      if (isolateId != null && dillOutput != null) {
        await _vmService.reloadSources(isolateId, rootLibUri: dillOutput);
      }
    }
  }
}