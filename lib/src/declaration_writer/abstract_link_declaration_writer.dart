import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'type_declaration_writer.dart';

abstract class AbstractLinkDeclarationWriter implements TypeDeclarationWriter {
  AbstractLinkDeclarationWriter();

  @override
  Future<Map<String, String>> writeLinkDeclarations(List<LinkDeclaration> links, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "link_declarations");
    for (final link in links) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${link.getName()}");
      final outputFile = File(outputPath);

      writeGeneratedHeader(buffer, link.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }
}