import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// Drive async stream delivery with the widget clock instead of awaiting
/// Stream.first's asynchronous cancellation while fake time is paused.
Future<T> streamSnapshot<T>(WidgetTester tester, Stream<T> stream) async {
  T? value;
  final subscription = stream.listen((event) => value = event);
  await tester.pump();
  unawaited(subscription.cancel());
  expect(value, isNotNull);
  return value as T;
}
