import 'dart:async';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:logging/logging.dart';

final _logger = Logger('WebSocketServer');
final _deviceConnections = <String, List<WebSocketChannel>>{};

Future<Response> onRequest(RequestContext context, String deviceId) async {
  final handler = webSocketHandler((channel, protocol) {
    _logger.info('New connection for device: $deviceId');

    if (!_deviceConnections.containsKey(deviceId)) {
      _deviceConnections[deviceId] = [];
    }
    _deviceConnections[deviceId]!.add(channel);

    _logConnectionsTable();

    channel.stream.listen(
      (message) {
        _handleMessage(deviceId, channel, message as String);
      },
      onDone: () {
        _deviceConnections[deviceId]!.remove(channel);
        _logConnectionsTable();
      },
    );
  });

  return handler(context);
}

void _handleMessage(String deviceId, WebSocketChannel sender, String message) {
  try {
    final data = jsonDecode(message) as Map<String, dynamic>;
    if (data.containsKey('status') && data.containsKey('deviceId')) {
      final newStatus = data['status'] as String;
      final messageDeviceId = data['deviceId'] as String;
      _logger.info('Status update for device $messageDeviceId: $newStatus');

      // Broadcast the new status to all clients connected to this device
      for (final connection in _deviceConnections[deviceId]!) {
        _sendStatusUpdate(connection, messageDeviceId, newStatus);
      }
    }
  } catch (e) {
    _logger.warning('Error processing message for device $deviceId: $e');
  }
}

void _sendStatusUpdate(
    WebSocketChannel channel, String deviceId, String status,) {
  final statusUpdate = jsonEncode({
    'deviceId': deviceId,
    'status': status,
  });
  channel.sink.add(statusUpdate);
}

void _logConnectionsTable() {
  final buffer = StringBuffer();
  buffer.writeln();
  buffer.writeln('Current WebSocket Connections:');
  buffer.writeln('╔════════════════╦═══════════════╗');
  buffer.writeln('║    Device ID   ║ Connections   ║');
  buffer.writeln('╠════════════════╬═══════════════╣');

  _deviceConnections.forEach((deviceId, connections) {
    buffer.writeln(
        '║ ${deviceId.padRight(14)} ║ ${connections.length.toString().padLeft(13)} ║',);
  });

  buffer.writeln('╚════════════════╩═══════════════╝');

  _logger.info(buffer.toString());
}
