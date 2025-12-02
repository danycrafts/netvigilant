import 'dart:developer' as developer;

class AppLogger {
  static const String _appPrefix = '[NetVigilant]';
  
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: '$_appPrefix ${tag ?? 'INFO'}',
      level: 800,
    );
  }
  
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: '$_appPrefix ${tag ?? 'WARNING'}',
      level: 900,
    );
  }
  
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    developer.log(
      message,
      name: '$_appPrefix ${tag ?? 'ERROR'}',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
  
  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: '$_appPrefix ${tag ?? 'DEBUG'}',
      level: 700,
    );
  }
}