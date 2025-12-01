import 'package:jetleaf_lang/lang.dart';

/// {@template type_declaration_writer}
/// Provides an abstraction for generating and writing various Dart **type declarations**  
/// into source files.
///
/// The [TypeDeclarationWriter] interface defines a unified contract for writing
/// different categories of declarations—classes, enums, annotations, records,
/// typedefs, extensions, fields, and methods—into a specified folder.
///
/// Each method returns a `Map<String, String>` where:
/// - **key** → the generated file path  
/// - **value** → the instance string pointing to that file  
///
/// This enables automated code generation systems to easily reference newly
/// created files without manually computing instance paths.
///
/// ### Responsibilities
/// - Generate Dart source files from typed declaration models
/// - Save generated code into the provided folder
/// - Return instance strings for integration with other codegen tasks
///
/// ### Example
/// ```dart
/// final writer = MyWriter();
/// final results = await writer.writeClassDeclarations(classes, 'lib/generated');
/// print(results.values); // instance strings
/// ```
///
/// ### See also
/// - ClassDeclaration
/// - EnumDeclaration
/// - RecordDeclaration
/// - TypedefDeclaration
/// {@endtemplate}
abstract interface class TypeDeclarationWriter {
  /// Writes annotation-type declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeAnnotationDeclarations(List<AnnotationDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes class declarations into the specified [internalFolder].
  /// 
  /// [runtimeClass] - The `RuntimeClassDeclaration` interface generated for the build. Contains the path where it is generated, with the name of the class.
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<MapEntry<String, String>> writeClassDeclarations(List<ClassDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes generic source declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeSourceDeclarations(List<SourceDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes enum declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeEnumDeclarations(List<EnumDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes extension declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeExtensionDeclarations(List<ExtensionDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes field declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeFieldDeclarations(List<FieldDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes method declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeMethodDeclarations(List<MethodDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes record declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeRecordDeclarations(List<RecordDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes record-field declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeRecordFieldDeclarations(List<RecordFieldDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes typedef declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeTypedefDeclarations(List<TypedefDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes link declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeLinkDeclarations(List<LinkDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);

  /// Writes member declarations into the specified [internalFolder].
  ///
  /// Returns a map of file paths to the corresponding instance strings.
  Future<Map<String, String>> writeMemberDeclarations(List<MemberDeclaration> declarations, String runtimeFolder, String internalFolder, String libraryName);
}