import 'dart:async';
import 'dart:isolate';

/// A generic function to run a task in a separate isolate.
/// [task] is the function to run.
/// [param] is the parameter to pass to the function.
Future<R> runInIsolate<P, R>(Future<R> Function(P param) task, P param) async {
  final completer = Completer<R>();
  final receivePort = ReceivePort();

  receivePort.listen((message) {
    completer.complete(message as R);
    receivePort.close();
  });

  await Isolate.spawn(_isolateEntry, [receivePort.sendPort, task, param]);
  return completer.future;
}

void _isolateEntry<P, R>(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final task = args[1] as Function;
  final param = args[2] as P;
  final result = await task(param) as R;
  sendPort.send(result);
}