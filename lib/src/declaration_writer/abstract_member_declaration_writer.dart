import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_record_declaration_writer.dart';
import 'type_declaration_writer.dart';

abstract class AbstractMemberDeclarationWriter extends AbstractRecordDeclarationWriter implements TypeDeclarationWriter {
  AbstractMemberDeclarationWriter();

  @override
  Future<Map<String, String>> writeMemberDeclarations(List<MemberDeclaration> members, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "member_declarations");
    for (final member in members) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${member.getName()}");
      final outputFile = File(outputPath);

      writeGeneratedHeader(buffer, member.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }
}