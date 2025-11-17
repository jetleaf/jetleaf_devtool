// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

part of 'file_watcher.dart';

/// {@template file_event}
/// Represents a **generic file system event** within the JetLeaf ecosystem.
///
/// A [FileEvent] is an abstract representation of any change or operation
/// associated with a [File], such as creation, modification, deletion, or
/// custom user-defined triggers. This class provides a **uniform interface**
/// for handling file-related events, allowing listeners and event-driven
/// components to react consistently across different types of file operations.
///
/// The primary purpose of this abstraction is to decouple file monitoring
/// logic from event handling. By extending [FileEvent], concrete subclasses
/// can provide additional metadata or behavior specific to the type of file
/// operation.
///
/// ### Key Features
/// - Encapsulates the affected [File].
/// - Provides a consistent API for retrieving the source file via [getSource].
/// - Can be extended to support more specific file events such as creation,
///   modification, or deletion.
/// - Enables integration with event listeners, watchers, or pipeline systems.
///
/// ### Example Usage
/// ```dart
/// class FileCreatedEvent extends FileEvent {
///   const FileCreatedEvent(File file) : super(file);
/// }
///
/// void onFileEvent(FileEvent event) {
///   final file = event.getSource();
///   print('File event triggered for: ${file.path}');
/// }
///
/// final myFile = File('example.txt');
/// final event = FileCreatedEvent(myFile);
/// onFileEvent(event);
/// ```
///
/// ### Extending FileEvent
/// Subclasses can add additional properties or methods to provide
/// context-specific information, for example:
/// - `timestamp`: when the event occurred
/// - `oldContent` / `newContent`: for modification events
/// - `isDirectory`: whether the affected file is a directory
///
/// This allows event listeners to react intelligently without needing
/// to directly query the file system for context.
///
/// ### Integration
/// Typically used in combination with:
/// - [FileWatcher] to observe filesystem changes
/// - Event-driven pipelines that process files automatically
/// - Hot reload or deployment systems that react to file modifications
/// {@endtemplate}
abstract interface class FileEvent {
  /// The [File] associated with this event.
  ///
  /// This is the file that was affected by the operation.
  /// Subclasses can provide more specialized information about
  /// the type of event (e.g., creation, modification, deletion).
  final File _file;

  /// Creates a new [FileEvent] for the given [file].
  ///
  /// Typically called by subclasses representing specific file operations.
  /// 
  /// {@macro file_event}
  const FileEvent(this._file);

  /// Returns the source file that triggered this event.
  ///
  /// Handlers and listeners can use this file to perform operations such as:
  /// - Reading or writing content
  /// - Logging changes
  /// - Triggering downstream processes
  File getSource() => _file;
}

/// {@template created_file_event}
/// Represents a **file creation event** within the JetLeaf ecosystem.
///
/// A [CreatedFileEvent] is triggered whenever a new file is created in the
/// monitored filesystem or project context. It extends [FileEvent] to
/// provide a specific semantic for file creation operations.
///
/// ### Key Features
/// - Encapsulates the newly created [File].
/// - Can be used by listeners or pipelines to react immediately to new files.
/// - Enables integration with logging, hot reload, or deployment systems.
///
/// ### Example Usage
/// ```dart
/// void onFileCreated(CreatedFileEvent event) {
///   final file = event.getSource();
///   print('New file created: ${file.path}');
/// }
///
/// final newFile = File('example.txt');
/// final event = CreatedFileEvent(newFile);
/// onFileCreated(event);
/// ```
///
/// ### Integration
/// Typically used with:
/// - [FileWatcher] to observe new files in directories
/// - Event-driven pipelines to process new files automatically
/// - Hot reload systems to react to newly added source files
/// {@endtemplate}
final class CreatedFileEvent extends FileEvent {
  /// Creates a new [CreatedFileEvent] for the given [file].
  ///
  /// This is typically called by a file watcher or monitoring system when
  /// a new file is detected.
  /// 
  /// {@macro created_file_event}
  const CreatedFileEvent(super._file);
}

/// {@template deleted_file_event}
/// Represents a **file deletion event** within the JetLeaf ecosystem.
///
/// A [DeletedFileEvent] is triggered whenever a file is removed from the
/// monitored filesystem or project context. It extends [FileEvent] to
/// provide a semantic for deletion operations.
///
/// ### Key Features
/// - Encapsulates the deleted [File].
/// - Can be used by listeners or pipelines to react immediately to removed files.
/// - Enables integration with logging, cleanup routines, or deployment systems.
///
/// ### Example Usage
/// ```dart
/// void onFileDeleted(DeletedFileEvent event) {
///   final file = event.getSource();
///   print('File deleted: ${file.path}');
/// }
///
/// final fileToDelete = File('example.txt');
/// final event = DeletedFileEvent(fileToDelete);
/// onFileDeleted(event);
/// ```
///
/// ### Integration
/// Typically used with:
/// - [FileWatcher] to observe deleted files in directories
/// - Event-driven pipelines to remove resources automatically
/// - Cleanup or hot reload systems to react to file removal
/// {@endtemplate}
final class DeletedFileEvent extends FileEvent {
  /// Creates a new [DeletedFileEvent] for the given [file].
  ///
  /// This is typically called by a file watcher or monitoring system when
  /// a file is deleted.
  /// 
  /// {@macro deleted_file_event}
  const DeletedFileEvent(super._file);
}

/// {@template modified_file_event}
/// Represents a **file modification event** within the JetLeaf ecosystem.
///
/// A [ModifiedFileEvent] is triggered whenever a file is updated or changed
/// in the monitored filesystem or project context. It extends [FileEvent]
/// to provide a semantic specifically for modifications.
///
/// ### Key Features
/// - Encapsulates the modified [File].
/// - Can be used by listeners or pipelines to react immediately to file changes.
/// - Enables integration with logging, hot reload, or build systems.
///
/// ### Example Usage
/// ```dart
/// void onFileModified(ModifiedFileEvent event) {
///   final file = event.getSource();
///   print('File modified: ${file.path}');
/// }
///
/// final fileToModify = File('example.txt');
/// final event = ModifiedFileEvent(fileToModify);
/// onFileModified(event);
/// ```
///
/// ### Integration
/// Typically used with:
/// - [FileWatcher] to observe file changes in directories
/// - Hot reload or live reload systems for development efficiency
/// - Event-driven pipelines that process updated files automatically
/// {@endtemplate}
final class ModifiedFileEvent extends FileEvent {
  /// Creates a new [ModifiedFileEvent] for the given [file].
  ///
  /// This is typically called by a file watcher or monitoring system when
  /// a file is modified.
  /// 
  /// {@macro modified_file_event}
  const ModifiedFileEvent(super._file);
}

/// {@template renamed_file_event}
/// Represents a **file rename event** within the JetLeaf ecosystem.
///
/// A [RenamedFileEvent] is triggered whenever a file is renamed in the
/// monitored filesystem or project context. It extends [FileEvent] to provide
/// semantic meaning specifically for renames, while also retaining a reference
/// to the original file before the rename.
///
/// ### Key Features
/// - Encapsulates the renamed [File].
/// - Retains reference to the original file via [getOldSource].
/// - Can be used by listeners or pipelines to react to renames for logging,
///   build updates, hot reload, or dependency tracking.
///
/// ### Example Usage
/// ```dart
/// void onFileRenamed(RenamedFileEvent event) {
///   final newFile = event.getSource();
///   final oldFile = event.getOldSource();
///   print('File renamed from ${oldFile?.path} to ${newFile.path}');
/// }
///
/// final oldFile = File('old_name.txt');
/// final newFile = File('new_name.txt');
/// final event = RenamedFileEvent(newFile, oldFile);
/// onFileRenamed(event);
/// ```
///
/// ### Integration
/// Typically used with:
/// - [FileWatcher] to observe file renames in directories
/// - Hot reload or live reload systems that track renamed files
/// - Event-driven pipelines that update references automatically
/// {@endtemplate}
final class RenamedFileEvent extends FileEvent {
  /// The original file before renaming.
  final File? _oldFile;

  /// Creates a new [RenamedFileEvent] with the given [file] and optional [_oldFile].
  ///
  /// [_oldFile] is the previous file path before the rename occurred.
  /// 
  /// {@macro renamed_file_event}
  const RenamedFileEvent(super._file, this._oldFile);

  /// Returns the original source file before it was renamed.
  File? getOldSource() => _oldFile;
}