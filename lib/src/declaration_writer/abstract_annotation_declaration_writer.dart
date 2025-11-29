import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_link_declaration_writer.dart';
import 'type_declaration_writer.dart';

abstract class AbstractAnnotationDeclarationWriter extends AbstractLinkDeclarationWriter implements TypeDeclarationWriter {
  AbstractAnnotationDeclarationWriter();

  @override
  Future<Map<String, String>> writeAnnotationDeclarations(List<AnnotationDeclaration> annotations, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "annotation_declarations");
    for (final annotation in annotations) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${annotation.getName()}");
      final outputFile = File(outputPath);

      writeGeneratedHeader(buffer, annotation.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }
}