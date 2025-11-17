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

import 'package:jetleaf_logging/logging.dart';

import 'commons.dart';

/// {@template spinner}
/// A simple CLI spinner for showing ongoing activity in JetLeaf tools.
///
/// This utility displays a terminal-based spinner animation to indicate
/// that a long-running task is in progress. It's especially useful
/// for improving UX during tasks like bootstrapping, building, or watching files.
///
/// Example usage:
/// ```dart
/// final spinner = Spinner('Building project...');
/// spinner.start();
/// await longRunningTask();
/// spinner.stop(successMessage: 'Build completed');
/// ```
///
/// The spinner uses ANSI escape sequences for animation, which are
/// supported on most modern terminals.
/// {@endtemplate}
class Spinner {
  /// The message displayed next to the spinner animation.
  final String message;

  final List<String> _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  int _currentFrame = 0;
  Timer? _timer;
  bool _isRunning = false;

  /// {@macro spinner}
  Spinner(this.message);

  /// Starts the spinner animation and displays the message in the terminal.
  ///
  /// If ANSI escape sequences are not supported by the terminal,
  /// a fallback format is used.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    if (stdout.supportsAnsiEscapes) {
      stdout.writeln('${AnsiColor.CYAN.call(_frames[_currentFrame])} ${AnsiColor.WHITE.call(message)}');
    } else {
      stdout.writeln('$_frames[$_currentFrame] $message');
    }
    // stdout.flush(); // Flush after initial write

    _timer = Timer.periodic(Duration(milliseconds: 80), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      goUpOneLine();
      clearLine();
      _currentFrame = (_currentFrame + 1) % _frames.length;
      if (stdout.supportsAnsiEscapes) {
        stdout.writeln('${AnsiColor.CYAN.call(_frames[_currentFrame])} ${AnsiColor.WHITE.call(message)}');
      } else {
        stdout.writeln('$_frames[$_currentFrame] $message');
      }

      // stdout.flush(); // Flush after each frame update
    });
  }

  /// Stops the spinner animation and optionally displays a success message.
  ///
  /// If [successMessage] is provided, it is printed on a new line.
  ///
  /// Example:
  /// ```dart
  /// spinner.stop(successMessage: 'Finished!');
  /// ```
  void stop({String? successMessage}) {
    if (!_isRunning) return;
    _isRunning = false;
    _timer?.cancel();
    goUpOneLine();
    clearLine();
    if (successMessage != null) {
      if (stdout.supportsAnsiEscapes) {
        stdout.writeln('${AnsiColor.GREEN.call('✔')} ${AnsiColor.WHITE.call(successMessage)}');
      } else {
        stdout.writeln('✔ $successMessage');
      }
    }

    // stdout.flush(); // Flush after stopping
  }
}