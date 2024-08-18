import 'dart:async';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';

final _connections = <WebSocketChannel>[];

Future<Response> onRequest(RequestContext context) async {
  final handler = webSocketHandler((channel, protocol) {
    _connections.add(channel);

    channel.stream.listen(
      (message) {
        _handleMessage(channel, message as String);
      },
      onDone: () => _connections.remove(channel),
    );
  });

  return handler(context);
}

void _handleMessage(WebSocketChannel channel, String message) {
  final parts = message.split(':');
  if (parts.length != 2) return;

  final action = parts[0];
  final data = parts[1];

  switch (action) {
    case 'id':
      _broadcastId(data);
    case 'status':
      _updateStatus(data);
  }
}

void _broadcastId(String id) {
  for (final connection in _connections) {
    connection.sink.add('id:$id');
  }
}

void _updateStatus(String status) {
  for (final connection in _connections) {
    connection.sink.add('status:$status');
  }
}
