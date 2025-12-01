import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_annotation_declaration_writer.dart';
import 'type_declaration_writer.dart';

abstract class AbstractMethodDeclarationWriter extends AbstractAnnotationDeclarationWriter implements TypeDeclarationWriter {
  AbstractMethodDeclarationWriter();

  @override
  Future<Map<String, String>> writeMethodDeclarations(List<MethodDeclaration> methods, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "method_declarations");
    for (final method in methods) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${method.getName()}");
      final outputFile = File(outputPath);

      writeGeneratedHeader(buffer, method.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }
}