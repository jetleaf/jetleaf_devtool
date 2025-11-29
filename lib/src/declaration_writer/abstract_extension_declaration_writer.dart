import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_enum_declaration_writer.dart';
import 'type_declaration_writer.dart';

abstract class AbstractExtensionDeclarationWriter extends AbstractEnumDeclarationWriter implements TypeDeclarationWriter {
  AbstractExtensionDeclarationWriter();

  @override
  Future<Map<String, String>> writeExtensionDeclarations(List<ExtensionDeclaration> extensions, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "typedef_declarations");
    for (final extension in extensions) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${extension.getName()}");
      final outputFile = File(outputPath);

      writeGeneratedHeader(buffer, extension.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }
}