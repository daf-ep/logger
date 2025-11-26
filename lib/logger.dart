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

library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'log.dart';

export './log.dart';

/// Provides a **platform-aware logging utility** with optional file persistence.
///
/// The [Logger] class offers a unified interface for structured logging
/// across different runtime environments (mobile, desktop, and web).
/// In debug builds (`kDebugMode`), it writes log output to a file
/// under the application’s document or support directory.
/// In release mode, logs are emitted in-memory only (without file persistence).
///
/// This design ensures detailed debugging in development without
/// compromising performance or storage use in production.
///
/// Example:
/// ```dart
/// await Logger.initialize();
/// Logger.I.log.info('App started successfully.');
///
/// try {
///   await fetchData();
/// } catch (e, st) {
///   Logger.I.log.error('Failed to fetch data: $e', stackTrace: st);
/// }
/// ```
///
/// ### Notes
/// - The logger must be **initialized** before use by calling [Logger.initialize].
/// - File logging is automatically disabled in release builds.
/// - The log directory is created inside:
///   - `getApplicationDocumentsDirectory()` on Android/iOS.
///   - `getApplicationSupportDirectory()` on desktop.
/// - Log files are timestamped using the local time at creation.
///
/// See also:
///  * [Log], which encapsulates the underlying I/O operations.
///  * [PackageInfo], used to determine the app name and path context.
class Logger {
  final Log log;

  Logger._(this.log);

  static Logger? _instance;

  /// Initializes the global [Logger] instance.
  ///
  /// This method must be called once before accessing [Logger.I].
  /// It automatically determines the appropriate log storage path
  /// based on the current platform and build mode.
  ///
  /// If called multiple times, subsequent calls are ignored.
  static Future<void> initialize({bool testMode = false}) async {
    if (_instance != null) return;

    if (testMode) {
      _instance = Logger._(Log(null));
      return;
    }

    if (kDebugMode) {
      final file = await _createLogFile();
      _instance = Logger._(Log(file));
    } else {
      _instance = Logger._(Log(null));
    }
  }

  static Logger get I {
    final instance = _instance;
    if (instance == null) {
      throw StateError('Logger not initialized. Call `Logger.initialize()` first.');
    }
    return instance;
  }

  static Future<List<File>> logs() async {
    final dir = await _logsDir();
    if (!await dir.exists()) return [];

    final fileSystemEntity = dir.listSync();

    return fileSystemEntity.where((file) => p.extension(file.path) == ".log").map((file) => File(file.path)).toList();
  }

  static Future<File> _createLogFile() async {
    final dir = await _logsDir();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final now = DateTime.now();
    final name = "${now.year}_${now.month}_${now.day}_${now.hour}_${now.minute}_${now.second}";

    final logFile = File('${dir.path}/$name.log');
    if (!await logFile.exists()) {
      await logFile.create();
    }

    return logFile;
  }

  static Future<Directory> _logsDir() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = _sanitizeAppName(packageInfo.appName);

    late final Directory baseDir;
    if (Platform.isAndroid || Platform.isIOS) {
      baseDir = await getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      baseDir = await getApplicationSupportDirectory();
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }

    return Directory('${baseDir.path}/$appName/logs');
  }

  static String _sanitizeAppName(String name) => name.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
}
