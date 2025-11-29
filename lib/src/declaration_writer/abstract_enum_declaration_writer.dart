import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_member_declaration_writer.dart';
import 'type_declaration_writer.dart';

abstract class AbstractEnumDeclarationWriter extends AbstractMemberDeclarationWriter implements TypeDeclarationWriter {
  AbstractEnumDeclarationWriter();

  @override
  Future<Map<String, String>> writeEnumDeclarations(List<EnumDeclaration> enums, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "enum_declarations");
    for (final item in enums) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${item.getName()}");
      final outputFile = File(outputPath);

      writeGeneratedHeader(buffer, item.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }
}