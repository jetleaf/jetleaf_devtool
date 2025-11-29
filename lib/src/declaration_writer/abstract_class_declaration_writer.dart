import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'abstract_extension_declaration_writer.dart';
import 'type_declaration_writer.dart';

abstract class AbstractClassDeclarationWriter extends AbstractExtensionDeclarationWriter implements TypeDeclarationWriter {
  MapEntry<String, String>? _generatedRuntimeClass;

  AbstractClassDeclarationWriter();

  @override
  Future<MapEntry<String, String>> writeClassDeclarations(List<ClassDeclaration> classes, String runtimeFolder, String internalFolder, String libraryName) async {
    final runtimeClass = await _generateRuntimeClass(runtimeFolder);
    final outputPath = p.normalize("$internalFolder/class_declarations.dart");
    final outputFile = File(outputPath);
    final buffer = StringBuffer();

    writeGeneratedHeader(buffer, libraryName);

    final runtimeClassImport = p.relative(runtimeClass.key, from: internalFolder);
    final langImport = "package:jetleaf_lang/lang.dart";
    final generatedImports = <String>{
      runtimeClassImport,
      ...classes.map((cls) => cls.getPackageUri()),
      langImport
    };
    writeGeneratedImports(buffer, generatedImports.toMap((c) => c, (c) => []));

    final className = "${internalFolder.split(p.separator).last}ClassDeclaration";
    final aliasMap = <String, String>{};
    String getOrCreateAlias(String key) => aliasMap[key] ?? aliasMap.putIfAbsent(key, () => buildImportAlias(key));

    buffer.writeln('final class $className implements ${getOrCreateAlias(runtimeClassImport)}.${runtimeClass.value} {');
    buffer.writeln('  @override');
    buffer.writeln('  List<${getOrCreateAlias(langImport)}.ClassDeclaration> getClasses() => [');
    buffer.writeln('  ];');
    buffer.writeln('}');

    await writeGeneratedOutput(buffer.toString(), outputFile);
    return MapEntry(p.relative(outputPath, from: internalFolder), "$className().getClasses();");
  }

  Future<MapEntry<String, String>> _generateRuntimeClass(String folder) async {
    if (_generatedRuntimeClass != null) {
      return _generatedRuntimeClass!;
    }
  
    final className = "RuntimeClassDeclaration";
    final outputPath = p.normalize("$folder/${className.snakeCase()}.dart");
    final outputFile = File(outputPath);
    final buffer = StringBuffer();

    buffer.writeln('''
import 'package:jetleaf_lang/lang.dart' show ClassDeclaration;

/// {@template ${className.snakeCase()}}
/// Represents a contract for accessing **runtime-generated or dynamically
/// discovered class declarations**.
///
/// Implementations of [$className] expose a collection of
/// [ClassDeclaration] instances that can be used by code generators,
/// compilers, or reflection-based systems to produce Dart source code or
/// perform structural analysis at runtime.
///
/// ### Responsibilities
/// - Provide access to a list of class declarations available at runtime
/// - Serve as a data source for higher-level generation or analysis tools
///
/// ### Example
/// ```dart
/// final runtime = MyRuntimeDeclarationProvider();
/// final classes = runtime.getClasses();
/// ```
///
/// ### See also
/// - [ClassDeclaration]
/// {@endtemplate}
abstract interface class $className {
  /// Returns all available [ClassDeclaration] instances exposed by this runtime provider.
  List<ClassDeclaration> getClasses();
}
''');

    await writeGeneratedOutput(buffer.toString(), outputFile);

    return _generatedRuntimeClass = MapEntry(outputPath, className);
  }
}