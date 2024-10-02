import 'dart:async';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:logging/logging.dart';

final _logger = Logger('WebSocketServer');
final _userConnections = <String, WebSocketChannel>{};
final _deviceConnections = <String, List<WebSocketChannel>>{};

Future<Response> onRequest(RequestContext context, String userId) async {
  final handler = webSocketHandler((channel, protocol) {
    _logger.info('New connection for user: $userId');

    _userConnections[userId] = channel;
    _logConnectionsTable();

    channel.stream.listen(
      (message) {
        _handleMessage(userId, channel, message as String);
      },
      onDone: () {
        _userConnections.remove(userId);
        _logConnectionsTable();
      },
    );
  });

  return handler(context);
}

void _handleMessage(String userId, WebSocketChannel sender, String message) {
  try {
    if (message.startsWith('s')) {
      _broadcastMessage(message);
      _logger.info('User $userId selected estate: $message');
    } else if (message.startsWith('t')) {
      _broadcastMessage(message);
      _logger.info('User $userId selected scene: $message');
    } else {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data.containsKey('deviceId') && data.containsKey('status')) {
        _logger.info(
          'Status update for device ${data['deviceId']}: ${data['status']}',
        );
        _broadcastDeviceStatus(data);
      }
    }
  } catch (e) {
    _logger.warning('Error processing message for user $userId: $e');
  }
}

void _broadcastMessage(String message) {
  for (final connection in _userConnections.values) {
    connection.sink.add(message);
  }
}

void _broadcastDeviceStatus(Map<String, dynamic> data) {
  final message = jsonEncode(data);
  for (final connection in _userConnections.values) {
    connection.sink.add(message);
  }
}

void _logConnectionsTable() {
  final buffer = StringBuffer();
  buffer.writeln();
  buffer.writeln('Current WebSocket Connections:');
  buffer.writeln('╔════════════════╦═══════════════╦═══════════════╗');
  buffer.writeln('║    User ID     ║  Connections  ║  Devices      ║');
  buffer.writeln('╠════════════════╬═══════════════╬═══════════════╣');

  _userConnections.forEach((userId, connection) {
    final deviceCount = _deviceConnections.entries
        .where((entry) => entry.value.contains(connection))
        .length;
    buffer.writeln(
      '║ ${userId.padRight(4).substring(0, 14)} ║ ${1.toString().padLeft(13)} ║ ${deviceCount.toString().padLeft(13)} ║',
    );
  });

  buffer.writeln('╚════════════════╩═══════════════╩═══════════════╝');

  _logger.info(buffer.toString());
}
