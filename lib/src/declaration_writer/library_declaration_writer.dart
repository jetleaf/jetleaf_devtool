import 'package:jetleaf_lang/lang.dart';


/// {@template library_declaration_writer}
/// A serialization interface responsible for converting a collection of
/// [`LibraryDeclaration`] objects into one or more textual outputs.
///
/// A `LibraryDeclarationWriter` defines **how JetLeaf library declarations
/// should be represented when written out of the runtime model**.  
/// Implementations may choose any target format, such as:
///
/// - Dart source files
/// - JSON/YAML metadata
/// - Human-readable reports
/// - Minified or tool-specific serialized structures
///
/// The writer does **not** decide where the output is stored; it only produces
/// a mapping of filenames (or logical identifiers) to their serialized content.
/// The receiver of this data determines how and where the resulting files are
/// persisted.
///
/// Writers are expected to:
/// - Respect declaration ordering when relevant.
/// - Preserve semantic relationships required by downstream tooling.
/// - Produce deterministic output given identical declarations.
/// - Avoid mutating the input list.
/// {@endtemplate}
abstract interface class LibraryDeclarationWriter {
  /// Writes the provided list of [`LibraryDeclaration`] objects and returns
  /// a mapping of output targets to serialized content.
  ///
  /// The returned `Map<String, String>` is interpreted as:
  /// - **key** → name or logical identifier of the output (e.g., filename)
  /// - **value** → textual representation produced by the writer
  ///
  /// Implementations may generate:
  /// - multiple files (e.g., one file per library)
  /// - a single aggregate file (e.g., combined metadata)
  ///
  /// Requirements:
  /// - The method must not modify the input declarations.
  /// - Serialization must be complete before the returned `Future` completes.
  /// - Keys must be unique and stable for identical inputs.
  ///
  /// Throws:
  /// - Implementations may throw writer-specific exceptions if
  ///   serialization fails, but are encouraged to fail atomically.
  Future<Map<String, String>> writeLibraryDeclarations(List<LibraryDeclaration> declarations, String folder);
}