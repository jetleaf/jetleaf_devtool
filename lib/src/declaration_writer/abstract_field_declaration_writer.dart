import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_method_declaration_writer.dart';
import 'type_declaration_writer.dart';

abstract class AbstractFieldDeclarationWriter extends AbstractMethodDeclarationWriter implements TypeDeclarationWriter {
  AbstractFieldDeclarationWriter();

  @override
  Future<Map<String, String>> writeFieldDeclarations(List<FieldDeclaration> fields, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "field_declarations");
    for (final field in fields) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${field.getName()}");
      final outputFile = File(outputPath);

      writeGeneratedHeader(buffer, field.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }
}