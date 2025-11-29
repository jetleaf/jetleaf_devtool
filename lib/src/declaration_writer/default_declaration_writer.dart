import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_library_declaration_writer.dart';
import 'declaration_writer.dart';

final class DefaultDeclarationWriter extends AbstractLibraryDeclarationWriter implements DeclarationWriter {
  DefaultDeclarationWriter();

  @override
  Future<void> write(RuntimeProvider provider, File file, String folder) async {
    final StringBuffer buffer = StringBuffer();
    writeGeneratedHeader(buffer, provider.getAllPackages().find((pk) => pk.getIsRootPackage())?.getName() ?? "project");

    final libraries = await writeLibraryDeclarations(provider.getAllLibraries(), folder);

    final assetOutputPath = p.normalize("$folder/generated_assets.dart");
    final assetOutputFile = File(assetOutputPath);
    final assetImport = p.relative(assetOutputPath, from: folder);
    final assets = await writeGeneratedAssets(provider.getAllAssets(), assetOutputPath, assetOutputFile);

    final packageOutputPath = p.normalize("$folder/generated_packages.dart");
    final packageOutputFile = File(packageOutputPath);
    final packageImport = p.relative(packageOutputPath, from: folder);
    final packages = await writeGeneratedPackages(provider.getAllPackages(), packageOutputPath, packageOutputFile);

    final imports = [...libraries.keys, assetImport, packageImport];
    writeGeneratedImports(buffer, imports.toMap((c) => c, (c) => []));

    // Step 3: Write the actual RuntimeProvider

    final resolver = provider.getRuntimeResolver();

    // await _write(provider.getAllLibraries().firstOrNull.toString(), file);
    await writeGeneratedOutput(buffer.toString(), file);
  }
}

void main() async {
  final result = await runScan();
  final folder = "${Directory.current.path}/build";
  DefaultDeclarationWriter().write(result, File("$folder/test.dart"), folder);
}