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

import 'commons.dart';

// ASCII control characters (replacing charcode/ascii.dart)
const int _esc = 0x1B;
const int _lbracket = 0x5B;
const int _A = 0x41;
const int _B = 0x42;
const int _lf = 0x0A; // Line Feed (Enter key)
const int _asterisk = 0x2A; // For concealing input

/// Prompt the user, and return the first line read.
/// This is the core of [Prompter], and the basis for all other
/// functions.
///
/// A function to [validate] may be passed. If `null`, it defaults
/// to checking if the string is not empty.
///
/// A default value may be given as [defaultsTo]. If present, the [message]
/// will have `' ($defaultsTo)'` append to it.
///
/// If [chevron] is `true` (default), then a `>` will be appended to the prompt.
///
/// If [color] is `true` (default), then pretty ANSI colors will be used in the prompt.
///
/// [inputColor] may be used to give a color to the user's input as they type.
///
/// If [allowMultiline] is `true` (default: `false`), then lines ending in a
/// backslash (`\`) will be interpreted as a signal that another line of
/// input is to come. This is helpful for building REPL's.
String get(String message, {
  bool Function(String)? validate,
  String? defaultsTo,
  bool chevron = true,
  bool color = true,
  bool allowMultiline = false,
  bool conceal = false,
  AnsiColor inputColor = AnsiColor.CYAN
}) {
  validate ??= (s) => s.trim().isNotEmpty;
  if (defaultsTo != null) {
    var oldValidate = validate;
    validate = (s) => s.trim().isEmpty || oldValidate(s);
  }
  var prefix = '?';
  var code = AnsiColor.CYAN;
  var currentChevron = '\u00BB';

  // Save original terminal modes
  bool originalEchoMode = stdin.echoMode;
  bool originalLineMode = stdin.lineMode;

  try {
    while (true) {
      var msg = color && stdout.supportsAnsiEscapes
          ? ('${code.call(prefix)} ${wrapWith(message, [AnsiColor.DARK_GRAY])}')
          : message;
      stdout.write(msg);
      if (defaultsTo != null) stdout.write(' ($defaultsTo)');
      if (chevron) {
        stdout.write(color && stdout.supportsAnsiEscapes ? AnsiColor.GRAY.call(' $currentChevron') : ' $currentChevron');
      }
      stdout.write(' ');
      // stdout.flush(); // Flush prompt immediately

      var buf = StringBuffer();
      if (conceal) {
        stdin.echoMode = false; // Disable echo for concealed input
      } else {
        stdin.echoMode = true; // Ensure echo is on for regular input
      }
      stdin.lineMode = true; // Ensure line mode is on for readLineSync

      while (true) {
        var line = stdin.readLineSync()!;
        if (!allowMultiline || !line.endsWith('\\')) {
          buf.writeln(line);
          break;
        } else {
          buf.writeln(line.substring(0, line.length - 1));
        }
        clearLine(); // Clear line if multi-line input continues
      }

      var line = buf.toString().trim();

      if (validate(line)) {
        String out;
        if (defaultsTo != null) {
          out = line.isEmpty ? defaultsTo : line;
        } else {
          out = line;
        }
        if (color && stdout.supportsAnsiEscapes) {
          var toWrite = line;
          if (conceal) {
            var asterisks = List.filled(line.length, _asterisk);
            toWrite = String.fromCharCodes(asterisks);
          }
          prefix = '\u2714';
          code = AnsiColor.GREEN;
          goUpOneLine(); // Move up to the line where the prompt was
          clearLine();   // Clear that line
          // Now, rewrite the prompt with the checkmark and the user's input
          stdout.writeln('${code.call(prefix)} $message ${AnsiColor.DARK_GRAY.call(toWrite)}');
          // stdout.flush(); // Ensure it's written
        }
        return out;
      } else {
        code = AnsiColor.RED;
        prefix = '\u2717';
        goUpOneLine();
        clearLine();
        // stdout.flush(); // Flush after clearing on error
      }
    }
  } finally {
    // Always restore original terminal modes
    stdin.echoMode = originalEchoMode;
    stdin.lineMode = originalLineMode;
  }
}

/// Presents a yes/no prompt to the user.
///
/// If [appendYesNo] is `true`, then a `(y/n)`, `(Y/n)` or `(y/N)` is
/// appended to the [message], depending on its value.
///
/// [color], [inputColor], [conceal], and [chevron] are forwarded to [get].
bool getBool(String message, {
  bool defaultsTo = false,
  bool appendYesNo = true,
  bool color = true,
  bool chevron = true,
  bool conceal = false,
  AnsiColor inputColor = AnsiColor.CYAN
}) {
  if (appendYesNo) {
    message += (defaultsTo ? ' (Y/n)' : ' (y/N)');
  }
  var result = get(
    message,
    color: color,
    inputColor: inputColor,
    conceal: conceal,
    chevron: chevron,
    validate: (s) {
      s = s.trim().toLowerCase();
      return (s.isEmpty) || s.startsWith('y') || s.startsWith('n');
    },
  );
  result = result.toLowerCase();
  if (result.isEmpty) {
    return defaultsTo;
  } else if (result == 'y') {
    return true;
  }
  return false;
}

/// Prompts the user to enter an integer.
///
/// An optional [radix] may be provided.
///
/// [color], [defaultsTo], [inputColor], [conceal], and [chevron] are forwarded to [get].
int getInt(String message, {
  int? defaultsTo,
  int radix = 10,
  bool color = true,
  bool chevron = true,
  bool conceal = false,
  AnsiColor inputColor = AnsiColor.CYAN
}) {
  return int.parse(get(
    message,
    defaultsTo: defaultsTo?.toString(),
    chevron: chevron,
    inputColor: inputColor,
    color: color,
    conceal: conceal,
    validate: (s) => int.tryParse(s, radix: radix) != null,
  ));
}

/// Prompts the user to enter a double.
///
/// [color], [defaultsTo], [inputColor], [conceal], and [chevron] are forwarded to [get].
double getDouble(String message, {
  double? defaultsTo,
  bool color = true,
  bool chevron = true,
  bool conceal = false,
  AnsiColor inputColor = AnsiColor.CYAN
}) {
  return double.parse(get(
    message,
    defaultsTo: defaultsTo?.toString(),
    chevron: chevron,
    inputColor: inputColor,
    color: color,
    conceal: conceal,
    validate: (s) => double.tryParse(s) != null,
  ));
}

/// Displays to the user a list of [options], and returns
/// once one has been chosen.
///
/// Each option will be prefixed with a number, corresponding
/// to its index + `1`. Pass an iterable of [names] to provide custom prefixes.
///
/// A default option may be provided by means of [defaultsTo].
///
/// A custom [prompt] may be provided, which is then forwarded to [get].
///
/// This function also supports an [interactive] mode, where user arrow keys are processed.
/// In [interactive] mode, you can provide a [defaultIndex] for the UI to start on.
///
/// [color], [defaultsTo], [inputColor], [conceal], and [chevron] are forwarded to [get].
///
/// Example:
///
/// ```
/// Choose a color:
///
/// 1) Red
/// 2) Blue
/// 3) Green
/// ```
T? choose<T>(String message, Iterable<T> options, {
  T? defaultsTo,
  String prompt = 'Enter your choice',
  bool chevron = true,
  AnsiColor inputColor = AnsiColor.CYAN,
  bool color = true,
  bool conceal = false,
  bool interactive = true,
  Iterable<String>? names
}) {
  if (options.isEmpty) {
    throw ArgumentError.value('`options` may not be empty.');
  }
  if (defaultsTo != null && !options.contains(defaultsTo)) {
    throw ArgumentError('$defaultsTo is not contained in $options, and therefore cannot be the default value.');
  }
  if (names != null && names.length != options.length) {
    throw ArgumentError('$names must have length ${options.length}, not ${names.length}.');
  }
  if (names != null && names.any((s) => s.length != 1)) {
    throw ArgumentError('Every member of $names must be a string with a length of 1.');
  }
  var map = <T, String>{};
  for (var option in options) {
    map[option] = option.toString();
  }
  if (chevron) message += ':';
  var b = StringBuffer();
  b.writeln(message);

  // Save original terminal modes
  bool originalEchoMode = stdin.echoMode;
  bool originalLineMode = stdin.lineMode;

  try {
    if (interactive && stdout.supportsAnsiEscapes && !Platform.isWindows) {
      var index = defaultsTo != null ? options.toList().indexOf(defaultsTo) : 0;
      var needsClear = false;
      if (color) {
        print(wrapWith(b.toString(), [AnsiColor.DARK_GRAY]));
      } else {
        print(b);
      }
      void writeIt() {
        if (!needsClear) {
          needsClear = true;
        } else {
          for (var i = 0; i < options.length; i++) {
            goUpOneLine();
            clearLine();
          }
        }
        for (var i = 0; i < options.length; i++) {
          var key = map.keys.elementAt(i);
          var msg = map[key];
          AnsiColor code;
          if (index == i) {
            code = AnsiColor.CYAN;
            msg = '* $msg';
          } else {
            code = AnsiColor.DARK_GRAY;
            msg = '$msg  ';
          }
          if (names != null) {
            msg = '${names.elementAt(i)}) $msg';
          }
          if (color) {
            print(code.call(msg));
          } else {
            print(msg);
          }
        }
        // stdout.flush(); // Flush after writing options
      }
      do {
        int ch;
        writeIt();
        try {
          stdin.lineMode = stdin.echoMode = false; // Enter raw mode
          ch = stdin.readByteSync();
          if (ch == _esc) {
            ch = stdin.readByteSync();
            if (ch == _lbracket) {
              ch = stdin.readByteSync();
              if (ch == _A) {
                index--;
                if (index < 0) index = options.length - 1;
              } else if (ch == _B) {
                index++;
                if (index >= options.length) index = 0;
              }
            }
          } else if (ch == _lf) {
            return map.keys.elementAt(index);
          } else {
            var s = String.fromCharCode(ch);
            if (names != null && names.contains(s)) {
              index = names.toList().indexOf(s);
              return map.keys.elementAt(index);
            }
          }
        } finally {
          // Modes are reset in the outer finally block
        }
      } while (true);
    } else {
      b.writeln();
      for (var i = 0; i < options.length; i++) {
        var key = map.keys.elementAt(i);
        var indicator = names != null ? names.elementAt(i) : (i + 1).toString();
        b.write('$indicator) ${map[key]}');
        if (key == defaultsTo) b.write(' [Default - Press Enter]');
        b.writeln();
      }
      b.writeln();
      if (color) {
        print(wrapWith(b.toString(), [AnsiColor.DARK_GRAY]));
      } else {
        print(b);
      }
      var line = get(
        prompt,
        chevron: false,
        inputColor: inputColor,
        color: color,
        conceal: conceal,
        validate: (s) {
          if (s.isEmpty) return defaultsTo != null;
          if (map.values.contains(s)) return true;
          if (names != null && names.contains(s)) return true;
          var i = int.tryParse(s);
          if (i == null) return false;
          return i >= 1 && i <= options.length;
        },
      );
      if (line.isEmpty) return defaultsTo;
      int? i;
      if (names != null && names.contains(line)) {
        i = names.toList().indexOf(line) + 1;
      } else {
        i = int.tryParse(line);
      }
      if (i != null) return map.keys.elementAt(i - 1);
      return map.keys.elementAt(map.values.toList(growable: false).indexOf(line));
    }
  } finally {
    // Always restore original terminal modes after the choose function completes
    stdin.echoMode = originalEchoMode;
    stdin.lineMode = originalLineMode;
  }
}

/// Similar to [choose], but opts for a shorthand syntax that fits into one line,
/// rather than a multi-line prompt.
///
/// Acceptable inputs include:
/// * The full value of `toString()` for any one option
/// * The first character (case-insensitive) of `toString()` for an option
///
/// A default option may be provided by means of [defaultsTo].
///
/// [color], [defaultsTo], [inputColor], and [chevron] are forwarded to [get].
T? chooseShorthand<T>(String message, Iterable<T> options, {
  T? defaultsTo,
  bool chevron = true,
  AnsiColor inputColor = AnsiColor.CYAN,
  bool color = true,
  bool conceal = false
}) {
  if (options.isEmpty) {
    throw ArgumentError.value('`options` may not be empty.');
  }
  var b = StringBuffer(message);
  if (chevron) b.write(':');
  b.write(' (');
  var firstChars = <String>[], strings = <String>[];
  var i = 0;
  for (var option in options) {
    var str = option.toString();
    if (i++ > 0) b.write('/');
    if (defaultsTo != null) {
      if (defaultsTo == option) {
        str = str[0].toUpperCase() + str.substring(1);
      } else {
        str = str[0].toLowerCase() + str.substring(1);
      }
    }
    b.write(str);
    firstChars.add(str[0].toLowerCase());
    strings.add(str);
  }
  b.write(')');
  T? value;
  get(
    b.toString(),
    chevron: chevron,
    inputColor: inputColor,
    color: color,
    conceal: conceal,
    validate: (s) {
      if (s.isEmpty) return (value = defaultsTo) != null;
      if (strings.contains(s)) {
        value = options.elementAt(strings.indexOf(s));
        return true;
      }
      if (firstChars.contains(s[0].toLowerCase())) {
        value = options.elementAt(firstChars.indexOf(s[0].toLowerCase()));
        return true;
      }
      return false;
    },
  );
  return value;
}