import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_typedef_declaration_writer.dart';
import 'type_declaration_writer.dart';

abstract class AbstractRecordDeclarationWriter extends AbstractTypedefDeclarationWriter implements TypeDeclarationWriter {
  AbstractRecordDeclarationWriter();

  @override
  Future<Map<String, String>> writeRecordDeclarations(List<RecordDeclaration> records, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "record_declarations");
    for (final record in records) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${record.getName()}");
      final outputFile = File(outputPath);

      writeGeneratedHeader(buffer, record.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }

  @override
  Future<Map<String, String>> writeRecordFieldDeclarations(List<RecordFieldDeclaration> recordFields, String runtimeFolder, String internalFolder, String libraryName) async {
    final importsAndInstances = <String, String>{};

    final packageFolder = p.join(internalFolder, "record_field_declarations");
    for (final recordField in recordFields) {
      final buffer = StringBuffer();
      final outputPath = p.normalize("$packageFolder/${recordField.getName()}");
      final outputFile = File(outputPath);
      print("Out - $outputPath - ${recordField.getName()} - $outputFile");

      writeGeneratedHeader(buffer, recordField.getType());

      // await writeGeneratedOutput(buffer.toString(), outputFile);
      importsAndInstances.add(p.relative(outputPath, from: internalFolder), "");
    }
    return importsAndInstances;
  }
}