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

import 'dart:async';
import 'dart:io';

part 'file_event.dart';

/// {@template file_event_handler}
/// Signature for handling file events triggered by a [FileWatcher].
///
/// The function takes a [FileEvent] and returns a [Future], allowing
/// asynchronous processing.
///
/// ### Example:
/// ```dart
/// Future<void> handle(FileEvent event) async {
///   print('Detected change: ${event.getSource().path}');
/// }
/// ```
/// {@endtemplate}
typedef FileEventHandler = Future<void> Function(FileEvent event);

/// {@template file_watcher}
/// A contract for **monitoring filesystem changes** within a directory or project.
///
/// A `FileWatcher` provides a unified way to observe files for changes, including:
/// - Creation of new files
/// - Modification of existing files
/// - Deletion of files
/// - Renaming of files
///
/// Implementations may use platform-specific APIs, polling strategies, or hybrid approaches.
/// The interface ensures that clients can query the current state of changed files and respond
/// to events in real-time.
///
/// ### Key Responsibilities
/// 1. **Start Watching**  
///    The watcher must begin observing the root directory and its subdirectories when
///    [start] is called. Implementations should deliver events asynchronously and
///    safely to the provided [FileEventHandler].
///
/// 2. **Stop Watching**  
///    Calling [stop] terminates monitoring and releases all resources, including
///    timers, streams, and OS handles. No further events should be emitted after stopping.
///
/// 3. **Track Events**  
///    Implementations should maintain internal state to allow queries for:
///    - Created files ([getCreatedFiles])
///    - Modified files ([getModifiedFiles])
///    - Deleted files ([getDeletedFiles])
///    - Renamed files ([getRenamedFiles])
///
/// ### Usage Example
/// ```dart
/// class MyFileWatcher extends FileWatcher {
///   final Directory root;
///   final List<File> created = [];
///   final List<File> modified = [];
///   final List<File> deleted = [];
///   final List<File> renamed = [];
///
///   MyFileWatcher(this.root);
///
///   @override
///   Directory getSource() => root;
///
///   @override
///   Future<void> start(FileEventHandler onEvent) async {
///     // Start listening for file events (platform-specific logic)
///   }
///
///   @override
///   Future<void> stop() async {
///     // Clean up resources
///   }
///
///   @override
///   List<File> getCreatedFiles() => List.unmodifiable(created);
///
///   @override
///   List<File> getModifiedFiles() => List.unmodifiable(modified);
///
///   @override
///   List<File> getDeletedFiles() => List.unmodifiable(deleted);
///
///   @override
///   List<File> getRenamedFiles() => List.unmodifiable(renamed);
/// }
///
/// final watcher = MyFileWatcher(Directory.current);
/// await watcher.start((event) {
///   if (event is CreatedFileEvent) {
///     print('File created: ${event.getSource().path}');
///   }
/// });
/// ```
///
/// ### Best Practices
/// - Avoid blocking operations in the event handler. If needed, dispatch work
///   to separate isolates or async tasks.
/// - Consider debouncing or throttling events when monitoring directories
///   with many rapid changes.
/// - Use [getRenamedFiles] to accurately track rename operations rather than
///   treating them as separate deletion and creation events.
///
/// ### Notes
/// - The watcher may not guarantee exact ordering of events for simultaneous changes
///   across different files.
/// - Large directories or filesystems may introduce latency in event delivery.
/// - Implementations should ensure minimal CPU/memory overhead for production use.
/// {@endtemplate}
abstract interface class FileWatcher {
  /// {@macro file_watcher}
  const FileWatcher();

  /// Starts the file watcher and begins listening for file events.
  ///
  /// - [onEvent]: Callback invoked whenever a relevant [FileEvent] occurs.
  ///   Implementations should invoke this for all `CreatedFileEvent`,
  ///   `ModifiedFileEvent`, `DeletedFileEvent`, and `RenamedFileEvent`.
  ///
  /// Event delivery must be asynchronous and safe for concurrent execution.
  Future<void> start(FileEventHandler onEvent);

  /// Returns the root directory being monitored.
  ///
  /// All events reported by the watcher are relative to this directory.
  Directory getSource();

  /// Stops the watcher and releases all associated resources.
  ///
  /// After this method is called, no further events should be emitted.
  Future<void> stop();

  /// Returns the list of files that have been **created** since the watcher
  /// started or the last reset.
  List<File> getCreatedFiles();

  /// Returns the list of files that have been **modified** since the watcher
  /// started or the last reset.
  List<File> getModifiedFiles();

  /// Returns the list of files that have been **renamed** since the watcher
  /// started or the last reset.
  ///
  /// This list is particularly useful when you want to preserve references
  /// to the previous path of files.
  List<File> getRenamedFiles();

  /// Returns the list of files that have been **deleted** since the watcher
  /// started or the last reset.
  List<File> getDeletedFiles();
}

/// {@template application_file_watcher}
/// A concrete implementation of [FileWatcher] for monitoring file system changes
/// within a project or directory.
///
/// The `ApplicationFileWatcher` observes a root directory and detects:
/// - Newly created files
/// - Modified files
/// - Deleted files
/// - Renamed files
///
/// ### Features
/// 1. **Automatic Project Root Detection**
///    - By default, the watcher attempts to locate the project root by
///      searching for the nearest `pubspec.yaml` starting from [Directory.current].
///    - If no `pubspec.yaml` is found, the current directory is used.
///
/// 2. **Include and Exclude Filters**
///    - Uses [includePatterns] to allow only files matching certain extensions or paths.
///    - Uses [excludePatterns] to ignore build directories, lock files, or system files.
///    - Filters are RegExp-based for maximum flexibility.
///
/// 3. **Debounced Event Delivery**
///    - Avoids flooding with events when multiple rapid changes occur.
///    - The [debounceDuration] defines the minimum interval between event emissions.
///
/// 4. **Change Tracking**
///    - Maintains internal lists of created, modified, deleted, and renamed files.
///    - Lists are available through [getCreatedFiles], [getModifiedFiles],
///      [getDeletedFiles], and [getRenamedFiles].
///
/// ### Usage
/// ```dart
/// final watcher = ApplicationFileWatcher();
///
/// await watcher.start((event) {
///   if (event is CreatedFileEvent) {
///     print('File created: ${event.getSource().path}');
///   } else if (event is ModifiedFileEvent) {
///     print('File modified: ${event.getSource().path}');
///   }
/// });
///
/// // Stop watching when done
/// await watcher.stop();
/// ```
///
/// ### Customization
/// ```dart
/// watcher.debounceDuration = Duration(milliseconds: 500);
/// watcher.includePatterns = [RegExp(r'\.dart$')];
/// watcher.excludePatterns = [RegExp(r'[/\\](build|.git)[/\\]?')];
/// ```
///
/// ### Implementation Notes
/// - Uses [Directory.watch] internally for cross-platform file system notifications.
/// - Events are buffered and debounced to prevent duplicate notifications.
/// - Renamed files are tracked if the underlying [FileSystemMoveEvent] provides
///   an `oldPath`.
/// - Includes utility `_isRelevant` to match files against include/exclude patterns.
/// - `_flushBuffer` ensures only the latest event per file path is delivered after debouncing.
/// {@endtemplate}
final class ApplicationFileWatcher implements FileWatcher {
  /// The root directory being monitored.
  ///
  /// Automatically set to the project root based on `pubspec.yaml`.
  /// Falls back to [Directory.current] if project root cannot be determined.
  late Directory root;

  /// Minimum duration between emitting file events.
  ///
  /// This is used for debouncing rapid file system events to avoid
  /// sending multiple events for a single logical change.
  Duration debounceDuration = const Duration(milliseconds: 250);

  /// List of RegExp patterns for files or paths to include in monitoring.
  ///
  /// Only files matching at least one include pattern will generate events.
  List<RegExp> includePatterns = [
    RegExp(r'\.(dart|leaf|html|yaml|env|properties|json|yml|css|js|ts|tsx|jsx|vue|md|markdown)$')
  ];

  /// List of RegExp patterns for files or directories to exclude from monitoring.
  ///
  /// Any file matching an exclude pattern is ignored even if it matches an include pattern.
  List<RegExp> excludePatterns = [
    RegExp(r'[/\\](build|test|\.git|\.idea)[/\\]?'), // ignore common directories
    RegExp(r'\.lock$'), // ignore lock files
    RegExp(r'\.DS_Store$'), // ignore macOS metadata files
  ];

  /// Subscription to the file system watch stream.
  ///
  /// Used to listen for real-time file changes in the [root] directory.
  StreamSubscription<FileSystemEvent>? _subscription;

  /// Timer used to debounce events.
  ///
  /// When multiple file system events happen in quick succession, this
  /// timer delays the processing to batch events together.
  Timer? _debounce;

  /// Internal buffer holding incoming [FileSystemEvent]s before processing.
  List<FileSystemEvent> _eventBuffer = [];

  /// Internal list of files that have been created since watcher started.
  final List<File> _addedFiles = [];

  /// Internal list of files that have been deleted since watcher started.
  final List<File> _removedFiles = [];

  /// Internal list of files that have been modified since watcher started.
  final List<File> _modifiedFiles = [];

  /// Internal list of files that have been renamed since watcher started.
  final List<File> _renamedFiles = [];

  /// Constructs a new [ApplicationFileWatcher] instance.
  ///
  /// Automatically detects the project root directory by searching for
  /// `pubspec.yaml`. Defaults to [Directory.current] if not found.
  /// 
  /// {@macro application_file_watcher}
  ApplicationFileWatcher() {
    root = _findProjectRoot(Directory.current) ?? Directory.current;
  }

  /// Attempts to locate the project root by searching for `pubspec.yaml`.
  ///
  /// Starts from [start] directory and moves upwards in the directory
  /// hierarchy until a `pubspec.yaml` file is found or the filesystem root
  /// is reached.
  Directory? _findProjectRoot(Directory start) {
    Directory current = start;

    while (true) {
      final pubspec = File('${current.path}${Platform.pathSeparator}pubspec.yaml');
      if (pubspec.existsSync()) {
        return current;
      }

      final parent = current.parent;
      if (parent.path == current.path) break; // Reached root
      current = parent;
    }

    return null; // fallback will be Directory.current
  }

  @override
  Directory getSource() => root;

  @override
  List<File> getCreatedFiles() => _addedFiles;

  @override
  List<File> getDeletedFiles() => _removedFiles;

  @override
  List<File> getModifiedFiles() => _modifiedFiles;

  @override
  List<File> getRenamedFiles() => _renamedFiles;

  @override
  Future<void> start(FileEventHandler onEvent) {
    _subscription = root.watch().listen((event) => _handleEvent(event, onEvent));
    return Future.value();
  }

  /// Internal method to handle incoming [FileSystemEvent]s.
  ///
  /// Adds the event to [_eventBuffer] and sets a debounced timer to
  /// process events in batches using [_flushBuffer].
  void _handleEvent(FileSystemEvent event, FileEventHandler onEvent) {
    final file = File(event.path);
    if (!_isRelevant(file)) return;

    _eventBuffer.add(event);
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, () => _flushBuffer(onEvent));
  }

  /// Determines whether a given file is relevant for monitoring.
  ///
  /// - Returns `true` if the file matches at least one include pattern
  ///   and does not match any exclude pattern.
  /// - Returns `false` otherwise.
  bool _isRelevant(File file) {
    final path = file.path;

    for (final ex in excludePatterns) {
      if (ex.hasMatch(path)) return false;
    }

    for (final inc in includePatterns) {
      if (inc.hasMatch(path)) return true;
    }

    return false;
  }

  /// Flushes the buffered events and converts them into concrete [FileEvent]s.
  ///
  /// Only the latest event per file path is processed to avoid duplicate notifications.
  void _flushBuffer(FileEventHandler onEvent) {
    final seen = <String>{};
    for (final event in _eventBuffer.reversed) {
      if (seen.add(event.path)) {
        final fileEvent = toFileEvent(event);
        if (fileEvent != null) {
          // Update internal change tracking lists
          if (fileEvent is CreatedFileEvent) _addedFiles.add(fileEvent._file);
          if (fileEvent is DeletedFileEvent) _removedFiles.add(fileEvent._file);
          if (fileEvent is ModifiedFileEvent) _modifiedFiles.add(fileEvent._file);
          if (fileEvent is RenamedFileEvent) _renamedFiles.add(fileEvent._file);
          
          onEvent(fileEvent);
        }
      }
    }
    _eventBuffer.clear();
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _debounce?.cancel();
    _eventBuffer = [];

    return Future.value();
  }

  /// Converts a [FileSystemEvent] into a concrete [FileEvent].
  ///
  /// Returns:
  /// - [CreatedFileEvent] if it's a create event.
  /// - [ModifiedFileEvent] if it's a modify event.
  /// - [DeletedFileEvent] if it's a delete event.
  /// - [RenamedFileEvent] if it's a move/rename event.
  FileEvent? toFileEvent(FileSystemEvent event) {
    final file = File(event.path);
    if (event is FileSystemCreateEvent) return CreatedFileEvent(file);
    if (event is FileSystemModifyEvent) return ModifiedFileEvent(file);
    if (event is FileSystemDeleteEvent) return DeletedFileEvent(file);
    if (event is FileSystemMoveEvent) {
      final oldPath = (event as dynamic).oldPath as String?;
      return oldPath != null
          ? RenamedFileEvent(file, File(oldPath))
          : RenamedFileEvent(file, null);
    }
    return null;
  }
}