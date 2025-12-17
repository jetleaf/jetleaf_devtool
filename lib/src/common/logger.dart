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

import 'dart:io';

import 'package:jetleaf_logging/logging.dart';

/// A simple logger class for CLI output.
class CliLogger {
  final String name;

  /// Creates a new [CliLogger] instance with a given [name].
  CliLogger(this.name);

  /// Logs an informational message.
  void info(String message) {
    final color = LogCommons.levelColors[LogLevel.INFO]!;
    final emoji = LogCommons.levelEmojis[LogLevel.INFO]!;
    _log(message, color, emoji, "INFO");
  }

  void onInfo(String message, bool updated) => info(message);
  void onWarn(String message, bool updated) => warn(message);
  void onError(String message, bool updated) => error(message);

  /// Logs a warning message.
  void warn(String message) {
    final color = LogCommons.levelColors[LogLevel.WARN]!;
    final emoji = LogCommons.levelEmojis[LogLevel.WARN]!;
    _log(message, color, emoji, "WARN");
  }

  /// Logs an error message.
  void error(String message) {
    final color = LogCommons.levelColors[LogLevel.ERROR]!;
    final emoji = LogCommons.levelEmojis[LogLevel.ERROR]!;
    _log(message, color, emoji, "ERROR", true);
  }

  void _log(String message, AnsiColor color, String emoji, String level, [bool isError = false]) {
    final len = 6 - name.length;
    final width = len.isNegative ? 0 : len;
    final logName = '[$name]${''.padRight(width)}';

    final levelLen = 6 - level.length;
    final levelWidth = levelLen.isNegative ? 0 : levelLen;
    final logLevel = '$emoji $level:${''.padRight(levelWidth)}';

    if (isError) {
      stderr.writeln('${color.call(logName)} ${color.call(logLevel)} $message');
    } else {
      stdout.writeln('${color.call(logName)} ${color.call(logLevel)} $message');
    }
  }

  /// Prints an empty line for spacing.
  void space() => stdout.writeln('');
}

/// A simple session manager for CLI loggers.
class CliSession {
  /// Retrieves a [CliLogger] instance by name.
  CliLogger get(String name) => CliLogger(name);
}

/// Global instance of [CliSession].
final cliSession = CliSession();