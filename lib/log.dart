// Copyright (C) 2025 Fiber
//
// All rights reserved. This script, including its code and logic, is the
// exclusive property of Fiber. Redistribution, reproduction,
// or modification of any part of this script is strictly prohibited
// without prior written permission from Fiber.
//
// Conditions of use:
// - The code may not be copied, duplicated, or used, in whole or in part,
//   for any purpose without explicit authorization.
// - Redistribution of this code, with or without modification, is not
//   permitted unless expressly agreed upon by Fiber.
// - The name "Fiber" and any associated branding, logos, or
//   trademarks may not be used to endorse or promote derived products
//   or services without prior written approval.
//
// Disclaimer:
// THIS SCRIPT AND ITS CODE ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL
// FIBER BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING BUT NOT LIMITED TO LOSS OF USE,
// DATA, PROFITS, OR BUSINESS INTERRUPTION) ARISING OUT OF OR RELATED TO THE USE
// OR INABILITY TO USE THIS SCRIPT, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Unauthorized copying or reproduction of this script, in whole or in part,
// is a violation of applicable intellectual property laws and will result
// in legal action.

import 'dart:io';

import 'package:flutter/foundation.dart';

/// Defines the **severity level** of a log entry.
///
/// Each [Level] value corresponds to a specific category of diagnostic
/// information, determining how the message is formatted and prioritized
/// in both console output and file storage.
///
/// Example:
/// ```dart
/// await Logger.I.log.error(tag: Tag.service, message: 'Failed to connect.');
/// ```
///
/// See also:
///  * [Log], which uses [Level] to format and colorize console output.
enum Level {
  /// Informational message indicating normal operational events.
  info,

  /// Indicates successful completion of an operation.
  success,

  /// Highlights non-critical issues or potential risks.
  warning,

  /// Denotes an error or failure requiring attention.
  error,

  /// Used for verbose diagnostic information in development builds.
  debug,
}

/// Defines the **categorization tag** associated with a log entry.
///
/// Each [Tag] value identifies the logical subsystem or context
/// in which a log message was generated, enabling better filtering
/// and analysis of diagnostic data.
///
/// Example:
/// ```dart
/// await Logger.I.log.info(tag: Tag.gsdk, message: 'Initialization complete.');
/// ```
///
/// See also:
///  * [Level], which determines message severity.
enum Tag {
  /// Indicates that the log originates from a **service** or backend integration.
  service,

  /// Indicates that the log originates from the **GSDK (Generic SDK)** layer.
  gsdk,
}

/// Provides the core **logging engine** for structured output and file persistence.
///
/// The [Log] class is responsible for writing formatted log entries
/// to both the console (with ANSI color codes in debug mode)
/// and an optional log file when running under [kDebugMode].
///
/// This class is typically used indirectly via [Logger],
/// which manages singleton initialization and file setup.
///
/// ### Behavior
/// - When `kDebugMode` is **true**, messages are printed to the console
///   and optionally appended to a `.log` file.
/// - When `kDebugMode` is **false**, logging is silently ignored.
///
/// Example:
/// ```dart
/// final log = Log(File('app.log'));
///
/// await log.info(tag: Tag.service, message: 'Service started');
/// await log.error(tag: Tag.gsdk, message: 'Failed to load configuration');
/// ```
///
/// ### Notes
/// - Console output uses ANSI color codes for readability:
///   - Blue → `info`
///   - Green → `success`
///   - Yellow → `warning`
///   - Red → `error`
///   - Gray → `debug`
/// - Log entries written to file are timestamped with the current epoch time.
///
/// See also:
///  * [Logger], which provides a high-level interface for initializing and accessing a global logger.
///  * [Level], which defines message severity.
///  * [Tag], which identifies the log’s subsystem.
class Log {
  /// Optional file handle used for persistent logging.
  ///
  /// If `null`, log messages are only printed to the console.
  final File? file;

  /// Creates a new [Log] instance.
  ///
  /// If a [file] is provided, all log entries will be appended to it.
  const Log(this.file);

  /// Logs an informational message.
  ///
  /// Typically used for reporting standard operational events.
  Future<void> info({required Tag tag, required String message}) => _log(Level.info, tag, message);

  /// Logs a success message.
  ///
  /// Used to indicate that an operation completed successfully.
  Future<void> success({required Tag tag, required String message}) => _log(Level.success, tag, message);

  /// Logs a warning message.
  ///
  /// Highlights a non-critical issue or potential risk condition.
  Future<void> warning({required Tag tag, required String message}) => _log(Level.warning, tag, message);

  /// Logs an error message.
  ///
  /// Indicates a failure or problem requiring investigation.
  Future<void> error({required Tag tag, required String message}) => _log(Level.error, tag, message);

  /// Logs a debug message.
  ///
  /// Provides detailed diagnostic output for developers.
  Future<void> debug({required Tag tag, required String message}) => _log(Level.debug, tag, message);

  /// Internal logging method.
  ///
  /// Formats and dispatches log entries to both the console and file.
  Future<void> _log(Level level, Tag tag, String message) async {
    if (!kDebugMode) return;

    final millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;

    _printConsole(level, tag, message);
    await _writeLine('[$millisecondsSinceEpoch][${level.name.toUpperCase()}][${tag.name.toUpperCase()}]: $message');
  }

  void _printConsole(Level level, Tag tag, String line) {
    if (kDebugMode) {
      return switch (level) {
        Level.info => print('\x1B[34m[${level.name.toUpperCase()}]\x1B[0m[${tag.name.toUpperCase()}]: $line'),
        Level.success => print('\x1B[32m[${level.name.toUpperCase()}]\x1B[0m[${tag.name.toUpperCase()}]: $line'),
        Level.warning => print('\x1B[33m[${level.name.toUpperCase()}]\x1B[0m[${tag.name.toUpperCase()}]: $line'),
        Level.error => print('\x1B[31m[${level.name.toUpperCase()}]\x1B[0m[${tag.name.toUpperCase()}]: $line'),
        Level.debug => print('\x1B[90m[${level.name.toUpperCase()}]\x1B[0m[${tag.name.toUpperCase()}]: $line'),
      };
    }
  }

  Future<void> _writeLine(String line) async {
    if (file == null) return;

    try {
      await file!.writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }
}
