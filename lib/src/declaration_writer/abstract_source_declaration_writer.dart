import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_field_declaration_writer.dart';
import 'type_declaration_writer.dart';

abstract class AbstractSourceDeclarationWriter extends AbstractFieldDeclarationWriter implements TypeDeclarationWriter {
  AbstractSourceDeclarationWriter();

  @override
  Future<Map<String, String>> writeSourceDeclarations(List<SourceDeclaration> sources, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "source_declarations");
    for (final source in sources) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${source.getName()}");
      final outputFile = File(outputPath);

      writeGeneratedHeader(buffer, source.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }
}