import 'dart:io';

import 'package:jetleaf_lang/lang.dart';

import 'library_declaration_writer.dart';
import 'type_declaration_writer.dart';

/// {@template declaration_writer}
/// A strategy interface responsible for transforming runtime declarations
/// produced by a [`RuntimeProvider`] and writing them into a concrete output
/// file.
///
/// This interface represents the final stage of the JetLeaf declaration
/// extraction pipeline. Implementations determine **how declarations are
/// serialized and where they are persisted**.
///
/// Typical use cases include:
/// - Emitting JSON or YAML metadata files.
/// - Producing Dart source files for generated code.
/// - Writing symbol tables or dependency graphs.
/// - Persisting analysis results for tooling.
///
/// Implementations must ensure that their output is fully written, stable,
/// and free from partial corruption whenever possible.
///
/// {@endtemplate}
abstract interface class DeclarationWriter implements LibraryDeclarationWriter, TypeDeclarationWriter {
  /// Writes all declarations provided by the given [`RuntimeProvider`] into the
  /// specified output file.
  ///
  /// Implementations are responsible for:
  /// - Reading every declaration from the `provider`.
  /// - Serializing or transforming those declarations into the chosen format.
  /// - Ensuring the `output` file is created or overwritten safely.
  /// - Performing the entire write operation before the returned `Future`
  ///   completes.
  ///
  /// This method **must not** mutate the provider in any way. It must be
  /// deterministic with respect to the data supplied.
  Future<void> write(RuntimeProvider provider, File file, String folder);
}