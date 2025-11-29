import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_source_declaration_writer.dart';
import 'type_declaration_writer.dart';

abstract class AbstractTypedefDeclarationWriter extends AbstractSourceDeclarationWriter implements TypeDeclarationWriter {
  AbstractTypedefDeclarationWriter();

  @override
  Future<Map<String, String>> writeTypedefDeclarations(List<TypedefDeclaration> typedefs, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "typedef_declarations");
    for (final typedef in typedefs) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${typedef.getName()}");
      final outputFile = File(outputPath);

      writeGeneratedHeader(buffer, typedef.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }
}