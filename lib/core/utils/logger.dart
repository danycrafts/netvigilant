import 'package:flutter/foundation.dart';

void log(dynamic message, {Object? error, StackTrace? stackTrace}) {
  if (kDebugMode) {
    print(message);
    if (error != null) {
      print('Error: $error');
    }
    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
  }
}
