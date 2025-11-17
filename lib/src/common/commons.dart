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

/// {@template ansi_esc}
/// ANSI escape sequence introducer for terminal control.
/// {@endtemplate}
const String _ansiEsc = '\x1B';

/// {@template carriage_return}
/// ASCII carriage return used to reset to the beginning of the current line.
/// {@endtemplate}
const String _cr = '\r';

/// {@template go_up_one_line}
/// Moves the terminal cursor one line up using ANSI escape codes.
/// {@endtemplate}
void goUpOneLine() {
  if (stdout.supportsAnsiEscapes) {
    stdout.write('$_ansiEsc[1A');
  }
}

/// {@template clear_line}
/// Clears the current terminal line using ANSI escape codes and
/// resets the cursor to the beginning of the line.
/// {@endtemplate}
void clearLine() {
  if (stdout.supportsAnsiEscapes) {
    stdout.write('$_cr$_ansiEsc[2K');
  }
}

/// {@template wrap_with}
/// Applies multiple [AnsiColor] styles to a given [msg] string.
///
/// Useful for combining text styles like bold, underline, and colors.
///
/// Example:
/// ```dart
/// print(wrapWith('Hello', [AnsiColor.RED, AnsiColor.BOLD]));
/// ```
/// {@endtemplate}
String wrapWith(String msg, List<AnsiColor> codes) {
  if (!stdout.supportsAnsiEscapes) return msg;
  String result = msg;
  for (final code in codes) {
    result = code.call(result);
  }
  return result;
}