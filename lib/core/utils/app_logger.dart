import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Uygulama genelinde kullanılacak logger utility
/// Debug modda konsola, release modda hiçbir yere yazmaz
class AppLogger {
  AppLogger._();

  static const String _name = 'ESAS';

  /// Debug seviyesinde log - geliştirme sırasında detaylı bilgi
  static void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('DEBUG', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Info seviyesinde log - normal uygulama akışı
  static void info(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('INFO', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Warning seviyesinde log - beklenmeyen ama kritik olmayan durumlar
  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('WARN', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Error seviyesinde log - hatalar
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// API çağrıları için özel log
  static void api(
    String message, {
    String? method,
    String? url,
    int? statusCode,
    Object? body,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.write('[$_name][API] ');
    if (method != null) buffer.write('$method ');
    if (url != null) buffer.write('$url ');
    if (statusCode != null) buffer.write('(Status: $statusCode) ');
    buffer.write(message);
    if (body != null) buffer.write('\nBody: $body');

    developer.log(buffer.toString(), name: _name);
  }

  /// Network request/response için log
  static void network({
    required String type,
    String? url,
    Map<String, dynamic>? headers,
    Object? body,
    int? statusCode,
    Object? response,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('[$_name][NETWORK][$type]');
    if (url != null) buffer.writeln('URL: $url');
    if (statusCode != null) buffer.writeln('Status: $statusCode');
    if (headers != null) buffer.writeln('Headers: $headers');
    if (body != null) buffer.writeln('Body: $body');
    if (response != null) buffer.writeln('Response: $response');

    developer.log(buffer.toString(), name: _name);
  }

  static void _log(
    String level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Release modda hiçbir şey yazma
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.write('[$_name][$level]');
    if (tag != null) buffer.write('[$tag]');
    buffer.write(' $message');

    developer.log(
      buffer.toString(),
      name: _name,
      error: error,
      stackTrace: stackTrace,
      level: _levelToInt(level),
    );
  }

  static int _levelToInt(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 800;
    }
  }
}
