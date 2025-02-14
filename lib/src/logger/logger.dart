import 'dart:async';

import 'definition.dart';
import 'emit.dart';
import 'event.dart';
import 'payload.dart';

/// Prisma event listener.
typedef Listener = void Function(Payload payload);

/// Prisma event logger
abstract class Logger {
  /// Create a new logger.
  factory Logger({
    Iterable<Event>? stdout,
    Iterable<Event>? event,
  }) = _LoggerImpl;

  /// The log definitions.
  Iterable<Definition> get definitions;

  /// Listen to log event.
  void on(Event event, Listener listener);

  /// Emit a log event.
  void emit(Event event, Payload payload);
}

/// Broadcast Event.
class _BroadcastEvent {
  final Event event;
  final Payload payload;

  _BroadcastEvent(this.event, this.payload);
}

class _LoggerImpl implements Logger {
  @override
  final List<Definition> definitions;

  /// Briadcast stream controller.
  final StreamController<_BroadcastEvent> broadcast;

  /// Create a new Emmiter.
  const _LoggerImpl._internal({
    required this.definitions,
    required this.broadcast,
  });

  /// Create a new logger.
  factory _LoggerImpl({
    Iterable<Event>? stdout,
    Iterable<Event>? event,
  }) {
    final broadcast = StreamController<_BroadcastEvent>.broadcast();
    final definitions = <Definition>[];

    if (stdout != null) {
      definitions.addAll(
          stdout.toSet().map((event) => Definition(event, Emit.stdout)));

      broadcast.stream
          .where((event) => stdout.contains(event.event))
          .map((event) => event.payload)
          .listen(print);
    }
    if (event != null) {
      definitions
          .addAll(event.toSet().map((event) => Definition(event, Emit.event)));
    }

    return _LoggerImpl._internal(
      definitions: definitions,
      broadcast: broadcast,
    );
  }

  @override
  void emit(Event event, Payload payload) {
    // If [event] is [Event.query], The [playload] must be a [QueryPayload].
    if (event == Event.query && payload is! QueryPayload) {
      throw ArgumentError.value(
        payload,
        'payload',
        'The payload must be a QueryPayload',
      );

      // If [paload] is a [QueryPayload], The [event] must be [Event.query].
    } else if (payload is QueryPayload && event != Event.query) {
      throw ArgumentError.value(
        event,
        'event',
        'The event must be Event.query',
      );
    }

    broadcast.add(_BroadcastEvent(event, payload));
  }

  @override
  void on(Event event, Listener listener) {
    broadcast.stream
        .where((e) => e.event == event)
        .where((event) => definitions
            .where((element) => element.emit == Emit.event)
            .map((element) => element.event)
            .contains(event.event))
        .map((event) => event.payload)
        .listen(listener);
  }
}
