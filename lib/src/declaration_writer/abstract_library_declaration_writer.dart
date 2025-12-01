import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_class_declaration_writer.dart';
import 'library_declaration_writer.dart';

abstract class AbstractLibraryDeclarationWriter extends AbstractClassDeclarationWriter implements LibraryDeclarationWriter {
  AbstractLibraryDeclarationWriter();

  @override
  Future<Map<String, String>> writeLibraryDeclarations(List<LibraryDeclaration> declarations, String folder) async {
    final importsAndInstances = <String, String>{};
    final runtimeFolder = p.normalize("$folder/_runtime_generated");
    final groupedLibraries = declarations.group((lib) => lib.getPackage());

    for (final entry in groupedLibraries.entries) {
      final pkg = entry.key;
      final packageName = pkg.getName();
      final libraries = entry.value;

      final packageFolder = p.join(folder, packageName);
      for (final library in libraries) {
        final buffer = StringBuffer();
        final libraryName = library.getName();
        final outputPath = p.normalize("$packageFolder/${_getLibraryName(libraryName, packageName)}");
        final outputFile = File(outputPath);

        writeGeneratedHeader(buffer, packageName);

        final internalFolder = outputPath.replaceAll(".dart", ""); 
        final libClass = await writeClassDeclarations(library.getClasses(), runtimeFolder, internalFolder, libraryName);
        final annotations = await writeAnnotationDeclarations(library.getAnnotations(), runtimeFolder, internalFolder, libraryName);
        final enums = await writeEnumDeclarations(library.getEnums(), runtimeFolder, internalFolder, libraryName);
        final extensions = await writeExtensionDeclarations(library.getExtensions(), runtimeFolder, internalFolder, libraryName);
        final typedefs = await writeTypedefDeclarations(library.getTypedefs(), runtimeFolder, internalFolder, libraryName);
        final sources = await writeSourceDeclarations(library.getDeclarations(), runtimeFolder, internalFolder, libraryName);
        final topLevelFields = await writeFieldDeclarations(library.getTopLevelFields(), runtimeFolder, internalFolder, libraryName);
        final topLevelMethods = await writeMethodDeclarations(library.getTopLevelMethods(), runtimeFolder, internalFolder, libraryName);
        final topLevelRecords = await writeRecordDeclarations(library.getTopLevelRecords(), runtimeFolder, internalFolder, libraryName);
        final topLevelRecordFields = await writeRecordFieldDeclarations(library.getTopLevelRecordFields(), runtimeFolder, internalFolder, libraryName);

        await writeGeneratedOutput(buffer.toString(), outputFile);
        importsAndInstances.add(p.relative(outputPath, from: folder), "");
      }
    }

    return importsAndInstances;
  }

  String _getLibraryName(String name, String packageName) {
    String library;
    if (name.startsWith("dart:")) {
      library = name.replaceAll(":", "_");
    } else {
      library = name.replaceAll("package:$packageName", "");
    }

    return library.endsWith(".dart") ? library : "$library.dart";
  }
}